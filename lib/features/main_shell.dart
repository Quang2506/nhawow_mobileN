import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app/app_store.dart';
import '../core/app_assets.dart';
import '../core/app_image.dart';
import '../core/auth_gate.dart';
import '../core/widgets.dart';
import '../models/models.dart';
import '../l10n/app_localizations.dart';
import 'account_page.dart';
import 'favorites_page.dart';
import 'home_page.dart';
import 'landlord_request_page.dart';
import 'search_page.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  ListingKind _selectedHomeKind = ListingKind.houseSale;
  // Lúc ở đầu trang, cụm danh mục lớn trong banner đã hiển thị đầy đủ nên
  // không cần hiện thêm thanh danh mục nổi phía trên bottom navigation.
  bool _showHomeKindSwitcher = false;
  int _homeScrollToTopRequest = 0;

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final pages = <Widget>[
      HomePage(
        selectedKind: _selectedHomeKind,
        scrollToTopRequest: _homeScrollToTopRequest,
        onSelectedKindChanged: _selectHomeKind,
        onBottomSwitcherVisibilityChanged: _setHomeKindSwitcherVisible,
      ),
      const FavoritesPage(),
      const LandlordRequestPage(embedded: true),
      const AccountPage(),
      const SearchPage(embedded: true),
    ];

    final int selectedIndex =
        store.selectedTab.clamp(0, pages.length - 1).toInt();

    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: selectedIndex, children: pages),
      bottomNavigationBar: _NhaWowBottomBar(
        selectedIndex: selectedIndex,
        favoriteCount: store.favoriteProperties.length,
        isLoggedIn: store.isLoggedIn,
        store: store,
        selectedKind: _selectedHomeKind,
        showKindSwitcher: selectedIndex == 0 && _showHomeKindSwitcher,
        onHome: () {
          store.setSelectedTab(0);
          _requestHomeScrollToTop();
        },
        onFavorites: () => _openFavorites(store),
        onFindHome: () {
          store.setSelectedTab(4);
        },
        onKindSelected: (kind) {
          store.setSelectedTab(0);
          setState(() {
            _selectedHomeKind = kind;
            _showHomeKindSwitcher = false;
            _homeScrollToTopRequest++;
          });
        },
        onPost: () => _openPosting(store),
        onAccount: () => store.setSelectedTab(3),
      ),
    );
  }

  Future<void> _openFavorites(AppStore store) async {
    final allowed = await AuthGate.ensureLoggedIn(context);
    if (!mounted || !allowed) return;
    store.setSelectedTab(1);
  }

  void _openPosting(AppStore store) {
    store.setSelectedTab(2);
  }

  void _requestHomeScrollToTop() {
    setState(() {
      _showHomeKindSwitcher = false;
      _homeScrollToTopRequest++;
    });
  }

  void _selectHomeKind(ListingKind kind) {
    if (_selectedHomeKind == kind) return;
    setState(() => _selectedHomeKind = kind);
  }

  void _setHomeKindSwitcherVisible(bool visible) {
    if (_showHomeKindSwitcher == visible || !mounted) return;
    setState(() => _showHomeKindSwitcher = visible);
  }
}

class _NhaWowBottomBar extends StatelessWidget {
  const _NhaWowBottomBar({
    required this.selectedIndex,
    required this.favoriteCount,
    required this.isLoggedIn,
    required this.store,
    required this.selectedKind,
    required this.showKindSwitcher,
    required this.onHome,
    required this.onFavorites,
    required this.onFindHome,
    required this.onKindSelected,
    required this.onPost,
    required this.onAccount,
  });

  final int selectedIndex;
  final int favoriteCount;
  final bool isLoggedIn;
  final AppStore store;
  final ListingKind selectedKind;
  final bool showKindSwitcher;
  final VoidCallback onHome;
  final VoidCallback onFavorites;
  final VoidCallback onFindHome;
  final ValueChanged<ListingKind> onKindSelected;
  final VoidCallback onPost;
  final VoidCallback onAccount;

  static const Color _activeColor = Color(0xFF0866FF);
  static const Color _navy = Color(0xFF082457);
  static const Color _inactiveColor = Color(0xFF7B8796);
  static const double _bodyHeight = 84;
  static const double _topNotchDepth = 20;

  // Phần nút giữa nhô lên khỏi thân thanh điều hướng.
  static const double _centerButtonLift = 20;

  // Kích thước và khoảng cách của thanh switch phía trên.
  static const double _kindSwitcherHeight = 46;
  static const double _kindSwitcherGap = 38;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final navHeight = _bodyHeight + bottomInset;
    final navLayerHeight = navHeight + _centerButtonLift;

    // Quan trọng: khi switch đang hiển thị, chiều cao thật của
    // bottomNavigationBar phải bao gồm cả switch. Nếu chỉ vẽ switch ra ngoài
    // Stack bằng clipBehavior: Clip.none thì switch vẫn nhìn thấy nhưng Flutter
    // không hit-test vùng nằm ngoài kích thước cha, nên bấm sẽ không hoạt động.
    final switcherExtraHeight = showKindSwitcher
        ? _kindSwitcherHeight + _kindSwitcherGap
        : 0.0;
    final totalHeight = math.max(
      navLayerHeight,
      navHeight + switcherExtraHeight,
    );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      height: totalHeight,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          // Toàn bộ thanh điều hướng chính nằm trong vùng hit-test hợp lệ.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: navLayerHeight,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.topCenter,
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: navHeight,
                  child: CustomPaint(
                    painter: const _CurvedBottomBarPainter(),
                  ),
                ),
                Positioned(
                  left: 4,
                  right: 4,
                  top: _centerButtonLift + 2,
                  bottom: math.max(18.0, bottomInset + 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: _BottomBarItem(
                          icon: Icons.home_outlined,
                          selectedIcon: Icons.home_rounded,
                          label: context.tr('Trang chủ'),
                          isSelected: selectedIndex == 0,
                          activeColor: _activeColor,
                          inactiveColor: _inactiveColor,
                          onTap: onHome,
                        ),
                      ),
                      Expanded(
                        child: _BottomBarItem(
                          label: context.tr('Yêu thích'),
                          isSelected: selectedIndex == 1,
                          activeColor: _activeColor,
                          inactiveColor: _inactiveColor,
                          onTap: onFavorites,
                          iconBuilder: (color) => CountBadge(
                            count: favoriteCount,
                            child: Icon(
                              Icons.favorite_border_rounded,
                              color: color,
                              size: 24,
                            ),
                          ),
                          selectedIconBuilder: (color) => CountBadge(
                            count: favoriteCount,
                            child: Icon(
                              Icons.favorite_rounded,
                              color: color,
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 82),
                      Expanded(
                        child: _BottomBarItem(
                          icon: Icons.add_business_outlined,
                          selectedIcon: Icons.add_business_rounded,
                          label: context.tr('Đăng tin'),
                          isSelected: selectedIndex == 2,
                          activeColor: _activeColor,
                          inactiveColor: _inactiveColor,
                          onTap: onPost,
                        ),
                      ),
                      Expanded(
                        child: _BottomBarItem(
                          label: context.tr('Tài khoản'),
                          isSelected: selectedIndex == 3,
                          activeColor: _activeColor,
                          inactiveColor: _inactiveColor,
                          onTap: onAccount,
                          iconBuilder: (color) => isLoggedIn
                              ? _BottomNavAccountIcon(
                                  store: store,
                                  selected: false,
                                  tintColor: color,
                                )
                              : Icon(
                                  Icons.person_outline_rounded,
                                  color: color,
                                  size: 24,
                                ),
                          selectedIconBuilder: (color) => isLoggedIn
                              ? _BottomNavAccountIcon(
                                  store: store,
                                  selected: true,
                                  tintColor: color,
                                )
                              : Icon(
                                  Icons.person_rounded,
                                  color: color,
                                  size: 24,
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 0,
                  child: _FindHomeCenterButton(
                    onTap: onFindHome,
                    isSelected: selectedIndex == 4,
                    activeColor: _activeColor,
                    inactiveColor: _inactiveColor,
                  ),
                ),
              ],
            ),
          ),

          // Switch giờ nằm hoàn toàn bên trong chiều cao của bottomNavigationBar,
          // vì vậy InkWell nhận được sự kiện chạm bình thường.
          Positioned(
            left: 12,
            right: 12,
            bottom: navHeight + _kindSwitcherGap,
            height: _kindSwitcherHeight,
            child: IgnorePointer(
              ignoring: !showKindSwitcher,
              child: AnimatedSlide(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                offset: showKindSwitcher
                    ? Offset.zero
                    : const Offset(0, 0.78),
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 170),
                  opacity: showKindSwitcher ? 1 : 0,
                  child: _HomeKindSwitcher(
                    selectedKind: selectedKind,
                    onSelected: onKindSelected,
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

class _CurvedBottomBarPainter extends CustomPainter {
  const _CurvedBottomBarPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const dipDepth = _NhaWowBottomBar._topNotchDepth;
    final center = size.width / 2;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(center - 78, 0)
      ..cubicTo(
        center - 56,
        0,
        center - 54,
        dipDepth,
        center - 28,
        dipDepth,
      )
      ..cubicTo(
        center - 12,
        dipDepth,
        center + 12,
        dipDepth,
        center + 28,
        dipDepth,
      )
      ..cubicTo(
        center + 54,
        dipDepth,
        center + 56,
        0,
        center + 78,
        0,
      )
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawShadow(path, const Color(0x26082457), 14, false);

    final fillPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.white;
    canvas.drawPath(path, fillPaint);

    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = const Color(0xFFE2E8F0);
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _BottomBarItem extends StatelessWidget {
  const _BottomBarItem({
    required this.label,
    required this.isSelected,
    required this.activeColor,
    required this.inactiveColor,
    required this.onTap,
    this.icon,
    this.selectedIcon,
    this.iconBuilder,
    this.selectedIconBuilder,
  });

  final String label;
  final bool isSelected;
  final Color activeColor;
  final Color inactiveColor;
  final VoidCallback onTap;
  final IconData? icon;
  final IconData? selectedIcon;
  final Widget Function(Color color)? iconBuilder;
  final Widget Function(Color color)? selectedIconBuilder;

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? activeColor : inactiveColor;
    final iconWidget = isSelected
        ? (selectedIconBuilder?.call(color) ??
            Icon(selectedIcon ?? icon, color: color, size: 24))
        : (iconBuilder?.call(color) ?? Icon(icon, color: color, size: 24));

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 24, child: Center(child: iconWidget)),
              const SizedBox(height: 5),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontSize: 11.2,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FindHomeCenterButton extends StatelessWidget {
  const _FindHomeCenterButton({
    required this.onTap,
    required this.isSelected,
    required this.activeColor,
    required this.inactiveColor,
  });

  final VoidCallback onTap;
  final bool isSelected;
  final Color activeColor;
  final Color inactiveColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 92,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _FindHomeDiamondButton(
                activeColor: activeColor,
                isSelected: isSelected,
              ),
              // Hạ nhãn xuống để thẳng hàng với nhãn của 4 mục bên cạnh.
              const SizedBox(height: 18),
              Text(
                context.tr('Tìm nhà'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isSelected ? activeColor : inactiveColor,
                  fontSize: 11.6,
                  height: 1,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FindHomeDiamondButton extends StatelessWidget {
  const _FindHomeDiamondButton({
    required this.activeColor,
    required this.isSelected,
  });

  final Color activeColor;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: math.pi / 4,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              activeColor,
              const Color(0xFF0550CF),
            ],
          ),
          border: Border.all(
            color: isSelected ? Colors.white : const Color(0x99FFFFFF),
            width: isSelected ? 2.2 : 1.2,
          ),
          borderRadius: BorderRadius.circular(10),
          boxShadow: const [
            BoxShadow(
              color: Color(0x25004AAF),
              blurRadius: 10,
              offset: Offset(0, 7),
            ),
          ],
        ),
        child: Transform.rotate(
          angle: -math.pi / 4,
          child: const Center(
            child: Icon(
              Icons.home_work_rounded,
              size: 18,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeKindSwitcher extends StatelessWidget {
  const _HomeKindSwitcher({
    required this.selectedKind,
    required this.onSelected,
  });

  final ListingKind selectedKind;
  final ValueChanged<ListingKind> onSelected;

  static const List<_HomeKindSwitchItem> _items = [
    _HomeKindSwitchItem(
      kind: ListingKind.houseSale,
      label: 'Bán nhà',
      icon: Icons.real_estate_agent_outlined,
    ),
    _HomeKindSwitchItem(
      kind: ListingKind.houseRent,
      label: 'Thuê nhà',
      icon: Icons.house_outlined,
    ),
    _HomeKindSwitchItem(
      kind: ListingKind.landSale,
      label: 'Đất bán',
      icon: Icons.location_on_outlined,
    ),
    _HomeKindSwitchItem(
      kind: ListingKind.premises,
      label: 'Mặt bằng',
      icon: Icons.storefront_outlined,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 470),
        child: Material(
          color: Colors.white,
          elevation: 8,
          shadowColor: const Color(0x20082457),
          borderRadius: BorderRadius.circular(18),
          child: Container(
            height: 46,
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFDDE4EE)),
            ),
            child: Row(
              children: _items.map((item) {
                final selected = item.kind == selectedKind;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: _HomeKindSwitchTile(
                      item: item,
                      selected: selected,
                      onTap: () => onSelected(item.kind),
                    ),
                  ),
                );
              }).toList(growable: false),
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeKindSwitchTile extends StatelessWidget {
  const _HomeKindSwitchTile({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final _HomeKindSwitchItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? Colors.white : _NhaWowBottomBar._navy;

    return Material(
      color: selected ? _NhaWowBottomBar._navy : Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 5),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(item.icon, size: 15.5, color: foreground),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  context.tr(item.label),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: foreground,
                    fontSize: 10.4,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
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

class _HomeKindSwitchItem {
  const _HomeKindSwitchItem({
    required this.kind,
    required this.label,
    required this.icon,
  });

  final ListingKind kind;
  final String label;
  final IconData icon;
}

class _BottomNavAccountIcon extends StatelessWidget {
  const _BottomNavAccountIcon({
    required this.store,
    this.selected = false,
    required this.tintColor,
  });

  final AppStore store;
  final bool selected;
  final Color tintColor;

  @override
  Widget build(BuildContext context) {
    Widget avatar;
    if (store.currentUser.avatarUrl.trim().isNotEmpty) {
      avatar = AppAvatar(
        url: store.currentUser.avatarUrl,
        fallbackText: store.currentUser.name,
        radius: 12,
      );
    } else {
      avatar = ClipOval(
        child: Image.asset(
          AppAssets.agentHero,
          width: 24,
          height: 24,
          fit: BoxFit.cover,
        ),
      );
    }

    if (!selected) return avatar;
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        border: Border.all(color: tintColor, width: 2),
        shape: BoxShape.circle,
      ),
      child: avatar,
    );
  }
}
