import 'package:flutter/material.dart';

import '../app/app_store.dart';
import '../core/app_theme.dart';
import '../core/auth_gate.dart';
import '../core/widgets.dart';
import '../l10n/app_localizations.dart';
import 'property_detail_page.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    if (!store.isLoggedIn) {
      return Scaffold(
        appBar: AppBar(title: Text(context.tr('Thông báo'))),
        body: PageContainer(
          maxWidth: 760,
          child: EmptyState(
            icon: Icons.lock_outline,
            title: context.tr('Vui lòng đăng nhập'),
            message: context.tr('Nội dung này chỉ hiển thị cho tài khoản đã đăng nhập.'),
            action: FilledButton(
              onPressed: () => AuthGate.ensureLoggedIn(context),
              child: Text(context.tr('Đăng nhập')),
            ),
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('Thông báo')),
        actions: [
          TextButton(
            onPressed: store.unreadNotificationCount == 0 ? null : store.markAllNotificationsRead,
            child: Text(context.tr('Đọc tất cả')),
          ),
        ],
      ),
      body: PageContainer(
        maxWidth: 760,
        child: store.notifications.isEmpty
            ? EmptyState(
                icon: Icons.notifications_none,
                title: context.tr('Chưa có thông báo'),
                message: context.tr(
                  'Các cập nhật về tin đăng, chat và tài khoản sẽ xuất hiện tại đây.',
                ),
              )
            : ListView.separated(
                itemCount: store.notifications.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final item = store.notifications[index];
                  return Card(
                    color: item.isRead ? Colors.white : const Color(0xFFEAF7FF),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      leading: CircleAvatar(
                        backgroundColor: item.isRead ? const Color(0xFFF0F3F7) : AppTheme.primary,
                        child: Icon(
                          Icons.notifications_outlined,
                          color: item.isRead ? Colors.blueGrey : Colors.white,
                        ),
                      ),
                      title: Text(
                        context.tr(item.title),
                        style: TextStyle(
                          color: AppTheme.navy,
                          fontWeight: item.isRead ? FontWeight.w700 : FontWeight.w900,
                        ),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 5),
                        child: Text(context.tr(item.message)),
                      ),
                      onTap: () {
                        store.markNotificationRead(item.id);
                        if (item.propertyId != null) {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => PropertyDetailPage(propertyId: item.propertyId!),
                            ),
                          );
                        }
                      },
                    ),
                  );
                },
              ),
      ),
    );
  }
}
