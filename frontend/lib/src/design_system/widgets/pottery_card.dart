import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import '../pottery_colors.dart';
import '../pottery_spacing.dart';
import '../pottery_typography.dart';
import 'stage_indicator.dart';

/// Photo-centric card component for displaying pottery items
/// Designed for mobile-first pottery studio workflow
class PotteryCard extends StatefulWidget {
  const PotteryCard({
    super.key,
    required this.name,
    required this.clayType,
    this.location,
    this.primaryPhotoUrl,
    this.photos = const [],
    this.currentStatus,
    this.createdDateTime,
    this.lastUpdatedDateTime,
    this.isBroken = false,
    this.isArchived = false,
    this.onTap,
    this.onLongPress,
    this.heroTag,
    this.showStageIndicator = true,
    this.showDate = true,
    this.cardVariant = PotteryCardVariant.grid,
  });

  final String name;
  final String clayType;
  final String? location;
  final String? primaryPhotoUrl;
  final List<Map<String, dynamic>> photos;
  final String? currentStatus;
  final DateTime? createdDateTime;
  final DateTime? lastUpdatedDateTime;
  final bool isBroken;
  final bool isArchived;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final String? heroTag;
  final bool showStageIndicator;
  final bool showDate;
  final PotteryCardVariant cardVariant;

  @override
  State<PotteryCard> createState() => _PotteryCardState();
}

class _PotteryCardState extends State<PotteryCard> with TickerProviderStateMixin {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stages = widget.currentStatus?.toCurrentStatusStageMap() ?? widget.photos.toStageMap();

    final cardContent = widget.cardVariant == PotteryCardVariant.list
        ? _buildListContent(context, theme, stages)
        : _buildGridContent(context, theme, stages);

    // Big play: Apply special background colors for archived/broken items
    Color? cardColor;
    if (widget.isArchived) {
      cardColor = Colors.amber.shade50;  // Subtle amber tint for archived items
    } else if (widget.isBroken) {
      cardColor = theme.colorScheme.errorContainer.withOpacity(0.15);
    }

    Widget card = Card(
      clipBehavior: Clip.antiAlias,
      elevation: _isPressed ? 1 : 2,
      color: cardColor,
      child: InkWell(
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        child: cardContent,
      ),
    );

    // Add hero animation if heroTag provided
    if (widget.heroTag != null) {
      card = Hero(
        tag: widget.heroTag!,
        child: card,
      );
    }

    // Add pottery clay bounce animation
    return card
        .animate()
        .scale(
          duration: 150.ms,
          begin: const Offset(1.0, 1.0),
          end: const Offset(0.95, 0.95),
          curve: Curves.easeOut,
        )
        .then()
        .scale(
          duration: 200.ms,
          begin: const Offset(0.95, 0.95),
          end: const Offset(1.0, 1.0),
          curve: Curves.elasticOut,
        );
  }

  Widget _buildGridContent(BuildContext context, ThemeData theme, Map<String, bool> stages) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Photo section - let image determine its own aspect ratio
        ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(PotterySpacing.trim)),
          child: Stack(
            children: [
              _buildPhotoDisplay(context, theme),

              // Archived/Broken status badges - top-left corner
              if (widget.isArchived || widget.isBroken)
                Positioned(
                  top: PotterySpacing.tool,
                  left: PotterySpacing.tool,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: widget.isArchived
                        ? Colors.amber.shade700  // Warm amber for "filed away" feel
                        : theme.colorScheme.error,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: widget.isArchived
                          ? Colors.amber.shade900
                          : theme.colorScheme.onError,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        widget.isArchived ? 'A' : 'B',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),

              // Stage indicator overlay (top-right)
              if (widget.showStageIndicator)
                Positioned(
                  top: PotterySpacing.tool,
                  right: PotterySpacing.tool,
                  child: Container(
                    padding: const EdgeInsets.all(PotterySpacing.slip),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(PotterySpacing.ceramic),
                    ),
                    child: StageIndicator(
                      stages: stages,
                      size: StageIndicatorSize.small,
                    ),
                  ),
                ),
            ],
          ),
        ),

        // Info section
        Flexible(
          fit: FlexFit.loose,
          child: Padding(
            padding: const EdgeInsets.all(PotterySpacing.trim),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Item name
                Text(
                  widget.name,
                  style: theme.textTheme.ceramic.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                // Clay type
                Text(
                  widget.clayType,
                  style: theme.textTheme.slip.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                // Location (if provided)
                if (widget.location?.isNotEmpty == true)
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 14,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      PotterySpace.slipHorizontal,
                      Expanded(
                        child: Text(
                          widget.location!,
                          style: theme.textTheme.tool.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                // Date information (if provided)
                if (widget.showDate && (widget.createdDateTime != null || widget.lastUpdatedDateTime != null))
                  Row(
                    children: [
                      Icon(
                        Icons.schedule_outlined,
                        size: 14,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      PotterySpace.slipHorizontal,
                      Expanded(
                        child: Text(
                          _formatDisplayDate(),
                          style: theme.textTheme.tool.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildListContent(BuildContext context, ThemeData theme, Map<String, bool> stages) {
    return Padding(
      padding: const EdgeInsets.all(PotterySpacing.trim),
      child: Row(
        children: [
          // Photo thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(PotterySpacing.round),
            child: SizedBox(
              width: 64,
              height: 64,
              child: Stack(
                children: [
                  _buildPhotoDisplay(context, theme),
                  // Archived/Broken status badge for list variant - compact
                  if (widget.isArchived || widget.isBroken)
                    Positioned(
                      top: 4,
                      left: 4,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: widget.isArchived
                            ? Colors.amber.shade700
                            : theme.colorScheme.error,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: widget.isArchived
                              ? Colors.amber.shade900
                              : theme.colorScheme.onError,
                            width: 1.5,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            widget.isArchived ? 'A' : 'B',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          PotterySpace.trimHorizontal,

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name and stage indicator
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.name,
                        style: theme.textTheme.ceramic.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (widget.showStageIndicator) ...[
                      PotterySpace.toolHorizontal,
                      StageIndicator(
                        stages: stages,
                        size: StageIndicatorSize.small,
                      ),
                    ],
                  ],
                ),

                PotterySpace.slipVertical,

                // Clay type
                Text(
                  widget.clayType,
                  style: theme.textTheme.slip.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                // Location (if provided)
                if (widget.location?.isNotEmpty == true) ...[
                  PotterySpace.slipVertical,
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 12,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      PotterySpace.slipHorizontal,
                      Expanded(
                        child: Text(
                          widget.location!,
                          style: theme.textTheme.tool.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],

                // Date information (if provided)
                if (widget.showDate && (widget.createdDateTime != null || widget.lastUpdatedDateTime != null)) ...[
                  PotterySpace.slipVertical,
                  Row(
                    children: [
                      Icon(
                        Icons.schedule_outlined,
                        size: 12,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      PotterySpace.slipHorizontal,
                      Expanded(
                        child: Text(
                          _formatDisplayDate(),
                          style: theme.textTheme.tool.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Chevron for list items
          Icon(
            Icons.chevron_right,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoDisplay(BuildContext context, ThemeData theme) {
    if (widget.primaryPhotoUrl?.isNotEmpty == true) {
      // Main play: Let image display at natural size, masonry grid handles layout
      // Use fitWidth to fill card width while maintaining aspect ratio
      return CachedNetworkImage(
        imageUrl: widget.primaryPhotoUrl!,
        fit: BoxFit.fitWidth,
        width: double.infinity,
        placeholder: (context, url) => _buildPhotoPlaceholder(theme),
        errorWidget: (context, url, error) => _buildPhotoError(theme),
        fadeInDuration: const Duration(milliseconds: 150),
        fadeOutDuration: const Duration(milliseconds: 50),
        // Victory lap: Don't specify memCache dimensions to preserve aspect ratio
        // Specifying both width and height would force square caching, squishing images
      );
    } else {
      return _buildPhotoPlaceholder(theme);
    }
  }

  Widget _buildPhotoPlaceholder(ThemeData theme) {
    // Victory lap: Give placeholder a reasonable aspect ratio when no photo present
    // This prevents cards from collapsing to nothing
    return AspectRatio(
      aspectRatio: 0.75, // 3:4 portrait ratio
      child: Container(
        color: theme.colorScheme.surfaceVariant,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.camera_alt_outlined,
                size: widget.cardVariant == PotteryCardVariant.grid ? 32 : 24,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              if (widget.cardVariant == PotteryCardVariant.grid) ...[
                PotterySpace.toolVertical,
                Text(
                  'No photo yet',
                  style: theme.textTheme.tool.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoError(ThemeData theme) {
    // Here's where we keep error state consistent with placeholder
    return AspectRatio(
      aspectRatio: 0.75, // 3:4 portrait ratio
      child: Container(
        color: theme.colorScheme.errorContainer.withOpacity(0.1),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.broken_image_outlined,
                size: widget.cardVariant == PotteryCardVariant.grid ? 32 : 24,
                color: theme.colorScheme.error,
              ),
              if (widget.cardVariant == PotteryCardVariant.grid) ...[
                PotterySpace.toolVertical,
                Text(
                  'Photo unavailable',
                  style: theme.textTheme.tool.copyWith(
                    color: theme.colorScheme.error,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDisplayDate() {
    final dateToShow = widget.lastUpdatedDateTime ?? widget.createdDateTime;
    if (dateToShow == null) return '';

    // Opening move: Compare calendar dates, not time differences
    // This fixes the bug where "Today 6:31 PM" shows for yesterday's timestamp
    final now = DateTime.now();
    final localDate = dateToShow.toLocal();

    // Big play: Normalize to date-only (midnight) for accurate day comparison
    final nowDate = DateTime(now.year, now.month, now.day);
    final itemDate = DateTime(localDate.year, localDate.month, localDate.day);
    final dayDifference = nowDate.difference(itemDate).inDays;

    if (dayDifference == 0) {
      return 'Today ${DateFormat.jm().format(localDate)}';
    } else if (dayDifference == 1) {
      return 'Yesterday';
    } else if (dayDifference < 7) {
      return '${dayDifference}d ago';
    } else if (dayDifference < 30) {
      return '${(dayDifference / 7).floor()}w ago';
    } else {
      return DateFormat.yMd().format(localDate);
    }
  }
}

/// Compact pottery card for tight spaces
class CompactPotteryCard extends StatelessWidget {
  const CompactPotteryCard({
    super.key,
    required this.name,
    required this.clayType,
    this.primaryPhotoUrl,
    this.photos = const [],
    this.onTap,
    this.heroTag,
  });

  final String name;
  final String clayType;
  final String? primaryPhotoUrl;
  final List<Map<String, dynamic>> photos;
  final VoidCallback? onTap;
  final String? heroTag;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stages = photos.toStageMap();

    Widget card = Card(
      margin: const EdgeInsets.all(PotterySpacing.slip),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(PotterySpacing.round),
        child: Padding(
          padding: const EdgeInsets.all(PotterySpacing.tool),
          child: Row(
            children: [
              // Tiny photo
              ClipRRect(
                borderRadius: BorderRadius.circular(PotterySpacing.soft),
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: primaryPhotoUrl?.isNotEmpty == true
                      ? CachedNetworkImage(
                          imageUrl: primaryPhotoUrl!,
                          fit: BoxFit.cover,
                          fadeInDuration: const Duration(milliseconds: 150),
                          fadeOutDuration: const Duration(milliseconds: 50),
                          memCacheWidth: 100, // Small cache for tiny thumbnails
                          memCacheHeight: 100,
                          placeholder: (context, url) => Container(
                            color: theme.colorScheme.surfaceVariant,
                            child: Icon(
                              Icons.image_outlined,
                              size: 16,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: theme.colorScheme.errorContainer.withOpacity(0.1),
                            child: Icon(
                              Icons.broken_image_outlined,
                              size: 16,
                              color: theme.colorScheme.error,
                            ),
                          ),
                        )
                      : Container(
                          color: theme.colorScheme.surfaceVariant,
                          child: Icon(
                            Icons.camera_alt_outlined,
                            size: 16,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                ),
              ),

              PotterySpace.toolHorizontal,

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: theme.textTheme.slip.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      clayType,
                      style: theme.textTheme.tool.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Micro stage indicator
              StageIndicator(
                stages: stages,
                size: StageIndicatorSize.small,
              ),
            ],
          ),
        ),
      ),
    );

    if (heroTag != null) {
      card = Hero(tag: heroTag!, child: card);
    }

    return card;
  }
}

/// Card variants for different layouts
enum PotteryCardVariant {
  grid,   // Photo-centric grid layout
  list,   // Horizontal list layout
}

/// Pottery card with stage celebration animation
class CelebrationPotteryCard extends StatefulWidget {
  const CelebrationPotteryCard({
    super.key,
    required this.potteryCard,
    this.celebrateStage,
  });

  final PotteryCard potteryCard;
  final String? celebrateStage;

  @override
  State<CelebrationPotteryCard> createState() => _CelebrationPotteryCardState();
}

class _CelebrationPotteryCardState extends State<CelebrationPotteryCard>
    with TickerProviderStateMixin {
  late AnimationController _celebrationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _celebrationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.1),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.1, end: 0.95),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.95, end: 1.05),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.05, end: 1.0),
        weight: 25,
      ),
    ]).animate(CurvedAnimation(
      parent: _celebrationController,
      curve: Curves.elasticOut,
    ));

    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 0.1,
    ).animate(CurvedAnimation(
      parent: _celebrationController,
      curve: Curves.elasticOut,
    ));

    // Start celebration if stage provided
    if (widget.celebrateStage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _celebrationController.forward();
      });
    }
  }

  @override
  void dispose() {
    _celebrationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _celebrationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Transform.rotate(
            angle: _rotationAnimation.value,
            child: widget.potteryCard,
          ),
        );
      },
    );
  }
}
