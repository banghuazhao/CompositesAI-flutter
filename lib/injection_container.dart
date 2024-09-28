import 'package:data/data_sources/chat_remote_data_source.dart';
import 'package:data/repositories/chat_repository_impl.dart';
import 'package:data/repositories/chat_session_repository_imp.dart';
import 'package:domain/repositories_abstract/chat_repository.dart';
import 'package:domain/repositories_abstract/chat_session_repository.dart';
import 'package:domain/usecases/chat_session_usecase.dart';
import 'package:domain/usecases/chat_usecase.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'presentation/chat/viewModels/chat_view_model.dart';

final sl = GetIt.instance;

void initInjection() {
  // ViewModels
  sl.registerFactory<ChatViewModel>(() => ChatViewModel(sl(), sl()));

  // Use Cases
  sl.registerLazySingleton<ChatUseCase>(() => ChatUseCase(sl()));

  sl.registerLazySingleton<ChatSessionUseCase>(() => ChatSessionUseCase(sl()));

  // Repositories
  sl.registerLazySingleton<ChatRepository>(
      () => ChatRepositoryImp(remoteDataSource: sl()));
  sl.registerLazySingleton<ChatSessionRepository>(
      () => ChatSessionRepositoryImpl());

  // Data Sources
  sl.registerLazySingleton<ChatRemoteDataSource>(
      () => ChatRemoteDataSourceImpl(client: sl()));

  // External
  sl.registerLazySingleton(() => http.Client());
}
