import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/chat_service.dart';
import '../services/data_manager.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final DataManager _dataManager = DataManager();
  List<ChatMessage> _chatMessages = [];
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();
  bool _isTyping = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadChatHistory();
  }

  Future<void> _loadChatHistory() async {
    setState(() => _isLoading = true);
    
    try {
      final messages = await _dataManager.getChatMessages();
      setState(() {
        _chatMessages = messages;
        _isLoading = false;
      });
      _scrollToBottom();
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Failed to load chat history: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _sendChatMessage() async {
    if (_chatController.text.trim().isEmpty) return;

    final userMessage = _chatController.text.trim();
    _chatController.clear();

    // Create and save user message
    final userChatMessage = ChatMessage(
      text: userMessage,
      isUser: true,
      timestamp: DateTime.now(),
    );

    try {
      // Save user message to database
      await _dataManager.addChatMessage(userChatMessage);
      
      setState(() {
        _chatMessages.add(userChatMessage);
        _isTyping = true;
      });

      _scrollToBottom();

      // Get AI response
      final response = await ChatService.sendMessage(userMessage);
      
      // Create and save AI response
      final aiChatMessage = ChatMessage(
        text: response,
        isUser: false,
        timestamp: DateTime.now(),
      );

      await _dataManager.addChatMessage(aiChatMessage);
      
      setState(() {
        _chatMessages.add(aiChatMessage);
        _isTyping = false;
      });
    } catch (e) {
      // Create error message
      final errorMessage = ChatMessage(
        text: "I apologize, but I'm experiencing technical difficulties. Please try again later or contact your healthcare provider if you have urgent concerns.",
        isUser: false,
        timestamp: DateTime.now(),
      );

      // Save error message to database
      await _dataManager.addChatMessage(errorMessage);
      
      setState(() {
        _chatMessages.add(errorMessage);
        _isTyping = false;
      });
    }

    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chatScrollController.hasClients) {
        _chatScrollController.animateTo(
          _chatScrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _clearChatHistory() async {
    try {
      bool confirmed = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Clear Chat History'),
            content: Text('Are you sure you want to clear all chat messages? This action cannot be undone.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: Text('Clear'),
              ),
            ],
          );
        },
      ) ?? false;

      if (confirmed) {
        await _dataManager.clearChatHistory();
        await _loadChatHistory(); // Reload chat (will include welcome message)
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Chat history cleared'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      _showErrorSnackBar('Failed to clear chat history: $e');
    }
  }

  Widget _buildChatBubble(ChatMessage message) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Row(
        mainAxisAlignment: message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Color(0xFF10B981),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.smart_toy, color: Colors.white, size: 18),
            ),
            SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: message.isUser ? Color(0xFF10B981) : Colors.grey[100],
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  color: message.isUser ? Colors.white : Colors.black87,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          if (message.isUser) ...[
            SizedBox(width: 8),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Color(0xFF0D9488),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.person, color: Colors.white, size: 18),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Chat Header
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Color(0xFF10B981),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.smart_toy, color: Colors.white, size: 24),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('SmartCare Assistant', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text('AI-powered health support', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                  ],
                ),
              ),
              // Clear chat button
              IconButton(
                onPressed: _clearChatHistory,
                icon: Icon(Icons.clear_all, color: Colors.grey[600]),
                tooltip: 'Clear chat history',
              ),
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Color(0xFF10B981),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ),
        
        // Chat Messages
        Expanded(
          child: _isLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Color(0xFF10B981)),
                    SizedBox(height: 16),
                    Text('Loading chat history...', style: TextStyle(color: Colors.grey[600])),
                  ],
                ),
              )
            : _chatMessages.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[400]),
                      SizedBox(height: 16),
                      Text('Start a conversation!', style: TextStyle(color: Colors.grey[600], fontSize: 18)),
                      SizedBox(height: 8),
                      Text('Ask me anything about your health', style: TextStyle(color: Colors.grey[500])),
                    ],
                  ),
                )
              : ListView.builder(
                  controller: _chatScrollController,
                  padding: EdgeInsets.symmetric(vertical: 8),
                  itemCount: _chatMessages.length + (_isTyping ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index < _chatMessages.length) {
                      return _buildChatBubble(_chatMessages[index]);
                    } else {
                      // Typing indicator
                      return Container(
                        margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: Color(0xFF10B981),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.smart_toy, color: Colors.white, size: 18),
                            ),
                            SizedBox(width: 8),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Text('Typing...', style: TextStyle(color: Colors.grey[600])),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                  },
                ),
        ),
        
        // Chat Input
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Colors.grey[300]!)),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _chatController,
                  decoration: InputDecoration(
                    hintText: 'Ask me about your health...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(color: Color(0xFF10B981), width: 2),
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  maxLines: null,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendChatMessage(),
                ),
              ),
              SizedBox(width: 8),
              Container(
                width: 48,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isTyping ? null : _sendChatMessage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    shape: CircleBorder(),
                    padding: EdgeInsets.zero,
                  ),
                  child: Icon(Icons.send, size: 24),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _chatController.dispose();
    _chatScrollController.dispose();
    super.dispose();
  }
}