import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/measurement_detail.dart';
import '../../../data/models/pottery_item.dart';
import '../../../data/repositories/item_repository.dart';
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
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;

  late final TextEditingController _nameController;
  late final TextEditingController _clayTypeController;
  late final TextEditingController _locationController;
  late final TextEditingController _glazeController;
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

    _nameController = TextEditingController(text: _formState.name);
    _clayTypeController = TextEditingController(text: _formState.clayType);
    _locationController = TextEditingController(text: _formState.location);
    _glazeController = TextEditingController(text: _formState.glaze ?? '');
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
  }

  @override
  void dispose() {
    _nameController.dispose();
    _clayTypeController.dispose();
    _locationController.dispose();
    _glazeController.dispose();
    _noteController.dispose();
    _greenwareControllers.dispose();
    _bisqueControllers.dispose();
    _finalControllers.dispose();
    super.dispose();
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
      clayType: _clayTypeController.text.trim(),
      location: _locationController.text.trim(),
      glaze: _glazeController.text.trim().isEmpty
          ? null
          : _glazeController.text.trim(),
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

    return Scaffold(
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
              _ClayTypeSelector(
                initialValue: _formState.clayType,
                onChanged: (value) {
                  _clayTypeController.text = value;
                  setState(() {
                    _formState = _formState.copyWith(clayType: value);
                  });
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(labelText: 'Location'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Location is required'
                    : null,
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
                items: const [
                  DropdownMenuItem(value: 'greenware', child: Text('Greenware')),
                  DropdownMenuItem(value: 'bisque', child: Text('Bisque')),
                  DropdownMenuItem(value: 'final', child: Text('Final')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _formState = _formState.copyWith(currentStatus: value);
                    });
                  }
                },
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

class _ClayTypeSelector extends StatefulWidget {
  const _ClayTypeSelector({
    required this.initialValue,
    required this.onChanged,
  });

  final String initialValue;
  final ValueChanged<String> onChanged;

  @override
  State<_ClayTypeSelector> createState() => _ClayTypeSelectorState();
}

class _ClayTypeSelectorState extends State<_ClayTypeSelector> {
  static const List<String> _predefinedClayTypes = [
    'Stoneware',
    'Earthenware',
    'Porcelain',
    'Raku',
    'Terra Cotta',
    'Fire Clay',
    'Ball Clay',
    'Paper Clay',
  ];

  late String _selectedValue;
  bool _isCustom = false;
  final TextEditingController _customController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedValue = widget.initialValue;
    _isCustom = !_predefinedClayTypes.contains(_selectedValue);
    if (_isCustom) {
      _customController.text = _selectedValue;
    }
  }

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  void _handleChange(String value) {
    setState(() {
      _selectedValue = value;
      _isCustom = value == 'custom';
      if (!_isCustom) {
        _customController.clear();
      }
    });
    widget.onChanged(_isCustom ? _customController.text : value);
  }

  @override
  Widget build(BuildContext context) {
    final List<DropdownMenuItem<String>> items = [
      ..._predefinedClayTypes.map(
        (type) => DropdownMenuItem(value: type, child: Text(type)),
      ),
      const DropdownMenuItem(
        value: 'custom',
        child: Text('Other (specify)'),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          value: _isCustom ? 'custom' : _selectedValue,
          decoration: const InputDecoration(
            labelText: 'Clay Type',
          ),
          items: items,
          onChanged: (value) {
            if (value != null) {
              _handleChange(value);
            }
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Clay type is required';
            }
            if (value == 'custom' && _customController.text.trim().isEmpty) {
              return 'Please specify the clay type';
            }
            return null;
          },
        ),
        if (_isCustom) ...[
          const SizedBox(height: 8),
          TextFormField(
            controller: _customController,
            decoration: const InputDecoration(
              labelText: 'Specify clay type',
              hintText: 'Enter custom clay type',
            ),
            onChanged: (value) {
              widget.onChanged(value);
            },
            validator: (value) {
              if (_isCustom && (value == null || value.trim().isEmpty)) {
                return 'Please specify the clay type';
              }
              return null;
            },
          ),
        ],
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
