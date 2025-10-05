import 'package:flutter/material.dart';
import '../pottery_colors.dart';
import '../pottery_spacing.dart';
import '../pottery_typography.dart';

/// Circular radio button selector for pottery stages
/// Uses same visual style as StageIndicator but allows user selection
class StageSelector extends StatelessWidget {
  const StageSelector({
    super.key,
    required this.selectedStage,
    required this.onStageSelected,
    this.size = StageSelectorSize.medium,
    this.showHelp = true,
  });

  /// Currently selected stage (greenware, bisque, or final)
  final String selectedStage;

  /// Callback when a stage is selected
  final ValueChanged<String> onStageSelected;

  /// Size variant of the selector
  final StageSelectorSize size;

  /// Whether to show the help icon
  final bool showHelp;

  @override
  Widget build(BuildContext context) {
    final spacing = _getSpacing();

    // Big play: Show progression like StageIndicator
    // When Bisque selected, show Greenware as filled too
    // When Final selected, show all three as filled
    final normalizedStage = selectedStage.toLowerCase();
    final isGreenweareFilled = normalizedStage == 'greenware' ||
                                normalizedStage == 'bisque' ||
                                normalizedStage == 'final';
    final isBisqueFilled = normalizedStage == 'bisque' || normalizedStage == 'final';
    final isFinalFilled = normalizedStage == 'final';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _SelectableStageBadge(
          stage: 'greenware',
          label: 'G',
          isFilled: isGreenweareFilled,
          isCurrentStage: normalizedStage == 'greenware',
          onTap: () => onStageSelected('greenware'),
          size: size,
        ),
        SizedBox(width: spacing),
        _SelectableStageBadge(
          stage: 'bisque',
          label: 'B',
          isFilled: isBisqueFilled,
          isCurrentStage: normalizedStage == 'bisque',
          onTap: () => onStageSelected('bisque'),
          size: size,
        ),
        SizedBox(width: spacing),
        _SelectableStageBadge(
          stage: 'final',
          label: 'F',
          isFilled: isFinalFilled,
          isCurrentStage: normalizedStage == 'final',
          onTap: () => onStageSelected('final'),
          size: size,
        ),
        if (showHelp) ...[
          SizedBox(width: spacing * 2), // Extra spacing before help icon
          _HelpIcon(size: size),
        ],
      ],
    );
  }

  double _getSpacing() {
    switch (size) {
      case StageSelectorSize.small:
        return PotterySpacing.slip;
      case StageSelectorSize.medium:
        return PotterySpacing.tool;
      case StageSelectorSize.large:
        return PotterySpacing.trim;
    }
  }
}

/// Individual selectable stage badge (radio button style)
class _SelectableStageBadge extends StatelessWidget {
  const _SelectableStageBadge({
    required this.stage,
    required this.label,
    required this.isFilled,
    required this.isCurrentStage,
    required this.onTap,
    required this.size,
  });

  final String stage;
  final String label;
  final bool isFilled;
  final bool isCurrentStage;
  final VoidCallback onTap;
  final StageSelectorSize size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stageColor = PotteryColors.getStageColor(stage);

    final badgeSize = _getBadgeSize();
    final textStyle = _getTextStyle(theme);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(badgeSize / 2),
      child: Container(
        width: badgeSize,
        height: badgeSize,
        decoration: BoxDecoration(
          // Big play: Show progression - filled badges for completed stages
          // Extra border for the actual current stage
          color: isFilled ? stageColor : theme.colorScheme.surfaceVariant,
          border: isFilled
              ? (isCurrentStage
                  ? Border.all(
                      color: stageColor,
                      width: 2.5,
                    )
                  : null)
              : Border.all(
                  color: stageColor.withOpacity(0.5),
                  width: 1.5,
                ),
          borderRadius: BorderRadius.circular(badgeSize / 2),
          boxShadow: isFilled
              ? [
                  BoxShadow(
                    color: stageColor.withOpacity(isCurrentStage ? 0.4 : 0.3),
                    blurRadius: isCurrentStage ? 6 : 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: textStyle.copyWith(
              color: isFilled ? Colors.white : stageColor,
              fontWeight: isFilled ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  double _getBadgeSize() {
    switch (size) {
      case StageSelectorSize.small:
        return 24.0;
      case StageSelectorSize.medium:
        return 32.0;
      case StageSelectorSize.large:
        return 40.0;
    }
  }

  TextStyle _getTextStyle(ThemeData theme) {
    switch (size) {
      case StageSelectorSize.small:
        return theme.textTheme.labelSmall ?? PotteryTypography.labelSmall;
      case StageSelectorSize.medium:
        return theme.textTheme.labelMedium ?? PotteryTypography.labelMedium;
      case StageSelectorSize.large:
        return theme.textTheme.labelLarge ?? PotteryTypography.labelLarge;
    }
  }
}

/// Help icon that shows stage explanation dialog
class _HelpIcon extends StatelessWidget {
  const _HelpIcon({required this.size});

  final StageSelectorSize size;

  @override
  Widget build(BuildContext context) {
    final iconSize = _getIconSize();

    return IconButton(
      icon: Icon(
        Icons.help_outline,
        size: iconSize,
      ),
      padding: EdgeInsets.zero,
      constraints: BoxConstraints(
        minWidth: iconSize + 8,
        minHeight: iconSize + 8,
      ),
      onPressed: () => _showStageHelpDialog(context),
      tooltip: 'What do these stages mean?',
    );
  }

  double _getIconSize() {
    switch (size) {
      case StageSelectorSize.small:
        return 16.0;
      case StageSelectorSize.medium:
        return 20.0;
      case StageSelectorSize.large:
        return 24.0;
    }
  }

  void _showStageHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pottery Firing Stages'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StageHelpRow(
              badge: 'G',
              stage: 'Greenware',
              description: 'Unfired pottery, still soft and fragile. Needs to dry completely before bisque firing.',
              color: PotteryColors.getStageColor('greenware'),
            ),
            PotterySpace.clayVertical,
            _StageHelpRow(
              badge: 'B',
              stage: 'Bisque',
              description: 'Pottery after first firing. Hard and porous, ready for glazing.',
              color: PotteryColors.getStageColor('bisque'),
            ),
            PotterySpace.clayVertical,
            _StageHelpRow(
              badge: 'F',
              stage: 'Final',
              description: 'Pottery after glaze firing. Fully finished and ready to use.',
              color: PotteryColors.getStageColor('final'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
  }
}

/// Help dialog row showing stage info
class _StageHelpRow extends StatelessWidget {
  const _StageHelpRow({
    required this.badge,
    required this.stage,
    required this.description,
    required this.color,
  });

  final String badge;
  final String stage;
  final String description;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Opening move: Show filled badge as example
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Text(
              badge,
              style: theme.textTheme.labelMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        PotterySpace.trimHorizontal,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                stage,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Size variants for stage selector
enum StageSelectorSize {
  small,
  medium,
  large,
}
