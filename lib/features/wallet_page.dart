import 'package:flutter/material.dart';

import '../app/app_store.dart';
import '../core/app_theme.dart';
import '../core/widgets.dart';
import '../l10n/app_localizations.dart';

class WalletPage extends StatelessWidget {
  const WalletPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('Ví NhaWOW'))),
      body: SingleChildScrollView(
        child: PageContainer(
          maxWidth: 760,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppTheme.navy, AppTheme.primaryDark]),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(context.tr('Số dư khả dụng'), style: TextStyle(color: Colors.white70)),
                    const SizedBox(height: 6),
                    Text(
                      context.tr('{amount} đ', {'amount': _formatMoney(store.walletBalance)}),
                      style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 18),
                    FilledButton.icon(
                      onPressed: () => _showTopup(context, store),
                      style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppTheme.navy),
                      icon: const Icon(Icons.qr_code_2),
                      label: Text(context.tr('Nạp tiền bằng QR')),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SectionHeader(title: context.tr('Lịch sử giao dịch')),
              const SizedBox(height: 12),
              ...store.transactions.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: item.isCredit ? const Color(0xFFEAF8EE) : const Color(0xFFFFEEEE),
                        child: Icon(
                          item.isCredit ? Icons.south_west_rounded : Icons.north_east_rounded,
                          color: item.isCredit ? Colors.green : AppTheme.danger,
                        ),
                      ),
                      title: Text(context.tr(item.title), style: const TextStyle(color: AppTheme.navy, fontWeight: FontWeight.w800)),
                      subtitle: Text('${item.createdAt.day}/${item.createdAt.month}/${item.createdAt.year}'),
                      trailing: Text(
                        context.tr(
                          '{sign}{amount} đ',
                          {
                            'sign': item.isCredit ? '+' : '-',
                            'amount': _formatMoney(item.amount.abs()),
                          },
                        ),
                        style: TextStyle(
                          color: item.isCredit ? Colors.green : AppTheme.danger,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTopup(BuildContext context, AppStore store) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(context.tr('Chọn số tiền nạp'), style: TextStyle(color: AppTheme.navy, fontSize: 20, fontWeight: FontWeight.w900)),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [100000.0, 200000.0, 500000.0, 1000000.0]
                      .map(
                        (amount) => ActionChip(
                          label: Text(context.tr('{amount} đ', {'amount': _formatMoney(amount)})),
                          onPressed: () {
                            store.topupWallet(amount);
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(context.tr('Đã mô phỏng giao dịch nạp tiền thành công.'))),
                            );
                          },
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 14),
                Text(context.tr('Khi kết nối backend, bước này sẽ tạo QR PayOS/SePay và theo dõi trạng thái giao dịch.')),
              ],
            ),
          ),
        );
      },
    );
  }

  static String _formatMoney(double value) {
    final raw = value.round().toString();
    final chars = <String>[];
    for (var i = 0; i < raw.length; i++) {
      chars.add(raw[i]);
      final remaining = raw.length - i - 1;
      if (remaining > 0 && remaining % 3 == 0) chars.add('.');
    }
    return chars.join();
  }
}
