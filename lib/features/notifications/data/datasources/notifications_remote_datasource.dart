import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/notification_model.dart';
import '../../../../core/errors/exceptions.dart';

abstract class NotificationsRemoteDataSource {
  Future<List<NotificationModel>> getNotifications({
    int page = 1,
    int limit = 20,
    bool? isRead,
  });
  Future<int> getUnreadCount();
  Future<void> markAsRead(String id);
  Future<void> markAllAsRead();
  Future<void> deleteNotification(String id);
  Future<void> deleteAllNotifications();
}

class NotificationsRemoteDataSourceImpl
    implements NotificationsRemoteDataSource {
  final Dio dio;

  NotificationsRemoteDataSourceImpl({required this.dio});

  @override
  Future<List<NotificationModel>> getNotifications({
    int page = 1,
    int limit = 20,
    bool? isRead,
  }) async {
    try {
      final queryParams = {
        'page': page,
        'limit': limit,
        if (isRead != null) 'isRead': isRead,
      };

      final response = await dio.get(
        ApiConstants.notificationsEndpoint,
        queryParameters: queryParams,
      );

      final List<dynamic> items = response.data['items'];
      return items.map((json) => NotificationModel.fromFirebase(json)).toList();
    } on DioException catch (e) {
      _handleDioException(e);
      rethrow;
    } catch (e) {
      throw ServerException(message: 'Failed to get notifications: $e');
    }
  }

  @override
  Future<int> getUnreadCount() async {
    try {
      final response = await dio.get(
        ApiConstants.notificationsUnreadCountEndpoint,
      );
      return response.data['count'] as int;
    } on DioException catch (e) {
      _handleDioException(e);
      rethrow;
    } catch (e) {
      throw ServerException(message: 'Failed to get unread count: $e');
    }
  }

  @override
  Future<void> markAsRead(String id) async {
    try {
      await dio.patch('${ApiConstants.notificationsEndpoint}/$id/read');
    } on DioException catch (e) {
      _handleDioException(e);
    } catch (e) {
      throw ServerException(message: 'Failed to mark as read: $e');
    }
  }

  @override
  Future<void> markAllAsRead() async {
    try {
      await dio.patch('${ApiConstants.notificationsEndpoint}/read-all');
    } on DioException catch (e) {
      _handleDioException(e);
    } catch (e) {
      throw ServerException(message: 'Failed to mark all as read: $e');
    }
  }

  @override
  Future<void> deleteNotification(String id) async {
    try {
      await dio.delete('${ApiConstants.notificationsEndpoint}/$id');
    } on DioException catch (e) {
      _handleDioException(e);
    } catch (e) {
      throw ServerException(message: 'Failed to delete notification: $e');
    }
  }

  @override
  Future<void> deleteAllNotifications() async {
    try {
      await dio.delete(ApiConstants.notificationsEndpoint);
    } on DioException catch (e) {
      _handleDioException(e);
    } catch (e) {
      throw ServerException(message: 'Failed to delete all notifications: $e');
    }
  }

  void _handleDioException(DioException e) {
    if (e.response != null) {
      final message = e.response?.data['message'] ?? 'Unknown server error';
      throw ServerException(message: message.toString());
    } else {
      throw ServerException(message: 'Network error: ${e.message}');
    }
  }
}
