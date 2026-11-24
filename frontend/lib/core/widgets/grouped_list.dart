// Trách nhiệm file: Cung cấp bộ widget danh sách nhóm (grouped list) chuẩn Apple HIG dùng cho các màn hình Cài đặt.

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';

class GroupedSection extends StatelessWidget {
  const GroupedSection({
    super.key,
    this.header,
    this.footer,
    required this.children,
  });

  final String? header;
  final String? footer;
  final List<Widget> children;

  bool _hasIcon(Widget widget) {
    if (widget is GroupedTile) {
      return widget.icon != null && !widget.destructive;
    }
    if (widget is GroupedSwitchTile) {
      return widget.icon != null;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final headerStyle = theme.textTheme.bodySmall?.copyWith(
      color: AppColors.n600,
    );
    final footerStyle = theme.textTheme.bodySmall?.copyWith(
      color: AppColors.n600,
    );

    final List<Widget> items = [];
    for (int i = 0; i < children.length; i++) {
      items.add(children[i]);
      if (i < children.length - 1) {
        final bool hasIcon = _hasIcon(children[i]) || _hasIcon(children[i + 1]);
        final double indent = hasIcon
            ? (AppDimensions.s16 + AppDimensions.s28 + AppDimensions.s16)
            : AppDimensions.s16;
        items.add(
          Padding(
            padding: EdgeInsets.only(left: indent),
            child: const Divider(
              key: ValueKey('grouped-separator'),
              height: 0.5,
              thickness: 0.5,
              color: AppColors.n200,
            ),
          ),
        );
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (header != null && header!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(
                left: AppDimensions.s16,
                right: AppDimensions.s16,
                bottom: AppDimensions.s8,
              ),
              child: Text(header!, style: headerStyle),
            ),
          ClipRRect(
            borderRadius: AppDimensions.radius12,
            child: ColoredBox(
              color: AppColors.n0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: items,
              ),
            ),
          ),
          if (footer != null && footer!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(
                left: AppDimensions.s16,
                right: AppDimensions.s16,
                top: AppDimensions.s8,
              ),
              child: Text(footer!, style: footerStyle),
            ),
        ],
      ),
    );
  }
}

class GroupedTile extends StatelessWidget {
  const GroupedTile({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.value,
    this.onTap,
    this.trailing,
    this.destructive = false,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final String? value;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final titleStyle = theme.textTheme.bodyLarge?.copyWith(
      color: destructive ? AppColors.error : AppColors.n800,
      fontWeight: destructive ? FontWeight.w500 : FontWeight.w400,
    );
    final subtitleStyle = theme.textTheme.bodySmall?.copyWith(
      color: AppColors.n600,
    );
    final valueStyle = theme.textTheme.bodyLarge?.copyWith(
      color: AppColors.n600,
    );

    Widget content;

    if (destructive) {
      content = Center(
        child: Text(
          title,
          style: titleStyle,
          textAlign: TextAlign.center,
        ),
      );
    } else {
      final List<Widget> rowChildren = [];

      if (icon != null) {
        rowChildren.add(
          Container(
            width: AppDimensions.s28,
            height: AppDimensions.s28,
            decoration: BoxDecoration(
              color: AppColors.p500,
              borderRadius: AppDimensions.radius8,
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: Colors.white, size: 18),
          ),
        );
        rowChildren.add(const SizedBox(width: AppDimensions.s16));
      }

      final titleCol = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title, style: titleStyle),
          if (subtitle != null && subtitle!.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              style: subtitleStyle,
              maxLines: 6,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      );

      rowChildren.add(Expanded(child: titleCol));

      if (trailing != null) {
        rowChildren.add(const SizedBox(width: AppDimensions.s8));
        rowChildren.add(trailing!);
      } else {
        if (value != null && value!.isNotEmpty) {
          rowChildren.add(const SizedBox(width: AppDimensions.s8));
          rowChildren.add(
            Flexible(
              child: Text(
                value!,
                style: valueStyle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
              ),
            ),
          );
        }
        if (onTap != null) {
          rowChildren.add(const SizedBox(width: AppDimensions.s4));
          rowChildren.add(
            const Icon(
              Icons.chevron_right,
              size: 20,
              color: AppColors.n400,
            ),
          );
        }
      }

      content = Row(
        children: rowChildren,
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 52.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.s16,
              vertical: AppDimensions.s12,
            ),
            child: content,
          ),
        ),
      ),
    );
  }
}

class GroupedSwitchTile extends StatelessWidget {
  const GroupedSwitchTile({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return GroupedTile(
      title: title,
      subtitle: subtitle,
      icon: icon,
      trailing: Switch.adaptive(
        value: value,
        onChanged: onChanged,
        activeTrackColor: AppColors.success,
      ),
      onTap: onChanged != null ? () => onChanged!(!value) : null,
    );
  }
}

