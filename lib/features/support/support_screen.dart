import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../shared/widgets/mobile_container.dart';

// ─── Local Palette ────────────────────────────────────────────────────────────
const _bgScreen   = Color(0xFFF8F9FA); // White-ish background
const _green      = Color(0xFF2E7D32);
const _lightGreen = Color(0xFFE8F5E9);
const _primary    = Color(0xFF1A1A2E);
const _grey       = Color(0xFF6B7280);
const _hint       = Color(0xFF9CA3AF);
const _divider    = Color(0xFFE5E7EB);
const _cardWhite  = Colors.white;

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgScreen,
      appBar: AppBar(
        backgroundColor: _bgScreen,
        elevation: 0,
        leading: BackButton(color: _primary, onPressed: () => context.pop()),
        title: const Text(
          'Help & Support',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: _primary,
          ),
        ),
        centerTitle: true,
      ),
      body: MobileContainer(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              const _SearchBar(),
              const SizedBox(height: 24),
              const _QuickHelpGrid(),
              const SizedBox(height: 32),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Frequently Asked Questions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _primary,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const _FaqAccordion(),
              const SizedBox(height: 32),
              const _TicketCard(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Search Bar ───────────────────────────────────────────────────────────────
class _SearchBar extends StatelessWidget {
  const _SearchBar();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: _cardWhite,
          borderRadius: BorderRadius.circular(28),
          boxShadow: const [
            BoxShadow(
              color: Color(0x05000000),
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 14),
              child: Icon(Icons.search_rounded, color: _hint, size: 20),
            ),
            const Expanded(
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search for help...',
                  hintStyle: TextStyle(color: _hint, fontSize: 14),
                  border: InputBorder.none,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Quick Help Grid ──────────────────────────────────────────────────────────
class _QuickHelpGrid extends StatelessWidget {
  const _QuickHelpGrid();

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.2,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: const [
        _GridCard(
          icon: Icons.chat_bubble_outline_rounded,
          iconColor: _green,
          iconBg: _lightGreen,
          title: 'Live Chat',
          subtitle: 'AVG REPLY: 2 MIN',
          isGreenCaps: true,
        ),
        _GridCard(
          icon: Icons.phone_outlined,
          iconColor: Color(0xFF1976D2),
          iconBg: Color(0xFFE3F2FD),
          title: 'Call Us',
          subtitle: 'Available 24/7',
        ),
        _GridCard(
          icon: Icons.message_rounded,
          iconColor: _green,
          iconBg: _lightGreen,
          title: 'WhatsApp',
          subtitle: 'Instant support',
        ),
        _GridCard(
          icon: Icons.email_outlined,
          iconColor: Color(0xFF7B1FA2),
          iconBg: Color(0xFFF3E5F5),
          title: 'Email',
          subtitle: 'Send a message',
        ),
      ],
    );
  }
}

class _GridCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String subtitle;
  final bool isGreenCaps;

  const _GridCard({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    this.isGreenCaps = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _cardWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: _primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: isGreenCaps ? 10 : 12,
              fontWeight: isGreenCaps ? FontWeight.bold : FontWeight.normal,
              color: isGreenCaps ? _green : _grey,
              letterSpacing: isGreenCaps ? 0.5 : 0,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── FAQ Accordion ────────────────────────────────────────────────────────────
class _FaqAccordion extends StatelessWidget {
  const _FaqAccordion();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: const [
          _FaqItem(
            question: 'How are claims triggered?',
            answer:
                'Our system automatically detects disruptions using weather and platform APIs. When a threshold is breached in your zone and you were active, a claim is generated automatically.',
          ),
          SizedBox(height: 12),
          _FaqItem(
            question: 'When will I receive payout?',
            answer:
                'Payouts process every Sunday night. 70% credits immediately and 30% releases within 48 hours.',
          ),
          SizedBox(height: 12),
          _FaqItem(
            question: 'Can I update my coverage?',
            answer:
                'Yes. Go to Policy → Upgrade. Changes apply from the following Monday.',
          ),
        ],
      ),
    );
  }
}

class _FaqItem extends StatefulWidget {
  final String question;
  final String answer;

  const _FaqItem({required this.question, required this.answer});

  @override
  State<_FaqItem> createState() => _FaqItemState();
}

class _FaqItemState extends State<_FaqItem> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _cardWhite,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Text(
            widget.question,
            style: const TextStyle(
              fontSize: 14,
              color: _primary,
            ),
          ),
          iconColor: _hint,
          collapsedIconColor: _hint,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          onExpansionChanged: (val) => setState(() => _expanded = val),
          children: [
            Text(
              widget.answer,
              style: const TextStyle(
                fontSize: 13,
                color: _grey,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Raise Ticket Card ────────────────────────────────────────────────────────
class _TicketCard extends StatelessWidget {
  const _TicketCard();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _cardWhite,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x05000000),
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Raise a Ticket',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: _primary,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: _bgScreen,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _divider),
              ),
              child: const TextField(
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Describe your issue in detail...',
                  hintStyle: TextStyle(color: _hint, fontSize: 14),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(16),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.attach_file_rounded, color: _green, size: 16),
                const SizedBox(width: 4),
                const Text(
                  'Attach screenshot',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: _green,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                child: const Text(
                  'Submit Ticket',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
