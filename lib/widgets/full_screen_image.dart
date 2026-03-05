import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photo_view/photo_view.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:gal/gal.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:kaapav_app/config/theme.dart';

class FullScreenImage extends StatefulWidget {
  final String imageUrl;
  final String? caption;
  final String? senderName;
  final String? timestamp;

  const FullScreenImage({
    super.key,
    required this.imageUrl,
    this.caption,
    this.senderName,
    this.timestamp,
  });

  @override
  State<FullScreenImage> createState() => _FullScreenImageState();
}

class _FullScreenImageState extends State<FullScreenImage> {
  bool _showControls = true;
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () => setState(() => _showControls = !_showControls),
        child: Stack(
          children: [
            Center(
              child: PhotoView(
                imageProvider: CachedNetworkImageProvider(widget.imageUrl),
                minScale: PhotoViewComputedScale.contained,
                maxScale: PhotoViewComputedScale.covered * 3,
                backgroundDecoration: const BoxDecoration(color: Colors.black),
                loadingBuilder: (_, event) => Center(
                  child: CircularProgressIndicator(
                    value: event != null && event.expectedTotalBytes != null
                        ? event.cumulativeBytesLoaded / event.expectedTotalBytes!
                        : null,
                    valueColor: const AlwaysStoppedAnimation(KaapavTheme.gold),
                  ),
                ),
                errorBuilder: (_, __, ___) => const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.broken_image, color: Colors.white54, size: 64),
                    SizedBox(height: 16),
                    Text('Failed to load', style: TextStyle(color: Colors.white54)),
                  ],
                ),
              ),
            ),
            if (_showControls) ...[
              Positioned(
                top: 0, left: 0, right: 0,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.black54, Colors.transparent],
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back, color: Colors.white),
                            onPressed: () => Navigator.pop(context),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (widget.senderName != null)
                                  Text(widget.senderName!,
                                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                                if (widget.timestamp != null)
                                  Text(widget.timestamp!,
                                      style: const TextStyle(color: Colors.white70, fontSize: 12)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0, left: 0, right: 0,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Colors.black54, Colors.transparent],
                    ),
                  ),
                  child: SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.caption != null && widget.caption!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Text(widget.caption!,
                                style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.4)),
                          ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _actionBtn(Icons.share, 'Share', _share),
                              _actionBtn(
                                _saving ? Icons.hourglass_top : Icons.download,
                                _saving ? 'Saving...' : 'Save',
                                _saving ? null : _save,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _actionBtn(IconData icon, String label, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      HapticFeedback.lightImpact();
      final hasAccess = await Gal.hasAccess(toAlbum: true);
      if (!hasAccess) {
        final granted = await Gal.requestAccess(toAlbum: true);
        if (!granted) {
          _snack('Gallery permission denied');
          return;
        }
      }
      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/KAAPAV_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await Dio().download(widget.imageUrl, filePath);
      await Gal.putImage(filePath, album: 'KAAPAV');
      try { await File(filePath).delete(); } catch (_) {}
      _snack('✅ Saved to gallery');
    } catch (e) {
      _snack('Failed to save: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _share() async {
    try {
      HapticFeedback.lightImpact();
      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/KAAPAV_share_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await Dio().download(widget.imageUrl, filePath);
      await Share.shareXFiles([XFile(filePath)], text: widget.caption);
    } catch (e) {
      _snack('Failed to share: $e');
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}