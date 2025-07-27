import 'dart:async';
import 'dart:convert';

import 'package:web_socket_client/web_socket_client.dart';
class ChatWebService {
  static final _instance = ChatWebService._internal();
  WebSocket? _socket;
  bool _isConnected = false;
  bool _isConnecting = false;
  Timer? _reconnectionTimer;
  final int _maxReconnectAttempts = 3;
  int _reconnectAttempts = 0;
  String _currentResponse = ""; 
  factory ChatWebService() => _instance;
  ChatWebService._internal();

  final _searchResultController = StreamController<Map<String, dynamic>>.broadcast();
  final _contentController = StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get searchResultStream => _searchResultController.stream;
  Stream<Map<String, dynamic>> get contentSream => _contentController.stream;
  bool get isConnected => _isConnected;

  void connect() {
    if (_isConnecting) {
      print('Already attempting to connect, ignoring duplicate request');
      return;
    }

    if (_isConnected && _socket != null) {
      print('WebSocket already connected');
      return;
    }

    _isConnecting = true;

    try {
      print('Attempting to connect to WebSocket...');
      final url = Uri.parse("ws://10.0.2.2:8000/ws/chat");
      
      _socket = WebSocket(
        url,
        backoff: ConstantBackoff(Duration(seconds: 5)),
      );

      _socket!.connection.listen(
        (state) {
          if (state is Connected) {
            print('WebSocket connected successfully');
            _isConnected = true;
            _isConnecting = false;
            _reconnectAttempts = 0;
            _reconnectionTimer?.cancel();
            _reconnectionTimer = null;
          } else if (state is Disconnected) {
            print('WebSocket disconnected: ${state.reason}');
            _isConnected = false;
            _isConnecting = false;
            // Only attempt reconnection if it wasn't a normal closure
            if (state.reason != 'Normal closure') {
              _handleDisconnection();
            }
          }
        },
        onError: (error) {
          print('WebSocket connection error: $error');
          _isConnected = false;
          _isConnecting = false;
          _handleDisconnection();
        },
        cancelOnError: false,
      );


      _socket!.messages.listen(
        (message) {
          print('Received message: $message');
          try {
            final data = json.decode(message);
            if (data['type'] == 'search_result') {
              _searchResultController.add(data);
            } else if (data['type'] == 'content') {
              String messageContent = data['data'];
              
              // Check if the message is an error
              if (messageContent.startsWith('Error:')) {
                // Reset the current response if it's an error
                _currentResponse = messageContent;
                
                // Send error as complete response
                _contentController.add({
                  'data': messageContent,
                  'done': true
                });
                
                _currentResponse = ""; // Reset for next message
                return;
              }
              
              // Normal message handling
              _currentResponse += messageContent;
              bool isComplete = data['done'] ?? false;
              
              _contentController.add({
                'data': _currentResponse,
                'done': isComplete
              });
              
              if (isComplete) {
                _currentResponse = "";
              }
            }
          } catch (e) {
            print('Error processing message: $e');
            _contentController.add({
              'data': 'Error: Something happened. Please try again later.',
              'done': true
            });
          }
        },
        onError: (error) {
          print('WebSocket message error: $error');
          _contentController.add({
            'data': 'Error: Something happened. Please try again later.',
            'done': true
          });
        },
        cancelOnError: false,
      );
    } catch (e) {
      print('Error establishing WebSocket connection: $e');
      _isConnected = false;
      _isConnecting = false;
      _handleDisconnection();
    }
  }

  void _handleDisconnection() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      print('Max reconnection attempts reached');
      return;
    }

    _reconnectionTimer?.cancel();
    _reconnectionTimer = Timer(Duration(seconds: 5), () {
      _reconnectAttempts++;
      print('Reconnection attempt $_reconnectAttempts of $_maxReconnectAttempts');
      connect();
    });
  }
Future<bool> chat(String query, String chatId, String userId) async {
  if (!_isConnected || _socket == null) {
    print('[CHAT] WebSocket is not connected. Attempting to reconnect...');
    connect();
    
    // Wait for connection or timeout
    int attempts = 0;
    while (!_isConnected && attempts < 3) {
      await Future.delayed(Duration(seconds: 1));
      attempts++;
    }
    
    if (!_isConnected) {
      print('[CHAT] Failed to reconnect WebSocket');
      return false;
    }
  }

  try {
    print('[CHAT] Sending message - Query: $query, ChatId: $chatId, UserId: $userId');
    final message = {
      'query': query,
      'chat_id': chatId,
      'user_id': userId,
      'timestamp': DateTime.now().toUtc().toString(),
    };
    print('[CHAT] Sending message data: ${json.encode(message)}');
    _socket!.send(json.encode(message));
    return true;
  } catch (e) {
    print('[CHAT] Error sending chat message: $e');
    _isConnected = false;
    return false;
  }
}

  void dispose() {
    _reconnectionTimer?.cancel();
    _socket = null;
    _isConnected = false;
    _isConnecting = false;
    _reconnectAttempts = 0;
    _currentResponse = "";
  }
} 