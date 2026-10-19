import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/theme/cozy/cozy.dart';
import 'cozy_toast.dart';

/// Shares [verseText] (+ [reference]) as a polished verse **image** via the
/// system share sheet — the single source of truth used by both the
/// Verse-of-the-Day card and the Bible reader's selection toolbar.
///
/// Renders a designed card off-screen, captures it to a hi-res PNG, writes it
/// to a temp file and shares the file alongside the verse text. Falls back to a
/// plain-text share if the image export / file share fails on this device.
/// Pass [sharePositionOrigin] for a precise iPad popover anchor; otherwise it's
/// derived from [context]'s render box. Feedback uses [CozyToast] only — never
/// GetX snackbars (they crash).
Future<void> shareVerseAsImage(
  BuildContext context, {
  required String verseText,
  required String reference,
  Rect? sharePositionOrigin,
}) async {
  final origin = sharePositionOrigin ?? _shareOrigin(context);
  final text = '"$verseText"\n— $reference\n\nvia FaithLock';
  try {
    final bytes = await _captureShareCard(context, verseText, reference);
    if (!context.mounted) return;
    if (bytes == null) {
      CozyToast.show(context, "Couldn't create the image. Try again.",
          variant: CozyToastVariant.error);
      return;
    }

    final dir = await getTemporaryDirectory();
    final file = File(
      '${dir.path}/faithlock_verse_${DateTime.now().millisecondsSinceEpoch}.png',
    );
    await file.writeAsBytes(bytes);

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'image/png')],
        text: text,
        sharePositionOrigin: origin,
      ),
    );
  } catch (e) {
    debugPrint('[shareVerseAsImage] image share failed: $e');
    // Graceful fallback: share the verse as plain text so sharing still works
    // even if the image export / file share fails on this device.
    try {
      await SharePlus.instance.share(
        ShareParams(text: text, sharePositionOrigin: origin),
      );
    } catch (e2) {
      debugPrint('[shareVerseAsImage] text share failed: $e2');
      if (context.mounted) {
        CozyToast.show(context, "Couldn't share the verse.",
            variant: CozyToastVariant.error);
      }
    }
  }
}

/// The anchor rect the iPad share popover points at (required on iPad,
/// harmless on iPhone). Derived from [context]'s render box.
Rect? _shareOrigin(BuildContext context) {
  final box = context.findRenderObject() as RenderBox?;
  if (box == null || !box.hasSize) return null;
  return box.localToGlobal(Offset.zero) & box.size;
}

/// Renders [_VerseShareCard] off-screen via an [OverlayEntry] and captures it
/// to a high-resolution PNG. Off-screen positioning lets it lay out and paint
/// (required for [RenderRepaintBoundary.toImage]) without ever flashing on
/// screen.
Future<Uint8List?> _captureShareCard(
  BuildContext context,
  String verseText,
  String reference,
) async {
  final overlay = Overlay.of(context, rootOverlay: true);
  final boundaryKey = GlobalKey();
  const Size logical = Size(360, 450);

  final entry = OverlayEntry(
    builder: (_) => Positioned(
      left: -10000, // off-screen
      top: 0,
      child: Material(
        type: MaterialType.transparency,
        child: RepaintBoundary(
          key: boundaryKey,
          child: _VerseShareCard(
            size: logical,
            verseText: verseText,
            reference: reference,
          ),
        ),
      ),
    ),
  );

  overlay.insert(entry);
  try {
    // Let the freshly-inserted subtree build, lay out and PAINT. One endOfFrame
    // isn't always enough (the entry was inserted mid-frame), so pump a couple
    // of frames with a short gap — this is the part that flaked on real devices.
    await WidgetsBinding.instance.endOfFrame;
    await Future<void>.delayed(const Duration(milliseconds: 32));
    await WidgetsBinding.instance.endOfFrame;

    final boundary =
        boundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return null;

    // Retry briefly if the boundary still hasn't painted (debug builds only;
    // debugNeedsPaint is always false in release, so this is a no-op there).
    var tries = 0;
    while (boundary.debugNeedsPaint && tries < 8) {
      await Future<void>.delayed(const Duration(milliseconds: 16));
      tries++;
    }

    // Defensive: a failed capture returns null (→ "couldn't create image"
    // toast) instead of throwing all the way up to the text-share fallback.
    try {
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('[shareVerseAsImage] toImage failed: $e');
      return null;
    }
  } finally {
    entry.remove();
  }
}

/// The shareable verse artwork — a polished, self-contained design rendered to
/// an image (not a screenshot of any on-screen card). Warm cozy palette, chunky
/// framed panel, oversized quote mark, and a subtle FaithLock wordmark.
class _VerseShareCard extends StatelessWidget {
  final Size size;
  final String verseText;
  final String reference;

  const _VerseShareCard({
    required this.size,
    required this.verseText,
    required this.reference,
  });

  @override
  Widget build(BuildContext context) {
    // Height is intentionally NOT fixed: the card wraps its content so short
    // verses stay compact and long ones never overflow (the old fixed 450 +
    // Expanded clipped long verses and left dead space above short ones).
    return Container(
      width: size.width,
      color: CozyColors.background,
      padding: const EdgeInsets.all(20),
      child: Container(
        decoration: ShapeDecoration(
          color: CozyColors.surface,
          shape: CozyTokens.smooth(
            CozyTokens.radiusLg,
            side: const BorderSide(
              color: CozyColors.outline,
              width: CozyTokens.borderWidth,
            ),
          ),
          shadows: CozyTokens.shadowHard,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Header: "VERSE OF THE DAY" flanked by rules, dash below ──
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 20, 22, 0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: _rule()),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          'VERSE OF THE DAY',
                          style: TextStyle(
                            fontFamily: 'Satoshi',
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: CozyColors.primary,
                            letterSpacing: 2.0,
                          ),
                        ),
                      ),
                      Expanded(child: _rule()),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _dash(),
                ],
              ),
            ),
            // ── Body (left/start-aligned): quote, verse, dash, reference ──
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '“',
                    style: TextStyle(
                      fontFamily: 'Satoshi',
                      fontSize: 40,
                      height: 0.55,
                      fontWeight: FontWeight.w800,
                      color: CozyColors.primary.withValues(alpha: 0.9),
                    ),
                  ),
                  Text(
                    verseText,
                    textAlign: TextAlign.start,
                    style: const TextStyle(
                      fontFamily: 'Satoshi',
                      fontSize: 18,
                      height: 1.3,
                      fontWeight: FontWeight.w600,
                      color: CozyColors.ink,
                      letterSpacing: -0.1,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _dash(width: 30),
                  const SizedBox(height: 10),
                  Text(
                    reference.toUpperCase(),
                    textAlign: TextAlign.start,
                    style: const TextStyle(
                      fontFamily: 'Satoshi',
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: CozyColors.primary,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            // ── Footer: hairline divider + small Download wordmark ──
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 14, 24, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 1,
                    color: CozyColors.outline.withValues(alpha: 0.15),
                  ),
                  const SizedBox(height: 10),
                  _downloadWordmark(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// A thin horizontal rule used to flank the header label.
  Widget _rule() => Container(
        height: 1.5,
        color: CozyColors.primary.withValues(alpha: 0.35),
      );

  /// A short rounded accent dash (header underline + verse/reference divider).
  Widget _dash({double width = 22}) => Container(
        width: width,
        height: 3,
        decoration: BoxDecoration(
          color: CozyColors.primary,
          borderRadius: BorderRadius.circular(2),
        ),
      );

  Widget _downloadWordmark() {
    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.file_download_outlined,
          size: 12,
          color: CozyColors.primary,
        ),
        SizedBox(width: 5),
        Text(
          'Download FaithLock',
          style: TextStyle(
            fontFamily: 'Satoshi',
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: CozyColors.ink,
            letterSpacing: 0.1,
          ),
        ),
      ],
    );
  }
}
