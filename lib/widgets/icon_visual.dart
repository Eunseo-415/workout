import 'dart:convert';

import 'package:flutter/material.dart';

/// 이모지 또는 base64 이미지를 동일한 자리에 렌더링하는 아이콘 표시 위젯.
class IconVisual extends StatelessWidget {
  final String? emoji;
  final String? imageBase64;
  final double size;

  const IconVisual({
    super.key,
    this.emoji,
    this.imageBase64,
    this.size = 20,
  });

  @override
  Widget build(BuildContext context) {
    if (imageBase64 != null && imageBase64!.isNotEmpty) {
      try {
        return ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Image.memory(
            base64Decode(imageBase64!),
            width: size,
            height: size,
            fit: BoxFit.cover,
          ),
        );
      } catch (_) {
        return SizedBox(width: size, height: size);
      }
    }
    // Note: color emoji glyphs render as tofu boxes when drawn through a
    // scale transform (e.g. FittedBox) on some Skia/Impeller builds, so the
    // size is fixed via fontSize + a clipped SizedBox instead of scaling.
    return ClipRect(
      child: SizedBox(
        width: size,
        height: size,
        child: Center(
          child: Text(
            emoji ?? '',
            style: TextStyle(fontSize: size * 0.85),
          ),
        ),
      ),
    );
  }
}
