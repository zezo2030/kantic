import '../repositories/notifications_repository.dart';

class MarkNotificationReadUseCase {
  final NotificationsRepository repository;

  MarkNotificationReadUseCase({required this.repository});

  Future<void> call(String id) async {
    return await repository.markAsRead(id);
  }
}

class MarkAllNotificationsReadUseCase {
  final NotificationsRepository repository;

  MarkAllNotificationsReadUseCase({required this.repository});

  Future<void> call() async {
    return await repository.markAllAsRead();
  }
}
