import '../entities/application.dart';

abstract class CompositeExpertRepository {
  Future<List<CompositeExpertRequest>> getAllApplications();
}
