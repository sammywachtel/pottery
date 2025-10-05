import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/measurement_detail.dart';
import '../../../data/models/pottery_item.dart';
import '../../../data/repositories/item_repository.dart';
import '../../../design_system/pottery_colors.dart';
import '../controllers/item_form_state.dart';
import '../controllers/item_providers.dart';

class ItemFormPage extends ConsumerStatefulWidget {
  const ItemFormPage({super.key, this.existingItem});

  final PotteryItemModel? existingItem;

  @override
  ConsumerState<ItemFormPage> createState() => _ItemFormPageState();
}

class _ItemFormPageState extends ConsumerState<ItemFormPage> {
  late ItemFormState _formState;
  late ItemFormState _initialFormState;
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;
  bool _hasUnsavedChanges = false;

  late final TextEditingController _nameController;
  late final TextEditingController _clayTypeController;
  late final TextEditingController _locationController;
  late final TextEditingController _glazeController;
  late final TextEditingController _coneController;
  late final TextEditingController _noteController;

  late final _MeasurementControllers _greenwareControllers;
  late final _MeasurementControllers _bisqueControllers;
  late final _MeasurementControllers _finalControllers;

  @override
  void initState() {
    super.initState();
    _formState = widget.existingItem == null
        ? ItemFormState()
        : ItemFormState.fromItem(widget.existingItem!);
    // Opening move: Save initial state to detect unsaved changes
    _initialFormState = _formState;

    _nameController = TextEditingController(text: _formState.name);
    _clayTypeController = TextEditingController(text: _formState.clayType);
    _locationController = TextEditingController(text: _formState.location);
    _glazeController = TextEditingController(text: _formState.glaze ?? '');
    _coneController = TextEditingController(text: _formState.cone ?? '');
    _noteController = TextEditingController(text: _formState.note ?? '');

    _greenwareControllers = _MeasurementControllers.fromDetail(
      _formState.greenware,
    );
    _bisqueControllers = _MeasurementControllers.fromDetail(
      _formState.bisque,
    );
    _finalControllers = _MeasurementControllers.fromDetail(
      _formState.finalMeasurement,
    );

    // Big play: Track changes on all text fields
    _nameController.addListener(_checkForChanges);
    _clayTypeController.addListener(_checkForChanges);
    _locationController.addListener(_checkForChanges);
    _glazeController.addListener(_checkForChanges);
    _coneController.addListener(_checkForChanges);
    _noteController.addListener(_checkForChanges);
    _greenwareControllers.height.addListener(_checkForChanges);
    _greenwareControllers.width.addListener(_checkForChanges);
    _greenwareControllers.depth.addListener(_checkForChanges);
    _bisqueControllers.height.addListener(_checkForChanges);
    _bisqueControllers.width.addListener(_checkForChanges);
    _bisqueControllers.depth.addListener(_checkForChanges);
    _finalControllers.height.addListener(_checkForChanges);
    _finalControllers.width.addListener(_checkForChanges);
    _finalControllers.depth.addListener(_checkForChanges);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _clayTypeController.dispose();
    _locationController.dispose();
    _glazeController.dispose();
    _coneController.dispose();
    _noteController.dispose();
    _greenwareControllers.dispose();
    _bisqueControllers.dispose();
    _finalControllers.dispose();
    super.dispose();
  }

  // Main play: Check if any field has changed from initial state
  void _checkForChanges() {
    final hasChanges = _nameController.text.trim() != (_initialFormState.name) ||
        _clayTypeController.text.trim() != (_initialFormState.clayType ?? '') ||
        _locationController.text.trim() != (_initialFormState.location ?? '') ||
        _glazeController.text.trim() != (_initialFormState.glaze ?? '') ||
        _coneController.text.trim() != (_initialFormState.cone ?? '') ||
        _noteController.text.trim() != (_initialFormState.note ?? '') ||
        _formState.currentStatus != _initialFormState.currentStatus ||
        _formState.createdDateTime != _initialFormState.createdDateTime ||
        _measurementHasChanged(_greenwareControllers, _initialFormState.greenware) ||
        _measurementHasChanged(_bisqueControllers, _initialFormState.bisque) ||
        _measurementHasChanged(_finalControllers, _initialFormState.finalMeasurement);

    if (hasChanges != _hasUnsavedChanges) {
      setState(() => _hasUnsavedChanges = hasChanges);
    }
  }

  // Victory lap: Check if measurement values have changed
  bool _measurementHasChanged(_MeasurementControllers controllers, MeasurementDetail? initial) {
    final currentHeight = controllers.height.text.trim();
    final currentWidth = controllers.width.text.trim();
    final currentDepth = controllers.depth.text.trim();

    final initialHeight = initial?.height?.toString() ?? '';
    final initialWidth = initial?.width?.toString() ?? '';
    final initialDepth = initial?.depth?.toString() ?? '';

    return currentHeight != initialHeight || currentWidth != initialWidth || currentDepth != initialDepth;
  }

  // Big play: Show unsaved changes dialog when user tries to leave
  Future<bool> _handleBackNavigation() async {
    if (!_hasUnsavedChanges || _isSubmitting) {
      return true; // Allow navigation if no changes or already submitting
    }

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unsaved Changes'),
        content: const Text('You have unsaved changes. What would you like to do?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop('cancel'),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop('discard'),
            child: const Text('Discard Changes'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop('save'),
            child: const Text('Save and Close'),
          ),
        ],
      ),
    );

    if (result == 'save') {
      // Security checkpoint: Validate and save before closing
      await _submit();
      return !mounted; // Only allow navigation if save succeeded and we unmounted
    } else if (result == 'discard') {
      return true; // Allow navigation, discard changes
    }
    return false; // Cancel, stay on page
  }

  Future<void> _selectDateTime() async {
    final contextDate = await showDatePicker(
      context: context,
      initialDate: _formState.createdDateTime,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (contextDate == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_formState.createdDateTime),
    );
    if (time == null) {
      setState(() {
        _formState = _formState.copyWith(
          createdDateTime: DateTime(
            contextDate.year,
            contextDate.month,
            contextDate.day,
            _formState.createdDateTime.hour,
            _formState.createdDateTime.minute,
          ),
        );
      });
      _checkForChanges();
      return;
    }

    setState(() {
      _formState = _formState.copyWith(
        createdDateTime: DateTime(
          contextDate.year,
          contextDate.month,
          contextDate.day,
          time.hour,
          time.minute,
        ),
      );
    });
    _checkForChanges();
  }

  MeasurementDetail? _parseMeasurement(_MeasurementControllers controllers) {
    final height = controllers.height.text.trim();
    final width = controllers.width.text.trim();
    final depth = controllers.depth.text.trim();
    if (height.isEmpty && width.isEmpty && depth.isEmpty) {
      return null;
    }
    double? parse(String value) => value.isEmpty ? null : double.tryParse(value);
    return MeasurementDetail(
      height: parse(height),
      width: parse(width),
      depth: parse(depth),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSubmitting = true);
    final repository = ref.read(itemRepositoryProvider);
    final messenger = ScaffoldMessenger.of(context);

    final updatedForm = _formState.copyWith(
      name: _nameController.text.trim(),
      clayType: _clayTypeController.text.trim().isEmpty
          ? null
          : _clayTypeController.text.trim(),
      location: _locationController.text.trim().isEmpty
          ? null
          : _locationController.text.trim(),
      glaze: _glazeController.text.trim().isEmpty
          ? null
          : _glazeController.text.trim(),
      cone: _coneController.text.trim().isEmpty
          ? null
          : _coneController.text.trim(),
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
      currentStatus: _formState.currentStatus,
      greenware: _parseMeasurement(_greenwareControllers),
      bisque: _parseMeasurement(_bisqueControllers),
      finalMeasurement: _parseMeasurement(_finalControllers),
    );

    final payload = repository.buildItemPayload(
      name: updatedForm.name,
      clayType: updatedForm.clayType,
      location: updatedForm.location,
      createdDateTime: updatedForm.createdDateTime.toUtc(),
      currentStatus: updatedForm.currentStatus,
      glaze: updatedForm.glaze,
      cone: updatedForm.cone,
      note: updatedForm.note,
      measurements: (updatedForm.greenware != null ||
              updatedForm.bisque != null ||
              updatedForm.finalMeasurement != null)
          ? updatedForm.toMeasurements()
          : null,
    );

    try {
      if (widget.existingItem == null) {
        await repository.createItem(payload);
      } else {
        await repository.updateItem(widget.existingItem!.id, payload);
      }
      if (mounted) {
        ref.invalidate(itemListProvider);
        Navigator.of(context).pop(true);
      }
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to save item: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.existingItem == null ? 'Create Pottery Item' : 'Edit Pottery Item';

    // Security checkpoint: Intercept back navigation to check for unsaved changes
    return PopScope(
      canPop: false,
      onPopInvoked: (bool didPop) async {
        if (didPop) return;
        final shouldPop = await _handleBackNavigation();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(title: Text(title)),
        body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (value) =>
                    value == null || value.trim().isEmpty ? 'Name is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _clayTypeController,
                decoration: const InputDecoration(labelText: 'Clay Type (optional)'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(labelText: 'Location (optional)'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _glazeController,
                decoration: const InputDecoration(labelText: 'Glaze (optional)'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _noteController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Notes (optional)'),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _formState.currentStatus,
                decoration: const InputDecoration(
                  labelText: 'Current Status',
                ),
                items: [
                  DropdownMenuItem(
                    value: 'greenware',
                    child: _StageDropdownItem(
                      stage: 'greenware',
                      label: 'Greenware',
                      isSelected: _formState.currentStatus == 'greenware',
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'bisque',
                    child: _StageDropdownItem(
                      stage: 'bisque',
                      label: 'Bisque',
                      isSelected: _formState.currentStatus == 'bisque',
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'final',
                    child: _StageDropdownItem(
                      stage: 'final',
                      label: 'Final',
                      isSelected: _formState.currentStatus == 'final',
                    ),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _formState = _formState.copyWith(currentStatus: value);
                    });
                    _checkForChanges();
                  }
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _coneController,
                decoration: const InputDecoration(labelText: 'Cone (optional)'),
              ),
              const SizedBox(height: 16),
              _MeasurementSection(
                title: 'Greenware measurements (optional)',
                controllers: _greenwareControllers,
              ),
              const SizedBox(height: 16),
              _MeasurementSection(
                title: 'Bisque measurements (optional)',
                controllers: _bisqueControllers,
              ),
              const SizedBox(height: 16),
              _MeasurementSection(
                title: 'Final measurements (optional)',
                controllers: _finalControllers,
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Creation date & time'),
                subtitle: Text(_formState.formattedCreatedDate()),
                trailing: IconButton(
                  icon: const Icon(Icons.calendar_today_outlined),
                  onPressed: _selectDateTime,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _isSubmitting ? null : _submit,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(_isSubmitting ? 'Saving...' : 'Save item'),
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}

class _MeasurementSection extends StatelessWidget {
  const _MeasurementSection({
    required this.title,
    required this.controllers,
  });

  final String title;
  final _MeasurementControllers controllers;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: controllers.height,
                decoration: const InputDecoration(labelText: 'Height (in)'),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: controllers.width,
                decoration: const InputDecoration(labelText: 'Width (in)'),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: controllers.depth,
                decoration: const InputDecoration(labelText: 'Depth (in)'),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MeasurementControllers {
  _MeasurementControllers({
    String? height,
    String? width,
    String? depth,
  })  : height = TextEditingController(text: height ?? ''),
        width = TextEditingController(text: width ?? ''),
        depth = TextEditingController(text: depth ?? '');

  factory _MeasurementControllers.fromDetail(MeasurementDetail? detail) {
    if (detail == null) {
      return _MeasurementControllers();
    }
    return _MeasurementControllers(
      height: detail.height?.toString(),
      width: detail.width?.toString(),
      depth: detail.depth?.toString(),
    );
  }

  final TextEditingController height;
  final TextEditingController width;
  final TextEditingController depth;

  void dispose() {
    height.dispose();
    width.dispose();
    depth.dispose();
  }
}

/// Dropdown item with circular stage indicator icon
class _StageDropdownItem extends StatelessWidget {
  const _StageDropdownItem({
    required this.stage,
    required this.label,
    required this.isSelected,
  });

  final String stage;
  final String label;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final stageColor = PotteryColors.getStageColor(stage);
    final badgeLabel = label.substring(0, 1); // G, B, or F

    return Row(
      children: [
        // Big play: Circle icon matching StageIndicator styling
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: isSelected ? stageColor : Colors.transparent,
            border: Border.all(
              color: stageColor.withOpacity(isSelected ? 1.0 : 0.5),
              width: isSelected ? 0 : 1.5,
            ),
            shape: BoxShape.circle,
            boxShadow: isSelected
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
              badgeLabel,
              style: TextStyle(
                color: isSelected ? Colors.white : stageColor,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(label),
      ],
    );
  }
}
