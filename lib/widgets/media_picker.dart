// lib/widgets/media_picker.dart
// ═══════════════════════════════════════════════════════════════
// MEDIA PICKER — Bottom sheet for selecting images/documents
// ═══════════════════════════════════════════════════════════════

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../config/theme.dart';
import '../config/constants.dart';
import '../utils/logger.dart';

class MediaPickerResult {
  final File file;
  final String type; // 'image', 'document', 'video'
  final String? mimeType;
  final String fileName;
  final int fileSize;

  MediaPickerResult({
    required this.file,
    required this.type,
    this.mimeType,
    required this.fileName,
    required this.fileSize,
  });

  bool get isImage => type == 'image';
  bool get isDocument => type == 'document';
  bool get isVideo => type == 'video';
}

class MediaPicker extends StatelessWidget {
  final Function(MediaPickerResult result) onSelected;
  final VoidCallback? onCancel;
  final bool allowImages;
  final bool allowDocuments;
  final bool allowCamera;

  const MediaPicker({
    super.key,
    required this.onSelected,
    this.onCancel,
    this.allowImages = true,
    this.allowDocuments = true,
    this.allowCamera = true,
  });

  static Future<MediaPickerResult?> show(
    BuildContext context, {
    bool allowImages = true,
    bool allowDocuments = true,
    bool allowCamera = true,
  }) async {
    MediaPickerResult? result;

    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => MediaPicker(
        allowImages: allowImages,
        allowDocuments: allowDocuments,
        allowCamera: allowCamera,
        onSelected: (r) {
          result = r;
          Navigator.pop(ctx);
        },
        onCancel: () => Navigator.pop(ctx),
      ),
    );

    return result;
  }

  Future<void> _pickFromCamera(BuildContext context) async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );

      if (image != null) {
        final file = File(image.path);
        final stat = await file.stat();

        if (stat.size > AppConstants.maxImageSize) {
          _showSizeError(context, 'Image', AppConstants.maxImageSize);
          return;
        }

        onSelected(MediaPickerResult(
          file: file,
          type: 'image',
          mimeType: 'image/jpeg',
          fileName: image.name,
          fileSize: stat.size,
        ));
      }
    } catch (e) {
      AppLogger.error('Camera pick failed', e);
      _showError(context, 'Failed to open camera');
    }
  }

  Future<void> _pickFromGallery(BuildContext context) async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );

      if (image != null) {
        final file = File(image.path);
        final stat = await file.stat();

        if (stat.size > AppConstants.maxImageSize) {
          _showSizeError(context, 'Image', AppConstants.maxImageSize);
          return;
        }

        onSelected(MediaPickerResult(
          file: file,
          type: 'image',
          mimeType: _getMimeType(image.name),
          fileName: image.name,
          fileSize: stat.size,
        ));
      }
    } catch (e) {
      AppLogger.error('Gallery pick failed', e);
      _showError(context, 'Failed to open gallery');
    }
  }

  Future<void> _pickDocument(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'txt', 'csv', 'zip'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final pickedFile = result.files.first;

        if (pickedFile.path == null) {
          _showError(context, 'Failed to get file path');
          return;
        }

        final file = File(pickedFile.path!);
        final fileSize = pickedFile.size;

        if (fileSize > AppConstants.maxDocSize) {
          _showSizeError(context, 'Document', AppConstants.maxDocSize);
          return;
        }

        onSelected(MediaPickerResult(
          file: file,
          type: 'document',
          mimeType: _getMimeType(pickedFile.name),
          fileName: pickedFile.name,
          fileSize: fileSize,
        ));
      }
    } catch (e) {
      AppLogger.error('Document pick failed', e);
      _showError(context, 'Failed to pick document');
    }
  }

  String _getMimeType(String filename) {
    final ext = filename.split('.').last.toLowerCase();
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'xls':
        return 'application/vnd.ms-excel';
      case 'xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case 'txt':
        return 'text/plain';
      case 'csv':
        return 'text/csv';
      case 'zip':
        return 'application/zip';
      default:
        return 'application/octet-stream';
    }
  }

  void _showSizeError(BuildContext context, String type, int maxSize) {
    final maxMB = (maxSize / (1024 * 1024)).toStringAsFixed(0);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$type size must be less than ${maxMB}MB'),
        backgroundColor: KaapavTheme.error,
      ),
    );
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: KaapavTheme.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: KaapavTheme.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            // Title
            const Text(
              'Share',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: KaapavTheme.dark,
              ),
            ),
            const SizedBox(height: 24),

            // Options
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  if (allowCamera)
                    _buildOption(
                      context,
                      icon: Icons.camera_alt,
                      label: 'Camera',
                      color: KaapavTheme.gold,
                      onTap: () => _pickFromCamera(context),
                    ),
                  if (allowImages)
                    _buildOption(
                      context,
                      icon: Icons.photo_library,
                      label: 'Gallery',
                      color: KaapavTheme.purple,
                      onTap: () => _pickFromGallery(context),
                    ),
                  if (allowDocuments)
                    _buildOption(
                      context,
                      icon: Icons.insert_drive_file,
                      label: 'Document',
                      color: KaapavTheme.info,
                      onTap: () => _pickDocument(context),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildOption(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: KaapavTheme.dark,
            ),
          ),
        ],
      ),
    );
  }
}