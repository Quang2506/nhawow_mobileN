import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/app_store.dart';
import '../core/app_assets.dart';
import '../core/auth_gate.dart';
import '../core/widgets.dart';
import '../models/models.dart';
import '../l10n/app_localizations.dart';
import 'notifications_page.dart';
import 'chat_inbox_page.dart';
import 'property_detail_page.dart';
import 'search_page.dart';

// Bảng màu riêng cho trang chủ, giúp toàn bộ phần banner và danh mục đồng nhất.
class _HomePalette {
  const _HomePalette._();

  static const Color primary = Color(0xFF0866FF);
  static const Color navy = Color(0xFF082457);
  static const Color pageBackground = Color(0xFFF4F7FC);
  static const Color iconBackground = Color(0xFFEEF5FF);
  static const Color secondaryText = Color(0xFF667085);
  static const Color placeholder = Color(0xFF98A2B3);
}

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    this.selectedKind = ListingKind.houseSale,
    this.scrollToTopRequest = 0,
    this.onSelectedKindChanged,
    this.onBottomSwitcherVisibilityChanged,
  });

  final ListingKind selectedKind;
  final int scrollToTopRequest;
  final ValueChanged<ListingKind>? onSelectedKindChanged;
  final ValueChanged<bool>? onBottomSwitcherVisibilityChanged;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const double _stickyToolbarThreshold = 170;
  static const double _loadMoreThreshold = 720;
  static const double _scrollDirectionThreshold = 5;

  final ScrollController _scrollController = ScrollController();
  final GlobalKey _listingSectionKey = GlobalKey();
  late AppStore _store;
  bool _showStickyToolbar = false;
  bool _loadCheckScheduled = false;
  bool _bottomSwitcherVisible = false;
  double? _bottomSwitcherActivationOffset;
  double _previousScrollOffset = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateBottomSwitcherActivationOffset();
      _setBottomSwitcherVisibility(false);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _store = AppScope.of(context);
  }

  @override
  void didUpdateWidget(covariant HomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedKind != widget.selectedKind) {
      _scheduleLoadMoreCheck();
    }
    if (oldWidget.scrollToTopRequest != widget.scrollToTopRequest) {
      _animateToTop();
    }
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (!_scrollController.hasClients || !mounted) return;

    final offset = _scrollController.offset;
    final shouldShowStickyToolbar = offset >= _stickyToolbarThreshold;
    if (shouldShowStickyToolbar != _showStickyToolbar) {
      setState(() => _showStickyToolbar = shouldShowStickyToolbar);
    }

    // Thanh lựa chọn nổi chỉ bắt đầu hoạt động sau khi phần danh sách tin
    // (vạch phân cách ngay trên tiêu đề "Bán nhà/Thuê nhà/...") đã đi qua
    // mép trên màn hình. Trước mốc này, khối lựa chọn lớn trong banner vẫn
    // đang hiện nên không hiển thị thêm một thanh lựa chọn ở phía dưới.
    final activationOffset = _bottomSwitcherActivationOffset;
    final delta = offset - _previousScrollOffset;

    if (activationOffset == null) {
      _updateBottomSwitcherActivationOffset();
      _setBottomSwitcherVisibility(false);
    } else if (offset < activationOffset) {
      // Quay trở lại phía trên vạch: luôn ẩn thanh nổi.
      _setBottomSwitcherVisibility(false);
    } else if (delta > _scrollDirectionThreshold) {
      // Đi xuống sâu hơn trong danh sách: ẩn để ưu tiên diện tích nội dung.
      _setBottomSwitcherVisibility(false);
    } else if (delta < -_scrollDirectionThreshold) {
      // Sau khi đã qua vạch, cuộn ngược lên: hiện các chức năng trong khung.
      _setBottomSwitcherVisibility(true);
    }
    _previousScrollOffset = offset;

    if (_scrollController.position.extentAfter <= _loadMoreThreshold) {
      _store.loadMoreProperties(widget.selectedKind);
    }
  }

  void _animateToTop() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
      );
      _setBottomSwitcherVisibility(false);
    });
  }

  void _scheduleLoadMoreCheck() {
    if (_loadCheckScheduled) return;
    _loadCheckScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCheckScheduled = false;
      if (!mounted || !_scrollController.hasClients) return;
      if (_scrollController.position.extentAfter <= _loadMoreThreshold) {
        _store.loadMoreProperties(widget.selectedKind);
      }
    });
  }

  void _updateBottomSwitcherActivationOffset() {
    if (!mounted || !_scrollController.hasClients) return;

    final sectionContext = _listingSectionKey.currentContext;
    final renderObject = sectionContext?.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) return;

    final sectionTopOnScreen = renderObject.localToGlobal(Offset.zero).dy;
    final absoluteSectionTop =
        _scrollController.offset + sectionTopOnScreen;

    if (absoluteSectionTop.isFinite && absoluteSectionTop > 0) {
      _bottomSwitcherActivationOffset = absoluteSectionTop;
    }
  }

  void _setBottomSwitcherVisibility(bool visible) {
    if (_bottomSwitcherVisible == visible) return;
    _bottomSwitcherVisible = visible;
    widget.onBottomSwitcherVisibilityChanged?.call(visible);
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final selectedKind = widget.selectedKind;
    final items = store.properties
        .where((item) => item.kind == selectedKind)
        .toList(growable: false);
    final isLoadingMore = store.isLoadingMoreProperties(selectedKind);
    final hasMore = store.hasMoreProperties(selectedKind);
    _scheduleLoadMoreCheck();

    final overlayStyle = (_showStickyToolbar
            ? SystemUiOverlayStyle.dark
            : SystemUiOverlayStyle.light)
        .copyWith(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    );

    Future<void> openNotifications() async {
      final loggedIn = await AuthGate.ensureLoggedIn(context);
      if (!loggedIn || !context.mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const NotificationsPage(),
        ),
      );
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: Scaffold(
        backgroundColor: _HomePalette.pageBackground,
        body: Stack(
          children: [
            RefreshIndicator(
              onRefresh: store.refreshProperties,
              child: SingleChildScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _DesignedHomeHeader(
                      store: store,
                      onSearch: () => _openSearch(context, store),
                      onAccount: () => _openAccount(context, store),
                      onNotifications: openNotifications,
                      onMessages: () => _openMessages(context),
                      selectedKind: selectedKind,
                      onCategorySelected: (kind) {
                        widget.onSelectedKindChanged?.call(kind);
                        _setBottomSwitcherVisibility(false);
                      },
                    ),
                    PageContainer(
                      key: _listingSectionKey,
                      // Chừa đủ không gian cho thanh danh mục nổi và bottom bar.
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 184),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (store.isLoadingProperties) ...[
                            const LinearProgressIndicator(),
                            const SizedBox(height: 12),
                          ],
                          if (store.propertyError != null ||
                              store.usingMockData) ...[
                            _ApiStatusBanner(
                              message: store.usingMockData
                                  ? context.tr('Chưa kết nối được API PostgreSQL. Ứng dụng đang hiển thị dữ liệu mẫu.')
                                  : context.tr(store.propertyError!),
                              onRetry: store.refreshProperties,
                            ),
                            const SizedBox(height: 14),
                          ],
                          const SizedBox(height: 18),
                          SectionHeader(
                            title: context.tr(selectedKind.label),
                            subtitle: context.tr(
                              'Danh sách tin mới nhất từ hệ thống NhaWOW',
                            ),
                          ),
                          const SizedBox(height: 12),
                          PropertyGrid(
                            properties: items,
                            onPropertyTap: (property) =>
                                _openDetail(context, property.id),
                          ),
                          if (isLoadingMore) ...[
                            const SizedBox(height: 22),
                            const _HomeLoadMoreIndicator(),
                          ],
                          if (!hasMore && items.isNotEmpty) ...[
                            const SizedBox(height: 28),
                            const _BrokerBanner(),
                          ],
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: IgnorePointer(
                ignoring: !_showStickyToolbar,
                child: AnimatedSlide(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  offset: _showStickyToolbar
                      ? Offset.zero
                      : const Offset(0, -1.15),
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 160),
                    opacity: _showStickyToolbar ? 1 : 0,
                    child: _StickyHomeToolbar(
                      store: store,
                      onSearch: () => _openSearch(context, store),
                      onNotifications: openNotifications,
                      onMessages: () => _openMessages(context),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openSearch(
    BuildContext context,
    AppStore store, {
    SearchFilterModel initialFilter = const SearchFilterModel(),
  }) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SearchPage(initialFilter: initialFilter),
      ),
    );
  }

  void _openDetail(BuildContext context, int propertyId) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PropertyDetailPage(propertyId: propertyId),
      ),
    );
  }

  Future<void> _openMessages(BuildContext context) async {
    final loggedIn = await AuthGate.ensureLoggedIn(context);
    if (!loggedIn || !context.mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const ChatInboxPage()),
    );
  }

  Future<void> _openAccount(BuildContext context, AppStore store) async {
    final loggedIn = await AuthGate.ensureLoggedIn(context);
    if (!loggedIn || !context.mounted) return;
    store.setSelectedTab(3);
  }

}

// Các thông số giao diện phần đầu trang chủ.
class _HomeHeaderUiTuning {
  const _HomeHeaderUiTuning._();

  // Banner gốc có kích thước 750 x 500, tương ứng tỉ lệ 3:2.
  static const double maxBannerWidth = 750;
  static const double bannerAspectRatio = 750 / 500;

  // Độ nâng của cả cụm tìm kiếm + danh mục lên trên banner.
  // Tăng giá trị này nếu muốn cụm được đẩy lên cao hơn nữa.
  static const double verySmallControlsLift = 28;
  static const double compactControlsLift = 85;
  static const double wideControlsLift = 72;
}

class _DesignedHomeHeader extends StatelessWidget {
  const _DesignedHomeHeader({
    required this.store,
    required this.onSearch,
    required this.onAccount,
    required this.onNotifications,
    required this.onMessages,
    required this.selectedKind,
    required this.onCategorySelected,
  });

  final AppStore store;
  final VoidCallback onSearch;
  final VoidCallback onAccount;
  final VoidCallback onNotifications;
  final VoidCallback onMessages;
  final ListingKind selectedKind;
  final ValueChanged<ListingKind> onCategorySelected;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth > _HomeHeaderUiTuning.maxBannerWidth
            ? _HomeHeaderUiTuning.maxBannerWidth
            : constraints.maxWidth;
        final compact = width < 700;
        final verySmall = width < 350;

        // Luôn giữ đúng tỉ lệ hiển thị 750 x 500 của ảnh banner.
        final heroHeight = width / _HomeHeaderUiTuning.bannerAspectRatio;
        final searchHeight = compact ? 44.0 : 58.0;
        final categoryCardHeight = compact ? 184.0 : 126.0;
        final controlsGap = compact ? 14.0 : 18.0;
        final controlsInset = compact ? 16.0 : 36.0;
        final controlsLift = verySmall
            ? _HomeHeaderUiTuning.verySmallControlsLift
            : compact
                ? _HomeHeaderUiTuning.compactControlsLift
                : _HomeHeaderUiTuning.wideControlsLift;

        // Cả ô tìm kiếm và khối danh mục được đặt thành một cụm,
        // sau đó nâng lên đúng vùng gạch màu cam trong ảnh mẫu.
        final controlsTop = heroHeight - searchHeight - controlsLift;
        final controlsHeight =
            searchHeight + controlsGap + categoryCardHeight;
        final totalHeight = controlsTop + controlsHeight + 18;
        final horizontalMargin = (constraints.maxWidth - width) / 2;

        return SizedBox(
          width: constraints.maxWidth,
          height: totalHeight,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: horizontalMargin,
                top: 0,
                width: width,
                height: heroHeight,
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(
                        AppAssets.landlordHeroMobile,
                        fit: BoxFit.cover,
                        alignment: Alignment.center,
                        filterQuality: FilterQuality.high,
                        errorBuilder: (_, __, ___) => const ColoredBox(
                          color: _HomePalette.pageBackground,
                        ),
                      ),

                      // Lớp phủ xanh navy làm dịu ảnh và giúp chữ trắng dễ đọc.
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            stops: [0.0, 0.52, 1.0],
                            colors: [
                              Color(0xA8061B3F),
                              Color(0x52061B3F),
                              Color(0x12061B3F),
                            ],
                          ),
                        ),
                      ),

                      _HeroForeground(
                        store: store,
                        compact: compact,
                        verySmall: verySmall,
                        onAccount: onAccount,
                        onNotifications: onNotifications,
                        onMessages: onMessages,
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: controlsTop,
                left: horizontalMargin + controlsInset,
                width: width - (controlsInset * 2),
                height: controlsHeight,
                child: Column(
                  children: [
                    SizedBox(
                      height: searchHeight,
                      child: _HeroSearchPill(
                        onTap: onSearch,
                        compact: compact,
                        verySmall: verySmall,
                      ),
                    ),
                    SizedBox(height: controlsGap),
                    SizedBox(
                      height: categoryCardHeight,
                      child: _QuickCategoryCard(
                        compact: compact,
                        selectedKind: selectedKind,
                        onSelected: onCategorySelected,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HeroForeground extends StatelessWidget {
  const _HeroForeground({
    required this.store,
    required this.compact,
    required this.verySmall,
    required this.onAccount,
    required this.onNotifications,
    required this.onMessages,
  });

  final AppStore store;
  final bool compact;
  final bool verySmall;
  final VoidCallback onAccount;
  final VoidCallback onNotifications;
  final VoidCallback onMessages;

  @override
  Widget build(BuildContext context) {
    final safeTop = MediaQuery.paddingOf(context).top;
    final greeting = context.tr(_greetingForHour(DateTime.now().hour));
    final displayName = context.tr(_displayName(store));

    return Padding(
      padding: EdgeInsets.fromLTRB(
        compact ? 16 : 30,
        safeTop + (compact ? 6 : 14),
        compact ? 16 : 30,
        compact ? 8 : 20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _WhiteBrandWordmark(onTap: onAccount),
              const Spacer(),
              CountBadge(
                count: store.unreadNotificationCount,
                child: _RoundHeroIconButton(
                  tooltip: context.tr('Thông báo'),
                  icon: Icons.notifications_none_rounded,
                  onPressed: onNotifications,
                ),
              ),
              SizedBox(width: compact ? 8 : 10),
              CountBadge(
                count: store.unreadMessageCount,
                child: _RoundHeroIconButton(
                  tooltip: context.tr('Tin nhắn'),
                  icon: Icons.chat_bubble_outline_rounded,
                  onPressed: onMessages,
                ),
              ),
            ],
          ),
          SizedBox(height: compact ? 7 : 18),
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: compact ? 330 : 500),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  greeting,
                  style: TextStyle(
                    color: const Color(0xE6FFFFFF),
                    fontSize: verySmall ? 12.5 : (compact ? 14 : 18),
                    fontWeight: FontWeight.w600,
                    height: 1.05,
                    shadows: const [
                      Shadow(
                        color: Color(0x66000000),
                        blurRadius: 7,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: verySmall ? 26 : (compact ? 32 : 43),
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.8,
                          height: 1,
                          shadows: const [
                            Shadow(
                              color: Color(0x73000000),
                              blurRadius: 10,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (!store.isLoggedIn) ...[
                      SizedBox(width: verySmall ? 8 : 11),
                      _LoginNowButton(
                        compact: compact,
                        verySmall: verySmall,
                        onPressed: onAccount,
                      ),
                    ],
                  ],
                ),
                SizedBox(height: compact ? 5 : 8),
                Text(
                  context.tr('Khám phá không gian sống chân thực với trải nghiệm VR 360°.'),
                  maxLines: verySmall ? 1 : (compact ? 2 : 3),
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: const Color(0xD1FFFFFF),
                    fontSize: verySmall ? 11 : (compact ? 12.5 : 15),
                    height: 1.32,
                    fontWeight: FontWeight.w500,
                    shadows: const [
                      Shadow(
                        color: Color(0x66000000),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _greetingForHour(int hour) {
    if (hour >= 5 && hour < 12) return 'Chào buổi sáng';
    if (hour >= 12 && hour < 18) return 'Chào buổi chiều';
    return 'Chào buổi tối';
  }

  static String _displayName(AppStore store) {
    if (!store.isLoggedIn) return 'Khách';
    final name = store.currentUser.name.trim();
    if (name.isEmpty) return 'Bạn';
    final parts = name.split(RegExp(r'\s+'));
    return parts.isEmpty ? name : parts.last;
  }
}


class _LoginNowButton extends StatelessWidget {
  const _LoginNowButton({
    required this.compact,
    required this.verySmall,
    required this.onPressed,
  });

  final bool compact;
  final bool verySmall;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.96),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: verySmall ? 10 : (compact ? 12 : 16),
            vertical: verySmall ? 6 : (compact ? 7 : 9),
          ),
          child: Text(
            context.tr('Đăng nhập ngay'),
            maxLines: 1,
            style: TextStyle(
              color: _HomePalette.primary,
              fontSize: verySmall ? 10.5 : (compact ? 11.5 : 14),
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _WhiteBrandWordmark extends StatelessWidget {
  const _WhiteBrandWordmark({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 3),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 28,
                height: 28,
                child: Image.asset(
                  AppAssets.brandLogo,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.home_rounded,
                    color: _HomePalette.primary,
                    size: 25,
                  ),
                ),
              ),
              const SizedBox(width: 7),
              const Text(
                'NhaWOW',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.4,
                  shadows: [
                    Shadow(
                      color: Color(0x73000000),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoundHeroIconButton extends StatelessWidget {
  const _RoundHeroIconButton({
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
      color: Colors.white.withValues(alpha: 0.94),
      elevation: 3,
      shadowColor: const Color(0x1F082457),
      shape: const CircleBorder(),
      child: SizedBox(
        width: 40,
        height: 40,
        child: IconButton(
          tooltip: tooltip,
          padding: EdgeInsets.zero,
          onPressed: onPressed,
          icon: Icon(icon, color: _HomePalette.navy, size: 22),
        ),
      ),
    );
  }
}

class _HeroSearchPill extends StatelessWidget {
  const _HeroSearchPill({
    required this.onTap,
    required this.compact,
    required this.verySmall,
  });

  final VoidCallback onTap;
  final bool compact;
  final bool verySmall;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.96),
      elevation: 5,
      shadowColor: const Color(0x21082457),
      borderRadius: BorderRadius.circular(compact ? 18 : 22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(compact ? 18 : 22),
        child: SizedBox(
          height: compact ? 44 : 58,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: verySmall ? 14 : 18),
            child: Row(
              children: [
                Icon(
                  Icons.search_rounded,
                  color: _HomePalette.navy,
                  size: verySmall ? 25 : (compact ? 27 : 31),
                ),
                SizedBox(width: compact ? 10 : 13),
                Expanded(
                  child: Text(
                    context.tr('Tìm bất động sản, nhà, đất, mặt bằng...'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _HomePalette.placeholder,
                      fontSize: verySmall ? 12.5 : (compact ? 14 : 17),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Container(
                  width: 1,
                  height: compact ? 24 : 30,
                  margin: EdgeInsets.symmetric(horizontal: compact ? 8 : 12),
                  color: const Color(0xFFE3E8F0),
                ),
                Icon(
                  Icons.tune_rounded,
                  color: _HomePalette.primary,
                  size: verySmall ? 23 : (compact ? 25 : 28),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


class _StickyHomeToolbar extends StatelessWidget {
  const _StickyHomeToolbar({
    required this.store,
    required this.onSearch,
    required this.onNotifications,
    required this.onMessages,
  });

  final AppStore store;
  final VoidCallback onSearch;
  final VoidCallback onNotifications;
  final VoidCallback onMessages;

  @override
  Widget build(BuildContext context) {
    final safeTop = MediaQuery.paddingOf(context).top;

    return Material(
      color: Colors.white,
      elevation: 8,
      shadowColor: const Color(0x25082457),
      child: Padding(
        padding: EdgeInsets.fromLTRB(12, safeTop + 8, 12, 9),
        child: Row(
          children: [
            Expanded(
              child: _StickySearchField(onTap: onSearch),
            ),
            const SizedBox(width: 8),
            CountBadge(
              count: store.unreadNotificationCount,
              child: _StickyToolbarIconButton(
                tooltip: context.tr('Thông báo'),
                icon: Icons.notifications_none_rounded,
                onPressed: onNotifications,
              ),
            ),
            const SizedBox(width: 6),
            CountBadge(
              count: store.unreadMessageCount,
              child: _StickyToolbarIconButton(
                tooltip: context.tr('Tin nhắn'),
                icon: Icons.chat_bubble_outline_rounded,
                onPressed: onMessages,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StickySearchField extends StatelessWidget {
  const _StickySearchField({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF8FAFD),
      borderRadius: BorderRadius.circular(17),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(17),
        child: Container(
          height: 46,
          padding: const EdgeInsets.fromLTRB(13, 0, 10, 0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: const Color(0xFFD9E0EA)),
          ),
          child: Row(
            children: [
              Icon(
                Icons.search_rounded,
                color: _HomePalette.navy,
                size: 25,
              ),
              SizedBox(width: 9),
              Expanded(
                child: Text(
                  context.tr('Tìm bất động sản...'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _HomePalette.placeholder,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              SizedBox(width: 7),
              SizedBox(
                height: 24,
                child: VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: Color(0xFFE0E6EF),
                ),
              ),
              SizedBox(width: 9),
              Icon(
                Icons.tune_rounded,
                color: _HomePalette.primary,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StickyToolbarIconButton extends StatelessWidget {
  const _StickyToolbarIconButton({
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
      color: const Color(0xFFF8FAFD),
      shape: const CircleBorder(
        side: BorderSide(color: Color(0xFFD9E0EA)),
      ),
      child: SizedBox(
        width: 44,
        height: 44,
        child: IconButton(
          tooltip: tooltip,
          padding: EdgeInsets.zero,
          onPressed: onPressed,
          icon: Icon(icon, color: _HomePalette.navy, size: 23),
        ),
      ),
    );
  }
}

class _QuickCategoryCard extends StatelessWidget {
  const _QuickCategoryCard({
    required this.compact,
    required this.selectedKind,
    required this.onSelected,
  });

  final bool compact;
  final ListingKind selectedKind;
  final ValueChanged<ListingKind> onSelected;

  @override
  Widget build(BuildContext context) {
    final items = <_QuickCategoryData>[
      const _QuickCategoryData(
        label: 'Bán nhà',
        icon: Icons.real_estate_agent_outlined,
        kind: ListingKind.houseSale,
      ),
      const _QuickCategoryData(
        label: 'Thuê nhà',
        icon: Icons.house_outlined,
        kind: ListingKind.houseRent,
      ),
      const _QuickCategoryData(
        label: 'Đất bán',
        icon: Icons.location_on_outlined,
        kind: ListingKind.landSale,
      ),
      const _QuickCategoryData(
        label: 'Mặt bằng',
        icon: Icons.storefront_outlined,
        kind: ListingKind.premises,
      ),
    ];

    return Material(
      color: Colors.white,
      elevation: 5,
      shadowColor: const Color(0x17082457),
      borderRadius: BorderRadius.circular(compact ? 22 : 26),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 12 : 18,
          vertical: compact ? 12 : 14,
        ),
        child: compact
            ? Column(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: _QuickCategoryTile(
                            data: items[0],
                            compact: true,
                            selected: selectedKind == items[0].kind,
                            onTap: () => onSelected(items[0].kind),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _QuickCategoryTile(
                            data: items[1],
                            compact: true,
                            selected: selectedKind == items[1].kind,
                            onTap: () => onSelected(items[1].kind),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: _QuickCategoryTile(
                            data: items[2],
                            compact: true,
                            selected: selectedKind == items[2].kind,
                            onTap: () => onSelected(items[2].kind),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _QuickCategoryTile(
                            data: items[3],
                            compact: true,
                            selected: selectedKind == items[3].kind,
                            onTap: () => onSelected(items[3].kind),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            : Row(
                children: [
                  for (var index = 0; index < items.length; index++) ...[
                    if (index > 0) const SizedBox(width: 10),
                    Expanded(
                      child: _QuickCategoryTile(
                        data: items[index],
                        compact: false,
                        selected: selectedKind == items[index].kind,
                        onTap: () => onSelected(items[index].kind),
                      ),
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}

class _QuickCategoryTile extends StatelessWidget {
  const _QuickCategoryTile({
    required this.data,
    required this.compact,
    required this.selected,
    required this.onTap,
  });

  final _QuickCategoryData data;
  final bool compact;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tileColor = selected ? const Color(0xFFF3F8FF) : Colors.transparent;
    final borderColor = selected ? const Color(0xFFBFD6FF) : Colors.transparent;

    return Material(
      color: tileColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: compact
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _QuickCategoryIcon(icon: data.icon, compact: true),
                    const SizedBox(height: 5),
                    Text(
                      context.tr(data.label),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _HomePalette.navy,
                        fontSize: 14,
                        fontWeight:
                            selected ? FontWeight.w800 : FontWeight.w700,
                      ),
                    ),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _QuickCategoryIcon(icon: data.icon, compact: false),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        context.tr(data.label),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: _HomePalette.navy,
                          fontSize: 16,
                          fontWeight:
                              selected ? FontWeight.w900 : FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _QuickCategoryIcon extends StatelessWidget {
  const _QuickCategoryIcon({required this.icon, required this.compact});

  final IconData icon;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 48.0 : 50.0;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _HomePalette.iconBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x120866FF),
            blurRadius: 12,
            offset: Offset(0, 5),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Icon(
        icon,
        color: _HomePalette.primary,
        size: compact ? 29 : 30,
      ),
    );
  }
}

class _QuickCategoryData {
  const _QuickCategoryData({
    required this.label,
    required this.icon,
    required this.kind,
  });

  final String label;
  final IconData icon;
  final ListingKind kind;
}

class _HomeLoadMoreIndicator extends StatelessWidget {
  const _HomeLoadMoreIndicator();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2.6),
            ),
            const SizedBox(height: 9),
            Text(
              context.tr('Đang tải thêm bất động sản...'),
              style: const TextStyle(
                color: _HomePalette.secondaryText,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ApiStatusBanner extends StatelessWidget {
  const _ApiStatusBanner({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFFFF4D6),
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            const Icon(Icons.info_outline, color: Color(0xFF9A6700)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                context.tr(message),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Color(0xFF714B00)),
              ),
            ),
            TextButton(
              onPressed: () => onRetry(),
              child: Text(context.tr('Thử lại')),
            ),
          ],
        ),
      ),
    );
  }
}

class _BrokerBanner extends StatelessWidget {
  const _BrokerBanner();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 29,
              backgroundColor: _HomePalette.iconBackground,
              child: Icon(
                Icons.campaign_outlined,
                color: _HomePalette.primary,
                size: 30,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr('Bạn là môi giới hoặc chủ nhà?'),
                    style: const TextStyle(
                      color: _HomePalette.navy,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    context.tr('Đăng tin và quản lý khách hàng ngay trên ứng dụng NhaWOW.'),
                    style: const TextStyle(
                      color: _HomePalette.secondaryText,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: _HomePalette.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final allowed = await AuthGate.ensurePostingPermission(context);
                if (!context.mounted || !allowed) return;
                AppScope.of(context).setSelectedTab(2);
              },
              child: Text(context.tr('Đăng tin')),
            ),
          ],
        ),
      ),
    );
  }
}
