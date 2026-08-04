import 'package:flutter/material.dart';

import '../core/app_assets.dart';
import '../core/app_theme.dart';
import '../core/widgets.dart';
import '../l10n/app_localizations.dart';

class PostingGuidePage extends StatelessWidget {
  const PostingGuidePage({super.key});

  static const List<(String, String)> _steps = <(String, String)>[
    ('Đăng nhập hoặc đăng ký', 'Mở tài khoản NhaWOW để lưu tin, chat và quản lý bài đăng.'),
    ('Điền thông tin đăng ký', 'Nhập thông tin liên hệ chính xác để NhaWOW hỗ trợ khi cần.'),
    ('Xác thực email bằng OTP', 'Nhập mã OTP được gửi tới email để hoàn tất xác thực tài khoản.'),
    ('Tạo bất động sản', 'Chọn nhóm Nhà hoặc Đất & Mặt bằng, sau đó nhập thông tin chi tiết.'),
    ('Quản lý bài đăng', 'Theo dõi trạng thái chờ duyệt, đang hiển thị, đã đóng hoặc đã giao dịch.'),
    ('Đăng ký VR 360°', 'Gửi yêu cầu chụp VR để khách hàng có thể xem không gian từ xa.'),
    ('Trải nghiệm VR trên điện thoại', 'Mở tin có biểu tượng VR 360° và di chuyển giữa các phòng.'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('Hướng dẫn đăng tin'))),
      body: SingleChildScrollView(
        child: PageContainer(
          maxWidth: 860,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Image.asset(
                  AppAssets.postingGuideOverview,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 22),
              Text(
                context.tr('Quy trình sử dụng NhaWOW'),
                style: const TextStyle(
                  color: AppTheme.navy,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                context.tr('Nội dung và hình minh họa được đồng bộ từ trang Hướng dẫn đăng tin của website.'),
                style: const TextStyle(color: Colors.blueGrey, height: 1.45),
              ),
              const SizedBox(height: 18),
              for (var index = 0; index < _steps.length; index++) ...[
                _GuideStep(
                  number: index + 1,
                  title: context.tr(_steps[index].$1),
                  description: context.tr(_steps[index].$2),
                  imageAsset: AppAssets.postingGuideSteps[index],
                ),
                if (index < _steps.length - 1) const SizedBox(height: 14),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _GuideStep extends StatelessWidget {
  const _GuideStep({
    required this.number,
    required this.title,
    required this.description,
    required this.imageAsset,
  });

  final int number;
  final String title;
  final String description;
  final String imageAsset;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 680;
          final image = Container(
            color: const Color(0xFFF4F7FA),
            padding: const EdgeInsets.all(12),
            child: Image.asset(imageAsset, fit: BoxFit.contain),
          );
          final text = Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppTheme.primaryDark,
                  child: Text(
                    '$number',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.navy,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 7),
                Text(description, style: const TextStyle(height: 1.5)),
              ],
            ),
          );

          if (wide) {
            return SizedBox(
              height: 270,
              child: Row(
                children: [
                  Expanded(flex: 5, child: image),
                  Expanded(flex: 4, child: text),
                ],
              ),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 230, child: image),
              text,
            ],
          );
        },
      ),
    );
  }
}
