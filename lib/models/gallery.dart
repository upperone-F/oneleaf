import 'package:flutter/material.dart';

/// 封面图库中的一张「图片」。示例阶段用渐变色 + emoji 表示，零图片资源、包体轻。
/// 后续接真实图库时，只需把 gradient/emoji 换成 imageUrl 即可，上层无感。
class CoverArt {
  final String name;
  final String emoji;
  final List<Color> colors;

  const CoverArt({
    required this.name,
    required this.emoji,
    required this.colors,
  });
}

/// 内置示例图库（每天放一张，用户可自行更换）。
const kGallery = <CoverArt>[
  CoverArt(
      name: '晨雾',
      emoji: '🌫️',
      colors: [Color(0xFFD7E3EC), Color(0xFFB9CDD6)]),
  CoverArt(
      name: '海边的下午',
      emoji: '🌊',
      colors: [Color(0xFFBFD9DC), Color(0xFF8FB8C4)]),
  CoverArt(
      name: '林间光',
      emoji: '🌿',
      colors: [Color(0xFFD6E3D3), Color(0xFFA8C6A5)]),
  CoverArt(
      name: '落日',
      emoji: '🌇',
      colors: [Color(0xFFF3D9CB), Color(0xFFE5B09C)]),
  CoverArt(
      name: '夜色',
      emoji: '🌙',
      colors: [Color(0xFFC9C6D8), Color(0xFF9A97B4)]),
  CoverArt(
      name: '花开',
      emoji: '🌸',
      colors: [Color(0xFFF3DDE1), Color(0xFFE5B0B7)]),
  CoverArt(
      name: '暖阳',
      emoji: '☀️',
      colors: [Color(0xFFF5E6C8), Color(0xFFE0C08A)]),
  CoverArt(
      name: '雨天',
      emoji: '🌧️',
      colors: [Color(0xFFD5DBE0), Color(0xFFAEBAC4)]),
];

/// 按日期稳定地取一张默认封面（同一天永远是同一张）。
int defaultCoverIndex(DateTime day) =>
    (day.year * 372 + day.month * 31 + day.day) % kGallery.length;
