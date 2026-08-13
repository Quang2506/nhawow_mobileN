import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app/app_store.dart';
import '../config/app_config.dart';
import '../core/agent_level_ui.dart';
import '../core/app_assets.dart';
import '../core/app_theme.dart';
import '../core/auth_gate.dart';
import '../core/widgets.dart';
import '../data/remote/api_transport.dart';
import '../l10n/app_localizations.dart';
import '../models/models.dart';
import 'chat_thread_page.dart';
import 'property_detail_page.dart';

class AgentProfilePage extends StatefulWidget {
  const AgentProfilePage({required this.agent, super.key});

  final AgentModel agent;

  @override
  State<AgentProfilePage> createState() => _AgentProfilePageState();
}

class _AgentProfilePageState extends State<AgentProfilePage> {
  final GlobalKey _listingSectionKey = GlobalKey();
  final TextEditingController _keywordController = TextEditingController();

  AgentProfileModel? _profile;
  bool _requested = false;
  bool _isLoading = false;
  String? _error;
  String _assetCategory = 'house';
  String _mode = 'sale';
  String _sortBy = 'newest';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_requested) return;
    _requested = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadProfile());
  }

  @override
  void dispose() {
    _keywordController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile({bool showLoading = true}) async {
    if (!mounted) return;
    if (showLoading) setState(() => _isLoading = true);
    try {
      final result = await AppScope.of(context).loadAgentProfile(
        widget.agent.id,
        fallbackAgent: widget.agent,
      );
      if (!mounted) return;
      setState(() {
        _profile = result;
        _error = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = _cleanError(error));
    } finally {
      if (mounted && showLoading) setState(() => _isLoading = false);
    }
  }

  AgentProfileModel get _effectiveProfile {
    final store = AppScope.of(context);
    final localItems = store.properties
        .where((item) => item.owner.id == widget.agent.id)
        .toList(growable: false);
    return _profile ??
        AgentProfileModel(
          agent: widget.agent,
          totalPublishedListings: widget.agent.verifiedListingCount > 0
              ? widget.agent.verifiedListingCount
              : localItems.length,
          totalViewCount: localItems.fold<int>(
            0,
            (sum, item) => sum + item.viewCount,
          ),
          mainCity: localItems
              .map((item) => item.city.trim())
              .firstWhere(
                (item) => item.isNotEmpty,
                orElse: () => context.tr('Đang cập nhật'),
              ),
          isOwnProfile:
              store.isLoggedIn && store.currentUser.id == widget.agent.id,
          properties: localItems,
          totalItems: localItems.length,
        );
  }

  List<PropertyModel> get _filteredProperties {
    final keyword = _keywordController.text.trim().toLowerCase();
    final source = _effectiveProfile.properties.where((item) {
      final categoryMatches = _assetCategory == 'land'
          ? item.kind.isLand
          : !item.kind.isLand;
      final modeMatches =
          _mode == 'rent' ? item.kind.isRent : !item.kind.isRent;
      if (!categoryMatches || !modeMatches) return false;
      if (keyword.isEmpty) return true;
      return '${item.title} ${item.address} ${item.city} ${item.ward}'
          .toLowerCase()
          .contains(keyword);
    }).toList(growable: true);

    if (_sortBy == 'oldest') {
      source.sort((a, b) => a.id.compareTo(b.id));
    } else if (_sortBy == 'price_asc') {
      source.sort((a, b) => a.price.compareTo(b.price));
    } else if (_sortBy == 'price_desc') {
      source.sort((a, b) => b.price.compareTo(a.price));
    }
    // newest giữ thứ tự API để bảo toàn logic ưu tiên tin nổi bật/hội viên.
    return source;
  }

  @override
  Widget build(BuildContext context) {
    final profile = _effectiveProfile;
    final filteredProperties = _filteredProperties;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: Text(
          context.tr('Hồ sơ người đăng'),
          style: const TextStyle(
            color: AppTheme.navy,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            tooltip: context.tr('Chia sẻ'),
            onPressed: () => _copyProfileLink(profile.agent),
            icon: const Icon(Icons.ios_share_rounded, size: 22),
          ),
          const SizedBox(width: 4),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFE9EDF3)),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadProfile(showLoading: false),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 36),
          children: [
            _AgentProfileCard(
              profile: profile,
              isLoading: _isLoading,
              onChat: profile.isOwnProfile
                  ? () => _showMessage(context.tr('Đây là hồ sơ công khai của bạn.'))
                  : () => _openChat(profile.agent),
              onPhone: profile.isOwnProfile
                  ? () => _showMessage(context.tr('Đây là hồ sơ công khai của bạn.'))
                  : () => _callAgent(profile.agent),
              onViewListings: _scrollToListings,
            ),
            // Giữ nguyên logic cấp bậc môi giới cũ. Chỉ giao diện hồ sơ phía trên
            // và bộ lọc/tìm kiếm bên dưới được thiết kế lại theo mẫu mới.
            if (profile.agent.isBroker && profile.isOwnProfile) ...[
              const SizedBox(height: 10),
              AgentLevelRoadmap(
                agent: profile.agent,
                publishedListingCount: profile.totalPublishedListings,
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 10),
              _InlineError(
                message: _error!,
                onRetry: () => _loadProfile(),
              ),
            ],
            const SizedBox(height: 12),
            Container(
              key: _listingSectionKey,
              child: _AgentListingFilters(
                assetCategory: _assetCategory,
                mode: _mode,
                sortBy: _sortBy,
                keywordController: _keywordController,
                resultCount: filteredProperties.length,
                onAssetCategoryChanged: (value) {
                  setState(() => _assetCategory = value);
                },
                onModeChanged: (value) => setState(() => _mode = value),
                onSortChanged: (value) => setState(() => _sortBy = value),
                onKeywordChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(height: 10),
            PropertyGrid(
              properties: filteredProperties,
              onPropertyTap: (property) {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        PropertyDetailPage(propertyId: property.id),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openChat(AgentModel agent) async {
    final loggedIn = await AuthGate.ensureLoggedIn(context);
    if (!loggedIn || !mounted) return;
    try {
      final conversation =
          await AppScope.of(context).startAgentConversation(agent.id);
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ChatThreadPage(conversationId: conversation.id),
        ),
      );
    } catch (error) {
      if (mounted) _showMessage(_cleanError(error));
    }
  }

  Future<void> _callAgent(AgentModel agent) async {
    final loggedIn = await AuthGate.ensureLoggedIn(context);
    if (!loggedIn || !mounted) return;

    AgentModel refreshedAgent = agent;
    try {
      final profile = await AppScope.of(context).loadAgentProfile(
        agent.id,
        fallbackAgent: agent,
      );
      refreshedAgent = profile.agent;
      if (mounted) setState(() => _profile = profile);
    } catch (_) {
      // Dùng dữ liệu đang có nếu làm mới hồ sơ thất bại.
    }

    final phone = refreshedAgent.phone.trim();
    if (phone.isEmpty || phone.toLowerCase().contains('x')) {
      if (mounted) {
        _showMessage(context.tr('Số điện thoại đang được cập nhật.'));
      }
      return;
    }

    final uri = Uri(
      scheme: 'tel',
      path: phone.replaceAll(RegExp(r'[^0-9+]'), ''),
    );
    try {
      final opened = await launchUrl(uri);
      if (!opened && mounted) {
        _showMessage(context.tr('Không thể thực hiện cuộc gọi.'));
      }
    } catch (_) {
      if (mounted) {
        _showMessage(context.tr('Không thể thực hiện cuộc gọi.'));
      }
    }
  }

  void _scrollToListings() {
    final targetContext = _listingSectionKey.currentContext;
    if (targetContext == null) return;
    Scrollable.ensureVisible(
      targetContext,
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
      alignment: 0.02,
    );
  }

  String _profileLink(AgentModel agent) =>
      '${AppConfig.webBaseUrl}/Agent/Index?id=${agent.id}';

  Future<void> _copyProfileLink(AgentModel agent) async {
    await Clipboard.setData(ClipboardData(text: _profileLink(agent)));
    if (mounted) {
      _showMessage(context.tr('Đã sao chép liên kết hồ sơ'));
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.tr(message))),
    );
  }

  String _cleanError(Object error) {
    if (error is ApiTransportException) return context.tr(error.message);
    return context.tr(error.toString().replaceFirst('Exception: ', ''));
  }
}

class _AgentProfileCard extends StatelessWidget {
  const _AgentProfileCard({
    required this.profile,
    required this.isLoading,
    required this.onChat,
    required this.onPhone,
    required this.onViewListings,
  });

  final AgentProfileModel profile;
  final bool isLoading;
  final VoidCallback onChat;
  final VoidCallback onPhone;
  final VoidCallback onViewListings;

  @override
  Widget build(BuildContext context) {
    final agent = profile.agent;
    final city = profile.mainCity.trim().isEmpty
        ? context.tr('Đang cập nhật')
        : profile.mainCity.trim();
    final role = agent.isBroker
        ? context.tr('Môi giới')
        : context.tr(agent.roleLabel.isEmpty ? 'Người đăng tin' : agent.roleLabel);

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5EAF1)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x120F2942),
            blurRadius: 24,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.055,
                child: Image.asset(
                  AppAssets.agentHero,
                  fit: BoxFit.cover,
                  alignment: Alignment.centerRight,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AgentMembershipAvatar(agent: agent, radius: 29),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  agent.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppTheme.navy,
                                    fontSize: 18,
                                    height: 1.1,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 7),
                              const _PublicProfileBadge(),
                            ],
                          ),
                          const SizedBox(height: 6),
                          if (agent.isBroker)
                            AgentLevelBadge(
                              agent: agent,
                              compact: true,
                              showLevelNumber: true,
                              maxWidth: 190,
                            )
                          else
                            Text(
                              role,
                              style: const TextStyle(
                                color: Color(0xFF4D6480),
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          const SizedBox(height: 7),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on_outlined,
                                size: 15,
                                color: Color(0xFF64748B),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  city,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Color(0xFF475569),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  context.tr(
                    'Chuyên đăng tin và tư vấn bất động sản tại {city}.',
                    {'city': city},
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF40536A),
                    fontSize: 12,
                    height: 1.38,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 13),
                Container(
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Color(0xFFE9EDF3)),
                      bottom: BorderSide(color: Color(0xFFE9EDF3)),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: _ProfileStat(
                          icon: Icons.description_outlined,
                          iconColor: const Color(0xFF3987F5),
                          iconBackground: const Color(0xFFEDF5FF),
                          value: '${profile.totalPublishedListings}',
                          label: context.tr('tin đăng'),
                        ),
                      ),
                      const _StatDivider(),
                      Expanded(
                        child: _ProfileStat(
                          icon: Icons.visibility_outlined,
                          iconColor: const Color(0xFF18A768),
                          iconBackground: const Color(0xFFECFBF4),
                          value: _formatCompactNumber(profile.totalViewCount),
                          label: context.tr('lượt xem'),
                        ),
                      ),
                      const _StatDivider(),
                      Expanded(
                        child: _ProfileStat(
                          icon: Icons.workspace_premium_outlined,
                          iconColor: const Color(0xFFE2A20C),
                          iconBackground: const Color(0xFFFFF8E5),
                          value: agent.isBroker ? agent.levelTitle : '—',
                          label: context.tr('Cấp hồ sơ'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 42,
                        child: FilledButton.icon(
                          onPressed: onChat,
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF0D7BEF),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(9),
                            ),
                            textStyle: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          icon: const Icon(
                            Icons.chat_bubble_outline_rounded,
                            size: 17,
                          ),
                          label: Text(context.tr('Nhắn tin')),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SizedBox(
                        height: 42,
                        child: OutlinedButton.icon(
                          onPressed: onPhone,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF119F5C),
                            side: const BorderSide(
                              color: Color(0xFF39BE81),
                              width: 1.2,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(9),
                            ),
                            textStyle: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          icon: const Icon(Icons.phone_rounded, size: 17),
                          label: Text(context.tr('Gọi điện')),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 40,
                  child: OutlinedButton.icon(
                    onPressed: onViewListings,
                    style: OutlinedButton.styleFrom(
                      backgroundColor: const Color(0xFFF8FAFD),
                      foregroundColor: const Color(0xFF3677C9),
                      side: const BorderSide(color: Color(0xFFE3E9F1)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(9),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    icon: const Icon(Icons.home_work_outlined, size: 16),
                    label: Text(
                      context.tr(
                        'Xem {count} tin đăng',
                        {'count': profile.totalPublishedListings},
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (isLoading)
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(minHeight: 2),
            ),
        ],
      ),
    );
  }
}

class _PublicProfileBadge extends StatelessWidget {
  const _PublicProfileBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 105),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E8),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFFFE0A3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.verified_user_outlined,
            size: 11,
            color: Color(0xFFD89A16),
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              context.tr('Hồ sơ công khai'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFFB57A06),
                fontSize: 9.5,
                height: 1,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileStat extends StatelessWidget {
  const _ProfileStat({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 25,
          height: 25,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: iconBackground,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 14, color: iconColor),
        ),
        const SizedBox(height: 5),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppTheme.navy,
            fontSize: 15,
            height: 1,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF75859A),
            fontSize: 9.5,
            height: 1,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 54,
      color: const Color(0xFFE9EDF3),
    );
  }
}

class _AgentListingFilters extends StatelessWidget {
  const _AgentListingFilters({
    required this.assetCategory,
    required this.mode,
    required this.sortBy,
    required this.keywordController,
    required this.resultCount,
    required this.onAssetCategoryChanged,
    required this.onModeChanged,
    required this.onSortChanged,
    required this.onKeywordChanged,
  });

  final String assetCategory;
  final String mode;
  final String sortBy;
  final TextEditingController keywordController;
  final int resultCount;
  final ValueChanged<String> onAssetCategoryChanged;
  final ValueChanged<String> onModeChanged;
  final ValueChanged<String> onSortChanged;
  final ValueChanged<String> onKeywordChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE4E9F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C0F2942),
            blurRadius: 18,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _TopTab(
                  label: context.tr('Nhà'),
                  selected: assetCategory == 'house',
                  onTap: () => onAssetCategoryChanged('house'),
                ),
              ),
              Expanded(
                child: _TopTab(
                  label: context.tr('Đất & Mặt bằng'),
                  selected: assetCategory == 'land',
                  onTap: () => onAssetCategoryChanged('land'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _ModeSelector(
                  assetCategory: assetCategory,
                  mode: mode,
                  onChanged: onModeChanged,
                ),
              ),
              const SizedBox(width: 10),
              _SortMenu(
                value: sortBy,
                onChanged: onSortChanged,
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 40,
            child: TextField(
              controller: keywordController,
              onChanged: onKeywordChanged,
              textInputAction: TextInputAction.search,
              style: const TextStyle(fontSize: 12.5),
              decoration: InputDecoration(
                isDense: true,
                filled: true,
                fillColor: Colors.white,
                prefixIcon: const Icon(Icons.search_rounded, size: 19),
                suffixIcon: keywordController.text.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          keywordController.clear();
                          onKeywordChanged('');
                        },
                        icon: const Icon(Icons.close_rounded, size: 17),
                      ),
                hintText:
                    context.tr('Tìm trong tin đăng của người này...'),
                hintStyle: const TextStyle(
                  color: Color(0xFF9AA8B8),
                  fontSize: 11.5,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 9,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFE1E7EF)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFF77AEEE)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  context.tr('Bất động sản đang hiển thị'),
                  style: const TextStyle(
                    color: AppTheme.navy,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                context.tr('{count} tin đăng', {'count': resultCount}),
                style: const TextStyle(
                  color: Color(0xFF7C8B9D),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ModeSelector extends StatelessWidget {
  const _ModeSelector({
    required this.assetCategory,
    required this.mode,
    required this.onChanged,
  });

  final String assetCategory;
  final String mode;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final saleLabel = assetCategory == 'house' ? 'Mua nhà' : 'Đất bán';
    final rentLabel = assetCategory == 'house' ? 'Thuê nhà' : 'Mặt bằng';

    return Container(
      height: 34,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F6F9),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE7EBF1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ModeOption(
              label: context.tr(saleLabel),
              selected: mode == 'sale',
              onTap: () => onChanged('sale'),
            ),
          ),
          Expanded(
            child: _ModeOption(
              label: context.tr(rentLabel),
              selected: mode == 'rent',
              onTap: () => onChanged('rent'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeOption extends StatelessWidget {
  const _ModeOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 170),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF0B7EEA) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: selected ? Colors.white : const Color(0xFF69798D),
              fontSize: 10.5,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _SortMenu extends StatelessWidget {
  const _SortMenu({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    String labelFor(String raw) {
      switch (raw) {
        case 'oldest':
          return context.tr('Cũ nhất');
        case 'price_asc':
          return context.tr('Giá tăng dần');
        case 'price_desc':
          return context.tr('Giá giảm dần');
        case 'newest':
        default:
          return context.tr('Mới nhất');
      }
    }

    return PopupMenuButton<String>(
      initialValue: value,
      onSelected: onChanged,
      position: PopupMenuPosition.under,
      itemBuilder: (_) => [
        PopupMenuItem(value: 'newest', child: Text(context.tr('Mới nhất'))),
        PopupMenuItem(value: 'oldest', child: Text(context.tr('Cũ nhất'))),
        PopupMenuItem(
          value: 'price_asc',
          child: Text(context.tr('Giá tăng dần')),
        ),
        PopupMenuItem(
          value: 'price_desc',
          child: Text(context.tr('Giá giảm dần')),
        ),
      ],
      child: Container(
        height: 34,
        constraints: const BoxConstraints(minWidth: 104),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE1E7EF)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                labelFor(value),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF53657A),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 5),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 17,
              color: Color(0xFF64748B),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopTab extends StatelessWidget {
  const _TopTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: selected ? const Color(0xFF0B7EEA) : Colors.transparent,
              width: 2.4,
            ),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: selected ? AppTheme.navy : const Color(0xFF7B899A),
            fontSize: 12.5,
            fontWeight: selected ? FontWeight.w900 : FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4F4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFD2D2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: Color(0xFFC84545)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFF8F3131),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            child: Text(context.tr('Thử lại')),
          ),
        ],
      ),
    );
  }
}

String _formatCompactNumber(int value) {
  if (value >= 1000000) {
    final number = value / 1000000;
    return '${number.toStringAsFixed(number >= 10 ? 0 : 1)}M';
  }
  if (value >= 1000) {
    final number = value / 1000;
    return '${number.toStringAsFixed(number >= 10 ? 0 : 1)}K';
  }
  return '$value';
}
