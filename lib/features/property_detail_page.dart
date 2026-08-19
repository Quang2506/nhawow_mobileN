import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app/app_store.dart';
import '../core/agent_level_ui.dart';
import '../core/app_assets.dart';
import '../core/app_image.dart';
import '../core/app_theme.dart';
import '../core/auth_gate.dart';
import '../core/widgets.dart';
import '../core/google_map_embed.dart';
import '../core/media_url_resolver.dart';
import '../core/property_price_formatter.dart';
import '../config/app_config.dart';
import '../models/models.dart';
import '../l10n/app_localizations.dart';
import 'agent_profile_page.dart';
import 'chat_thread_page.dart';
import 'vr_page.dart';

class PropertyDetailPage extends StatefulWidget {
  const PropertyDetailPage({required this.propertyId, super.key});

  final int propertyId;

  @override
  State<PropertyDetailPage> createState() => _PropertyDetailPageState();
}

class _PropertyDetailPageState extends State<PropertyDetailPage> {
  final ScrollController _scrollController = ScrollController();

  String? _requestedLanguage;
  bool _showHeaderBackground = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) return;

    final showBackground = _scrollController.offset > 18;
    if (showBackground == _showHeaderBackground || !mounted) return;

    setState(() => _showHeaderBackground = showBackground);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final language = AppScope.of(context).apiLanguageCode;
    if (_requestedLanguage == language) return;
    _requestedLanguage = language;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || AppScope.of(context).apiLanguageCode != language) return;
      AppScope.of(context).loadPropertyDetail(widget.propertyId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final property = store.propertyById(widget.propertyId);

    if (property == null) {
      if (store.isPropertyDetailLoading(widget.propertyId)) {
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      }

      return Scaffold(
        appBar: AppBar(title: Text(context.tr('Chi tiết bất động sản'))),
        body: EmptyState(
          icon: Icons.error_outline,
          title: context.tr('Không tìm thấy tin đăng'),
          message: store.propertyError != null
              ? context.tr(store.propertyError!)
              : context.tr('Tin đăng có thể đã bị xóa hoặc không còn hiển thị.'),
          action: FilledButton.icon(
            onPressed: () => store.loadPropertyDetail(widget.propertyId),
            icon: const Icon(Icons.refresh),
            label: Text(context.tr('Thử lại')),
          ),
        ),
      );
    }

    final similar = store.properties
        .where((item) => item.id != property.id && item.kind == property.kind)
        .take(4)
        .toList(growable: false);

    final isWide = MediaQuery.sizeOf(context).width >= 700;
    final showSolidHeader = isWide || _showHeaderBackground;

    return Scaffold(
      backgroundColor: Colors.white,
      extendBodyBehindAppBar: !isWide,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        toolbarHeight: 60,
        backgroundColor:
            showSolidHeader ? Colors.white : Colors.transparent,
        foregroundColor: showSolidHeader ? AppTheme.navy : Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        shadowColor: const Color(0x22000000),
        systemOverlayStyle: showSolidHeader
            ? SystemUiOverlayStyle.dark
            : SystemUiOverlayStyle.light,
        shape: showSolidHeader
            ? const Border(
                bottom: BorderSide(color: Color(0xFFE8EDF2)),
              )
            : null,
        leadingWidth: showSolidHeader ? 54 : 62,
        leading: _HeaderActionButton(
          solidHeader: showSolidHeader,
          tooltip: context.tr('Quay lại'),
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
          ),
        ),
        actions: [
          _HeaderActionButton(
            solidHeader: showSolidHeader,
            tooltip: context.tr('Yêu thích'),
            onPressed: () => AuthGate.toggleFavorite(context, property.id),
            icon: Icon(
              property.isFavorite ? Icons.favorite : Icons.favorite_border,
              color: showSolidHeader
                  ? (property.isFavorite ? AppTheme.danger : AppTheme.navy)
                  : Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 2),
          _HeaderActionButton(
            solidHeader: showSolidHeader,
            tooltip: context.tr('Chia sẻ'),
            onPressed: () => _sharePropertyLink(context, property),
            icon: const Icon(
              Icons.share_rounded,
              size: 21,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      bottomNavigationBar:
          isWide ? null : _ContactBar(property: property),
      body: SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _DetailHero(
              property: property,
              isWide: isWide,
            ),
            PageContainer(
              maxWidth: 1050,
              padding: EdgeInsets.fromLTRB(
                isWide ? 18 : 20,
                isWide ? 20 : 14,
                isWide ? 18 : 20,
                isWide ? 28 : 20,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (store.isPropertyDetailLoading(widget.propertyId)) ...[
                    const LinearProgressIndicator(),
                    const SizedBox(height: 14),
                  ],
                  Text(
                    _normalizedDetailTitle(property.title),
                    style: TextStyle(
                      color: AppTheme.navy,
                      fontSize: isWide ? 26 : 25,
                      height: 1.25,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.28,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 1.5),
                        child: Icon(
                          Icons.location_on_outlined,
                          size: 18,
                          color: _detailSecondaryTextColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          property.displayAddress,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _detailSecondaryTextColor,
                            fontSize: 15.5,
                            height: 1.4,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _SectionDivider(),
                  const SizedBox(height: 14),
                  _DetailPriceSummary(property: property),
                  if (property.infoTags.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _ExpandableInfoTags(tags: property.infoTags),
                  ],
                  const SizedBox(height: 16),
                  const _SectionDivider(),
                  const SizedBox(height: 16),
                  _BasicInformationSection(property: property),
                  const SizedBox(height: 18),
                  const _SectionDivider(),
                  const SizedBox(height: 16),
                  _SectionCard(
                    title: context.tr('Tiện ích / Nội thất'),
                    icon: Icons.chair_alt_outlined,
                    child: property.amenities.isEmpty
                        ? Text(
                            context.tr('Chưa cập nhật'),
                            style: TextStyle(
                              color: _detailSecondaryTextColor,
                              fontSize: 15,
                            ),
                          )
                        : Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: property.amenities
                                .map((item) => _AmenityChip(label: item))
                                .toList(growable: false),
                          ),
                  ),
                  const SizedBox(height: 18),
                  const _SectionDivider(),
                  const SizedBox(height: 16),
                  _SectionCard(
                    title: context.tr('Mô tả'),
                    icon: Icons.subject_rounded,
                    child: _ExpandableDescription(
                      description: property.description,
                    ),
                  ),
                  const SizedBox(height: 18),
                  const _SectionDivider(),
                  const SizedBox(height: 16),
                  _MapCard(property: property),
                  if (similar.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    const _SectionDivider(),
                    const SizedBox(height: 16),
                    SectionHeader(title: context.tr('Bất động sản tương tự')),
                    const SizedBox(height: 8),
                    PropertyGrid(
                      properties: similar,
                      onPropertyTap: (item) {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                PropertyDetailPage(propertyId: item.id),
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


const Color _detailSecondaryTextColor = Color(0xFF667085);
const Color _detailDividerColor = Color(0xFFEEF2F6);
const Color _detailMutedBackground = Color(0xFFF7F9FC);

String _normalizedDetailTitle(String title) {
  final normalized = title.trim().replaceAll(RegExp(r'\s+'), ' ');
  if (normalized.isEmpty) return normalized;

  final containsLetter = RegExp(r'[A-Za-zÀ-ỹ]').hasMatch(normalized);
  final isAllCaps = containsLetter && normalized == normalized.toUpperCase();
  if (!isAllCaps) return normalized;

  final lower = normalized.toLowerCase();
  return '${lower[0].toUpperCase()}${lower.substring(1)}';
}

IconData? _tagIconForLabel(String label) {
  final value = label.trim().toLowerCase();
  if (value.isEmpty || value == '...') return null;
  if (value.contains('phòng ngủ') || value.contains(' pn')) return Icons.bed_rounded;
  if (value.contains('wc') || value.contains('toilet') || value.contains('phòng tắm')) {
    return Icons.bathtub_outlined;
  }
  if (value.contains('phòng thờ')) return Icons.self_improvement_rounded;
  if (value.contains('phòng khách')) return Icons.weekend_outlined;
  if (value.contains('tầng')) return Icons.apartment_rounded;
  if (value.contains('ban công')) return Icons.deck_outlined;
  if (value.contains('gara') || value.contains('ô tô')) return Icons.directions_car_outlined;
  return null;
}

class _SectionDivider extends StatelessWidget {
  const _SectionDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, thickness: 1, color: _detailDividerColor);
  }
}

class _HeaderActionButton extends StatelessWidget {
  const _HeaderActionButton({
    required this.solidHeader,
    required this.tooltip,
    required this.onPressed,
    required this.icon,
  });

  final bool solidHeader;
  final String tooltip;
  final VoidCallback onPressed;
  final Widget icon;

  @override
  Widget build(BuildContext context) {
    if (solidHeader) {
      return IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: icon,
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
        constraints: const BoxConstraints.tightFor(
          width: 40,
          height: 40,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
      child: Material(
        color: Colors.black.withValues(alpha: 0.52),
        elevation: 0,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: IconTheme(
          data: const IconThemeData(color: Colors.white),
          child: IconButton(
            tooltip: tooltip,
            onPressed: onPressed,
            icon: icon,
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints.tightFor(
              width: 40,
              height: 40,
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailHero extends StatelessWidget {
  const _DetailHero({
    required this.property,
    required this.isWide,
  });

  final PropertyModel property;
  final bool isWide;

  @override
  Widget build(BuildContext context) {
    final radius = isWide ? BorderRadius.circular(22) : BorderRadius.zero;

    return Padding(
      padding: isWide
          ? const EdgeInsets.fromLTRB(14, 12, 14, 0)
          : EdgeInsets.zero,
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1050),
          child: AspectRatio(
            aspectRatio: isWide ? 2.15 : 1.42,
            child: Stack(
              fit: StackFit.expand,
              children: [
                _PropertyGallery(
                  property: property,
                  borderRadius: radius,
                ),
                if (property.isFeatured || property.isCertified)
                  Positioned(
                    top: 14,
                    left: 16,
                    child: Wrap(
                      spacing: 8,
                      children: [
                        if (property.isFeatured)
                          MiniBadge(
                            label: context.tr('Nổi bật'),
                            color: AppTheme.danger,
                          ),
                        if (property.isCertified)
                          MiniBadge(
                            label: context.tr('Tin xác thực'),
                            color: Colors.green,
                          ),
                      ],
                    ),
                  ),
                if (property.isVrAvailable)
                  Positioned(
                    left: 14,
                    bottom: 14,
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => VrPage(property: property),
                          ),
                        );
                      },
                      icon: const Icon(Icons.view_in_ar_rounded, size: 19),
                      label: Text(context.tr('Xem VR 360°')),
                      style: FilledButton.styleFrom(
                        backgroundColor:
                            AppTheme.primaryDark.withValues(alpha: 0.94),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 13,
                          vertical: 10,
                        ),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailPriceSummary extends StatelessWidget {
  const _DetailPriceSummary({required this.property});

  final PropertyModel property;

  static const Color _priceColor = Color(0xFFEF4444);

  @override
  Widget build(BuildContext context) {
    final pricePerSquareMeter = _detailPricePerSquareMeter(context, property);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                displayPropertyPrice(context, property),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _priceColor,
                  fontSize: 29,
                  height: 1.08,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.35,
                ),
              ),
              if (pricePerSquareMeter.isNotEmpty) ...[
                const SizedBox(height: 7),
                Text(
                  '~$pricePerSquareMeter',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _priceColor,
                    fontSize: 15,
                    height: 1.18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 16),
        Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.visibility_outlined,
                size: 17,
                color: _detailSecondaryTextColor,
              ),
              const SizedBox(width: 5),
              Text(
                "${property.compactViewCount} ${context.tr('lượt xem')}",
                maxLines: 1,
                style: const TextStyle(
                  color: _detailSecondaryTextColor,
                  fontSize: 13.5,
                  height: 1.2,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ExpandableInfoTags extends StatefulWidget {
  const _ExpandableInfoTags({required this.tags});

  final List<String> tags;

  @override
  State<_ExpandableInfoTags> createState() => _ExpandableInfoTagsState();
}

class _ExpandableInfoTagsState extends State<_ExpandableInfoTags> {
  static const double _spacing = 8;
  static const double _moreWidth = 44;
  static const TextStyle _tagTextStyle = TextStyle(
    color: AppTheme.navy,
    fontSize: 13.5,
    height: 1.1,
    fontWeight: FontWeight.w600,
  );

  bool _expanded = false;

  List<String> get _tags {
    final values = <String>[];
    for (final item in widget.tags) {
      final value = item.trim();
      if (value.isNotEmpty && !values.contains(value)) values.add(value);
    }
    return values;
  }

  @override
  void didUpdateWidget(covariant _ExpandableInfoTags oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tags != widget.tags && _expanded) {
      _expanded = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tags = _tags;
    if (tags.isEmpty) return const SizedBox.shrink();

    return AnimatedSize(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topLeft,
      child: _expanded
          ? InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => setState(() => _expanded = false),
              child: Wrap(
                spacing: _spacing,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  ...tags.map((item) => _RoomTagPill(label: item)),
                  _RoomTagPill(
                    label: context.tr('Thu gọn'),
                    trailingIcon: Icons.expand_less_rounded,
                  ),
                ],
              ),
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                final widths = tags
                    .map((item) => _measureTagWidth(context, item))
                    .toList(growable: false);
                final totalWidth = widths.fold<double>(0, (a, b) => a + b) +
                    _spacing * (widths.length - 1);
                final hasOverflow = totalWidth > constraints.maxWidth;

                if (!hasOverflow) {
                  return Row(
                    children: [
                      for (var index = 0; index < tags.length; index++) ...[
                        if (index > 0) const SizedBox(width: _spacing),
                        Flexible(
                          fit: FlexFit.loose,
                          child: _RoomTagPill(label: tags[index]),
                        ),
                      ],
                    ],
                  );
                }

                final availableForTags =
                    (constraints.maxWidth - _spacing - _moreWidth)
                        .clamp(0.0, double.infinity);
                final visible = <String>[];
                var usedWidth = 0.0;

                for (var index = 0; index < tags.length; index++) {
                  final gap = visible.isEmpty ? 0.0 : _spacing;
                  final nextWidth = usedWidth + gap + widths[index];
                  if (nextWidth > availableForTags) break;
                  visible.add(tags[index]);
                  usedWidth = nextWidth;
                }

                if (visible.isEmpty) visible.add(tags.first);

                return InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => setState(() => _expanded = true),
                  child: Row(
                    children: [
                      Expanded(
                        child: ClipRect(
                          child: Row(
                            children: [
                              for (var index = 0;
                                  index < visible.length;
                                  index++) ...[
                                if (index > 0)
                                  const SizedBox(width: _spacing),
                                Flexible(
                                  fit: FlexFit.loose,
                                  child: _RoomTagPill(
                                    label: visible[index],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: _spacing),
                      const SizedBox(
                        width: _moreWidth,
                        child: _RoomTagPill(label: '...'),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  double _measureTagWidth(BuildContext context, String value) {
    final painter = TextPainter(
      text: TextSpan(text: value, style: _tagTextStyle),
      textDirection: Directionality.of(context),
      maxLines: 1,
    )..layout();

    return painter.width + 32;
  }
}

class _RoomTagPill extends StatelessWidget {
  const _RoomTagPill({required this.label, this.trailingIcon});

  final String label;
  final IconData? trailingIcon;

  @override
  Widget build(BuildContext context) {
    final leadingIcon = trailingIcon == null ? _tagIconForLabel(label) : null;

    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: _detailMutedBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leadingIcon != null) ...[
            Icon(
              leadingIcon,
              size: 16,
              color: AppTheme.primaryDark,
            ),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.ellipsis,
              style: _ExpandableInfoTagsState._tagTextStyle,
            ),
          ),
          if (trailingIcon != null) ...[
            const SizedBox(width: 4),
            Icon(
              trailingIcon,
              size: 16,
              color: AppTheme.primaryDark,
            ),
          ],
        ],
      ),
    );
  }
}

class _PropertyGallery extends StatefulWidget {
  const _PropertyGallery({
    required this.property,
    required this.borderRadius,
  });

  final PropertyModel property;
  final BorderRadius borderRadius;

  @override
  State<_PropertyGallery> createState() => _PropertyGalleryState();
}

class _PropertyGalleryState extends State<_PropertyGallery> {
  int _index = 0;

  @override
  void didUpdateWidget(covariant _PropertyGallery oldWidget) {
    super.didUpdateWidget(oldWidget);
    final urls = _galleryUrls(widget.property);
    if (oldWidget.property.id != widget.property.id ||
        (urls.isNotEmpty && _index >= urls.length)) {
      _index = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final urls = _galleryUrls(widget.property);

    if (urls.isEmpty) {
      return ClipRRect(
        borderRadius: widget.borderRadius,
        child: PropertyVisual(property: widget.property),
      );
    }

    return ClipRRect(
      borderRadius: widget.borderRadius,
      child: Stack(
        fit: StackFit.expand,
        children: [
          PageView.builder(
            itemCount: urls.length,
            onPageChanged: (value) {
              if (!mounted || _index == value) return;
              setState(() => _index = value);
            },
            itemBuilder: (context, index) => GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _openPreview(context, urls, index),
              child: AppNetworkImage(
                url: urls[index],
                fit: BoxFit.cover,
                fallback: PropertyVisual(property: widget.property),
              ),
            ),
          ),
          if (urls.length > 1)
            Positioned(
              left: 0,
              right: 0,
              bottom: 14,
              child: IgnorePointer(
                child: Center(
                  child: _GalleryPageIndicator(
                    currentIndex: _index,
                    itemCount: urls.length,
                  ),
                ),
              ),
            ),
          Positioned(
            right: 12,
            bottom: 12,
            child: Material(
              color: Colors.black.withValues(alpha: 0.52),
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                onTap: () => _openPreview(context, urls, _index),
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 6,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.photo_library_outlined,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${_index + 1}/${urls.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openPreview(
    BuildContext context,
    List<String> urls,
    int initialIndex,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _FullScreenGalleryPage(
          imageUrls: urls,
          initialIndex: initialIndex,
          title: widget.property.title,
        ),
      ),
    );
  }
}

class _FullScreenGalleryPage extends StatefulWidget {
  const _FullScreenGalleryPage({
    required this.imageUrls,
    required this.initialIndex,
    required this.title,
  });

  final List<String> imageUrls;
  final int initialIndex;
  final String title;

  @override
  State<_FullScreenGalleryPage> createState() =>
      _FullScreenGalleryPageState();
}

class _FullScreenGalleryPageState extends State<_FullScreenGalleryPage> {
  late final PageController _pageController;
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, widget.imageUrls.length - 1).toInt();
    _pageController = PageController(initialPage: _index);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: widget.imageUrls.length,
            onPageChanged: (value) => setState(() => _index = value),
            itemBuilder: (context, index) => _ZoomableNetworkImage(
              url: widget.imageUrls[index],
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
                child: Row(
                  children: [
                    Material(
                      color: Colors.black.withValues(alpha: 0.5),
                      shape: const CircleBorder(),
                      child: IconButton(
                        tooltip: context.tr('Đóng'),
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          shadows: [Shadow(color: Colors.black, blurRadius: 6)],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 13,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.58),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_index + 1}/${widget.imageUrls.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ZoomableNetworkImage extends StatefulWidget {
  const _ZoomableNetworkImage({required this.url});

  final String url;

  @override
  State<_ZoomableNetworkImage> createState() => _ZoomableNetworkImageState();
}

class _ZoomableNetworkImageState extends State<_ZoomableNetworkImage> {
  final TransformationController _transformationController =
      TransformationController();
  bool _panEnabled = false;

  @override
  void initState() {
    super.initState();
    _transformationController.addListener(_handleTransformChanged);
  }

  @override
  void dispose() {
    _transformationController
      ..removeListener(_handleTransformChanged)
      ..dispose();
    super.dispose();
  }

  void _handleTransformChanged() {
    final nextPanEnabled =
        _transformationController.value.getMaxScaleOnAxis() > 1.01;
    if (nextPanEnabled == _panEnabled || !mounted) return;
    setState(() => _panEnabled = nextPanEnabled);
  }

  @override
  Widget build(BuildContext context) {
    final resolvedUrl = MediaUrlResolver.resolve(widget.url);
    if (resolvedUrl.isEmpty) {
      return const Center(
        child: Icon(
          Icons.broken_image_outlined,
          color: Colors.white70,
          size: 64,
        ),
      );
    }

    return InteractiveViewer(
      transformationController: _transformationController,
      minScale: 1,
      maxScale: 5,
      panEnabled: _panEnabled,
      boundaryMargin: const EdgeInsets.all(80),
      child: Center(
        child: Image.network(
          resolvedUrl,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
          gaplessPlayback: true,
          webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            final total = progress.expectedTotalBytes;
            return Center(
              child: CircularProgressIndicator(
                color: Colors.white,
                value: total == null
                    ? null
                    : progress.cumulativeBytesLoaded / total,
              ),
            );
          },
          errorBuilder: (_, __, ___) => const Center(
            child: Icon(
              Icons.broken_image_outlined,
              color: Colors.white70,
              size: 64,
            ),
          ),
        ),
      ),
    );
  }
}

class _BasicInformationSection extends StatelessWidget {
  const _BasicInformationSection({required this.property});

  final PropertyModel property;

  @override
  Widget build(BuildContext context) {
    final apiItems = property.basicInfoItems
        .map(
          (item) => _InformationItemData(
            label: item.label,
            value: item.value,
            icon: _basicInfoIcon(item.key),
          ),
        )
        .toList(growable: false);

    final items = apiItems.isNotEmpty
        ? apiItems
        : _fallbackBasicInformationItems(property);

    return _InformationGridSection(
      title: context.tr('Thông tin cơ bản'),
      icon: Icons.info_outline_rounded,
      items: items,
    );
  }
}

List<_InformationItemData> _fallbackBasicInformationItems(
  PropertyModel property,
) {
  final areaItem = _InformationItemData(
    label: 'Diện tích',
    value: property.area > 0
        ? '${_formatNumber(property.area)} m²'
        : 'Đang cập nhật',
    icon: Icons.square_foot_outlined,
  );

  if (property.kind == ListingKind.premises) {
    final items = <_InformationItemData>[
      areaItem,
      _InformationItemData(
        label: 'Loại mặt bằng',
        value: _textOrUpdating(property.propertyType),
        icon: Icons.store_mall_directory_outlined,
      ),
    ];

    switch (property.propertyTypeCode.trim().toLowerCase()) {
      case 'land_office':
        items.addAll([
          _InformationItemData(
            label: 'Số tầng',
            value: _unitOrUpdating(property.floorInfo, 'tầng'),
            icon: Icons.apartment_outlined,
          ),
          _InformationItemData(
            label: 'Thời hạn thuê',
            value: _unitOrUpdating(property.leaseTerm, 'tháng'),
            icon: Icons.calendar_month_outlined,
          ),
        ]);
        break;
      case 'land_warehouse':
        items.addAll([
          _InformationItemData(
            label: 'Chiều cao kho',
            value: _unitOrUpdating(property.frontage, 'm'),
            icon: Icons.height_rounded,
          ),
          _InformationItemData(
            label: 'Tải trọng sàn',
            value: _unitOrUpdating(property.roadWidth, 'tấn/m²'),
            icon: Icons.scale_outlined,
          ),
          _InformationItemData(
            label: 'Đường vào',
            value: _unitOrUpdating(property.legalInfo, 'm'),
            icon: Icons.add_road_outlined,
          ),
        ]);
        break;
      case 'land_factory':
        items.addAll([
          _InformationItemData(
            label: 'Công suất điện',
            value: _unitOrUpdating(property.frontage, 'KVA'),
            icon: Icons.bolt_outlined,
          ),
          _InformationItemData(
            label: 'Tải trọng sàn',
            value: _unitOrUpdating(property.roadWidth, 'tấn/m²'),
            icon: Icons.scale_outlined,
          ),
        ]);
        break;
      case 'land_business':
        items.addAll([
          _InformationItemData(
            label: 'Mặt tiền',
            value: _unitOrUpdating(property.frontage, 'm'),
            icon: Icons.domain_outlined,
          ),
          _InformationItemData(
            label: 'Vỉa hè',
            value: _unitOrUpdating(property.roadWidth, 'm'),
            icon: Icons.directions_walk_outlined,
          ),
          _InformationItemData(
            label: 'Thời hạn thuê',
            value: _unitOrUpdating(property.leaseTerm, 'tháng'),
            icon: Icons.calendar_month_outlined,
          ),
        ]);
        break;
      case 'land_ground':
        items.addAll([
          _InformationItemData(
            label: 'Loại đất',
            value: _textOrUpdating(property.frontage),
            icon: Icons.map_outlined,
          ),
          _InformationItemData(
            label: 'Mặt tiền',
            value: _unitOrUpdating(property.roadWidth, 'm'),
            icon: Icons.domain_outlined,
          ),
          _InformationItemData(
            label: 'Đường vào',
            value: _unitOrUpdating(property.legalInfo, 'm'),
            icon: Icons.add_road_outlined,
          ),
          _InformationItemData(
            label: 'Pháp lý',
            value: _textOrUpdating(property.leaseTerm),
            icon: Icons.description_outlined,
          ),
          _InformationItemData(
            label: 'Thời hạn thuê',
            value: _unitOrUpdating(property.floorInfo, 'tháng'),
            icon: Icons.calendar_month_outlined,
          ),
        ]);
        break;
      case 'land_transfer':
        items.addAll([
          _InformationItemData(
            label: 'Giá sang nhượng',
            value: _textOrUpdating(property.frontage),
            icon: Icons.payments_outlined,
          ),
          _InformationItemData(
            label: 'Tài sản đi kèm',
            value: _textOrUpdating(property.roadWidth),
            icon: Icons.inventory_2_outlined,
          ),
          _InformationItemData(
            label: 'Hợp đồng còn lại',
            value: _textOrUpdating(property.legalInfo),
            icon: Icons.assignment_outlined,
          ),
          _InformationItemData(
            label: 'Lý do sang nhượng',
            value: _textOrUpdating(property.leaseTerm),
            icon: Icons.chat_bubble_outline,
          ),
        ]);
        break;
    }

    return items;
  }

  if (property.kind == ListingKind.landSale) {
    return <_InformationItemData>[
      areaItem,
      _InformationItemData(
        label: 'Pháp lý',
        value: _textOrUpdating(property.legalInfo),
        icon: Icons.description_outlined,
      ),
      _InformationItemData(
        label: 'Đường vào',
        value: _meterOrUpdating(property.roadWidth),
        icon: Icons.add_road_outlined,
      ),
      _InformationItemData(
        label: 'Mặt tiền',
        value: _meterOrUpdating(property.frontage),
        icon: Icons.domain_outlined,
      ),
      _InformationItemData(
        label: 'Loại đất',
        value: _textOrUpdating(property.propertyType),
        icon: Icons.map_outlined,
      ),
    ];
  }

  if (property.kind == ListingKind.houseSale) {
    return <_InformationItemData>[
      _InformationItemData(
        label: 'Khoảng giá',
        value: _textOrUpdating(property.priceLabel),
        icon: Icons.payments_outlined,
      ),
      areaItem,
      _InformationItemData(
        label: 'Mặt tiền',
        value: _meterOrUpdating(property.frontage),
        icon: Icons.domain_outlined,
      ),
      _InformationItemData(
        label: 'Đường vào',
        value: _meterOrUpdating(property.roadWidth),
        icon: Icons.add_road_outlined,
      ),
      _InformationItemData(
        label: 'Pháp lý',
        value: _textOrUpdating(property.legalInfo),
        icon: Icons.description_outlined,
      ),
      _InformationItemData(
        label: 'Số tầng',
        value: _unitOrUpdating(property.floorInfo, 'tầng'),
        icon: Icons.apartment_outlined,
      ),
    ];
  }

  return <_InformationItemData>[
    areaItem,
    _InformationItemData(
      label: 'Kiểu nhà',
      value: _textOrUpdating(property.propertyType),
      icon: Icons.home_work_outlined,
    ),
    _InformationItemData(
      label: 'Hướng',
      value: _textOrUpdating(property.orientation),
      icon: Icons.explore_outlined,
    ),
    const _InformationItemData(
      label: 'Thời gian cập nhật',
      value: 'Đang cập nhật',
      icon: Icons.update_outlined,
    ),
    _InformationItemData(
      label: 'Tình trạng vào ở',
      value: _textOrUpdating(property.moveInStatus),
      icon: Icons.meeting_room_outlined,
    ),
    _InformationItemData(
      label: 'Tầng',
      value: _unitOrUpdating(property.floorInfo, 'tầng'),
      icon: Icons.apartment_outlined,
    ),
    _InformationItemData(
      label: 'Nước sinh hoạt',
      value: _textOrUpdating(property.waterInfo),
      icon: Icons.water_drop_outlined,
    ),
    _InformationItemData(
      label: 'Điện sử dụng',
      value: _textOrUpdating(property.electricityInfo),
      icon: Icons.bolt_outlined,
    ),
    _InformationItemData(
      label: 'Thời hạn thuê',
      value: _unitOrUpdating(property.leaseTerm, 'tháng'),
      icon: Icons.calendar_month_outlined,
    ),
  ];
}

IconData _basicInfoIcon(String rawKey) {
  switch (rawKey.trim().toLowerCase()) {
    case 'area':
      return Icons.square_foot_outlined;
    case 'premises_type':
      return Icons.store_mall_directory_outlined;
    case 'property_type':
      return Icons.home_work_outlined;
    case 'price':
    case 'transfer_price':
      return Icons.payments_outlined;
    case 'frontage':
      return Icons.domain_outlined;
    case 'access_road':
    case 'road_width':
      return Icons.add_road_outlined;
    case 'legal':
      return Icons.description_outlined;
    case 'floor':
    case 'floor_count':
      return Icons.apartment_outlined;
    case 'orientation':
      return Icons.explore_outlined;
    case 'updated':
      return Icons.update_outlined;
    case 'move_in':
      return Icons.meeting_room_outlined;
    case 'water':
      return Icons.water_drop_outlined;
    case 'electricity':
    case 'power_capacity':
      return Icons.bolt_outlined;
    case 'lease_term':
      return Icons.calendar_month_outlined;
    case 'warehouse_height':
      return Icons.height_rounded;
    case 'floor_load':
      return Icons.scale_outlined;
    case 'sidewalk':
      return Icons.directions_walk_outlined;
    case 'land_type':
      return Icons.map_outlined;
    case 'included_assets':
      return Icons.inventory_2_outlined;
    case 'remaining_contract':
      return Icons.assignment_outlined;
    case 'transfer_reason':
      return Icons.chat_bubble_outline;
    default:
      return Icons.info_outline_rounded;
  }
}

class _InformationGridSection extends StatelessWidget {
  const _InformationGridSection({
    required this.title,
    required this.icon,
    required this.items,
  });

  final String title;
  final IconData icon;
  final List<_InformationItemData> items;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: title,
      icon: icon,
      child: _InformationGrid(items: items),
    );
  }
}

class _InformationGrid extends StatelessWidget {
  const _InformationGrid({required this.items});

  final List<_InformationItemData> items;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 10.0;
        final columns = constraints.maxWidth >= 760 ? 3 : 2;
        final itemWidth =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: items
              .map(
                (item) => SizedBox(
                  width: itemWidth,
                  child: _InformationItem(data: item),
                ),
              )
              .toList(growable: false),
        );
      },
    );
  }
}

class _InformationItemData {
  const _InformationItemData({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;
}

class _InformationItem extends StatelessWidget {
  const _InformationItem({required this.data});

  final _InformationItemData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 70),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDDE5EE)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(data.icon, size: 18, color: AppTheme.primaryDark),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr(data.label),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _detailSecondaryTextColor,
                    fontSize: 12,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  context.tr(data.value),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.navy,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
    this.icon,
  });

  final String title;
  final Widget child;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF3FF),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(
                    icon,
                    size: 19,
                    color: AppTheme.primaryDark,
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.navy,
                    fontSize: 18,
                    height: 1.2,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

const Map<String, String> _amenityCodeToVietnamese = <String, String>{
  'air_conditioner': 'Điều hòa',
  'air_conditioning': 'Điều hòa',
  'premises_air_conditioning': 'Điều hòa',
  'water_heater': 'Bình nóng lạnh',
  'hot_water': 'Nước nóng',
  'washing_machine': 'Máy giặt',
  'full_nt': 'Đầy đủ nội thất',
  'full_furniture': 'Đầy đủ nội thất',
  'wifi': 'Wi-Fi',
  'internet': 'Internet',
  'bathtub': 'Bồn tắm',
  'bed': 'Giường',
  'dining_table': 'Bàn ăn',
  'elevator': 'Thang máy',
  'premises_elevator': 'Thang máy',
  'fan': 'Quạt',
  'kitchen_cabinet': 'Tủ bếp',
  'kitchen': 'Bếp',
  'parking': 'Chỗ để xe',
  'premises_parking': 'Chỗ để xe',
  'refrigerator': 'Tủ lạnh',
  'smart_lock': 'Khóa thông minh',
  'television': 'Tivi',
  'tv': 'Tivi',
  'wardrobe': 'Tủ quần áo',
  'water_purifier': 'Máy lọc nước',
  'pool': 'Hồ bơi',
  'swimming_pool': 'Hồ bơi',
  'security': 'An ninh',
  'balcony': 'Ban công',
  'garden': 'Sân vườn',
  'premises_fire_safety': 'PCCC đạt chuẩn',
  'premises_three_phase_power': 'Điện 3 pha',
  'premises_production_license': 'Được cấp phép sản xuất',
  'premises_busy_area': 'Khu đông người',
  'premises_heavy_traffic': 'Nhiều xe qua lại',
  'premises_near_school': 'Gần trường học',
  'premises_near_office': 'Gần khu văn phòng',
  'premises_near_apartment': 'Gần chung cư',
};

String _localizedAmenityLabel(BuildContext context, String rawLabel) {
  final trimmed = rawLabel.trim();
  if (trimmed.isEmpty) return trimmed;

  final normalized = trimmed
      .toLowerCase()
      .replaceAll('-', '_')
      .replaceAll(' ', '_');
  final vietnameseSource = _amenityCodeToVietnamese[normalized];

  if (vietnameseSource != null) return context.tr(vietnameseSource);
  return context.tr(trimmed);
}

class _AmenityChip extends StatelessWidget {
  const _AmenityChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final displayLabel = _localizedAmenityLabel(context, label);
    final asset = AppAssets.amenityIcon(displayLabel);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _detailMutedBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          asset == null
              ? const Icon(
                  Icons.check_circle_outline,
                  size: 17,
                  color: AppTheme.primaryDark,
                )
              : Padding(
                  padding: const EdgeInsets.all(1),
                  child: Image.asset(
                    asset,
                    width: 18,
                    height: 18,
                    fit: BoxFit.contain,
                  ),
                ),
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              displayLabel,
              style: const TextStyle(
                color: AppTheme.navy,
                fontSize: 13.5,
                height: 1.15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpandableDescription extends StatefulWidget {
  const _ExpandableDescription({required this.description});

  final String description;

  @override
  State<_ExpandableDescription> createState() =>
      _ExpandableDescriptionState();
}

class _ExpandableDescriptionState extends State<_ExpandableDescription> {
  static const int _collapsedLines = 6;
  static const TextStyle _descriptionStyle = TextStyle(
    color: Color(0xFF33465C),
    fontSize: 15,
    height: 1.62,
  );

  bool _expanded = false;

  @override
  void didUpdateWidget(covariant _ExpandableDescription oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.description != widget.description && _expanded) {
      _expanded = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final description = widget.description.trim();
    if (description.isEmpty) {
      return Text(
        context.tr('Chưa cập nhật'),
        style: _descriptionStyle,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final painter = TextPainter(
          text: TextSpan(text: description, style: _descriptionStyle),
          textDirection: Directionality.of(context),
          maxLines: _collapsedLines,
        )..layout(maxWidth: constraints.maxWidth);
        final canExpand = painter.didExceedMaxLines;

        return AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                description,
                maxLines: _expanded ? null : _collapsedLines,
                overflow:
                    _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
                style: _descriptionStyle,
              ),
              if (canExpand) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.center,
                  child: TextButton.icon(
                    onPressed: () => setState(() => _expanded = !_expanded),
                    icon: Icon(
                      _expanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      size: 21,
                    ),
                    label: Text(
                      context.tr(_expanded ? 'Thu gọn' : 'Hiển thị thêm'),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.primaryDark,
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.w700,
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _MapCard extends StatefulWidget {
  const _MapCard({required this.property});

  final PropertyModel property;

  @override
  State<_MapCard> createState() => _MapCardState();
}

class _MapCardState extends State<_MapCard> {
  static const double _defaultZoom = 15;
  static const double _minZoom = 5;
  static const double _maxZoom = 19;
  static const LatLng _fallbackCenter = LatLng(20.4388, 106.1621);

  final MapController _mapController = MapController();
  bool _mapReady = false;

  PropertyModel get property => widget.property;

  bool get _hasPoint {
    final latitude = property.latitude;
    final longitude = property.longitude;
    return latitude != null &&
        longitude != null &&
        latitude >= -90 &&
        latitude <= 90 &&
        longitude >= -180 &&
        longitude <= 180;
  }

  bool _validBounds(
    double? north,
    double? south,
    double? east,
    double? west,
  ) {
    return north != null &&
        south != null &&
        east != null &&
        west != null &&
        north > south &&
        east > west &&
        north <= 90 &&
        south >= -90 &&
        east <= 180 &&
        west >= -180;
  }

  String get _renderMode => property.mapRenderMode.trim().toLowerCase();

  bool get _hasPolygon => property.mapPolygon.length >= 3;

  bool get _hasRect => _validBounds(
        property.mapBoundsNorth,
        property.mapBoundsSouth,
        property.mapBoundsEast,
        property.mapBoundsWest,
      );

  List<LatLng> get _regionPoints {
    if (_renderMode == 'polygon' && _hasPolygon) {
      return property.mapPolygon
          .map((item) => LatLng(item.latitude, item.longitude))
          .toList(growable: false);
    }

    if (_renderMode != 'rect' || !_hasRect) return const <LatLng>[];
    return <LatLng>[
      LatLng(property.mapBoundsNorth!, property.mapBoundsWest!),
      LatLng(property.mapBoundsNorth!, property.mapBoundsEast!),
      LatLng(property.mapBoundsSouth!, property.mapBoundsEast!),
      LatLng(property.mapBoundsSouth!, property.mapBoundsWest!),
    ];
  }

  LatLng? get _regionCenter {
    final points = _regionPoints;
    if (points.isEmpty) return null;
    var latitude = 0.0;
    var longitude = 0.0;
    for (final point in points) {
      latitude += point.latitude;
      longitude += point.longitude;
    }
    return LatLng(latitude / points.length, longitude / points.length);
  }

  LatLng? get _resolvedCenter {
    if (_hasPoint) return LatLng(property.latitude!, property.longitude!);
    return _regionCenter;
  }

  LatLng get _mapCenter => _resolvedCenter ?? _fallbackCenter;

  bool get _useNativeMap =>
      (_renderMode == 'point' && _hasPoint) ||
      (_renderMode == 'rect' && (_hasRect || _hasPoint)) ||
      (_renderMode == 'polygon' && _hasPolygon);

  bool get _canUseEmbed {
    final uri = Uri.tryParse(property.mapEmbedUrl.trim());
    return !_useNativeMap &&
        uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
  }

  double get _resolvedZoom {
    final points = _regionPoints;
    if (points.length < 3) {
      return _hasPoint && !property.isApproximateLocation ? 17 : _defaultZoom;
    }

    var minLat = points.first.latitude;
    var maxLat = points.first.latitude;
    var minLng = points.first.longitude;
    var maxLng = points.first.longitude;
    for (final point in points.skip(1)) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }
    final span = (maxLat - minLat).abs() > (maxLng - minLng).abs()
        ? (maxLat - minLat).abs()
        : (maxLng - minLng).abs();
    if (span >= 0.30) return 9.5;
    if (span >= 0.15) return 10.5;
    if (span >= 0.08) return 11.5;
    if (span >= 0.04) return 12.2;
    if (span >= 0.02) return 13;
    if (span >= 0.01) return 14;
    return 15;
  }

  @override
  void didUpdateWidget(covariant _MapCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_mapReady) return;
    final changed = oldWidget.property.id != property.id ||
        oldWidget.property.latitude != property.latitude ||
        oldWidget.property.longitude != property.longitude ||
        oldWidget.property.mapRenderMode != property.mapRenderMode ||
        oldWidget.property.mapPolygon.length != property.mapPolygon.length ||
        oldWidget.property.mapBoundsNorth != property.mapBoundsNorth ||
        oldWidget.property.mapBoundsSouth != property.mapBoundsSouth ||
        oldWidget.property.mapBoundsEast != property.mapBoundsEast ||
        oldWidget.property.mapBoundsWest != property.mapBoundsWest;
    if (changed && _resolvedCenter != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _mapReady) {
          _mapController.move(_mapCenter, _resolvedZoom);
        }
      });
    }
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 1,
      shadowColor: const Color(0x22000000),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFFF0F2F5)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(13, 12, 13, 13),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _WebStyleSectionTitle(title: context.tr('Vị trí trên bản đồ')),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                height: 292,
                child: _buildMapContent(context),
              ),
            ),
            if (property.mapDisplayNote.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                property.mapDisplayNote.trim(),
                style: const TextStyle(
                  color: Colors.blueGrey,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMapContent(BuildContext context) {
    if (_useNativeMap) return _buildNativeMap(context);

    if (_canUseEmbed) {
      return Stack(
        children: [
          Positioned.fill(
            child: GoogleMapEmbed(
              key: ValueKey<String>(property.mapEmbedUrl),
              url: property.mapEmbedUrl,
              fallback: _buildNoMap(context),
            ),
          ),
          Positioned(
            top: 10,
            left: 10,
            right: 10,
            child: _MapPlaceOverlay(
              title: _mapPlaceTitle(property),
              subtitle: property.mapAddress.trim().isNotEmpty
                  ? property.mapAddress
                  : property.mapDisplayAddress,
              onOpen: _openMapAction,
            ),
          ),
        ],
      );
    }

    return _buildNoMap(context);
  }

  Widget _buildNoMap(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFFF2F5F8),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.location_off_outlined,
                size: 38,
                color: Colors.blueGrey,
              ),
              const SizedBox(height: 10),
              Text(
                context.tr('Chưa có dữ liệu bản đồ.'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppTheme.navy,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (property.mapActionUrl.trim().isNotEmpty ||
                  property.mapOpenUrl.trim().isNotEmpty) ...[
                const SizedBox(height: 10),
                TextButton.icon(
                  onPressed: _openMapAction,
                  icon: const Icon(Icons.open_in_new_rounded),
                  label: Text(context.tr('Mở trong bản đồ')),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNativeMap(BuildContext context) {
    final regionPoints = _regionPoints;
    return Stack(
      children: [
        Positioned.fill(
          child: FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _mapCenter,
              initialZoom: _resolvedZoom,
              minZoom: _minZoom,
              maxZoom: _maxZoom,
              onMapReady: () {
                _mapReady = true;
                if (_resolvedCenter != null) {
                  _mapController.move(_mapCenter, _resolvedZoom);
                }
              },
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.nhawow.mobile',
                maxZoom: _maxZoom,
              ),
              if (regionPoints.length >= 3)
                PolygonLayer(
                  polygons: [
                    Polygon(
                      points: regionPoints,
                      color: const Color(0x14FF3D4F),
                      borderStrokeWidth: 2.2,
                      borderColor: const Color(0xFFFF3D4F),
                      pattern: StrokePattern.dashed(
                        segments: const <double>[7, 5],
                      ),
                    ),
                  ],
                ),
              if (_hasPoint && regionPoints.length < 3)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _mapCenter,
                      width: 56,
                      height: 64,
                      alignment: Alignment.topCenter,
                      child: const _PropertyMapMarker(),
                    ),
                  ],
                ),
            ],
          ),
        ),
        Positioned(
          top: 10,
          left: 10,
          right: 82,
          child: _MapPlaceOverlay(
            title: _mapPlaceTitle(property),
            subtitle: property.mapAddress.trim().isNotEmpty
                ? property.mapAddress
                : property.mapDisplayAddress,
            onOpen: _openMapAction,
          ),
        ),
        Positioned(
          right: 10,
          bottom: 64,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _MapRoundAction(
                tooltip: context.tr('Phóng to'),
                icon: Icons.add_rounded,
                onPressed: () => _changeMapZoom(1),
              ),
              const SizedBox(height: 8),
              _MapRoundAction(
                tooltip: context.tr('Thu nhỏ'),
                icon: Icons.remove_rounded,
                onPressed: () => _changeMapZoom(-1),
              ),
            ],
          ),
        ),
        Positioned(
          right: 10,
          bottom: 10,
          child: _MapRoundAction(
            tooltip: context.tr('Mở toàn màn hình'),
            icon: Icons.fullscreen_rounded,
            onPressed: _openFullScreenMap,
          ),
        ),
        Positioned(
          left: 8,
          bottom: 7,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.90),
                borderRadius: BorderRadius.circular(5),
              ),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                child: Text(
                  '© OpenStreetMap contributors',
                  style: TextStyle(
                    color: Color(0xFF536476),
                    fontSize: 8.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _changeMapZoom(double delta) {
    if (!_mapReady) return;
    final camera = _mapController.camera;
    final nextZoom = (camera.zoom + delta).clamp(_minZoom, _maxZoom).toDouble();
    _mapController.move(camera.center, nextZoom);
  }

  Future<void> _openMapAction() async {
    // Dùng đúng ActionUrl/ClickUrl do PublicMapResolver của website trả về,
    // không geocode lại ở Flutter nên marker/ranh giới đồng nhất với web.
    final rawUrl = property.mapActionUrl.trim().isNotEmpty
        ? property.mapActionUrl.trim()
        : property.mapOpenUrl.trim();
    final uri = Uri.tryParse(rawUrl);
    if (uri == null || !uri.hasScheme) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('Chưa có đường dẫn bản đồ hợp lệ.'))),
      );
      return;
    }

    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('Không thể mở ứng dụng bản đồ.'))),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('Không thể mở ứng dụng bản đồ.'))),
      );
    }
  }

  void _openFullScreenMap() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _FullScreenMapPage(
          center: _mapCenter,
          hasCoordinates: _hasPoint,
          title: _mapPlaceTitle(property),
          regionPoints: _regionPoints,
          initialZoom: _resolvedZoom,
        ),
      ),
    );
  }
}

class _WebStyleSectionTitle extends StatelessWidget {
  const _WebStyleSectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 23,
          decoration: BoxDecoration(
            color: const Color(0xFFFF3D4F),
            borderRadius: BorderRadius.circular(99),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: Color(0xFF172B43),
              fontSize: 16,
              height: 1.2,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _MapPlaceOverlay extends StatelessWidget {
  const _MapPlaceOverlay({
    required this.title,
    required this.subtitle,
    required this.onOpen,
  });

  final String title;
  final String subtitle;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 3,
      shadowColor: const Color(0x33000000),
      borderRadius: BorderRadius.circular(3),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF263238),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (subtitle.trim().isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF6C757D),
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 6),
            InkWell(
              borderRadius: BorderRadius.circular(50),
              onTap: onOpen,
              child: const Padding(
                padding: EdgeInsets.all(7),
                child: Icon(
                  Icons.open_in_new_rounded,
                  color: Color(0xFF2979FF),
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapRoundAction extends StatelessWidget {
  const _MapRoundAction({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 3,
      shadowColor: const Color(0x44000000),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: Icon(icon, color: const Color(0xFF5F6B75), size: 27),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints.tightFor(width: 46, height: 46),
      ),
    );
  }
}

class _FullScreenMapPage extends StatelessWidget {
  const _FullScreenMapPage({
    required this.center,
    required this.hasCoordinates,
    required this.title,
    required this.regionPoints,
    required this.initialZoom,
  });

  final LatLng center;
  final bool hasCoordinates;
  final String title;
  final List<LatLng> regionPoints;
  final double initialZoom;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: FlutterMap(
        options: MapOptions(
          initialCenter: center,
          initialZoom: initialZoom,
          minZoom: 5,
          maxZoom: 19,
          interactionOptions: const InteractionOptions(
            flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
          ),
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.nhawow.mobile',
            maxZoom: 19,
          ),
          if (regionPoints.length >= 3)
            PolygonLayer(
              polygons: [
                Polygon(
                  points: regionPoints,
                  color: const Color(0x14FF3D4F),
                  borderStrokeWidth: 2.2,
                  borderColor: const Color(0xFFFF3D4F),
                  pattern: StrokePattern.dashed(
                    segments: const <double>[7, 5],
                  ),
                ),
              ],
            ),
          if (hasCoordinates && regionPoints.length < 3)
            MarkerLayer(
              markers: [
                Marker(
                  point: center,
                  width: 56,
                  height: 64,
                  alignment: Alignment.topCenter,
                  child: const _PropertyMapMarker(),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _PropertyMapMarker extends StatelessWidget {
  const _PropertyMapMarker();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        Positioned(
          top: 40,
          child: Container(
            width: 24,
            height: 9,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.20),
              borderRadius: BorderRadius.circular(50),
            ),
          ),
        ),
        const Icon(
          Icons.location_pin,
          size: 54,
          color: AppTheme.danger,
          shadows: [
            Shadow(
              color: Color(0x55000000),
              blurRadius: 7,
              offset: Offset(0, 3),
            ),
          ],
        ),
        const Positioned(
          top: 11,
          child: Icon(
            Icons.home_rounded,
            size: 18,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

String _mapPlaceTitle(PropertyModel property) {
  final address = property.mapDisplayAddress.trim();
  if (address.isEmpty) return property.city.trim();

  // Tiêu đề lớn cũng lấy từ cùng dòng địa chỉ nhỏ để tránh hiển thị tên
  // phường/xã không khớp với vị trí bản đồ.
  final firstPart = address.split(',').first.trim();
  return firstPart.isEmpty ? address : firstPart;
}

class _GalleryPageIndicator extends StatelessWidget {
  const _GalleryPageIndicator({
    required this.currentIndex,
    required this.itemCount,
  });

  final int currentIndex;
  final int itemCount;

  @override
  Widget build(BuildContext context) {
    const maxVisibleItems = 7;
    final visibleCount = itemCount > maxVisibleItems ? maxVisibleItems : itemCount;
    final maxStart = itemCount - visibleCount;
    final preferredStart = currentIndex - (visibleCount ~/ 2);
    final startIndex = preferredStart.clamp(0, maxStart);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List<Widget>.generate(visibleCount, (position) {
        final imageIndex = startIndex + position;
        final isActive = imageIndex == currentIndex;
        final isEdgeOverflow = itemCount > visibleCount &&
            ((position == 0 && startIndex > 0) ||
                (position == visibleCount - 1 &&
                    startIndex + visibleCount < itemCount));

        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          width: isActive ? 20 : (isEdgeOverflow ? 4 : 5),
          height: 4,
          margin: const EdgeInsets.symmetric(horizontal: 2.5),
          decoration: BoxDecoration(
            color: isActive
                ? AppTheme.primaryDark
                : const Color(0xFFC9D3DE),
            borderRadius: BorderRadius.circular(99),
          ),
        );
      }),
    );
  }
}

class _ContactBar extends StatelessWidget {
  const _ContactBar({required this.property});

  final PropertyModel property;

  @override
  Widget build(BuildContext context) {
    final owner = property.owner;

    return SafeArea(
      top: false,
      child: Material(
        color: Colors.white,
        elevation: 18,
        shadowColor: const Color(0x22000000),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Color(0xFFE7EDF4))),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => AgentProfilePage(agent: owner),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      AppAvatar(
                        url: owner.avatarUrl,
                        fallbackText: owner.name,
                        radius: 22,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              owner.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppTheme.navy,
                                fontSize: 15.5,
                                height: 1.2,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 5),
                            AgentLevelBadge(agent: owner, compact: true),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: _detailSecondaryTextColor,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _BottomContactAction(
                      backgroundColor: const Color(0xFF18A84B),
                      foregroundColor: Colors.white,
                      icon: Icons.phone_rounded,
                      label: context.tr('Gọi điện'),
                      onPressed: () => _callPropertyOwner(context, property),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _BottomContactAction(
                      backgroundColor: const Color(0xFF1697F6),
                      foregroundColor: Colors.white,
                      icon: Icons.forum_rounded,
                      label: context.tr('Nhắn tin'),
                      onPressed: () => _openPropertyChat(context, property),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<bool> _ensurePropertyLogin(
  BuildContext context,
  PropertyModel property,
) async {
  final store = AppScope.of(context);
  final loggedIn = await AuthGate.ensureLoggedIn(context);
  if (!loggedIn || !context.mounted) return false;

  await store.loadPropertyDetail(property.id);
  return context.mounted && store.isLoggedIn;
}

Future<void> _callPropertyOwner(
  BuildContext context,
  PropertyModel property,
) async {
  final loggedIn = await _ensurePropertyLogin(context, property);
  if (!loggedIn || !context.mounted) return;

  final store = AppScope.of(context);
  final refreshedProperty = store.propertyById(property.id) ?? property;
  final phone = refreshedProperty.owner.phone.trim();
  if (phone.isEmpty) {
    _showDetailMessage(context, context.tr('Số điện thoại đang được cập nhật.'));
    return;
  }

  final phoneDigits = phone.replaceAll(RegExp(r'[^0-9+]'), '');
  final uri = Uri(scheme: 'tel', path: phoneDigits);
  try {
    final opened = await launchUrl(uri);
    if (!opened && context.mounted) {
      _showDetailMessage(context, context.tr('Không thể thực hiện cuộc gọi.'));
    }
  } catch (_) {
    if (context.mounted) {
      _showDetailMessage(context, context.tr('Không thể thực hiện cuộc gọi.'));
    }
  }
}

Future<void> _openPropertyChat(
  BuildContext context,
  PropertyModel property,
) async {
  final loggedIn = await _ensurePropertyLogin(context, property);
  if (!loggedIn || !context.mounted) return;

  final store = AppScope.of(context);
  try {
    final conversation = await store.startPropertyConversation(property.id);
    if (!context.mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ChatThreadPage(conversationId: conversation.id),
      ),
    );
  } catch (error) {
    if (context.mounted) {
      _showDetailMessage(context, context.tr(error.toString()));
    }
  }
}

Future<void> _sharePropertyLink(
  BuildContext context,
  PropertyModel property,
) async {
  final link = '${AppConfig.webBaseUrl}/Property/Detail/${property.id}';
  await Clipboard.setData(ClipboardData(text: link));
  if (context.mounted) {
    _showDetailMessage(context, context.tr('Đã sao chép liên kết tin đăng'));
  }
}

void _showDetailMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(context.tr(message))),
  );
}

class _BottomContactAction extends StatelessWidget {
  const _BottomContactAction({
    required this.backgroundColor,
    required this.foregroundColor,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final Color backgroundColor;
  final Color foregroundColor;
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: Material(
        color: backgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(11),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: foregroundColor, size: 18),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: foregroundColor,
                      fontSize: 12.5,
                      height: 1.1,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

List<String> _galleryUrls(PropertyModel property) {
  final urls = <String>[];
  for (final url in property.imageUrls) {
    final normalized = url.trim();
    if (normalized.isNotEmpty && !urls.contains(normalized)) {
      urls.add(normalized);
    }
  }

  final thumbnail = property.thumbnailUrl.trim();
  if (thumbnail.isNotEmpty && !urls.contains(thumbnail)) {
    urls.insert(0, thumbnail);
  }
  return urls;
}

String _formatNumber(double value) {
  if (value == value.roundToDouble()) return value.toStringAsFixed(0);
  return value.toStringAsFixed(2).replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
}

String _textOrUpdating(String? value) {
  final normalized = value?.trim() ?? '';
  return normalized.isEmpty ? 'Đang cập nhật' : normalized;
}

String _meterOrUpdating(String? raw) {
  final value = raw?.trim() ?? '';
  if (value.isEmpty) return 'Đang cập nhật';
  if (value.toLowerCase().contains('m')) return value;

  final numeric = double.tryParse(value.replaceAll(',', '.'));
  return numeric == null ? value : '${_formatNumber(numeric)} m';
}

String _unitOrUpdating(String? raw, String unit) {
  final value = raw?.trim() ?? '';
  if (value.isEmpty) return 'Đang cập nhật';

  final normalizedValue = value.toLowerCase().replaceAll(' ', '');
  final normalizedUnit = unit.toLowerCase().replaceAll(' ', '');
  if (normalizedValue.contains(normalizedUnit)) return value;

  final numeric = double.tryParse(value.replaceAll(',', '.'));
  final display = numeric == null ? value : _formatNumber(numeric);
  return '$display $unit';
}

String _detailPricePerSquareMeter(
  BuildContext context,
  PropertyModel property,
) {
  if (property.kind != ListingKind.houseSale &&
      property.kind != ListingKind.landSale) {
    return '';
  }

  if (property.area <= 0) return '';

  final parsedFromLabel = _parseDetailPriceLabel(property.priceLabel);
  var totalPrice = property.price;
  if (totalPrice <= 0 ||
      (totalPrice < 1000000 && parsedFromLabel > totalPrice * 1000)) {
    totalPrice = parsedFromLabel;
  }

  if (totalPrice <= 0) return '';

  final millionPerSquareMeter = totalPrice / property.area / 1000000;
  if (!millionPerSquareMeter.isFinite || millionPerSquareMeter <= 0) {
    return '';
  }

  final languageCode = Localizations.localeOf(context).languageCode;
  if (languageCode.toLowerCase().startsWith('zh')) {
    final vndPerSquareMeter = totalPrice / property.area;
    return '${formatChineseVndCompact(vndPerSquareMeter)}/平方米';
  }

  final raw = millionPerSquareMeter.toStringAsFixed(2);
  final formatted = languageCode == 'vi' ? raw.replaceAll('.', ',') : raw;
  return context.tr('{value} triệu/m²', {'value': formatted});
}

double _parseDetailPriceLabel(String label) {
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
      normalized.contains('nghin') ||
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
    numberText = numberText.replaceAll('.', '').replaceAll(',', '');
  } else if (numberText.contains(',') && numberText.contains('.')) {
    numberText = numberText.replaceAll('.', '').replaceAll(',', '.');
  } else if (numberText.contains(',')) {
    numberText = numberText.replaceAll(',', '.');
  } else if (numberText.contains('.')) {
    final parts = numberText.split('.');
    if (!(parts.length == 2 && parts.last.length <= 2)) {
      numberText = numberText.replaceAll('.', '');
    }
  }

  return (double.tryParse(numberText) ?? 0) * multiplier;
}
