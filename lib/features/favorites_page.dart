import 'package:flutter/material.dart';

import '../app/app_store.dart';
import '../core/auth_gate.dart';
import '../core/widgets.dart';
import '../l10n/app_localizations.dart';
import 'property_detail_page.dart';

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final items = store.favoriteProperties;
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('Tin yêu thích'))),
      body: SingleChildScrollView(
        child: PageContainer(
          child: !store.isLoggedIn
              ? EmptyState(
                  icon: Icons.lock_outline,
                  title: context.tr('Đăng nhập để xem tin yêu thích'),
                  message: context.tr(
                    'Danh sách yêu thích được đồng bộ theo tài khoản của bạn.',
                  ),
                  action: FilledButton(
                    onPressed: () => AuthGate.ensureLoggedIn(context),
                    child: Text(context.tr('Đăng nhập')),
                  ),
                )
              : items.isEmpty
                  ? EmptyState(
                      icon: Icons.favorite_border,
                      title: context.tr('Chưa có tin yêu thích'),
                      message: context.tr(
                        'Nhấn biểu tượng trái tim để lưu bất động sản bạn quan tâm.',
                      ),
                    )
                  : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SectionHeader(
                      title: context.tr('{count} tin đã lưu', {'count': items.length}),
                      subtitle: context.tr('Danh sách yêu thích được đồng bộ theo tài khoản'),
                    ),
                    const SizedBox(height: 12),
                    PropertyGrid(
                      properties: items,
                      onPropertyTap: (property) {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => PropertyDetailPage(propertyId: property.id),
                          ),
                        );
                      },
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
