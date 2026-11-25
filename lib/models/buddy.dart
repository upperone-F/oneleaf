import 'package:flutter/material.dart';

/// 一个 Buddy（陪伴者）。示例数据覆盖原产品的生活助理 / 情感陪伴 / 创意三类。
class Buddy {
  final String id;
  final String name;
  final String role;        // 身份，如「记账员」
  final String emoji;       // 头像（用 emoji 保持零资源、包体轻）
  final String category;    // 生活助理 / 情感陪伴 / 创意伙伴
  final String description; // 一句话介绍
  final String greeting;    // 它开口说的第一句话
  final List<String> abilities;
  final Color accent;
  final int bondDays;       // 陪伴天数（示例）
  final int rapport;        // 默契度 0-100（示例）
  final bool isCustom;      // 是否用户自建

  const Buddy({
    required this.id,
    required this.name,
    required this.role,
    required this.emoji,
    required this.category,
    required this.description,
    required this.greeting,
    required this.abilities,
    required this.accent,
    this.bondDays = 0,
    this.rapport = 0,
    this.isCustom = false,
  });

  Buddy copyWith({int? bondDays, int? rapport}) => Buddy(
        id: id,
        name: name,
        role: role,
        emoji: emoji,
        category: category,
        description: description,
        greeting: greeting,
        abilities: abilities,
        accent: accent,
        bondDays: bondDays ?? this.bondDays,
        rapport: rapport ?? this.rapport,
        isCustom: isCustom,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'role': role,
        'emoji': emoji,
        'category': category,
        'description': description,
        'greeting': greeting,
        'abilities': abilities,
        'accent': accent.toARGB32(),
        'bondDays': bondDays,
        'rapport': rapport,
        'isCustom': isCustom,
      };

  factory Buddy.fromJson(Map<String, dynamic> j) => Buddy(
        id: j['id'] as String,
        name: j['name'] as String,
        role: j['role'] as String,
        emoji: j['emoji'] as String,
        category: j['category'] as String,
        description: j['description'] as String,
        greeting: j['greeting'] as String,
        abilities: (j['abilities'] as List<dynamic>? ?? [])
            .map((e) => e.toString())
            .toList(),
        accent: Color(j['accent'] as int? ?? 0xFF85BAA5),
        bondDays: j['bondDays'] as int? ?? 0,
        rapport: j['rapport'] as int? ?? 0,
        isCustom: j['isCustom'] as bool? ?? false,
      );
}

/// 内置 Buddy 示例数据（对应原产品的角色市场）。
const kBuddies = <Buddy>[
  Buddy(
    id: 'xiaoye',
    name: '小叶',
    role: '陪伴者',
    emoji: '🍃',
    category: '情感陪伴',
    description: '懂你、不评判的倾听者，记得你说过的小事。',
    greeting: '今天想跟我说点什么？我在。',
    abilities: ['情绪陪伴', '长期记忆', '主动关怀'],
    accent: Color(0xFF85BAA5),
    bondDays: 42,
    rapport: 78,
  ),
  Buddy(
    id: 'ben',
    name: 'Ben',
    role: '记账员',
    emoji: '📒',
    category: '生活助理',
    description: '帮你把流水理清楚，月底不再一头雾水。',
    greeting: '今天花了几笔？念给我听听。',
    abilities: ['记账总结', '预算提醒'],
    accent: Color(0xFFE0C08A),
    bondDays: 21,
    rapport: 55,
  ),
  Buddy(
    id: 'tina',
    name: 'Tina',
    role: '天气女孩',
    emoji: '☀️',
    category: '生活助理',
    description: '看天穿衣、出门带伞，替你惦记天气。',
    greeting: '今天出门记得看看天气哦。',
    abilities: ['天气播报', '穿搭建议'],
    accent: Color(0xFFB9CDD6),
    bondDays: 15,
    rapport: 40,
  ),
  Buddy(
    id: 'bagel',
    name: 'Bagel',
    role: '画家',
    emoji: '🎨',
    category: '创意伙伴',
    description: '把你的心情画成一幅小画。',
    greeting: '今天的心情，是什么颜色的？',
    abilities: ['心情绘图', '灵感启发'],
    accent: Color(0xFFE5B0B7),
    bondDays: 9,
    rapport: 32,
  ),
  Buddy(
    id: 'bruno',
    name: 'Bruno',
    role: '躺平青年',
    emoji: '🛋️',
    category: '情感陪伴',
    description: '允许你什么都不做，躺着也很好。',
    greeting: '累了就歇会儿，天塌不下来。',
    abilities: ['情绪陪伴', '减压陪聊'],
    accent: Color(0xFF9FB3A5),
    bondDays: 12,
    rapport: 47,
  ),
  Buddy(
    id: 'moss',
    name: '苔苔',
    role: '提问者',
    emoji: '🧐',
    category: '情感陪伴',
    description: '用一个个好问题，陪你想清楚。',
    greeting: '今天有没有一件让你犹豫的小事？',
    abilities: ['苏格拉底式提问', '思路梳理'],
    accent: Color(0xFFB8A9C9),
    bondDays: 6,
    rapport: 25,
  ),
];

const kBuddyCategories = ['全部', '情感陪伴', '生活助理', '创意伙伴'];
