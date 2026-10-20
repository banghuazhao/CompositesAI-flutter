import 'dart:async';
import 'dart:typed_data';

import 'package:domain/chat/entities/chat_file.dart';
import 'package:flutter/material.dart';
import 'package:swiftcomp/generated/l10n.dart';

/// A cached attachment preview. Opening it never fetches, uploads or sends data.
///
/// [isAvailable] should capture the attachment's session identity. With
/// [sessionListenable], the preview closes if that session or attachment ends.
class PendingImageAttachment extends StatefulWidget {
  const PendingImageAttachment({
    super.key,
    required this.file,
    required this.bytes,
    this.onRemove,
    this.sessionListenable,
    this.isAvailable,
  });

  final ChatFile file;
  final Uint8List? bytes;
  final VoidCallback? onRemove;
  final Listenable? sessionListenable;
  final bool Function()? isAvailable;

  @override
  State<PendingImageAttachment> createState() => _PendingImageAttachmentState();
}

class _PendingImageAttachmentState extends State<PendingImageAttachment> {
  DialogRoute<void>? _previewRoute;
  NavigatorState? _previewNavigator;
  Listenable? _previewListenable;
  bool Function()? _previewIsAvailable;
  bool _closingPreview = false;

  bool _available(bool Function()? check) {
    try {
      return check?.call() ?? true;
    } catch (_) {
      // A removed provider/session must never keep private image content open.
      return false;
    }
  }

  @override
  void didUpdateWidget(covariant PendingImageAttachment oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.file.id != widget.file.id ||
        oldWidget.file.name != widget.file.name ||
        oldWidget.sessionListenable != widget.sessionListenable) {
      _dismissPreview(_previewRoute);
    } else {
      _checkPreviewAvailability();
    }
  }

  void _checkPreviewAvailability() {
    if (!_available(_previewIsAvailable)) _dismissPreview(_previewRoute);
  }

  void _stopListening() {
    _previewListenable?.removeListener(_checkPreviewAvailability);
    _previewListenable = null;
  }

  void _dismissPreview(DialogRoute<void>? route) {
    if (route == null || route != _previewRoute || _closingPreview) return;
    _closingPreview = true;
    _stopListening();
    final navigator = _previewNavigator;
    // Disposal or a session notification can occur during a widget build.
    // Remove this exact route after that frame, even if another route covers it.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (navigator != null && navigator.mounted && route.isActive) {
        navigator.removeRoute(route);
      }
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  void _openPreview() {
    if (!mounted ||
        _previewRoute != null ||
        !_available(widget.isAvailable) ||
        ModalRoute.of(context)?.isCurrent != true) {
      return;
    }

    FocusManager.instance.primaryFocus?.unfocus();
    final navigator = Navigator.of(context, rootNavigator: true);
    final source = widget.bytes;
    final snapshot = source == null || source.isEmpty
        ? null
        // Web image decoders require a native typed array; a Dart read-only
        // wrapper cannot be converted to a browser BufferSource. This private
        // copy still isolates the preview from changes to the attachment.
        : Uint8List.fromList(source);
    final ImageProvider<Object>? image = snapshot == null
        ? null
        : ResizeImage(
            MemoryImage(snapshot),
            width: 2048,
            height: 2048,
            policy: ResizeImagePolicy.fit,
            allowUpscaling: false,
          );
    final name = widget.file.name;
    late final DialogRoute<void> route;
    route = DialogRoute<void>(
      context: context,
      builder: (_) => _PendingImagePreviewDialog(
        name: name,
        image: image,
        onClose: () => _dismissPreview(route),
      ),
    );
    _previewRoute = route;
    _previewNavigator = navigator;
    // Keep the original session check even if a later build supplies a new one.
    _previewIsAvailable = widget.isAvailable;
    _previewListenable = widget.sessionListenable;
    _previewListenable?.addListener(_checkPreviewAvailability);
    unawaited(navigator.push(route).whenComplete(() {
      if (_previewRoute == route) {
        _stopListening();
        _previewRoute = null;
        _previewNavigator = null;
        _previewIsAvailable = null;
        _closingPreview = false;
      }
      // Each dialog owns its copied bytes; release the decoded preview cache.
      if (image != null) unawaited(image.evict().catchError((_) => false));
    }));
  }

  @override
  void dispose() {
    _dismissPreview(_previewRoute);
    _stopListening();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final strings = S.maybeOf(context);
    final id = widget.file.id;
    final name = widget.file.name;
    final previewLabel = strings?.Chat_preview_image(name) ?? 'Preview $name';
    final unavailable = strings?.Chat_image_preview_unavailable ??
        'Image preview is unavailable.';
    final remove = widget.onRemove;
    final available = widget.isAvailable;
    final bytes = widget.bytes;

    Widget placeholder() => Semantics(
          label: unavailable,
          child: const Icon(Icons.image_not_supported_outlined, size: 32),
        );

    return SizedBox(
      width: 96,
      height: 80,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            width: 80,
            height: 80,
            child: Semantics(
              button: true,
              label: previewLabel,
              child: Tooltip(
                message: previewLabel,
                excludeFromSemantics: true,
                child: Material(
                  color: scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    key: ValueKey('pending-image-preview-${widget.file.id}'),
                    onTap: _openPreview,
                    child: bytes == null || bytes.isEmpty
                        ? Center(child: placeholder())
                        : Image(
                            image: ResizeImage(
                              MemoryImage(bytes),
                              width: 160,
                              height: 160,
                              policy: ResizeImagePolicy.fit,
                              allowUpscaling: false,
                            ),
                            fit: BoxFit.cover,
                            excludeFromSemantics: true,
                            errorBuilder: (_, __, ___) =>
                                Center(child: placeholder()),
                          ),
                  ),
                ),
              ),
            ),
          ),
          if (remove != null)
            Positioned(
              top: 0,
              right: 0,
              child: IconButton(
                key: ValueKey('pending-image-remove-${widget.file.id}'),
                tooltip:
                    strings?.Chat_remove_attachment(name) ?? 'Remove $name',
                constraints:
                    const BoxConstraints.tightFor(width: 48, height: 48),
                padding: const EdgeInsets.all(4),
                onPressed: () {
                  if (mounted &&
                      widget.file.id == id &&
                      widget.file.name == name &&
                      _available(available)) {
                    remove();
                  }
                },
                icon: Align(
                  alignment: Alignment.topRight,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: scheme.inverseSurface,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.close,
                        size: 13, color: scheme.onInverseSurface),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PendingImagePreviewDialog extends StatelessWidget {
  const _PendingImagePreviewDialog({
    required this.name,
    required this.image,
    required this.onClose,
  });

  final String name;
  final ImageProvider<Object>? image;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final strings = S.maybeOf(context);
    final unavailable = strings?.Chat_image_preview_unavailable ??
        'Image preview is unavailable.';
    final height =
        (MediaQuery.sizeOf(context).height * .55).clamp(120.0, 520.0);

    Widget placeholder() => Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.image_not_supported_outlined, size: 48),
                const SizedBox(height: 12),
                Text(unavailable,
                    key: const ValueKey('pending-image-preview-unavailable'),
                    textAlign: TextAlign.center),
              ],
            ),
          ),
        );

    return AlertDialog(
      key: const ValueKey('pending-image-preview-dialog'),
      scrollable: true,
      insetPadding: const EdgeInsets.all(12),
      title: Text(strings?.Chat_image_preview ?? 'Image preview'),
      content: SizedBox(
        width: 700,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(name, maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 12),
            SizedBox(
              height: height,
              child: image == null
                  ? placeholder()
                  : ClipRect(
                      child: InteractiveViewer(
                        minScale: 1,
                        maxScale: 5,
                        child: Center(
                          child: Image(
                            key:
                                const ValueKey('pending-image-preview-content'),
                            image: image!,
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.contain,
                            semanticLabel: name,
                            errorBuilder: (_, __, ___) => placeholder(),
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          key: const ValueKey('pending-image-preview-close'),
          onPressed: onClose,
          child: Tooltip(
            message: strings?.Chat_close_image_preview ?? 'Close image preview',
            child: Text(MaterialLocalizations.of(context).closeButtonLabel),
          ),
        ),
      ],
    );
  }
}
