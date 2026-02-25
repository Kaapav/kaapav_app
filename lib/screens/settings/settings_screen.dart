// lib/screens/settings/settings_screen.dart
// ═══════════════════════════════════════════════════════════════════════════════
// KAAPAV SETTINGS SCREEN — Production Grade (Full Featured)
// ═══════════════════════════════════════════════════════════════════════════════

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/settings_provider.dart';
import '../../utils/logger.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _hasChanges = false;
  bool _saving = false;
  bool _testingWhatsApp = false;

  // Form controllers
  final _businessNameController = TextEditingController();
  final _businessPhoneController = TextEditingController();
  final _businessEmailController = TextEditingController();
  final _businessAddressController = TextEditingController();
  final _websiteUrlController = TextEditingController();
  final _instagramUrlController = TextEditingController();
  final _facebookUrlController = TextEditingController();
  final _welcomeMessageController = TextEditingController();
  final _awayMessageController = TextEditingController();

  // Toggle states
  bool _aiAutoReply = true;
  bool _autoGreeting = true;
  bool _businessHoursEnabled = false;
  String _businessHoursStart = '10:00';
  String _businessHoursEnd = '19:00';
  bool _orderConfirmation = true;
  bool _shippingNotification = true;
  bool _deliveryNotification = true;
  bool _cartRecovery = true;
  int _cartRecoveryHours = 24;
  bool _reviewRequest = false;
  bool _pushEnabled = true;
  bool _soundEnabled = true;
  String _currency = 'INR';
  String _timezone = 'Asia/Kolkata';
  String _theme = 'light';

  final _tabs = const [
    Tab(icon: Icon(Icons.store, size: 20), text: 'Business'),
    Tab(icon: Icon(Icons.chat, size: 20), text: 'WhatsApp'),
    Tab(icon: Icon(Icons.smart_toy, size: 20), text: 'Auto'),
    Tab(icon: Icon(Icons.notifications, size: 20), text: 'Alerts'),
    Tab(icon: Icon(Icons.person, size: 20), text: 'Account'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadSettings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _businessNameController.dispose();
    _businessPhoneController.dispose();
    _businessEmailController.dispose();
    _businessAddressController.dispose();
    _websiteUrlController.dispose();
    _instagramUrlController.dispose();
    _facebookUrlController.dispose();
    _welcomeMessageController.dispose();
    _awayMessageController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    await ref.read(settingsProvider.notifier).loadAll();
    final settings = ref.read(settingsProvider).settings;
    
    setState(() {
      _businessNameController.text = settings['business_name'] ?? 'KAAPAV Fashion Jewellery';
      _businessPhoneController.text = settings['business_phone'] ?? '919148330016';
      _businessEmailController.text = settings['business_email'] ?? 'kaapavin@gmail.com';
      _businessAddressController.text = settings['business_address'] ?? '';
      _websiteUrlController.text = settings['website_url'] ?? 'https://www.kaapav.com';
      _instagramUrlController.text = settings['instagram_url'] ?? '';
      _facebookUrlController.text = settings['facebook_url'] ?? '';
      _welcomeMessageController.text = settings['welcome_message'] ?? '';
      _awayMessageController.text = settings['away_message'] ?? '';
      
      _aiAutoReply = settings['ai_auto_reply'] == true || settings['ai_auto_reply'] == 'true';
      _autoGreeting = settings['auto_greeting'] == true || settings['auto_greeting'] == 'true';
      _businessHoursEnabled = settings['business_hours_enabled'] == true;
      _businessHoursStart = settings['business_hours_start'] ?? '10:00';
      _businessHoursEnd = settings['business_hours_end'] ?? '19:00';
      _orderConfirmation = settings['order_confirmation_enabled'] != false;
      _shippingNotification = settings['shipping_notification_enabled'] != false;
      _deliveryNotification = settings['delivery_notification_enabled'] != false;
      _cartRecovery = settings['cart_recovery_enabled'] == true;
      _cartRecoveryHours = settings['cart_recovery_hours'] ?? 24;
      _reviewRequest = settings['review_request_enabled'] == true;
      _pushEnabled = settings['push_enabled'] != false;
      _soundEnabled = settings['sound_enabled'] != false;
      _currency = settings['currency'] ?? 'INR';
      _timezone = settings['timezone'] ?? 'Asia/Kolkata';
      _theme = settings['theme'] ?? 'light';
    });
  }

  void _markChanged() {
    if (!_hasChanges) setState(() => _hasChanges = true);
  }

  Future<void> _saveSettings() async {
    setState(() => _saving = true);

    final data = {
      'business_name': _businessNameController.text,
      'business_phone': _businessPhoneController.text,
      'business_email': _businessEmailController.text,
      'business_address': _businessAddressController.text,
      'website_url': _websiteUrlController.text,
      'instagram_url': _instagramUrlController.text,
      'facebook_url': _facebookUrlController.text,
      'welcome_message': _welcomeMessageController.text,
      'away_message': _awayMessageController.text,
      'ai_auto_reply': _aiAutoReply,
      'auto_greeting': _autoGreeting,
      'business_hours_enabled': _businessHoursEnabled,
      'business_hours_start': _businessHoursStart,
      'business_hours_end': _businessHoursEnd,
      'order_confirmation_enabled': _orderConfirmation,
      'shipping_notification_enabled': _shippingNotification,
      'delivery_notification_enabled': _deliveryNotification,
      'cart_recovery_enabled': _cartRecovery,
      'cart_recovery_hours': _cartRecoveryHours,
      'review_request_enabled': _reviewRequest,
      'push_enabled': _pushEnabled,
      'sound_enabled': _soundEnabled,
      'currency': _currency,
      'timezone': _timezone,
      'theme': _theme,
    };

    final success = await ref.read(settingsProvider.notifier).updateSettings(data);
    
    setState(() {
      _saving = false;
      if (success) _hasChanges = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(success ? '✅ Settings saved!' : '❌ Failed to save'),
        backgroundColor: success ? Colors.green : Colors.red,
      ));
    }
  }

  Future<void> _testWhatsApp() async {
    if (_businessPhoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Set business phone first')),
      );
      return;
    }

    setState(() => _testingWhatsApp = true);
    
    final success = await ref.read(settingsProvider.notifier)
        .testWhatsApp(_businessPhoneController.text);
    
    setState(() => _testingWhatsApp = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(success ? '✅ Test message sent!' : '❌ Test failed'),
        backgroundColor: success ? Colors.green : Colors.red,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final settingsState = ref.watch(settingsProvider);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        foregroundColor: isDark ? Colors.white : const Color(0xFF1A1A1A),
        elevation: 0,
        actions: [
          if (_hasChanges) ...[
            TextButton(
              onPressed: _loadSettings,
              child: Text('Discard', style: TextStyle(color: Colors.grey[600])),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ElevatedButton(
                onPressed: _saving ? null : _saveSettings,
                style: ElevatedButton.styleFrom(
                  backgroundColor: KaapavTheme.gold,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: _saving
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Save'),
              ),
            ),
          ],
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: KaapavTheme.gold,
          labelColor: KaapavTheme.gold,
          unselectedLabelColor: Colors.grey,
          tabs: _tabs,
        ),
      ),
      body: settingsState.isLoading
          ? const Center(child: CircularProgressIndicator(color: KaapavTheme.gold))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildBusinessTab(isDark),
                _buildWhatsAppTab(isDark),
                _buildAutomationTab(isDark),
                _buildNotificationsTab(isDark),
                _buildAccountTab(isDark),
              ],
            ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════════
  // BUSINESS TAB
  // ═══════════════════════════════════════════════════════════════════════════════

  Widget _buildBusinessTab(bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSection('📊 Business Information', [
          _buildTextField('Business Name', _businessNameController, Icons.store),
          _buildTextField('Phone (with country code)', _businessPhoneController, Icons.phone,
              keyboardType: TextInputType.phone, helper: 'Format: 919876543210'),
          _buildTextField('Email', _businessEmailController, Icons.email,
              keyboardType: TextInputType.emailAddress),
          _buildTextField('Address', _businessAddressController, Icons.location_on,
              maxLines: 2),
        ], isDark),
        const SizedBox(height: 16),
        _buildSection('🌍 Regional', [
          _buildDropdown('Currency', _currency, [
            ('INR', '₹ Indian Rupee'),
            ('USD', '\$ US Dollar'),
            ('EUR', '€ Euro'),
            ('GBP', '£ British Pound'),
          ], (v) => setState(() { _currency = v; _markChanged(); })),
          _buildDropdown('Timezone', _timezone, [
            ('Asia/Kolkata', 'IST (India)'),
            ('Asia/Dubai', 'GST (Dubai)'),
            ('America/New_York', 'EST (New York)'),
            ('Europe/London', 'GMT (London)'),
          ], (v) => setState(() { _timezone = v; _markChanged(); })),
        ], isDark),
        const SizedBox(height: 16),
        _buildSection('🔗 Social Links', [
          _buildTextField('Website', _websiteUrlController, Icons.language,
              keyboardType: TextInputType.url),
          _buildTextField('Instagram', _instagramUrlController, Icons.camera_alt,
              keyboardType: TextInputType.url),
          _buildTextField('Facebook', _facebookUrlController, Icons.facebook,
              keyboardType: TextInputType.url),
        ], isDark),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════════
  // WHATSAPP TAB
  // ═══════════════════════════════════════════════════════════════════════════════

  Widget _buildWhatsAppTab(bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Connection status
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green.shade50, Colors.green.shade100],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: const Icon(Icons.chat, color: Color(0xFF25D366), size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('WhatsApp Business API',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                    Text('✅ Connected', style: TextStyle(color: Colors.green[700], fontSize: 12)),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: _testingWhatsApp ? null : _testWhatsApp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF25D366),
                  elevation: 0,
                  side: const BorderSide(color: Color(0xFF25D366)),
                ),
                child: _testingWhatsApp
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Test'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildSection('🤖 Auto-Reply', [
          _buildToggle('AI Auto-Reply', 'Automatically respond to messages', _aiAutoReply,
              (v) => setState(() { _aiAutoReply = v; _markChanged(); })),
          _buildToggle('Auto Greeting', 'Welcome message to new customers', _autoGreeting,
              (v) => setState(() { _autoGreeting = v; _markChanged(); })),
          _buildToggle('Business Hours', 'Auto-reply when away', _businessHoursEnabled,
              (v) => setState(() { _businessHoursEnabled = v; _markChanged(); })),
        ], isDark),
        if (_businessHoursEnabled) ...[
          const SizedBox(height: 16),
          _buildSection('⏰ Business Hours', [
            Row(
              children: [
                Expanded(child: _buildTimePicker('Start', _businessHoursStart,
                    (v) => setState(() { _businessHoursStart = v; _markChanged(); }))),
                const SizedBox(width: 16),
                Expanded(child: _buildTimePicker('End', _businessHoursEnd,
                    (v) => setState(() { _businessHoursEnd = v; _markChanged(); }))),
              ],
            ),
            const SizedBox(height: 12),
            _buildTextField('Away Message', _awayMessageController, Icons.schedule, maxLines: 2),
          ], isDark),
        ],
        const SizedBox(height: 16),
        _buildSection('💬 Templates', [
          _buildTextField('Welcome Message', _welcomeMessageController, Icons.waving_hand, maxLines: 3),
        ], isDark),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════════
  // AUTOMATION TAB
  // ═══════════════════════════════════════════════════════════════════════════════

  Widget _buildAutomationTab(bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSection('📦 Order Automation', [
          _buildToggle('Order Confirmation', 'Auto-send when order placed', _orderConfirmation,
              (v) => setState(() { _orderConfirmation = v; _markChanged(); })),
          _buildToggle('Shipping Updates', 'Notify when shipped', _shippingNotification,
              (v) => setState(() { _shippingNotification = v; _markChanged(); })),
          _buildToggle('Delivery Confirmation', 'Notify when delivered', _deliveryNotification,
              (v) => setState(() { _deliveryNotification = v; _markChanged(); })),
        ], isDark),
        const SizedBox(height: 16),
        _buildSection('🎯 Engagement', [
          _buildToggle('Cart Recovery', 'Remind about abandoned carts', _cartRecovery,
              (v) => setState(() { _cartRecovery = v; _markChanged(); })),
          if (_cartRecovery)
            Padding(
              padding: const EdgeInsets.only(left: 48, top: 8),
              child: _buildDropdown('Reminder after', '$_cartRecoveryHours hours', [
                ('6', '6 hours'),
                ('12', '12 hours'),
                ('24', '24 hours'),
                ('48', '48 hours'),
              ], (v) => setState(() { _cartRecoveryHours = int.parse(v); _markChanged(); })),
            ),
          _buildToggle('Review Requests', 'Ask for reviews after delivery', _reviewRequest,
              (v) => setState(() { _reviewRequest = v; _markChanged(); })),
        ], isDark),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════════
  // NOTIFICATIONS TAB
  // ═══════════════════════════════════════════════════════════════════════════════

  Widget _buildNotificationsTab(bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSection('📱 App Notifications', [
          _buildToggle('Push Notifications', 'Browser/App push alerts', _pushEnabled,
              (v) => setState(() { _pushEnabled = v; _markChanged(); })),
          _buildToggle('Sound Alerts', 'Play sound for new messages', _soundEnabled,
              (v) => setState(() { _soundEnabled = v; _markChanged(); })),
        ], isDark),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.orange[700]),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'FCM Push Notifications require Firebase setup. Coming soon!',
                  style: TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════════
  // ACCOUNT TAB
  // ═══════════════════════════════════════════════════════════════════════════════

  Widget _buildAccountTab(bool isDark) {
    final user = ref.watch(authProvider).user;
    final auth = ref.watch(authProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Profile card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: KaapavTheme.goldGradient,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: Colors.white24,
                child: Text(
                  (user?.name ?? 'A')[0].toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user?.name ?? 'Admin',
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                    Text(user?.email ?? '',
                        style: const TextStyle(color: Colors.white70, fontSize: 13)),
                    Container(
                      margin: const EdgeInsets.only(top: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        user?.role == 'admin' ? '👑 Admin' : '👤 User',
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _buildSection('🔐 Security', [
          _SettingsTile(
            icon: Icons.pin,
            title: 'Setup PIN',
            subtitle: 'Change your app PIN',
            onTap: () => _showPINSetup(),
          ),
          _SettingsTile(
            icon: Icons.fingerprint,
            title: 'Biometric Lock',
            subtitle: auth.biometricAvailable ? 'Enabled' : 'Tap to enable',
            trailing: Switch(
              value: auth.biometricAvailable,
              onChanged: (v) async {
                if (v) {
                  await ref.read(authProvider.notifier).enableBiometric();
                } else {
                  await ref.read(authProvider.notifier).disableBiometric();
                }
              },
              activeColor: KaapavTheme.gold,
            ),
            onTap: () async {
              if (!auth.biometricAvailable) {
                await ref.read(authProvider.notifier).enableBiometric();
              }
            },
          ),
        ], isDark),
        const SizedBox(height: 16),
        _buildSection('🎨 Appearance', [
          _buildDropdown('Theme', _theme, [
            ('light', '☀️ Light'),
            ('dark', '🌙 Dark'),
            ('auto', '🔄 Auto'),
          ], (v) => setState(() { _theme = v; _markChanged(); })),
        ], isDark),
        const SizedBox(height: 24),
        // Logout button
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.red.shade200, width: 2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
            onTap: () => _logout(),
          ),
        ),
        const SizedBox(height: 24),
        Center(
          child: Text(
            'KAAPAV Business Suite v1.0.0\nBuilt with ❤️',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[500], fontSize: 12),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════════
  // HELPER WIDGETS
  // ═══════════════════════════════════════════════════════════════════════════════

  Widget _buildSection(String title, List<Widget> children, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon,
      {TextInputType? keyboardType, int maxLines = 1, String? helper}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            onChanged: (_) => _markChanged(),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, size: 20, color: KaapavTheme.gold),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            ),
          ),
          if (helper != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(helper, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
            ),
        ],
      ),
    );
  }

  Widget _buildToggle(String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: KaapavTheme.gold,
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown(String label, String value, List<(String, String)> options,
      ValueChanged<String> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(10),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: options.any((o) => o.$1 == value) ? value : options.first.$1,
                isExpanded: true,
                items: options.map((o) => DropdownMenuItem(value: o.$1, child: Text(o.$2))).toList(),
                onChanged: (v) => onChanged(v!),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimePicker(String label, String value, ValueChanged<String> onChanged) {
    return GestureDetector(
      onTap: () async {
        final parts = value.split(':');
        final time = await showTimePicker(
          context: context,
          initialTime: TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1])),
        );
        if (time != null) {
          onChanged('${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}');
        }
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            const Icon(Icons.access_time, size: 20, color: KaapavTheme.gold),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showPINSetup() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Set New PIN'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          obscureText: true,
          maxLength: 6,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 24, letterSpacing: 8),
          decoration: const InputDecoration(hintText: '••••'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.length >= 4) {
                Navigator.pop(ctx);
                await ref.read(authProvider.notifier).setupPIN(controller.text);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('✅ PIN updated!'), backgroundColor: Colors.green),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: KaapavTheme.gold),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: Text(_hasChanges
            ? 'You have unsaved changes. Logout anyway?'
            : 'Are you sure you want to logout?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(authProvider.notifier).logout();
              if (mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.login, (_) => false);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SETTINGS TILE WIDGET
// ═══════════════════════════════════════════════════════════════════════════════

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: KaapavTheme.gold.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: KaapavTheme.gold, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: subtitle != null ? Text(subtitle!, style: const TextStyle(fontSize: 12)) : null,
      trailing: trailing ?? const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }
}