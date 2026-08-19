import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/models.dart';
import 'app_image.dart';
import 'app_theme.dart';

class AgentLevelBadge extends StatefulWidget {
  const AgentLevelBadge({
    required this.agent,
    this.compact = false,
    this.showLevelNumber = false,
    this.maxWidth,
    super.key,
  });

  final AgentModel agent;
  final bool compact;
  final bool showLevelNumber;
  final double? maxWidth;

  @override
  State<AgentLevelBadge> createState() => _AgentLevelBadgeState();
}

class _AgentLevelBadgeState extends State<AgentLevelBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 5800),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = AgentLevelPalette.forAgent(widget.agent);
    final compact = widget.compact;
    final height = compact ? 24.0 : 31.0;
    final horizontalPadding = compact ? 10.0 : 12.0;
    final fontSize = compact ? 11.5 : 12.5;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final phase = _controller.value * math.pi * 2;
        final iconScale = 1 + (math.sin(phase * 2.64) * 0.055);
        final sweepX = -2.1 + (_controller.value * 4.2);

        return ConstrainedBox(
          constraints: BoxConstraints(maxWidth: widget.maxWidth ?? double.infinity),
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: palette.gradient,
              borderRadius: BorderRadius.circular(999),
              // Mobile web intentionally leaves the small badge borderless.
              // The gradient and soft shadow are the visual separator.
              border: null,
              boxShadow: palette.shadow,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: SizedBox(
                height: height,
                child: Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    Positioned.fill(
                      child: Align(
                        alignment: Alignment(sweepX, 0),
                        child: Transform.rotate(
                          angle: 0.42,
                          child: Container(
                            width: compact ? 13 : 18,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  palette.sweepColor,
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.agent.isBroker) ...[
                            Transform.scale(
                              scale: iconScale,
                              child: kIsWeb
                                  ? Icon(
                                      _webLevelIcon(widget.agent.normalizedLevel),
                                      size: compact ? 14 : 16,
                                      color: palette.foreground,
                                    )
                                  : Text(
                                      widget.agent.levelIcon,
                                      style: TextStyle(
                                        fontSize: compact ? 12.5 : 14,
                                        height: 1,
                                        shadows: const [
                                          Shadow(
                                            color: Color(0x260F172A),
                                            blurRadius: 5,
                                            offset: Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                    ),
                            ),
                            SizedBox(width: compact ? 5 : 7),
                          ],
                          if (widget.showLevelNumber && widget.agent.isBroker) ...[
                            Container(
                              height: compact ? 17 : 20,
                              padding: const EdgeInsets.symmetric(horizontal: 6),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.24),
                                borderRadius: BorderRadius.circular(999),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x1FFFFFFF),
                                    blurRadius: 0,
                                    offset: Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: Text(
                                widget.agent.levelTitle,
                                style: TextStyle(
                                  color: palette.foreground,
                                  fontSize: compact ? 9.5 : 10.5,
                                  height: 1,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            SizedBox(width: compact ? 5 : 7),
                          ],
                          Flexible(
                            child: Text(
                              context.tr(widget.agent.cleanLevelName),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: palette.foreground,
                                fontSize: fontSize,
                                height: 1,
                                fontWeight: FontWeight.w800,
                              ),
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
      },
    );
  }
}

IconData _webLevelIcon(int level) {
  switch (level) {
    case 1:
      return Icons.home_rounded;
    case 2:
      return Icons.star_rounded;
    case 3:
      return Icons.shield_rounded;
    case 4:
      return Icons.emoji_events_rounded;
    case 5:
      return Icons.diamond_rounded;
    case 6:
    default:
      return Icons.workspace_premium_rounded;
  }
}

class AgentMembershipAvatar extends StatelessWidget {
  const AgentMembershipAvatar({
    required this.agent,
    this.radius = 30,
    super.key,
  });

  final AgentModel agent;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final ring = _membershipRing(agent.membershipCode);
    return Container(
      width: (radius * 2) + 6,
      height: (radius * 2) + 6,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: ring,
        boxShadow: const [
          BoxShadow(
            color: Color(0x240F2942),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: AppAvatar(
            url: agent.avatarUrl,
            fallbackText: agent.name,
            radius: radius,
          ),
        ),
      ),
    );
  }

  LinearGradient _membershipRing(String rawCode) {
    final code = rawCode.trim().toUpperCase();
    if (code.contains('TOP') || code.contains('VIP')) {
      return const LinearGradient(
        colors: [Color(0xFF111827), Color(0xFFD4AF37), Color(0xFF111827)],
      );
    }
    if (code.contains('ADV') || code.contains('PRO')) {
      return const LinearGradient(
        colors: [Color(0xFF0099CC), Color(0xFFBEEFFF), Color(0xFF0099CC)],
      );
    }
    if (code.contains('BASIC')) {
      return const LinearGradient(
        colors: [Color(0xFF0F766E), Color(0xFF8EE3C8), Color(0xFF0F766E)],
      );
    }
    return const LinearGradient(
      colors: [Color(0xFFE2E8F0), Color(0xFF94A3B8), Color(0xFFE2E8F0)],
    );
  }
}

class AgentLevelRoadmap extends StatefulWidget {
  const AgentLevelRoadmap({
    required this.agent,
    required this.publishedListingCount,
    this.initiallyExpanded = false,
    super.key,
  });

  final AgentModel agent;
  final int publishedListingCount;
  final bool initiallyExpanded;

  @override
  State<AgentLevelRoadmap> createState() => _AgentLevelRoadmapState();
}

class _AgentLevelRoadmapState extends State<AgentLevelRoadmap> {
  late bool _expanded = widget.initiallyExpanded;

  static const List<int> _targets = <int>[0, 20, 50, 100, 200, 300];
  static const List<String> _names = <String>[
    'Môi giới thường',
    'Môi giới chất lượng',
    'Môi giới bạc',
    'Môi giới vàng',
    'Môi giới kim cương',
    'Chuyên gia môi giới',
  ];
  static const List<List<String>> _benefits = <List<String>>[
    <String>['Đăng tin nhà/phòng', 'Tạo trang cá nhân', 'Khách hàng tư vấn'],
    <String>['Ưu tiên hiển thị', 'Dấu hiệu xác thực', 'Tăng lưu lượng'],
    <String>['Tăng đề xuất', 'Trang cá nhân nâng cao', 'CSKH riêng'],
    <String>['Đề xuất trang chủ', 'Xác thực thương hiệu', 'Ưu tiên nhận khách'],
    <String>['Siêu hiển thị', 'Cộng trọng số lưu lượng', 'Hoạt động riêng'],
    <String>['Xác thực TOP', 'Hỗ trợ toàn sàn', 'Đề xuất chính thức'],
  ];

  @override
  Widget build(BuildContext context) {
    final currentLevel = widget.agent.normalizedLevel;
    final count = math.max(0, widget.publishedListingCount);
    final nextTarget = currentLevel >= 6 ? count : _targets[currentLevel];
    final previousTarget = _targets[currentLevel - 1];
    final progress = currentLevel >= 6
        ? 1.0
        : ((count - previousTarget) / math.max(1, nextTarget - previousTarget))
            .clamp(0.0, 1.0)
            .toDouble();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xFFE3E8EF)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x140F2942),
            blurRadius: 18,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 13, 12, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr('Quy trình cấp bậc NhaWow'),
                        style: const TextStyle(
                          color: AppTheme.navy,
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        context.tr(
                          'Cấp bậc càng cao thì nhà/phòng của môi giới càng được ưu tiên hiển thị trước.',
                        ),
                        style: const TextStyle(
                          color: Color(0xFF46617B),
                          fontSize: 11.5,
                          height: 1.32,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: const Color(0xFF102E50),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        context.tr('Mốc hiện tại'),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 9,
                          height: 1,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        currentLevel >= 6 ? '$count+' : '$count/$nextTarget',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          height: 1,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 11),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: SizedBox(
                height: 6,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFFE5E7EB),
                            Color(0xFF0F766E),
                            Color(0xFFC9D0DA),
                            Color(0xFFD4AF37),
                            Color(0xFF61D5FF),
                            Color(0xFF111111),
                          ],
                        ),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: 1 - progress,
                      alignment: Alignment.centerRight,
                      child: ColoredBox(
                        color: Colors.white.withValues(alpha: 0.78),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 7, 10, 8),
            child: Align(
              alignment: Alignment.centerRight,
              child: InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: () => setState(() => _expanded = !_expanded),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: const Color(0xFFDCE3EA)),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x100F2942),
                        blurRadius: 7,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        context.tr(_expanded ? 'Ẩn cấp bậc' : 'Xem cấp bậc'),
                        style: const TextStyle(
                          color: AppTheme.navy,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 4),
                      AnimatedRotation(
                        turns: _expanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 220),
                        child: const Icon(Icons.keyboard_arrow_down_rounded, size: 17),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: _expanded
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(9, 0, 9, 10),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final columns = constraints.maxWidth >= 365 ? 3 : 2;
                        return GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: 6,
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: columns,
                            crossAxisSpacing: 7,
                            mainAxisSpacing: 7,
                            mainAxisExtent: columns == 3 ? 164 : 153,
                          ),
                          itemBuilder: (context, index) => _AgentLevelStepCard(
                            level: index + 1,
                            name: context.tr(_names[index]),
                            rangeLabel: _rangeLabel(context, index),
                            benefits: _benefits[index]
                                .map((item) => context.tr(item))
                                .toList(growable: false),
                            isCurrent: index + 1 == currentLevel,
                          ),
                        );
                      },
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  String _rangeLabel(BuildContext context, int index) {
    if (index == 5) {
      return context.tr('{count}+ nhà/phòng thật', {'count': 300});
    }
    return context.tr(
      '{from}–{to} nhà/phòng thật',
      {
        'from': _targets[index],
        'to': _targets[index + 1] - 1,
      },
    );
  }
}

class _AgentLevelStepCard extends StatefulWidget {
  const _AgentLevelStepCard({
    required this.level,
    required this.name,
    required this.rangeLabel,
    required this.benefits,
    required this.isCurrent,
  });

  final int level;
  final String name;
  final String rangeLabel;
  final List<String> benefits;
  final bool isCurrent;

  @override
  State<_AgentLevelStepCard> createState() => _AgentLevelStepCardState();
}

class _AgentLevelStepCardState extends State<_AgentLevelStepCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 5200),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = AgentLevelPalette.forLevel(widget.level);
    const icons = <String>['🏠', '⭐', '🛡️', '🏆', '💎', '👑'];

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: widget.isCurrent
              ? 1 + (math.sin(_controller.value * math.pi * 2) * 0.008)
              : 1,
          child: Container(
            decoration: BoxDecoration(
              gradient: palette.gradient,
              borderRadius: BorderRadius.circular(11),
              border: Border.all(
                color: widget.isCurrent ? const Color(0xFFFFB11B) : palette.borderColor,
                width: widget.isCurrent ? 1.7 : 0.8,
              ),
              boxShadow: palette.shadow,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Align(
                      alignment: Alignment(-2.2 + (_controller.value * 4.4), 0),
                      child: Transform.rotate(
                        angle: 0.42,
                        child: Container(
                          width: 18,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                palette.sweepColor,
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 7, 7),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(icons[widget.level - 1], style: const TextStyle(fontSize: 18, height: 1)),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                widget.name,
                                maxLines: 2,
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: palette.titleColor,
                                  fontSize: 10.5,
                                  height: 1.05,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.rangeLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: palette.descriptionColor,
                            fontSize: 8.2,
                            height: 1,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        ...widget.benefits.map(
                          (benefit) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '•',
                                  style: TextStyle(
                                    color: palette.bulletColor,
                                    fontSize: 10,
                                    height: 1.15,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(width: 3),
                                Expanded(
                                  child: Text(
                                    benefit,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: palette.bulletColor,
                                      fontSize: 8.4,
                                      height: 1.15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (widget.isCurrent) ...[
                          const Spacer(),
                          Align(
                            alignment: Alignment.bottomRight,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF102E50),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                context.tr('Hiện tại'),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 7.5,
                                  height: 1,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class AgentLevelPalette {
  const AgentLevelPalette({
    required this.gradient,
    required this.foreground,
    required this.borderColor,
    required this.shadow,
    required this.titleColor,
    required this.descriptionColor,
    required this.bulletColor,
    required this.sweepColor,
  });

  final Gradient gradient;
  final Color foreground;
  final Color borderColor;
  final List<BoxShadow> shadow;
  final Color titleColor;
  final Color descriptionColor;
  final Color bulletColor;
  final Color sweepColor;

  factory AgentLevelPalette.forAgent(AgentModel agent) {
    if (!agent.isBroker) {
      return const AgentLevelPalette(
        gradient: LinearGradient(colors: [Color(0xFF64748B), Color(0xFF64748B)]),
        foreground: Colors.white,
        borderColor: Colors.transparent,
        shadow: [BoxShadow(color: Color(0x291E293B), blurRadius: 10, offset: Offset(0, 4))],
        titleColor: Colors.white,
        descriptionColor: Color(0xFFE2E8F0),
        bulletColor: Color(0xFFE2E8F0),
        sweepColor: Color(0x2EFFFFFF),
      );
    }
    return AgentLevelPalette.forLevel(agent.normalizedLevel);
  }

  factory AgentLevelPalette.forLevel(int rawLevel) {
    final level = rawLevel < 1 ? 1 : (rawLevel > 6 ? 6 : rawLevel);
    switch (level) {
      case 2:
        return const AgentLevelPalette(
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF064E3B), Color(0xFF0F766E)]),
          foreground: Colors.white,
          borderColor: Color(0xFF064E3B),
          shadow: [BoxShadow(color: Color(0x38064E3B), blurRadius: 16, offset: Offset(0, 7))],
          titleColor: Colors.white,
          descriptionColor: Color(0xEBFFFFFF),
          bulletColor: Color(0xE6FFFFFF),
          sweepColor: Color(0x38FFFFFF),
        );
      case 3:
        return const AgentLevelPalette(
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Colors.white, Color(0xFFCFD4DC), Color(0xFF8F98A3), Colors.white], stops: [0, 0.38, 0.72, 1]),
          foreground: Color(0xFF222222),
          borderColor: Color(0xFF8F98A3),
          shadow: [BoxShadow(color: Color(0x388F98A3), blurRadius: 16, offset: Offset(0, 7))],
          titleColor: Color(0xFF222222),
          descriptionColor: Color(0xFF4B5563),
          bulletColor: Color(0xFF374151),
          sweepColor: Color(0x85FFFFFF),
        );
      case 4:
        return const AgentLevelPalette(
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF8C6A1D), Color(0xFFD4AF37), Color(0xFFFFE6A0)]),
          foreground: Color(0xFF2B1B02),
          borderColor: Color(0xFF8C6A1D),
          shadow: [BoxShadow(color: Color(0x3D8C6A1D), blurRadius: 18, offset: Offset(0, 8))],
          titleColor: Color(0xFF2B1B02),
          descriptionColor: Color(0xFF4A3206),
          bulletColor: Color(0xFF3B2603),
          sweepColor: Color(0x61FFFFFF),
        );
      case 5:
        return const AgentLevelPalette(
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF0099CC), Color(0xFF61D5FF), Color(0xFFDFF7FF)]),
          foreground: Color(0xFF083344),
          borderColor: Color(0xFF0099CC),
          shadow: [BoxShadow(color: Color(0x380099CC), blurRadius: 18, offset: Offset(0, 8))],
          titleColor: Color(0xFF083344),
          descriptionColor: Color(0xFF075985),
          bulletColor: Color(0xFF0C4A6E),
          sweepColor: Color(0x6BFFFFFF),
        );
      case 6:
        return const AgentLevelPalette(
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF050505), Color(0xFF1B1B1B), Color(0xFF050505)]),
          foreground: Colors.white,
          borderColor: Color(0xFFD4AF37),
          shadow: [
            BoxShadow(color: Color(0x38D4AF37), blurRadius: 20),
            BoxShadow(color: Color(0x380F172A), blurRadius: 20, offset: Offset(0, 9)),
          ],
          titleColor: Colors.white,
          descriptionColor: Color(0xEBFFFFFF),
          bulletColor: Color(0xE6FFFFFF),
          sweepColor: Color(0x33FFFFFF),
        );
      case 1:
      default:
        return const AgentLevelPalette(
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Colors.white, Color(0xFFE5E7EB)]),
          foreground: Color(0xFF222222),
          borderColor: Color(0xFFD1D5DB),
          shadow: [BoxShadow(color: Color(0x140F172A), blurRadius: 10, offset: Offset(0, 4))],
          titleColor: Color(0xFF222222),
          descriptionColor: Color(0xFF4B5563),
          bulletColor: Color(0xFF374151),
          sweepColor: Color(0x7AFFFFFF),
        );
    }
  }
}
