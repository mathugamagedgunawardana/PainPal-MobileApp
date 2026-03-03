import 'package:flutter/material.dart';
import '../data/gemini_ai_service.dart';
import '../data/voice_agent_service.dart';

/// Chat message model
class ChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}

/// Chat dialog widget - displayed as a popup
class ChatDialog extends StatefulWidget {
  const ChatDialog({super.key});

  @override
  State<ChatDialog> createState() => _ChatDialogState();
}

class _ChatDialogState extends State<ChatDialog> {
  late final GeminiAiService _aiService;
  late final VoiceAgentService _voiceService;
  final List<ChatMessage> _messages = [];
  final TextEditingController _messageController = TextEditingController();
  bool _isLoading = false;
  bool _isListening = false;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _aiService = GeminiAiService();
    _voiceService = VoiceAgentService();
    _setupVoiceAgent();
    _addInitialMessage();
  }

  void _setupVoiceAgent() {
    _voiceService.onSpeechResult = (recognizedWords) {
      _messageController.text = recognizedWords;
      _sendMessage();
    };

    _voiceService.onListeningStart = () {
      setState(() {
        _isListening = true;
      });
    };

    _voiceService.onListeningEnd = () {
      setState(() {
        _isListening = false;
      });
    };
  }

  void _addInitialMessage() {
    setState(() {
      _messages.add(
        ChatMessage(
          id: DateTime.now().toString(),
          text:
              'Hello! I\'m Painpal AI, your migraine and pain management assistant. You can type your message or use the microphone icon to speak. How can I help you today?',
          isUser: false,
          timestamp: DateTime.now(),
        ),
      );
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    // Add user message to chat
    setState(() {
      _messages.add(
        ChatMessage(
          id: DateTime.now().toString(),
          text: text,
          isUser: true,
          timestamp: DateTime.now(),
        ),
      );
      _isLoading = true;
    });

    _messageController.clear();
    _scrollToBottom();

    try {
      // Get AI response
      final response = await _aiService.sendMessage(text);

      setState(() {
        _messages.add(
          ChatMessage(
            id: DateTime.now().toString(),
            text: response,
            isUser: false,
            timestamp: DateTime.now(),
          ),
        );
        _isLoading = false;
      });

      // Speak the response
      await _voiceService.speak(response);

      _scrollToBottom();
    } catch (e) {
      setState(() {
        _messages.add(
          ChatMessage(
            id: DateTime.now().toString(),
            text: 'Sorry, something went wrong. Please try again.',
            isUser: false,
            timestamp: DateTime.now(),
          ),
        );
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleListening() async {
    try {
      if (_isListening) {
        await _voiceService.stopListening();
      } else {
        await _voiceService.startListening();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Microphone error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _aiService.dispose();
    _voiceService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      insetPadding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFB6F36B),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Painpal AI Assistant',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F1218),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Color(0xFF0F1218)),
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: 'Close chat',
                ),
              ],
            ),
          ),
          // Messages area
          Flexible(
            child: Container(
              width: double.maxFinite,
              constraints: const BoxConstraints(maxWidth: 500, minHeight: 300),
              padding: const EdgeInsets.all(16),
              color: const Color(0xFF0F1218),
              child: ListView.builder(
                controller: _scrollController,
                itemCount: _messages.length + (_isLoading ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _messages.length) {
                    // Loading indicator
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          const SizedBox(width: 12),
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(
                                Color(0xFFB6F36B),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Typing...',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final message = _messages[index];
                  return _buildMessageBubble(message);
                },
              ),
            ),
          ),
          // Input area
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF171B22),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        maxLines: null,
                        minLines: 1,
                        enabled: !_isLoading && !_isListening,
                        decoration: InputDecoration(
                          hintText: 'Ask me anything...',
                          hintStyle: const TextStyle(color: Colors.grey),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFF2A2E35),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFF2A2E35),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFFB6F36B),
                            ),
                          ),
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        style: const TextStyle(color: Colors.white),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Microphone button
                    FloatingActionButton(
                      mini: true,
                      backgroundColor: _isListening
                          ? const Color(0xFFFF6B6B)
                          : const Color(0xFFB6F36B),
                      onPressed: _toggleListening,
                      tooltip: _isListening ? 'Stop listening' : 'Start listening',
                      child: Icon(
                        _isListening ? Icons.mic : Icons.mic_none,
                        color: const Color(0xFF0F1218),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Send button
                    FloatingActionButton(
                      mini: true,
                      backgroundColor: const Color(0xFFB6F36B),
                      onPressed: _isLoading || _isListening ? null : _sendMessage,
                      tooltip: 'Send message',
                      child: Icon(
                        Icons.send,
                        color: const Color(0xFF0F1218),
                        size: _isLoading ? 16 : 20,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!message.isUser)
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFFB6F36B),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(
                  Icons.smart_toy,
                  color: Color(0xFF0F1218),
                  size: 18,
                ),
              ),
            ),
          const SizedBox(width: 12),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: message.isUser
                    ? const Color(0xFFB6F36B)
                    : const Color(0xFF171B22),
                borderRadius: BorderRadius.circular(12),
                border: message.isUser
                    ? null
                    : Border.all(
                        color: const Color(0xFF2A2E35),
                        width: 1,
                      ),
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  color: message.isUser
                      ? const Color(0xFF0F1218)
                      : Colors.white,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          if (message.isUser) const SizedBox(width: 12),
          if (message.isUser)
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: Color(0xFFB6F36B),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(
                  Icons.person,
                  color: Color(0xFF0F1218),
                  size: 18,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Floating chat button widget
class ChatButton extends StatefulWidget {
  final VoidCallback? onPressed;

  const ChatButton({
    this.onPressed,
    super.key,
  });

  @override
  State<ChatButton> createState() => _ChatButtonState();
}

class _ChatButtonState extends State<ChatButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handlePress() {
    _animationController.forward().then((_) {
      _animationController.reverse();
    });
    widget.onPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: Tween<double>(begin: 1.0, end: 1.1).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
      ),
      child: FloatingActionButton(
        onPressed: _handlePress,
        backgroundColor: const Color(0xFFB6F36B),
        tooltip: 'Chat with Painpal AI',
        child: const Icon(
          Icons.chat_bubble_outline,
          color: Color(0xFF0F1218),
          size: 28,
        ),
      ),
    );
  }
}

