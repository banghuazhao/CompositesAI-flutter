import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:swiftcomp/data/repositories/chat_session_repository_imp.dart';
import 'package:swiftcomp/domain/repositories_abstract/chat_session_repository.dart';
import 'package:swiftcomp/domain/usecases/chat_session_usecase.dart';
import 'package:swiftcomp/domain/usecases/chat_usecase.dart';
import 'data/data_sources/chat_remote_data_source.dart';
import 'data/repositories/chat_repository_impl.dart';
import 'domain/repositories_abstract/chat_repository.dart';
import 'home/chat/viewModels/chat_view_model.dart';

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
