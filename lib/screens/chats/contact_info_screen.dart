import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:kaapav_app/config/theme.dart';
import '../../providers/chat_provider.dart';
import '../../providers/message_provider.dart';
import 'media_gallery_screen.dart';

class ContactInfoScreen extends ConsumerWidget {
  final String phone;
  const ContactInfoScreen({super.key, required this.phone});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chat = ref.watch(chatProvider).getChatByPhone(phone);
    final customer = ref.watch(currentCustomerProvider);
    final messages = ref.watch(messagesForPhoneProvider(phone));
    final name = chat?.customerName ?? customer?.name ?? phone;
    final isPinned = ref.watch(chatProvider).pinnedChats.contains(phone);
    final isMuted = ref.watch(chatProvider).mutedChats.contains(phone);
    final isBlocked = chat?.isBlocked ?? false;

    final imageCount = messages.where((m) => m.messageType == 'image' && m.mediaUrl != null).length;
    final docCount = messages.where((m) => m.messageType == 'document').length;

    return Scaffold(
      backgroundColor: KaapavTheme.white,
      appBar: AppBar(backgroundColor: KaapavTheme.white, elevation: 0,
        title: const Text('Contact Info', style: TextStyle(color: KaapavTheme.dark))),
      body: ListView(
        children: [
          const SizedBox(height: 20),
          // Avatar
          Center(child: CircleAvatar(radius: 50, backgroundColor: KaapavTheme.gold,
            child: Text(_initials(name), style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)))),
          const SizedBox(height: 12),
          Center(child: Text(name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: KaapavTheme.dark))),
          Center(child: Text(phone, style: const TextStyle(fontSize: 14, color: KaapavTheme.gray))),
          if (customer?.segment != null)
            Center(child: Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(color: KaapavTheme.gold.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
              child: Text((customer?.segment ?? "").toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: KaapavTheme.gold)),
            )),
          const SizedBox(height: 24),

          // Quick actions
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            _actionBtn(Icons.chat, 'Message', () => Navigator.pop(context)),
            _actionBtn(Icons.call, 'Call', () => launchUrl(Uri.parse('tel:$phone'))),
            _actionBtn(Icons.videocam, 'Video', () {}),
            _actionBtn(Icons.search, 'Search', () {}),
          ]),
          const Divider(height: 32),

          // Info section
          if (customer != null) ...[
            if (customer.email != null) _infoTile(Icons.email, 'Email', customer.email!),
            if (customer.city != null) _infoTile(Icons.location_on, 'Location', '${customer.city}, ${customer.state ?? ""}'),
            _infoTile(Icons.shopping_bag, 'Orders', '${customer.orderCount}'),
            _infoTile(Icons.currency_rupee, 'Total Spent', '₹${customer.totalSpent}'),
            _infoTile(Icons.calendar_today, 'First Seen', customer.firstSeen ?? 'Unknown'),
            const Divider(height: 24),
          ],

          // Media & Docs
          ListTile(
            leading: const Icon(Icons.photo_library, color: KaapavTheme.gold),
            title: const Text('Media, Docs & Links'),
            trailing: Text('$imageCount photos, $docCount docs', style: const TextStyle(color: KaapavTheme.gray, fontSize: 12)),
            onTap: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => MediaGalleryScreen(messages: messages, chatName: name))),
          ),
          const Divider(height: 8),

          // Toggle actions
          SwitchListTile(
            secondary: const Icon(Icons.push_pin, color: KaapavTheme.gold),
            title: const Text('Pin Chat'),
            value: isPinned,
            activeThumbColor: KaapavTheme.gold,
            onChanged: (_) => ref.read(chatProvider.notifier).togglePin(phone),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.notifications_off, color: KaapavTheme.gold),
            title: const Text('Mute Notifications'),
            value: isMuted,
            activeThumbColor: KaapavTheme.gold,
            onChanged: (_) => ref.read(chatProvider.notifier).toggleMute(phone),
          ),
          const Divider(height: 8),

          // Block
          ListTile(
            leading: Icon(isBlocked ? Icons.block : Icons.block_outlined,
                color: isBlocked ? KaapavTheme.error : KaapavTheme.gray),
            title: Text(isBlocked ? 'Unblock $name' : 'Block $name',
                style: TextStyle(color: isBlocked ? KaapavTheme.error : KaapavTheme.dark)),
            onTap: () {
              showDialog(context: context, builder: (ctx) => AlertDialog(
                title: Text(isBlocked ? 'Unblock?' : 'Block?'),
                content: Text(isBlocked ? 'Allow messages from $name?' : 'Block all messages from $name?'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                  TextButton(
                    onPressed: () { Navigator.pop(ctx); ref.read(chatProvider.notifier).toggleBlock(phone); },
                    child: Text(isBlocked ? 'Unblock' : 'Block', style: const TextStyle(color: KaapavTheme.error)),
                  ),
                ],
              ));
            },
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  String _initials(String n) {
    final p = n.trim().split(' ');
    if (p.length == 1) return p[0].substring(0, 1).toUpperCase();
    return '${p[0][0]}${p.last[0]}'.toUpperCase();
  }

  Widget _actionBtn(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(onTap: onTap, child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 48, height: 48, decoration: BoxDecoration(color: KaapavTheme.gold.withValues(alpha: 0.1), shape: BoxShape.circle),
        child: Icon(icon, color: KaapavTheme.gold, size: 22)),
      const SizedBox(height: 4),
      Text(label, style: const TextStyle(fontSize: 12, color: KaapavTheme.gray)),
    ]));
  }

  Widget _infoTile(IconData icon, String label, String value) {
    return ListTile(
      leading: Icon(icon, color: KaapavTheme.gold, size: 20),
      title: Text(label, style: const TextStyle(fontSize: 13, color: KaapavTheme.gray)),
      subtitle: Text(value, style: const TextStyle(fontSize: 15, color: KaapavTheme.dark, fontWeight: FontWeight.w500)),
      dense: true,
    );
  }
}


