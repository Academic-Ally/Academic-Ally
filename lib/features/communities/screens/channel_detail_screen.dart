import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../config/theme.dart';
import '../../../models/channel_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/communities_provider.dart';

class ChannelDetailScreen extends ConsumerStatefulWidget {
  final String channelId;

  const ChannelDetailScreen({super.key, required this.channelId});

  @override
  ConsumerState<ChannelDetailScreen> createState() =>
      _ChannelDetailScreenState();
}

class _ChannelDetailScreenState extends ConsumerState<ChannelDetailScreen> {
  final _composer = TextEditingController();
  final _scrollController = ScrollController();
  bool _sending = false;

  @override
  void dispose() {
    _composer.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _composer.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await sendMessage(
          ref: ref, channelId: widget.channelId, text: text);
      _composer.clear();
      // Jump to bottom after the stream re-emits. Post-frame ensures layout
      // is done before we animate.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not send: $e'),
            backgroundColor: const Color(0xFFFF0101),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark
        ? Theme.of(context).scaffoldBackgroundColor
        : const Color(0xFFF1F1FA);
    final channelAsync =
        ref.watch(channelDetailProvider(widget.channelId));
    final messagesAsync =
        ref.watch(channelMessagesProvider(widget.channelId));
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        title: channelAsync.when(
          loading: () => Text('Loading…',
              style: GoogleFonts.poppins(fontSize: 16)),
          error: (_, _) => Text('Channel',
              style: GoogleFonts.poppins(fontSize: 16)),
          data: (channel) {
            if (channel == null) {
              return Text('Channel',
                  style: GoogleFonts.poppins(fontSize: 16));
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '# ${channel.name}',
                  style: GoogleFonts.poppins(
                      fontSize: 16, fontWeight: FontWeight.w700),
                ),
                Text(
                  channel.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                      fontSize: 11, fontWeight: FontWeight.w400),
                ),
              ],
            );
          },
        ),
        actions: [
          channelAsync.when(
            data: (channel) {
              if (channel != null &&
                  currentUser != null &&
                  channel.createdBy == currentUser.uid) {
                return IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _confirmDeleteChannel(context),
                );
              }
              return const SizedBox.shrink();
            },
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: messagesAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    'Could not load messages.\n$e',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                        fontSize: 13, color: Colors.grey[700]),
                  ),
                ),
              ),
              data: (messages) {
                if (messages.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: Text(
                        'Be the first to say something 👋',
                        style: GoogleFonts.poppins(
                            fontSize: 13, color: Colors.grey[600]),
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 12),
                  itemCount: messages.length,
                  itemBuilder: (_, i) {
                    final msg = messages[i];
                    final isMine = msg.authorUid == currentUser?.uid;
                    return _MessageBubble(
                      message: msg,
                      isMine: isMine,
                      onLongPress: isMine
                          ? () => _confirmDeleteMessage(context, msg.id)
                          : null,
                    );
                  },
                );
              },
            ),
          ),
          _Composer(
            controller: _composer,
            sending: _sending,
            onSend: _send,
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteChannel(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete channel?'),
        content: const Text(
            'The channel will be removed for everyone. Existing messages become orphans.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style:
                TextButton.styleFrom(foregroundColor: const Color(0xFFFF0101)),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await deleteChannel(widget.channelId);
    if (context.mounted) Navigator.pop(context);
  }

  Future<void> _confirmDeleteMessage(
      BuildContext context, String messageId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete message?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style:
                TextButton.styleFrom(foregroundColor: const Color(0xFFFF0101)),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await deleteMessage(channelId: widget.channelId, messageId: messageId);
  }
}

class _MessageBubble extends StatelessWidget {
  final ChannelMessage message;
  final bool isMine;
  final VoidCallback? onLongPress;

  const _MessageBubble({
    required this.message,
    required this.isMine,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final align = isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final bubbleColor = isMine
        ? AppTheme.primaryColor
        : (isDark ? Colors.grey[800] : Colors.white);
    final textColor = isMine
        ? Colors.white
        : (isDark ? Colors.white : const Color(0xFF161719));

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: align,
        children: [
          if (!isMine)
            Padding(
              padding: const EdgeInsets.only(left: 6, bottom: 2),
              child: Text(
                message.authorName,
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey[600],
                ),
              ),
            ),
          GestureDetector(
            onLongPress: onLongPress,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: bubbleColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message.text,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: textColor,
                        height: 1.4,
                      ),
                    ),
                    if (message.createdAt != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        _fmtTime(message.createdAt!),
                        style: GoogleFonts.poppins(
                          fontSize: 9,
                          color: isMine
                              ? Colors.white.withValues(alpha: 0.7)
                              : Colors.grey[500],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _fmtTime(DateTime d) {
    final local = d.toLocal();
    final h = local.hour.toString().padLeft(2, '0');
    final m = local.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

class _Composer extends StatelessWidget {
  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;

  const _Composer({
    required this.controller,
    required this.sending,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 6, 10, 10),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                maxLines: 4,
                minLines: 1,
                style: GoogleFonts.poppins(fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Message…',
                  hintStyle: GoogleFonts.poppins(
                      fontSize: 13, color: Colors.grey[500]),
                  filled: true,
                  fillColor: isDark ? Colors.grey[850] : Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            SizedBox(
              width: 44,
              height: 44,
              child: ElevatedButton(
                onPressed: sending ? null : onSend,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.zero,
                  shape: const CircleBorder(),
                ),
                child: sending
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send, size: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
