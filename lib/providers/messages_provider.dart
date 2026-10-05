import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../core/network/dio_client.dart';
import '../core/constants/api_constants.dart';

class MessagesProvider extends ChangeNotifier {
  IO.Socket? _socket;
  int _nonLus = 0;
  VoidCallback? onConversationUpdated;
  String? _currentConvId;
  int get nonLus => _nonLus;

  void connect(String token) {
    if (_socket != null) {
      debugPrint('⚠️ Socket déjà connecté, skip');
      return;
    }

    debugPrint('🔌 Tentative connexion socket avec token: ${token.substring(0, 20)}...');

    _socket = IO.io(
      ApiConstants.baseUrl.replaceAll('/api/v1', ''),
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setAuth({'token': token})
          .build(),
    );

    _socket!.connect();

    _socket!.onConnect((_) => debugPrint('✅ Socket MessagesProvider connecté'));
    _socket!.onConnectError((e) => debugPrint('❌ Socket erreur connexion : $e'));
    _socket!.onDisconnect((_) => debugPrint('🔌 Socket déconnecté'));

    _socket!.on('conversation_updated', (_) {
      debugPrint('🔔 conversation_updated reçu');
      _nonLus++;
      onConversationUpdated?.call();
      notifyListeners();
    });

    _socket!.on('messages_read', (_) {
      debugPrint('🔔 messages_read reçu');
      onConversationUpdated?.call();
      _reloadCount(token);
    });

    _socket!.on('new_message', (data) {
      _onNewMessage?.call(Map<String, dynamic>.from(data));
    });
  }

  Future<void> _reloadCount(String token) async {
    try {
      final res = await DioClient.instance.get('/messages');
      final list = res.data as List;
      _nonLus = list.fold(0, (sum, c) => sum + ((c['nonLus'] as int?) ?? 0));
      notifyListeners();
    } catch (_) {}
  }


  void joinConversation(String convId, {required void Function(Map<String, dynamic>) onMessage}) {
    _currentConvId = convId;
    _onNewMessage = onMessage;

    // Si déjà connecté, rejoindre immédiatement
    if (_socket?.connected == true) {
      _socket!.emit('join_conversation', convId);
    }
    // Sinon, rejoindre dès la connexion
    _socket?.onConnect((_) {
      if (_currentConvId != null) {
        _socket!.emit('join_conversation', _currentConvId!);
      }
    });
  }

  void leaveConversation(String convId) {
    _socket?.emit('leave_conversation', convId);
    _currentConvId = null;
    _onNewMessage = null;
  }

  // Ajouter le champ
  void Function(Map<String, dynamic>)? _onNewMessage;

  Future<void> markAsRead(String convId) async {
    try {
      await DioClient.instance.post('/messages/conversation/$convId/read');
    } catch (_) {}
  }

  Future<void> reloadCount(String token) => _reloadCount(token);

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _nonLus = 0;
  }
}