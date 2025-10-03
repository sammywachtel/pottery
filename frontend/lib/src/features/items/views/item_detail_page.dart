import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../data/models/photo.dart';
import '../../../data/models/measurement_detail.dart';
import '../../../data/models/measurements.dart';
import '../../../data/models/pottery_item.dart';
import '../../../data/repositories/item_repository.dart';
import '../../../design_system/pottery_typography.dart';
import '../../../design_system/pottery_spacing.dart';
import '../../../design_system/pottery_colors.dart';
import '../../../design_system/widgets/stage_indicator.dart';
import '../../photos/controllers/stage_provider.dart';
import '../../photos/views/photo_upload_sheet.dart';
import '../controllers/item_providers.dart';
import 'item_form_page.dart';

class ItemDetailPage extends ConsumerWidget {
  const ItemDetailPage({super.key, required this.itemId});

  final String itemId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemAsync = ref.watch(itemDetailProvider(itemId));

    Future<void> refresh() async {
      ref.invalidate(itemDetailProvider(itemId));
      await ref.read(itemDetailProvider(itemId).future);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Item details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: refresh,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await showModalBottomSheet<bool>(
            context: context,
            isScrollControlled: true,
            builder: (_) => PhotoUploadSheet(itemId: itemId),
          );
          if (created == true) {
            refresh();
            ref.invalidate(itemListProvider);
          }
        },
        icon: const Icon(Icons.cloud_upload_outlined),
        label: const Text('Upload photo'),
      ),
      body: itemAsync.when(
        data: (item) => _ItemDetailContent(
          item: item,
          onRefresh: refresh,
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.warning_amber_rounded, size: 56),
                const SizedBox(height: 16),
                Text('Failed to load item',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(error.toString(), textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: refresh,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ItemDetailContent extends ConsumerWidget {
  const _ItemDetailContent({
    required this.item,
    required this.onRefresh,
  });

  final PotteryItemModel item;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.watch(itemRepositoryProvider);
    final messenger = ScaffoldMessenger.of(context);
    final dateFormatter = DateFormat.yMMMd().add_jm();

    Future<void> editItem() async {
      final updated = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => ItemFormPage(existingItem: item),
        ),
      );
      if (updated == true) {
        await onRefresh();
        ref.invalidate(itemListProvider);
      }
    }

    Future<void> deletePhoto(PhotoModel photo) async {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete photo'),
          content: const Text('Are you sure you want to delete this photo?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
              child: const Text('Delete'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;

      try {
        await repository.deletePhoto(item.id, photo.id);
        messenger.showSnackBar(
          const SnackBar(content: Text('Photo removed')),
        );
        await onRefresh();
      } catch (error) {
        messenger.showSnackBar(
          SnackBar(content: Text('Failed to delete photo: $error')),
        );
      }
    }

    Future<void> setPrimaryPhoto(PhotoModel photo) async {
      try {
        await repository.setPrimaryPhoto(item.id, photo.id);
        messenger.showSnackBar(
          const SnackBar(content: Text('Set as primary photo')),
        );
        await onRefresh();
        ref.invalidate(itemListProvider);
      } catch (error) {
        messenger.showSnackBar(
          SnackBar(content: Text('Failed to set primary photo: $error')),
        );
      }
    }

    void _showPhotoViewer(BuildContext context, List<PhotoModel> photos, int initialIndex) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => _PhotoViewerPage(
            photos: photos,
            initialIndex: initialIndex,
            onSetPrimary: (photo) async {
              Navigator.of(context).pop();
              await setPrimaryPhoto(photo);
            },
          ),
        ),
      );
    }

    Future<void> editPhoto(PhotoModel photo) async {
      final stagesAsync = await ref.read(stagesProvider.future);
      final stageOptions = stagesAsync.isEmpty
          ? const ['Greenware', 'Bisque', 'Final']
          : stagesAsync;

      final controller = TextEditingController(text: photo.imageNote ?? '');
      // Here's where we dodge the dropdown error: ensure initial value exists in options
      // If photo.stage isn't in the list, fall back to first option to prevent crash
      String selectedStage = stageOptions.contains(photo.stage)
          ? photo.stage
          : stageOptions.first;
      final result = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Update photo details'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                value: selectedStage,
                items: stageOptions
                    .map(
                      (stage) => DropdownMenuItem(
                        value: stage,
                        child: Text(stage),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    selectedStage = value;
                  }
                },
                decoration: const InputDecoration(labelText: 'Stage'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: 'Note (optional)',
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Save'),
            ),
          ],
        ),
      );

      if (result != true) return;

      try {
        await repository.updatePhoto(
          item.id,
          photo.id,
          {
            'stage': selectedStage,
            'imageNote': controller.text.trim().isEmpty
                ? null
                : controller.text.trim(),
          },
        );
        messenger.showSnackBar(
          const SnackBar(content: Text('Photo updated')),
        );
        await onRefresh();
      } catch (error) {
        messenger.showSnackBar(
          SnackBar(content: Text('Failed to update photo: $error')),
        );
      }
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header with item name and current status
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    PotterySpace.toolVertical,
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: PotterySpacing.trim,
                            vertical: PotterySpacing.slip,
                          ),
                          decoration: BoxDecoration(
                            color: PotteryColors.getStageColor(item.currentStatus),
                            borderRadius: BorderRadius.circular(PotterySpacing.round),
                          ),
                          child: Text(
                            item.currentStatus.toUpperCase(),
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        PotterySpace.trimHorizontal,
                        StageIndicator(
                          stages: item.currentStatus.toCurrentStatusStageMap(),
                          size: StageIndicatorSize.medium,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Edit item',
                onPressed: editItem,
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Item Details Section
          Text('Details', style: Theme.of(context).textTheme.ceramic),
          const SizedBox(height: 12),
          _DetailRow(label: 'Clay Type', value: item.clayType),
          _DetailRow(label: 'Location', value: item.location),
          if (item.glaze != null && item.glaze!.isNotEmpty)
            _DetailRow(label: 'Glaze', value: item.glaze!),
          if (item.cone != null && item.cone!.isNotEmpty)
            _DetailRow(label: 'Cone', value: item.cone!),
          if (item.note != null && item.note!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('Notes', style: Theme.of(context).textTheme.ceramic),
            const SizedBox(height: 8),
            Text(item.note!, style: Theme.of(context).textTheme.slip),
          ],
          const SizedBox(height: 24),
          // Photos Section with horizontal scrolling
          Row(
            children: [
              Text('Photos', style: Theme.of(context).textTheme.ceramic),
              PotterySpace.trimHorizontal,
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: PotterySpacing.tool,
                  vertical: PotterySpacing.slip,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(PotterySpacing.round),
                ),
                child: Text(
                  '${item.photos.length}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (item.photos.isEmpty)
            Container(
              padding: const EdgeInsets.all(PotterySpacing.clay),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(PotterySpacing.trim),
                border: Border.all(
                  color: Theme.of(context).dividerColor,
                  style: BorderStyle.solid,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.photo_library_outlined,
                    size: 48,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  PotterySpace.trimVertical,
                  Text(
                    'No photos uploaded yet',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    'Use the upload button below to add your first photo',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            SizedBox(
              height: 280,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: item.photos.length,
                separatorBuilder: (context, index) => PotterySpace.trimHorizontal,
                itemBuilder: (context, index) {
                  final photo = item.photos[index];
                  return SizedBox(
                    width: 200,
                    child: _PhotoCard(
                      photo: photo,
                      onTap: () => _showPhotoViewer(context, item.photos, index),
                      onSetPrimary: () => setPrimaryPhoto(photo),
                      onEdit: () => editPhoto(photo),
                      onDelete: () => deletePhoto(photo),
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 24),
          // Measurements Section with modern grid layout
          if (item.measurements != null) ...[
            Text('Measurements', style: Theme.of(context).textTheme.ceramic),
            const SizedBox(height: 12),
            _MeasurementsGrid(measurements: item.measurements!),
            const SizedBox(height: 24),
          ],
          // Timestamps Section at the bottom
          Text('Timestamps', style: Theme.of(context).textTheme.ceramic),
          const SizedBox(height: 12),
          _DetailRow(label: 'Created', value: dateFormatter.format(item.createdDateTime.toLocal())),
          if (item.updatedDateTime != null)
            _DetailRow(label: 'Updated', value: dateFormatter.format(item.updatedDateTime!.toLocal())),
          // Add padding at bottom so FAB doesn't block content
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: PotterySpacing.tool),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

// Opening move: Build a modern measurements grid with card-based design
// This replaces the old vertical table with a responsive 2-column grid
class _MeasurementsGrid extends StatelessWidget {
  const _MeasurementsGrid({required this.measurements});

  final Measurements measurements;

  @override
  Widget build(BuildContext context) {
    // Main play: Use Column + Row layout for responsive 2-column grid
    // Greenware and Bisque side-by-side, Final spans full width below
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _MeasurementStageCard(
                stage: 'Greenware',
                detail: measurements.greenware,
                color: const Color(0xFF8B7355),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MeasurementStageCard(
                stage: 'Bisque',
                detail: measurements.bisque,
                color: const Color(0xFFC9966B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Victory lap: Final measurement spans full width, emphasizing completion
        _MeasurementStageCard(
          stage: 'Final',
          detail: measurements.finalMeasurement,
          color: const Color(0xFFB8704F),
        ),
      ],
    );
  }
}

// Here's where we build each stage card with elevation and color coding
class _MeasurementStageCard extends StatelessWidget {
  const _MeasurementStageCard({
    required this.stage,
    required this.detail,
    required this.color,
  });

  final String stage;
  final MeasurementDetail? detail;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 160),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Big play: Stage header with color indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  stage,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          // Victory lap: Display the measurements
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _MeasurementRow(
                  icon: '↕',
                  label: 'Height',
                  value: detail?.height,
                  color: color,
                ),
                const SizedBox(height: 8),
                _MeasurementRow(
                  icon: '↔',
                  label: 'Width',
                  value: detail?.width,
                  color: color,
                ),
                const SizedBox(height: 8),
                _MeasurementRow(
                  icon: '⊟',
                  label: 'Depth',
                  value: detail?.depth,
                  color: color,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// This looks odd, but it saves us from repeating measurement row code three times
class _MeasurementRow extends StatelessWidget {
  const _MeasurementRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final String icon;
  final String label;
  final double? value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Center(
            child: Text(
              icon,
              style: TextStyle(fontSize: 14, color: color),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        Text(
          value != null ? value.toString() : '—',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        if (value != null) ...[
          const SizedBox(width: 2),
          Text(
            'in',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey.shade400,
              fontSize: 10,
            ),
          ),
        ],
      ],
    );
  }
}

class _PhotoCard extends StatelessWidget {
  const _PhotoCard({
    required this.photo,
    required this.onTap,
    required this.onSetPrimary,
    required this.onEdit,
    required this.onDelete,
  });

  final PhotoModel photo;
  final VoidCallback onTap;
  final VoidCallback onSetPrimary;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final dateText = DateFormat.yMMMd().add_jm().format(photo.uploadedAt.toLocal());

    return Card(
      child: Column(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: onTap,
              child: Stack(
                children: [
                  // Main play: Display the photo
                  photo.signedUrl != null
                      ? ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                          child: Image.network(
                            photo.signedUrl!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            errorBuilder: (_, __, ___) => const Center(
                              child: Icon(Icons.broken_image_outlined, size: 48),
                            ),
                          ),
                        )
                      : const Center(child: Icon(Icons.broken_image_outlined, size: 48)),

                  // Victory lap: Show star indicator for primary photo
                  if (photo.isPrimary)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.star,
                          color: Colors.amber,
                          size: 20,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      photo.stage,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    PopupMenuButton<_PhotoAction>(
                      onSelected: (action) {
                        switch (action) {
                          case _PhotoAction.setPrimary:
                            onSetPrimary();
                            break;
                          case _PhotoAction.edit:
                            onEdit();
                            break;
                          case _PhotoAction.delete:
                            onDelete();
                            break;
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: _PhotoAction.setPrimary,
                          child: ListTile(
                            leading: Icon(
                              photo.isPrimary ? Icons.star : Icons.star_outline,
                              color: photo.isPrimary ? Colors.amber : null,
                            ),
                            title: Text(photo.isPrimary ? 'Primary photo' : 'Set as primary'),
                          ),
                        ),
                        const PopupMenuItem(
                          value: _PhotoAction.edit,
                          child: ListTile(
                            leading: Icon(Icons.edit_outlined),
                            title: Text('Edit details'),
                          ),
                        ),
                        const PopupMenuItem(
                          value: _PhotoAction.delete,
                          child: ListTile(
                            leading: Icon(Icons.delete_outline),
                            title: Text('Delete'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (photo.imageNote != null && photo.imageNote!.isNotEmpty)
                  Text(photo.imageNote!),
                const SizedBox(height: 8),
                Text(
                  'Uploaded $dateText',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Theme.of(context).hintColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum _PhotoAction { setPrimary, edit, delete }

// Opening move: Build a fullscreen photo viewer with swipe and pinch zoom
// This lets users examine their pottery photos in detail
class _PhotoViewerPage extends StatefulWidget {
  const _PhotoViewerPage({
    required this.photos,
    required this.initialIndex,
    required this.onSetPrimary,
  });

  final List<PhotoModel> photos;
  final int initialIndex;
  final Future<void> Function(PhotoModel) onSetPrimary;

  @override
  State<_PhotoViewerPage> createState() => _PhotoViewerPageState();
}

class _PhotoViewerPageState extends State<_PhotoViewerPage> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentPhoto = widget.photos[_currentIndex];
    final dateText = DateFormat.yMMMd().add_jm().format(currentPhoto.uploadedAt.toLocal());

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Main play: PageView for swiping between photos
          PageView.builder(
            controller: _pageController,
            itemCount: widget.photos.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemBuilder: (context, index) {
              final photo = widget.photos[index];
              return _ZoomableImage(
                imageUrl: photo.signedUrl,
              );
            },
          ),
          // Big play: Top bar with close button and photo info
          SafeArea(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.7),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            currentPhoto.stage,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (currentPhoto.imageNote != null && currentPhoto.imageNote!.isNotEmpty)
                            Text(
                              currentPhoto.imageNote!,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 14,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        currentPhoto.isPrimary ? Icons.star : Icons.star_outline,
                        color: currentPhoto.isPrimary ? Colors.amber : Colors.white,
                      ),
                      onPressed: () => widget.onSetPrimary(currentPhoto),
                      tooltip: currentPhoto.isPrimary ? 'Primary photo' : 'Set as primary',
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Victory lap: Bottom bar with page indicator and date
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.7),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.photos.length > 1)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            widget.photos.length,
                            (index) => Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: index == _currentIndex
                                    ? Colors.white
                                    : Colors.white.withOpacity(0.4),
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 8),
                      Text(
                        'Uploaded $dateText',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        '${_currentIndex + 1} of ${widget.photos.length}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Here's where we handle pinch-to-zoom and pan gestures
// This saves us from adding a third-party dependency
class _ZoomableImage extends StatefulWidget {
  const _ZoomableImage({required this.imageUrl});

  final String? imageUrl;

  @override
  State<_ZoomableImage> createState() => _ZoomableImageState();
}

class _ZoomableImageState extends State<_ZoomableImage> with SingleTickerProviderStateMixin {
  late TransformationController _transformationController;
  late AnimationController _animationController;
  Animation<Matrix4>? _animation;

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..addListener(() {
        if (_animation != null) {
          _transformationController.value = _animation!.value;
        }
      });
  }

  @override
  void dispose() {
    _transformationController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // Time to tackle the tricky bit: reset zoom with double-tap
  void _handleDoubleTap() {
    final currentScale = _transformationController.value.getMaxScaleOnAxis();

    if (currentScale > 1.0) {
      // Already zoomed, reset to normal
      _animateToScale(Matrix4.identity());
    } else {
      // Zoom in to 2x
      final newScale = 2.0;
      final matrix = Matrix4.identity()..scale(newScale);
      _animateToScale(matrix);
    }
  }

  void _animateToScale(Matrix4 targetMatrix) {
    _animation = Matrix4Tween(
      begin: _transformationController.value,
      end: targetMatrix,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.imageUrl == null) {
      return const Center(
        child: Icon(Icons.broken_image_outlined, color: Colors.white, size: 64),
      );
    }

    return GestureDetector(
      onDoubleTap: _handleDoubleTap,
      child: InteractiveViewer(
        transformationController: _transformationController,
        minScale: 1.0,
        maxScale: 4.0,
        child: Center(
          child: Image.network(
            widget.imageUrl!,
            fit: BoxFit.contain,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                      : null,
                  color: Colors.white,
                ),
              );
            },
            errorBuilder: (_, __, ___) => const Center(
              child: Icon(Icons.broken_image_outlined, color: Colors.white, size: 64),
            ),
          ),
        ),
      ),
    );
  }
}
