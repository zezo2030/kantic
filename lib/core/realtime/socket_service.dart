import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../constants/api_constants.dart';
import '../storage/secure_storage_service.dart';

class SocketService {
  SocketService._();
  static final SocketService instance = SocketService._();

  IO.Socket? _socket;
  final _hallControllers = <String, StreamController<Map<String, dynamic>>>{};

  Future<void> connect() async {
    if (_socket?.connected == true) return;
    final token = await SecureStorageService().getAccessToken();
    _socket = IO.io(ApiConstants.baseUrl.replaceFirst('/api/v1', ''), {
      'transports': ['websocket'],
      'extraHeaders': token != null ? {'Authorization': 'Bearer $token'} : null,
    });
    _socket?.onConnect((_) {});
    _socket?.onReconnect((_) {});
    _socket?.onDisconnect((_) {});
  }

  void dispose() {
    for (var c in _hallControllers.values) {
      c.close();
    }
    _hallControllers.clear();
    _socket?.dispose();
    _socket = null;
  }

  Future<void> joinHall(String hallId) async {
    await connect();
    _socket?.emit('join:hall', hallId);
    _socket?.off('hall:updated');
    _socket?.on('hall:updated', (data) {
      final id = (data is Map && data['id'] != null)
          ? data['id'].toString()
          : null;
      if (id == hallId) {
        final controller = _hallControllers.putIfAbsent(
          hallId,
          () => StreamController.broadcast(),
        );
        controller.add((data as Map).cast<String, dynamic>());
      }
    });
  }

  void leaveHall(String hallId) {
    _socket?.emit('leave:hall', hallId);
    // keep listener if other halls are used; stream will stop receiving events for this id
  }

  Stream<Map<String, dynamic>> onHallUpdated(String hallId) {
    final controller = _hallControllers.putIfAbsent(
      hallId,
      () => StreamController.broadcast(),
    );
    return controller.stream;
  }
}
