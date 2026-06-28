import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import 'package:sharecycleapp/models/chat_message.dart';

class ChatService {
  static const String _kAuthTokenKey = 'auth_token';
  late StompClient _stompClient;
  final StreamController<ChatMessage> _messageController = StreamController<ChatMessage>.broadcast();
  final StreamController<bool> _connectionStatusController = StreamController<bool>.broadcast();
  String? _currentUserId;
  bool _isConnected = false;

  Stream<ChatMessage> get messageStream => _messageController.stream;
  Stream<bool> get connectionStatusStream => _connectionStatusController.stream;
  bool get isConnected => _isConnected;
  String? get currentUserId => _currentUserId;

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _currentUserId = prefs.getString('owner_id');
    print("Current User ID: $_currentUserId");
    if (_currentUserId == null) {
      throw Exception('User ID not found');
    }
    await _connect();
  }

  Future<void> _connect() async {
    try {
      final token = await _getAuthToken();
      if (token.isEmpty) {
        throw Exception('No authentication token found');
      }

      // Get WebSocket URL
      final wsUrl = _getWebSocketUrl();
      print('Connecting to WebSocket: $wsUrl');

      // Configure STOMP client
      _stompClient = StompClient(
        config: StompConfig.sockJS(
          url: wsUrl,
          onConnect: _onConnect,
          onWebSocketError: (dynamic error) {
            print('WebSocket error: $error');
            _onDisconnect();
          },
          onStompError: (StompFrame frame) {
            print('STOMP error: ${frame.body}');
            _onDisconnect();
          },
          onDisconnect: (StompFrame frame) {
            print('Disconnected from WebSocket');
            _onDisconnect();
          },
          reconnectDelay: const Duration(seconds: 5),
          connectionTimeout: const Duration(seconds: 10),
          stompConnectHeaders: {
            'Authorization': 'Bearer $token',
          },
          webSocketConnectHeaders: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      // Activate the client
      _stompClient.activate();
      
    } catch (e) {
      print('Failed to connect to WebSocket: $e');
      _onDisconnect();
      _reconnect();
    }
  }

  void _onConnect(StompFrame frame) async {
    print('WebSocket connected successfully');
    _isConnected = true;
    _connectionStatusController.add(true);
    final prefs = await SharedPreferences.getInstance();
    _currentUserId = prefs.getString('current_user_id');
    
    // Subscribe to personal message queue
    if (_currentUserId != null) {
      _stompClient.subscribe(
        destination: '/user/$_currentUserId/queue/messages',
        callback: (frame) {
          print('Message received on /user/$_currentUserId/queue/messages');
          print('Frame body: ${frame.body}');
          try {
            if (frame.body != null) {
              print('Received message: ${frame.body}');
              final message = ChatMessage.fromJson(jsonDecode(frame.body!), _currentUserId!);
              _messageController.add(message);
            }
          } catch (e) {
            print('Error processing message: $e');
          }
        },
        headers: {},
      );
    }
  }

  void _onDisconnect() {
    _isConnected = false;
    _connectionStatusController.add(false);
  }

  Future<void> sendMessage(String content, {required String receiverId}) async {
    if (_currentUserId == null) return;
    
    if (!_isConnected) {
      print('Cannot send message: Not connected to WebSocket');
      return;
    }

    final message = {
      'senderId': int.parse(_currentUserId!),
      'receiverId': int.parse(receiverId),
      'content': content,
      'type': 'CHAT',
      'timestamp': DateTime.now().toIso8601String(),
    };

    try {
      _stompClient.send(
        destination: '/app/chat.sendMessage',
        body: jsonEncode(message),
        headers: {'content-type': 'application/json'},
      );
    } catch (e) {
      print('Error sending message: $e');
      rethrow;
    }
  }

  Future<List<ChatMessage>> loadChatHistory(owner, renter) async {
  if (_currentUserId == null) {
    final prefs = await SharedPreferences.getInstance();
    _currentUserId = prefs.getString('current_user_id');
    
    if (_currentUserId == null) {
      print('Cannot load chat history: No current user ID available');
      return [];
    }
  }

  try {
    final token = await _getAuthToken();
    final baseUrl = dotenv.maybeGet("API_BASE_URL") ?? "";
    final url = '$baseUrl/messages/$owner/$renter';
    
    print('Fetching chat history from: $url');
    
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> messages = jsonDecode(response.body);
      return messages.map((msg) => ChatMessage.fromJson(msg, _currentUserId!)).toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    } else {
      print('Failed to load chat history: ${response.statusCode} - ${response.body}');
      return [];
    }
  } catch (e) {
    print('Error loading chat history: $e');
    return [];
  }
}

  void _reconnect() {
    if (!_isConnected) {
      Future.delayed(const Duration(seconds: 5), () => _connect());
    }
  }

  Future<void> dispose() async {
    try {
      if (_isConnected) {
        _stompClient.deactivate();
        _isConnected = false;
      }
      await _messageController.close();
      await _connectionStatusController.close();
    } catch (e) {
      print('Error disposing ChatService: $e');
      rethrow;
    }
  }

  Future<String> _getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kAuthTokenKey) ?? '';
  }

  String _getWebSocketUrl() {
    String? baseUrl = dotenv.maybeGet('API_BASE_URL');
    return '$baseUrl/ws';
  }
}
