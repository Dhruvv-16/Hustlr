import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/app_localizations.dart';
import '../../services/api_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();

  bool _isTyping = false;

  final ScrollController _scrollController = ScrollController();

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;
    final userText = _messageController.text.trim();
    setState(() {
      _messages.add({'isUser': true, 'text': userText, 'time': 'Just now'});
      _messageController.clear();
      _isTyping = true;
    });
    _scrollToBottom();

    try {
      final res = await ApiService.instance.sendChatMessage(userText);
      final reply = res['response'] as String? ?? 'I encountered an error connecting to my ML brain.';
      if (!mounted) return;
      setState(() {
        _isTyping = false;
        _messages.add({
          'isUser': false,
          'text': reply,
          'time': 'Just now',
        });
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isTyping = false;
        _messages.add({
          'isUser': false,
          'text': 'Network error reaching my ML model. Please try again.',
          'time': 'Just now',
        });
      });
    }
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  final List<Map<String, dynamic>> _messages = [];
  bool _isInit = false;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
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
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (_isTyping && index == _messages.length) {
                  return _buildTypingIndicator(theme, primaryColor);
                }
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

  Widget _buildTypingIndicator(ThemeData theme, Color primaryColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: theme.cardColor,
            child: const Icon(Icons.support_agent_rounded, size: 20),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: primaryColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
                bottomRight: Radius.circular(24),
                bottomLeft: Radius.circular(4),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _Dot(delay: 0),
                const SizedBox(width: 4),
                _Dot(delay: 200),
                const SizedBox(width: 4),
                _Dot(delay: 400),
              ],
            ),
          ),
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
                      color: isDark ? theme.colorScheme.surface : primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.send_rounded, color: isDark ? primaryColor : Colors.white, size: 24),
                  ),
                ),
              ],
            ),
          ),
          // Quick action chips — Hustlr relevant
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _buildQuickChip(Icons.receipt_long_rounded,   'Check my claim',     'What is the status of my claim?',              true,  theme, primaryColor),
                _buildQuickChip(Icons.water_drop_rounded,     'Rain payout',        'How does the rain payout work?',               false, theme, primaryColor),
                _buildQuickChip(Icons.location_on_rounded,    'My zone',            'Tell me about my zone coverage.',              false, theme, primaryColor),
                _buildQuickChip(Icons.currency_rupee_rounded, 'My premium',         'Why is my premium ₹49?',                       false, theme, primaryColor),
                _buildQuickChip(Icons.account_balance_wallet_rounded, 'Withdraw',   'How do I withdraw my payout balance to UPI?',  false, theme, primaryColor),
                _buildQuickChip(Icons.memory_rounded,         'ML Models',          'How does your ML tracking detect fraud?',      false, theme, primaryColor),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _sendPreset(String message) {
    setState(() {
      _messages.add({'isUser': true, 'text': message, 'time': 'Just now'});
      _isTyping = true;
    });
    _scrollToBottom();
    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      setState(() {
        _isTyping = false;
        _messages.add({'isUser': false, 'text': _getAutoReply(message), 'time': 'Just now'});
      });
      _scrollToBottom();
    });
  }

  Widget _buildQuickChip(IconData icon, String label, String presetMessage, bool isFilled, ThemeData theme, Color primaryColor) {
    final isDark = theme.brightness == Brightness.dark;
    final filledBg = isDark ? const Color(0xFF1c1f1c) : primaryColor;
    final emptyBg  = isDark ? const Color(0xFF1c1f1c).withOpacity(0.4) : theme.scaffoldBackgroundColor;
    final borderCol = isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.08);

    return GestureDetector(
      onTap: () => _sendPreset(presetMessage),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isFilled ? filledBg : emptyBg,
          borderRadius: BorderRadius.circular(24),
          border: isFilled ? null : Border.all(color: borderCol),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16,
              color: isFilled ? (isDark ? primaryColor : Colors.white) : theme.colorScheme.onSurface.withOpacity(0.7)),
            const SizedBox(width: 6),
            Text(label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isFilled ? Colors.white : theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Animated bouncing dot for typing indicator
class _Dot extends StatefulWidget {
  final int delay;
  const _Dot({required this.delay});
  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))
      ..repeat(reverse: true);
    _anim = Tween(begin: 0.0, end: -6.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: Interval(widget.delay / 800, 1.0, curve: Curves.easeInOut),
      ),
    );
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Transform.translate(
        offset: Offset(0, _anim.value),
        child: Container(
          width: 8, height: 8,
          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
        ),
      ),
    );
  }
}
