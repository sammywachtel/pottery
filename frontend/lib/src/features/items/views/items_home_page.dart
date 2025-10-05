import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:intl/intl.dart';

import '../../auth/controllers/auth_controller.dart';
import '../../../data/models/pottery_item.dart';
import '../../../data/repositories/item_repository.dart';
import '../../../design_system/widgets/pottery_card.dart';
import '../../../design_system/widgets/pottery_empty_state.dart';
import '../../../design_system/pottery_spacing.dart';
import '../../../design_system/pottery_colors.dart';
import '../../../design_system/pottery_typography.dart';
import '../controllers/item_providers.dart';
import 'item_detail_page.dart';
import 'item_form_page.dart';

// Sort criteria and direction for pottery items
enum ItemSortCriteria { name, date, stage }
enum SortDirection { ascending, descending }

class ItemsHomePage extends ConsumerStatefulWidget {
  const ItemsHomePage({super.key});

  @override
  ConsumerState<ItemsHomePage> createState() => _ItemsHomePageState();
}

class _ItemsHomePageState extends ConsumerState<ItemsHomePage> {
  ItemSortCriteria _sortCriteria = ItemSortCriteria.date;
  SortDirection _sortDirection = SortDirection.descending;

  // Filter state
  Set<String> _selectedStages = {};
  Set<String> _selectedLocations = {};
  DateTimeRange? _selectedDateRange;
  bool _showArchived = false;
  bool _showBroken = false;

  @override
  Widget build(BuildContext context) {
    final itemsAsync = ref.watch(itemListProvider);
    final authState = ref.watch(authControllerProvider);

    Future<void> refresh() async {
      ref.invalidate(itemListProvider);
      await ref.read(itemListProvider.future);
    }

    return Scaffold(
      appBar: AppBar(
        // Here's where we fix overflow: flexible title that can shrink
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.handyman,
              color: Theme.of(context).colorScheme.primary,
              size: 24, // Slightly smaller icon
            ),
            const SizedBox(width: 6),
            const Flexible(
              child: Text(
                'Pottery Studio',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          // Opening move: Filter button with count badge showing active filters
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.filter_list),
                tooltip: 'Filter options',
                onPressed: () => _showFilterOptions(context),
              ),
              if (_hasActiveFilters())
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 16),
                    height: 16,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        '${_getActiveFilterCount()}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          // Sort button
          IconButton(
            icon: Icon(_sortDirection == SortDirection.ascending
                ? Icons.sort_by_alpha
                : Icons.sort_by_alpha),
            tooltip: 'Sort options',
            onPressed: () => _showSortOptions(context),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reload pottery collection',
            onPressed: () => ref.invalidate(itemListProvider),
          ),
          PopupMenuButton<_MenuAction>(
            onSelected: (action) async {
              if (action == _MenuAction.logout) {
                await ref.read(authControllerProvider.notifier).logout();
              }
            },
            itemBuilder: (context) {
              return [
                PopupMenuItem(
                  value: _MenuAction.logout,
                  child: ListTile(
                    leading: const Icon(Icons.logout),
                    title: Text('Sign out${authState.username != null ? ' (${authState.username})' : ''}'),
                  ),
                ),
              ];
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (_) => const ItemFormPage(),
            ),
          );
          if (created == true) {
            ref.invalidate(itemListProvider);
          }
        },
        icon: const Icon(Icons.handyman),
        label: const Text('Create Pottery'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: itemsAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return PotteryEmptyState(
              type: PotteryEmptyStateType.noItems,
              onActionPressed: () async {
                final created = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (_) => const ItemFormPage(),
                  ),
                );
                if (created == true) {
                  ref.invalidate(itemListProvider);
                }
              },
            );
          }

          // Filter and sort items based on current criteria and direction
          final filteredItems = _filterItems(items);
          final sortedItems = _sortItems(filteredItems);
          return RefreshIndicator.adaptive(
            onRefresh: refresh,
            child: CustomScrollView(
              // Opening move: Increase cache extent to keep more items alive off-screen
              // This prevents photos from being disposed and reloaded during scroll
              cacheExtent: 1000.0, // Keep ~3 screens worth of items cached
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.all(PotterySpacing.clay),
                  sliver: SliverMasonryGrid.count(
                    crossAxisCount: _getCrossAxisCount(context),
                    mainAxisSpacing: PotterySpacing.trim,
                    crossAxisSpacing: PotterySpacing.trim,
                    childCount: sortedItems.length,
                    itemBuilder: (context, index) {
                      final item = sortedItems[index];
                      return _PotteryItemCard(
                        item: item,
                        onTap: () => _navigateToDetail(context, ref, item),
                        onLongPress: () => _showItemActions(context, ref, item),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const PotteryEmptyState(
          type: PotteryEmptyStateType.loading,
        ),
        error: (error, _) => _ErrorState(
          message: error.toString(),
          onRetry: () => ref.invalidate(itemListProvider),
        ),
      ),
    );
  }

  // Helper function to determine grid columns based on screen width
  int _getCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 900) return 4; // Desktop
    if (width > 600) return 3; // Tablet
    return 2; // Mobile
  }

  // Sort items based on current criteria and direction
  List<PotteryItemModel> _sortItems(List<PotteryItemModel> items) {
    final sortedItems = List<PotteryItemModel>.from(items);

    switch (_sortCriteria) {
      case ItemSortCriteria.name:
        sortedItems.sort((a, b) => _sortDirection == SortDirection.ascending
            ? a.name.compareTo(b.name)
            : b.name.compareTo(a.name));
        break;
      case ItemSortCriteria.date:
        // Big play: Sort by updated datetime (falls back to created if no updates)
        sortedItems.sort((a, b) {
          final aDate = a.updatedDateTime ?? a.createdDateTime;
          final bDate = b.updatedDateTime ?? b.createdDateTime;
          return _sortDirection == SortDirection.ascending
              ? aDate.compareTo(bDate)
              : bDate.compareTo(aDate);
        });
        break;
      case ItemSortCriteria.stage:
        // Define stage order: greenware < bisque < final
        final stageOrder = {'greenware': 0, 'bisque': 1, 'final': 2};
        sortedItems.sort((a, b) {
          final aOrder = stageOrder[a.currentStatus.toLowerCase()] ?? 0;
          final bOrder = stageOrder[b.currentStatus.toLowerCase()] ?? 0;
          return _sortDirection == SortDirection.ascending
              ? aOrder.compareTo(bOrder)
              : bOrder.compareTo(aOrder);
        });
        break;
    }

    return sortedItems;
  }

  // Show sort options modal
  void _showSortOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(PotterySpacing.clay),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: PotterySpacing.clay),
                decoration: BoxDecoration(
                  color: Theme.of(context).dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              'Sort pottery items',
              style: Theme.of(context).textTheme.ceramic,
            ),
            PotterySpace.clayVertical,

            // Sort criteria options
            _SortOption(
              title: 'Name',
              subtitle: 'Alphabetical order',
              icon: Icons.sort_by_alpha,
              isSelected: _sortCriteria == ItemSortCriteria.name,
              onTap: () {
                setState(() {
                  _sortCriteria = ItemSortCriteria.name;
                });
                Navigator.pop(context);
              },
            ),
            _SortOption(
              title: 'Date updated',
              subtitle: 'Most recently modified',
              icon: Icons.calendar_today,
              isSelected: _sortCriteria == ItemSortCriteria.date,
              onTap: () {
                setState(() {
                  _sortCriteria = ItemSortCriteria.date;
                });
                Navigator.pop(context);
              },
            ),
            _SortOption(
              title: 'Firing stage',
              subtitle: 'Greenware → Bisque → Final',
              icon: Icons.local_fire_department,
              isSelected: _sortCriteria == ItemSortCriteria.stage,
              onTap: () {
                setState(() {
                  _sortCriteria = ItemSortCriteria.stage;
                });
                Navigator.pop(context);
              },
            ),

            const Divider(),
            PotterySpace.trimVertical,

            // Sort direction toggle
            ListTile(
              leading: Icon(_sortDirection == SortDirection.ascending
                  ? Icons.arrow_upward
                  : Icons.arrow_downward),
              title: Text(_sortDirection == SortDirection.ascending
                  ? 'Ascending'
                  : 'Descending'),
              subtitle: Text(_getSortDirectionDescription()),
              trailing: Switch(
                value: _sortDirection == SortDirection.descending,
                onChanged: (value) {
                  setState(() {
                    _sortDirection = value
                        ? SortDirection.descending
                        : SortDirection.ascending;
                  });
                },
              ),
            ),
            // Victory lap: Removed extra bottom padding to fix 2px overflow
          ],
        ),
      ),
    );
  }

  String _getSortDirectionDescription() {
    switch (_sortCriteria) {
      case ItemSortCriteria.name:
        return _sortDirection == SortDirection.ascending ? 'A to Z' : 'Z to A';
      case ItemSortCriteria.date:
        return _sortDirection == SortDirection.ascending ? 'Least recent first' : 'Most recent first';
      case ItemSortCriteria.stage:
        return _sortDirection == SortDirection.ascending ? 'Greenware first' : 'Final first';
    }
  }

  // Filter items based on current filter criteria
  List<PotteryItemModel> _filterItems(List<PotteryItemModel> items) {
    return items.where((item) {
      // Opening move: Archived and broken are exclusive filters
      // When enabled, show ONLY those items, not include them
      if (_showArchived) {
        // Show only archived items
        if (!item.isArchived) return false;
      } else if (_showBroken) {
        // Show only broken items
        if (!item.isBroken) return false;
      } else {
        // Default: hide both archived and broken items
        if (item.isArchived || item.isBroken) return false;
      }

      // Filter by stages
      if (_selectedStages.isNotEmpty && !_selectedStages.contains(item.currentStatus.toLowerCase())) {
        return false;
      }

      // Filter by locations
      if (_selectedLocations.isNotEmpty && !_selectedLocations.contains(item.location)) {
        return false;
      }

      // Filter by date range
      if (_selectedDateRange != null) {
        final itemDate = item.createdDateTime;
        if (itemDate.isBefore(_selectedDateRange!.start) ||
            itemDate.isAfter(_selectedDateRange!.end.add(const Duration(hours: 23, minutes: 59, seconds: 59)))) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  // Check if any filters are currently active
  bool _hasActiveFilters() {
    return _selectedStages.isNotEmpty ||
           _selectedLocations.isNotEmpty ||
           _selectedDateRange != null ||
           _showArchived ||
           _showBroken;
  }

  // Big play: Count active filters for badge display
  int _getActiveFilterCount() {
    int count = 0;
    if (_selectedStages.isNotEmpty) count++;
    if (_selectedLocations.isNotEmpty) count++;
    if (_selectedDateRange != null) count++;
    if (_showArchived || _showBroken) count++; // Count as one visibility filter
    return count;
  }

  // Get unique stages from all items
  Set<String> _getAvailableStages(List<PotteryItemModel> items) {
    return items.map((item) => item.currentStatus.toLowerCase()).toSet();
  }

  // Get unique locations from all items
  Set<String> _getAvailableLocations(List<PotteryItemModel> items) {
    return items.map((item) => item.location).toSet();
  }

  // Show filter options modal
  void _showFilterOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _FilterOptionsSheet(
        selectedStages: _selectedStages,
        selectedLocations: _selectedLocations,
        selectedDateRange: _selectedDateRange,
        showArchived: _showArchived,
        showBroken: _showBroken,
        availableStages: _getAvailableStages(ref.read(itemListProvider).value ?? []),
        availableLocations: _getAvailableLocations(ref.read(itemListProvider).value ?? []),
        onFiltersChanged: (stages, locations, dateRange, showArchived, showBroken) {
          setState(() {
            _selectedStages = stages;
            _selectedLocations = locations;
            _selectedDateRange = dateRange;
            _showArchived = showArchived;
            _showBroken = showBroken;
          });
        },
        onClearAll: () {
          setState(() {
            _selectedStages.clear();
            _selectedLocations.clear();
            _selectedDateRange = null;
            _showArchived = false;
            _showBroken = false;
          });
        },
      ),
    );
  }

  // Navigate to item detail page
  Future<void> _navigateToDetail(BuildContext context, WidgetRef ref, PotteryItemModel item) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ItemDetailPage(itemId: item.id),
      ),
    );
    ref.invalidate(itemListProvider);
  }

  // Show item actions bottom sheet
  void _showItemActions(BuildContext context, WidgetRef ref, PotteryItemModel item) {
    showModalBottomSheet(
      context: context,
      builder: (context) => _ItemActionsSheet(item: item, ref: ref),
    );
  }
}

// Opening move: Convert to StatefulWidget with AutomaticKeepAliveClientMixin
// This prevents the widget from being disposed when scrolling, keeping photos cached
class _PotteryItemCard extends StatefulWidget {
  const _PotteryItemCard({
    required this.item,
    this.onTap,
    this.onLongPress,
  });

  final PotteryItemModel item;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  State<_PotteryItemCard> createState() => _PotteryItemCardState();
}

class _PotteryItemCardState extends State<_PotteryItemCard>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    // Big play: Call super.build to enable keep-alive functionality
    super.build(context);

    return PotteryCard(
      name: widget.item.name,
      clayType: widget.item.clayType,
      location: widget.item.location,
      primaryPhotoUrl: _getPrimaryPhotoUrl(),
      photos: widget.item.photos.map((photo) => {
        'stage': photo.stage,
        'signedUrl': photo.signedUrl,
        'id': photo.id,
      }).toList(),
      currentStatus: widget.item.currentStatus,
      createdDateTime: widget.item.createdDateTime,
      lastUpdatedDateTime: widget.item.updatedDateTime,
      isBroken: widget.item.isBroken,
      isArchived: widget.item.isArchived,
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      heroTag: 'item-${widget.item.id}',
      cardVariant: PotteryCardVariant.grid,
    );
  }

  String? _getPrimaryPhotoUrl() {
    if (widget.item.photos.isEmpty) return null;

    // Check if any photo is marked as primary
    final primaryPhoto = widget.item.photos.where((p) => p.isPrimary).firstOrNull;
    if (primaryPhoto?.signedUrl != null) {
      return primaryPhoto!.signedUrl;
    }

    // If no primary photo, use the most recent photo (newest uploadedAt)
    final photosWithUrl = widget.item.photos.where((p) => p.signedUrl != null).toList();
    if (photosWithUrl.isEmpty) return null;

    // Sort by uploadedAt descending (most recent first)
    photosWithUrl.sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));

    // Victory lap: return the most recent photo
    return photosWithUrl.first.signedUrl;
  }
}

// Item actions bottom sheet
class _ItemActionsSheet extends ConsumerWidget {
  const _ItemActionsSheet({
    required this.item,
    required this.ref,
  });

  final PotteryItemModel item;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(PotterySpacing.clay),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurfaceVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          PotterySpace.clayVertical,

          // Item info
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(PotterySpacing.round),
                ),
                child: Icon(
                  Icons.handyman,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
              PotterySpace.trimHorizontal,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: theme.textTheme.ceramic,
                    ),
                    Text(
                      item.clayType,
                      style: theme.textTheme.slip.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          PotterySpace.clayVertical,

          // Actions
          ListTile(
            leading: Icon(Icons.visibility_outlined, color: theme.colorScheme.primary),
            title: const Text('View details'),
            onTap: () async {
              Navigator.of(context).pop();
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ItemDetailPage(itemId: item.id),
                ),
              );
              ref.invalidate(itemListProvider);
            },
          ),
          ListTile(
            leading: Icon(Icons.edit_outlined, color: theme.colorScheme.secondary),
            title: const Text('Edit pottery'),
            onTap: () async {
              Navigator.of(context).pop();
              final updated = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (_) => ItemFormPage(existingItem: item),
                ),
              );
              if (updated == true) {
                ref.invalidate(itemListProvider);
              }
            },
          ),
          ListTile(
            leading: Icon(Icons.delete_outline, color: theme.colorScheme.error),
            title: const Text('Delete pottery'),
            onTap: () => _handleDelete(context),
          ),
          PotterySpace.clayVertical,
        ],
      ),
    );
  }

  Future<void> _handleDelete(BuildContext context) async {
    Navigator.of(context).pop(); // Close bottom sheet

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete pottery item'),
        content: Text('Are you sure you want to delete "${item.name}"?\n\nThis will also delete all associated photos.'),
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

    final messenger = ScaffoldMessenger.of(context);
    try {
      final itemRepository = ref.read(itemRepositoryProvider);
      await itemRepository.deleteItem(item.id);
      ref.invalidate(itemListProvider);
      messenger.showSnackBar(
        SnackBar(
          content: Text('Deleted "${item.name}" 🏺'),
          backgroundColor: PotteryColors.clayPrimary,
        ),
      );
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Failed to delete: $error'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }
}

// Removed old _ItemCard - replaced with _PotteryItemCard above
// Removed old _EmptyState - using PotteryEmptyState instead

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.warning_amber_rounded, size: 56),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

// Filter options sheet widget
class _FilterOptionsSheet extends StatefulWidget {
  const _FilterOptionsSheet({
    required this.selectedStages,
    required this.selectedLocations,
    required this.selectedDateRange,
    required this.showArchived,
    required this.showBroken,
    required this.availableStages,
    required this.availableLocations,
    required this.onFiltersChanged,
    required this.onClearAll,
  });

  final Set<String> selectedStages;
  final Set<String> selectedLocations;
  final DateTimeRange? selectedDateRange;
  final bool showArchived;
  final bool showBroken;
  final Set<String> availableStages;
  final Set<String> availableLocations;
  final Function(Set<String>, Set<String>, DateTimeRange?, bool, bool) onFiltersChanged;
  final VoidCallback onClearAll;

  @override
  State<_FilterOptionsSheet> createState() => _FilterOptionsSheetState();
}

class _FilterOptionsSheetState extends State<_FilterOptionsSheet> {
  late Set<String> _tempSelectedStages;
  late Set<String> _tempSelectedLocations;
  DateTimeRange? _tempSelectedDateRange;
  late bool _tempShowArchived;
  late bool _tempShowBroken;

  @override
  void initState() {
    super.initState();
    _tempSelectedStages = Set.from(widget.selectedStages);
    _tempSelectedLocations = Set.from(widget.selectedLocations);
    _tempSelectedDateRange = widget.selectedDateRange;
    _tempShowArchived = widget.showArchived;
    _tempShowBroken = widget.showBroken;
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          padding: const EdgeInsets.all(PotterySpacing.clay),
          child: Column(
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: PotterySpacing.clay),
                decoration: BoxDecoration(
                  color: Theme.of(context).dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Row(
                children: [
                  Text(
                    'Filter pottery items',
                    style: Theme.of(context).textTheme.ceramic,
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _tempSelectedStages.clear();
                        _tempSelectedLocations.clear();
                        _tempSelectedDateRange = null;
                        _tempShowArchived = false;
                        _tempShowBroken = false;
                      });
                    },
                    child: const Text('Clear all'),
                  ),
                ],
              ),
              const Divider(),

              // Content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    // Big play: Section header for visibility filters
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Text(
                        'VISIBILITY',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    // Date range filter
                    ListTile(
                      leading: const Icon(Icons.date_range),
                      title: const Text('Date range'),
                      subtitle: Text(_tempSelectedDateRange == null
                          ? 'All dates'
                          : '${DateFormat.yMMMd().format(_tempSelectedDateRange!.start)} - ${DateFormat.yMMMd().format(_tempSelectedDateRange!.end)}'),
                      trailing: _tempSelectedDateRange != null
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                setState(() {
                                  _tempSelectedDateRange = null;
                                });
                              },
                            )
                          : null,
                      onTap: () async {
                        final dateRange = await showDateRangePicker(
                          context: context,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                          initialDateRange: _tempSelectedDateRange,
                        );
                        if (dateRange != null) {
                          setState(() {
                            _tempSelectedDateRange = dateRange;
                          });
                        }
                      },
                    ),

                    PotterySpace.slipVertical,

                    // Victory lap: Explanation of visibility logic
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Text(
                        'By default, archived and broken items are hidden. These filters show ONLY the selected type (mutually exclusive).',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),

                    // Show archived toggle - battle-hardened visibility control
                    SwitchListTile(
                      secondary: const Icon(Icons.archive_outlined),
                      title: const Text('Show only archived items'),
                      subtitle: const Text('View completed/filed items only'),
                      value: _tempShowArchived,
                      onChanged: (value) {
                        setState(() {
                          _tempShowArchived = value;
                          // Big play: Mutually exclusive - disable broken when archived enabled
                          if (value) _tempShowBroken = false;
                        });
                      },
                    ),

                    // Show broken toggle - same pattern as archived
                    SwitchListTile(
                      secondary: const Icon(Icons.warning_outlined),
                      title: const Text('Show only broken items'),
                      subtitle: const Text('View damaged items only'),
                      value: _tempShowBroken,
                      onChanged: (value) {
                        setState(() {
                          _tempShowBroken = value;
                          // Big play: Mutually exclusive - disable archived when broken enabled
                          if (value) _tempShowArchived = false;
                        });
                      },
                    ),

                    PotterySpace.clayVertical,
                    const Divider(),

                    // Main play: Section header for stage filters
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Text(
                        'FIRING STAGE',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Text(
                        'Select one or more stages to filter by. Items must match at least one selected stage.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),

                    // Firing stages filter
                    if (widget.availableStages.isNotEmpty) ...[
                      ...widget.availableStages.map((stage) {
                        final isSelected = _tempSelectedStages.contains(stage);
                        return CheckboxListTile(
                          title: Text(stage.toUpperCase()),
                          value: isSelected,
                          onChanged: (value) {
                            setState(() {
                              if (value == true) {
                                _tempSelectedStages.add(stage);
                              } else {
                                _tempSelectedStages.remove(stage);
                              }
                            });
                          },
                        );
                      }).toList(),
                      PotterySpace.clayVertical,
                    ],

                    const Divider(),

                    // Main play: Section header for location filters
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Text(
                        'LOCATION',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Text(
                        'Select one or more locations to filter by. Items must match at least one selected location.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),

                    // Locations filter
                    if (widget.availableLocations.isNotEmpty) ...[
                      ...widget.availableLocations.map((location) {
                        final isSelected = _tempSelectedLocations.contains(location);
                        return CheckboxListTile(
                          title: Text(location),
                          value: isSelected,
                          onChanged: (value) {
                            setState(() {
                              if (value == true) {
                                _tempSelectedLocations.add(location);
                              } else {
                                _tempSelectedLocations.remove(location);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ],
                  ],
                ),
              ),

              // Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  PotterySpace.trimHorizontal,
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        widget.onFiltersChanged(
                          _tempSelectedStages,
                          _tempSelectedLocations,
                          _tempSelectedDateRange,
                          _tempShowArchived,
                          _tempShowBroken,
                        );
                        Navigator.of(context).pop();
                      },
                      child: const Text('Apply filters'),
                    ),
                  ),
                ],
              ),
              PotterySpace.clayVertical,
            ],
          ),
        );
      },
    );
  }
}

// Helper widget for sort option list tiles
class _SortOption extends StatelessWidget {
  const _SortOption({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      title: Text(
        title,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : null,
          fontWeight: isSelected ? FontWeight.w600 : null,
        ),
      ),
      subtitle: Text(subtitle),
      trailing: isSelected
          ? Icon(
              Icons.check,
              color: Theme.of(context).colorScheme.primary,
            )
          : null,
      onTap: onTap,
    );
  }
}

enum _MenuAction { logout }

enum _ItemAction { details, edit, delete }
