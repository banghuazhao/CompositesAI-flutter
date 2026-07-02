import 'package:infrastructure/token_provider.dart';

import '../entities/user.dart';
import '../entities/expert_upgrade_request.dart';
import '../repositories_abstract/user_repository.dart';

class UserUseCase {
  final UserRepository repository;
  final TokenProvider tokenProvider;

  UserUseCase({required this.repository, required this.tokenProvider});

  Future<User> fetchMe() async {
    return await repository.fetchMe();
  }

  Future<void> updateMe(String newName) async {
    return await repository.updateMe(newName);
  }

  Future<void> deleteAccount() async {
    await repository.deleteAccount();
    await tokenProvider.deleteToken();
  }

  Future<String> submitApplication(String? reason, String? link) async {
    String result = await repository.submitApplication(reason, link);
    return result;
  }

  Future<List<ExpertUpgradeRequest>> fetchPendingExpertRequests() {
    return repository.fetchPendingExpertRequests();
  }

  Future<ExpertUpgradeRequest?> fetchExpertRequestForUser(String userId) {
    return repository.fetchExpertRequestForUser(userId);
  }

  Future<ExpertUpgradeRequest> requestExpertUpgrade(
    String userId,
    String requesterNotes,
  ) {
    return repository.requestExpertUpgrade(userId, requesterNotes);
  }

  Future<void> approveExpertRequest(ExpertUpgradeRequest request) async {
    await repository.updateExpertRequestStatus(request.id, 'approved');
    await repository.updateUserExpertStatus(request.userId, true);
  }

  Future<void> denyExpertRequest(ExpertUpgradeRequest request) async {
    await repository.updateExpertRequestStatus(request.id, 'denied');
  }

  Future<User> getUserById(int userId) async {
    return await repository.getUserById(userId);
  }

  Future<void> becomeExpert(int userId) async {
    await repository.becomeExpert(userId);
  }
}
