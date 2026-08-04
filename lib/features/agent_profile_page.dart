import 'package:flutter/material.dart';

import '../app/app_store.dart';
import '../core/app_image.dart';
import '../core/app_theme.dart';
import '../core/widgets.dart';
import '../models/models.dart';
import '../l10n/app_localizations.dart';
import 'property_detail_page.dart';

class AgentProfilePage extends StatelessWidget {
  const AgentProfilePage({required this.agent, super.key});

  final AgentModel agent;

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final items = store.properties.where((item) => item.owner.id == agent.id).toList();
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('Hồ sơ người đăng'))),
      body: SingleChildScrollView(
        child: PageContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      AppAvatar(
                        url: agent.avatarUrl,
                        fallbackText: agent.name,
                        radius: 39,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              agent.name,
                              style: const TextStyle(color: AppTheme.navy, fontSize: 22, fontWeight: FontWeight.w900),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              agent.displayLevelName,
                            ),
                            const SizedBox(height: 7),
                            Wrap(
                              spacing: 7,
                              runSpacing: 7,
                              children: [
                                MiniBadge(label: agent.membershipCode, color: AppTheme.primaryDark),
                                if (agent.isBroker)
                                  MiniBadge(
                                    label: context.tr(
                                      '{count} tin xác thực',
                                      {'count': agent.verifiedListingCount},
                                    ),
                                    color: Colors.green,
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      IconButton.filledTonal(onPressed: () {}, icon: const Icon(Icons.chat_bubble_outline)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 22),
              SectionHeader(
                title: context.tr('Bất động sản đang hiển thị'),
                subtitle: context.tr('{count} tin đăng', {'count': items.length}),
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
