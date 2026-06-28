import 'package:flutter/material.dart';
import 'package:sharecycleapp/models/chat_message.dart';
import 'package:sharecycleapp/services/chat_service.dart';
import 'package:sharecycleapp/theme/color.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatScreen extends StatefulWidget {
  final String otherUserName;
  final String? otherUserImageUrl;

  const ChatScreen({
    Key? key,
    required this.otherUserName,
    this.otherUserImageUrl,
  }) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late ChatService _chatService;
  final List<ChatMessage> _messages = [];
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    _chatService = ChatService();
    
    // Initialize chat after a small delay to ensure the UI is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeChat();
    });
  }

  Future<void> _initializeChat() async {
    try {
      await _chatService.initialize();
      final prefs = await SharedPreferences.getInstance();
      final renterId = prefs.getString('renter_id') ?? '';
      final ownerId = prefs.getString('owner_id') ?? '';
      final currentUserId = prefs.getString('current_user_id') ?? '';
      
      // Determine the other user's ID
      final otherUserId = currentUserId == renterId ? ownerId : renterId;
      
      if (otherUserId.isEmpty) {
        throw Exception('Could not determine other user ID');
      }
      
      // Load existing messages
      final messages = await _chatService.loadChatHistory(currentUserId, otherUserId);
      if (mounted) {
        setState(() {
          _messages.clear();
          _messages.addAll(messages);
          // Scroll to bottom after messages are loaded
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToBottom();
          });
        });
      }

      // Listen for new messages
      _chatService.messageStream.listen((message) {
        if (mounted) {
          setState(() {
            _messages.add(message);
          });
          // Always scroll to bottom for new messages
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToBottom();
          });
        }
      });

      _chatService.connectionStatusStream.listen((isConnected) {
        if (mounted) {
          setState(() {
            _isConnected = isConnected;
          });
        }
      });
    } catch (e) {
      print('Error initializing chat: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load chat history')),
        );
      }
    }
  }

  // Scroll to bottom of the message list with smooth animation
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      // Small delay to ensure the list is built
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent + 200, // Add some extra space
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  void _sendMessage() async {
    final messageText = _messageController.text.trim();
    if (messageText.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      final currentUserId = prefs.getString('current_user_id') ?? '';
      final renterId = prefs.getString('renter_id') ?? '';
      final ownerId = prefs.getString('owner_id') ?? '';
      
      if (currentUserId.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error: User not authenticated')),
          );
        }
        return;
      }

      final receiverId = currentUserId == renterId ? ownerId : renterId;

      if (receiverId.isNotEmpty) {
        // Generate a temporary ID for the message
        final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
        
        // Add the message to the UI immediately for better UX
        final newMessage = ChatMessage(
          id: tempId,
          chatRoomId: '${currentUserId}_$receiverId',
          senderId: currentUserId, // Keep as String to match the model
          content: messageText,
          isMe: true,
          createdAt: DateTime.now(), // Use DateTime directly
        );
        
        setState(() {
          _messages.add(newMessage);
        });
        
        // Scroll to bottom after adding the message
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
        });
        
        // Clear the input field
        _messageController.clear();
        
        // Send the message through the service
        try {
          await _chatService.sendMessage(messageText, receiverId: receiverId);
          // The actual message will be added to the list when received from the server
          // with the correct ID and timestamp
          setState(() {
            _messages.removeWhere((m) => m.id == tempId);
          });
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to send message: ${e.toString()}')),
            );
          }
          // Remove the temporary message if sending fails
          if (mounted) {
            setState(() {
              _messages.removeWhere((m) => m.id == tempId);
            });
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error: Could not determine recipient')),
          );
        }
      }
    }
  }

  // Add a FocusNode to control the text field focus
  final FocusNode _messageFocusNode = FocusNode();

  @override
  void dispose() async {
    super.dispose();
    final prefs = await SharedPreferences.getInstance();
    prefs.remove("owner_id");
    prefs.remove("renter_id");
    _messageController.dispose();
    _scrollController.dispose();
    _messageFocusNode.dispose();
    _chatService.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Add GestureDetector to handle tap outside to dismiss keyboard
    return GestureDetector(
      onTap: () {
        // This will dismiss the keyboard when tapping outside the text field
        FocusScope.of(context).unfocus();
      },
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              CircleAvatar(
                backgroundImage: widget.otherUserImageUrl != null ? NetworkImage(widget.otherUserImageUrl!) : null,
                child: widget.otherUserImageUrl == null ? Text(widget.otherUserName[0].toUpperCase()) : null,
              ),
              const SizedBox(width: 12),
              Text(widget.otherUserName),
            ],
          ),
        ),
        body: Column(
          children: [
            // if (!_isConnected)
            //   Container(
            //     padding: const EdgeInsets.all(8),
            //     color: Colors.orange,
            //     child: const Text(
            //       'Connecting...',
            //       style: TextStyle(color: Colors.white),
            //       textAlign: TextAlign.center,
            //     ),
            //   ),
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(8),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  return _buildMessageBubble(message);
                },
              ),
            ),
            _buildMessageInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isMe = message.isMe;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: isMe ? orange : Colors.grey[200],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              message.content,
              style: TextStyle(
                color: isMe ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTime(message.createdAt),
              style: TextStyle(
                fontSize: 10,
                color: isMe ? Colors.white70 : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 2,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              focusNode: _messageFocusNode,
              // Add FocusNode here
              decoration: const InputDecoration(
                hintText: 'Type a message...',
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onSubmitted: (_) => _sendMessage(),
              textInputAction: TextInputAction.send,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send, color: orange),
            onPressed: _sendMessage,
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
