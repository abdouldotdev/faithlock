import 'package:flutter/material.dart';

import '../../../core/theme/cozy/cozy.dart';

/// Chunky bordered text input field.
///
/// - Single-line by default ([maxLines] = 1).
/// - Multiline (textarea) via [maxLines] > 1.
/// - White surface fill, [CozyColors.outline] border, [CozyTokens.radiusMd].
///
/// ```dart
/// CozyTextField(
///   controller: _titleController,
///   hintText: 'A name for this reflection…',
/// )
///
/// CozyTextField(
///   hintText: 'Write down what resonates with you…',
///   maxLines: 6,
///   minLines: 4,
/// )
/// ```
class CozyTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? hintText;
  final int maxLines;
  final int? minLines;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;

  const CozyTextField({
    super.key,
    this.controller,
    this.hintText,
    this.maxLines = 1,
    this.minLines,
    this.textInputAction,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final bool multiline = maxLines > 1;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: CozyColors.surface,
        borderRadius: BorderRadius.circular(CozyTokens.radiusMd),
        border: Border.all(
          color: CozyColors.outline,
          width: CozyTokens.borderWidth,
        ),
        boxShadow: CozyTokens.shadowHard,
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        minLines: minLines,
        textInputAction: textInputAction ??
            (multiline ? TextInputAction.newline : TextInputAction.done),
        onChanged: onChanged,
        style: CozyText.body.copyWith(color: CozyColors.ink),
        decoration: InputDecoration(
          // Defeat the app-level inputDecorationTheme (filled: true) — the
          // rounded [Container] is the only surface; a themed fill would paint
          // a sharp-cornered rectangle bleeding past the radius.
          filled: false,
          hintText: hintText,
          hintStyle: CozyText.body.copyWith(color: CozyColors.inkMuted),
          contentPadding: EdgeInsets.symmetric(
            horizontal: CozyTokens.space16,
            vertical: multiline ? CozyTokens.space16 : CozyTokens.space12,
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
      ),
    );
  }
}
