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
          isOwnProfile: store.isLoggedIn && store.currentUser.id == widget.agent.id,
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
      final modeMatches = _mode == 'rent' ? item.kind.isRent : !item.kind.isRent;
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
    // Với newest, giữ nguyên thứ tự do Mobile API/web trả về để không làm mất
    // ưu tiên tin nổi bật, hạng hội viên và thời gian làm mới.
    return source;
  }

  @override
  Widget build(BuildContext context) {
    final profile = _effectiveProfile;
    final filteredProperties = _filteredProperties;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('Hồ sơ người đăng')),
        actions: [
          IconButton(
            tooltip: context.tr('Chia sẻ'),
            onPressed: () => _copyProfileLink(profile.agent),
            icon: const Icon(Icons.ios_share_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadProfile(showLoading: false),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 34),
          children: [
            _AgentProfileHero(
              profile: profile,
              isLoading: _isLoading,
              onChat: () => _openChat(profile.agent),
              onPhone: () => _callAgent(profile.agent),
              onViewListings: _scrollToListings,
              onCopy: () => _copyProfileLink(profile.agent),
              onFacebook: () => _shareProfile(profile.agent, 'facebook'),
              onZalo: () => _shareProfile(profile.agent, 'zalo'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              _InlineError(
                message: _error!,
                onRetry: () => _loadProfile(),
              ),
            ],
            if (profile.agent.isBroker && profile.isOwnProfile) ...[
              const SizedBox(height: 10),
              AgentLevelRoadmap(
                agent: profile.agent,
                publishedListingCount: profile.totalPublishedListings,
              ),
            ],
            const SizedBox(height: 14),
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
                    builder: (_) => PropertyDetailPage(propertyId: property.id),
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
      final conversation = await AppScope.of(context).startAgentConversation(agent.id);
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
      if (mounted) _showMessage(context.tr('Số điện thoại đang được cập nhật.'));
      return;
    }

    final uri = Uri(scheme: 'tel', path: phone.replaceAll(RegExp(r'[^0-9+]'), ''));
    try {
      final opened = await launchUrl(uri);
      if (!opened && mounted) {
        _showMessage(context.tr('Không thể thực hiện cuộc gọi.'));
      }
    } catch (_) {
      if (mounted) _showMessage(context.tr('Không thể thực hiện cuộc gọi.'));
    }
  }

  void _scrollToListings() {
    final targetContext = _listingSectionKey.currentContext;
    if (targetContext == null) return;
    Scrollable.ensureVisible(
      targetContext,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
      alignment: 0.04,
    );
  }

  String _profileLink(AgentModel agent) =>
      '${AppConfig.webBaseUrl}/Agent/Index?id=${agent.id}';

  Future<void> _copyProfileLink(AgentModel agent) async {
    await Clipboard.setData(ClipboardData(text: _profileLink(agent)));
    if (mounted) _showMessage(context.tr('Đã sao chép liên kết hồ sơ'));
  }

  Future<void> _shareProfile(AgentModel agent, String channel) async {
    final link = _profileLink(agent);
    final uri = channel == 'facebook'
        ? Uri.https('www.facebook.com', '/sharer/sharer.php', {'u': link})
        : Uri.https('zalo.me', '/share', {'u': link});
    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened && mounted) await _copyProfileLink(agent);
    } catch (_) {
      if (mounted) await _copyProfileLink(agent);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  String _cleanError(Object error) {
    if (error is ApiTransportException) return context.tr(error.message);
    return context.tr(error.toString().replaceFirst('Exception: ', ''));
  }
}

class _AgentProfileHero extends StatelessWidget {
  const _AgentProfileHero({
    required this.profile,
    required this.isLoading,
    required this.onChat,
    required this.onPhone,
    required this.onViewListings,
    required this.onCopy,
    required this.onFacebook,
    required this.onZalo,
  });

  final AgentProfileModel profile;
  final bool isLoading;
  final VoidCallback onChat;
  final VoidCallback onPhone;
  final VoidCallback onViewListings;
  final VoidCallback onCopy;
  final VoidCallback onFacebook;
  final VoidCallback onZalo;

  @override
  Widget build(BuildContext context) {
    final agent = profile.agent;
    final city = profile.mainCity.trim().isEmpty
        ? context.tr('Đang cập nhật')
        : profile.mainCity.trim();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xFFE4EAF1)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x180F2942),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Stack(
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 390;
                  return IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          flex: compact ? 58 : 61,
                          child: _AgentHeroIdentity(
                            agent: agent,
                            city: city,
                            listingCount: profile.totalPublishedListings,
                            onChat: onChat,
                            onPhone: onPhone,
                            onViewListings: onViewListings,
                            compact: compact,
                          ),
                        ),
                        Expanded(
                          flex: compact ? 42 : 39,
                          child: _AgentHeroStats(
                            profile: profile,
                            onCopy: onCopy,
                            onFacebook: onFacebook,
                            onZalo: onZalo,
                            compact: compact,
                          ),
                        ),
                      ],
                    ),
                  );
                },
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
          const Divider(height: 1, color: Color(0xFFE7ECF2)),
          _AgentTrustStrip(city: city),
        ],
      ),
    );
  }
}

class _AgentHeroIdentity extends StatelessWidget {
  const _AgentHeroIdentity({
    required this.agent,
    required this.city,
    required this.listingCount,
    required this.onChat,
    required this.onPhone,
    required this.onViewListings,
    required this.compact,
  });

  final AgentModel agent;
  final String city;
  final int listingCount;
  final VoidCallback onChat;
  final VoidCallback onPhone;
  final VoidCallback onViewListings;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(compact ? 7 : 9, 10, compact ? 5 : 7, 9),
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage(AppAssets.agentHero),
          fit: BoxFit.cover,
          alignment: Alignment.center,
          opacity: 0.16,
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Color(0xF7FFFFFF), Color(0xEFFFFFFF)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AgentMembershipAvatar(agent: agent, radius: compact ? 21 : 24),
              SizedBox(width: compact ? 6 : 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      agent.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: const Color(0xFF151A21),
                        fontSize: compact ? 13 : 15,
                        height: 1,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF4DD),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: const Color(0xFFFFC66B)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.verified_user_outlined, size: 9, color: Color(0xFFD97706)),
                          const SizedBox(width: 3),
                          Flexible(
                            child: Text(
                              context.tr('Hồ sơ công khai'),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFFB45309),
                                fontSize: 7.5,
                                height: 1,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          AgentLevelBadge(
            agent: agent,
            compact: true,
            showLevelNumber: true,
            maxWidth: compact ? 145 : 165,
          ),
          const SizedBox(height: 7),
          _TinyMeta(icon: Icons.location_on_rounded, text: city),
          const SizedBox(height: 4),
          _TinyMeta(
            icon: Icons.badge_outlined,
            text: context.tr('Người đăng tin trên NhaWow'),
          ),
          const SizedBox(height: 8),
          Text(
            context.tr(
              'Chuyên đăng tin và tư vấn bất động sản tại {city}',
              {'city': city},
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF334D68),
              fontSize: 8.8,
              height: 1.32,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 7),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: [
              _AgentTag(icon: Icons.home_work_outlined, label: context.tr('Tin nhà đất')),
              _AgentTag(icon: Icons.forum_outlined, label: context.tr('Tư vấn trực tiếp')),
              _AgentTag(icon: Icons.public_rounded, label: city),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _HeroAction(
                  icon: Icons.chat_bubble_outline_rounded,
                  title: context.tr('Nhắn tin'),
                  subtitle: context.tr('Tư vấn trực tuyến'),
                  color: const Color(0xFF087CF0),
                  onTap: onChat,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: _HeroAction(
                  icon: Icons.phone_rounded,
                  title: agent.phone.trim().isEmpty ? context.tr('Gọi điện') : agent.phone,
                  subtitle: context.tr('Gọi điện trực tiếp'),
                  color: const Color(0xFF16A34A),
                  onTap: onPhone,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: _HeroAction(
                  icon: Icons.home_work_rounded,
                  title: context.tr('Xem tất cả'),
                  subtitle: context.tr(
                    '{count} tin đang có',
                    {'count': listingCount},
                  ),
                  color: const Color(0xFF168AE6),
                  onTap: onViewListings,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AgentHeroStats extends StatelessWidget {
  const _AgentHeroStats({
    required this.profile,
    required this.onCopy,
    required this.onFacebook,
    required this.onZalo,
    required this.compact,
  });

  final AgentProfileModel profile;
  final VoidCallback onCopy;
  final VoidCallback onFacebook;
  final VoidCallback onZalo;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final agent = profile.agent;
    return Container(
      margin: const EdgeInsets.fromLTRB(0, 8, 7, 8),
      padding: EdgeInsets.all(compact ? 5 : 7),
      decoration: BoxDecoration(
        color: const Color(0xF5FFFFFF),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xFFDCE5EF)),
        boxShadow: const [
          BoxShadow(color: Color(0x110F2942), blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          _StatTile(
            icon: Icons.home_work_rounded,
            iconColor: const Color(0xFF2D7EF7),
            iconBackground: const Color(0xFFEAF3FF),
            value: '${profile.totalPublishedListings}',
            title: context.tr('Số tin đăng'),
            subtitle: context.tr('Tin đã đăng thật'),
          ),
          const SizedBox(height: 5),
          _StatTile(
            icon: Icons.visibility_rounded,
            iconColor: const Color(0xFF17A34A),
            iconBackground: const Color(0xFFE7FBEF),
            value: _formatCompactNumber(profile.totalViewCount),
            title: context.tr('Tổng lượt xem'),
            subtitle: context.tr('Tất cả tin đăng'),
          ),
          const SizedBox(height: 5),
          _StatTile(
            icon: Icons.workspace_premium_rounded,
            iconColor: const Color(0xFFF59E0B),
            iconBackground: const Color(0xFFFFF5DD),
            value: agent.isBroker ? agent.levelTitle : '—',
            title: context.tr('Cấp hồ sơ'),
            subtitle: agent.cleanLevelName,
          ),
          const SizedBox(height: 5),
          _StatTile(
            icon: Icons.location_city_rounded,
            iconColor: const Color(0xFF7C3AED),
            iconBackground: const Color(0xFFF0EAFE),
            value: profile.mainCity.isEmpty ? '—' : profile.mainCity,
            title: context.tr('Khu vực chính'),
            subtitle: context.tr('Thị trường đang hoạt động'),
            valueMaxLines: 1,
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(
                  context.tr('Chia sẻ hồ sơ:'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF52677D),
                    fontSize: 7.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              _ShareCircle(label: 'f', onTap: onFacebook, background: const Color(0xFF1877F2)),
              const SizedBox(width: 4),
              _ShareCircle(label: 'Za', onTap: onZalo, background: const Color(0xFF168AE6)),
              const SizedBox(width: 4),
              _ShareCircle(icon: Icons.link_rounded, onTap: onCopy, background: const Color(0xFF94A3B8)),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.value,
    required this.title,
    required this.subtitle,
    this.valueMaxLines = 1,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String value;
  final String title;
  final String subtitle;
  final int valueMaxLines;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: iconBackground, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 13),
          ),
          const SizedBox(width: 5),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: valueMaxLines,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF172033),
                    fontSize: 11,
                    height: 1,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF263B53),
                    fontSize: 7,
                    height: 1,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF75869A),
                    fontSize: 6.3,
                    height: 1,
                    fontWeight: FontWeight.w600,
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

class _TinyMeta extends StatelessWidget {
  const _TinyMeta({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 9.5, color: const Color(0xFF168AE6)),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF314860),
              fontSize: 8,
              height: 1,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _AgentTag extends StatelessWidget {
  const _AgentTag({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 92),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFDCE7F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 8, color: const Color(0xFF19A64A)),
          const SizedBox(width: 3),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF38516A),
                fontSize: 7,
                height: 1,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroAction extends StatelessWidget {
  const _HeroAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(6),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 32,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 10, color: Colors.white),
                const SizedBox(width: 3),
                Flexible(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 7.3,
                          height: 1,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xE6FFFFFF),
                          fontSize: 5.7,
                          height: 1,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
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

class _ShareCircle extends StatelessWidget {
  const _ShareCircle({
    this.label,
    this.icon,
    required this.onTap,
    required this.background,
  });

  final String? label;
  final IconData? icon;
  final VoidCallback onTap;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        width: 22,
        height: 22,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: background, shape: BoxShape.circle),
        child: icon != null
            ? Icon(icon, size: 13, color: Colors.white)
            : Text(
                label ?? '',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 8,
                  height: 1,
                  fontWeight: FontWeight.w900,
                ),
              ),
      ),
    );
  }
}

class _AgentTrustStrip extends StatelessWidget {
  const _AgentTrustStrip({required this.city});

  final String city;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: _TrustItem(
              icon: Icons.shield_outlined,
              title: context.tr('Hồ sơ công khai'),
              subtitle: context.tr('Thông tin người đăng'),
              background: const Color(0xFFEAF3FF),
              foreground: const Color(0xFF277CF3),
            ),
          ),
          Expanded(
            child: _TrustItem(
              icon: Icons.person_pin_circle_outlined,
              title: context.tr('Liên hệ trực tiếp'),
              subtitle: context.tr('Nhắn tin hoặc gọi điện'),
              background: const Color(0xFFE8FAEF),
              foreground: const Color(0xFF16A34A),
            ),
          ),
          Expanded(
            child: _TrustItem(
              icon: Icons.workspace_premium_outlined,
              title: context.tr('Cấp bậc rõ ràng'),
              subtitle: context.tr('Uy tín môi giới'),
              background: const Color(0xFFFFF4DF),
              foreground: const Color(0xFFE49A0C),
            ),
          ),
          Expanded(
            child: _TrustItem(
              icon: Icons.layers_outlined,
              title: context.tr('Tin đăng tập trung'),
              subtitle: city,
              background: const Color(0xFFF0EAFE),
              foreground: const Color(0xFF7C3AED),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrustItem extends StatelessWidget {
  const _TrustItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.background,
    required this.foreground,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 25,
            height: 25,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: background, shape: BoxShape.circle),
            child: Icon(icon, size: 13, color: foreground),
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF263B53),
                    fontSize: 7.3,
                    height: 1,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF738397),
                    fontSize: 5.8,
                    height: 1,
                    fontWeight: FontWeight.w600,
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
      padding: const EdgeInsets.fromLTRB(9, 8, 9, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFE4EAF1)),
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
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: SegmentedButton<String>(
                  showSelectedIcon: false,
                  segments: [
                    ButtonSegment<String>(
                      value: 'sale',
                      label: Text(
                        context.tr(assetCategory == 'house' ? 'Mua nhà' : 'Đất bán'),
                      ),
                    ),
                    ButtonSegment<String>(
                      value: 'rent',
                      label: Text(
                        context.tr(assetCategory == 'house' ? 'Thuê nhà' : 'Mặt bằng'),
                      ),
                    ),
                  ],
                  selected: {mode},
                  onSelectionChanged: (values) => onModeChanged(values.first),
                  style: const ButtonStyle(
                    visualDensity: VisualDensity(horizontal: -3, vertical: -3),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: sortBy,
                  isDense: true,
                  borderRadius: BorderRadius.circular(12),
                  items: [
                    DropdownMenuItem(value: 'newest', child: Text(context.tr('Mới nhất'))),
                    DropdownMenuItem(value: 'oldest', child: Text(context.tr('Cũ nhất'))),
                    DropdownMenuItem(value: 'price_asc', child: Text(context.tr('Giá tăng dần'))),
                    DropdownMenuItem(value: 'price_desc', child: Text(context.tr('Giá giảm dần'))),
                  ],
                  onChanged: (value) {
                    if (value != null) onSortChanged(value);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: keywordController,
            onChanged: onKeywordChanged,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              isDense: true,
              prefixIcon: const Icon(Icons.search_rounded, size: 19),
              suffixIcon: keywordController.text.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () {
                        keywordController.clear();
                        onKeywordChanged('');
                      },
                      icon: const Icon(Icons.close_rounded, size: 18),
                    ),
              hintText: context.tr('Tìm trong tin đăng của người này...'),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            ),
          ),
          const SizedBox(height: 7),
          Row(
            children: [
              Text(
                context.tr('Bất động sản đang hiển thị'),
                style: const TextStyle(
                  color: AppTheme.navy,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              Text(
                context.tr('{count} tin đăng', {'count': resultCount}),
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 11,
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
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: selected ? AppTheme.primaryDark : Colors.transparent,
              width: 2.5,
            ),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: selected ? AppTheme.navy : const Color(0xFF64748B),
            fontSize: 13,
            fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
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
      padding: const EdgeInsets.fromLTRB(11, 8, 8, 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFCBC6)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppTheme.danger, size: 18),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Color(0xFF8B2E26), fontSize: 11),
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
