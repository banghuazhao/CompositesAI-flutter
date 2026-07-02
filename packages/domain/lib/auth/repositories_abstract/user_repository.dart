import '../entities/user.dart';
import '../entities/expert_upgrade_request.dart';

abstract class UserRepository {
  Future<User> fetchMe();
  Future<void> updateMe(String newName);
  Future<void> deleteAccount();
  Future<String> submitApplication(String? reason, String? link);
  Future<List<ExpertUpgradeRequest>> fetchPendingExpertRequests();
  Future<ExpertUpgradeRequest?> fetchExpertRequestForUser(String userId);
  Future<ExpertUpgradeRequest> requestExpertUpgrade(
      String userId, String requesterNotes);
  Future<void> updateExpertRequestStatus(String requestId, String status);
  Future<void> updateUserExpertStatus(String userId, bool isExpert);
  Future<User> getUserById(int userId);
  Future<void> becomeExpert(int userId);
}
