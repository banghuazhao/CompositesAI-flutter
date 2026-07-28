import 'dart:collection';

import 'package:domain/chat/chat_use_case.dart';
import 'package:domain/chat/entities/chat_file.dart';
import 'package:domain/chat/entities/chat_knowledge.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../model/chat_error.dart';

typedef ChatAccessCallback = bool Function();
typedef AttachmentErrorCallback = void Function(
  ChatFailure failure, {
  AsyncCallback? retry,
});

/// Owns attachment upload, preview, and knowledge-selection state.
class ChatAttachmentController extends ChangeNotifier {
  ChatAttachmentController({
    required ChatUseCase chatUseCase,
    required ChatAccessCallback canUseChat,
    required AttachmentErrorCallback onError,
  })  : _chatUseCase = chatUseCase,
        _canUseChat = canUseChat,
        _onError = onError;

  static const int maxPendingAttachments = 10;
  static const int maxCachedImagePreviews = 24;

  final ChatUseCase _chatUseCase;
  final ChatAccessCallback _canUseChat;
  final AttachmentErrorCallback _onError;

  final List<ChatKnowledge> _knowledgeBases = <ChatKnowledge>[];
  final List<ChatFile> _pendingFiles = <ChatFile>[];
  final List<String> _uploadingFileNames = <String>[];
  final Map<String, Uint8List> _imagePreviewBytes = <String, Uint8List>{};
  late final List<ChatKnowledge> _knowledgeBasesView =
      UnmodifiableListView<ChatKnowledge>(_knowledgeBases);
  late final List<ChatFile> _pendingFilesView =
      UnmodifiableListView<ChatFile>(_pendingFiles);
  late final List<String> _uploadingFileNamesView =
      UnmodifiableListView<String>(_uploadingFileNames);
  late final Map<String, Uint8List> _imagePreviewBytesView =
      UnmodifiableMapView<String, Uint8List>(_imagePreviewBytes);

  bool isLoadingKnowledge = false;
  bool isUploadingFile = false;
  bool _isDisposed = false;

  List<ChatKnowledge> get knowledgeBases => _knowledgeBasesView;
  List<ChatFile> get pendingFiles => _pendingFilesView;
  List<String> get uploadingFileNames => _uploadingFileNamesView;
  Map<String, Uint8List> get imagePreviewBytes => _imagePreviewBytesView;

  Future<void> fetchKnowledgeBases() async {
    if (_isDisposed || !_canUseChat()) return;

    isLoadingKnowledge = true;
    _notifyListenersIfActive();
    try {
      final knowledge = await _chatUseCase.fetchKnowledgeBases();
      if (_isDisposed) return;
      _knowledgeBases
        ..clear()
        ..addAll(knowledge);
    } catch (error) {
      if (_isDisposed) return;
      if (kDebugMode) debugPrint('fetchKnowledgeBases error: $error');
      _knowledgeBases.clear();
      _onError(
        ChatErrorMapper.from(
          error,
          operation: ChatOperation.loadKnowledge,
        ),
        retry: fetchKnowledgeBases,
      );
    } finally {
      isLoadingKnowledge = false;
      _notifyListenersIfActive();
    }
  }

  Future<void> pickAndUploadFiles() async {
    if (_isDisposed || !_canUseChat() || isUploadingFile) return;

    try {
      final result = await FilePicker.pickFiles(
        allowMultiple: true,
        withData: kIsWeb,
      );
      if (_isDisposed || result == null || result.files.isEmpty) return;

      isUploadingFile = true;
      _notifyListenersIfActive();
      var skipped = 0;

      for (final file in result.files) {
        if (_pendingFiles.length >= maxPendingAttachments) {
          skipped++;
          break;
        }
        if (file.size <= 0) {
          skipped++;
          continue;
        }

        _uploadingFileNames.add(file.name);
        _notifyListenersIfActive();
        try {
          final uploaded = await _chatUseCase.uploadChatFile(
            name: file.name,
            size: file.size,
            path: file.path,
            bytes: file.bytes,
          );
          if (_isDisposed) return;
          _addPendingAttachment(uploaded);
        } finally {
          _uploadingFileNames.remove(file.name);
          _notifyListenersIfActive();
        }
      }
      _reportSkippedUploads(skipped, emptyType: 'files');
    } catch (error) {
      if (_isDisposed) return;
      if (kDebugMode) debugPrint('pickAndUploadFiles error: $error');
      _onError(
        ChatErrorMapper.from(
          error,
          operation: ChatOperation.uploadFile,
        ),
        retry: pickAndUploadFiles,
      );
    } finally {
      isUploadingFile = false;
      _notifyListenersIfActive();
    }
  }

  Future<void> pickAndUploadImages(ImageSource source) async {
    if (_isDisposed || !_canUseChat() || isUploadingFile) return;

    try {
      final picker = ImagePicker();
      final images = source == ImageSource.camera
          ? await _pickCameraImage(picker)
          : await picker.pickMultiImage(imageQuality: 85);
      if (_isDisposed || images.isEmpty) return;

      isUploadingFile = true;
      _notifyListenersIfActive();
      var skipped = 0;

      for (final image in images) {
        if (_pendingFiles.length >= maxPendingAttachments) {
          skipped++;
          break;
        }
        final bytes = await image.readAsBytes();
        if (_isDisposed) return;
        if (bytes.isEmpty) {
          skipped++;
          continue;
        }

        _uploadingFileNames.add(image.name);
        _notifyListenersIfActive();
        try {
          final uploaded = await _chatUseCase.uploadChatFile(
            name: image.name,
            size: bytes.length,
            bytes: bytes,
          );
          if (_isDisposed) return;
          _addPendingAttachment(uploaded);
          _cacheImagePreview(uploaded.id, bytes);
        } finally {
          _uploadingFileNames.remove(image.name);
          _notifyListenersIfActive();
        }
      }
      _reportSkippedUploads(skipped, emptyType: 'images');
    } catch (error) {
      if (_isDisposed) return;
      if (kDebugMode) debugPrint('pickAndUploadImages error: $error');
      _onError(
        ChatErrorMapper.from(
          error,
          operation: ChatOperation.uploadImage,
        ),
        retry: () => pickAndUploadImages(source),
      );
    } finally {
      isUploadingFile = false;
      _notifyListenersIfActive();
    }
  }

  Future<List<XFile>> _pickCameraImage(ImagePicker picker) async {
    final image = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );
    return image == null ? <XFile>[] : <XFile>[image];
  }

  void _reportSkippedUploads(int skipped, {required String emptyType}) {
    if (skipped == 0) return;
    if (_pendingFiles.length >= maxPendingAttachments) {
      _onError(
        ChatFailure.validation(
          operation: ChatOperation.uploadFile,
          title: 'Attachment limit reached',
          message: 'Attachment limit reached ($maxPendingAttachments).',
          technicalCode: 'CHAT_ATTACHMENT_LIMIT',
        ),
      );
    } else {
      _onError(
        ChatFailure.validation(
          operation: ChatOperation.uploadFile,
          title: 'Some attachments were skipped',
          message: 'Some empty $emptyType were skipped.',
          technicalCode: 'CHAT_EMPTY_ATTACHMENT',
        ),
      );
    }
  }

  void _cacheImagePreview(String id, Uint8List bytes) {
    if (id.isEmpty) return;
    _imagePreviewBytes.remove(id);
    _imagePreviewBytes[id] = bytes;
    while (_imagePreviewBytes.length > maxCachedImagePreviews) {
      _imagePreviewBytes.remove(_imagePreviewBytes.keys.first);
    }
  }

  void _addPendingAttachment(ChatFile attachment) {
    final key = _attachmentKey(attachment);
    final existingIndex =
        _pendingFiles.indexWhere((file) => _attachmentKey(file) == key);
    if (existingIndex >= 0) {
      _imagePreviewBytes.remove(_pendingFiles[existingIndex].id);
      _pendingFiles[existingIndex] = attachment;
      return;
    }
    _pendingFiles.add(attachment);
  }

  String _attachmentKey(ChatFile file) {
    if (file.isKnowledgeCollection) return 'collection:${file.id}';
    if (file.isKnowledgeFile) return 'knowledge-file:${file.id}';
    return 'upload:${file.name}:${file.size}';
  }

  void clearPendingFiles() {
    if (_isDisposed) return;
    final pendingIds = _pendingFiles.map((file) => file.id).toSet();
    _pendingFiles.clear();
    _imagePreviewBytes.removeWhere((id, _) => pendingIds.contains(id));
    _notifyListenersIfActive();
  }

  void markPendingFilesSent() {
    if (_isDisposed) return;
    _pendingFiles.clear();
    _notifyListenersIfActive();
  }

  void removePendingFile(ChatFile file) {
    if (_isDisposed) return;
    _pendingFiles.removeWhere((item) => item.id == file.id);
    _imagePreviewBytes.remove(file.id);
    _notifyListenersIfActive();
  }

  void toggleKnowledgeCollection(ChatKnowledge knowledge) {
    if (_isDisposed) return;
    _togglePendingAttachment(knowledge.toCollectionAttachment());
  }

  void toggleKnowledgeFile(ChatFile file) {
    if (_isDisposed) return;
    _togglePendingAttachment(file);
  }

  bool isKnowledgeSelected(String id) {
    return _pendingFiles.any((file) => file.id == id);
  }

  void _togglePendingAttachment(ChatFile attachment) {
    final key = _attachmentKey(attachment);
    final index =
        _pendingFiles.indexWhere((file) => _attachmentKey(file) == key);
    if (index >= 0) {
      final removed = _pendingFiles.removeAt(index);
      _imagePreviewBytes.remove(removed.id);
    } else {
      if (_pendingFiles.length >= maxPendingAttachments) {
        _onError(
          ChatFailure.validation(
            operation: ChatOperation.uploadFile,
            title: 'Attachment limit reached',
            message: 'Attachment limit reached ($maxPendingAttachments).',
            technicalCode: 'CHAT_ATTACHMENT_LIMIT',
          ),
        );
        return;
      }
      _addPendingAttachment(attachment);
    }
    _notifyListenersIfActive();
  }

  void reset() {
    if (_isDisposed) return;
    _knowledgeBases.clear();
    _pendingFiles.clear();
    _uploadingFileNames.clear();
    _imagePreviewBytes.clear();
    isLoadingKnowledge = false;
    isUploadingFile = false;
    _notifyListenersIfActive();
  }

  void _notifyListenersIfActive() {
    if (!_isDisposed) notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
