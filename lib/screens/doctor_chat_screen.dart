import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/auth_service.dart';
import '../data/doctor_chat_service.dart';

class DoctorChatScreen extends StatefulWidget {
  const DoctorChatScreen({super.key});

  @override
  State<DoctorChatScreen> createState() => _DoctorChatScreenState();
}

class _DoctorChatScreenState extends State<DoctorChatScreen> {
  late final DoctorChatService _chatService;

  ConversationSummary? _conversation;
  final List<DoctorChatMessage> _messages = [];
  final TextEditingController _inputController = TextEditingController();
  bool _loading = true;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final auth = context.read<AuthService>();
      _chatService = DoctorChatService(authService: auth);

      final convs = await _chatService.listConversations();
      if (convs.isEmpty) {
        setState(() {
          _conversation = null;
          _loading = false;
        });
        return;
      }

      final conv = convs.first;
      final msgs = await _chatService.getMessages(conv.id);

      setState(() {
        _conversation = conv;
        _messages
          ..clear()
          ..addAll(msgs);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load chat: $e')),
      );
    }
  }

  Future<void> _send() async {
    if (_conversation == null) return;
    final text = _inputController.text.trim();
    if (text.isEmpty || _sending) return;

    setState(() {
      _sending = true;
    });

    try {
      final msg = await _chatService.sendMessage(
        conversationId: _conversation!.id,
        content: text,
      );
      if (!mounted) return;
      setState(() {
        _messages.add(msg);
        _inputController.clear();
        _sending = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _sending = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send message: $e')),
      );
    }
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _conversation?.otherName ?? 'Doctor chat',
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _conversation == null
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'No linked doctor conversations yet.\nAsk your doctor to add you in the web dashboard.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final m = _messages[index];
                          final isMe = m.isMe;
                          final bubbleColor = isMe
                              ? theme.colorScheme.primary
                              : theme.colorScheme.surfaceVariant;
                          final textColor =
                              isMe ? Colors.black : theme.colorScheme.onSurface;

                          return Align(
                            alignment: isMe
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: bubbleColor,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                m.content,
                                style: TextStyle(color: textColor),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _inputController,
                                minLines: 1,
                                maxLines: 4,
                                decoration: const InputDecoration(
                                  hintText: 'Type a message...',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              onPressed: _sending ? null : _send,
                              icon: _sending
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.send),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}

