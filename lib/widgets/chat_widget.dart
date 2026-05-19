import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../data/auth_models.dart';
import '../data/database.dart';
import '../data/doctor_patient_chat_api.dart';
import '../data/gemini_ai_service.dart';
import '../data/patient_ai_context_builder.dart';
import '../data/storage.dart';
import '../data/voice_agent_service.dart';
import '../services/app_services.dart';

/// Local model for the Gemini / voice assistant tab only.
class AiChatMessage {
  AiChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
  });

  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
}

/// Keeps tab body state alive when using [TabBarView] (off-screen tabs are otherwise disposed).
class _KeepAliveTabBody extends StatefulWidget {
  const _KeepAliveTabBody({required this.child});

  final Widget child;

  @override
  State<_KeepAliveTabBody> createState() => _KeepAliveTabBodyState();
}

class _KeepAliveTabBodyState extends State<_KeepAliveTabBody>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}

/// Full-screen style dialog: optional **Your doctor** tab (patients, signed in) + **AI assistant**.
class ChatDialog extends StatefulWidget {
  const ChatDialog({super.key});

  @override
  State<ChatDialog> createState() => _ChatDialogState();
}

class _ChatDialogState extends State<ChatDialog>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;
  bool _showDoctorTab = false;

  @override
  void initState() {
    super.initState();
    final u = AppServices.auth.currentUser;
    _showDoctorTab =
        AppServices.auth.isAuthenticated && u?.role == UserRole.patient;
    if (_showDoctorTab) {
      _tabController = TabController(length: 2, vsync: this);
    }
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.sizeOf(context).height * 0.72;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.maxFinite,
        height: h,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: const BoxDecoration(
                color: Color(0xFFB6F36B),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.chat_bubble_outline, color: Color(0xFF0F1218)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _showDoctorTab ? 'Messages' : 'Painpal AI Assistant',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F1218),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Color(0xFF0F1218)),
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: 'Close',
                  ),
                ],
              ),
            ),
            if (_showDoctorTab && _tabController != null) ...[
              Material(
                color: const Color(0xFF171B22),
                child: TabBar(
                  controller: _tabController,
                  labelColor: const Color(0xFFB6F36B),
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: const Color(0xFFB6F36B),
                  tabs: const [
                    Tab(text: 'Your doctor'),
                    Tab(text: 'AI assistant'),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: const [
                    _KeepAliveTabBody(child: _PatientDoctorChatPanel()),
                    _KeepAliveTabBody(child: _AiChatPanel()),
                  ],
                ),
              ),
            ] else
              const Expanded(child: _AiChatPanel()),
          ],
        ),
      ),
    );
  }
}

class _PatientDoctorChatPanel extends StatefulWidget {
  const _PatientDoctorChatPanel();

  @override
  State<_PatientDoctorChatPanel> createState() =>
      _PatientDoctorChatPanelState();
}

class _PatientDoctorChatPanelState extends State<_PatientDoctorChatPanel> {
  final DoctorPatientChatApi _api = DoctorPatientChatApi();
  final TextEditingController _bootstrapDoctorId = TextEditingController();
  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();

  List<PatientChatConversation> _conversations = [];
  List<PatientChatMessage> _messages = [];
  String? _conversationId;
  bool _loading = true;
  bool _opening = false;
  bool _sending = false;
  String? _error;

  Timer? _poll;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    final saved = await SettingsStorage().readChatDoctorProfileId();
    if (mounted) {
      _bootstrapDoctorId.text = saved ?? '';
    }
    await _loadConversations();
  }

  void _startPoll() {
    _poll?.cancel();
    _poll = Timer.periodic(const Duration(seconds: 5), (_) {
      _silentReloadMessages();
    });
  }

  Future<void> _silentReloadMessages() async {
    final cid = _conversationId;
    if (cid == null || !mounted) {
      return;
    }
    try {
      final next = await _api.fetchMessages(cid);
      if (!mounted) {
        return;
      }
      setState(() {
        _messages = next;
      });
      _scrollToBottom();
    } catch (_) {
      // Same as web ChatPanel: ignore transient poll errors
    }
  }

  Future<void> _loadConversations() async {
    if (!AppServices.auth.isAuthenticated) {
      setState(() {
        _loading = false;
        _error = 'Sign in to message your care team.';
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await _api.listConversations();
      if (!mounted) {
        return;
      }
      String? cid = _conversationId;
      if (cid == null || !list.any((c) => c.id == cid)) {
        cid = list.isNotEmpty ? list.first.id : null;
      }
      setState(() {
        _conversations = list;
        _conversationId = cid;
      });
      if (cid != null) {
        await _reloadMessages(showSpinner: false);
        _startPoll();
      } else {
        _poll?.cancel();
        setState(() {
          _messages = [];
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _reloadMessages({bool showSpinner = true}) async {
    final cid = _conversationId;
    if (cid == null) {
      return;
    }
    if (showSpinner) {
      setState(() => _loading = true);
    }
    try {
      final msgs = await _api.fetchMessages(cid);
      if (!mounted) {
        return;
      }
      setState(() {
        _messages = msgs;
        _error = null;
      });
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
        });
      }
    } finally {
      if (mounted && showSpinner) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _openWithDoctorId() async {
    final raw = _bootstrapDoctorId.text.trim();
    if (raw.isEmpty) {
      setState(() => _error = 'Enter your doctor’s profile id.');
      return;
    }
    setState(() {
      _opening = true;
      _error = null;
    });
    try {
      await SettingsStorage().saveChatDoctorProfileId(raw);
      final id = await _api.ensureConversationForDoctor(raw);
      if (!mounted) {
        return;
      }
      setState(() {
        _conversationId = id;
      });
      await _loadConversations();
      _startPoll();
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() => _opening = false);
      }
    }
  }

  Future<void> _confirmClearChat() async {
    final cid = _conversationId;
    if (cid == null) {
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear chat?'),
        content: Text(
          'This removes all messages between you and $titleName for both of you. '
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Clear',
              style: TextStyle(color: Colors.red.shade400),
            ),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) {
      return;
    }
    setState(() => _loading = true);
    try {
      await _api.clearMessages(cid);
      if (!mounted) {
        return;
      }
      setState(() {
        _messages = [];
        _error = null;
      });
      await _loadConversations();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Chat cleared')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    final cid = _conversationId;
    if (text.isEmpty || cid == null || _sending) {
      return;
    }
    setState(() => _sending = true);
    _input.clear();
    try {
      await _api.sendMessage(cid, text);
      if (!mounted) {
        return;
      }
      await _reloadMessages(showSpinner: false);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 200), () {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  PatientChatConversation? get _selectedConv {
    final id = _conversationId;
    if (id == null) {
      return null;
    }
    try {
      return _conversations.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    _poll?.cancel();
    _bootstrapDoctorId.dispose();
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!AppServices.auth.isAuthenticated) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Sign in to use clinic messaging.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70),
          ),
        ),
      );
    }

    final titleName = _selectedConv?.otherPartyName ?? 'your doctor';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_conversations.length > 1)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: 'Conversation',
                labelStyle: const TextStyle(color: Colors.grey),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade700),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFB6F36B)),
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  dropdownColor: const Color(0xFF171B22),
                  value: _conversationId,
                  style: const TextStyle(color: Colors.white),
                  items: _conversations
                      .map(
                        (c) => DropdownMenuItem(
                          value: c.id,
                          child: Text(c.otherPartyName),
                        ),
                      )
                      .toList(),
                  onChanged: (v) async {
                    if (v == null) {
                      return;
                    }
                    _poll?.cancel();
                    setState(() {
                      _conversationId = v;
                      _messages = [];
                    });
                    await _reloadMessages();
                    _startPoll();
                  },
                ),
              ),
            ),
          ),
        if (_conversationId != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 12, 8, 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Chat with $titleName',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Clear chat',
                  onPressed: _loading ? null : _confirmClearChat,
                  icon: Icon(
                    Icons.delete_outline,
                    color: Colors.grey.shade400,
                  ),
                ),
              ],
            ),
          ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text(
              _error!,
              style: TextStyle(color: Colors.red.shade300, fontSize: 12),
            ),
          ),
        Expanded(
          child: Container(
            color: const Color(0xFF0F1218),
            child: _loading && _conversationId != null && _messages.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _conversationId == null
                    ? SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'No conversation yet. If your doctor is already linked in the web app, paste their doctor profile id (Mongo ObjectId). You can also save it in Settings.',
                              style: TextStyle(
                                color: Colors.grey.shade400,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: _bootstrapDoctorId,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                hintText: 'Doctor profile id',
                                hintStyle: TextStyle(color: Colors.grey.shade600),
                                filled: true,
                                fillColor: const Color(0xFF171B22),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            FilledButton(
                              onPressed: _opening ? null : _openWithDoctorId,
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFFB6F36B),
                                foregroundColor: const Color(0xFF0F1218),
                              ),
                              child: _opening
                                  ? const SizedBox(
                                      height: 22,
                                      width: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Color(0xFF0F1218),
                                      ),
                                    )
                                  : const Text('Open conversation'),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scroll,
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length,
                        itemBuilder: (context, i) {
                          final m = _messages[i];
                          final mine = m.senderRole == 'PATIENT';
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              mainAxisAlignment: mine
                                  ? MainAxisAlignment.end
                                  : MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                if (!mine) ...[
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundColor: Colors.grey.shade700,
                                    child: const Icon(
                                      Icons.local_hospital_outlined,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                Flexible(
                                  child: Column(
                                    crossAxisAlignment: mine
                                        ? CrossAxisAlignment.end
                                        : CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 10,
                                        ),
                                        decoration: BoxDecoration(
                                          color: mine
                                              ? const Color(0xFFB6F36B)
                                              : const Color(0xFF171B22),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: mine
                                              ? null
                                              : Border.all(
                                                  color: const Color(0xFF2A2E35),
                                                ),
                                        ),
                                        child: Text(
                                          m.content,
                                          style: TextStyle(
                                            color: mine
                                                ? const Color(0xFF0F1218)
                                                : Colors.white,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        DateFormat.yMd()
                                            .add_jms()
                                            .format(m.createdAt.toLocal()),
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (mine) ...[
                                  const SizedBox(width: 8),
                                  const CircleAvatar(
                                    radius: 16,
                                    backgroundColor: Color(0xFFB6F36B),
                                    child: Icon(
                                      Icons.person,
                                      size: 16,
                                      color: Color(0xFF0F1218),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ),
        if (_conversationId != null)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Color(0xFF171B22),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _input,
                    minLines: 1,
                    maxLines: 4,
                    enabled: !_sending,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Type a message…',
                      hintStyle: const TextStyle(color: Colors.grey),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                    onSubmitted: (_) => _send(),
                  ),
                ),
                const SizedBox(width: 8),
                FloatingActionButton(
                  mini: true,
                  backgroundColor: const Color(0xFFB6F36B),
                  onPressed: _sending ? null : _send,
                  child: _sending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF0F1218),
                          ),
                        )
                      : const Icon(Icons.send, color: Color(0xFF0F1218)),
                ),
              ],
            ),
          ),
      ],
    );
  }

}

class _AiChatPanel extends StatefulWidget {
  const _AiChatPanel();

  @override
  State<_AiChatPanel> createState() => _AiChatPanelState();
}

class _AiChatPanelState extends State<_AiChatPanel> {
  GeminiAiService? _aiService;
  bool _aiBootstrapping = true;
  late final VoiceAgentService _voiceService;
  final List<AiChatMessage> _messages = [];
  final TextEditingController _messageController = TextEditingController();
  bool _isLoading = false;
  bool _isListening = false;
  late ScrollController _scrollController;
  final Uuid _uuid = const Uuid();

  String _aiChatAccountKey() {
    final u = AppServices.auth.currentUser;
    if (u != null) {
      if (u.id.isNotEmpty) return u.id;
      if (u.email.isNotEmpty) return u.email;
    }
    final p = AppServices.auth.patientProfile;
    if (p != null && p.userId.isNotEmpty) {
      return p.userId;
    }
    return 'local_guest';
  }

  /// Gemini requires history to start with `user` and end before a new send with `model`.
  List<Content> _storedToGeminiHistory(List<AiChatStoredMessage> stored) {
    final contents = <Content>[];
    for (final s in stored) {
      if (s.isUser) {
        contents.add(Content.text(s.body));
      } else {
        contents.add(Content.model([TextPart(s.body)]));
      }
    }
    while (contents.isNotEmpty && contents.first.role == 'model') {
      contents.removeAt(0);
    }
    while (contents.isNotEmpty && contents.last.role == 'user') {
      contents.removeLast();
    }
    const maxContents = 80;
    if (contents.length > maxContents) {
      contents.removeRange(0, contents.length - maxContents);
      while (contents.isNotEmpty && contents.first.role == 'model') {
        contents.removeAt(0);
      }
      while (contents.isNotEmpty && contents.last.role == 'user') {
        contents.removeLast();
      }
    }
    return contents;
  }

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _voiceService = VoiceAgentService();
    _setupVoiceAgent();
    _bootstrapAi();
  }

  Future<void> _bootstrapAi() async {
    final accountKey = _aiChatAccountKey();
    List<AiChatStoredMessage> stored = [];
    try {
      stored = await PainpalDatabase.instance.fetchAiChatMessages(accountKey);
    } catch (_) {}

    String? ctx;
    try {
      ctx = await PatientAiContextBuilder.build();
    } catch (_) {
      ctx = null;
    }

    final history = _storedToGeminiHistory(stored);
    final hasPatientContext = ctx != null && ctx.trim().isNotEmpty;

    if (!mounted) {
      return;
    }
    try {
      setState(() {
        _aiService = GeminiAiService(
          patientContext: ctx,
          chatHistory: history,
        );
        _aiBootstrapping = false;
        _messages.clear();
        if (stored.isEmpty) {
          _messages.add(
            AiChatMessage(
              id: _uuid.v4(),
              text: hasPatientContext
                  ? 'Hello! I\'m Painpal AI. I\'ve loaded your recent migraine logs and clinic summary so I can answer questions in context. This is not medical advice—ask your doctor for clinical decisions. How can I help?'
                  : 'Hello! I\'m Painpal AI, your migraine and pain management assistant. You can type your message or use the microphone icon to speak. How can I help you today?',
              isUser: false,
              timestamp: DateTime.now(),
            ),
          );
        } else {
          for (final s in stored) {
            _messages.add(
              AiChatMessage(
                id: s.id,
                text: s.body,
                isUser: s.isUser,
                timestamp: s.createdAt,
              ),
            );
          }
        }
      });
      if (stored.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
      }
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _aiBootstrapping = false;
        _aiService = null;
        _messages.clear();
        if (stored.isNotEmpty) {
          for (final s in stored) {
            _messages.add(
              AiChatMessage(
                id: s.id,
                text: s.body,
                isUser: s.isUser,
                timestamp: s.createdAt,
              ),
            );
          }
        }
        _messages.add(
          AiChatMessage(
            id: _uuid.v4(),
            text:
                'AI could not start (check Gemini API key in .env). You can still use clinic chat from the Messages tab.',
            isUser: false,
            timestamp: DateTime.now(),
          ),
        );
      });
    }
  }

  void _setupVoiceAgent() {
    _voiceService.onSpeechResult = (recognizedWords) {
      setState(() {
        _messageController.text = recognizedWords;
      });
      _sendMessage();
    };

    _voiceService.onListeningStart = () {
      if (mounted) {
        setState(() {
          _isListening = true;
        });
      }
    };

    _voiceService.onListeningEnd = () {
      if (mounted) {
        setState(() {
          _isListening = false;
        });
      }
    };

    _voiceService.onError = (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Voice error: $error'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isListening = false;
        });
      }
    };
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _aiBootstrapping || _aiService == null) {
      return;
    }

    final svc = _aiService!;
    final accountKey = _aiChatAccountKey();
    final userId = _uuid.v4();

    setState(() {
      _messages.add(
        AiChatMessage(
          id: userId,
          text: text,
          isUser: true,
          timestamp: DateTime.now(),
        ),
      );
      _isLoading = true;
    });

    try {
      await PainpalDatabase.instance.insertAiChatMessage(
        accountKey: accountKey,
        id: userId,
        isUser: true,
        body: text,
      );
    } catch (_) {
      // Still try to reach the model; persistence can be retried later.
    }

    _messageController.clear();
    _scrollToBottom();

    try {
      final response = await svc.sendMessage(text);
      final botId = _uuid.v4();
      final now = DateTime.now();

      setState(() {
        _messages.add(
          AiChatMessage(
            id: botId,
            text: response,
            isUser: false,
            timestamp: now,
          ),
        );
        _isLoading = false;
      });

      try {
        await PainpalDatabase.instance.insertAiChatMessage(
          accountKey: accountKey,
          id: botId,
          isUser: false,
          body: response,
        );
        await PainpalDatabase.instance.pruneAiChatMessages(accountKey);
      } catch (_) {}

      await _voiceService.speak(response);

      _scrollToBottom();
    } catch (e) {
      final errId = _uuid.v4();
      const errText = 'Sorry, something went wrong. Please try again.';
      setState(() {
        _messages.add(
          AiChatMessage(
            id: errId,
            text: errText,
            isUser: false,
            timestamp: DateTime.now(),
          ),
        );
        _isLoading = false;
      });
      try {
        await PainpalDatabase.instance.insertAiChatMessage(
          accountKey: accountKey,
          id: errId,
          isUser: false,
          body: errText,
        );
      } catch (_) {}
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

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _aiService?.dispose();
    _voiceService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_aiBootstrapping) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Loading your records for AI…',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: Container(
            width: double.maxFinite,
            color: const Color(0xFF0F1218),
            padding: const EdgeInsets.all(16),
            child: ListView.builder(
              controller: _scrollController,
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length) {
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
                          style: TextStyle(color: Colors.grey, fontSize: 12),
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
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Color(0xFF171B22),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(16),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  maxLines: null,
                  minLines: 1,
                  enabled:
                      !_isLoading && !_isListening && _aiService != null,
                  decoration: InputDecoration(
                    hintText:
                        _isListening ? 'Listening...' : 'Ask me anything...',
                    hintStyle: const TextStyle(color: Colors.grey),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF2A2E35)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF2A2E35)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFB6F36B)),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                  style: const TextStyle(color: Colors.white),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              const SizedBox(width: 8),
              FloatingActionButton(
                mini: true,
                backgroundColor: _isListening
                    ? const Color(0xFFFF6B6B)
                    : const Color(0xFFB6F36B),
                onPressed:
                    _aiService == null ? null : _toggleListening,
                tooltip: _isListening ? 'Stop listening' : 'Start listening',
                child: Icon(
                  _isListening ? Icons.mic : Icons.mic_none,
                  color: const Color(0xFF0F1218),
                  size: 20,
                ),
              ),
              const SizedBox(width: 8),
              FloatingActionButton(
                mini: true,
                backgroundColor: const Color(0xFFB6F36B),
                onPressed: _isLoading || _isListening || _aiService == null
                    ? null
                    : _sendMessage,
                tooltip: 'Send message',
                child: Icon(
                  Icons.send,
                  color: const Color(0xFF0F1218),
                  size: _isLoading ? 16 : 20,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMessageBubble(AiChatMessage message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: message.isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!message.isUser)
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: Color(0xFFB6F36B),
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
                    : Border.all(color: const Color(0xFF2A2E35), width: 1),
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

class ChatButton extends StatefulWidget {
  const ChatButton({this.onPressed, super.key});

  final VoidCallback? onPressed;

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
        tooltip: 'Clinic chat & AI assistant',
        child: const Icon(
          Icons.chat_bubble_outline,
          color: Color(0xFF0F1218),
          size: 28,
        ),
      ),
    );
  }
}
