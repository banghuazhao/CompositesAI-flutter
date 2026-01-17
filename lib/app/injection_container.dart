import 'package:data/repositories/functional_call_repository_impl.dart';
import 'package:domain/repositories_abstract/functional_call_repository.dart';
import 'package:domain/use_cases/functional_call_use_case.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;

import 'package:data/repositories/composites_tools_repository_impl.dart';
import 'package:data/repositories/composite_expert_repository_impl.dart';
import 'package:data/repositories/auth_repository_impl.dart';
import 'package:data/repositories/chat_session_repository_imp.dart';
import 'package:data/repositories/user_repository_impl.dart';
import 'package:data/repositories/threads_repository_impl.dart';
import 'package:data/repositories/thread_runs_repository_impl.dart';

import 'package:domain/domain.dart';
import 'package:domain/repositories_abstract/composites_tools_repository.dart';
import 'package:domain/repositories_abstract/composite_expert_repository.dart';
import 'package:domain/repositories_abstract/auth_repository.dart';
import 'package:domain/repositories_abstract/user_repository.dart';
import 'package:domain/repositories_abstract/thread_runs_repository.dart';
import 'package:domain/repositories_abstract/threads_repository.dart';

import 'package:domain/use_cases/composites_tools_use_case.dart';
import 'package:domain/use_cases/auth_use_case.dart';
import 'package:domain/use_cases/composite_expert_use_case.dart';
import 'package:domain/use_cases/threads_use_case.dart';
import 'package:domain/use_cases/user_use_case.dart';
import 'package:domain/use_cases/thread_runs_use_case.dart';

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
        chatSessionUseCase: sl(),
        authUseCase: sl(),
        userUserCase: sl(),
        threadsUseCase: sl(),
        threadRunsUseCase: sl(),
        toolsUseCase: sl(),
        functionalCallUseCase: sl(),
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
  sl.registerLazySingleton<ChatSessionUseCase>(
      () => ChatSessionUseCaseImpl(repository: sl()));
  sl.registerLazySingleton<AuthUseCase>(
      () => AuthUseCaseImpl(repository: sl()));
  sl.registerLazySingleton<UserUseCase>(
      () => UserUseCase(repository: sl(), tokenProvider: sl()));
  sl.registerLazySingleton<CompositeExpertUseCase>(
      () => CompositeExpertUseCase(repository: sl(), tokenProvider: sl()));
  sl.registerLazySingleton<CompositesToolsUseCase>(
      () => CompositesToolsUseCaseImpl(repository: sl(), tokenProvider: sl()));
  sl.registerFactory<ThreadsUseCase>(
      () => ThreadsUseCaseImpl(repository: sl()));
  sl.registerFactory<ThreadRunsUseCase>(
      () => ThreadRunsUseCaseImpl(threadRunsRepository: sl()));
  sl.registerFactory<FunctionalCallUseCase>(
      () => FunctionalCallUseCaseImpl(repository: sl()));

  // Repositories
  sl.registerLazySingleton<ChatSessionRepository>(
      () => ChatSessionRepositoryImpl());
  sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(
      client: sl(),
      authClient: sl(),
      apiEnvironment: sl(),
      tokenProvider: sl()));
  sl.registerLazySingleton<UserRepository>(
      () => UserRepositoryImpl(authClient: sl(), apiEnvironment: sl()));
  sl.registerLazySingleton<CompositeExpertRepository>(() =>
      CompositeExpertRepositoryImpl(authClient: sl(), apiEnvironment: sl()));
  sl.registerLazySingleton<CompositesToolsRepository>(() =>
      CompositesToolsRepositoryImpl(authClient: sl(), apiEnvironment: sl()));
  sl.registerFactory<ThreadsRepository>(
      () => ThreadsRepositoryImpl(client: sl()));
  sl.registerFactory<ThreadRunsRepository>(() => ThreadRunsRepositoryImpl());
  sl.registerFactory<FunctionalCallRepository>(
      () => FunctionalCallRepositoryImpl());

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
