import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/widgets.dart';

class ServiceIntroPage extends StatelessWidget {
  const ServiceIntroPage({super.key});

  static const List<_OverviewItem> _overviewItems = [
    _OverviewItem(
      icon: Icons.workspace_premium_outlined,
      title: 'Gói hội viên',
      subtitle: 'Tăng quota đăng tin, ưu tiên hiển thị và nhận quyền lợi theo hạng.',
      meta: 'Hiệu lực 1 tháng • Trừ từ Ví NhaWOW',
    ),
    _OverviewItem(
      icon: Icons.post_add_outlined,
      title: 'Đăng tin lẻ & Combo',
      subtitle: 'Đăng thêm tin hoặc mua kèm dịch vụ ngay ở bước tạo tin.',
      meta: 'Chỉ trừ tiền khi đăng tin thành công',
    ),
    _OverviewItem(
      icon: Icons.auto_graph_outlined,
      title: 'Dịch vụ gia tăng',
      subtitle: 'Tăng hiệu quả hiển thị, kiểm duyệt và độ tin cậy cho từng tin.',
      meta: 'Mua theo lượt • Một số lượt Top miễn phí theo gói',
    ),
  ];

  static const List<_MembershipPlan> _plans = [
    _MembershipPlan(
      name: 'Miễn phí',
      price: '0 đ / tháng',
      dayLimit: '2 tin/ngày',
      monthLimit: '30 tin/tháng',
      sortPriority: '0',
      benefits: [
        'Sắp xếp thường',
        'Phù hợp khi đăng ít tin',
      ],
    ),
    _MembershipPlan(
      name: 'Cơ bản',
      price: '300.000 đ / tháng',
      dayLimit: '5 tin/ngày',
      monthLimit: '80 tin/tháng',
      sortPriority: '10',
      benefits: [
        'Ưu tiên hiển thị hơn gói miễn phí',
        'Có nhãn hội viên',
      ],
    ),
    _MembershipPlan(
      name: 'Cao cấp',
      price: '500.000 đ / tháng',
      dayLimit: '8 tin/ngày',
      monthLimit: '150 tin/tháng',
      sortPriority: '20',
      benefits: [
        '1 lượt Ghim Top 7 ngày miễn phí / tháng',
        'Hỗ trợ ưu tiên',
      ],
    ),
    _MembershipPlan(
      name: 'Tối thượng',
      price: '800.000 đ / tháng',
      dayLimit: '12 tin/ngày',
      monthLimit: '250 tin/tháng',
      sortPriority: '30',
      benefits: [
        '3 lượt Ghim Top miễn phí / tháng',
        'Fast Review cho tin đủ điều kiện',
        'Hỗ trợ ưu tiên / 1-1',
      ],
    ),
  ];

  static const List<_PriceItem> _postingItems = [
    _PriceItem(
      title: 'Đăng tin lẻ',
      price: '10.000 đ / tin',
      description: '1 tin, chu kỳ hiển thị 30 ngày. Phù hợp khi hết quota hoặc muốn đăng thêm.',
    ),
    _PriceItem(
      title: 'Combo Chứng nhận',
      price: '15.000 đ',
      description: 'Tin cơ bản + Nhãn chứng nhận 7 ngày. Tăng độ tin cậy cho tin đăng.',
    ),
    _PriceItem(
      title: 'Combo Duyệt siêu tốc',
      price: '15.000 đ',
      description: 'Tin cơ bản + Fast Review. Cần hiển thị sớm trong khi Admin tiếp tục kiểm duyệt.',
    ),
    _PriceItem(
      title: 'Combo Ghim Top',
      price: '60.000 đ',
      description: 'Tin cơ bản + Ghim Top 7 ngày. Cần tăng hiển thị ngay khi đăng.',
    ),
  ];

  static const List<_PriceItem> _extraServices = [
    _PriceItem(
      title: 'Ghim Top 7 ngày',
      price: '60.000 đ / lượt',
      description: 'Đẩy tin lên nhóm ưu tiên theo BoostedUntil trong 7 ngày.',
    ),
    _PriceItem(
      title: 'Làm mới tin',
      price: '15.000 đ / lượt',
      description: 'Bắt đầu lại chu kỳ 30 ngày, đặt lại PublishedAt / RefreshedAt / ListingExpiresAt.',
    ),
    _PriceItem(
      title: 'Duyệt tin siêu tốc',
      price: '10.000 đ / lượt',
      description: 'Người dùng thấy Đã duyệt và tin hiển thị sớm, Admin vẫn tiếp tục kiểm duyệt.',
    ),
    _PriceItem(
      title: 'Nhãn chứng nhận 7 ngày',
      price: '10.000 đ / lượt',
      description: 'Hiển thị nhãn chứng nhận, tăng độ tin cậy cho tin.',
    ),
  ];

  static const List<_SuggestionItem> _suggestions = [
    _SuggestionItem('Đăng ít tin, chỉ cần cơ bản', 'Miễn phí / Tin lẻ', 'Chi phí thấp, quota có sẵn.'),
    _SuggestionItem('Đăng đều mỗi ngày', 'Cơ bản', 'Quota cao hơn + ưu tiên 10.'),
    _SuggestionItem('Môi giới cần tăng hiển thị', 'Cao cấp', '150 tin/tháng + ưu tiên 20 + 1 Top miễn phí.'),
    _SuggestionItem('Tài khoản cần ưu tiên cao nhất', 'Tối thượng', 'Ưu tiên 30 + 3 Top + Fast Review.'),
    _SuggestionItem('Cần một tin lên vị trí tốt ngay', 'Ghim Top 7 ngày', 'Tác động trực tiếp đến boost.'),
    _SuggestionItem('Tin sắp hết hạn / cần đẩy lại', 'Làm mới tin', 'Bắt đầu lại chu kỳ hiển thị 30 ngày.'),
    _SuggestionItem('Cần tin hiển thị sớm', 'Duyệt siêu tốc', 'Public sớm, Admin vẫn kiểm duyệt.'),
    _SuggestionItem('Cần tăng độ tin cậy', 'Nhãn chứng nhận 7 ngày', 'Hiển thị nhãn chứng nhận rõ ràng.'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gói mua & dịch vụ')),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: PageContainer(
          maxWidth: 920,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HeroCard(),
              const SizedBox(height: 18),
              const _SectionTitle(
                index: '1',
                title: 'Tổng quan hệ thống gói mua',
                subtitle: 'NhaWOW gồm 3 nhóm sản phẩm: Hội viên, Đăng tin lẻ & Combo, Dịch vụ gia tăng.',
              ),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= 760;
                  if (wide) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (var i = 0; i < _overviewItems.length; i++) ...[
                          Expanded(child: _OverviewCard(item: _overviewItems[i])),
                          if (i < _overviewItems.length - 1) const SizedBox(width: 12),
                        ],
                      ],
                    );
                  }
                  return Column(
                    children: [
                      for (var i = 0; i < _overviewItems.length; i++) ...[
                        _OverviewCard(item: _overviewItems[i]),
                        if (i < _overviewItems.length - 1) const SizedBox(height: 12),
                      ],
                    ],
                  );
                },
              ),
              const SizedBox(height: 18),
              const _HighlightNote(
                title: 'Điểm mới quan trọng',
                bullets: [
                  'Ưu đãi hội viên áp dụng cả cho tin đã đăng trước khi mua hoặc nâng cấp.',
                  'Duyệt tin siêu tốc cho phép tin hiển thị công khai sớm, trong khi Admin vẫn tiếp tục kiểm duyệt.',
                  'Nếu EN/ZH chưa đủ nội dung, hệ thống tạm dùng tiếng Việt để tránh gián đoạn hiển thị.',
                ],
              ),
              const SizedBox(height: 24),
              const _SectionTitle(
                index: '2',
                title: 'Bảng giá gói hội viên',
                subtitle: 'Quota và mức ưu tiên hiển thị sẽ tăng theo hạng gói.',
              ),
              const SizedBox(height: 12),
              for (var i = 0; i < _plans.length; i++) ...[
                _MembershipPlanCard(plan: _plans[i], highlight: i == _plans.length - 1),
                if (i < _plans.length - 1) const SizedBox(height: 12),
              ],
              const SizedBox(height: 14),
              const _HighlightNote(
                title: 'Ưu đãi áp dụng cho tin cũ như thế nào?',
                bullets: [
                  'Ngay sau khi mua hoặc nâng cấp, SortPriority của tất cả tin thuộc tài khoản được cập nhật theo gói mới.',
                  'Tin cũ không bị làm mới giả tạo: UpdatedAt / RefreshedAt không bị đổi chỉ vì mua hội viên.',
                  'Quota Ghim Top miễn phí là quyền cấp tài khoản và được dùng trên các tin phù hợp trong tháng.',
                ],
              ),
              const SizedBox(height: 24),
              const _SectionTitle(
                index: '3',
                title: 'Đăng tin lẻ & Combo',
                subtitle: 'Linh hoạt khi hết quota hoặc muốn đẩy mạnh tin ngay từ lúc tạo tin.',
              ),
              const SizedBox(height: 12),
              for (var i = 0; i < _postingItems.length; i++) ...[
                _PriceCard(item: _postingItems[i], icon: Icons.post_add_outlined),
                if (i < _postingItems.length - 1) const SizedBox(height: 10),
              ],
              const SizedBox(height: 14),
              const _HighlightNote(
                title: 'Nguyên tắc thanh toán',
                bullets: [
                  'Lựa chọn combo được giữ tạm thời trong Session khi chuyển sang màn tạo tin.',
                  'Tiền chỉ bị trừ khi nghiệp vụ đăng tin thành công.',
                  'Nếu không chọn combo, hệ thống ưu tiên quota ngày/tháng của gói đang hoạt động; hết quota mới tính 10.000 đ / tin lẻ.',
                ],
              ),
              const SizedBox(height: 24),
              const _SectionTitle(
                index: '4',
                title: 'Dịch vụ gia tăng',
                subtitle: 'Các dịch vụ tăng hiệu quả hiển thị và độ tin cậy cho từng tin đăng.',
              ),
              const SizedBox(height: 12),
              for (var i = 0; i < _extraServices.length; i++) ...[
                _PriceCard(item: _extraServices[i], icon: Icons.bolt_outlined),
                if (i < _extraServices.length - 1) const SizedBox(height: 10),
              ],
              const SizedBox(height: 14),
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _InfoHeading('Ưu đãi Ghim Top theo hội viên'),
                      SizedBox(height: 10),
                      _MiniTableRow(title: 'Miễn phí', value: '0 lượt / tháng'),
                      Divider(height: 18),
                      _MiniTableRow(title: 'Cơ bản', value: '0 lượt / tháng'),
                      Divider(height: 18),
                      _MiniTableRow(title: 'Cao cấp', value: '1 lượt / tháng'),
                      Divider(height: 18),
                      _MiniTableRow(title: 'Tối thượng', value: '3 lượt / tháng'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const _SectionTitle(
                index: '5',
                title: 'Duyệt tin siêu tốc - trải nghiệm người dùng',
                subtitle: 'Luồng hiển thị công khai sớm trong khi Admin vẫn tiếp tục kiểm duyệt.',
              ),
              const SizedBox(height: 12),
              const _TimelineCard(
                steps: [
                  'Mua dịch vụ thành công.',
                  'Trang Quản lý BĐS hiển thị “Đã duyệt” và nhãn “Duyệt siêu tốc - đang hiển thị công khai”.',
                  'Tin xuất hiện trên Home / List / Detail / Mobile theo điều kiện hiển thị thông thường.',
                  'Nếu EN/ZH chưa đủ bản dịch, hệ thống dùng nội dung tiếng Việt tạm thời.',
                  'Admin vẫn thấy “Chờ duyệt”, tiếp tục chỉnh sửa đa ngôn ngữ và duyệt chính thức sau.',
                ],
              ),
              const SizedBox(height: 14),
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _InfoHeading('Thứ tự Admin khi chờ duyệt'),
                      SizedBox(height: 10),
                      _MiniTableRow(title: '1', value: 'Duyệt siêu tốc'),
                      Divider(height: 18),
                      _MiniTableRow(title: '2', value: 'Tối thượng - SortPriority 30'),
                      Divider(height: 18),
                      _MiniTableRow(title: '3', value: 'Cao cấp - 20'),
                      Divider(height: 18),
                      _MiniTableRow(title: '4', value: 'Cơ bản - 10'),
                      Divider(height: 18),
                      _MiniTableRow(title: '5', value: 'Miễn phí - 0'),
                      Divider(height: 18),
                      _MiniTableRow(title: '6', value: 'Cùng mức: tin mới hơn trước'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const _SectionTitle(
                index: '6',
                title: 'Cơ chế ưu tiên hiển thị trên Home & List',
                subtitle: 'Các yếu tố ảnh hưởng đến thứ tự tin hiển thị công khai.',
              ),
              const SizedBox(height: 12),
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _InfoHeading('Trang chủ - khu nổi bật'),
                      SizedBox(height: 8),
                      _BulletLines(lines: [
                        'Tin đủ điều kiện public (published chính thức hoặc pending đã Fast Review) mới có thể tham gia hiển thị.',
                        'Ghim Top và vị trí nổi bật có trọng số cao khi còn hiệu lực.',
                        'SortPriority hội viên giúp Tối thượng > Cao cấp > Cơ bản > Miễn phí khi các điều kiện khác tương đương.',
                        'Làm mới tin tác động đến thời gian và giúp tin mới hơn trong cùng nhóm ưu tiên.',
                      ]),
                      SizedBox(height: 14),
                      _InfoHeading('Trang List'),
                      SizedBox(height: 8),
                      _BulletLines(lines: [
                        'Mặc định: Ghim Top / ưu tiên hội viên / thời gian cập nhật tác động đến thứ tự.',
                        'Nếu người dùng chọn sắp xếp theo Giá hoặc Cũ nhất, tiêu chí đó sẽ được ưu tiên theo lựa chọn UI.',
                        'Sau khi mua gói hội viên, ranking của các tin cũ cũng được cập nhật.',
                      ]),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const _SectionTitle(
                index: '7',
                title: 'So sánh nhanh theo nhu cầu',
                subtitle: 'Gợi ý lựa chọn để khách hàng dễ quyết định hơn.',
              ),
              const SizedBox(height: 12),
              for (var i = 0; i < _suggestions.length; i++) ...[
                _SuggestionCard(item: _suggestions[i]),
                if (i < _suggestions.length - 1) const SizedBox(height: 10),
              ],
              const SizedBox(height: 24),
              const _SectionTitle(
                index: '8',
                title: 'Phân biệt Người dùng - Chủ nhà - Môi giới',
                subtitle: 'Giúp vận hành và tư vấn gói đúng vai trò trong hệ thống.',
              ),
              const SizedBox(height: 12),
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _RoleCard(title: 'Người dùng', role: 'user', capability: 'Theo luồng cấp quyền', rights: 'Có thể mua khi có quyền đăng / quản lý tin'),
                      SizedBox(height: 10),
                      _RoleCard(title: 'Chủ nhà', role: 'landlord', capability: 'Có quản lý tin', rights: 'Giữ nguyên role landlord; dùng hội viên / dịch vụ cho tin của mình'),
                      SizedBox(height: 10),
                      _RoleCard(title: 'Môi giới', role: 'partner', capability: 'Có quản lý tin', rights: 'Dùng hội viên / dịch vụ và cấp độ môi giới'),
                      SizedBox(height: 12),
                      _BulletLines(lines: [
                        'Không tự động đổi landlord thành Partner chỉ vì người dùng nhấn Đăng tin.',
                        'IsGoldAgent chỉ là thuộc tính nổi bật, không quyết định tài khoản có phải Môi giới hay không.',
                        '“owner” trong Chat không phải Role; đó là quan hệ của người nhận hội thoại với tin.',
                      ]),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const _SectionTitle(
                index: '9',
                title: 'Bảng giá tóm tắt',
                subtitle: 'Tóm tắt nhanh để tư vấn và chốt nhu cầu với khách hàng.',
              ),
              const SizedBox(height: 12),
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _MiniTableRow(title: 'Hội viên Cơ bản', value: '300.000 đ / tháng'),
                      Divider(height: 18),
                      _MiniTableRow(title: 'Hội viên Cao cấp', value: '500.000 đ / tháng'),
                      Divider(height: 18),
                      _MiniTableRow(title: 'Hội viên Tối thượng', value: '800.000 đ / tháng'),
                      Divider(height: 18),
                      _MiniTableRow(title: 'Tin lẻ', value: '10.000 đ'),
                      Divider(height: 18),
                      _MiniTableRow(title: 'Combo Chứng nhận', value: '15.000 đ'),
                      Divider(height: 18),
                      _MiniTableRow(title: 'Combo Duyệt siêu tốc', value: '15.000 đ'),
                      Divider(height: 18),
                      _MiniTableRow(title: 'Combo Ghim Top', value: '60.000 đ'),
                      Divider(height: 18),
                      _MiniTableRow(title: 'Ghim Top 7 ngày', value: '60.000 đ'),
                      Divider(height: 18),
                      _MiniTableRow(title: 'Làm mới tin', value: '15.000 đ'),
                      Divider(height: 18),
                      _MiniTableRow(title: 'Duyệt tin siêu tốc', value: '10.000 đ'),
                      Divider(height: 18),
                      _MiniTableRow(title: 'Nhãn chứng nhận 7 ngày', value: '10.000 đ'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0C63E7), Color(0xFF00B1FE)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Text(
              'TÀI LIỆU GIỚI THIỆU SẢN PHẨM',
              style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'GÓI MUA & DỊCH VỤ NhaWOW',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w900,
              height: 1.18,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Bảng giá, quyền lợi hội viên, combo đăng tin, dịch vụ gia tăng và cơ chế ưu tiên hiển thị.',
            style: TextStyle(color: Colors.white, height: 1.5),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: const [
              _HeroChip(label: 'Phiên bản logic: Membership + Fast Review + Role separation'),
              _HeroChip(label: 'Cập nhật: 08/08/2026'),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  const _HeroChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppTheme.navy,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.index,
    required this.title,
    required this.subtitle,
  });

  final String index;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            index,
            style: const TextStyle(
              color: AppTheme.primaryDark,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppTheme.navy,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(subtitle, style: TextStyle(color: Colors.blueGrey.shade700, height: 1.45)),
            ],
          ),
        ),
      ],
    );
  }
}

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({required this.item});

  final _OverviewItem item;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(item.icon, color: AppTheme.primaryDark),
            ),
            const SizedBox(height: 14),
            Text(
              item.title,
              style: const TextStyle(
                color: AppTheme.navy,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(item.subtitle, style: const TextStyle(height: 1.5)),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF6FAFE),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFDDEBFA)),
              ),
              child: Text(
                item.meta,
                style: const TextStyle(color: AppTheme.primaryDark, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MembershipPlanCard extends StatelessWidget {
  const _MembershipPlanCard({required this.plan, this.highlight = false});

  final _MembershipPlan plan;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: highlight ? const Color(0xFF7ED2FF) : const Color(0xFFE8EDF4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plan.name,
                        style: const TextStyle(
                          color: AppTheme.navy,
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        plan.price,
                        style: const TextStyle(
                          color: AppTheme.primaryDark,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: highlight ? const Color(0xFFE8F7FF) : const Color(0xFFF4F7FA),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'SortPriority ${plan.sortPriority}',
                    style: const TextStyle(color: AppTheme.navy, fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _Badge(label: plan.dayLimit),
                _Badge(label: plan.monthLimit),
              ],
            ),
            const SizedBox(height: 14),
            const _InfoHeading('Quyền lợi nổi bật'),
            const SizedBox(height: 8),
            _BulletLines(lines: plan.benefits),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF5FAFF),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFD9EBFB)),
      ),
      child: Text(
        label,
        style: const TextStyle(color: AppTheme.primaryDark, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _PriceCard extends StatelessWidget {
  const _PriceCard({required this.item, required this.icon});

  final _PriceItem item;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppTheme.primaryDark),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: const TextStyle(
                            color: AppTheme.navy,
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        item.price,
                        style: const TextStyle(
                          color: AppTheme.primaryDark,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(item.description, style: const TextStyle(height: 1.5)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HighlightNote extends StatelessWidget {
  const _HighlightNote({required this.title, required this.bullets});

  final String title;
  final List<String> bullets;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF2FAFF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFCEEAFE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppTheme.navy,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          _BulletLines(lines: bullets),
        ],
      ),
    );
  }
}

class _TimelineCard extends StatelessWidget {
  const _TimelineCard({required this.steps});

  final List<String> steps;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            for (var i = 0; i < steps.length; i++)
              Padding(
                padding: EdgeInsets.only(bottom: i == steps.length - 1 ? 0 : 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: AppTheme.primaryDark,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${i + 1}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(steps[i], style: const TextStyle(height: 1.45)),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SuggestionCard extends StatelessWidget {
  const _SuggestionCard({required this.item});

  final _SuggestionItem item;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.need,
              style: const TextStyle(
                color: AppTheme.navy,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            _Badge(label: item.recommendation),
            const SizedBox(height: 10),
            Text(item.reason, style: const TextStyle(height: 1.5)),
          ],
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.title,
    required this.role,
    required this.capability,
    required this.rights,
  });

  final String title;
  final String role;
  final String capability;
  final String rights;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FBFD),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5ECF4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.navy,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0xFFDCE6F0)),
                ),
                child: Text(
                  role,
                  style: const TextStyle(color: AppTheme.primaryDark, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('Quản lý tin: $capability', style: const TextStyle(height: 1.4)),
          const SizedBox(height: 4),
          Text('Hội viên / dịch vụ: $rights', style: const TextStyle(height: 1.4)),
        ],
      ),
    );
  }
}

class _InfoHeading extends StatelessWidget {
  const _InfoHeading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppTheme.navy,
        fontSize: 16,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _BulletLines extends StatelessWidget {
  const _BulletLines({required this.lines});

  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < lines.length; i++)
          Padding(
            padding: EdgeInsets.only(bottom: i == lines.length - 1 ? 0 : 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 7),
                  child: Icon(Icons.circle, size: 7, color: AppTheme.primaryDark),
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(lines[i], style: const TextStyle(height: 1.45))),
              ],
            ),
          ),
      ],
    );
  }
}

class _MiniTableRow extends StatelessWidget {
  const _MiniTableRow({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: AppTheme.navy,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: AppTheme.primaryDark,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _OverviewItem {
  const _OverviewItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.meta,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String meta;
}

class _MembershipPlan {
  const _MembershipPlan({
    required this.name,
    required this.price,
    required this.dayLimit,
    required this.monthLimit,
    required this.sortPriority,
    required this.benefits,
  });

  final String name;
  final String price;
  final String dayLimit;
  final String monthLimit;
  final String sortPriority;
  final List<String> benefits;
}

class _PriceItem {
  const _PriceItem({
    required this.title,
    required this.price,
    required this.description,
  });

  final String title;
  final String price;
  final String description;
}

class _SuggestionItem {
  const _SuggestionItem(this.need, this.recommendation, this.reason);

  final String need;
  final String recommendation;
  final String reason;
}
