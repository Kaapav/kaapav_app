// lib/widgets/chat_input.dart
// ---------------------------------------------------------------
// CHAT INPUT   Send bar with attachments
// ---------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kaapav_app/config/theme.dart';
import '../utils/logger.dart';
import 'attachment_picker.dart';
import 'voice_recorder.dart';

class ChatInput extends StatefulWidget {
  final Function(String text) onSend;
  final Function(String path, String type)? onAttachment;
  final VoidCallback? onAttachPressed;
  final VoidCallback? onCameraPressed;
  final VoidCallback? onEmojiPressed;
  final bool isSending;
  final bool enabled;
  final String? hintText;
  final String? initialText;
  final Function(String path, Duration duration)? onVoiceCompleted;

  const ChatInput({
    super.key,
    required this.onSend,
    this.onAttachment,
    this.onCameraPressed,
    this.onAttachPressed,
    this.onEmojiPressed,
    this.onVoiceCompleted,
    this.isSending = false,
    this.enabled = true,
    this.hintText,
    this.initialText,
  });

  @override
  State<ChatInput> createState() => ChatInputState();
}

class ChatInputState extends State<ChatInput> {
  late TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();
  bool _hasText = false;
  bool _isRecording = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
    _hasText = _controller.text.trim().isNotEmpty;
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = _controller.text.trim().isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
    }
  }

  void _handleSend() {
    final text = _controller.text.trim();
    if (text.isEmpty || widget.isSending || !widget.enabled) return;

    HapticFeedback.lightImpact();
    widget.onSend(text);
    _controller.clear();
    _focusNode.requestFocus();
  }

  // -------------------------------------------------------------
  // ATTACHMENT PICKER
  // -------------------------------------------------------------

 void _showAttachmentPicker() {
  // If old callback exists, use it (backward compatible)
  if (widget.onAttachPressed != null) {
    widget.onAttachPressed!();
    return;
  }
  
  // Otherwise use new attachment picker
  showAttachmentPicker(context, (path, type) {
    AppLogger.info('?? File selected: $path ($type)');
    widget.onAttachment?.call(path, type);
  });
}

  // -------------------------------------------------------------
  // PUBLIC METHODS
  // -------------------------------------------------------------

  void setText(String text) {
    _controller.text = text;
    _controller.selection = TextSelection.fromPosition(
      TextPosition(offset: text.length),
    );
    _focusNode.requestFocus();
  }

  String get text => _controller.text;
  void clear() => _controller.clear();
  void focus() => _focusNode.requestFocus();

  // -------------------------------------------------------------
  // BUILD
  // -------------------------------------------------------------

  @override
Widget build(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final bottomInset = MediaQuery.of(context).viewPadding.bottom;

  if (_isRecording) {
    return VoiceRecorder(
      onCompleted: (path, duration) {
        setState(() => _isRecording = false);
        widget.onVoiceCompleted?.call(path, duration);
      },
      onCancel: () => setState(() => _isRecording = false),
    );
  }

  return Container(
    padding: EdgeInsets.only(
      left: 8,
      right: 8,
      top: 8,
      bottom: 8 + bottomInset,
    ),
    decoration: const BoxDecoration(
      color: Colors.transparent,
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _buildIconButton(
          icon: Icons.add_rounded,
          onTap: widget.enabled ? _showAttachmentPicker : null,
          tooltip: 'Attach',
          color: KaapavTheme.goldLight,
          filled: true,
        ),

        const SizedBox(width: 6),

        Expanded(
          child: Container(
            constraints: const BoxConstraints(maxHeight: 124),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: isDark ? 0.090 : 0.74),
                  KaapavTheme.teal.withValues(alpha: isDark ? 0.040 : 0.055),
                  Colors.black.withValues(alpha: isDark ? 0.110 : 0.000),
                ],
              ),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                color: Colors.white.withValues(alpha: isDark ? 0.115 : 0.62),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.05),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 4),
                  child: _buildIconButton(
                    icon: Icons.emoji_emotions_outlined,
                    onTap: widget.onEmojiPressed ?? () => _focusNode.requestFocus(),
                    tooltip: 'Emoji',
                    size: 36,
                    color: KaapavTheme.amethyst,
                  ),
                ),

                Expanded(
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    enabled: widget.enabled,
                    maxLines: 5,
                    minLines: 1,
                    textCapitalization: TextCapitalization.sentences,
                    textInputAction: TextInputAction.newline,
                    cursorColor: KaapavTheme.goldLight,
                    style: const TextStyle(
                      fontSize: 15.5,
                      color: KaapavTheme.white,
                      fontWeight: FontWeight.w500,
                      height: 1.28,
                    ),
                    decoration: InputDecoration(
                      hintText: widget.hintText ?? 'Message KAAPAV customer...',
                      hintStyle: TextStyle(
                        color: KaapavTheme.grayLight.withValues(alpha: 0.72),
                        fontSize: 14.5,
                        fontWeight: FontWeight.w500,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),

                if (!_hasText)
                  Padding(
                    padding: const EdgeInsets.only(right: 4, bottom: 4),
                    child: _buildIconButton(
                      icon: Icons.camera_alt_outlined,
                      onTap: widget.onCameraPressed ?? _showAttachmentPicker,
                      tooltip: 'Camera',
                      size: 36,
                      color: KaapavTheme.sapphire,
                    ),
                  ),
              ],
            ),
          ),
        ),

        const SizedBox(width: 8),

        _buildSendButton(),
      ],
    ),
  );
}

  // -------------------------------------------------------------
  // ICON BUTTON
  // -------------------------------------------------------------

  Widget _buildIconButton({
  required IconData icon,
  VoidCallback? onTap,
  String? tooltip,
  double size = 44,
  Color? color,
  bool filled = false,
}) {
  final accent = color ?? KaapavTheme.grayLight;

  return Tooltip(
    message: tooltip ?? '',
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(size / 2),
        child: Container(
          width: size,
          height: size,
          decoration: filled
              ? BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      accent.withValues(alpha: 0.22),
                      Colors.white.withValues(alpha: 0.070),
                    ],
                  ),
                  border: Border.all(
                    color: accent.withValues(alpha: 0.22),
                  ),
                )
              : null,
          child: Icon(
            icon,
            color: onTap != null
                ? accent
                : KaapavTheme.grayLight.withValues(alpha: 0.42),
            size: size >= 44 ? 24 : 21,
          ),
        ),
      ),
    ),
  );
}

  // -------------------------------------------------------------
  // SEND BUTTON
  // -------------------------------------------------------------

    Widget _buildSendButton() {
  final canSend = _hasText && !widget.isSending && widget.enabled;

  if (!_hasText && !widget.isSending && widget.onVoiceCompleted != null) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        setState(() => _isRecording = true);
      },
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          gradient: KaapavTheme.successGradient,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: KaapavTheme.teal.withValues(alpha: 0.28),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Icon(
          Icons.mic_rounded,
          color: KaapavTheme.white,
          size: 22,
        ),
      ),
    );
  }

  return AnimatedContainer(
    duration: const Duration(milliseconds: 220),
    curve: Curves.easeOutCubic,
    width: 48,
    height: 48,
    decoration: BoxDecoration(
      gradient: canSend ? KaapavTheme.luxeGoldGradient : null,
      color: canSend
          ? null
          : KaapavTheme.grayLight.withValues(alpha: 0.18),
      shape: BoxShape.circle,
      border: Border.all(
        color: canSend
            ? KaapavTheme.goldLight.withValues(alpha: 0.44)
            : Colors.white.withValues(alpha: 0.08),
      ),
      boxShadow: canSend
          ? [
              BoxShadow(
                color: KaapavTheme.gold.withValues(alpha: 0.32),
                blurRadius: 20,
                offset: const Offset(0, 9),
              ),
            ]
          : null,
    ),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: canSend ? _handleSend : null,
        borderRadius: BorderRadius.circular(24),
        child: Center(
          child: widget.isSending
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(KaapavTheme.white),
                  ),
                )
              : Icon(
                  Icons.send_rounded,
                  color: canSend
                      ? KaapavTheme.bgDeep
                      : KaapavTheme.grayLight.withValues(alpha: 0.65),
                  size: 20,
                ),
        ),
      ),
    ),
  );
}
}