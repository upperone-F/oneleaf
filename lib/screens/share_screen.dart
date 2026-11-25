import 'package:flutter/material.dart';

import '../models/diary.dart';
import '../services/storage.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// 分享预览页：访客只读视角，展示日记 + Buddy 悄悄话，支持匿名与访问计数（示例）。
class ShareScreen extends StatelessWidget {
  final StorageService storage;
  const ShareScreen({super.key, required this.storage});

  @override
  Widget build(BuildContext context) {
    // 取最近一篇有内容的日记作为分享示例
    final all = storage.allFilled();
    final entry = all.isNotEmpty ? all.first : DiaryEntry(date: '2026-11-21');
    final content = entry.isEmpty ? '今天想一个人待着，写几句就好。窗外的光很好，心里也慢慢亮了一点。' : entry.content;

    return Scaffold(
      appBar: AppBar(
        title: const Text('分享预览'),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            tooltip: '复制示例链接',
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('示例链接已复制（演示）'), behavior: SnackBarBehavior.floating),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const DemoTag(),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.mint.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.visibility_outlined, size: 16, color: AppTheme.mintDark),
                    SizedBox(width: 8),
                    Text('这是访客看到的只读页面', style: TextStyle(fontSize: 12, color: AppTheme.ink)),
                    Spacer(),
                    Text('已被访问 12 次', style: TextStyle(fontSize: 11, color: AppTheme.inkSoft)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // 模拟分享卡片（访客视角）
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.card,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.line),
                  boxShadow: [
                    BoxShadow(color: AppTheme.ink.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4))
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 封面图占位（渐变）
                    Container(
                      height: 120,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        gradient: const LinearGradient(
                          colors: [Color(0xFFDCE7E0), Color(0xFFD7E3EC), Color(0xFFF3D9DE)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: const Center(
                        child: Text('🌿', style: TextStyle(fontSize: 40)),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(entry.date, style: const TextStyle(fontSize: 13, color: AppTheme.inkSoft)),
                    const SizedBox(height: 10),
                    Text(content, style: const TextStyle(fontSize: 16, color: AppTheme.ink, height: 1.9)),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.blush.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('🍃', style: TextStyle(fontSize: 18)),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text('「今天先别急着振作，慢慢来，我在。」\n—— 小叶的悄悄话',
                                style: TextStyle(fontSize: 13, color: AppTheme.ink, height: 1.6)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.eco, size: 14, color: AppTheme.mint),
                        SizedBox(width: 6),
                        Text('写于 Oneleaf', style: TextStyle(fontSize: 12, color: AppTheme.inkSoft)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SoftCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    SectionTitle(title: '分享设置', subtitle: '控制访客能看到什么'),
                    SizedBox(height: 8),
                    _SettingLine(icon: Icons.person_off_outlined, label: '匿名分享', value: '已开启 · 不显示昵称'),
                    _SettingLine(icon: Icons.chat_bubble_outline, label: '包含 Buddy 对话', value: '已开启'),
                    _SettingLine(icon: Icons.link, label: '链接有效期', value: '永不过期'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingLine extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _SettingLine({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.mintDark),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(fontSize: 14, color: AppTheme.ink)),
          const Spacer(),
          Text(value, style: const TextStyle(fontSize: 12, color: AppTheme.inkSoft)),
        ],
      ),
    );
  }
}
