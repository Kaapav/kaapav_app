// lib/widgets/attachment_picker.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../utils/logger.dart';

class AttachmentPicker extends StatelessWidget {
  final Function(String path, String type) onFilePicked;

  const AttachmentPicker({super.key, required this.onFilePicked});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildOption(
            context: context,
            icon: Icons.photo_library,
            label: 'Gallery',
            color: Colors.purple,
            onTap: () => _pickImage(context, ImageSource.gallery),
          ),
          _buildOption(
            context: context,
            icon: Icons.camera_alt,
            label: 'Camera',
            color: Colors.blue,
            onTap: () => _pickImage(context, ImageSource.camera),
          ),
          _buildOption(
            context: context,
            icon: Icons.insert_drive_file,
            label: 'Document',
            color: Colors.orange,
            onTap: () => _pickDocument(context),
          ),
        ],
      ),
    );
  }

  Widget _buildOption({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withOpacity(0.1),
        child: Icon(icon, color: color),
      ),
      title: Text(label),
      onTap: onTap,
    );
  }

  Future<void> _pickImage(BuildContext context, ImageSource source) async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: source, imageQuality: 80);
      
      if (image != null && context.mounted) {
        Navigator.pop(context);
        onFilePicked(image.path, 'image');
        AppLogger.info('📷 Image picked: ${image.path}');
      }
    } catch (e) {
      AppLogger.error('Image picker error', e);
    }
  }

  Future<void> _pickDocument(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'xlsx'],
      );
      
      if (result != null && result.files.single.path != null && context.mounted) {
        Navigator.pop(context);
        onFilePicked(result.files.single.path!, 'document');
        AppLogger.info('📄 Document picked: ${result.files.single.path}');
      }
    } catch (e) {
      AppLogger.error('Document picker error', e);
    }
  }
}

// Helper to show picker
void showAttachmentPicker(
  BuildContext context,
  Function(String path, String type) onFilePicked,
) {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => AttachmentPicker(onFilePicked: onFilePicked),
  );
}