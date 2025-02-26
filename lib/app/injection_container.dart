import 'package:data/repositories/functional_call_repository_impl.dart';
import 'package:domain/repositories_abstract/functional_call_repository.dart';
import 'package:domain/usecases/functional_call_usecase.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;


import 'package:data/repositories/composites_tools_repository_impl.dart';
import 'package:data/repositories/composite_expert_repository_impl.dart';
import 'package:data/repositories/auth_repository_impl.dart';
import 'package:data/repositories/chat_session_repository_imp.dart';
import 'package:data/repositories/user_repository_impl.dart';
import 'package:data/repositories/threads_repository_impl.dart';
import 'package:data/repositories/messages_repository_impl.dart';
import 'package:data/repositories/thread_runs_repository_impl.dart';

import 'package:domain/domain.dart';
import 'package:domain/repositories_abstract/composites_tools_repository.dart';
import 'package:domain/repositories_abstract/composite_expert_repository.dart';
import 'package:domain/repositories_abstract/auth_repository.dart';
import 'package:domain/repositories_abstract/user_repository.dart';
import 'package:domain/repositories_abstract/thread_runs_repository.dart';
import 'package:domain/repositories_abstract/threads_repository.dart';
import 'package:domain/repositories_abstract/messages_repository.dart';

import 'package:domain/usecases/composites_tools_usecase.dart';
import 'package:domain/usecases/auth_usecase.dart';
import 'package:domain/usecases/composite_expert_usecase.dart';
import 'package:domain/usecases/threads_usecase.dart';
import 'package:domain/usecases/user_usercase.dart';
import 'package:domain/usecases/messages_usecase.dart';
import 'package:domain/usecases/thread_runs_usecase.dart';

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
import 'package:swiftcomp/presentation/chat/viewModels/chat_view_model.dart';
import 'package:swiftcomp/presentation/settings/viewModels/qa_settings_view_model.dart';

final sl = GetIt.instance;

void initInjection() {
  // ViewModels
  sl.registerFactory<ChatViewModel>(() => ChatViewModel(
        chatSessionUseCase: sl(),
        authUseCase: sl(),
        userUserCase: sl(),
        messagesUseCase: sl(),
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
      () => AuthUseCaseImpl(repository: sl(), tokenProvider: sl()));
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
  sl.registerFactory<MessagesUseCase>(
      () => MessagesUseCaseImpl(repository: sl()));
  sl.registerFactory<FunctionalCallUseCase>(
      () => FunctionalCallUseCaseImpl(repository: sl()));

  // Repositories
  sl.registerLazySingleton<ChatSessionRepository>(
      () => ChatSessionRepositoryImpl());
  sl.registerLazySingleton<AuthRepository>(() =>
      AuthRepositoryImpl(client: sl(), authClient: sl(), apiEnvironment: sl()));
  sl.registerLazySingleton<UserRepository>(
      () => UserRepositoryImpl(authClient: sl(), apiEnvironment: sl()));
  sl.registerLazySingleton<CompositeExpertRepository>(() =>
      CompositeExpertRepositoryImpl(authClient: sl(), apiEnvironment: sl()));
  sl.registerLazySingleton<CompositesToolsRepository>(() =>
      CompositesToolsRepositoryImpl(authClient: sl(), apiEnvironment: sl()));
  sl.registerFactory<ThreadsRepository>(
      () => ThreadsRepositoryImpl(client: sl()));
  sl.registerFactory<ThreadRunsRepository>(() => ThreadRunsRepositoryImpl());
  sl.registerFactory<MessagesRepository>(
      () => MessagesRepositoryImpl(client: sl()));
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
