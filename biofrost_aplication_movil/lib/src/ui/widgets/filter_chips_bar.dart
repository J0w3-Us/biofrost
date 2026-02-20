import 'package:flutter/material.dart';

import '../tokens/app_colors.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_text_styles.dart';

/// Barra horizontal scrolleable de chips de filtro.
///
/// Opcionalmente incluye un chip «Todos» al inicio.
///
/// ```dart
/// FilterChipsBar<String>(
///   items: ['React', 'Flutter', 'Node.js'],
///   selected: state.selectedStack,
///   labelBuilder: (s) => s,
///   onSelected: (s) => notifier.filterByStack(s),
/// )
/// ```
class FilterChipsBar<T> extends StatelessWidget {
  const FilterChipsBar({
    super.key,
    required this.items,
    required this.labelBuilder,
    required this.onSelected,
    this.selected,
    this.allLabel = 'Todos',
    this.padding,
  });

  final List<T> items;
  final String Function(T) labelBuilder;
  final void Function(T?) onSelected;
  final T? selected;
  final String allLabel;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding:
            padding ??
            const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadding),
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemCount: items.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return _Chip(
              label: allLabel,
              isSelected: selected == null,
              onTap: () => onSelected(null),
            );
          }
          final item = items[index - 1];
          return _Chip(
            label: labelBuilder(item),
            isSelected: selected == item,
            onTap: () => onSelected(item),
          );
        },
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.border,
                width: 1.2,
              ),
            ),
            child: Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: isSelected ? Colors.white : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
