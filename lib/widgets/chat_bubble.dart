// lib/widgets/chat_bubble.dart
// ---------------------------------------------------------------
// CHAT BUBBLE   Advanced Production Widget
// Aligned with: Message model, KaapavTheme
// Supports: text, image, document, audio, buttons, product, order
// ---------------------------------------------------------------

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:kaapav_app/config/theme.dart';
import 'package:kaapav_app/models/message.dart';
import 'package:kaapav_app/utils/formatters.dart';
import 'package:kaapav_app/widgets/full_screen_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:audioplayers/audioplayers.dart';

class ChatBubble extends StatefulWidget {
  final Message message;
  final Function(String buttonId, String buttonTitle)? onButtonClick;
  final Function(Message message)? onRetry;
  final Function(Message message)? onLongPress;

  const ChatBubble({
    super.key,
    required this.message,
    this.onButtonClick,
    this.onRetry,
    this.onLongPress,
  });

  @override
  State<ChatBubble> createState() => _ChatBubbleState();
}

class _ChatBubbleState extends State<ChatBubble> with SingleTickerProviderStateMixin {
  //bool _imageLoaded = false;
  //bool _imageError = false;
  int? _hoveredButton;

    String? _reaction;
  // Audio player state
  AudioPlayer? _audioPlayer;
  bool _isPlaying = false;
  Duration _audioDuration = Duration.zero;
  Duration _audioPosition = Duration.zero;

    @override
  void dispose() {
    _audioPlayer?.dispose();
    super.dispose();
  }

  Message get message => widget.message;
  bool get isOutgoing => message.isOutgoing;
  bool get isIncoming => message.isIncoming;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        mainAxisAlignment: isOutgoing ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Flexible(
          child: GestureDetector(
              onDoubleTap: () {
                HapticFeedback.lightImpact();
                _showReactionPicker(context);
              },
              onLongPress: () {
                HapticFeedback.mediumImpact();
                widget.onLongPress?.call(message);
              },
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.75,
                ),
                              child: Column(
                  crossAxisAlignment: isOutgoing ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildBubbleContent(),
                    if (_reaction != null)
                      Transform.translate(
                        offset: const Offset(0, -8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: KaapavTheme.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: KaapavTheme.border),
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 4)],
                          ),
                          child: Text(_reaction!, style: const TextStyle(fontSize: 16)),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
         ],
      ),
    );
  }

  Widget _buildBubbleContent() {
    // Check for button message (autoresponder)
    final buttons = _parseButtons();
    if (buttons != null && buttons.isNotEmpty) {
      return _buildButtonMessage(buttons);
    }

    switch (message.messageType) {
      case 'image':
        return _buildImageBubble();
      case 'document':
        return _buildDocumentBubble();
      case 'audio':
      case 'voice':
        return _buildAudioBubble();
      case 'video':
        return _buildVideoBubble();
      case 'location':
        return _buildLocationBubble();
      case 'sticker':
        return _buildStickerBubble();
      case 'interactive':
        return _buildInteractiveBubble();
      case 'buttons':
        final btns = _parseButtons();
        if (btns != null && btns.isNotEmpty) {
          return _buildButtonMessage(btns);
        }
        return _buildTextBubble();
      default:
        return _buildTextBubble();
    }
  }

  // -----------------------------------------------------------
  // PARSE BUTTONS
  // -----------------------------------------------------------

  List<Map<String, dynamic>>? _parseButtons() {
    try {
      // Check message.buttons
      if (message.buttons != null) {
        if (message.buttons is List) {
          return List<Map<String, dynamic>>.from(
            (message.buttons as List).map((e) => Map<String, dynamic>.from(e as Map)),
          );
        }
        if (message.buttons is String && (message.buttons as String).isNotEmpty) {
          final parsed = jsonDecode(message.buttons as String);
          if (parsed is List) {
            return List<Map<String, dynamic>>.from(
              parsed.map((e) => Map<String, dynamic>.from(e as Map)),
            );
          }
        }
      }

      // Fallback: parse from buttonText (pipe-separated)
      if (message.buttonText != null && message.buttonText!.isNotEmpty) {
        final titles = message.buttonText!
            .split('|')
            .map((t) => t.trim())
            .where((t) => t.isNotEmpty)
            .toList();
        if (titles.isNotEmpty) {
          return titles.asMap().entries.map((e) => {
            'id': 'btn_${e.key}',
            'title': e.value,
          }).toList();
        }
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  // -----------------------------------------------------------
  // GET DISPLAY TEXT
  // -----------------------------------------------------------

  String _getDisplayText() {
    if (message.text == null || message.text!.isEmpty) {
      return message.displayText;
    }

    String text = message.text!;

    // Try parsing JSON
    if (text.trim().startsWith('{') || text.trim().startsWith('[')) {
      try {
        final parsed = jsonDecode(text);
        if (parsed is Map) {
          // Interactive message body
          if (parsed['interactive']?['body']?['text'] != null) {
            return parsed['interactive']['body']['text'].toString();
          }
          if (parsed['text']?['body'] != null) {
            return parsed['text']['body'].toString();
          }
          if (parsed['body']?['text'] != null) {
            return parsed['body']['text'].toString();
          }
          if (parsed['body'] is String) {
            return parsed['body'].toString();
          }
        }
      } catch (_) {}
    }

    // Remove button markers [Button1] [Button2]
    return text.replaceAll(RegExp(r'\[([^\]]+)\]'), '').trim();
  }

  // -----------------------------------------------------------
  // FORMAT TIMESTAMP
  // -----------------------------------------------------------

  String _formatTime() {
    final dt = Formatters.parseDate(message.timestamp);
    return Formatters.time(dt);
  }

    // -----------------------------------------------------------
  // RICH TEXT WITH CLICKABLE LINKS
  // -----------------------------------------------------------

  Widget _buildRichText(String text, {required Color textColor, Color? linkColor}) {
    final urlRegex = RegExp(
      r'(https?://[^\s<>"\)]+|www\.[^\s<>"\)]+)',
      caseSensitive: false,
    );

    final matches = urlRegex.allMatches(text).toList();

    if (matches.isEmpty) {
      return Text(text, style: TextStyle(fontSize: 15, height: 1.4, color: textColor));
    }

    final spans = <TextSpan>[];
    int lastEnd = 0;

    for (final match in matches) {
      // Text before link
      if (match.start > lastEnd) {
        spans.add(TextSpan(
          text: text.substring(lastEnd, match.start),
          style: TextStyle(fontSize: 15, height: 1.4, color: textColor),
        ));
      }

      // Link
      final url = match.group(0)!;
      spans.add(TextSpan(
        text: url,
        style: TextStyle(
          fontSize: 15,
          height: 1.4,
          color: linkColor ?? (isOutgoing ? Colors.white : const Color(0xFF1A73E8)),
          decoration: TextDecoration.underline,
          decorationColor: linkColor ?? (isOutgoing ? Colors.white70 : const Color(0xFF1A73E8)),
        ),
        recognizer: TapGestureRecognizer()
          ..onTap = () {
            final fullUrl = url.startsWith('http') ? url : 'https://$url';
            launchUrl(Uri.parse(fullUrl), mode: LaunchMode.externalApplication);
          },
      ));

      lastEnd = match.end;
    }

    // Text after last link
    if (lastEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastEnd),
        style: TextStyle(fontSize: 15, height: 1.4, color: textColor),
      ));
    }

    return RichText(text: TextSpan(children: spans));
  }


  // -----------------------------------------------------------
  // TEXT BUBBLE
  // -----------------------------------------------------------

  Widget _buildTextBubble() {
    final displayText = _getDisplayText();
    if (displayText.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: isOutgoing ? KaapavTheme.goldGradient : null,
        color: isOutgoing ? null : KaapavTheme.white,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft: Radius.circular(isOutgoing ? 16 : 4),
          bottomRight: Radius.circular(isOutgoing ? 4 : 16),
        ),
        border: isOutgoing ? null : Border.all(color: KaapavTheme.border),
        boxShadow: [
          BoxShadow(
            color: isOutgoing
                ? KaapavTheme.gold.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Forwarded indicator
          if (message.isForwarded) ...[
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.forward,
                  size: 12,
                  color: isOutgoing ? Colors.white70 : KaapavTheme.grayLight,
                ),
                const SizedBox(width: 4),
                Text(
                  'Forwarded',
                  style: TextStyle(
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                    color: isOutgoing ? Colors.white70 : KaapavTheme.grayLight,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
          ],

          // Message text
                    // Message text with clickable links
          _buildRichText(
            displayText,
            textColor: isOutgoing ? Colors.white : KaapavTheme.dark,
            linkColor: isOutgoing ? Colors.white : null,
          ),
          const SizedBox(height: 4),
          _buildFooter(),
        ],
      ),
    );
  }

  // -----------------------------------------------------------
  // BUTTON MESSAGE (Autoresponder Menu)
  // -----------------------------------------------------------

  Widget _buildButtonMessage(List<Map<String, dynamic>> buttons) {
    final displayText = _getDisplayText();

    return Container(
      decoration: BoxDecoration(
        color: KaapavTheme.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: KaapavTheme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Gold accent bar
          Container(
            height: 4,
            decoration: const BoxDecoration(
              gradient: KaapavTheme.goldGradient,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
          ),

          // Message body
          if (displayText.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
                            child: _buildRichText(
                displayText,
                textColor: KaapavTheme.dark,
              ),
            ),

          // Buttons
          Container(
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: KaapavTheme.border)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: buttons.asMap().entries.map((entry) {
                final idx = entry.key;
                final btn = entry.value;
                return _buildButton(btn, idx, idx > 0);
              }).toList(),
            ),
          ),

          // Footer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: const BoxDecoration(
              color: Color(0xFFFAFAFA),
              border: Border(top: BorderSide(color: KaapavTheme.border)),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (message.isAutoReply)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: KaapavTheme.cream,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      '?? Auto',
                      style: TextStyle(fontSize: 10, color: KaapavTheme.grayLight),
                    ),
                  )
                else
                  const SizedBox.shrink(),
                Text(
                  _formatTime(),
                  style: const TextStyle(fontSize: 11, color: KaapavTheme.grayLight),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButton(Map<String, dynamic> btn, int index, bool showBorder) {
    final title = btn['title']?.toString() ??
        btn['text']?.toString() ??
        btn['reply']?['title']?.toString() ??
        'Option';
    final id = btn['id']?.toString() ??
        btn['reply']?['id']?.toString() ??
        title;

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredButton = index),
      onExit: (_) => setState(() => _hoveredButton = null),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            widget.onButtonClick?.call(id, title);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: BoxDecoration(
              color: _hoveredButton == index ? KaapavTheme.cream : Colors.transparent,
              border: showBorder
                  ? const Border(top: BorderSide(color: KaapavTheme.border))
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.reply,
                  size: 14,
                  color: KaapavTheme.gold.withValues(alpha: 0.7),
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: KaapavTheme.gold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // -----------------------------------------------------------
  // IMAGE BUBBLE
  // -----------------------------------------------------------

  Widget _buildImageBubble() {
    // -- Handle null mediaUrl   show placeholder card --
    if (message.mediaUrl == null || message.mediaUrl!.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: isOutgoing ? KaapavTheme.goldGradient : null,
          color: isOutgoing ? null : KaapavTheme.white,
          borderRadius: BorderRadius.circular(16),
          border: isOutgoing ? null : Border.all(color: KaapavTheme.border),
          boxShadow: [
            BoxShadow(
              color: isOutgoing
                  ? KaapavTheme.gold.withValues(alpha: 0.3)
                  : Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isOutgoing ? Colors.white.withValues(alpha: 0.2) : KaapavTheme.gold.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.image, color: isOutgoing ? Colors.white : KaapavTheme.gold, size: 28),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '?? Photo',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isOutgoing ? Colors.white : KaapavTheme.dark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Image not available',
                        style: TextStyle(
                          fontSize: 12,
                          color: isOutgoing ? Colors.white70 : KaapavTheme.gray,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (message.mediaCaption != null && message.mediaCaption!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                message.mediaCaption!,
                style: TextStyle(
                  fontSize: 14,
                  color: isOutgoing ? Colors.white : KaapavTheme.dark,
                ),
              ),
            ],
            const SizedBox(height: 6),
            _buildFooter(),
          ],
        ),
      );
    }

    // -- Has mediaUrl   show image with tap-to-fullscreen --
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => FullScreenImage(
              imageUrl: message.mediaUrl!,
              caption: message.mediaCaption,
              senderName: isIncoming ? 'Customer' : 'You',
              timestamp: _formatTime(),
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: isOutgoing ? null : Border.all(color: KaapavTheme.border),
          boxShadow: [
            BoxShadow(
              color: isOutgoing
                  ? KaapavTheme.gold.withValues(alpha: 0.3)
                  : Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Image with zoom icon overlay
              Stack(
                children: [
                  CachedNetworkImage(
                    imageUrl: message.mediaUrl!,
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      height: 200,
                      color: KaapavTheme.cream,
                      child: const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation(KaapavTheme.gold),
                          strokeWidth: 2,
                        ),
                      ),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      height: 200,
                      color: KaapavTheme.cream,
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.broken_image, color: KaapavTheme.grayLight, size: 48),
                          SizedBox(height: 8),
                          Text('Failed to load', style: TextStyle(color: KaapavTheme.gray, fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                  // Zoom icon overlay
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(Icons.zoom_in, color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),

              // Caption
              if (message.mediaCaption != null && message.mediaCaption!.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: isOutgoing ? KaapavTheme.goldGradient : null,
                    color: isOutgoing ? null : KaapavTheme.white,
                  ),
                  child: Text(
                    message.mediaCaption!,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      color: isOutgoing ? Colors.white : KaapavTheme.dark,
                    ),
                  ),
                ),

              // Footer
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: isOutgoing ? KaapavTheme.goldGradient : null,
                  color: isOutgoing ? null : KaapavTheme.white,
                ),
                child: _buildFooter(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // -----------------------------------------------------------
  // DOCUMENT BUBBLE
  // -----------------------------------------------------------

  Widget _buildDocumentBubble() {
    final filename = message.mediaCaption ?? 'Document';
    final parts = filename.split('.');
    final ext = parts.length > 1 ? parts.last.toUpperCase() : 'FILE';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: KaapavTheme.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: KaapavTheme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              // File icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _getFileColor(ext).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _getFileIcon(ext),
                  color: _getFileColor(ext),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),

              // File info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      filename,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: KaapavTheme.dark,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      ext,
                      style: const TextStyle(
                        fontSize: 12,
                        color: KaapavTheme.gray,
                      ),
                    ),
                  ],
                ),
              ),

              // Download button
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: KaapavTheme.goldGradient,
                  shape: BoxShape.circle,
                  boxShadow: [KaapavTheme.goldShadow],
                ),
                child: const Icon(Icons.download, color: Colors.white, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              _formatTime(),
              style: const TextStyle(fontSize: 11, color: KaapavTheme.grayLight),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getFileIcon(String ext) {
    switch (ext) {
      case 'PDF':
        return Icons.picture_as_pdf;
      case 'DOC':
      case 'DOCX':
        return Icons.description;
      case 'XLS':
      case 'XLSX':
        return Icons.table_chart;
      case 'PPT':
      case 'PPTX':
        return Icons.slideshow;
      case 'ZIP':
      case 'RAR':
        return Icons.folder_zip;
      case 'MP3':
      case 'WAV':
      case 'M4A':
        return Icons.audio_file;
      case 'MP4':
      case 'MOV':
      case 'AVI':
        return Icons.video_file;
      default:
        return Icons.insert_drive_file;
    }
  }

  Color _getFileColor(String ext) {
    switch (ext) {
      case 'PDF':
        return const Color(0xFFDC2626);
      case 'DOC':
      case 'DOCX':
        return const Color(0xFF2563EB);
      case 'XLS':
      case 'XLSX':
        return const Color(0xFF059669);
      case 'PPT':
      case 'PPTX':
        return const Color(0xFFD97706);
      case 'ZIP':
      case 'RAR':
        return const Color(0xFF7C3AED);
      default:
        return KaapavTheme.gray;
    }
  }


  // -----------------------------------------------------------
  // AUDIO BUBBLE (with player)
  // -----------------------------------------------------------

    Widget _buildAudioBubble() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: isOutgoing ? KaapavTheme.goldGradient : null,
        color: isOutgoing ? null : KaapavTheme.white,
        borderRadius: BorderRadius.circular(24),
        border: isOutgoing ? null : Border.all(color: KaapavTheme.border),
        boxShadow: [BoxShadow(
          color: isOutgoing ? KaapavTheme.gold.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Play/Pause button
          GestureDetector(
            onTap: () => _toggleAudio(),
            child: Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: isOutgoing ? Colors.white.withValues(alpha: 0.2) : null,
                gradient: isOutgoing ? null : KaapavTheme.goldGradient,
                shape: BoxShape.circle,
              ),
              child: Icon(_isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.white, size: 24),
            ),
          ),
          const SizedBox(width: 12),
          // Progress bar
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 3,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                    activeTrackColor: isOutgoing ? Colors.white : KaapavTheme.gold,
                    inactiveTrackColor: isOutgoing ? Colors.white38 : KaapavTheme.border,
                    thumbColor: isOutgoing ? Colors.white : KaapavTheme.gold,
                    overlayShape: SliderComponentShape.noOverlay,
                  ),
                  child: Slider(
                    value: _audioDuration.inMilliseconds > 0
                        ? _audioPosition.inMilliseconds / _audioDuration.inMilliseconds
                        : 0,
                    onChanged: (v) {
                      _audioPlayer?.seek(Duration(milliseconds: (v * _audioDuration.inMilliseconds).round()));
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _isPlaying ? _fmt(_audioPosition) : _fmt(_audioDuration),
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500,
                color: isOutgoing ? Colors.white.withValues(alpha: 0.8) : KaapavTheme.gray),
          ),
        ],
      ),
    );
  }

  String _fmt(Duration d) =>
      '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';

  Future<void> _toggleAudio() async {
    if (message.mediaUrl == null) return;

    _audioPlayer ??= AudioPlayer();

    if (_isPlaying) {
      await _audioPlayer!.pause();
      setState(() => _isPlaying = false);
    } else {
      _audioPlayer!.onDurationChanged.listen((d) {
        if (mounted) setState(() => _audioDuration = d);
      });
      _audioPlayer!.onPositionChanged.listen((p) {
        if (mounted) setState(() => _audioPosition = p);
      });
      _audioPlayer!.onPlayerComplete.listen((_) {
        if (mounted) setState(() { _isPlaying = false; _audioPosition = Duration.zero; });
      });
      await _audioPlayer!.play(UrlSource(message.mediaUrl!));
      setState(() => _isPlaying = true);
    }
  }

     // -----------------------------------------------------------
  // VIDEO BUBBLE
  // -----------------------------------------------------------

  Widget _buildVideoBubble() {
    return GestureDetector(
      onTap: () {
        if (message.mediaUrl != null) {
          launchUrl(Uri.parse(message.mediaUrl!), mode: LaunchMode.externalApplication);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: isOutgoing ? null : Border.all(color: KaapavTheme.border),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: double.infinity,
                height: 200,
                color: KaapavTheme.dark,
                child: const Icon(Icons.videocam, color: Colors.white54, size: 48),
              ),
              Container(
                width: 64, height: 64,
                decoration: BoxDecoration(
                  gradient: KaapavTheme.goldGradient,
                  shape: BoxShape.circle,
                  boxShadow: [KaapavTheme.goldShadow],
                ),
                child: const Icon(Icons.play_arrow, color: Colors.white, size: 32),
              ),
              Positioned(
                bottom: 0, left: 0, right: 0,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Colors.black54, Colors.transparent],
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(_formatTime(), style: const TextStyle(fontSize: 11, color: Colors.white70)),
                      if (isOutgoing) ...[
                        const SizedBox(width: 4),
                        _buildStatusIcon(color: Colors.white70),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // -----------------------------------------------------------
  // LOCATION BUBBLE
  // -----------------------------------------------------------

  Widget _buildLocationBubble() {
    return Container(
      decoration: BoxDecoration(
        color: KaapavTheme.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: KaapavTheme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Map placeholder
          Container(
            height: 120,
            decoration: const BoxDecoration(
              gradient: KaapavTheme.goldGradient,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: const Center(
              child: Icon(Icons.location_on, color: Colors.white, size: 48),
            ),
          ),

          // Info
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '?? Location Shared',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: KaapavTheme.dark,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Tap to view on map',
                  style: TextStyle(fontSize: 13, color: KaapavTheme.gray),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    _formatTime(),
                    style: const TextStyle(fontSize: 11, color: KaapavTheme.grayLight),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // -----------------------------------------------------------
  // STICKER BUBBLE
  // -----------------------------------------------------------

  Widget _buildStickerBubble() {
    if (message.mediaUrl == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: isOutgoing ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        CachedNetworkImage(
          imageUrl: message.mediaUrl!,
          width: 150,
          height: 150,
          fit: BoxFit.contain,
          placeholder: (_, __) => const SizedBox(
            width: 150,
            height: 150,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
          errorWidget: (_, __, ___) => const Icon(Icons.emoji_emotions, size: 100),
        ),
        const SizedBox(height: 4),
        Text(
          _formatTime(),
          style: const TextStyle(fontSize: 11, color: KaapavTheme.grayLight),
        ),
      ],
    );
  }

  // -----------------------------------------------------------
  // INTERACTIVE REPLY BUBBLE
  // -----------------------------------------------------------

  Widget _buildInteractiveBubble() {
    final displayText = _getDisplayText();
    if (displayText.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: isOutgoing ? KaapavTheme.goldGradient : null,
        color: isOutgoing ? null : KaapavTheme.white,
        borderRadius: BorderRadius.circular(16),
        border: isOutgoing ? null : Border.all(color: KaapavTheme.border),
        boxShadow: [
          BoxShadow(
            color: isOutgoing
                ? KaapavTheme.gold.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Selected option indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isOutgoing ? Colors.white.withValues(alpha: 0.2) : KaapavTheme.cream,
              borderRadius: BorderRadius.circular(8),
              border: isOutgoing ? null : Border.all(color: KaapavTheme.gold.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle,
                  size: 14,
                  color: isOutgoing ? Colors.white : KaapavTheme.gold,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    displayText,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isOutgoing ? Colors.white : KaapavTheme.gold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          _buildFooter(),
        ],
      ),
    );
  }

    void _showReactionPicker(BuildContext context) {
    final emojis = ['??', '??', '??', '??', '??', '??'];
    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (ctx) => Stack(
        children: [
          GestureDetector(onTap: () => Navigator.pop(ctx), child: Container(color: Colors.transparent)),
          Positioned(
            bottom: MediaQuery.of(context).size.height * 0.4,
            left: 40, right: 40,
            child: Center(
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(28),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(color: KaapavTheme.white, borderRadius: BorderRadius.circular(28)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: emojis.map((e) => GestureDetector(
                      onTap: () {
                        setState(() => _reaction = _reaction == e ? null : e);
                        Navigator.pop(ctx);
                        HapticFeedback.lightImpact();
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        child: Text(e, style: const TextStyle(fontSize: 28)),
                      ),
                    )).toList(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // -----------------------------------------------------------
  // FOOTER & STATUS
  // -----------------------------------------------------------

  Widget _buildFooter() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Auto reply badge
        if (message.isAutoReply && isOutgoing) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              '??',
              style: TextStyle(fontSize: 10),
            ),
          ),
          const SizedBox(width: 4),
        ],

        // Timestamp
        Text(
          _formatTime(),
          style: TextStyle(
            fontSize: 11,
            color: isOutgoing ? Colors.white.withValues(alpha: 0.7) : KaapavTheme.grayLight,
          ),
        ),

        // Status icon (outgoing only)
        if (isOutgoing) ...[
          const SizedBox(width: 4),
          _buildStatusIcon(),
        ],
      ],
    );
  }

  Widget _buildStatusIcon({Color? color}) {
    final iconColor = color ?? (isOutgoing ? Colors.white.withValues(alpha: 0.7) : KaapavTheme.grayLight);

    switch (message.status) {
      case 'sending':
        return Icon(Icons.schedule, size: 14, color: iconColor.withValues(alpha: 0.5));
      case 'sent':
        return Icon(Icons.check, size: 14, color: iconColor);
      case 'delivered':
        return Icon(Icons.done_all, size: 14, color: iconColor);
      case 'read':
        return const Icon(Icons.done_all, size: 14, color: KaapavTheme.readBlue);
      case 'failed':
        return GestureDetector(
          onTap: () => widget.onRetry?.call(message),
          child: const Icon(Icons.error_outline, size: 14, color: KaapavTheme.error),
        );
      default:
        return Icon(Icons.check, size: 14, color: iconColor);
    }
  }
}
