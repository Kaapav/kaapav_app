// lib/screens/login_screen.dart
// ═══════════════════════════════════════════════════════════════════════════════
// KAAPAV LOCK SCREEN — Production Grade
// ═══════════════════════════════════════════════════════════════════════════════
// Premium lock screen with PIN + Biometric authentication
// WhatsApp-inspired UI with KAAPAV gold luxury theme
// ═══════════════════════════════════════════════════════════════════════════════

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/routes.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';

const int _pinLength = 4;

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _pin = [];
  Timer? _lockoutTimer;
  bool _initialBiometricTriggered = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _lockoutTimer?.cancel();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // AUTO-TRIGGER BIOMETRIC ON FIRST BUILD
  // ─────────────────────────────────────────────────────────────────────────────

void _maybeAutoTriggerBiometric(AuthState auth) {
  if (_initialBiometricTriggered) return;
  if (auth.status != AuthStatus.locked) return;

  _initialBiometricTriggered = true;

  if (!auth.biometricAvailable) {
    // No biometric → go to PIN tab
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _tabController.animateTo(1);
    });
    return;
  }

  // ✅ AUTO-TRIGGER biometric
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (mounted) {
      _tabController.animateTo(0); // Fingerprint tab
      
      Future.delayed(const Duration(milliseconds: 500), () {
        if (!mounted) return;
        
        final currentAuth = ref.read(authProvider);
        if (currentAuth.status == AuthStatus.locked && !currentAuth.isLoading) {
          _tryBiometric();
        }
      });
    }
  });
}

  // ─────────────────────────────────────────────────────────────────────────────
  // BIOMETRIC AUTHENTICATION
  // ─────────────────────────────────────────────────────────────────────────────

  Future<void> _tryBiometric() async {
    final success = await ref.read(authProvider.notifier).unlockWithBiometric();
    if (!mounted) return;

    if (success) {
      _navigateToHome();
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // PIN INPUT HANDLING
  // ─────────────────────────────────────────────────────────────────────────────

  Future<void> _onDigit(String digit) async {
    final auth = ref.read(authProvider);
    if (auth.isLoading || auth.isLockedOut || _pin.length >= _pinLength) return;

    HapticFeedback.lightImpact();
    setState(() => _pin.add(digit));

    if (_pin.length == _pinLength) {
      final pinCode = _pin.join();
      final success = await ref.read(authProvider.notifier).unlockWithPIN(pinCode);

      if (!mounted) return;

      if (success) {
        _navigateToHome();
      } else {
        HapticFeedback.heavyImpact();
        setState(() => _pin.clear());

        // Start lockout timer if locked out
        final newAuth = ref.read(authProvider);
        if (newAuth.isLockedOut) {
          _startLockoutTimer();
        }
      }
    }
  }

  void _onDelete() {
    final auth = ref.read(authProvider);
    if (auth.isLoading || auth.isLockedOut) return;

    if (_pin.isNotEmpty) {
      HapticFeedback.selectionClick();
      setState(() => _pin.removeLast());
      ref.read(authProvider.notifier).clearError();
    }
  }

  void _onClear() {
    final auth = ref.read(authProvider);
    if (auth.isLoading || auth.isLockedOut) return;

    if (_pin.isNotEmpty) {
      HapticFeedback.mediumImpact();
      setState(() => _pin.clear());
      ref.read(authProvider.notifier).clearError();
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // LOCKOUT TIMER
  // ─────────────────────────────────────────────────────────────────────────────

  void _startLockoutTimer() {
    _lockoutTimer?.cancel();
    _lockoutTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) {
        _lockoutTimer?.cancel();
        return;
      }

      final auth = ref.read(authProvider);
      if (!auth.isLockedOut) {
        ref.read(authProvider.notifier).resetLockout();
        _lockoutTimer?.cancel();
        setState(() {});
      } else {
        setState(() {}); // Refresh to update countdown
      }
    });
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // NAVIGATION
  // ─────────────────────────────────────────────────────────────────────────────

  void _navigateToHome() {
    HapticFeedback.mediumImpact();
    AppRoutes.pushAndClearStack(context, AppRoutes.home);
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    
    // Auto-trigger biometric on first ready state
    _maybeAutoTriggerBiometric(auth);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 40),
            _buildHeader(),
            const SizedBox(height: 32),
            _buildTabs(auth),
            const SizedBox(height: 8),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                physics: auth.biometricAvailable
                    ? const BouncingScrollPhysics()
                    : const NeverScrollableScrollPhysics(),
                children: [
                  _BiometricTab(
                    auth: auth,
                    onTap: _tryBiometric,
                    onSwitchToPin: () => _tabController.animateTo(1),
                  ),
                  _PinTab(
                    auth: auth,
                    pin: _pin,
                    onDigit: _onDigit,
                    onDelete: _onDelete,
                    onClear: _onClear,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // HEADER
  // ─────────────────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Column(
      children: [
        // Logo
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            gradient: KaapavTheme.goldGradient,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: KaapavTheme.gold.withOpacity(0.4),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(Icons.lock_outline, size: 44, color: Colors.white),
        ),
        const SizedBox(height: 20),
        const Text(
          'KAAPAV',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: 4,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Unlock to continue',
          style: TextStyle(color: Color(0xFF888888), fontSize: 14),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // TABS
  // ─────────────────────────────────────────────────────────────────────────────

  Widget _buildTabs(AuthState auth) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 32),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(14),
      ),
      child: TabBar(
        controller: _tabController,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          gradient: KaapavTheme.goldGradient,
          borderRadius: BorderRadius.circular(12),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: const Color(0xFF666666),
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        dividerColor: Colors.transparent,
        tabs: [
          Tab(
            icon: Icon(
              auth.biometricType == AppBiometricType.face
                  ? Icons.face
                  : Icons.fingerprint,
              size: 20,
            ),
            text: auth.biometricLabel,
          ),
          const Tab(icon: Icon(Icons.dialpad, size: 20), text: 'PIN'),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// BIOMETRIC TAB
// ═══════════════════════════════════════════════════════════════════════════════

class _BiometricTab extends StatelessWidget {
  final AuthState auth;
  final VoidCallback onTap;
  final VoidCallback onSwitchToPin;

  const _BiometricTab({
    required this.auth,
    required this.onTap,
    required this.onSwitchToPin,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          const SizedBox(height: 48),

          // Biometric button
          GestureDetector(
            onTap: auth.isLoading ? null : onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: auth.isLoading
                    ? LinearGradient(colors: [
                        KaapavTheme.gold.withOpacity(0.5),
                        KaapavTheme.goldDark.withOpacity(0.5),
                      ])
                    : KaapavTheme.goldGradient,
                boxShadow: [
                  BoxShadow(
                    color: KaapavTheme.gold.withOpacity(auth.isLoading ? 0.2 : 0.5),
                    blurRadius: 40,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: auth.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 3,
                      ),
                    )
                  : Icon(
                      auth.biometricType == AppBiometricType.face
                          ? Icons.face
                          : Icons.fingerprint,
                      size: 72,
                      color: Colors.white,
                    ),
            ),
          ),
          const SizedBox(height: 20),

          // Status text
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Text(
              auth.isLoading
                  ? 'Verifying...'
                  : auth.biometricType == AppBiometricType.face
                      ? 'Look at camera to unlock'
                      : 'Touch sensor to unlock',
              key: ValueKey(auth.isLoading),
              style: const TextStyle(color: Color(0xFF888888), fontSize: 15),
            ),
          ),

          // Error message
          if (auth.hasError && auth.errorType != AuthErrorType.invalidPin) ...[
            const SizedBox(height: 20),
            _ErrorBox(message: auth.displayError),
            const SizedBox(height: 12),
            TextButton(
              onPressed: onSwitchToPin,
              child: const Text(
                'Use PIN instead →',
                style: TextStyle(color: KaapavTheme.gold, fontSize: 14),
              ),
            ),
          ],

          // Biometric not available
          if (!auth.biometricAvailable) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Icon(Icons.info_outline, color: Color(0xFF666666)),
                  const SizedBox(height: 8),
                  const Text(
                    'Biometric not available',
                    style: TextStyle(color: Color(0xFF888888), fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  TextButton(
                    onPressed: onSwitchToPin,
                    child: const Text(
                      'Use PIN',
                      style: TextStyle(color: KaapavTheme.gold),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// PIN TAB
// ═══════════════════════════════════════════════════════════════════════════════

class _PinTab extends StatelessWidget {
  final AuthState auth;
  final List<String> pin;
  final void Function(String) onDigit;
  final VoidCallback onDelete;
  final VoidCallback onClear;

  const _PinTab({
    required this.auth,
    required this.pin,
    required this.onDigit,
    required this.onDelete,
    required this.onClear,
  });

  bool get _isDisabled => auth.isLoading || auth.isLockedOut;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          const SizedBox(height: 32),

          // Status text
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Text(
              auth.isLockedOut
                  ? 'Locked — wait ${auth.lockoutSecondsRemaining}s'
                  : auth.isLoading
                      ? 'Verifying...'
                      : 'Enter 4-digit PIN',
              key: ValueKey('${auth.isLockedOut}_${auth.lockoutSecondsRemaining}_${auth.isLoading}'),
              style: TextStyle(
                color: auth.isLockedOut
                    ? const Color(0xFFEF4444)
                    : const Color(0xFF888888),
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // PIN dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_pinLength, (i) {
              final filled = i < pin.length;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: const EdgeInsets.symmetric(horizontal: 14),
                width: filled ? 20 : 18,
                height: filled ? 20 : 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: filled ? KaapavTheme.gold : Colors.transparent,
                  border: Border.all(
                    color: auth.hasError
                        ? const Color(0xFFEF4444)
                        : KaapavTheme.gold,
                    width: 2,
                  ),
                  boxShadow: filled
                      ? [
                          BoxShadow(
                            color: KaapavTheme.gold.withOpacity(0.4),
                            blurRadius: 8,
                          ),
                        ]
                      : null,
                ),
              );
            }),
          ),

          // Error message
          if (auth.hasError && auth.errorType == AuthErrorType.invalidPin) ...[
            const SizedBox(height: 16),
            _ErrorBox(message: auth.displayError),
          ],
          const SizedBox(height: 24),

          // Numpad
          Opacity(
            opacity: _isDisabled ? 0.4 : 1.0,
            child: AbsorbPointer(
              absorbing: _isDisabled,
              child: Column(
                children: [
                  for (final row in [
                    ['1', '2', '3'],
                    ['4', '5', '6'],
                    ['7', '8', '9'],
                  ])
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: row.map((d) => _NumpadButton(
                        label: d,
                        onTap: () => onDigit(d),
                      )).toList(),
                    ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _NumpadButton(
                        icon: Icons.clear_all,
                        onTap: onClear,
                        isSecondary: true,
                      ),
                      _NumpadButton(
                        label: '0',
                        onTap: () => onDigit('0'),
                      ),
                      _NumpadButton(
                        icon: Icons.backspace_outlined,
                        onTap: onDelete,
                        isSecondary: true,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Loading indicator
          if (auth.isLoading) ...[
            const SizedBox(height: 16),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(KaapavTheme.gold),
            ),
          ],
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// NUMPAD BUTTON
// ═══════════════════════════════════════════════════════════════════════════════

class _NumpadButton extends StatefulWidget {
  final String? label;
  final IconData? icon;
  final VoidCallback onTap;
  final bool isSecondary;

  const _NumpadButton({
    this.label,
    this.icon,
    required this.onTap,
    this.isSecondary = false,
  });

  @override
  State<_NumpadButton> createState() => _NumpadButtonState();
}

class _NumpadButtonState extends State<_NumpadButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        width: 72,
        height: 72,
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _isPressed
              ? const Color(0xFF2A2A2A)
              : const Color(0xFF1A1A1A),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(_isPressed ? 0.1 : 0.3),
              blurRadius: _isPressed ? 4 : 8,
              offset: Offset(0, _isPressed ? 1 : 2),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: widget.label != null
            ? Text(
                widget.label!,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w400,
                  color: Colors.white,
                ),
              )
            : Icon(
                widget.icon,
                size: 24,
                color: widget.isSecondary
                    ? KaapavTheme.gold
                    : Colors.white,
              ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// ERROR BOX
// ═══════════════════════════════════════════════════════════════════════════════

class _ErrorBox extends StatelessWidget {
  final String message;

  const _ErrorBox({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444).withOpacity(0.1),
        border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: Color(0xFFFF6B6B),
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFFFF6B6B),
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}