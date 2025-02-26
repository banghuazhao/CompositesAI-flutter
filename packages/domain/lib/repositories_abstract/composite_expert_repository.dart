import '../entities/composite_expert_request.dart';

abstract class CompositeExpertRepository {
  Future<List<CompositeExpertRequest>> getAllApplications();
  Future<void> deleteApplication(int userId);
}
