import 'package:flutter/material.dart';

import '../config.dart';
import '../models/diary.dart';
import '../services/buddy.dart';
import '../services/storage.dart';
import '../theme.dart';

/// MVP 的唯一页面：一页日记 = 日期 + 心情 + 写作 + Buddy 回应 + 翻页看历史。
class JournalScreen extends StatefulWidget {
  final StorageService storage;
  final BuddyService buddy;

  const JournalScreen({super.key, required this.storage, required this.buddy});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  DateTime _day = DateTime.now();
  final TextEditingController _controller = TextEditingController();
  bool _saving = false;
  String? _greeting;

  DiaryEntry get _current => widget.storage.read(dateKey(_day));

  @override
  void initState() {
    super.initState();
    _loadDay();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _loadDay() {
    final entry = _current;
    _controller.text = entry.content;
    _greeting = _buildGreeting(entry);
    setState(() {});
  }

  /// 记忆回流的可视化：如果最近几天写过东西，打开时就轻轻提一句。
  String? _buildGreeting(DiaryEntry today) {
    final recent = widget.storage.recentFilled(dateKey(_day), count: 3);
    if (recent.isEmpty) return null;
    final last = recent.first;
    final snippet = last.content.trim().replaceAll(RegExp(r'\s+'), ' ');
    final short = snippet.length > 22 ? '${snippet.substring(0, 22)}…' : snippet;
    return '上次你写到「$short」，后来还好吗？';
  }

  void _changeDay(int delta) {
    FocusScope.of(context).unfocus();
    _day = _day.add(Duration(days: delta));
    _loadDay();
  }

  Future<void> _save() async {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      _toast('写点什么再让小叶看吧');
      return;
    }
    setState(() => _saving = true);

    final entry = _current.copyWith(content: text);
    await widget.storage.save(entry);

    final recent = widget.storage.recentFilled(dateKey(_day), count: 3);
    final reply = await widget.buddy.respond(today: entry, recent: recent);
    await widget.storage.save(entry.copyWith(buddyReply: reply));

    if (!mounted) return;
    setState(() => _saving = false);
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final entry = _current;
    final isToday = dateKey(_day) == dateKey(DateTime.now());
    final weekday = _weekday(_day.weekday);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Oneleaf'),
        actions: [
          if (AppConfig.isDemoMode)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.gold.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('演示模式',
                      style: TextStyle(fontSize: 12, color: AppTheme.ink)),
                ),
              ),
            ),
        ],
      ),
      body: GestureDetector(
        // 左右滑动翻页
        onHorizontalDragEnd: (d) {
          final v = d.primaryVelocity ?? 0;
          if (v < -300) _changeDay(1);
          if (v > 300) _changeDay(-1);
        },
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildDateHeader(entry, isToday, weekday),
                const SizedBox(height: 18),
                if (_greeting != null) ...[
                  _buildGreetingCard(),
                  const SizedBox(height: 16),
                ],
                _buildMoodRow(entry),
                const SizedBox(height: 14),
                _buildEditor(),
                const SizedBox(height: 16),
                _buildSaveButton(),
                if (entry.buddyReply != null) ...[
                  const SizedBox(height: 22),
                  _buildReply(entry.buddyReply!),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDateHeader(DiaryEntry entry, bool isToday, String weekday) {
    return Row(
      children: [
        IconButton(
          onPressed: () => _changeDay(-1),
          icon: const Icon(Icons.chevron_left),
          tooltip: '前一天',
        ),
        Expanded(
          child: Column(
            children: [
              Text(
                '${_day.month}月${_day.day}日 · $weekday',
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.ink),
              ),
              const SizedBox(height: 2),
              Text(
                isToday ? '今天' : (_day.year == DateTime.now().year ? '' : '${_day.year}年'),
                style: const TextStyle(fontSize: 12, color: AppTheme.inkSoft),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => _changeDay(1),
          icon: const Icon(Icons.chevron_right),
          tooltip: '后一天',
        ),
      ],
    );
  }

  Widget _buildGreetingCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.mist.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(
            radius: 16,
            backgroundColor: AppTheme.mint,
            child: Text('叶', style: TextStyle(color: Colors.white, fontSize: 14)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(_greeting!,
                style: const TextStyle(fontSize: 14, color: AppTheme.ink, height: 1.55)),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodRow(DiaryEntry entry) {
    return Row(
      children: kMoods.entries.map((m) {
        final key = m.key;
        final selected = entry.mood == key;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: GestureDetector(
              onTap: () async {
                await widget.storage.save(entry.copyWith(mood: key));
                setState(() {});
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: selected ? AppTheme.mint : AppTheme.card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: selected ? AppTheme.mint : AppTheme.line,
                  ),
                ),
                child: Column(
                  children: [
                    Text(m.value['emoji']!, style: const TextStyle(fontSize: 20)),
                    const SizedBox(height: 4),
                    Text(
                      m.value['label']!,
                      style: TextStyle(
                        fontSize: 13,
                        color: selected ? Colors.white : AppTheme.inkSoft,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEditor() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextField(
        controller: _controller,
        maxLines: 10,
        minLines: 8,
        style: const TextStyle(fontSize: 16, height: 1.8, color: AppTheme.ink),
        decoration: const InputDecoration(
          hintText: '今天发生了什么？写几句就好…',
          hintStyle: TextStyle(color: AppTheme.inkSoft, fontSize: 15),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return FilledButton(
      onPressed: _saving ? null : _save,
      child: _saving
          ? const SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.white),
            )
          : const Text('写好啦，让小叶看看'),
    );
  }

  Widget _buildReply(String reply) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.blush.withValues(alpha: 0.20),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 14,
                backgroundColor: AppTheme.blush,
                child: Text('叶', style: TextStyle(color: Colors.white, fontSize: 12)),
              ),
              const SizedBox(width: 10),
              const Text('小叶的回应',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.ink)),
            ],
          ),
          const SizedBox(height: 12),
          Text(reply,
              style: const TextStyle(fontSize: 15, height: 1.7, color: AppTheme.ink)),
        ],
      ),
    );
  }

  String _weekday(int w) {
    const names = ['一', '二', '三', '四', '五', '六', '日'];
    return '周${names[w - 1]}';
  }
}
