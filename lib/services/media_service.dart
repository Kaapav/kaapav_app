// lib/services/media_service.dart
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:http_parser/http_parser.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';	
import '../utils/logger.dart';
import '../config/constants.dart';

class MediaService {
  static final ImagePicker _imagePicker = ImagePicker();
  static const _storage = FlutterSecureStorage();

 // ═══════════════════════════════════════════════════════════════
  // TOKEN HELPER
  // ═══════════════════════════════════════════════════════════════

  static Future<String?> _getToken() async {  
    return await _storage.read(key: 'auth_token');
  }

  // ═══════════════════════════════════════════════════════════
  // PERMISSIONS
  // ═══════════════════════════════════════════════════════════

  static Future<bool> _requestCameraPermission() async {
    if (Platform.isAndroid) {
      final status = await Permission.camera.request();
      if (status.isGranted) return true;
      if (status.isPermanentlyDenied) await openAppSettings();
      return false;
    }
    return true;
  }

  static Future<bool> _requestStoragePermission() async {
    if (Platform.isAndroid) {
      final photos = await Permission.photos.request();
      if (photos.isGranted) return true;
      
      final storage = await Permission.storage.request();
      if (storage.isGranted) return true;
      
      if (photos.isPermanentlyDenied || storage.isPermanentlyDenied) {
        await openAppSettings();
      }
      return false;
    }
    return true;
  }

  // ═══════════════════════════════════════════════════════════
  // PICK IMAGE
  // ═══════════════════════════════════════════════════════════

  static Future<File?> pickImage({ImageSource source = ImageSource.gallery}) async {
    try {
      if (source == ImageSource.camera) {
        if (!await _requestCameraPermission()) {
          AppLogger.warn('Camera permission denied');
          return null;
        }
      } else {
        if (!await _requestStoragePermission()) {
          AppLogger.warn('Storage permission denied');
          return null;
        }
      }

      final picked = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (picked == null) return null;

      // Save to app storage
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${path.basename(picked.path)}';
      final savedPath = path.join(appDir.path, 'media', fileName);
      
      final savedDir = Directory(path.dirname(savedPath));
      if (!await savedDir.exists()) {
        await savedDir.create(recursive: true);
      }

      final file = await File(picked.path).copy(savedPath);
      final size = await file.length();

      if (size > AppConstants.maxImageSize) {
        AppLogger.warn('Image too large: ${size ~/ 1024}KB');
        await file.delete();
        return null;
      }

      AppLogger.info('✅ Image saved: ${path.basename(savedPath)} (${size ~/ 1024}KB)');
      return file;
    } catch (e) {
      AppLogger.error('❌ Image pick failed', e);
      return null;
    }
  }

  static Future<File?> takePhoto() => pickImage(source: ImageSource.camera);
  static Future<File?> pickFromGallery() => pickImage(source: ImageSource.gallery);

  // ═══════════════════════════════════════════════════════════
  // PICK DOCUMENT
  // ═══════════════════════════════════════════════════════════

  static Future<File?> pickDocument() async {
    try {
      if (!await _requestStoragePermission()) {
        AppLogger.warn('Storage permission denied');
        return null;
      }

      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx', 'txt'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty || result.files.single.path == null) {
        return null;
      }

      final appDir = await getApplicationDocumentsDirectory();
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${result.files.single.name}';
      final savedPath = path.join(appDir.path, 'media', fileName);
      
      final savedDir = Directory(path.dirname(savedPath));
      if (!await savedDir.exists()) {
        await savedDir.create(recursive: true);
      }

      final file = await File(result.files.single.path!).copy(savedPath);
      final size = await file.length();

      if (size > AppConstants.maxDocSize) {
        AppLogger.warn('Document too large: ${size ~/ 1024}KB');
        await file.delete();
        return null;
      }

      AppLogger.info('✅ Document saved: ${result.files.single.name} (${size ~/ 1024}KB)');
      return file;
    } catch (e) {
      AppLogger.error('❌ Document pick failed', e);
      return null;
    }
  }

  // ═══════════════════════════════════════════════════════════
  // PICK VIDEO
  // ═══════════════════════════════════════════════════════════

  static Future<File?> pickVideo() async {
    try {
      if (!await _requestStoragePermission()) {
        AppLogger.warn('Storage permission denied');
        return null;
      }

      final picked = await _imagePicker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 3),
      );

      if (picked == null) return null;

      final appDir = await getApplicationDocumentsDirectory();
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${path.basename(picked.path)}';
      final savedPath = path.join(appDir.path, 'media', fileName);
      
      final savedDir = Directory(path.dirname(savedPath));
      if (!await savedDir.exists()) {
        await savedDir.create(recursive: true);
      }

      final file = await File(picked.path).copy(savedPath);
      final size = await file.length();

      if (size > AppConstants.maxVideoSize) {
        AppLogger.warn('Video too large: ${size ~/ 1024}KB');
        await file.delete();
        return null;
      }

      AppLogger.info('✅ Video saved: ${path.basename(savedPath)} (${size ~/ 1024}KB)');
      return file;
    } catch (e) {
      AppLogger.error('❌ Video pick failed', e);
      return null;
    }
  }

  // ═══════════════════════════════════════════════════════════
  // UPLOAD FILE - Returns local file path (not uploading anywhere)
  // ═══════════════════════════════════════════════════════════

 static Future<String?> uploadFile(
  File file, {
  String type = 'image',
  String? phone,
}) async {
  try {
    final token = await _getToken();
    if (token == null) {
      AppLogger.error('❌ Upload failed: No auth token');
      return null;
    }

    final fileName = path.basename(file.path);
    final mimeType = _getMimeType(fileName);
    final fileSize = await file.length();

    AppLogger.info('📤 Uploading: $fileName (${fileSize ~/ 1024}KB) type=$type');

    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        file.path,
        filename: fileName,
        contentType: MediaType.parse(mimeType),
      ),
      if (phone != null) 'phone': phone,
      'type': type,
    });

    final dio = Dio(BaseOptions(
      baseUrl: AppConstants.apiBaseUrl,
      connectTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(seconds: 30),
    ));

    final response = await dio.post(
      '/api/media/upload',
      data: formData,
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
        },
      ),
      onSendProgress: (sent, total) {
        final percent = ((sent / total) * 100).toStringAsFixed(0);
        AppLogger.info('📤 Upload progress: $percent%');
      },
    );

    if (response.statusCode == 200 && response.data['success'] == true) {
      final url = response.data['url']
          ?? response.data['mediaUrl']
          ?? response.data['fileName'];
      AppLogger.success('✅ Upload complete: $url');
      return url as String?;
    }

    AppLogger.error('❌ Upload failed: ${response.data}');
    return null;
  } on DioException catch (e) {
    if (e.type == DioExceptionType.connectionTimeout) {
      AppLogger.error('❌ Upload timeout - file too large or slow network');
    } else if (e.type == DioExceptionType.sendTimeout) {
      AppLogger.error('❌ Upload send timeout');
    } else if (e.response?.statusCode == 401) {
      AppLogger.error('❌ Upload unauthorized - token expired');
    } else if (e.response?.statusCode == 413) {
      AppLogger.error('❌ File too large for server');
    } else {
      AppLogger.error('❌ Upload error: ${e.message}');
    }
    return null;
  } catch (e) {
    AppLogger.error('❌ Upload failed', e);
    return null;
  }
}

static String _getMimeType(String filename) {
  final ext = path.extension(filename).toLowerCase();
  switch (ext) {
    case '.jpg':
    case '.jpeg':
      return 'image/jpeg';
    case '.png':
      return 'image/png';
    case '.gif':
      return 'image/gif';
    case '.webp':
      return 'image/webp';
    case '.pdf':
      return 'application/pdf';
    case '.doc':
      return 'application/msword';
    case '.docx':
      return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
    case '.mp4':
      return 'video/mp4';
    case '.mp3':
      return 'audio/mpeg';
    case '.ogg':
      return 'audio/ogg';
    default:
      return 'application/octet-stream';
  }
}

  // ═══════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════

  static String getFileExtension(String filePath) {
    return path.extension(filePath).toLowerCase().replaceAll('.', '');
  }

  static bool isImage(String filePath) {
    return ['jpg', 'jpeg', 'png', 'webp', 'gif'].contains(getFileExtension(filePath));
  }

  static bool isDocument(String filePath) {
    return ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx', 'txt'].contains(getFileExtension(filePath));
  }

  static bool isVideo(String filePath) {
    return ['mp4', 'mov', 'avi', 'mkv'].contains(getFileExtension(filePath));
  }
}