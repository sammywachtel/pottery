import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../pottery_colors.dart';
import '../pottery_spacing.dart';
import '../pottery_typography.dart';

/// Whimsical empty state widget with pottery-themed encouragement
/// Shows different messages and actions based on context
class PotteryEmptyState extends StatefulWidget {
  const PotteryEmptyState({
    super.key,
    required this.type,
    this.onActionPressed,
    this.actionLabel,
    this.customMessage,
    this.customSubtitle,
  });

  final PotteryEmptyStateType type;
  final VoidCallback? onActionPressed;
  final String? actionLabel;
  final String? customMessage;
  final String? customSubtitle;

  @override
  State<PotteryEmptyState> createState() => _PotteryEmptyStateState();
}

class _PotteryEmptyStateState extends State<PotteryEmptyState>
    with TickerProviderStateMixin {
  late AnimationController _floatController;
  late AnimationController _pulseController;
  late Animation<double> _floatAnimation;
  late Animation<double> _pulseAnimation;

  int _currentMessageIndex = 0;
  late List<PotteryMessage> _messages;

  @override
  void initState() {
    super.initState();

    // Floating animation for pottery wheel effect
    _floatController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _floatAnimation = Tween<double>(
      begin: -8.0,
      end: 8.0,
    ).animate(CurvedAnimation(
      parent: _floatController,
      curve: Curves.easeInOut,
    ));

    // Pulse animation for heart beat effect
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _pulseAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.1),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.1, end: 1.0),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: ConstantTween<double>(1.0),
        weight: 60,
      ),
    ]).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _messages = _getMessagesForType(widget.type);

    // Cycle through messages every 4 seconds
    _startMessageCycling();
  }

  void _startMessageCycling() {
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted && _messages.length > 1) {
        setState(() {
          _currentMessageIndex = (_currentMessageIndex + 1) % _messages.length;
        });
        _startMessageCycling();
      }
    });
  }

  @override
  void dispose() {
    _floatController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentMessage = _messages[_currentMessageIndex];

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(PotterySpacing.wheel),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated pottery icon
            AnimatedBuilder(
              animation: _floatAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, _floatAnimation.value),
                  child: AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _pulseAnimation.value,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer.withOpacity(0.2),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: theme.colorScheme.primary.withOpacity(0.3),
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: Icon(
                              currentMessage.icon,
                              size: 48,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),

            PotterySpace.wheelVertical,

            // Main message with fade transition
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              child: Text(
                widget.customMessage ?? currentMessage.title,
                key: ValueKey(_currentMessageIndex),
                style: theme.textTheme.clay.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            PotterySpace.clayVertical,

            // Subtitle with fade transition
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: animation.drive(
                      Tween<Offset>(
                        begin: const Offset(0.0, 0.3),
                        end: Offset.zero,
                      ).chain(CurveTween(curve: Curves.easeOut)),
                    ),
                    child: child,
                  ),
                );
              },
              child: Text(
                widget.customSubtitle ?? currentMessage.subtitle,
                key: ValueKey('subtitle_$_currentMessageIndex'),
                style: theme.textTheme.glaze.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            if (widget.onActionPressed != null && currentMessage.actionLabel != null) ...[
              PotterySpace.wheelVertical,

              // Action button with clay bounce effect
              FilledButton.icon(
                onPressed: widget.onActionPressed,
                icon: Icon(currentMessage.actionIcon ?? Icons.add),
                label: Text(widget.actionLabel ?? currentMessage.actionLabel!),
              )
                  .animate()
                  .fadeIn(delay: 1000.ms, duration: 500.ms)
                  .slideY(begin: 0.3, end: 0, duration: 500.ms, curve: Curves.easeOut),
            ],

            PotterySpace.centerVertical,

            // Pottery wisdom (long-press easter egg)
            GestureDetector(
              onLongPress: () => _showPotteryWisdom(context),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: PotterySpacing.clay,
                  vertical: PotterySpacing.tool,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(PotterySpacing.smooth),
                  border: Border.all(
                    color: theme.colorScheme.outline.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  '💡 Long press for pottery wisdom',
                  style: theme.textTheme.tool.copyWith(
                    color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<PotteryMessage> _getMessagesForType(PotteryEmptyStateType type) {
    switch (type) {
      case PotteryEmptyStateType.noItems:
        return [
          PotteryMessage(
            title: "Your pottery studio awaits!",
            subtitle: "Every master potter started with an empty shelf.\nTime to create your first masterpiece! 🏺",
            icon: Icons.handyman,
            actionLabel: "Create First Item",
            actionIcon: Icons.add_circle,
          ),
          PotteryMessage(
            title: "Clay is calling your name!",
            subtitle: "From humble earth to beautiful art—\nyour pottery journey begins here! ✨",
            icon: Icons.auto_awesome,
            actionLabel: "Start Creating",
            actionIcon: Icons.create,
          ),
          PotteryMessage(
            title: "Time to get your hands dirty!",
            subtitle: "The pottery wheel is spinning,\nwaiting for your creative touch! 🎯",
            icon: Icons.refresh,
            actionLabel: "Begin Journey",
            actionIcon: Icons.play_circle,
          ),
        ];

      case PotteryEmptyStateType.noPhotos:
        return [
          PotteryMessage(
            title: "Picture perfect pottery awaits!",
            subtitle: "Document your creation's journey from\ngreenware to gorgeous glazed glory! 📸",
            icon: Icons.camera_alt,
            actionLabel: "Take First Photo",
            actionIcon: Icons.photo_camera,
          ),
          PotteryMessage(
            title: "Capture the clay magic!",
            subtitle: "Every pottery stage tells a story—\nlet's start documenting yours! ✨",
            icon: Icons.auto_stories,
            actionLabel: "Add Photos",
            actionIcon: Icons.add_a_photo,
          ),
        ];

      case PotteryEmptyStateType.noResults:
        return [
          PotteryMessage(
            title: "No pottery matches found!",
            subtitle: "Sometimes the kiln fires differently—\ntry adjusting your search! 🔍",
            icon: Icons.search_off,
            actionLabel: "Clear Filters",
            actionIcon: Icons.clear_all,
          ),
          PotteryMessage(
            title: "These pieces are hiding!",
            subtitle: "Like pottery in the kiln,\nsometimes treasures need different timing! ⏰",
            icon: Icons.schedule,
          ),
        ];

      case PotteryEmptyStateType.greenwaveStage:
        return [
          PotteryMessage(
            title: "Ready for the kiln's first kiss!",
            subtitle: "Your greenware is waiting for that\ntransformative bisque firing! 🔥",
            icon: Icons.local_fire_department,
            actionLabel: "Add Greenware Photo",
            actionIcon: Icons.camera_alt,
          ),
        ];

      case PotteryEmptyStateType.bisqueStage:
        return [
          PotteryMessage(
            title: "Bisque fired and brilliant!",
            subtitle: "Ready for glazing? Time to add some\ncolor magic to your creation! 🌈",
            icon: Icons.palette,
            actionLabel: "Document Bisque",
            actionIcon: Icons.photo_library,
          ),
        ];

      case PotteryEmptyStateType.finalStage:
        return [
          PotteryMessage(
            title: "Masterpiece complete!",
            subtitle: "Your final fired pottery deserves\na place of honor in the gallery! 👑",
            icon: Icons.emoji_events,
            actionLabel: "Celebrate Final",
            actionIcon: Icons.celebration,
          ),
        ];

      case PotteryEmptyStateType.loading:
        return [
          PotteryMessage(
            title: "Spinning the pottery wheel...",
            subtitle: "Great pottery takes patience—\nyour pieces are loading! 🏺",
            icon: Icons.hourglass_bottom,
          ),
        ];
    }
  }

  void _showPotteryWisdom(BuildContext context) {
    final wisdoms = [
      "🏺 'The clay remembers every touch' - Ancient Potter",
      "✨ 'In pottery, mistakes become character' - Studio Wisdom",
      "🔥 'Fire reveals what the wheel concealed' - Master Potter",
      "💫 'Every crack tells a story of creation' - Ceramic Arts",
      "🎨 'Glazing is where magic meets chemistry' - Potter's Wisdom",
      "⚡ 'Centering clay is centering the soul' - Zen of Pottery",
    ];

    final randomWisdom = wisdoms[DateTime.now().millisecond % wisdoms.length];

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(randomWisdom),
        backgroundColor: PotteryColors.clayPrimary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(PotterySpacing.round),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

/// Data class for pottery empty state messages
class PotteryMessage {
  const PotteryMessage({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.actionLabel,
    this.actionIcon,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String? actionLabel;
  final IconData? actionIcon;
}

/// Types of empty states in pottery workflow
enum PotteryEmptyStateType {
  noItems,
  noPhotos,
  noResults,
  greenwaveStage,
  bisqueStage,
  finalStage,
  loading,
}
