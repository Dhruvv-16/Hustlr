import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/notification_service.dart';

class NotificationBell extends StatelessWidget {
  const NotificationBell({super.key});

  @override
  Widget build(BuildContext context) {
    return StatefulBuilder(
      builder: (context, setState) {
        final hasUnread = NotificationService.instance.unreadCount > 0;
        final isDark = Theme.of(context).brightness == Brightness.dark;
        
        return GestureDetector(
          onTap: () async {
            NotificationService.instance.markAllRead();
            GoRouter.of(context).push('/notifications');
            setState(() {});
          },
          behavior: HitTestBehavior.opaque,
          child: Center(
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.notifications_outlined, size: 22),
                if (hasUnread)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFFFF5252) : const Color(0xFFD32F2F),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Theme.of(context).cardColor,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
