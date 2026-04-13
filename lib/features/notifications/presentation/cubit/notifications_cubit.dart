import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_notifications_usecase.dart';
import '../../domain/usecases/get_unread_count_usecase.dart';
import '../../domain/usecases/mark_notification_read_usecase.dart';
import '../../domain/usecases/delete_notification_usecase.dart';
import '../../data/models/notification_model.dart';

// States
abstract class NotificationsState {}

class NotificationsInitial extends NotificationsState {}

class NotificationsLoading extends NotificationsState {}

class NotificationsLoaded extends NotificationsState {
  final List<NotificationModel> notifications;
  final int unreadCount;

  NotificationsLoaded({required this.notifications, required this.unreadCount});
}

class NotificationsError extends NotificationsState {
  final String message;

  NotificationsError(this.message);
}

// Cubit
class NotificationsCubit extends Cubit<NotificationsState> {
  final GetNotificationsUseCase getNotificationsUseCase;
  final GetUnreadCountUseCase getUnreadCountUseCase;
  final MarkNotificationReadUseCase markNotificationReadUseCase;
  final MarkAllNotificationsReadUseCase markAllNotificationsReadUseCase;
  final DeleteNotificationUseCase deleteNotificationUseCase;
  final DeleteAllNotificationsUseCase deleteAllNotificationsUseCase;

  NotificationsCubit({
    required this.getNotificationsUseCase,
    required this.getUnreadCountUseCase,
    required this.markNotificationReadUseCase,
    required this.markAllNotificationsReadUseCase,
    required this.deleteNotificationUseCase,
    required this.deleteAllNotificationsUseCase,
  }) : super(NotificationsInitial());

  List<NotificationModel> _notifications = const [];
  int _unreadCount = 0;
  final Set<String> _hiddenNotificationIds = <String>{};
  DateTime? _clearedAtCutoff;

  List<NotificationModel> _applyLocalFilters(List<NotificationModel> items) {
    return items.where((item) {
      if (_hiddenNotificationIds.contains(item.id)) {
        return false;
      }
      if (_clearedAtCutoff != null &&
          !item.timestamp.isAfter(_clearedAtCutoff!)) {
        return false;
      }
      return true;
    }).toList(growable: false);
  }

  void _emitLoaded() {
    emit(
      NotificationsLoaded(
        notifications: List<NotificationModel>.unmodifiable(_notifications),
        unreadCount: _unreadCount,
      ),
    );
  }

  /// Load all notifications
  Future<void> loadNotifications({
    int page = 1,
    int limit = 20,
    bool? isRead,
  }) async {
    try {
      if (page == 1) {
        emit(NotificationsLoading());
      }

      final notifications = await getNotificationsUseCase(
        page: page,
        limit: limit,
        isRead: isRead,
      );

      final filteredNotifications = _applyLocalFilters(notifications);

      _notifications = filteredNotifications;
      _unreadCount = filteredNotifications.where((n) => !n.isRead).length;
      _emitLoaded();
    } catch (e) {
      emit(NotificationsError(e.toString()));
    }
  }

  /// Mark notification as read
  Future<void> markAsRead(String id) async {
    try {
      // Optimistic update
      if (state is NotificationsLoaded) {
        final targetIndex = _notifications.indexWhere((n) => n.id == id);
        if (targetIndex != -1) {
          final target = _notifications[targetIndex];
          if (!target.isRead && _unreadCount > 0) {
            _unreadCount -= 1;
          }
          _notifications = _notifications
              .map((n) => n.id == id ? n.copyWith(isRead: true) : n)
              .toList(growable: false);
          _emitLoaded();
        }
      }

      await markNotificationReadUseCase(id);
    } catch (e) {
      emit(NotificationsError(e.toString()));
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    try {
      // Optimistic update
      if (state is NotificationsLoaded) {
        _notifications = _notifications
            .map((n) => n.copyWith(isRead: true))
            .toList(growable: false);
        _unreadCount = 0;
        _emitLoaded();
      }

      await markAllNotificationsReadUseCase();
    } catch (e) {
      emit(NotificationsError(e.toString()));
    }
  }

  /// Delete notification
  Future<void> deleteNotification(String id) async {
    try {
      // Optimistic update
      if (state is NotificationsLoaded) {
        _hiddenNotificationIds.add(id);

        NotificationModel? removedItem;
        final updatedList = <NotificationModel>[];
        for (final item in _notifications) {
          if (item.id == id) {
            removedItem = item;
            continue;
          }
          updatedList.add(item);
        }
        if (removedItem != null && !removedItem.isRead && _unreadCount > 0) {
          _unreadCount -= 1;
        }
        _notifications = updatedList;
        _emitLoaded();
      }

      await deleteNotificationUseCase(id);
    } catch (e) {
      // Rollback optimistic update when API delete fails.
      _hiddenNotificationIds.remove(id);
      if (state is NotificationsLoaded) {
        await loadNotifications();
      } else {
        emit(NotificationsError(e.toString()));
      }
    }
  }

  /// Delete all notifications
  Future<void> deleteAllNotifications() async {
    try {
      _clearedAtCutoff = DateTime.now();
      _hiddenNotificationIds.addAll(_notifications.map((n) => n.id));
      _notifications = const [];
      _unreadCount = 0;
      _emitLoaded();

      await deleteAllNotificationsUseCase();
    } catch (e) {
      _clearedAtCutoff = null;
      await loadNotifications();
    }
  }

  /// Get unread count
  Future<int> getUnreadCount() async {
    try {
      return await getUnreadCountUseCase();
    } catch (e) {
      return 0;
    }
  }

  /// Refresh notifications (call this when a new notification arrives)
  Future<void> refresh() async {
    await loadNotifications();
  }
}
