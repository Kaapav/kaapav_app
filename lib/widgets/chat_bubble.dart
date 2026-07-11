// lib/widgets/chat_bubble.dart
import 'dart:convert';
import 'dart:ui';
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
  final bool isSelectionMode;
  final bool isSelected;
  final Function(Message message)? onSelect;

  const ChatBubble({
    super.key,
    required this.message,
    this.onButtonClick,
    this.onRetry,
    this.onLongPress,
    this.isSelectionMode = false,
    this.isSelected = false,
    this.onSelect,
  });

  @override
  State<ChatBubble> createState() => _ChatBubbleState();
}

class _ChatBubbleState extends State<ChatBubble>
    with SingleTickerProviderStateMixin {
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

  // ─────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Row(
        mainAxisAlignment:
            isOutgoing ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // ── Checkbox – incoming side ──
          if (widget.isSelectionMode && !isOutgoing)
            GestureDetector(
              onTap: () => widget.onSelect?.call(message),
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _checkbox(),
              ),
            ),

          // ── Bubble ──
          Flexible(
            child: GestureDetector(
              onTap: widget.isSelectionMode
                  ? () => widget.onSelect?.call(message)
                  : null,
              onDoubleTap: widget.isSelectionMode
                  ? null
                  : () {
                      HapticFeedback.lightImpact();
                      _showReactionPicker(context);
                    },
              onLongPress: widget.isSelectionMode
                  ? null
                  : () {
                      HapticFeedback.mediumImpact();
                      widget.onLongPress?.call(message);
                    },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: widget.isSelected
                      ? KaapavTheme.gold.withValues(alpha: 0.08)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width *
                        (widget.isSelectionMode ? 0.68 : 0.75),
                  ),
                  child: Column(
                    crossAxisAlignment: isOutgoing
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildBubbleContent(isDark),
                      if (_reaction != null)
                        Transform.translate(
                          offset: const Offset(0, -8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
decoration: BoxDecoration(
  gradient: LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Colors.white.withValues(alpha: isDark ? 0.085 : 0.66),
      KaapavTheme.grayLight.withValues(alpha: isDark ? 0.055 : 0.045),
      Colors.black.withValues(alpha: isDark ? 0.13 : 0.00),
    ],
  ),
  borderRadius: BorderRadius.only(
    topLeft: const Radius.circular(18),
    topRight: const Radius.circular(18),
    bottomLeft: Radius.circular(isOutgoing ? 18 : 6),
    bottomRight: Radius.circular(isOutgoing ? 6 : 18),
  ),
  border: Border.all(
    color: Colors.white.withValues(alpha: isDark ? 0.10 : 0.48),
  ),
  boxShadow: [
    BoxShadow(
      color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.06),
      blurRadius: 16,
      spreadRadius: -7,
      offset: const Offset(0, 8),
    ),
  ],
),
                            child: Text(_reaction!,
                                style: const TextStyle(fontSize: 16)),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Checkbox – outgoing side ──
          if (widget.isSelectionMode && isOutgoing)
            GestureDetector(
              onTap: () => widget.onSelect?.call(message),
              child: Padding(
                padding: const EdgeInsets.only(left: 8),
                child: _checkbox(),
              ),
            ),
        ],
      ),
    );
  }

  // Reusable checkbox widget
  Widget _checkbox() {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: widget.isSelected ? KaapavTheme.gold : Colors.transparent,
        border: Border.all(
          color:
              widget.isSelected ? KaapavTheme.gold : KaapavTheme.grayLight,
          width: 2,
        ),
      ),
      child: widget.isSelected
          ? const Icon(Icons.check, size: 16, color: Colors.white)
          : null,
    );
  }

  // ─────────────────────────────────────────────
  // BUBBLE CONTENT ROUTER
  // ─────────────────────────────────────────────
  Widget _buildBubbleContent(bool isDark) {
  if (message.isDeleted) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isOutgoing
            ? KaapavTheme.gold.withValues(alpha: 0.15)
            : (isDark ? const Color(0xFF1E1E1E) : KaapavTheme.white),
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft: Radius.circular(isOutgoing ? 16 : 4),
          bottomRight: Radius.circular(isOutgoing ? 4 : 16),
        ),
        border: Border.all(color: KaapavTheme.border.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.block, size: 15, color: KaapavTheme.grayLight.withValues(alpha: 0.7)),
          const SizedBox(width: 6),
          Text('This message was deleted',
              style: TextStyle(
                fontSize: 14,
                fontStyle: FontStyle.italic,
                color: KaapavTheme.grayLight.withValues(alpha: 0.7),
              )),
        ],
      ),
    );
  }

  final buttons = _parseButtons();
  if (message.isMenu || (buttons != null && buttons.isNotEmpty)) {
    return _buildButtonMessage(buttons ?? [], isDark);
  }

  switch (message.messageType) {
    case 'image': return _buildImageBubble(isDark);
    case 'document': return _buildDocumentBubble(isDark);
    case 'audio':
    case 'voice': return _buildAudioBubble(isDark);
    case 'video': return _buildVideoBubble(isDark);
    case 'location': return _buildLocationBubble(isDark);
    case 'sticker': return _buildStickerBubble();
    case 'interactive': return _buildInteractiveBubble(isDark);
case 'unsupported': return _buildUnsupportedBubble(isDark);
    case 'buttons':
      final btns = _parseButtons();
      if (btns != null && btns.isNotEmpty) return _buildButtonMessage(btns, isDark);
      return _buildTextBubble(isDark);
    default:
      return _buildTextBubble(isDark);
  }
}

     
  // ─────────────────────────────────────────────
  // PARSE BUTTONS
  // ─────────────────────────────────────────────
  List<Map<String, dynamic>>? _parseButtons() {
  try {
    // ── 1. buttons field: already a List (rare, only if pre-parsed)
    if (message.buttons is List) {
      final list = message.buttons as List;
      if (list.isNotEmpty) {
        return list.map((e) {
          if (e is Map) return Map<String, dynamic>.from(e);
          return {'id': 'btn_0', 'title': e.toString()};
        }).toList();
      }
    }

    // ── 2. buttons field: String (this is what SQLite returns)
    if (message.buttons is String) {
      final s = (message.buttons as String).trim();
      if (s.isNotEmpty && s.startsWith('[')) {
        final parsed = jsonDecode(s);
        if (parsed is List && parsed.isNotEmpty) {
          return parsed.map((e) {
            if (e is Map) return Map<String, dynamic>.from(e);
            return {'id': 'btn_0', 'title': e.toString()};
          }).toList();
        }
      }
    }

    // ── 3. buttonText: pipe-separated fallback
    final bt = message.buttonText;
    if (bt != null && bt.trim().isNotEmpty) {
      final titles = bt
          .split('|')
          .map((t) => t.trim())
          .where((t) => t.isNotEmpty)
          .toList();
      if (titles.isNotEmpty) {
        return titles.asMap().entries
            .map((e) => {'id': 'btn_${e.key}', 'title': e.value})
            .toList();
      }
    }

    // ── 4. text field: interactive JSON
    final txt = message.text;
    if (txt != null && txt.trim().startsWith('{')) {
      final parsed = jsonDecode(txt);
      if (parsed is Map) {
        // WhatsApp interactive format
        final btns = parsed['interactive']?['action']?['buttons'];
        if (btns is List && btns.isNotEmpty) {
          return btns.map<Map<String, dynamic>>((b) {
            final reply = b is Map ? b['reply'] : null;
            return {
              'id': (reply is Map ? reply['id'] : null)?.toString() ?? 'btn',
              'title': (reply is Map ? reply['title'] : null)?.toString() ?? 'Option',
            };
          }).toList();
        }
        // flat buttons array
        final flat = parsed['buttons'];
        if (flat is List && flat.isNotEmpty) {
          return flat.map((e) {
            if (e is Map) return Map<String, dynamic>.from(e);
            return {'id': 'btn_0', 'title': e.toString()};
          }).toList();
        }
      }
    }

    return null;
  } catch (_) {
    return null;
  }
}

  // ─────────────────────────────────────────────
  // DISPLAY TEXT
  // ─────────────────────────────────────────────
String _getDisplayText() {
  final txt = message.text;
  if (txt == null || txt.trim().isEmpty) return message.displayText;

  String text = txt;

  // Strip [Menu] prefix
  if (text.trimLeft().startsWith('[Menu]')) {
    text = text.replaceFirst(RegExp(r'^\s*\[Menu\]\s*'), '');
  }

  if (text.trim().startsWith('{')) {
    try {
      final parsed = jsonDecode(text);
      if (parsed is Map) {
        final interBody = parsed['interactive']?['body']?['text'];
        if (interBody != null) return interBody.toString();
        final textBody = parsed['text']?['body'];
        if (textBody != null) return textBody.toString();
        final bodyText2 = parsed['body']?['text'];
        if (bodyText2 != null) return bodyText2.toString();
        if (parsed['body'] is String) return parsed['body'].toString();
      }
    } catch (_) {}
  }

  return text;
}

  // ─────────────────────────────────────────────
  // FORMAT TIME
  // ─────────────────────────────────────────────
String _formatTime() {
  final dt = Formatters.parseDate(message.timestamp);
  return Formatters.time(dt);
}
  // ─────────────────────────────────────────────
  // RICH TEXT
  // ─────────────────────────────────────────────
  Widget _buildRichText(String text,
      {required Color textColor, Color? linkColor}) {
    final lines = text.split('\n');
    final children = <Widget>[];

    for (final line in lines) {
      if (RegExp(r'^[═━─]{3,}$').hasMatch(line.trim())) {
        children.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Container(
            height: 1.5,
            decoration: BoxDecoration(
              gradient: KaapavTheme.goldGradient,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ));
        continue;
      }
      if (line.trim().isEmpty) {
        children.add(const SizedBox(height: 6));
        continue;
      }
      children.add(RichText(
        text: TextSpan(
          children:
              _parseInlineFormatting(line, textColor, linkColor),
        ),
      ));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: children,
    );
  }

  List<TextSpan> _parseInlineFormatting(
      String text, Color textColor, Color? linkColor) {
    final spans = <TextSpan>[];
    final regex = RegExp(
      r'(\*[^*]+\*)'
      r'|(_[^_]+_)'
      r'|(~[^~]+~)'
      r'|(```[^`]+```)'
      r'|(https?://[^\s<>")\]]+|www\.[^\s<>")\]]+)',
      caseSensitive: false,
    );

    final matches = regex.allMatches(text).toList();
    if (matches.isEmpty) {
      spans.add(TextSpan(
        text: text,
        style:
            TextStyle(fontSize: 15, height: 1.5, color: textColor),
      ));
      return spans;
    }

    int lastEnd = 0;
    for (final match in matches) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(
          text: text.substring(lastEnd, match.start),
          style: TextStyle(
              fontSize: 15, height: 1.5, color: textColor),
        ));
      }
      final matched = match.group(0)!;

      if (matched.startsWith('*') && matched.endsWith('*')) {
        spans.add(TextSpan(
          text: matched.substring(1, matched.length - 1),
          style: TextStyle(
              fontSize: 15,
              height: 1.5,
              color: textColor,
              fontWeight: FontWeight.w700),
        ));
      } else if (matched.startsWith('_') && matched.endsWith('_')) {
        spans.add(TextSpan(
          text: matched.substring(1, matched.length - 1),
          style: TextStyle(
              fontSize: 15,
              height: 1.5,
              color: textColor,
              fontStyle: FontStyle.italic),
        ));
      } else if (matched.startsWith('~') && matched.endsWith('~')) {
        spans.add(TextSpan(
          text: matched.substring(1, matched.length - 1),
          style: TextStyle(
              fontSize: 15,
              height: 1.5,
              color: textColor,
              decoration: TextDecoration.lineThrough),
        ));
      } else if (matched.startsWith('```') &&
          matched.endsWith('```')) {
        spans.add(TextSpan(
          text: matched.substring(3, matched.length - 3),
          style: TextStyle(
            fontSize: 14,
            height: 1.5,
            color: textColor,
            fontFamily: 'monospace',
            backgroundColor: textColor.withValues(alpha: 0.08),
          ),
        ));
      } else {
        final url = matched;
        final resolvedLinkColor = linkColor ??
            (isOutgoing
                ? Colors.white
                : const Color(0xFF0B57D0));
        spans.add(TextSpan(
          text: url,
          style: TextStyle(
            fontSize: 15,
            height: 1.5,
            color: resolvedLinkColor,
            decoration: TextDecoration.underline,
            decorationColor: resolvedLinkColor,
          ),
          recognizer: TapGestureRecognizer()
            ..onTap = () {
              final fullUrl = url.startsWith('http')
                  ? url
                  : 'https://$url';
              launchUrl(Uri.parse(fullUrl),
                  mode: LaunchMode.externalApplication);
            },
        ));
      }
      lastEnd = match.end;
    }

    if (lastEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastEnd),
        style:
            TextStyle(fontSize: 15, height: 1.5, color: textColor),
      ));
    }
    return spans;
  }

  // ─────────────────────────────────────────────
  // TEXT BUBBLE
  // ─────────────────────────────────────────────
  Widget _buildTextBubble(bool isDark) {
  final displayText = _getDisplayText();
  if (displayText.isEmpty) return const SizedBox.shrink();

  final isAutoReply = message.isAutoReply;
  final isNormalOutgoing = isOutgoing && !isAutoReply;

  final bubbleGradient = isNormalOutgoing
      ? KaapavTheme.luxeGoldGradient
      : LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: isDark ? 0.105 : 0.72),
            isAutoReply
                ? KaapavTheme.amethyst.withValues(alpha: isDark ? 0.13 : 0.08)
                : KaapavTheme.teal.withValues(alpha: isDark ? 0.055 : 0.05),
            Colors.black.withValues(alpha: isDark ? 0.14 : 0.00),
          ],
        );

  final textColor = isNormalOutgoing
      ? KaapavTheme.bgDeep
      : isDark
          ? KaapavTheme.white
          : KaapavTheme.dark;

  final timeColor = isNormalOutgoing
      ? KaapavTheme.bgDeep.withValues(alpha: 0.68)
      : isDark
          ? KaapavTheme.grayLight.withValues(alpha: 0.78)
          : KaapavTheme.gray.withValues(alpha: 0.82);

  final borderColor = isNormalOutgoing
      ? KaapavTheme.goldLight.withValues(alpha: 0.42)
      : isAutoReply
          ? KaapavTheme.amethyst.withValues(alpha: 0.24)
          : Colors.white.withValues(alpha: isDark ? 0.11 : 0.56);

  final linkColor = isNormalOutgoing
      ? KaapavTheme.bgDeep
      : isAutoReply
          ? KaapavTheme.amethyst
          : KaapavTheme.goldLight;

  return Container(
    constraints: const BoxConstraints(minWidth: 82),
    padding: const EdgeInsets.fromLTRB(13, 9, 13, 6),
    decoration: BoxDecoration(
      gradient: bubbleGradient,
      borderRadius: BorderRadius.only(
        topLeft: const Radius.circular(18),
        topRight: const Radius.circular(18),
        bottomLeft: Radius.circular(isOutgoing ? 18 : 6),
        bottomRight: Radius.circular(isOutgoing ? 6 : 18),
      ),
      border: Border.all(color: borderColor),
      boxShadow: [
        BoxShadow(
          color: isNormalOutgoing
              ? KaapavTheme.gold.withValues(alpha: 0.24)
              : isAutoReply
                  ? KaapavTheme.amethyst.withValues(alpha: 0.13)
                  : Colors.black.withValues(alpha: isDark ? 0.22 : 0.08),
          blurRadius: 18,
          spreadRadius: -7,
          offset: const Offset(0, 9),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.only(right: 46),
            child: _buildRichText(
              displayText,
              textColor: textColor,
              linkColor: linkColor,
            ),
          ),
        ),

        const SizedBox(height: 4),

        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isAutoReply && isOutgoing) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: KaapavTheme.amethyst.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: KaapavTheme.amethyst.withValues(alpha: 0.22),
                  ),
                ),
                child: const Text(
                  '🤖',
                  style: TextStyle(fontSize: 9),
                ),
              ),
              const SizedBox(width: 4),
            ],

            if (message.isEdited) ...[
              Icon(
                Icons.edit_rounded,
                size: 10.5,
                color: timeColor,
              ),
              const SizedBox(width: 2),
              Text(
                'edited ',
                style: TextStyle(
                  fontSize: 10,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w600,
                  color: timeColor,
                ),
              ),
            ],

            Text(
              _formatTime(),
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: timeColor,
              ),
            ),

            if (isOutgoing) ...[
              const SizedBox(width: 4),
              _buildStatusIcon(color: timeColor),
            ],
          ],
        ),
      ],
    ),
  );
}

  // ─────────────────────────────────────────────
  // BUTTON MESSAGE
  // ─────────────────────────────────────────────

Widget _buildButtonMessage(List<Map<String, dynamic>> buttons, bool isDark) {
  String? bodyText;
  String? footerText;
  String? headerText;

  if (message.text != null && message.text!.trim().startsWith('{')) {
    try {
      final parsed = jsonDecode(message.text!);

      if (parsed is Map) {
        final interactive = parsed['interactive'];

        if (interactive is Map) {
          final header = interactive['header'];
          final body = interactive['body'];
          final footer = interactive['footer'];

          if (header is Map) {
            headerText = header['text']?.toString().trim();
          }

          if (body is Map) {
            bodyText = body['text']?.toString().trim();
          }

          if (footer is Map) {
            footerText = footer['text']?.toString().trim();
          }
        }

        final parsedBody = parsed['body'];
        final parsedText = parsed['text'];

        if (bodyText == null || bodyText!.isEmpty) {
          if (parsedBody is Map) {
            bodyText = parsedBody['text']?.toString().trim();
          } else if (parsedBody != null) {
            bodyText = parsedBody.toString().trim();
          }
        }

        if (bodyText == null || bodyText!.isEmpty) {
          if (parsedText is Map) {
            bodyText = parsedText['body']?.toString().trim();
          } else if (parsedText != null) {
            bodyText = parsedText.toString().trim();
          }
        }
      }
    } catch (_) {}
  }

  if (bodyText == null && message.text != null) {
    String raw = message.text!;

    if (raw.trimLeft().startsWith('[Menu]')) {
      raw = raw.replaceFirst(RegExp(r'^\s*\[Menu\]\s*'), '');
    }

    final trimmed = raw.trim();
    if (trimmed.isNotEmpty) bodyText = trimmed;
  }

  bodyText ??= message.displayText;

  final isAutoReply = message.isAutoReply;
  final isNormalOutgoing = isOutgoing && !isAutoReply;

  final bubbleGradient = isNormalOutgoing
      ? KaapavTheme.luxeGoldGradient
      : LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: isDark ? 0.115 : 0.72),
            KaapavTheme.gold.withValues(alpha: isDark ? 0.075 : 0.055),
            KaapavTheme.amethyst.withValues(alpha: isDark ? 0.085 : 0.050),
            Colors.black.withValues(alpha: isDark ? 0.150 : 0.000),
          ],
        );

  final textColor = isNormalOutgoing
      ? KaapavTheme.bgDeep
      : isDark
          ? KaapavTheme.white
          : KaapavTheme.dark;

  final subTextColor = isNormalOutgoing
      ? KaapavTheme.bgDeep.withValues(alpha: 0.68)
      : isDark
          ? KaapavTheme.grayLight.withValues(alpha: 0.78)
          : KaapavTheme.gray.withValues(alpha: 0.82);

  final buttonTextColor = isNormalOutgoing
      ? KaapavTheme.bgDeep
      : KaapavTheme.goldLight;

  final borderColor = isNormalOutgoing
      ? KaapavTheme.goldLight.withValues(alpha: 0.42)
      : KaapavTheme.gold.withValues(alpha: isDark ? 0.22 : 0.30);

  return Container(
    constraints: const BoxConstraints(minWidth: 230, maxWidth: 350),
    decoration: BoxDecoration(
      gradient: bubbleGradient,
      borderRadius: BorderRadius.only(
        topLeft: const Radius.circular(20),
        topRight: const Radius.circular(20),
        bottomLeft: Radius.circular(isOutgoing ? 20 : 7),
        bottomRight: Radius.circular(isOutgoing ? 7 : 20),
      ),
      border: Border.all(color: borderColor),
      boxShadow: [
        BoxShadow(
          color: isNormalOutgoing
              ? KaapavTheme.gold.withValues(alpha: 0.25)
              : KaapavTheme.gold.withValues(alpha: isDark ? 0.13 : 0.08),
          blurRadius: 22,
          spreadRadius: -8,
          offset: const Offset(0, 10),
        ),
      ],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.only(
        topLeft: const Radius.circular(20),
        topRight: const Radius.circular(20),
        bottomLeft: Radius.circular(isOutgoing ? 20 : 7),
        bottomRight: Radius.circular(isOutgoing ? 7 : 20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (headerText != null && headerText.isNotEmpty)
            Container(
              padding: const EdgeInsets.fromLTRB(14, 13, 14, 7),
              decoration: BoxDecoration(
                color: isNormalOutgoing
                    ? Colors.white.withValues(alpha: 0.14)
                    : KaapavTheme.gold.withValues(alpha: 0.085),
                border: Border(
                  bottom: BorderSide(
                    color: borderColor.withValues(alpha: 0.55),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.auto_awesome_rounded,
                    size: 15,
                    color: buttonTextColor,
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      headerText,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w900,
                        color: textColor,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          if (bodyText != null && bodyText.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 13, 14, 10),
              child: _buildRichText(
                bodyText,
                textColor: textColor,
                linkColor: buttonTextColor,
              ),
            ),

          if (footerText != null && footerText.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
              child: Text(
                footerText,
                style: TextStyle(
                  fontSize: 11.5,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w600,
                  color: subTextColor,
                  height: 1.35,
                ),
              ),
            ),

          if (buttons.isNotEmpty) ...[
            _buildGradientDivider(isOutgoing),
            ...buttons.asMap().entries.expand((entry) {
              final idx = entry.key;
              final btn = entry.value;

              return [
                if (idx > 0) _buildGradientDivider(isOutgoing),
                _buildWhatsAppButton(
                  btn,
                  idx,
                  false,
                  isDark,
                  isOutgoing,
                  buttonTextColor,
                  subTextColor,
                ),
              ];
            }),
          ],

          Padding(
            padding: const EdgeInsets.fromLTRB(10, 6, 12, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (message.isAutoReply) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: KaapavTheme.amethyst.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: KaapavTheme.amethyst.withValues(alpha: 0.20),
                      ),
                    ),
                    child: const Text(
                      '🤖',
                      style: TextStyle(fontSize: 9),
                    ),
                  ),
                  const SizedBox(width: 4),
                ],
                if (message.isEdited) ...[
                  Icon(Icons.edit_rounded, size: 10.5, color: subTextColor),
                  const SizedBox(width: 2),
                  Text(
                    'edited ',
                    style: TextStyle(
                      fontSize: 10,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w600,
                      color: subTextColor,
                    ),
                  ),
                ],
                Text(
                  _formatTime(),
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: subTextColor,
                  ),
                ),
                if (isOutgoing) ...[
                  const SizedBox(width: 4),
                  _buildStatusIcon(color: subTextColor),
                ],
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _buildGradientDivider(bool isOutgoing) {
  return Container(
    height: 1,
    decoration: BoxDecoration(
      gradient: isOutgoing
          ? LinearGradient(
              colors: [
                KaapavTheme.bgDeep.withValues(alpha: 0.05),
                KaapavTheme.bgDeep.withValues(alpha: 0.18),
                KaapavTheme.bgDeep.withValues(alpha: 0.05),
              ],
            )
          : LinearGradient(
              colors: [
                Colors.white.withValues(alpha: 0.04),
                KaapavTheme.gold.withValues(alpha: 0.28),
                Colors.white.withValues(alpha: 0.04),
              ],
            ),
    ),
  );
}

Widget _buildWhatsAppButton(
  Map<String, dynamic> btn,
  int index,
  bool showTopBorder,
  bool isDark,
  bool isOutgoing,
  Color buttonTextColor,
  Color dividerColor,
) {
  final title = btn['title']?.toString() ?? btn['text']?.toString() ?? 'Option';
  final id = btn['id']?.toString() ?? title;

  String? emoji;
  String buttonText = title;

  final emojiRegex = RegExp(
    r'^[\u{1F600}-\u{1F64F}\u{1F300}-\u{1F5FF}\u{1F680}-\u{1F6FF}\u{1F700}-\u{1F77F}\u{1F780}-\u{1F7FF}\u{1F800}-\u{1F8FF}\u{1F900}-\u{1F9FF}\u{1FA00}-\u{1FA6F}\u{1FA70}-\u{1FAFF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}]',
    unicode: true,
  );

  final emojiMatch = emojiRegex.firstMatch(title);
  if (emojiMatch != null) {
    emoji = emojiMatch.group(0);
    buttonText = title.replaceFirst(emojiRegex, '').trim();
  }

  final hoverColor = isOutgoing
      ? KaapavTheme.bgDeep.withValues(alpha: 0.08)
      : KaapavTheme.gold.withValues(alpha: isDark ? 0.095 : 0.080);

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
          padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 14),
          decoration: BoxDecoration(
            color: _hoveredButton == index ? hoverColor : Colors.transparent,
            border: showTopBorder
                ? Border(top: BorderSide(color: dividerColor, width: 1))
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: buttonTextColor.withValues(
                    alpha: isOutgoing ? 0.10 : 0.13,
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: buttonTextColor.withValues(alpha: 0.18),
                  ),
                ),
                child: Icon(
                  Icons.touch_app_rounded,
                  size: 14,
                  color: buttonTextColor,
                ),
              ),
              const SizedBox(width: 8),
              if (emoji != null) ...[
                Text(
                  emoji,
                  style: const TextStyle(fontSize: 15),
                ),
                const SizedBox(width: 5),
              ],
              Flexible(
                child: Text(
                  buttonText,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w900,
                    color: buttonTextColor,
                    letterSpacing: -0.05,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}


  // ─────────────────────────────────────────────
  // IMAGE BUBBLE
  // ─────────────────────────────────────────────
  Widget _buildImageBubble(bool isDark) {
  final isAutoReply = message.isAutoReply;
  final isNormalOutgoing = isOutgoing && !isAutoReply;

  final radius = BorderRadius.only(
    topLeft: const Radius.circular(20),
    topRight: const Radius.circular(20),
    bottomLeft: Radius.circular(isOutgoing ? 20 : 7),
    bottomRight: Radius.circular(isOutgoing ? 7 : 20),
  );

  final bubbleGradient = isNormalOutgoing
      ? KaapavTheme.luxeGoldGradient
      : LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: isDark ? 0.105 : 0.72),
            KaapavTheme.sapphire.withValues(alpha: isDark ? 0.075 : 0.050),
            Colors.black.withValues(alpha: isDark ? 0.145 : 0.000),
          ],
        );

  final textColor = isNormalOutgoing
      ? KaapavTheme.bgDeep
      : isDark
          ? KaapavTheme.white
          : KaapavTheme.dark;

  final subTextColor = isNormalOutgoing
      ? KaapavTheme.bgDeep.withValues(alpha: 0.68)
      : isDark
          ? KaapavTheme.grayLight.withValues(alpha: 0.78)
          : KaapavTheme.gray.withValues(alpha: 0.82);

  final borderColor = isNormalOutgoing
      ? KaapavTheme.goldLight.withValues(alpha: 0.42)
      : Colors.white.withValues(alpha: isDark ? 0.12 : 0.58);

  if (message.mediaUrl == null || message.mediaUrl!.isEmpty) {
    return Container(
      constraints: const BoxConstraints(minWidth: 210, maxWidth: 330),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        gradient: bubbleGradient,
        borderRadius: radius,
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: isNormalOutgoing
                ? KaapavTheme.gold.withValues(alpha: 0.24)
                : KaapavTheme.sapphire.withValues(alpha: isDark ? 0.14 : 0.08),
            blurRadius: 20,
            spreadRadius: -8,
            offset: const Offset(0, 10),
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
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: isNormalOutgoing
                      ? KaapavTheme.bgDeep.withValues(alpha: 0.09)
                      : KaapavTheme.sapphire.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: isNormalOutgoing
                        ? KaapavTheme.bgDeep.withValues(alpha: 0.12)
                        : KaapavTheme.sapphire.withValues(alpha: 0.20),
                  ),
                ),
                child: Icon(
                  Icons.image_rounded,
                  color: isNormalOutgoing ? KaapavTheme.bgDeep : KaapavTheme.sapphire,
                  size: 25,
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Photo',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Image not available',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: subTextColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (message.mediaCaption != null && message.mediaCaption!.isNotEmpty) ...[
            const SizedBox(height: 10),
            _buildRichText(
              message.mediaCaption!,
              textColor: textColor,
              linkColor: isNormalOutgoing ? KaapavTheme.bgDeep : KaapavTheme.goldLight,
            ),
          ],
          const SizedBox(height: 7),
          _buildFooter(isDark),
        ],
      ),
    );
  }

  return GestureDetector(
    onTap: () => Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FullScreenImage(
          imageUrl: message.mediaUrl!,
          caption: message.mediaCaption,
          senderName: isIncoming ? 'Customer' : 'You',
          timestamp: _formatTime(),
        ),
      ),
    ),
    child: Container(
      constraints: const BoxConstraints(minWidth: 230, maxWidth: 350),
      decoration: BoxDecoration(
        gradient: bubbleGradient,
        borderRadius: radius,
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: isNormalOutgoing
                ? KaapavTheme.gold.withValues(alpha: 0.24)
                : KaapavTheme.sapphire.withValues(alpha: isDark ? 0.14 : 0.08),
            blurRadius: 22,
            spreadRadius: -8,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                CachedNetworkImage(
                  imageUrl: message.mediaUrl!,
                  width: double.infinity,
                  height: 210,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    height: 210,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.06),
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation(KaapavTheme.gold),
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    height: 210,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.06),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.broken_image_rounded,
                          color: subTextColor,
                          size: 46,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Failed to load image',
                          style: TextStyle(
                            color: subTextColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 9,
                  right: 9,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                      child: Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.34),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.16),
                          ),
                        ),
                        child: const Icon(
                          Icons.zoom_in_rounded,
                          color: KaapavTheme.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            if (message.mediaCaption != null && message.mediaCaption!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
                child: _buildRichText(
                  message.mediaCaption!,
                  textColor: textColor,
                  linkColor: isNormalOutgoing ? KaapavTheme.bgDeep : KaapavTheme.goldLight,
                ),
              ),

            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
              child: _buildFooter(isDark),
            ),
          ],
        ),
      ),
    ),
  );
}

  // ─────────────────────────────────────────────
  // DOCUMENT BUBBLE
  // ─────────────────────────────────────────────
  Widget _buildDocumentBubble(bool isDark) {
    final filename = message.mediaCaption ?? 'Document';
    final parts = filename.split('.');
    final ext =
        parts.length > 1 ? parts.last.toUpperCase() : 'FILE';
    final incomingBg =
        isDark ? const Color(0xFF1E1E1E) : KaapavTheme.white;
    final incomingBorder =
        isDark ? const Color(0xFF2A2A2A) : KaapavTheme.border;
    final incomingText =
        isDark ? const Color(0xFFEEEEEE) : KaapavTheme.dark;
    final incomingSubText =
        isDark ? const Color(0xFF888888) : KaapavTheme.gray;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: incomingBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: incomingBorder),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _getFileColor(ext)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(_getFileIcon(ext),
                    color: _getFileColor(ext), size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(filename,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: incomingText,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(ext,
                        style: TextStyle(
                            fontSize: 12,
                            color: incomingSubText)),
                  ],
                ),
              ),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: KaapavTheme.goldGradient,
                  shape: BoxShape.circle,
                  boxShadow: [KaapavTheme.goldShadow],
                ),
                child: const Icon(Icons.download,
                    color: Colors.white, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Text(_formatTime(),
                style: TextStyle(
                  fontSize: 11,
                  color: isDark
                      ? const Color(0xFF888888)
                      : KaapavTheme.grayLight,
                )),
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

  // ─────────────────────────────────────────────
  // AUDIO BUBBLE
  // ─────────────────────────────────────────────
  Widget _buildAudioBubble(bool isDark) {
    final incomingBg =
        isDark ? const Color(0xFF1E1E1E) : KaapavTheme.white;
    final incomingBorder =
        isDark ? const Color(0xFF2A2A2A) : KaapavTheme.border;

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: isOutgoing ? KaapavTheme.goldGradient : null,
        color: isOutgoing ? null : incomingBg,
        borderRadius: BorderRadius.circular(24),
        border: isOutgoing
            ? null
            : Border.all(color: incomingBorder),
        boxShadow: [
          BoxShadow(
            color: isOutgoing
                ? KaapavTheme.gold.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
          )
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: _toggleAudio,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isOutgoing
                    ? Colors.white.withValues(alpha: 0.2)
                    : null,
                gradient: isOutgoing
                    ? null
                    : KaapavTheme.goldGradient,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isPlaying ? Icons.pause : Icons.play_arrow,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SliderTheme(
              data: SliderThemeData(
                trackHeight: 3,
                thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 6),
                activeTrackColor: isOutgoing
                    ? Colors.white
                    : KaapavTheme.gold,
                inactiveTrackColor: isOutgoing
                    ? Colors.white38
                    : KaapavTheme.border,
                thumbColor: isOutgoing
                    ? Colors.white
                    : KaapavTheme.gold,
                overlayShape:
                    SliderComponentShape.noOverlay,
              ),
              child: Slider(
                value: _audioDuration.inMilliseconds > 0
                    ? _audioPosition.inMilliseconds /
                        _audioDuration.inMilliseconds
                    : 0,
                onChanged: (v) {
                  _audioPlayer?.seek(Duration(
                      milliseconds: (v *
                              _audioDuration.inMilliseconds)
                          .round()));
                },
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _isPlaying
                ? _fmt(_audioPosition)
                : _fmt(_audioDuration),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isOutgoing
                  ? Colors.white.withValues(alpha: 0.8)
                  : (isDark
                      ? const Color(0xFF888888)
                      : KaapavTheme.gray),
            ),
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
        if (mounted) {
          setState(() {
            _isPlaying = false;
            _audioPosition = Duration.zero;
          });
        }
      });
      await _audioPlayer!.play(UrlSource(message.mediaUrl!));
      setState(() => _isPlaying = true);
    }
  }

  // ─────────────────────────────────────────────
  // VIDEO BUBBLE
  // ─────────────────────────────────────────────
  Widget _buildVideoBubble(bool isDark) {
    final incomingBorder =
        isDark ? const Color(0xFF2A2A2A) : KaapavTheme.border;

    return GestureDetector(
      onTap: () {
        if (message.mediaUrl != null) {
          launchUrl(Uri.parse(message.mediaUrl!),
              mode: LaunchMode.externalApplication);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: isOutgoing
              ? null
              : Border.all(color: incomingBorder),
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
                child: const Icon(Icons.videocam,
                    color: Colors.white54, size: 48),
              ),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: KaapavTheme.goldGradient,
                  shape: BoxShape.circle,
                  boxShadow: [KaapavTheme.goldShadow],
                ),
                child: const Icon(Icons.play_arrow,
                    color: Colors.white, size: 32),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black54,
                        Colors.transparent
                      ],
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment:
                        MainAxisAlignment.end,
                    children: [
                      Text(_formatTime(),
                          style: const TextStyle(
                              fontSize: 11,
                              color: Colors.white70)),
                      if (isOutgoing) ...[
                        const SizedBox(width: 4),
                        _buildStatusIcon(
                            color: Colors.white70),
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

  // ─────────────────────────────────────────────
  // LOCATION BUBBLE
  // ─────────────────────────────────────────────
  Widget _buildLocationBubble(bool isDark) {
    final incomingBg =
        isDark ? const Color(0xFF1E1E1E) : KaapavTheme.white;
    final incomingBorder =
        isDark ? const Color(0xFF2A2A2A) : KaapavTheme.border;
    final textColor =
        isDark ? const Color(0xFFEEEEEE) : KaapavTheme.dark;
    final subTextColor =
        isDark ? const Color(0xFF888888) : KaapavTheme.gray;
    final timeColor =
        isDark ? const Color(0xFF888888) : KaapavTheme.grayLight;

    return Container(
      decoration: BoxDecoration(
        color: incomingBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: incomingBorder),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 120,
            decoration: const BoxDecoration(
              gradient: KaapavTheme.goldGradient,
              borderRadius: BorderRadius.vertical(
                  top: Radius.circular(16)),
            ),
            child: const Center(
              child: Icon(Icons.location_on,
                  color: Colors.white, size: 48),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('📍 Location Shared',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    )),
                const SizedBox(height: 4),
                Text('Tap to view on map',
                    style: TextStyle(
                        fontSize: 13, color: subTextColor)),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(_formatTime(),
                      style: TextStyle(
                          fontSize: 11, color: timeColor)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // STICKER BUBBLE
  // ─────────────────────────────────────────────
  Widget _buildStickerBubble() {
    if (message.mediaUrl == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: isOutgoing
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
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
            child: Center(
                child: CircularProgressIndicator(strokeWidth: 2)),
          ),
          errorWidget: (_, __, ___) =>
              const Icon(Icons.emoji_emotions, size: 100),
        ),
        const SizedBox(height: 4),
        Text(_formatTime(),
            style: const TextStyle(
                fontSize: 11, color: KaapavTheme.grayLight)),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // INTERACTIVE BUBBLE
  // ─────────────────────────────────────────────
  Widget _buildInteractiveBubble(bool isDark) {
    final displayText = _getDisplayText();
    if (displayText.isEmpty) return const SizedBox.shrink();

    final incomingBg =
        isDark ? const Color(0xFF1E1E1E) : KaapavTheme.white;
    final incomingBorder =
        isDark ? const Color(0xFF2A2A2A) : KaapavTheme.border;
    final chipBg = isDark
        ? const Color(0xFF2A2A2A)
        : KaapavTheme.cream;

    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: isOutgoing ? KaapavTheme.goldGradient : null,
        color: isOutgoing ? null : incomingBg,
        borderRadius: BorderRadius.circular(16),
        border: isOutgoing
            ? null
            : Border.all(color: incomingBorder),
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
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isOutgoing
                  ? Colors.white.withValues(alpha: 0.2)
                  : chipBg,
              borderRadius: BorderRadius.circular(8),
              border: isOutgoing
                  ? null
                  : Border.all(
                      color: KaapavTheme.gold
                          .withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle,
                    size: 14,
                    color: isOutgoing
                        ? Colors.white
                        : KaapavTheme.gold),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    displayText,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isOutgoing
                          ? Colors.white
                          : KaapavTheme.gold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          _buildFooter(isDark),
        ],
      ),
    );
  }

Widget _buildUnsupportedBubble(bool isDark) {
  Map<String, dynamic>? meta;

  final raw = message.mediaCaption?.trim() ?? '';

  if (raw.startsWith('{')) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        meta = Map<String, dynamic>.from(decoded);
      }
    } catch (_) {}
  }

  Map<String, dynamic>? firstError;
  final errors = meta?['errors'];

  if (errors is List && errors.isNotEmpty && errors.first is Map) {
    firstError = Map<String, dynamic>.from(errors.first as Map);
  }

  final code = firstError?['code']?.toString() ?? '';
  final title = firstError?['title']?.toString() ??
      firstError?['message']?.toString() ??
      'Unsupported WhatsApp message';

  final details = firstError?['details']?.toString() ??
      'Meta did not expose the readable message body for this webhook.';

  final isNormalOutgoing = isOutgoing && !message.isAutoReply;

  final textColor = isNormalOutgoing
      ? KaapavTheme.bgDeep
      : isDark
          ? KaapavTheme.white
          : KaapavTheme.dark;

  final subTextColor = isNormalOutgoing
      ? KaapavTheme.bgDeep.withValues(alpha: 0.68)
      : isDark
          ? KaapavTheme.grayLight.withValues(alpha: 0.78)
          : KaapavTheme.gray.withValues(alpha: 0.82);

  return Container(
    constraints: const BoxConstraints(minWidth: 230, maxWidth: 350),
    padding: const EdgeInsets.fromLTRB(13, 11, 13, 8),
    decoration: BoxDecoration(
      gradient: isNormalOutgoing
          ? KaapavTheme.luxeGoldGradient
          : LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: isDark ? 0.105 : 0.72),
                KaapavTheme.amber.withValues(alpha: isDark ? 0.09 : 0.06),
                Colors.black.withValues(alpha: isDark ? 0.145 : 0.000),
              ],
            ),
      borderRadius: BorderRadius.only(
        topLeft: const Radius.circular(20),
        topRight: const Radius.circular(20),
        bottomLeft: Radius.circular(isOutgoing ? 20 : 7),
        bottomRight: Radius.circular(isOutgoing ? 7 : 20),
      ),
      border: Border.all(
        color: KaapavTheme.amber.withValues(alpha: isDark ? 0.26 : 0.34),
      ),
      boxShadow: [
        BoxShadow(
          color: KaapavTheme.amber.withValues(alpha: isDark ? 0.14 : 0.08),
          blurRadius: 21,
          spreadRadius: -8,
          offset: const Offset(0, 10),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: KaapavTheme.amber.withValues(alpha: 0.14),
                shape: BoxShape.circle,
                border: Border.all(
                  color: KaapavTheme.amber.withValues(alpha: 0.22),
                ),
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: KaapavTheme.amber,
                size: 19,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w900,
                  color: textColor,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        Text(
          details,
          style: TextStyle(
            fontSize: 12,
            height: 1.35,
            fontWeight: FontWeight.w600,
            color: subTextColor,
          ),
        ),

        if (code.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: KaapavTheme.amber.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: KaapavTheme.amber.withValues(alpha: 0.20),
              ),
            ),
            child: Text(
              'Meta code: $code',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: KaapavTheme.amber,
              ),
            ),
          ),
        ],

        if (raw.isNotEmpty) ...[
          const SizedBox(height: 9),
          InkWell(
            onTap: () {
              Clipboard.setData(ClipboardData(text: raw));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Raw webhook copied')),
              );
            },
            borderRadius: BorderRadius.circular(999),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: isDark ? 0.08 : 0.42),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: Colors.white.withValues(alpha: isDark ? 0.10 : 0.46),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.content_copy_rounded,
                    size: 13,
                    color: subTextColor,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Copy raw webhook',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: subTextColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],

        const SizedBox(height: 8),

        Align(
          alignment: Alignment.centerRight,
          child: _buildFooter(isDark),
        ),
      ],
    ),
  );
}

  // ─────────────────────────────────────────────
  // REACTION PICKER
  // ─────────────────────────────────────────────
  void _showReactionPicker(BuildContext context) {
  final emojis = ['👍', '❤️', '😂', '😮', '😢', '🙏'];

  showDialog(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.10),
    builder: (ctx) => Stack(
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(ctx),
          child: Container(color: Colors.transparent),
        ),
        Positioned(
          bottom: MediaQuery.of(context).size.height * 0.40,
          left: 34,
          right: 34,
          child: Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withValues(alpha: 0.14),
                        KaapavTheme.gold.withValues(alpha: 0.075),
                        Colors.black.withValues(alpha: 0.16),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.13),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.28),
                        blurRadius: 26,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: emojis.map((e) {
                      return GestureDetector(
                        onTap: () {
                          setState(() => _reaction = _reaction == e ? null : e);
                          Navigator.pop(ctx);
                          HapticFeedback.lightImpact();
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 4,
                          ),
                          child: Text(
                            e,
                            style: const TextStyle(fontSize: 27),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

  // ─────────────────────────────────────────────
  // FOOTER
  // ─────────────────────────────────────────────
  Widget _buildFooter(bool isDark) {
  final isAutoReply = message.isAutoReply;
  final isNormalOutgoing = isOutgoing && !isAutoReply;

  final timeColor = isNormalOutgoing
      ? KaapavTheme.bgDeep.withValues(alpha: 0.68)
      : isDark
          ? KaapavTheme.grayLight.withValues(alpha: 0.78)
          : KaapavTheme.gray.withValues(alpha: 0.82);

  return Row(
    mainAxisSize: MainAxisSize.min,
    mainAxisAlignment: MainAxisAlignment.end,
    children: [
      if (isAutoReply && isOutgoing) ...[
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          decoration: BoxDecoration(
            color: KaapavTheme.amethyst.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: KaapavTheme.amethyst.withValues(alpha: 0.20),
            ),
          ),
          child: const Text('🤖', style: TextStyle(fontSize: 9)),
        ),
        const SizedBox(width: 4),
      ],
      if (message.isEdited) ...[
        Icon(Icons.edit_rounded, size: 10.5, color: timeColor),
        const SizedBox(width: 2),
        Text(
          'edited ',
          style: TextStyle(
            fontSize: 10,
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.w600,
            color: timeColor,
          ),
        ),
      ],
      Text(
        _formatTime(),
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
          color: timeColor,
        ),
      ),
      if (isOutgoing) ...[
        const SizedBox(width: 4),
        _buildStatusIcon(color: timeColor),
      ],
    ],
  );
}

  // ─────────────────────────────────────────────
  // STATUS ICON
  // ─────────────────────────────────────────────
  Widget _buildStatusIcon({Color? color}) {
    final iconColor = color ??
        (isOutgoing
            ? Colors.white.withValues(alpha: 0.7)
            : KaapavTheme.grayLight);

    switch (message.status) {
      case 'sending':
        return Icon(Icons.schedule,
            size: 14,
            color: iconColor.withValues(alpha: 0.5));
      case 'sent':
        return Icon(Icons.check, size: 14, color: iconColor);
      case 'delivered':
        return Icon(Icons.done_all, size: 14, color: iconColor);
      case 'read':
        return const Icon(Icons.done_all,
            size: 14, color: KaapavTheme.readBlue);
      case 'failed':
        return GestureDetector(
          onTap: () => widget.onRetry?.call(message),
          child: const Icon(Icons.error_outline,
              size: 14, color: KaapavTheme.error),
        );
      default:
        return Icon(Icons.check, size: 14, color: iconColor);
    }
  }
}