import 'package:flutter/material.dart';

import '../models/buddy.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// 三步创建 Buddy：命名 → 人设 → 能力。完成后加入市场并自动订阅。
class CreateBuddyScreen extends StatefulWidget {
  final AppState state;
  const CreateBuddyScreen({super.key, required this.state});

  @override
  State<CreateBuddyScreen> createState() => _CreateBuddyScreenState();
}

class _CreateBuddyScreenState extends State<CreateBuddyScreen> {
  int _step = 0;
  final _name = TextEditingController();
  final _role = TextEditingController();
  final _desc = TextEditingController();
  String _emoji = '🌱';
  String _category = '情感陪伴';
  final Set<String> _abilities = {'情绪陪伴'};

  static const _emojis = ['🌱', '🌙', '📚', '🎵', '🧭', '☕', '🐱', '🌻'];
  static const _allAbilities = ['情绪陪伴', '长期记忆', '主动关怀', '记账总结', '天气播报', '灵感启发', '减压陪聊'];

  @override
  void dispose() {
    _name.dispose();
    _role.dispose();
    _desc.dispose();
    super.dispose();
  }

  void _next() {
    if (_step == 0 && _name.text.trim().isEmpty) {
      _toast('先给你的 Buddy 起个名字');
      return;
    }
    if (_step < 2) {
      setState(() => _step++);
      return;
    }
    // 完成：构造 Buddy 加入状态
    final buddy = Buddy(
      id: 'custom_${DateTime.now().microsecondsSinceEpoch}',
      name: _name.text.trim(),
      role: _role.text.trim().isEmpty ? '陪伴者' : _role.text.trim(),
      emoji: _emoji,
      category: _category,
      description: _desc.text.trim().isEmpty ? '一个懂你的新朋友。' : _desc.text.trim(),
      greeting: '嗨，我是${_name.text.trim()}，以后由我陪你。',
      abilities: _abilities.toList(),
      accent: AppTheme.mint,
      isCustom: true,
    );
    widget.state.addBuddy(buddy);
    Navigator.of(context).pop();
    _toast('${buddy.name} 已加入市场并订阅');
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('创建 Buddy'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => _step == 0 ? Navigator.pop(context) : setState(() => _step--),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildStepper(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                child: _step == 0
                    ? _stepName()
                    : _step == 1
                        ? _stepPersona()
                        : _stepAbility(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: FilledButton(
                onPressed: _next,
                child: Text(_step == 2 ? '完成，加入市场' : '下一步'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepper() {
    final labels = ['命名', '人设', '能力'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
      child: Row(
        children: List.generate(3, (i) {
          final done = i <= _step;
          return Expanded(
            child: Column(
              children: [
                Row(
                  children: [
                    if (i > 0)
                      Expanded(child: Container(height: 2, color: i <= _step ? AppTheme.mint : AppTheme.line)),
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: done ? AppTheme.mint : AppTheme.card,
                        shape: BoxShape.circle,
                        border: Border.all(color: done ? AppTheme.mint : AppTheme.line),
                      ),
                      alignment: Alignment.center,
                      child: Text('${i + 1}',
                          style: TextStyle(fontSize: 12, color: done ? Colors.white : AppTheme.inkSoft)),
                    ),
                    if (i < 2)
                      Expanded(child: Container(height: 2, color: i < _step ? AppTheme.mint : AppTheme.line)),
                  ],
                ),
                const SizedBox(height: 5),
                Text(labels[i],
                    style: TextStyle(fontSize: 11, color: done ? AppTheme.mintDark : AppTheme.inkSoft)),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _stepName() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(title: '给它起个名字', subtitle: '一个你会愿意叫出口的名字'),
        const SizedBox(height: 20),
        const Text('选个头像', style: TextStyle(fontSize: 13, color: AppTheme.ink)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          children: _emojis.map((e) {
            final active = e == _emoji;
            return GestureDetector(
              onTap: () => setState(() => _emoji = e),
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: active ? AppTheme.mint.withValues(alpha: 0.18) : AppTheme.card,
                  shape: BoxShape.circle,
                  border: Border.all(color: active ? AppTheme.mint : AppTheme.line, width: 2),
                ),
                alignment: Alignment.center,
                child: Text(e, style: const TextStyle(fontSize: 24)),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        const Text('名字', style: TextStyle(fontSize: 13, color: AppTheme.ink)),
        const SizedBox(height: 8),
        TextField(
          controller: _name,
          decoration: const InputDecoration(hintText: '比如：小满、阿树、月亮…'),
        ),
      ],
    );
  }

  Widget _stepPersona() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(title: '描述它的性格', subtitle: '一句话设定，决定它怎么跟你说话'),
        const SizedBox(height: 20),
        const Text('身份', style: TextStyle(fontSize: 13, color: AppTheme.ink)),
        const SizedBox(height: 8),
        TextField(
          controller: _role,
          decoration: const InputDecoration(hintText: '比如：一个安静的倾听者'),
        ),
        const SizedBox(height: 18),
        const Text('性格描述', style: TextStyle(fontSize: 13, color: AppTheme.ink)),
        const SizedBox(height: 8),
        TextField(
          controller: _desc,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: '它是什么样的人？会怎么关心你？',
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 18),
        const Text('分类', style: TextStyle(fontSize: 13, color: AppTheme.ink)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: ['情感陪伴', '生活助理', '创意伙伴'].map((c) {
            final active = c == _category;
            return ChoiceChip(
              label: Text(c, style: TextStyle(fontSize: 12, color: active ? Colors.white : AppTheme.ink)),
              selected: active,
              onSelected: (_) => setState(() => _category = c),
              selectedColor: AppTheme.mint,
              backgroundColor: AppTheme.card,
              side: BorderSide(color: active ? AppTheme.mint : AppTheme.line),
              showCheckmark: false,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _stepAbility() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(title: '赋予它能力', subtitle: '选择它擅长的事（可多选）'),
        const SizedBox(height: 16),
        ..._allAbilities.map((a) {
          final on = _abilities.contains(a);
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              onTap: () => setState(() {
                if (on) {
                  _abilities.remove(a);
                } else {
                  _abilities.add(a);
                }
              }),
              child: SoftCard(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    Icon(on ? Icons.check_circle : Icons.radio_button_unchecked,
                        size: 20, color: on ? AppTheme.mint : AppTheme.inkSoft),
                    const SizedBox(width: 12),
                    Text(a, style: const TextStyle(fontSize: 14, color: AppTheme.ink)),
                  ],
                ),
              ),
            ),
          );
        }),
        const SizedBox(height: 12),
        Text('创建后会直接加入 Buddy 市场并自动订阅。',
            style: const TextStyle(fontSize: 12, color: AppTheme.inkSoft)),
      ],
    );
  }
}
