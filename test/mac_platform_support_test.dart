import 'dart:async';

import 'package:domain/auth/entities/user.dart';
import 'package:domain/auth/mocks/auth_use_case_mock.dart';
import 'package:domain/auth/mocks/user_use_case_mock.dart';
import 'package:domain/chat/chat_use_case.dart';
import 'package:domain/chat/entities/chat_file.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
// The plugin interface lets these tests verify that unsupported capture never
// reaches the native picker, while supported sources keep working.
// ignore: depend_on_referenced_packages
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:infrastructure/mocks/apple_sign_in_service_mock.dart';
import 'package:infrastructure/mocks/google_sign_in_service_mock.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swiftcomp/app/injection_container.dart';
import 'package:swiftcomp/presentation/auth/login_page.dart';
import 'package:swiftcomp/presentation/auth/login_view_model.dart';
import 'package:swiftcomp/presentation/chat/controllers/chat_attachment_controller.dart';
import 'package:swiftcomp/presentation/chat/model/chat_error.dart';
import 'package:swiftcomp/presentation/chat/viewModels/chat_view_model.dart';
import 'package:swiftcomp/presentation/chat/views/chat_screen.dart';

class _MemoryImage extends XFile {
  _MemoryImage(this.name, List<int> bytes)
      : _bytes = Uint8List.fromList(bytes),
        super('');

  @override
  final String name;
  final Uint8List _bytes;

  @override
  String get path => 'memory/$name';

  @override
  Future<Uint8List> readAsBytes() async => Uint8List.fromList(_bytes);
}

class _Picker extends ImagePickerPlatform {
  final sources = <ImageSource>[];
  int galleryCalls = 0;
  XFile? image;

  @override
  Future<XFile?> getImageFromSource({
    required ImageSource source,
    ImagePickerOptions options = const ImagePickerOptions(),
  }) async {
    sources.add(source);
    return image;
  }

  @override
  Future<List<XFile>> getMultiImageWithOptions({
    MultiImagePickerOptions options = const MultiImagePickerOptions(),
  }) async {
    galleryCalls++;
    return image == null ? [] : [image!];
  }
}

class _UseCase extends Fake implements ChatUseCase {
  final uploads = <List<int>>[];

  @override
  Future<ChatFile> uploadChatFile({
    required String name,
    required int size,
    String? path,
    List<int>? bytes,
  }) async {
    uploads.add(List.of(bytes!));
    return ChatFile(id: 'uploaded-${uploads.length}', name: name, url: '');
  }
}

class _ScreenModel extends ChatViewModel {
  _ScreenModel()
      : super(
          chatUseCase: _UseCase(),
          authUseCase: MockAuthUseCase(),
          userUserCase: MockUserUseCase(),
        ) {
    isLoggedIn = true;
    user = User(id: 'mac-test', email: 'mac@example.test');
  }

  final picked = <ImageSource>[];

  @override
  Future<void> fetchAuthSessionNew() async {}
  @override
  Future<void> fetchChats() async {}
  @override
  Future<void> fetchTools() async {}
  @override
  Future<void> pickAndUploadImages(ImageSource source) async {
    picked.add(source);
  }
}

class _LoginModel extends LoginViewModel {
  _LoginModel()
      : super(
          authUseCase: MockAuthUseCase(),
          appleSignInService: MockAppleSignInService(),
          googleSignInService: MockGoogleSignInService(),
        );

  final apple = Completer<void>();
  int appleCalls = 0;

  @override
  Future<void> signInWithApple() {
    appleCalls++;
    return apple.future;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late ImagePickerPlatform previousPicker;
  late _Picker picker;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    previousPicker = ImagePickerPlatform.instance;
    picker = _Picker();
    ImagePickerPlatform.instance = picker;
    await sl.reset();
  });
  tearDown(() async {
    ImagePickerPlatform.instance = previousPicker;
    await sl.reset();
  });

  testWidgets(
      'Mac direct camera request reports unavailable without a plugin call',
      (tester) async {
    final failures = <ChatFailure>[];
    final useCase = _UseCase();
    final controller = ChatAttachmentController(
      chatUseCase: useCase,
      canUseChat: () => true,
      onError: (failure, {retry}) {
        failures.add(failure);
        expect(retry, isNull);
      },
    );
    addTearDown(controller.dispose);
    await controller.pickAndUploadImages(ImageSource.camera);
    expect(picker.sources, isEmpty);
    expect(picker.galleryCalls, 0);
    expect(useCase.uploads, isEmpty);
    expect(controller.pendingFiles, isEmpty);
    expect(controller.isUploadingFile, isFalse);
    expect(failures.single.technicalCode, 'CHAT_CAMERA_UNAVAILABLE');
    expect(tester.takeException(), isNull);
  }, variant: TargetPlatformVariant.only(TargetPlatform.macOS), skip: kIsWeb);

  for (final platform in [
    TargetPlatform.macOS,
    TargetPlatform.android,
    TargetPlatform.iOS,
  ]) {
    testWidgets('$platform gallery still uploads the exact selected bytes',
        (tester) async {
      final bytes = Uint8List.fromList([1, 2, 3, 4]);
      picker.image = _MemoryImage('sample.png', bytes);
      final failures = <ChatFailure>[];
      final useCase = _UseCase();
      final controller = ChatAttachmentController(
        chatUseCase: useCase,
        canUseChat: () => true,
        onError: (failure, {retry}) => failures.add(failure),
      );
      addTearDown(controller.dispose);
      await tester
          .runAsync(() => controller.pickAndUploadImages(ImageSource.gallery));
      expect(picker.galleryCalls, 1);
      expect(useCase.uploads, [bytes]);
      expect(controller.pendingFiles.single.name, 'sample.png');
      expect(controller.imagePreviewBytes.values.single, bytes);
      expect(failures, isEmpty);
      expect(tester.takeException(), isNull);
    }, variant: TargetPlatformVariant.only(platform));
  }

  for (final platform in [TargetPlatform.android, TargetPlatform.iOS]) {
    testWidgets('$platform camera still reaches the picker and uploads',
        (tester) async {
      picker.image = _MemoryImage('camera.png', [8, 9]);
      final useCase = _UseCase();
      final controller = ChatAttachmentController(
        chatUseCase: useCase,
        canUseChat: () => true,
        onError: (failure, {retry}) => fail(failure.message),
      );
      addTearDown(controller.dispose);
      await tester
          .runAsync(() => controller.pickAndUploadImages(ImageSource.camera));
      expect(picker.sources, [ImageSource.camera]);
      expect(useCase.uploads, [
        [8, 9]
      ]);
      expect(controller.pendingFiles.single.name, 'camera.png');
    }, variant: TargetPlatformVariant.only(platform));
  }

  for (final platform in [
    TargetPlatform.macOS,
    TargetPlatform.android,
    TargetPlatform.iOS,
  ]) {
    testWidgets(
        '$platform attachment sheet keeps usable image and file actions',
        (tester) async {
      final model = _ScreenModel();
      try {
        await tester.pumpWidget(ChangeNotifierProvider<ChatViewModel>.value(
          value: model,
          child: const MaterialApp(home: ChatScreen()),
        ));
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('Add attachment'));
        await tester.pumpAndSettle();
        expect(find.text('Files'), findsOneWidget);
        expect(find.text('Photo Library'), findsOneWidget);
        expect(
            find.text('Camera'),
            kIsWeb || platform != TargetPlatform.macOS
                ? findsOneWidget
                : findsNothing);
        await tester.tap(find.text('Photo Library'));
        await tester.pumpAndSettle();
        expect(model.picked, [ImageSource.gallery]);
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
        model.dispose();
      }
    }, variant: TargetPlatformVariant.only(platform));
  }

  testWidgets('Mac Apple button dispatches sign-in and handles native failure',
      (tester) async {
    late _LoginModel model;
    sl.registerFactory<LoginViewModel>(() => model = _LoginModel());
    await tester.pumpWidget(const MaterialApp(home: LoginPage()));
    await tester.pumpAndSettle();
    final apple = find.byKey(const Key('login_apple'));
    await tester.ensureVisible(apple);
    await tester.pumpAndSettle();
    await tester.tap(apple);
    await tester.pump();
    expect(model.appleCalls, 1);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    model.apple.completeError(MissingPluginException('native unavailable'));
    await tester.pumpAndSettle();
    expect(find.text('Apple sign-in could not be completed. Please try again.'),
        findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  }, variant: TargetPlatformVariant.only(TargetPlatform.macOS), skip: kIsWeb);
}
