import 'package:flutter/material.dart';

import '../main.dart' show Routes;
import '../services/buddy.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// 我的 / 设置：账号、隐私、陪伴开关 + 二级页面入口。
class SettingsScreen extends StatelessWidget {
  final AppState state;
  const SettingsScreen({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: state,
      builder: (context, _) => Scaffold(
        appBar: AppBar(title: const Text('我的')),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 用户卡片
                SoftCard(
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: AppTheme.mint.withValues(alpha: 0.2),
                        child: const Icon(Icons.person, size: 30, color: AppTheme.mintDark),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('友好的旅人',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.ink)),
                            SizedBox(height: 4),
                            Text('已陪伴自己 42 天', style: TextStyle(fontSize: 12, color: AppTheme.inkSoft)),
                          ],
                        ),
                      ),
                      OutlinedButton(
                        onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('演示版暂不支持登录'), behavior: SnackBarBehavior.floating),
                        ),
                        child: const Text('登录'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                // 功能入口
                SoftCard(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    children: [
                      _navTile(context, Icons.favorite_border, '陪伴手册',
                          () => Routes.bond(context, state)),
                      _navTile(context, Icons.insights_outlined, '情绪洞察',
                          () => Routes.insights(context, state.storage)),
                      _navTile(context, Icons.cloud_outlined, '天气',
                          () => Routes.weather(context, state.storage)),
                      _navTile(context, Icons.mic_none, '语音',
                          () => Routes.voice(context, state.storage, _buddyService)),
                      _navTile(context, Icons.ios_share, '分享预览',
                          () => Routes.share(context, state.storage)),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                // 陪伴开关
                SoftCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionTitle(title: 'Buddy 陪伴', subtitle: '陪伴应该是可选择的'),
                      const Divider(height: 16, color: AppTheme.line),
                      ToggleRow(
                        icon: Icons.notifications_active_outlined,
                        title: '主动关怀',
                        subtitle: '读到情绪时主动开口',
                        value: state.setting('proactiveCare'),
                        onChanged: (_) => state.toggleSetting('proactiveCare'),
                      ),
                      ToggleRow(
                        icon: Icons.history,
                        title: '长期记忆',
                        subtitle: '让它记得你说过的小事',
                        value: state.setting('longMemory'),
                        onChanged: (_) => state.toggleSetting('longMemory'),
                      ),
                      ToggleRow(
                        icon: Icons.sentiment_satisfied_alt,
                        title: '情绪共鸣',
                        subtitle: '你低落时放轻语气',
                        value: state.setting('moodEcho'),
                        onChanged: (_) => state.toggleSetting('moodEcho'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                // 隐私与外观
                SoftCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionTitle(title: '隐私与外观'),
                      const Divider(height: 16, color: AppTheme.line),
                      ToggleRow(
                        icon: Icons.lock_outline,
                        title: '应用锁',
                        subtitle: '打开时需要验证',
                        value: state.setting('appLock'),
                        onChanged: (_) => state.toggleSetting('appLock'),
                      ),
                      ToggleRow(
                        icon: Icons.record_voice_over,
                        title: '语音朗读',
                        value: state.setting('voice'),
                        onChanged: (_) => state.toggleSetting('voice'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                SoftCard(
                  color: AppTheme.mint.withValues(alpha: 0.10),
                  child: Row(
                    children: const [
                      Icon(Icons.privacy_tip_outlined, size: 18, color: AppTheme.mintDark),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text('你的日记只存在本机，不上传、不用于训练。',
                            style: TextStyle(fontSize: 13, color: AppTheme.ink, height: 1.5)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Center(
                  child: Text('Oneleaf · v0.2.0（示例版）',
                      style: const TextStyle(fontSize: 11, color: AppTheme.inkSoft)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 设置页需要 BuddyService 来跳转语音页，这里用一个轻量单例避免改动构造签名
  static final BuddyService _buddyService = BuddyService();

  Widget _navTile(BuildContext context, IconData icon, String label, VoidTapCallback onTap) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, size: 20, color: AppTheme.mintDark),
      title: Text(label, style: const TextStyle(fontSize: 14, color: AppTheme.ink)),
      trailing: const Icon(Icons.chevron_right, size: 18, color: AppTheme.inkSoft),
      onTap: onTap,
    );
  }
}

typedef VoidTapCallback = void Function();
