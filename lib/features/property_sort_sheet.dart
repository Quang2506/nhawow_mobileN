import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../l10n/app_localizations.dart';

class PropertySortOption {
  const PropertySortOption({required this.value, required this.label});

  final String value;
  final String label;
}

const List<PropertySortOption> propertySortOptions = <PropertySortOption>[
  PropertySortOption(value: 'relevant', label: 'Phù hợp nhất (Mặc định)'),
  PropertySortOption(value: 'newest', label: 'Mới nhất'),
  PropertySortOption(value: 'price_asc', label: 'Giá thấp đến cao'),
  PropertySortOption(value: 'price_desc', label: 'Giá cao xuống thấp'),
];

String propertySortLabel(BuildContext context, String value) {
  for (final option in propertySortOptions) {
    if (option.value == value) return context.tr(option.label);
  }
  return context.tr(propertySortOptions.first.label);
}

Future<String?> showPropertySortSheet(
  BuildContext context, {
  required String selectedValue,
}) {
  return showModalBottomSheet<String>(
    context: context,
    useSafeArea: true,
    isScrollControlled: false,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.58),
    builder: (sheetContext) => _PropertySortSheet(
      selectedValue: selectedValue,
    ),
  );
}

class PropertySortButton extends StatelessWidget {
  const PropertySortButton({
    required this.value,
    required this.onTap,
    this.compact = true,
    super.key,
  });

  final String value;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final fullLabel = propertySortLabel(context, value);
    final label = value == 'relevant' ? context.tr('Phù hợp nhất') : fullLabel;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          constraints: BoxConstraints(minHeight: compact ? 42 : 46),
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 12 : 14,
            vertical: 9,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFD6DFE9)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.navy,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.sort_rounded,
                size: 20,
                color: Color(0xFF52606D),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PropertySortSheet extends StatelessWidget {
  const _PropertySortSheet({required this.selectedValue});

  final String selectedValue;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(22),
          topRight: Radius.circular(22),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 9),
          Center(
            child: Container(
              width: 54,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFFE3E6EA),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('Sắp xếp'),
                  style: const TextStyle(
                    color: Color(0xFF222222),
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  context.tr('Sắp xếp bất động sản theo thứ tự'),
                  style: const TextStyle(
                    color: Color(0xFF777777),
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE8E8E8)),
          for (var index = 0; index < propertySortOptions.length; index++) ...[
            _SortOptionRow(
              option: propertySortOptions[index],
              selected: propertySortOptions[index].value == selectedValue,
            ),
            if (index < propertySortOptions.length - 1)
              const Divider(height: 1, indent: 18, color: Color(0xFFF0F0F0)),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _SortOptionRow extends StatelessWidget {
  const _SortOptionRow({required this.option, required this.selected});

  final PropertySortOption option;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.of(context).pop(option.value),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        child: Row(
          children: [
            Expanded(
              child: Text(
                context.tr(option.label),
                style: TextStyle(
                  color: selected
                      ? const Color(0xFF078568)
                      : const Color(0xFF595959),
                  fontSize: 16,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 14),
            AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? const Color(0xFF078568) : Colors.white,
                border: Border.all(
                  color: selected
                      ? const Color(0xFF078568)
                      : const Color(0xFFDADADA),
                  width: 1.5,
                ),
              ),
              alignment: Alignment.center,
              child: selected
                  ? Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
