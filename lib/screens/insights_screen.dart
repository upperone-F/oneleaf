import 'package:flutter/material.dart';

import '../services/storage.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// 洞察页：情绪曲线 + 关键词云 + 统计 + 生成周报（超越原版的洞察能力）。
class InsightsScreen extends StatefulWidget {
  final StorageService storage;
  const InsightsScreen({super.key, required this.storage});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  String? _report;
  bool _generating = false;

  static const _weekdays = ['一', '二', '三', '四', '五', '六', '日'];
  // 示例情绪分值 0-100（高=好），真实版从日记 mood 计算
  static const _moodScores = [62, 71, 45, 80, 55, 88, 70];

  @override
  Widget build(BuildContext context) {
    final entries = widget.storage.allFilled();
    return Scaffold(
      appBar: AppBar(title: const Text('洞察')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const DemoTag(),
              const SizedBox(height: 14),
              Row(
                children: [
                  _statCard('${entries.length}', '篇日记'),
                  const SizedBox(width: 10),
                  _statCard('7', '连续天数'),
                  const SizedBox(width: 10),
                  _statCard('3', '位 Buddy'),
                ],
              ),
              const SizedBox(height: 14),
              SoftCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionTitle(title: '本周情绪曲线', subtitle: '从你的日记心情生成'),
                    const SizedBox(height: 18),
                    _buildMoodCurve(),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              SoftCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionTitle(title: '高频关键词', subtitle: '最近一个月你写得最多的词'),
                    const SizedBox(height: 14),
                    _buildWordCloud(),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              SoftCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionTitle(title: '每周回顾', subtitle: '让 Buddy 帮你总结这一周'),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: _generating ? null : _generate,
                      icon: _generating
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.auto_awesome, size: 18),
                      label: Text(_generating ? '生成中…' : '生成本周回顾'),
                    ),
                    if (_report != null) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppTheme.blush.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(_report!,
                            style: const TextStyle(fontSize: 14, color: AppTheme.ink, height: 1.7)),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statCard(String value, String label) {
    return Expanded(
      child: SoftCard(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppTheme.mintDark)),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.inkSoft)),
          ],
        ),
      ),
    );
  }

  Widget _buildMoodCurve() {
    final height = 120.0;
    return SizedBox(
      height: height + 24,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(7, (i) {
          final h = _moodScores[i] / 100 * height;
          return Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  width: 20,
                  height: h,
                  decoration: BoxDecoration(
                    color: i == 5 ? AppTheme.blush : AppTheme.mint.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 8),
                Text('周${_weekdays[i]}', style: const TextStyle(fontSize: 11, color: AppTheme.inkSoft)),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildWordCloud() {
    final words = <(String, double, Color)>[
      ('工作', 22, AppTheme.mintDark),
      ('上线', 18, AppTheme.blush),
      ('累', 16, AppTheme.inkSoft),
      ('海边', 15, AppTheme.mist),
      ('朋友', 14, AppTheme.gold),
      ('天气', 13, AppTheme.mintDark),
      ('咖啡', 12, AppTheme.inkSoft),
      ('散步', 12, AppTheme.blush),
    ];
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: words.map((w) => Text(w.$1,
          style: TextStyle(fontSize: w.$2, fontWeight: FontWeight.w600, color: w.$3))).toList(),
    );
  }

  void _generate() async {
    setState(() => _generating = true);
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    setState(() {
      _generating = false;
      _report =
          '这周你写了 7 篇日记，比上周更稳定。周二到周四被工作占满，情绪也跟着起落；'
          '但周六那篇里，「海边」「散步」这些词让人感到你终于松了下来。\n\n'
          '你反复提到「上线」——那件悬着的事落地了。接下来，也许可以给自己安排一个真正的休息日。';
    });
  }
}
