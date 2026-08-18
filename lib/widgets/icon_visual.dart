import 'dart:convert';

import 'package:flutter/material.dart';

/// 커스텀 이미지 또는 내장 벡터 아이콘을 동일한 자리에 렌더링하는 위젯.
///
/// 이모지 대신 벡터 아이콘(`IconData`)을 쓰는 이유: 컬러 이모지 글리프는
/// 일부 Skia/Impeller 렌더러 조합에서 깨진 사각형(tofu)으로 표시되는
/// 문제가 있어, 플랫폼에 상관없이 항상 동일하게 그려지는 아이콘 폰트를 쓴다.
class IconVisual extends StatelessWidget {
  final int? iconCodePoint;
  final String? iconFontFamily;
  final String? iconFontPackage;
  final String? imageBase64;
  final double size;
  final Color? color;

  const IconVisual({
    super.key,
    this.iconCodePoint,
    this.iconFontFamily,
    this.iconFontPackage,
    this.imageBase64,
    this.size = 20,
    this.color,
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
    if (iconCodePoint == null) {
      return SizedBox(width: size, height: size);
    }
    return SizedBox(
      width: size,
      height: size,
      child: Icon(
        IconData(iconCodePoint!, fontFamily: iconFontFamily, fontPackage: iconFontPackage),
        size: size,
        color: color ?? const Color(0xFF334155),
      ),
    );
  }
}
