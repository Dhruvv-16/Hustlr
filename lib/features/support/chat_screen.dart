import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/app_localizations.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();

  final List<Map<String, dynamic>> _messages = [];
  bool _isInit = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;
    setState(() {
      _messages.add({
        'isUser': true,
        'text': _messageController.text,
        'time': 'Just now',
      });
      _messageController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;
    final l10n = AppLocalizations.of(context)!;

    if (!_isInit) {
      _messages.add({
        'isUser': false,
        'text': l10n.chat_bot_greeting,
        'time': 'Just now',
      });
      _isInit = true;
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          l10n.chat_live_support,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: theme.colorScheme.onSurface,
            letterSpacing: -0.5,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: theme.colorScheme.onSurface),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.close_rounded, color: theme.colorScheme.onSurface),
            onPressed: () => context.pop(),
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return _buildChatBubble(msg['text'], msg['time'], msg['isUser'], theme, primaryColor);
              },
            ),
          ),
          Flexible(
            flex: 0,
            child: SingleChildScrollView(
              child: _buildInputSection(theme, primaryColor, isDark, l10n),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatBubble(String text, String time, bool isUser, ThemeData theme, Color primaryColor) {
    final bubbleColor = isUser ? theme.cardColor : primaryColor;
    final textColor = isUser ? theme.colorScheme.onSurface : Colors.black;

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 18,
              backgroundColor: theme.cardColor,
              child: const Icon(Icons.support_agent_rounded, size: 20),
            ),
            const SizedBox(width: 12),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(24),
                  topRight: const Radius.circular(24),
                  bottomLeft: isUser ? const Radius.circular(24) : const Radius.circular(4),
                  bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Text(
                text,
                style: TextStyle(
                  color: textColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            time,
            style: TextStyle(
              color: theme.colorScheme.onSurface.withOpacity(0.4),
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 12),
            CircleAvatar(
              radius: 18,
              backgroundColor: primaryColor.withOpacity(0.2),
              child: Icon(Icons.person_outline_rounded, size: 20, color: primaryColor),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInputSection(ThemeData theme, Color primaryColor, bool isDark, AppLocalizations l10n) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, -5)),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(
                      border: Border.all(color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1)),
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Icon(Icons.emoji_emotions_outlined, color: theme.colorScheme.onSurface.withOpacity(0.5)),
                        ),
                        Expanded(
                          child: TextField(
                            controller: _messageController,
                            style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.w600),
                            decoration: InputDecoration(
                              hintText: l10n.chat_hint,
                              hintStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.4), fontWeight: FontWeight.w600),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Icon(Icons.mic_none_rounded, color: theme.colorScheme.onSurface.withOpacity(0.5)),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                InkWell(
                  onTap: _sendMessage,
                  borderRadius: BorderRadius.circular(28),
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: isDark ? theme.colorScheme.surface : Colors.black,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.send_rounded, color: primaryColor, size: 24),
                  ),
                ),
              ],
            ),
          ),
          GridView(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 160,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              mainAxisExtent: 110,
            ),
            children: [
              _buildAttachGridItem(Icons.water_drop_outlined, l10n.chat_attach_weather, true, theme, primaryColor),
              _buildAttachGridItem(Icons.badge_outlined, l10n.chat_attach_id, false, theme, primaryColor),
              _buildAttachGridItem(Icons.receipt_long_outlined, l10n.chat_attach_receipt, false, theme, primaryColor),
              _buildAttachGridItem(Icons.account_balance_wallet_outlined, 'Attach payment\nrecords', false, theme, primaryColor),
              _buildAttachGridItem(Icons.account_balance_outlined, 'Attach bank\nrecords', false, theme, primaryColor),
              _buildAttachGridItem(Icons.gavel_rounded, 'Attach legal\ndocuments', false, theme, primaryColor),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAttachGridItem(IconData icon, String text, bool isFilled, ThemeData theme, Color primaryColor) {
    return Container(
      decoration: BoxDecoration(
        color: isFilled ? (theme.brightness == Brightness.dark ? const Color(0xFF1c1f1c) : Colors.black) : theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: isFilled ? null : Border.all(color: theme.brightness == Brightness.dark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: isFilled ? primaryColor : theme.colorScheme.onSurface.withOpacity(0.6),
            size: 28,
          ),
          const Spacer(),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isFilled ? Colors.white : theme.colorScheme.onSurface,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}
