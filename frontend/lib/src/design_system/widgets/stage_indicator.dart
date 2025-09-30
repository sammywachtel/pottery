import 'package:flutter/material.dart';
import '../pottery_colors.dart';
import '../pottery_spacing.dart';
import '../pottery_typography.dart';

/// Visual indicator for pottery stages - shows progression through Greenware → Bisque → Final
/// Displays as compact G/B/F badges with appropriate colors and states
class StageIndicator extends StatelessWidget {
  const StageIndicator({
    super.key,
    required this.stages,
    this.size = StageIndicatorSize.medium,
    this.showLabels = false,
    this.spacing,
  });

  /// Map of stage names to boolean indicating if that stage has photos
  final Map<String, bool> stages;

  /// Size variant of the indicator
  final StageIndicatorSize size;

  /// Whether to show full stage labels instead of abbreviations
  final bool showLabels;

  /// Custom spacing between badges (defaults to size-appropriate spacing)
  final double? spacing;

  @override
  Widget build(BuildContext context) {
    final effectiveSpacing = spacing ?? _getDefaultSpacing();

    return Wrap(
      spacing: effectiveSpacing,
      children: [
        _StageBadge(
          stage: 'greenware',
          label: showLabels ? 'Greenware' : 'G',
          hasPhotos: stages['greenware'] ?? false,
          size: size,
        ),
        _StageBadge(
          stage: 'bisque',
          label: showLabels ? 'Bisque' : 'B',
          hasPhotos: stages['bisque'] ?? false,
          size: size,
        ),
        _StageBadge(
          stage: 'final',
          label: showLabels ? 'Final' : 'F',
          hasPhotos: stages['final'] ?? false,
          size: size,
        ),
      ],
    );
  }

  double _getDefaultSpacing() {
    switch (size) {
      case StageIndicatorSize.small:
        return PotterySpacing.slip;
      case StageIndicatorSize.medium:
        return PotterySpacing.tool;
      case StageIndicatorSize.large:
        return PotterySpacing.trim;
    }
  }
}

/// Individual stage badge component
class _StageBadge extends StatelessWidget {
  const _StageBadge({
    required this.stage,
    required this.label,
    required this.hasPhotos,
    required this.size,
  });

  final String stage;
  final String label;
  final bool hasPhotos;
  final StageIndicatorSize size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stageColor = PotteryColors.getStageColor(stage);
    final stageColorLight = PotteryColors.getStageColorLight(stage);

    final badgeSize = _getBadgeSize();
    final textStyle = _getTextStyle(theme);

    return Container(
      width: badgeSize,
      height: badgeSize,
      decoration: BoxDecoration(
        color: hasPhotos ? stageColor : theme.colorScheme.surfaceVariant,
        border: hasPhotos
            ? null
            : Border.all(
                color: stageColor.withOpacity(0.5),
                width: 1,
              ),
        borderRadius: BorderRadius.circular(badgeSize / 2),
        boxShadow: hasPhotos
            ? [
                BoxShadow(
                  color: stageColor.withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Center(
        child: Text(
          label,
          style: textStyle.copyWith(
            color: hasPhotos
                ? Colors.white
                : stageColor,
            fontWeight: hasPhotos ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  double _getBadgeSize() {
    switch (size) {
      case StageIndicatorSize.small:
        return 20.0;
      case StageIndicatorSize.medium:
        return 28.0;
      case StageIndicatorSize.large:
        return 36.0;
    }
  }

  TextStyle _getTextStyle(ThemeData theme) {
    switch (size) {
      case StageIndicatorSize.small:
        return theme.textTheme.tool;
      case StageIndicatorSize.medium:
        return theme.textTheme.labelMedium ?? PotteryTypography.labelMedium;
      case StageIndicatorSize.large:
        return theme.textTheme.labelLarge ?? PotteryTypography.labelLarge;
    }
  }
}

/// Progress indicator showing stage completion
class StageProgressIndicator extends StatelessWidget {
  const StageProgressIndicator({
    super.key,
    required this.stages,
    this.showPercentage = false,
  });

  final Map<String, bool> stages;
  final bool showPercentage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final completedStages = stages.values.where((hasPhotos) => hasPhotos).length;
    final totalStages = stages.length;
    final progress = totalStages > 0 ? completedStages / totalStages : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: theme.colorScheme.surfaceVariant,
                valueColor: AlwaysStoppedAnimation<Color>(
                  theme.colorScheme.primary,
                ),
                minHeight: 8,
              ),
            ),
            if (showPercentage) ...[
              PotterySpace.toolHorizontal,
              Text(
                '${(progress * 100).round()}%',
                style: theme.textTheme.slip,
              ),
            ],
          ],
        ),
        PotterySpace.toolVertical,
        Text(
          '$completedStages of $totalStages stages documented',
          style: theme.textTheme.slip.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// Animated stage transition indicator for when pottery progresses
class StageTransitionIndicator extends StatefulWidget {
  const StageTransitionIndicator({
    super.key,
    required this.fromStage,
    required this.toStage,
    this.onComplete,
  });

  final String fromStage;
  final String toStage;
  final VoidCallback? onComplete;

  @override
  State<StageTransitionIndicator> createState() => _StageTransitionIndicatorState();
}

class _StageTransitionIndicatorState extends State<StageTransitionIndicator>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    ));

    _colorAnimation = ColorTween(
      begin: PotteryColors.getStageColor(widget.fromStage),
      end: PotteryColors.getStageColor(widget.toStage),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _controller.forward().then((_) {
      widget.onComplete?.call();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: _colorAnimation.value,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (_colorAnimation.value ?? theme.colorScheme.primary)
                      .withOpacity(0.4),
                  blurRadius: 12 * _scaleAnimation.value,
                  spreadRadius: 4 * _scaleAnimation.value,
                ),
              ],
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.arrow_upward,
                    color: Colors.white,
                    size: 24,
                  ),
                  Text(
                    _getStageLabel(widget.toStage),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
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

  String _getStageLabel(String stage) {
    switch (stage.toLowerCase()) {
      case 'bisque':
        return 'Bisque!';
      case 'final':
        return 'Final!';
      default:
        return 'Next!';
    }
  }
}

/// Size variants for stage indicators
enum StageIndicatorSize {
  small,
  medium,
  large,
}

/// Utility extension for getting stages from photo list
extension StageIndicatorHelper on List<Map<String, dynamic>> {
  /// Convert photo list to stage completion map
  Map<String, bool> toStageMap() {
    final stages = <String, bool>{
      'greenware': false,
      'bisque': false,
      'final': false,
    };

    for (final photo in this) {
      final stage = photo['stage']?.toString().toLowerCase();
      if (stage != null && stages.containsKey(stage)) {
        stages[stage] = true;
      }
    }

    return stages;
  }
}

/// Utility extension for creating stage map from currentStatus
extension CurrentStatusStageMap on String {
  /// Convert currentStatus to stage completion map based on firing progression
  /// Shows the current status and all previous stages as completed
  Map<String, bool> toCurrentStatusStageMap() {
    final stages = <String, bool>{
      'greenware': false,
      'bisque': false,
      'final': false,
    };

    final normalizedStatus = toLowerCase();

    // Show progression: greenware → bisque → final
    switch (normalizedStatus) {
      case 'greenware':
        stages['greenware'] = true;
        break;
      case 'bisque':
        stages['greenware'] = true;
        stages['bisque'] = true;
        break;
      case 'final':
        stages['greenware'] = true;
        stages['bisque'] = true;
        stages['final'] = true;
        break;
      default:
        // For any unrecognized status, default to greenware
        stages['greenware'] = true;
        break;
    }

    return stages;
  }
}
