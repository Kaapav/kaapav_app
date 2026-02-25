// lib/widgets/chat_input.dart
// ═══════════════════════════════════════════════════════════════
// CHAT INPUT — Send bar with attachments
// ═══════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config/theme.dart';
import '../utils/logger.dart';
import 'attachment_picker.dart';

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

  const ChatInput({
    super.key,
    required this.onSend,
    this.onAttachment,
    this.onCameraPressed,
    this.onAttachPressed,
    this.onEmojiPressed,
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

  // ─────────────────────────────────────────────────────────────
  // ATTACHMENT PICKER
  // ─────────────────────────────────────────────────────────────

 void _showAttachmentPicker() {
  // If old callback exists, use it (backward compatible)
  if (widget.onAttachPressed != null) {
    widget.onAttachPressed!();
    return;
  }
  
  // Otherwise use new attachment picker
  showAttachmentPicker(context, (path, type) {
    AppLogger.info('📎 File selected: $path ($type)');
    widget.onAttachment?.call(path, type);
  });
}

  // ─────────────────────────────────────────────────────────────
  // PUBLIC METHODS
  // ─────────────────────────────────────────────────────────────

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

  // ─────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 8,
        right: 8,
        top: 8,
        bottom: 8 + MediaQuery.of(context).viewPadding.bottom,
      ),
      decoration: BoxDecoration(
        color: KaapavTheme.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Attach button
          _buildIconButton(
            icon: Icons.add,
            onTap: widget.enabled ? _showAttachmentPicker : null,
            tooltip: 'Attach',
          ),

          // Input field
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 120),
              decoration: BoxDecoration(
                color: KaapavTheme.cream,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: KaapavTheme.border),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Emoji button
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 4),
                    child: _buildIconButton(
                      icon: Icons.emoji_emotions_outlined,
                      onTap: widget.onEmojiPressed ?? () => _focusNode.requestFocus(),
                      tooltip: 'Emoji',
                      size: 36,
                    ),
                  ),

                  // Text input
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      enabled: widget.enabled,
                      maxLines: 5,
                      minLines: 1,
                      textCapitalization: TextCapitalization.sentences,
                      textInputAction: TextInputAction.newline,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white,
  		        fontWeight: FontWeight.w400,
                      ),
                      decoration: InputDecoration(
                        hintText: widget.hintText ?? 'Type a message...',
                        hintStyle: TextStyle(
 			 color: Colors.white.withOpacity(0.5),  
  			 fontSize: 16,
		     ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),

                  // Camera button (only when no text)
                  if (!_hasText)
                    Padding(
                      padding: const EdgeInsets.only(right: 4, bottom: 4),
                      child: _buildIconButton(
                        icon: Icons.camera_alt_outlined,
                        onTap: widget.onCameraPressed ?? _showAttachmentPicker,
                        tooltip: 'Camera',
                        size: 36,
                      ),
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Send button
          _buildSendButton(),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // ICON BUTTON
  // ─────────────────────────────────────────────────────────────

  Widget _buildIconButton({
    required IconData icon,
    VoidCallback? onTap,
    String? tooltip,
    double size = 44,
  }) {
    return Tooltip(
      message: tooltip ?? '',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(size / 2),
          child: SizedBox(
            width: size,
            height: size,
            child: Icon(
              icon,
              color: onTap != null ? KaapavTheme.gray : KaapavTheme.grayLight,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // SEND BUTTON
  // ─────────────────────────────────────────────────────────────

  Widget _buildSendButton() {
    final canSend = _hasText && !widget.isSending && widget.enabled;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        gradient: canSend ? KaapavTheme.goldGradient : null,
        color: canSend ? null : KaapavTheme.grayLight.withOpacity(0.3),
        shape: BoxShape.circle,
        boxShadow: canSend ? [KaapavTheme.goldShadow] : null,
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
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  )
                : Icon(
                    Icons.send,
                    color: canSend ? Colors.white : KaapavTheme.grayLight,
                    size: 20,
                  ),
          ),
        ),
      ),
    );
  }
}