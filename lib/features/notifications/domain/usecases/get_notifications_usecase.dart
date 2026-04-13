import '../repositories/notifications_repository.dart';
import '../../data/models/notification_model.dart';

class GetNotificationsUseCase {
  final NotificationsRepository repository;

  GetNotificationsUseCase({required this.repository});

  Future<List<NotificationModel>> call({
    int page = 1,
    int limit = 20,
    bool? isRead,
  }) async {
    return await repository.getNotifications(
      page: page,
      limit: limit,
      isRead: isRead,
    );
  }
}
