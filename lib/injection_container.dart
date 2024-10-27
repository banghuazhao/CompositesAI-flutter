import 'package:data/data_sources/function_tools_data_source.dart';
import 'package:data/data_sources/open_ai_data_source.dart';
import 'package:data/repositories/auth_repository.dart';
import 'package:data/repositories/chat_repository_impl.dart';
import 'package:data/repositories/chat_session_repository_imp.dart';
import 'package:domain/domain.dart';
import 'package:domain/repositories_abstract/auth_repository.dart';
import 'package:domain/usecases/auth_usecase.dart';
import 'package:domain/usecases/function_tools_usecase.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:swiftcomp/presentation/more/NewLogin/viewModels/login_view_model.dart';
import 'package:swiftcomp/presentation/more/NewLogin/viewModels/signup_view_model.dart';
import 'presentation/chat/viewModels/chat_view_model.dart';

final sl = GetIt.instance;

void initInjection() {
  // ViewModels
  sl.registerFactory<ChatViewModel>(() => ChatViewModel(
      chatUseCase: sl(), chatSessionUseCase: sl(), functionToolsUseCase: sl()));
  sl.registerFactory<LoginViewModel>(() => LoginViewModel(authUseCase: sl()));
  sl.registerFactory<SignupViewModel>(() => SignupViewModel(
      authUseCase: sl()));


  // Use Cases
  sl.registerLazySingleton<ChatUseCase>(
      () => ChatUseCase(chatRepository: sl()));

  sl.registerLazySingleton<ChatSessionUseCase>(
      () => ChatSessionUseCase(repository: sl()));

  sl.registerLazySingleton<FunctionToolsUseCase>(() => FunctionToolsUseCase());

  sl.registerLazySingleton<AuthUseCase>(() => AuthUseCase(repository: sl()));

  // Repositories
  sl.registerLazySingleton<ChatRepository>(() =>
      ChatRepositoryImp(openAIDataSource: sl(), functionToolsDataSource: sl()));
  sl.registerLazySingleton<ChatSessionRepository>(
      () => ChatSessionRepositoryImpl());
  sl.registerLazySingleton<AuthRepository>(
          () => AuthRepositoryImpl(client: sl()));

  // Data Sources
  sl.registerLazySingleton<OpenAIDataSource>(
      () => ChatRemoteDataSourceImpl(client: sl()));
  sl.registerLazySingleton<FunctionToolsDataSource>(
      () => FunctionToolsDataSourceImp());

  // External
  sl.registerLazySingleton(() => http.Client());
}
