import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:web_socket_client/web_socket_client.dart';

class DocumentChatWebService {
  static final _instance = DocumentChatWebService._internal();
  WebSocket? _socket;
  bool _isConnected = false;
  bool _isConnecting = false;
  Timer? _reconnectionTimer;
  final int _maxReconnectAttempts = 3;
  int _reconnectAttempts = 0;
  String _currentResponse = "";

  factory DocumentChatWebService() => _instance;
  DocumentChatWebService._internal();

  final _contentController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get contentStream => _contentController.stream;
  bool get isConnected => _isConnected;

  Future<bool> isEmulator() async {
    if (!Platform.isAndroid) return false;
    
    try {
      final androidId = await File('/sys/class/android_usb/android0/iSerial').readAsString();
      return androidId.contains('emulator') || androidId.contains('generic');
    } catch (e) {
      return false;
    }
  }

  Future<void> connect() async {
    if (_isConnecting) {
      print('[DOC_CHAT] Already attempting to connect, ignoring duplicate request');
      return;
    }

    if (_isConnected && _socket != null) {
      print('[DOC_CHAT] WebSocket already connected');
      return;
    }

    _isConnecting = true;

    try {
      print('[DOC_CHAT] Attempting to connect to WebSocket...');
      
      final bool runningOnEmulator = await isEmulator();
      final String serverIp = runningOnEmulator ? '10.0.2.2' : '192.168.42.186';
      
      final url = Uri.parse("ws://10.0.2.2:8000/ws/document_chat");
      
      _socket = WebSocket(
        url,
        backoff: ConstantBackoff(Duration(seconds: 5)),
      );

      _socket!.connection.listen(
        (state) {
          if (state is Connected) {
            print('[DOC_CHAT] WebSocket connected successfully');
            _isConnected = true;
            _isConnecting = false;
            _reconnectAttempts = 0;
            _reconnectionTimer?.cancel();
            _reconnectionTimer = null;
          } else if (state is Disconnected) {
            print('[DOC_CHAT] WebSocket disconnected: ${state.reason}');
            _isConnected = false;
            _isConnecting = false;
            if (state.reason != 'Normal closure') {
              _handleDisconnection();
            }
          }
        },
        onError: (error) {
          print('[DOC_CHAT] WebSocket connection error: $error');
          _isConnected = false;
          _isConnecting = false;
          _handleDisconnection();
        },
        cancelOnError: false,
      );

      _socket!.messages.listen(
        (message) {
          print('[DOC_CHAT] Received message: $message');
          try {
            final data = json.decode(message);
            if (data['type'] == 'content') {
              String messageContent = data['data'];
              
              if (messageContent.startsWith('Error:')) {
                _currentResponse = messageContent;
                _contentController.add({
                  'data': messageContent,
                  'done': true,
                  'chat_id': data['chat_id'],
                  
                });
                _currentResponse = "";
                return;
              }
              
              _currentResponse += messageContent;
              bool isComplete = data['done'] ?? false;
              
              _contentController.add({
                'data': _currentResponse,
                'done': isComplete,
                'chat_id': data['chat_id'],
              
              });
              
              if (isComplete) {
                _currentResponse = "";
              }
            } else if (data['type'] == 'error') {
              _contentController.add({
                'data': data['data'],
                'done': true,
                'error': true,
                'chat_id': data['chat_id'],
                
              });
            }
          } catch (e) {
            print('[DOC_CHAT] Error processing message: $e');
            _contentController.add({
              'data': 'Error: Something happened. Please try again later.',
              'done': true,
              'error': true
            });
          }
        },
        onError: (error) {
          print('[DOC_CHAT] WebSocket message error: $error');
          _contentController.add({
            'data': 'Error: Something happened. Please try again later.',
            'done': true,
            'error': true
          });
        },
        cancelOnError: false,
      );
    } catch (e) {
      print('[DOC_CHAT] Error establishing WebSocket connection: $e');
      _isConnected = false;
      _isConnecting = false;
      _handleDisconnection();
    }
  }

  void _handleDisconnection() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      print('[DOC_CHAT] Max reconnection attempts reached');
      return;
    }

    _reconnectionTimer?.cancel();
    _reconnectionTimer = Timer(Duration(seconds: 5), () {
      _reconnectAttempts++;
      print('[DOC_CHAT] Reconnection attempt $_reconnectAttempts of $_maxReconnectAttempts');
      connect();
    });
  }

  Future<bool> chat({
    required String query,
    required String chatId,
    required String userId,

  }) async {
    if (!_isConnected || _socket == null) {
      print('[DOC_CHAT] WebSocket is not connected. Cannot send message.');
      return false;
    }

    try {
      print('[DOC_CHAT] Sending query for document');
      _socket!.send(json.encode({
        'query': query,
        'chat_id': chatId,
        'user_id': userId,
        'timestamp': DateTime.now().toUtc().toString(),
      }));
      return true;
    } catch (e) {
      print('[DOC_CHAT] Error sending chat message: $e');
      _isConnected = false;
      return false;
    }
  }

  void dispose() {
    _reconnectionTimer?.cancel();
    _socket?.close();
    _socket = null;
    _isConnected = false;
    _isConnecting = false;
    _reconnectAttempts = 0;
    _currentResponse = "";
    _contentController.close();
  }
}