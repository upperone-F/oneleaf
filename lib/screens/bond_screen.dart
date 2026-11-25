import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// 陪伴手册：陪伴创新的集中载体——默契、记忆抽屉、主动关怀开关、时间线。
class BondScreen extends StatelessWidget {
  final AppState state;
  const BondScreen({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: state,
      builder: (context, _) {
        final subs = state.subscribedBuddies;
        return PageScaffold(
          title: '陪伴手册',
          children: [
            const DemoTag(),
            const SizedBox(height: 14),
            SoftCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionTitle(title: '和你最默契的 Buddy', subtitle: '互动越多，它越懂你'),
                  const SizedBox(height: 14),
                  if (subs.isEmpty)
                    const EmptyHint(icon: Icons.favorite_border, text: '订阅 Buddy 后，这里会记录你们的默契')
                  else
                    ...subs.map((b) => Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: Row(
                            children: [
                              BuddyAvatar(buddy: b, size: 40),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(b.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.ink)),
                                        Text('${b.rapport}%', style: const TextStyle(fontSize: 12, color: AppTheme.inkSoft)),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: b.rapport / 100,
                                        minHeight: 6,
                                        backgroundColor: AppTheme.line,
                                        color: b.accent,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text('陪伴 ${b.bondDays} 天', style: const TextStyle(fontSize: 11, color: AppTheme.inkSoft)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )),
                ],
              ),
            ),
            const SizedBox(height: 14),
            SoftCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionTitle(title: '记忆抽屉', subtitle: 'Buddy 记住的、关于你的小事'),
                  const SizedBox(height: 12),
                  _memory('想去海边', '你 5 天前说过，想找个海边待两天。', '小叶'),
                  _memory('项目上线', '上周你忙项目上线，熬了好几天。', '小叶'),
                  _memory('不爱喝咖啡', '你提过晚上喝咖啡会睡不着。', 'Ben'),
                ],
              ),
            ),
            const SizedBox(height: 14),
            SoftCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionTitle(title: '主动关怀', subtitle: '让 Buddy 在合适的时候先开口'),
                  const Divider(height: 16, color: AppTheme.line),
                  ToggleRow(
                    icon: Icons.umbrella,
                    title: '天气提醒',
                    subtitle: '下雨时提醒带伞',
                    value: state.setting('proactiveCare'),
                    onChanged: (_) => state.toggleSetting('proactiveCare'),
                  ),
                  ToggleRow(
                    icon: Icons.nightlight_round,
                    title: '深夜关怀',
                    subtitle: '很晚还在写时提醒休息',
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
            SoftCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionTitle(title: '陪伴足迹', subtitle: '最近的和 Buddy 互动'),
                  const SizedBox(height: 12),
                  _timeline(Icons.chat_bubble_outline, '今天', '和小叶聊了项目上线的事'),
                  _timeline(Icons.calculate_outlined, '昨天', 'Ben 帮你总结了三笔开销'),
                  _timeline(Icons.auto_awesome, '3 天前', 'Bagel 为你画了一幅心情画'),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _memory(String tag, String text, String from) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.paper,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.line.withValues(alpha: 0.7)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.blush.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(tag, style: const TextStyle(fontSize: 11, color: AppTheme.ink)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(text, style: const TextStyle(fontSize: 13, color: AppTheme.ink, height: 1.5)),
                const SizedBox(height: 4),
                Text('— $from 记着', style: const TextStyle(fontSize: 11, color: AppTheme.inkSoft)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _timeline(IconData icon, String when, String what) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.mintDark),
          const SizedBox(width: 12),
          SizedBox(width: 44, child: Text(when, style: const TextStyle(fontSize: 12, color: AppTheme.inkSoft))),
          Expanded(child: Text(what, style: const TextStyle(fontSize: 13, color: AppTheme.ink))),
        ],
      ),
    );
  }
}
