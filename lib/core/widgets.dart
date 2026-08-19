import 'package:flutter/material.dart';

import '../app/app_store.dart';
import 'app_assets.dart';
import 'auth_gate.dart';
import 'app_image.dart';
import '../models/models.dart';
import '../l10n/app_localizations.dart';
import 'app_theme.dart';
import 'property_price_formatter.dart';

class PageContainer extends StatelessWidget {
  const PageContainer({
    required this.child,
    this.maxWidth = 1180,
    this.padding = const EdgeInsets.fromLTRB(16, 12, 16, 32),
    super.key,
  });

  final Widget child;
  final double maxWidth;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

class BrandWordmark extends StatelessWidget {
  const BrandWordmark({this.compact = false, super.key});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: compact ? 32 : 38,
          height: compact ? 32 : 38,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: const [
              BoxShadow(color: Color(0x1A11365B), blurRadius: 8, offset: Offset(0, 3)),
            ],
          ),
          child: Image.asset(AppAssets.brandLogo, fit: BoxFit.contain),
        ),
        const SizedBox(width: 9),
        Text(
          'NhaWOW',
          style: TextStyle(
            color: AppTheme.navy,
            fontSize: compact ? 20 : 24,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppTheme.navy,
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(subtitle!, style: TextStyle(color: Colors.blueGrey.shade600)),
              ],
            ],
          ),
        ),
        if (actionLabel != null)
          TextButton(onPressed: onAction, child: Text(actionLabel!)),
      ],
    );
  }
}

class PropertyGrid extends StatelessWidget {
  const PropertyGrid({required this.properties, this.onPropertyTap, super.key});

  final List<PropertyModel> properties;
  final ValueChanged<PropertyModel>? onPropertyTap;

  @override
  Widget build(BuildContext context) {
    if (properties.isEmpty) {
      return EmptyState(
        icon: Icons.home_work_outlined,
        title: context.tr('Chưa có bất động sản phù hợp'),
        message: context.tr('Hãy thay đổi bộ lọc hoặc từ khóa tìm kiếm.'),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width >= 980 ? 3 : (width >= 620 ? 2 : 1);
        const crossAxisSpacing = 14.0;
        final itemWidth =
            (width - (crossAxisSpacing * (columns - 1))) / columns;

        // Ảnh được tăng chiều cao theo tỉ lệ gần 3:2 để hạn chế cắt mất
        // phần trên/dưới của ảnh bất động sản trên màn hình điện thoại.
        final imageHeight = columns == 1
            ? (itemWidth * 0.64).clamp(225.0, 272.0).toDouble()
            : (itemWidth * 0.58).clamp(168.0, 220.0).toDouble();
        // Tiêu đề và tiện ích chỉ còn một dòng nên phần nội dung có thể
        // thu gọn hơn, đồng thời vẫn đủ chỗ cho giá và giá theo m².
        // Địa chỉ công khai có thể xuống tối đa 2 dòng (địa chỉ cũ +
        // địa chỉ hành chính mới trong ngoặc), vì vậy tăng nhẹ phần nội dung.
        // Trên mobile giảm phần nội dung của card đúng 1 line-height (20 px)
        // để loại bỏ khoảng trống nhưng vẫn đủ chỗ cho địa chỉ tối đa 2 dòng.
        final cardHeight = imageHeight + (columns == 1 ? 130.0 : 158.0);

        return GridView.builder(
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: properties.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: crossAxisSpacing,
            mainAxisSpacing: 14,
            mainAxisExtent: cardHeight,
          ),
          itemBuilder: (context, index) => PropertyCard(
            key: ValueKey<int>(properties[index].id),
            property: properties[index],
            imageHeight: imageHeight,
            onTap: onPropertyTap == null
                ? null
                : () => onPropertyTap!(properties[index]),
          ),
        );
      },
    );
  }
}

class PropertyCard extends StatelessWidget {
  const PropertyCard({
    required this.property,
    this.onTap,
    this.imageHeight = 240,
    super.key,
  });

  final PropertyModel property;
  final VoidCallback? onTap;
  final double imageHeight;

  static const Color _priceColor = Color(0xFFEF4444);

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final current = store.propertyById(property.id) ?? property;
    final pricePerSquareMeter = _formatPricePerSquareMeter(context, current);
    final areaLabel = _formatArea(current.area);
    final informationLine = _buildInformationLine(context, current);

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: imageHeight,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _PropertyCardGallery(
                    property: current,
                    onNeedMoreImages: () => store.loadPropertyDetail(current.id),
                  ),
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Wrap(
                      spacing: 6,
                      children: [
                        if (current.isFeatured)
                          MiniBadge(
                            label: context.tr('Nổi bật'),
                            color: AppTheme.danger,
                          ),
                        if (current.isVrAvailable)
                          const MiniBadge(
                            label: 'VR 360°',
                            color: AppTheme.primaryDark,
                          ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Material(
                      color: Colors.white.withValues(alpha: 0.94),
                      shape: const CircleBorder(),
                      child: IconButton(
                        tooltip: context.tr('Yêu thích'),
                        onPressed: () => AuthGate.toggleFavorite(context, current.id),
                        icon: Icon(
                          current.isFavorite
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: current.isFavorite
                              ? AppTheme.danger
                              : AppTheme.navy,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 10,
                    bottom: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.68),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.visibility_outlined,
                            size: 16,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            context.tr(
                              '{count} lượt xem',
                              {'count': current.compactViewCount},
                            ),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tiêu đề luôn chỉ hiển thị một dòng.
                    Text(
                      current.title,
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppTheme.navy,
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        height: 1.16,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 1),
                          child: Icon(
                            Icons.location_on_outlined,
                            size: 16,
                            color: Colors.blueGrey,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            current.displayAddress,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.blueGrey.shade700,
                              fontSize: 12.5,
                              height: 1.28,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Chỉ hiển thị các thông tin/tiện ích trên một dòng.
                    // Diện tích đã được chuyển xuống hàng giá phía dưới.
                    Container(
                      width: double.infinity,
                      height: 25,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F5FA),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.centerLeft,
                      child: Row(
                        children: [
                          const Icon(
                            Icons.home_work_outlined,
                            size: 14,
                            color: AppTheme.navy,
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              informationLine,
                              maxLines: 1,
                              softWrap: false,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppTheme.navy,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    const SizedBox(height: 5),

                    // Tổng giá và giá theo m² nằm liền nhau ở bên trái.
                    // Diện tích được đặt ở mép phải, thay vị trí cũ của giá/m².
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              const Icon(
                                Icons.payments_outlined,
                                size: 17,
                                color: _priceColor,
                              ),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text.rich(
                                  TextSpan(
                                    children: [
                                      TextSpan(
                                        text: displayPropertyPrice(context, current),
                                        style: const TextStyle(
                                          color: _priceColor,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                          height: 1.05,
                                        ),
                                      ),
                                      if (pricePerSquareMeter.isNotEmpty)
                                        TextSpan(
                                          text: '  $pricePerSquareMeter',
                                          style: const TextStyle(
                                            color: _priceColor,
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.w700,
                                            height: 1.05,
                                          ),
                                        ),
                                    ],
                                  ),
                                  maxLines: 1,
                                  softWrap: false,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (areaLabel.isNotEmpty) ...[
                          const SizedBox(width: 10),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.square_foot_rounded,
                                size: 16,
                                color: AppTheme.navy,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                areaLabel,
                                maxLines: 1,
                                softWrap: false,
                                style: const TextStyle(
                                  color: AppTheme.navy,
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  height: 1.05,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _buildInformationLine(
    BuildContext context,
    PropertyModel property,
  ) {
    final values = <String>[];

    for (final tag in property.infoTags) {
      final value = tag.trim();

      // Không lặp lại diện tích trong dòng tiện ích vì diện tích đã được
      // hiển thị ở mép phải của hàng giá.
      if (value.isEmpty ||
          _looksLikeArea(value) ||
          values.contains(value)) {
        continue;
      }

      values.add(context.tr(value));
    }

    return values.isEmpty
        ? context.tr('Chưa cập nhật tiện ích')
        : values.join(' • ');
  }

  static String _formatArea(num area) {
    if (area <= 0) return '';

    final areaText = area.toStringAsFixed(area % 1 == 0 ? 0 : 1);
    return '$areaText m²';
  }

  static bool _looksLikeArea(String value) {
    final normalized = value
        .toLowerCase()
        .replaceAll(' ', '')
        .replaceAll('㎡', 'm²');

    return RegExp(r'^\d+(?:[.,]\d+)?m(?:²|2)$').hasMatch(normalized);
  }

  static String _formatPricePerSquareMeter(
    BuildContext context,
    PropertyModel property,
  ) {
    // Chỉ hiển thị giá theo m² cho hai nhóm bán: Bán nhà và Đất bán.
    // Thuê nhà và Mặt bằng không hiển thị giá/m² hoặc giá/m²/tháng.
    if (property.kind != ListingKind.houseSale &&
        property.kind != ListingKind.landSale) {
      return '';
    }

    if (property.area <= 0) return '';

    final totalPrice = _resolveTotalPrice(property);
    if (totalPrice <= 0) return '';

    final millionPerSquareMeter = totalPrice / property.area / 1000000;
    if (!millionPerSquareMeter.isFinite ||
        millionPerSquareMeter <= 0) {
      return '';
    }

    final languageCode = Localizations.localeOf(context).languageCode;
    if (languageCode.toLowerCase().startsWith('zh')) {
      final vndPerSquareMeter = totalPrice / property.area;
      return '${formatChineseVndCompact(vndPerSquareMeter)}/平方米';
    }

    final raw = millionPerSquareMeter.toStringAsFixed(2);
    final formatted = languageCode == 'vi' ? raw.replaceAll('.', ',') : raw;

    return context.tr(
      '{value} triệu/m²',
      {'value': formatted},
    );
  }

  static double _resolveTotalPrice(PropertyModel property) {
    // Ưu tiên giá số nếu PropertyModel có trường price.
    // Dùng dynamic để file này vẫn tương thích với model cũ chưa có price.
    try {
      final dynamic rawPrice = (property as dynamic).price;
      if (rawPrice is num && rawPrice > 0) {
        return rawPrice.toDouble();
      }
    } catch (_) {
      // Model cũ không có price: chuyển sang đọc từ priceLabel.
    }

    return _parsePriceLabel(property.priceLabel);
  }

  static double _parsePriceLabel(String label) {
    var normalized = label
        .toLowerCase()
        .replaceAll('\u00a0', ' ')
        .trim();

    if (normalized.isEmpty ||
        normalized.contains('thỏa thuận') ||
        normalized.contains('thoả thuận') ||
        normalized.contains('negotiable') ||
        normalized.contains('价格面议')) {
      return 0;
    }

    var multiplier = 1.0;

    if (normalized.contains('tỷ') ||
        normalized.contains('ty') ||
        normalized.contains('billion') ||
        normalized.contains('十亿')) {
      multiplier = 1000000000;
    } else if (normalized.contains('triệu') ||
        normalized.contains('trieu') ||
        normalized.contains('million') ||
        normalized.contains('百万') ||
        RegExp(r'(^|\s)tr($|\s|/)').hasMatch(normalized)) {
      multiplier = 1000000;
    } else if (normalized.contains('nghìn') ||
        normalized.contains('ngan') ||
        normalized.contains('thousand') ||
        normalized.contains('千越南盾')) {
      multiplier = 1000;
    } else if (normalized.contains('亿')) {
      multiplier = 100000000;
    } else if (normalized.contains('万')) {
      multiplier = 10000;
    }

    var numberText = normalized.replaceAll(RegExp(r'[^0-9,.\-]'), '');
    if (numberText.isEmpty) return 0;

    if (multiplier == 1) {
      // Trường hợp API trả giá đầy đủ: 2.900.000.000 hoặc 2,900,000,000.
      numberText = numberText.replaceAll('.', '').replaceAll(',', '');
    } else if (numberText.contains(',') && numberText.contains('.')) {
      // Định dạng Việt Nam: 1.250,50 triệu.
      numberText = numberText.replaceAll('.', '').replaceAll(',', '.');
    } else if (numberText.contains(',')) {
      numberText = numberText.replaceAll(',', '.');
    } else if (numberText.contains('.')) {
      final parts = numberText.split('.');
      final lastPartLength = parts.last.length;

      // Một dấu chấm với 1–2 chữ số phía sau được coi là dấu thập phân.
      // Các trường hợp còn lại được coi là dấu phân cách hàng nghìn.
      if (!(parts.length == 2 && lastPartLength <= 2)) {
        numberText = numberText.replaceAll('.', '');
      }
    }

    final value = double.tryParse(numberText) ?? 0;
    return value * multiplier;
  }
}

class _PropertyCardGallery extends StatefulWidget {
  const _PropertyCardGallery({
    required this.property,
    required this.onNeedMoreImages,
  });

  final PropertyModel property;
  final Future<PropertyModel?> Function() onNeedMoreImages;

  @override
  State<_PropertyCardGallery> createState() => _PropertyCardGalleryState();
}

class _PropertyCardGalleryState extends State<_PropertyCardGallery> {
  int _index = 0;
  bool _isRequestingDetail = false;
  bool _hasRequestedDetail = false;
  double _horizontalDragDistance = 0;

  @override
  void didUpdateWidget(covariant _PropertyCardGallery oldWidget) {
    super.didUpdateWidget(oldWidget);
    final urls = _galleryUrls(widget.property);
    if (oldWidget.property.id != widget.property.id ||
        (urls.isNotEmpty && _index >= urls.length)) {
      _index = 0;
      _isRequestingDetail = false;
      _hasRequestedDetail = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final urls = _galleryUrls(widget.property);
    final reportedTotal = widget.property.imageCount > urls.length
        ? widget.property.imageCount
        : urls.length;

    // Tải chi tiết một lần khi API danh sách chưa trả đủ ảnh.
    // Một số phiên bản API cũ luôn trả imageCount = 1, vì vậy vẫn phải
    // tải chi tiết khi card ban đầu chỉ có đúng một ảnh. Sau khi nhận dữ
    // liệu chi tiết, AppStore cập nhật card và bộ đếm sẽ đổi thành 1/n.
    final needsDetailImages =
        reportedTotal > urls.length || urls.length <= 1;
    if (needsDetailImages &&
        !_isRequestingDetail &&
        !_hasRequestedDetail) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _requestDetails());
    }

    if (urls.isEmpty) {
      return PropertyVisual(
        property: widget.property,
        forceFallback: true,
      );
    }

    return Listener(
      onPointerDown: (_) => _horizontalDragDistance = 0,
      onPointerMove: (event) {
        _horizontalDragDistance += event.delta.dx.abs();
        if (_horizontalDragDistance >= 14 && urls.length <= 1) {
          _requestDetails();
        }
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          PageView.builder(
            key: PageStorageKey<String>(
              'property-card-gallery-${widget.property.id}',
            ),
            itemCount: urls.length,
            physics: urls.length > 1
                ? const PageScrollPhysics()
                : const NeverScrollableScrollPhysics(),
            onPageChanged: (value) {
              if (!mounted || _index == value) return;
              setState(() => _index = value);
            },
            itemBuilder: (context, index) => AppNetworkImage(
              url: urls[index],
              fit: BoxFit.cover,
              fallback: PropertyVisual(
                property: widget.property,
                forceFallback: true,
              ),
            ),
          ),
          Positioned(
            right: 10,
            bottom: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.72),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.photo_library_outlined,
                    color: Colors.white,
                    size: 17,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${_index + 1}/${reportedTotal == 0 ? urls.length : reportedTotal}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (_isRequestingDetail && reportedTotal > urls.length) ...[
                    const SizedBox(width: 7),
                    const SizedBox.square(
                      dimension: 11,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.6,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _requestDetails() async {
    if (_isRequestingDetail || _hasRequestedDetail || widget.property.id <= 0) {
      return;
    }
    _hasRequestedDetail = true;
    _isRequestingDetail = true;
    if (mounted) setState(() {});
    try {
      await widget.onNeedMoreImages();
    } finally {
      if (!mounted) return;
      setState(() => _isRequestingDetail = false);
    }
  }

  List<String> _galleryUrls(PropertyModel property) {
    final urls = <String>[];

    void addUrl(String value) {
      final url = value.trim();
      if (url.isEmpty || urls.contains(url)) return;
      urls.add(url);
    }

    addUrl(property.thumbnailUrl);
    for (final url in property.imageUrls) {
      addUrl(url);
    }
    return urls;
  }
}

class PropertyVisual extends StatelessWidget {
  const PropertyVisual({
    required this.property,
    this.fit = BoxFit.cover,
    this.forceFallback = false,
    super.key,
  });

  final PropertyModel property;
  final BoxFit fit;
  final bool forceFallback;

  @override
  Widget build(BuildContext context) {
    final url = property.thumbnailUrl.trim();
    if (!forceFallback && url.isNotEmpty) {
      return ColoredBox(
        color: const Color(0xFFE8EEF4),
        child: AppNetworkImage(
          url: url,
          fit: fit,
          fallback: _fallback(),
        ),
      );
    }
    return _fallback();
  }

  Widget _fallback() {
    final colors = _colorsFor(property.id);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            right: -20,
            bottom: -25,
            child: Icon(
              property.kind.isLand
                  ? Icons.landscape_rounded
                  : Icons.apartment_rounded,
              size: 150,
              color: Colors.white.withValues(alpha: 0.16),
            ),
          ),
          Icon(
            property.kind.isLand
                ? Icons.landscape_outlined
                : Icons.home_work_outlined,
            size: 64,
            color: Colors.white.withValues(alpha: 0.9),
          ),
        ],
      ),
    );
  }

  List<Color> _colorsFor(int id) {
    const sets = [
      [Color(0xFF3B82F6), Color(0xFF60A5FA)],
      [Color(0xFF0F766E), Color(0xFF2DD4BF)],
      [Color(0xFF7C3AED), Color(0xFFA78BFA)],
      [Color(0xFFEA580C), Color(0xFFFB923C)],
      [Color(0xFF0369A1), Color(0xFF38BDF8)],
      [Color(0xFF475569), Color(0xFF94A3B8)],
    ];
    return sets[id % sets.length];
  }
}

class MiniBadge extends StatelessWidget {
  const MiniBadge({required this.label, required this.color, super.key});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class SmallTag extends StatelessWidget {
  const SmallTag({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F5FA),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(color: AppTheme.navy, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
    super.key,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            children: [
              Icon(icon, size: 62, color: AppTheme.primaryDark),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppTheme.navy,
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.blueGrey.shade600, height: 1.45),
              ),
              if (action != null) ...[
                const SizedBox(height: 18),
                action!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class CountBadge extends StatelessWidget {
  const CountBadge({required this.count, required this.child, super.key});

  final int count;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        if (count > 0)
          Positioned(
            top: -5,
            right: -7,
            child: Container(
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: AppTheme.danger,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              alignment: Alignment.center,
              child: Text(
                count > 99 ? '99+' : '$count',
                style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700),
              ),
            ),
          ),
      ],
    );
  }
}
