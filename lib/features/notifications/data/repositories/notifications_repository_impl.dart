import '../../data/datasources/notifications_remote_datasource.dart';
import '../../domain/repositories/notifications_repository.dart';
import '../models/notification_model.dart';

class NotificationsRepositoryImpl implements NotificationsRepository {
  final NotificationsRemoteDataSource remoteDataSource;

  NotificationsRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<NotificationModel>> getNotifications({
    int page = 1,
    int limit = 20,
    bool? isRead,
  }) async {
    return await remoteDataSource.getNotifications(
      page: page,
      limit: limit,
      isRead: isRead,
    );
  }

  @override
  Future<int> getUnreadCount() async {
    return await remoteDataSource.getUnreadCount();
  }

  @override
  Future<void> markAsRead(String id) async {
    return await remoteDataSource.markAsRead(id);
  }

  @override
  Future<void> markAllAsRead() async {
    return await remoteDataSource.markAllAsRead();
  }

  @override
  Future<void> deleteNotification(String id) async {
    return await remoteDataSource.deleteNotification(id);
  }

  @override
  Future<void> deleteAllNotifications() async {
    return await remoteDataSource.deleteAllNotifications();
  }
}
