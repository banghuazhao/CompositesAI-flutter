import 'package:data/chat/chat_repository_imp.dart';
import 'package:domain/chat/chat_repository.dart';
import 'package:domain/chat/chat_use_case.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;

import 'package:data/auth/repositories/auth_repository_impl.dart';
import 'package:data/auth/repositories/user_repository_impl.dart';

import 'package:domain/domain.dart';
import 'package:domain/auth/repositories_abstract/auth_repository.dart';
import 'package:domain/auth/repositories_abstract/user_repository.dart';

import 'package:domain/auth/use_cases/auth_use_case.dart';
import 'package:domain/auth/use_cases/user_use_case.dart';

import 'package:infrastructure/api_environment.dart';
import 'package:infrastructure/apple_sign_in_service.dart';
import 'package:infrastructure/authenticated_http_client.dart';
import 'package:infrastructure/feature_flag_provider.dart';
import 'package:infrastructure/google_sign_in_service.dart';
import 'package:infrastructure/token_provider.dart';

import 'package:swiftcomp/presentation/auth/forget_password_view_model.dart';
import 'package:swiftcomp/presentation/auth/login_view_model.dart';
import 'package:swiftcomp/presentation/settings/viewModels/settings_view_model.dart';
import 'package:swiftcomp/presentation/auth/signup_view_model.dart';
import 'package:swiftcomp/presentation/auth/update_password_view_model.dart';
import 'package:swiftcomp/presentation/chat/viewModels/chat_view_model.dart';
import 'package:swiftcomp/presentation/settings/viewModels/qa_settings_view_model.dart';

final sl = GetIt.instance;

void initInjection() {
  // ViewModels
  sl.registerFactory<ChatViewModel>(() => ChatViewModel(
        chatUseCase: sl(),
        authUseCase: sl(),
        userUserCase: sl(),
      ));
  sl.registerFactory<LoginViewModel>(() => LoginViewModel(
      authUseCase: sl(), appleSignInService: sl(), googleSignInService: sl()));
  sl.registerFactory<SignupViewModel>(() => SignupViewModel(authUseCase: sl()));
  sl.registerLazySingleton<SettingsViewModel>(() => SettingsViewModel(
      authUseCase: sl(), userUserCase: sl(), featureFlagProvider: sl()));
  sl.registerFactory<QASettingsViewModel>(() => QASettingsViewModel(
      featureFlagProvider: sl(), apiEnvironment: sl(), authUseCase: sl()));
  sl.registerFactory<ForgetPasswordViewModel>(
      () => ForgetPasswordViewModel(authUseCase: sl()));
  sl.registerFactory<UpdatePasswordViewModel>(
      () => UpdatePasswordViewModel(authUseCase: sl()));

  // Use Cases
  sl.registerLazySingleton<ChatUseCase>(
      () => ChatUseCaseImpl(repository: sl()));
  sl.registerLazySingleton<AuthUseCase>(
      () => AuthUseCaseImpl(repository: sl()));
  sl.registerLazySingleton<UserUseCase>(
      () => UserUseCase(repository: sl(), tokenProvider: sl()));

  // Repositories
  sl.registerLazySingleton<ChatRepository>(() => ChatRepositoryImpl(
      authClient: sl(), apiEnvironment: sl(), tokenProvider: sl()));
  sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(
      client: sl(),
      authClient: sl(),
      apiEnvironment: sl(),
      tokenProvider: sl()));
  sl.registerLazySingleton<UserRepository>(
      () => UserRepositoryImpl(authClient: sl(), apiEnvironment: sl()));

  // Data Sources

  // Infrastructure
  sl.registerLazySingleton(() => http.Client());
  sl.registerLazySingleton<AuthenticatedHttpClient>(
      () => AuthenticatedHttpClient(sl(), sl()));
  sl.registerLazySingleton<APIEnvironment>(() => APIEnvironment());
  sl.registerLazySingleton<TokenProvider>(() => TokenProvider());
  sl.registerLazySingleton<FeatureFlagProvider>(() => FeatureFlagProvider());
  sl.registerLazySingleton<AppleSignInService>(() => AppleSignInServiceImpl());
  sl.registerLazySingleton<GoogleSignInService>(
      () => GoogleSignInServiceImpl());
}
