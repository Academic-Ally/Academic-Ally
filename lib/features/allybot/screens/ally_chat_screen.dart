import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/theme.dart';
import '../../../models/chat_session_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/allybot_provider.dart';

class AllyChatScreen extends ConsumerStatefulWidget {
  final String? sessionId;
  final String? resourceId;
  final String? resourceName;
  final String? subject;
  final String? storageId;

  const AllyChatScreen({
    super.key,
    this.sessionId,
    this.resourceId,
    this.resourceName,
    this.subject,
    this.storageId,
  });

  @override
  ConsumerState<AllyChatScreen> createState() => _AllyChatScreenState();
}

class _AllyChatScreenState extends ConsumerState<AllyChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  String? _currentSessionId;
  bool _isSending = false;
  bool _isInitiating = false;

  @override
  void initState() {
    super.initState();
    _currentSessionId = widget.sessionId;
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _initiateChatIfNeeded() async {
    if (_currentSessionId != null) return;

    final user = ref.read(currentUserProvider);
    if (user == null) return;

    setState(() => _isInitiating = true);

    try {
      final service = ref.read(allyBotServiceProvider);
      final sessionId = await service.initiateChat(
        uid: user.uid,
        pdfUrl: widget.storageId ?? '',
        resourceName: widget.resourceName ?? '',
        subject: widget.subject ?? '',
      );

      if (mounted && sessionId != null) {
        setState(() {
          _currentSessionId = sessionId;
          _isInitiating = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isInitiating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: const Color(0xFFFF0101),
          ),
        );
      }
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    // Initiate chat first if no session
    if (_currentSessionId == null) {
      await _initiateChatIfNeeded();
      if (_currentSessionId == null) return;
    }

    final user = ref.read(currentUserProvider);
    if (user == null) return;

    _messageController.clear();
    setState(() => _isSending = true);

    try {
      final session = ref
          .read(chatSessionProvider(_currentSessionId!))
          .value;

      final service = ref.read(allyBotServiceProvider);
      await service.sendMessage(
        uid: user.uid,
        sessionId: _currentSessionId!,
        sourceId: session?.sourceId ?? '',
        message: text,
      );

      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: const Color(0xFFFF0101),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? Theme.of(context).scaffoldBackgroundColor
          : const Color(0xFFF1F1FA),
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Row(
          children: [
            const Icon(Icons.smart_toy_outlined, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                widget.resourceName ?? 'AllyBot Chat',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Chat messages
          Expanded(
            child: _currentSessionId != null
                ? _buildChatMessages()
                : _buildInitialState(),
          ),

          // Input bar
          _buildInputBar(isDark),
        ],
      ),
    );
  }

  Widget _buildInitialState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.smart_toy_outlined,
                size: 60, color: AppTheme.primaryColor),
            const SizedBox(height: 20),
            const Text(
              'Ask AllyBot about this document',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Type a question below to start a conversation. AllyBot will analyze the PDF and answer your questions.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 14,
                height: 1.5,
              ),
            ),
            if (_isInitiating)
              const Padding(
                padding: EdgeInsets.only(top: 24),
                child: CircularProgressIndicator(color: AppTheme.primaryColor),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatMessages() {
    final sessionAsync = ref.watch(chatSessionProvider(_currentSessionId!));

    return sessionAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryColor),
      ),
      error: (e, _) => Center(
        child: Text('Error: $e', style: TextStyle(color: Colors.grey[500])),
      ),
      data: (session) {
        if (session == null) {
          return const Center(child: Text('Session not found'));
        }

        final messages = session.conversations;
        _scrollToBottom();

        if (messages.isEmpty) {
          return _buildInitialState();
        }

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          itemCount: messages.length + (_isSending ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == messages.length) {
              // Loading indicator for bot response
              return _buildBotLoadingBubble();
            }
            return _MessageBubble(message: messages[index]);
          },
        );
      },
    );
  }

  Widget _buildBotLoadingBubble() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(top: 8, right: 60),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppTheme.primaryColor,
              ),
            ),
            SizedBox(width: 8),
            Text('Thinking...', style: TextStyle(color: AppTheme.primaryColor)),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
                decoration: InputDecoration(
                  hintText: 'Ask a question...',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: isDark ? Colors.grey[800] : const Color(0xFFF1F1FA),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _isSending || _isInitiating ? null : _sendMessage,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _isSending || _isInitiating
                      ? Colors.grey
                      : AppTheme.primaryColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.send, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          top: 8,
          left: isUser ? 60 : 0,
          right: isUser ? 0 : 60,
        ),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isUser
              ? AppTheme.primaryColor
              : AppTheme.primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
        ),
        child: Text(
          message.message,
          style: TextStyle(
            color: isUser ? Colors.white : const Color(0xFF161719),
            fontSize: 15,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}
