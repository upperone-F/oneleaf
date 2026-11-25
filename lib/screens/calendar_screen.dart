import 'package:flutter/material.dart';

import '../models/diary.dart';
import '../services/storage.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// 日历：月视图 + 日期状态标记（已写/有 Buddy 陪伴）+ 点击跳转当天日记。
class CalendarScreen extends StatefulWidget {
  final StorageService storage;
  final AppState state;
  const CalendarScreen({super.key, required this.storage, required this.state});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime _month;
  DateTime? _selected;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month, 1);
    _selected = now;
  }

  final List<String> _week = ['一', '二', '三', '四', '五', '六', '日'];

  Set<String> get _written => widget.storage.allFilled().map((e) => e.date).toSet();

  void _changeMonth(int delta) {
    setState(() {
      _month = DateTime(_month.year, _month.month + delta, 1);
      _selected = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('日历'),
        actions: [
          IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => _changeMonth(-1)),
          IconButton(icon: const Icon(Icons.chevron_right), onPressed: () => _changeMonth(1)),
        ],
      ),
      body: AnimatedBuilder(
        animation: widget.state,
        builder: (context, _) {
          final written = _written;
          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
              child: Column(
                children: [
                  const DemoTag(),
                  const SizedBox(height: 16),
                  Text('${_month.year} 年 ${_month.month} 月',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppTheme.ink)),
                  const SizedBox(height: 18),
                  SoftCard(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      children: [
                        Row(
                          children: _week
                              .map((w) => Expanded(
                                    child: Center(
                                      child: Text(w, style: const TextStyle(fontSize: 12, color: AppTheme.inkSoft)),
                                    ),
                                  ))
                              .toList(),
                        ),
                        const SizedBox(height: 8),
                        _buildGrid(written),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildLegend(),
                  const SizedBox(height: 16),
                  if (_selected != null) _buildDayDetail(dateKey(_selected!)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGrid(Set<String> written) {
    final firstWeekday = _month.weekday - 1; // 周一=0
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final cells = <Widget>[];
    for (int i = 0; i < firstWeekday; i++) {
      cells.add(const SizedBox(height: 46));
    }
    final todayKey = dateKey(DateTime.now());
    for (int d = 1; d <= daysInMonth; d++) {
      final day = DateTime(_month.year, _month.month, d);
      final key = dateKey(day);
      final isToday = key == todayKey;
      final isSelected = _selected != null && dateKey(_selected!) == key;
      final hasWritten = written.contains(key);
      cells.add(
        GestureDetector(
          onTap: () => setState(() => _selected = day),
          child: Container(
            height: 46,
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.mint.withValues(alpha: 0.20)
                  : (isToday ? AppTheme.gold.withValues(alpha: 0.18) : Colors.transparent),
              borderRadius: BorderRadius.circular(10),
              border: isSelected ? Border.all(color: AppTheme.mint, width: 1.5) : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('$d',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: isToday ? FontWeight.w700 : FontWeight.normal,
                        color: isToday ? AppTheme.mintDark : AppTheme.ink)),
                const SizedBox(height: 2),
                if (hasWritten)
                  Container(width: 5, height: 5, decoration: const BoxDecoration(color: AppTheme.blush, shape: BoxShape.circle)),
              ],
            ),
          ),
        ),
      );
    }
    return Column(
      children: [
        for (int r = 0; r < (cells.length + 6) / 7; r++)
          Row(
            children: cells.skip(r * 7).take(7).map((c) => Expanded(child: c)).toList(),
          ),
      ],
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppTheme.gold, shape: BoxShape.circle)),
        const SizedBox(width: 5),
        const Text('今天', style: TextStyle(fontSize: 12, color: AppTheme.inkSoft)),
        const SizedBox(width: 18),
        Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppTheme.blush, shape: BoxShape.circle)),
        const SizedBox(width: 5),
        const Text('已写日记', style: TextStyle(fontSize: 12, color: AppTheme.inkSoft)),
      ],
    );
  }

  Widget _buildDayDetail(String key) {
    final entry = widget.storage.read(key);
    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitle(title: key, subtitle: entry.isEmpty ? '这天还没有日记' : '这天的记录'),
          if (!entry.isEmpty) ...[
            const SizedBox(height: 10),
            if (entry.mood != null)
              Chip(
                avatar: Text(kMoods[entry.mood]?['emoji'] ?? ''),
                label: Text(kMoods[entry.mood]?['label'] ?? ''),
                backgroundColor: AppTheme.paper,
                side: BorderSide.none,
              ),
            const SizedBox(height: 8),
            Text(entry.content, style: const TextStyle(fontSize: 14, color: AppTheme.ink, height: 1.6)),
          ] else ...[
            const SizedBox(height: 8),
            const Text('没有记录的日子，也照样翻过去了。',
                style: TextStyle(fontSize: 13, color: AppTheme.inkSoft)),
          ],
        ],
      ),
    );
  }
}
