import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:kaapav_app/config/theme.dart';
import '../../models/message.dart';
import '../../widgets/full_screen_image.dart';

class MediaGalleryScreen extends StatelessWidget {
  final List<Message> messages;
  final String chatName;

  const MediaGalleryScreen({super.key, required this.messages, required this.chatName});

  @override
  Widget build(BuildContext context) {
    final images = messages.where((m) => m.messageType == 'image' && m.mediaUrl != null && m.mediaUrl!.isNotEmpty).toList();
    final videos = messages.where((m) => m.messageType == 'video').toList();
    final docs = messages.where((m) => m.messageType == 'document').toList();

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: KaapavTheme.white,
        appBar: AppBar(
          backgroundColor: KaapavTheme.white,
          elevation: 0,
          title: Text('Media — $chatName',
              style: const TextStyle(color: KaapavTheme.dark, fontSize: 18, fontWeight: FontWeight.w600)),
          bottom: const TabBar(
            labelColor: KaapavTheme.gold,
            unselectedLabelColor: KaapavTheme.gray,
            indicatorColor: KaapavTheme.gold,
            tabs: [Tab(text: 'Images'), Tab(text: 'Videos'), Tab(text: 'Docs')],
          ),
        ),
        body: TabBarView(children: [
          _imageGrid(context, images),
          _videoList(context, videos),
          _docList(context, docs),
        ]),
      ),
    );
  }

  Widget _imageGrid(BuildContext context, List<Message> images) {
    if (images.isEmpty) return const Center(child: Text('No images', style: TextStyle(color: KaapavTheme.gray)));
    return GridView.builder(
      padding: const EdgeInsets.all(4),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 4, mainAxisSpacing: 4),
      itemCount: images.length,
      itemBuilder: (context, i) {
        final msg = images[i];
        return GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(
            builder: (_) => FullScreenImage(
              imageUrl: msg.mediaUrl!,
              caption: msg.mediaCaption,
              senderName: msg.isIncoming ? chatName : 'You',
            ),
          )),
          child: CachedNetworkImage(
            imageUrl: msg.mediaUrl!,
            fit: BoxFit.cover,
            placeholder: (_, __) => Container(color: KaapavTheme.cream),
            errorWidget: (_, __, ___) => Container(
              color: KaapavTheme.cream,
              child: const Icon(Icons.broken_image, color: KaapavTheme.grayLight),
            ),
          ),
        );
      },
    );
  }

  Widget _videoList(BuildContext context, List<Message> videos) {
    if (videos.isEmpty) return const Center(child: Text('No videos', style: TextStyle(color: KaapavTheme.gray)));
    return ListView.builder(
      itemCount: videos.length,
      itemBuilder: (_, i) {
        final msg = videos[i];
        return ListTile(
          leading: Container(
            width: 48, height: 48,
            decoration: BoxDecoration(gradient: KaapavTheme.goldGradient, borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.play_arrow, color: Colors.white),
          ),
          title: Text(msg.mediaCaption ?? 'Video', maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text(msg.timestamp ?? ''),
          trailing: const Icon(Icons.open_in_new, size: 18, color: KaapavTheme.gold),
          onTap: () {
            if (msg.mediaUrl != null) launchUrl(Uri.parse(msg.mediaUrl!), mode: LaunchMode.externalApplication);
          },
        );
      },
    );
  }

  Widget _docList(BuildContext context, List<Message> docs) {
    if (docs.isEmpty) return const Center(child: Text('No documents', style: TextStyle(color: KaapavTheme.gray)));
    return ListView.builder(
      itemCount: docs.length,
      itemBuilder: (_, i) {
        final msg = docs[i];
        return ListTile(
          leading: Container(
            width: 48, height: 48,
            decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.description, color: Colors.red),
          ),
          title: Text(msg.mediaCaption ?? 'Document', maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text(msg.timestamp ?? ''),
          trailing: const Icon(Icons.open_in_new, size: 18, color: KaapavTheme.gold),
          onTap: () {
            if (msg.mediaUrl != null) launchUrl(Uri.parse(msg.mediaUrl!), mode: LaunchMode.externalApplication);
          },
        );
      },
    );
  }
}