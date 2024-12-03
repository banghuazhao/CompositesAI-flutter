import 'package:data/data_sources/function_tools_data_source.dart';
import 'package:data/data_sources/open_ai_data_source.dart';
import 'package:data/repositories/auth_repository_impl.dart';
import 'package:data/repositories/chat_repository_impl.dart';
import 'package:data/repositories/chat_session_repository_imp.dart';
import 'package:data/repositories/user_repository_impl.dart';

import 'package:domain/repositories_abstract/auth_repository.dart';
import 'package:domain/repositories_abstract/user_repository.dart';

import 'package:domain/domain.dart';
import 'package:domain/usecases/auth_usecase.dart';
import 'package:domain/usecases/function_tools_usecase.dart';
import 'package:domain/usecases/user_usercase.dart';
import 'package:get_it/get_it.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:infrastructure/api_environment.dart';
import 'package:infrastructure/apple_sign_in_service.dart';
import 'package:infrastructure/authenticated_http_client.dart';
import 'package:infrastructure/feature_flag_provider.dart';
import 'package:infrastructure/google_sign_in_service.dart';
import 'package:infrastructure/token_provider.dart';
import 'package:swiftcomp/presentation/settings/viewModels/forget_password_view_model.dart';
import 'package:swiftcomp/presentation/settings/viewModels/login_view_model.dart';
import 'package:swiftcomp/presentation/settings/viewModels/settings_view_model.dart';
import 'package:swiftcomp/presentation/settings/viewModels/signup_view_model.dart';
import 'package:swiftcomp/presentation/settings/viewModels/update_password_view_model.dart';
import 'package:swiftcomp/presentation/settings/viewModels/user_profile_view_model.dart';
import '../presentation/chat/viewModels/chat_view_model.dart';
import '../presentation/settings/viewModels/qa_settings_view_model.dart';

final sl = GetIt.instance;

void initInjection() {
  // ViewModels
  sl.registerFactory<ChatViewModel>(() => ChatViewModel(
      chatUseCase: sl(), chatSessionUseCase: sl(), functionToolsUseCase: sl(), authUseCase: sl()));
  sl.registerFactory<LoginViewModel>(
      () => LoginViewModel(authUseCase: sl(), appleSignInService: sl(), googleSignInService: sl()));
  sl.registerFactory<SignupViewModel>(() => SignupViewModel(authUseCase: sl()));
  sl.registerFactory<SettingsViewModel>(() => SettingsViewModel(
      authUseCase: sl(), userUserCase: sl(), featureFlagProvider: sl()));
  sl.registerFactory<QASettingsViewModel>(() => QASettingsViewModel(
      featureFlagProvider: sl(),
      apiEnvironment: sl(),
      authUseCase: sl()));
  sl.registerFactory<UserProfileViewModel>(
      () => UserProfileViewModel(authUseCase: sl(), userUseCase: sl()));
  sl.registerFactory<ForgetPasswordViewModel>(
      () => ForgetPasswordViewModel(authUseCase: sl()));
  sl.registerFactory<UpdatePasswordViewModel>(
      () => UpdatePasswordViewModel(authUseCase: sl()));

  // Use Cases
  sl.registerLazySingleton<ChatUseCase>(
      () => ChatUseCase(chatRepository: sl()));

  sl.registerLazySingleton<ChatSessionUseCase>(
      () => ChatSessionUseCase(repository: sl()));

  sl.registerLazySingleton<FunctionToolsUseCase>(() => FunctionToolsUseCase());

  sl.registerLazySingleton<AuthUseCase>(
      () => AuthUseCaseImpl(repository: sl(), tokenProvider: sl()));
  sl.registerLazySingleton<UserUseCase>(
      () => UserUseCase(repository: sl(), tokenProvider: sl()));

  // Repositories
  sl.registerLazySingleton<ChatRepository>(() =>
      ChatRepositoryImp(openAIDataSource: sl(), functionToolsDataSource: sl()));
  sl.registerLazySingleton<ChatSessionRepository>(
      () => ChatSessionRepositoryImpl());
  sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(
      client: sl(), authClient: sl(), apiEnvironment: sl()));
  sl.registerLazySingleton<UserRepository>(() =>
      UserRepositoryImpl(authClient: sl(), apiEnvironment: sl()));

  // Data Sources
  sl.registerLazySingleton<OpenAIDataSource>(
      () => ChatRemoteDataSourceImpl(client: sl()));
  sl.registerLazySingleton<FunctionToolsDataSource>(
      () => FunctionToolsDataSourceImp());

  // Infrastructure
  sl.registerLazySingleton(() => http.Client());
  sl.registerLazySingleton<AuthenticatedHttpClient>(
      () => AuthenticatedHttpClient(sl(), sl()));
  sl.registerLazySingleton<APIEnvironment>(
          () => APIEnvironment());
  sl.registerLazySingleton<TokenProvider>(() => TokenProvider());
  sl.registerLazySingleton<FeatureFlagProvider>(() => FeatureFlagProvider());
  sl.registerLazySingleton<AppleSignInService>(() => AppleSignInServiceImpl());
  sl.registerLazySingleton<GoogleSignInService>(() => GoogleSignInServiceImpl());
}
