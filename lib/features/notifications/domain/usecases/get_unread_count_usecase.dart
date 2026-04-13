import '../repositories/notifications_repository.dart';

class GetUnreadCountUseCase {
  final NotificationsRepository repository;

  GetUnreadCountUseCase({required this.repository});

  Future<int> call() async {
    return await repository.getUnreadCount();
  }
}
