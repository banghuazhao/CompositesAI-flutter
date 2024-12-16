import 'package:infrastructure/token_provider.dart';

import '../entities/application.dart';
import '../repositories_abstract/composite_expert_repository.dart';

class CompositeExpertUseCase {
  final CompositeExpertRepository repository;
  final TokenProvider tokenProvider;

  CompositeExpertUseCase({required this.repository, required this.tokenProvider});

  Future<List<CompositeExpertRequest>> getAllApplications() async {
    return await repository.getAllApplications();
  }

  Future<void> deleteApplication(int userId) async {
    await repository.deleteApplication(userId);
  }
}
