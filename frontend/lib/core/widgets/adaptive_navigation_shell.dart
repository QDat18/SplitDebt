import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../theme/app_dimensions.dart';

/// Keep the page subtree in the same position when the device changes size.
/// This preserves in-progress forms and scroll positions during a resize.
class AdaptiveNavigationShell extends StatelessWidget {
  const AdaptiveNavigationShell({
    super.key,
    required this.child,
    required this.selectedIndex,
    required this.labels,
    required this.addLabel,
    required this.onSelect,
    required this.onQuickAdd,
  }) : assert(labels.length == 4);

  final Widget child;
  final int selectedIndex;
  final List<String> labels;
  final String addLabel;
  final ValueChanged<int> onSelect;
  final VoidCallback onQuickAdd;

  static const _icons = [
    CupertinoIcons.house,
    CupertinoIcons.person_2,
    CupertinoIcons.clock,
    CupertinoIcons.person_crop_circle,
  ];
  static const _selectedIcons = [
    CupertinoIcons.house_fill,
    CupertinoIcons.person_2_fill,
    CupertinoIcons.clock_fill,
    CupertinoIcons.person_crop_circle_fill,
  ];

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final rail =
          constraints.maxWidth >= AppDimensions.navigationRailBreakpoint;
      final extended =
          constraints.maxWidth >= AppDimensions.extendedNavigationBreakpoint;
      final scheme = Theme.of(context).colorScheme;
      final railWidth = rail ? (extended ? 232.0 : 104.0) : 0.0;
      return Scaffold(
        body: Row(
          children: [
            SizedBox(
              width: railWidth,
              child: rail
                  ? DecoratedBox(
                      decoration: BoxDecoration(
                        color: scheme.surface,
                        border: Border(
                          right: BorderSide(color: scheme.outlineVariant),
                        ),
                      ),
                      child: SafeArea(
                        right: false,
                        child: NavigationRail(
                          extended: extended,
                          scrollable: true,
                          minWidth: 103,
                          minExtendedWidth: 231,
                          groupAlignment: -1,
                          labelType: extended
                              ? NavigationRailLabelType.none
                              : NavigationRailLabelType.all,
                          leading: Padding(
                            padding: const EdgeInsets.only(top: 12, bottom: 24),
                            child: extended
                                ? SizedBox(
                                    width: 208,
                                    child: FilledButton.icon(
                                      onPressed: onQuickAdd,
                                      icon: const Icon(Icons.add),
                                      label: Text(addLabel, maxLines: 2),
                                    ),
                                  )
                                : IconButton.filled(
                                    tooltip: addLabel,
                                    onPressed: onQuickAdd,
                                    icon: const Icon(Icons.add),
                                  ),
                          ),
                          selectedIndex: selectedIndex,
                          onDestinationSelected: onSelect,
                          destinations: [
                            for (var i = 0; i < labels.length; i++)
                              NavigationRailDestination(
                                icon: Icon(_icons[i]),
                                selectedIcon: Icon(_selectedIcons[i]),
                                label: Text(labels[i]),
                              ),
                          ],
                        ),
                      ),
                    )
                  : null,
            ),
            Expanded(child: child),
          ],
        ),
        bottomNavigationBar: rail
            ? null
            : DecoratedBox(
                decoration: BoxDecoration(
                  color: scheme.surface,
                  border: Border(top: BorderSide(color: scheme.outlineVariant)),
                ),
                child: SafeArea(
                  top: false,
                  child: SizedBox(
                    height: MediaQuery.textScalerOf(context).scale(12) > 18
                        ? 88
                        : 72,
                    child: Row(
                      children: [
                        for (var i = 0; i < 2; i++) _tab(context, i),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: IconButton.filled(
                            tooltip: addLabel,
                            onPressed: onQuickAdd,
                            icon: const Icon(Icons.add),
                          ),
                        ),
                        for (var i = 2; i < 4; i++) _tab(context, i),
                      ],
                    ),
                  ),
                ),
              ),
      );
    },
  );

  Widget _tab(BuildContext context, int index) {
    final scheme = Theme.of(context).colorScheme;
    final selected = selectedIndex == index;
    final color = selected ? scheme.primary : scheme.onSurfaceVariant;
    return Expanded(
      child: Semantics(
        label: labels[index],
        selected: selected,
        button: true,
        onTap: () => onSelect(index),
        child: ExcludeSemantics(
          child: Tooltip(
            message: labels[index],
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => onSelect(index),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minHeight: 48,
                    minWidth: 48,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: selected
                              ? scheme.primary.withValues(alpha: 0.12)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          selected ? _selectedIcons[index] : _icons[index],
                          color: color,
                          size: 23,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        labels[index],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: color,
                          fontSize: 12,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
