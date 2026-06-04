import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// 解析文本中的 #标签，返回带颜色的 TextSpan 列表
/// #标签 渲染为 [tagStyle] 样式，其余文字为 [normalStyle] 样式
/// [onTagTap] 不为 null 时，标签文字可点击，回调参数为标签名（不含 #）
List<TextSpan> buildTaggedTextSpans({
  required String text,
  required TextStyle normalStyle,
  required TextStyle tagStyle,
  int? maxLines,
  void Function(String tag)? onTagTap,
}) {
  final spans = <TextSpan>[];
  final regex = RegExp(r'(#[^\s#]+)');
  final matches = regex.allMatches(text);

  int lastEnd = 0;
  for (final match in matches) {
    // 添加标签前的普通文字
    if (match.start > lastEnd) {
      spans.add(TextSpan(
        text: text.substring(lastEnd, match.start),
        style: normalStyle,
      ));
    }
    // 添加标签文字（带颜色，可点击）
    final tagText = match.group(0)!;
    final tagName = tagText.substring(1); // 去掉 #
    if (onTagTap != null) {
      spans.add(TextSpan(
        text: tagText,
        style: tagStyle,
        recognizer: TapGestureRecognizer()
          ..onTap = () => onTagTap(tagName),
      ));
    } else {
      spans.add(TextSpan(
        text: tagText,
        style: tagStyle,
      ));
    }
    lastEnd = match.end;
  }
  // 添加最后一段普通文字
  if (lastEnd < text.length) {
    spans.add(TextSpan(
      text: text.substring(lastEnd),
      style: normalStyle,
    ));
  }
  return spans;
}

/// 从文本中提取所有 #标签（不含 # 符号）
List<String> extractTags(String text) {
  final regex = RegExp(r'#([^\s#]+)');
  return regex.allMatches(text).map((m) => m.group(1)!).toList();
}
