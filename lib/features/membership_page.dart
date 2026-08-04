import 'package:flutter/material.dart';

import '../app/app_store.dart';
import '../core/app_theme.dart';
import '../core/widgets.dart';
import '../data/mock_data.dart';
import '../l10n/app_localizations.dart';

class MembershipPage extends StatelessWidget {
  const MembershipPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('Gói hội viên'))),
      body: SingleChildScrollView(
        child: PageContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(
                title: context.tr('Chọn gói phù hợp'),
                subtitle: context.tr(
                  'Hạn mức đăng tin và quyền lợi môi giới theo hệ thống web NhaWOW',
                ),
              ),
              const SizedBox(height: 14),
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 900 ? 3 : (constraints.maxWidth >= 600 ? 2 : 1);
                  final gap = 14.0;
                  final width = columns == 1
                      ? constraints.maxWidth
                      : (constraints.maxWidth - gap * (columns - 1)) / columns;
                  return Wrap(
                    spacing: gap,
                    runSpacing: gap,
                    children: mockMembershipPlans.map((plan) {
                      final active = store.membershipCode == plan.code;
                      return SizedBox(
                        width: width,
                        child: Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                            side: BorderSide(
                              color: plan.isRecommended || active ? AppTheme.primary : const Color(0xFFE8EDF4),
                              width: plan.isRecommended || active ? 1.7 : 1,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(18),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        context.tr(plan.name),
                                        style: const TextStyle(color: AppTheme.navy, fontSize: 20, fontWeight: FontWeight.w900),
                                      ),
                                    ),
                                    if (plan.isRecommended)
                                      MiniBadge(label: context.tr('Đề xuất'), color: AppTheme.primaryDark),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  context.tr(plan.priceLabel),
                                  style: const TextStyle(color: AppTheme.danger, fontSize: 22, fontWeight: FontWeight.w900),
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  context.tr(
                                    '{daily} tin/ngày · {monthly} tin/tháng',
                                    {
                                      'daily': plan.dailyPostLimit,
                                      'monthly': plan.monthlyPostLimit,
                                    },
                                  ),
                                ),
                                Text(
                                  context.tr(
                                    '{count} lượt ghim Top miễn phí',
                                    {'count': plan.freeTopLimit},
                                  ),
                                ),
                                const Divider(height: 24),
                                ...plan.benefits.map(
                                  (item) => Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.check_circle, color: Colors.green, size: 18),
                                        const SizedBox(width: 8),
                                        Expanded(child: Text(context.tr(item))),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                SizedBox(
                                  width: double.infinity,
                                  child: active
                                      ? OutlinedButton(onPressed: null, child: Text(context.tr('Đang sử dụng')))
                                      : FilledButton(
                                          onPressed: () {
                                            store.buyMembership(plan.code);
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  context.tr(
                                                    'Đã chuyển sang gói {plan} (bản mô phỏng).',
                                                    {'plan': context.tr(plan.name)},
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                          child: Text(context.tr('Chọn gói')),
                                        ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
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
