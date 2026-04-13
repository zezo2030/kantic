import '../repositories/notifications_repository.dart';

class DeleteNotificationUseCase {
  final NotificationsRepository repository;

  DeleteNotificationUseCase({required this.repository});

  Future<void> call(String id) async {
    return await repository.deleteNotification(id);
  }
}

class DeleteAllNotificationsUseCase {
  final NotificationsRepository repository;

  DeleteAllNotificationsUseCase({required this.repository});

  Future<void> call() async {
    return await repository.deleteAllNotifications();
  }
}
