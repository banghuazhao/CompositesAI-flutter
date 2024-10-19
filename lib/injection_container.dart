import 'package:data/data_sources/function_tools_data_source.dart';
import 'package:data/data_sources/open_ai_data_source.dart';
import 'package:data/repositories/chat_repository_impl.dart';
import 'package:data/repositories/chat_session_repository_imp.dart';
import 'package:domain/domain.dart';
import 'package:domain/usecases/function_tools_usecase.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'presentation/chat/viewModels/chat_view_model.dart';

final sl = GetIt.instance;

void initInjection() {
  // ViewModels
  sl.registerFactory<ChatViewModel>(() => ChatViewModel(
      chatUseCase: sl(), chatSessionUseCase: sl(), functionToolsUseCase: sl()));

  // Use Cases
  sl.registerLazySingleton<ChatUseCase>(
      () => ChatUseCase(chatRepository: sl()));

  sl.registerLazySingleton<ChatSessionUseCase>(
      () => ChatSessionUseCase(repository: sl()));

  sl.registerLazySingleton<FunctionToolsUseCase>(() => FunctionToolsUseCase());

  // Repositories
  sl.registerLazySingleton<ChatRepository>(() =>
      ChatRepositoryImp(openAIDataSource: sl(), functionToolsDataSource: sl()));
  sl.registerLazySingleton<ChatSessionRepository>(
      () => ChatSessionRepositoryImpl());

  // Data Sources
  sl.registerLazySingleton<OpenAIDataSource>(
      () => ChatRemoteDataSourceImpl(client: sl()));
  sl.registerLazySingleton<FunctionToolsDataSource>(
      () => FunctionToolsDataSourceImp());

  // External
  sl.registerLazySingleton(() => http.Client());
}
