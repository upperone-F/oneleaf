import 'package:flutter/material.dart';

import '../main.dart' show Routes;
import '../models/buddy.dart';
import '../models/chat.dart';
import '../services/buddy.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// Buddy 对话页：可切换已订阅 Buddy，发消息得到回应（含结构化卡片 + 记忆引用）。
class ChatScreen extends StatefulWidget {
  final BuddyService buddy;
  final AppState state;

  const ChatScreen({super.key, required this.buddy, required this.state});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  String? _activeId;
  final TextEditingController _input = TextEditingController();
  bool _thinking = false;

  List<Buddy> get _buddies => widget.state.subscribedBuddies;

  String get _active {
    if (_activeId != null && _buddies.any((b) => b.id == _activeId)) return _activeId!;
    return _buddies.isNotEmpty ? _buddies.first.id : '';
  }

  Buddy? get _activeBuddy => widget.state.buddyById(_active);

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _active.isEmpty) return;
    _input.clear();
    widget.state.addMessage(_active, ChatMessage(id: DateTime.now().microsecondsSinceEpoch.toString(), isMe: true, text: text));
    setState(() => _thinking = true);

    final buddy = _activeBuddy!;
    final recent = widget.state.storage.recentFilled(
      _todayKey(),
      count: 3,
    );
    final res = await widget.buddy.chatRespond(
      buddy: buddy,
      input: text,
      recent: recent,
      proactiveCare: widget.state.setting('proactiveCare'),
      longMemory: widget.state.setting('longMemory'),
      moodEcho: widget.state.setting('moodEcho'),
    );
    if (!mounted) return;
    widget.state.addMessage(
      _active,
      ChatMessage(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        isMe: false,
        buddyId: _active,
        text: res.text,
        kind: res.kind ?? 'text',
      ),
    );
    setState(() => _thinking = false);
  }

  String _todayKey() {
    final d = DateTime.now();
    return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.state,
      builder: (context, _) {
        final buddy = _activeBuddy;
        final messages = widget.state.chat(_active);
        return Scaffold(
          appBar: AppBar(
            title: buddy == null ? const Text('Buddy 对话') : Text('和 ${buddy.name} 聊聊'),
            actions: [
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                tooltip: '添加 Buddy',
                onPressed: () => Routes.createBuddy(context, widget.state),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: '清空对话',
                onPressed: () {
                  if (_active.isEmpty) return;
                  widget.state.clearChat(_active);
                  _toast('已清空与 ${buddy?.name} 的对话');
                },
              ),
            ],
          ),
          body: _buddies.isEmpty
              ? Column(
                  children: [
                    const EmptyHint(icon: Icons.people_outline, text: '还没有订阅 Buddy，去 Buddy 页挑一个吧'),
                    TextButton(
                      onPressed: () => Routes.createBuddy(context, widget.state),
                      child: const Text('创建一个 Buddy'),
                    ),
                  ],
                )
              : Column(
                  children: [
                    _buildBuddyStrip(),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                        itemCount: messages.length + (_thinking ? 1 : 0),
                        itemBuilder: (context, idx) {
                          if (_thinking && idx == messages.length) return _buildThinking(buddy!);
                          return _buildBubble(messages[idx], buddy!);
                        },
                      ),
                    ),
                    _buildInput(),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildBuddyStrip() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: SizedBox(
        height: 66,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: _buddies.length,
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (context, idx) {
            final b = _buddies[idx];
            final active = b.id == _active;
            return GestureDetector(
              onTap: () => setState(() => _activeId = b.id),
              child: Column(
                children: [
                  BuddyAvatar(buddy: b, size: 44, active: active),
                  const SizedBox(height: 4),
                  Text(b.name,
                      style: TextStyle(
                          fontSize: 11,
                          color: active ? AppTheme.mintDark : AppTheme.inkSoft,
                          fontWeight: active ? FontWeight.w700 : FontWeight.normal)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBubble(ChatMessage msg, Buddy buddy) {
    if (msg.isMe) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 5),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
          decoration: BoxDecoration(
            color: AppTheme.mint,
            borderRadius: BorderRadius.circular(16).copyWith(bottomRight: const Radius.circular(4)),
          ),
          child: Text(msg.text, style: const TextStyle(fontSize: 14, color: Colors.white, height: 1.5)),
        ),
      );
    }
    return Align(
      alignment: Alignment.centerLeft,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BuddyAvatar(buddy: buddy, size: 34),
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 5),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.card,
                borderRadius: BorderRadius.circular(16).copyWith(bottomLeft: const Radius.circular(4)),
                border: Border.all(color: AppTheme.line.withValues(alpha: 0.6)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(msg.text, style: const TextStyle(fontSize: 14, color: AppTheme.ink, height: 1.6)),
                  if (msg.kind == 'memory') ...[const SizedBox(height: 8), _buildMemoryCard()],
                  if (msg.kind == 'accounting') ...[const SizedBox(height: 8), _buildAccountingCard()],
                  if (msg.kind == 'drawing') ...[const SizedBox(height: 8), _buildDrawingCard()],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemoryCard() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.mist.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.history, size: 16, color: AppTheme.mist),
          const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              onTap: () => _toast('记忆来源：3 天前的一篇日记（示例）'),
              child: const Text('来自 3 天前的日记 · 点击查看',
                  style: TextStyle(fontSize: 12, color: AppTheme.inkSoft, decoration: TextDecoration.underline)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountingCard() {
    final rows = [
      ('餐饮', '¥ 42.0'),
      ('交通', '¥ 12.0'),
      ('咖啡', '¥ 28.0'),
    ];
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.gold.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('今日记账 · 示例',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.ink)),
          const SizedBox(height: 8),
          ...rows.map((r) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(r.$1, style: const TextStyle(fontSize: 13, color: AppTheme.ink)),
                    Text(r.$2, style: const TextStyle(fontSize: 13, color: AppTheme.ink)),
                  ],
                ),
              )),
          const Divider(height: 12, color: AppTheme.line),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('合计', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.ink)),
              Text('¥ 82.0', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.ink)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDrawingCard() {
    return Container(
      height: 96,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(
          colors: [Color(0xFFF3D9DE), Color(0xFFDCE7E0), Color(0xFFD7E3EC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Text('🎨  今日心情 · 渐变画（示例）',
            style: TextStyle(fontSize: 12, color: AppTheme.ink)),
      ),
    );
  }

  Widget _buildThinking(Buddy buddy) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          BuddyAvatar(buddy: buddy, size: 30),
          const SizedBox(width: 10),
          const Text('正在想…', style: TextStyle(fontSize: 13, color: AppTheme.inkSoft)),
        ],
      ),
    );
  }

  Widget _buildInput() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: BoxDecoration(
        color: AppTheme.card,
        border: Border(top: BorderSide(color: AppTheme.line)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _input,
              onSubmitted: (_) => _send(),
              decoration: InputDecoration(
                hintText: '说点什么，比如「记账」「画一张」「上次…」',
                hintStyle: const TextStyle(color: AppTheme.inkSoft, fontSize: 13),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: _thinking ? null : _send,
            style: FilledButton.styleFrom(
                minimumSize: const Size(48, 44), padding: EdgeInsets.zero),
            child: const Icon(Icons.arrow_upward, size: 20),
          ),
        ],
      ),
    );
  }
}
