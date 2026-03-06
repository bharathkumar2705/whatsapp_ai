import '../entities/status_entity.dart';

abstract class IStatusRepository {
  Future<void> postStatus(StatusEntity status);
  Stream<List<StatusEntity>> getRecentStatuses();
  Future<void> markStatusSeen(String statusId, String uid);
}
