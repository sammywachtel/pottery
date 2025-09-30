import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../data/models/photo_upload_request.dart';
import '../../../data/repositories/item_repository.dart';
import '../controllers/stage_provider.dart';

class PhotoUploadSheet extends ConsumerStatefulWidget {
  const PhotoUploadSheet({super.key, required this.itemId});

  final String itemId;

  @override
  ConsumerState<PhotoUploadSheet> createState() => _PhotoUploadSheetState();
}

// Helper widget for photo source selection buttons
class _PhotoSourceButton extends StatelessWidget {
  const _PhotoSourceButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.4),
          ),
          color: Theme.of(context).colorScheme.surface,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 32,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoUploadSheetState extends ConsumerState<PhotoUploadSheet> {
  final _formKey = GlobalKey<FormState>();
  final _noteController = TextEditingController();
  String? _selectedStage;
  XFile? _pickedFile;
  Uint8List? _previewBytes;
  String? _contentType;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickImage({ImageSource source = ImageSource.gallery}) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      maxWidth: 2400,
      imageQuality: 90,
    );
    if (picked == null) return;

    final bytes = await picked.readAsBytes();
    setState(() {
      _pickedFile = picked;
      _previewBytes = bytes;
      _contentType = picked.mimeType ?? 'image/jpeg';
    });
  }

  Future<void> _showImageSourceOptions() async {
    final result = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              'Add photo',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Take photo'),
              subtitle: const Text('Use camera to capture new photo'),
              onTap: () => Navigator.of(context).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              subtitle: const Text('Select existing photo from gallery'),
              onTap: () => Navigator.of(context).pop(ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (result != null) {
      await _pickImage(source: result);
    }
  }

  Future<void> _submit() async {
    if (_pickedFile == null || _previewBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select an image to upload.')),
      );
      return;
    }

    if (_selectedStage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select the stage for the photo.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final repository = ref.read(itemRepositoryProvider);

    final request = PhotoUploadRequest(
      stage: _selectedStage!,
      fileName: _pickedFile!.name,
      bytes: _previewBytes!,
      contentType: _contentType ?? 'image/jpeg',
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
    );

    try {
      await repository.uploadPhoto(widget.itemId, request);
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload photo: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final stagesAsync = ref.watch(stagesProvider);

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 48,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                'Upload photo',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              stagesAsync.when(
                data: (stages) {
                  final options = stages.isEmpty
                      ? const ['Greenware', 'Bisque', 'Final']
                      : stages;
                  return DropdownButtonFormField<String>(
                    value: _selectedStage,
                    items: options
                        .map(
                          (stage) => DropdownMenuItem(
                            value: stage,
                            child: Text(stage),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedStage = value;
                      });
                    },
                    decoration: const InputDecoration(labelText: 'Stage'),
                  );
                },
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => DropdownButtonFormField<String>(
                  value: _selectedStage,
                  items: const [
                    DropdownMenuItem(value: 'Greenware', child: Text('Greenware')),
                    DropdownMenuItem(value: 'Bisque', child: Text('Bisque')),
                    DropdownMenuItem(value: 'Final', child: Text('Final')),
                  ],
                  onChanged: (value) => setState(() => _selectedStage = value),
                  decoration: const InputDecoration(labelText: 'Stage'),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _noteController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Note (optional)',
                ),
              ),
              const SizedBox(height: 16),
              // Photo preview area with enhanced options
              if (_previewBytes == null)
                // Photo selection options when no photo is selected
                Row(
                  children: [
                    Expanded(
                      child: _PhotoSourceButton(
                        icon: Icons.camera_alt_outlined,
                        label: 'Take photo',
                        onTap: () => _pickImage(source: ImageSource.camera),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _PhotoSourceButton(
                        icon: Icons.photo_library_outlined,
                        label: 'Gallery',
                        onTap: () => _pickImage(source: ImageSource.gallery),
                      ),
                    ),
                  ],
                )
              else
                // Photo preview with change option
                Stack(
                  children: [
                    GestureDetector(
                      onTap: _showImageSourceOptions,
                      child: Container(
                        height: 200,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.4),
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.memory(
                            _previewBytes!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.edit, color: Colors.white, size: 20),
                          onPressed: _showImageSourceOptions,
                          tooltip: 'Change photo',
                        ),
                      ),
                    ),
                  ],
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
                      : const Icon(Icons.cloud_upload_outlined),
                  label: Text(_isSubmitting ? 'Uploading...' : 'Upload photo'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
