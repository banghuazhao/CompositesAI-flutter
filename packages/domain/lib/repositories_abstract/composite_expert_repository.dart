import '../entities/application.dart';

abstract class CompositeExpertRepository {
  Future<List<CompositeExpertRequest>> getAllApplications();
  Future<void> deleteApplication(int userId);
}
