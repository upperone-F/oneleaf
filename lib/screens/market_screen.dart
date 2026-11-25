import 'package:flutter/material.dart';

import '../main.dart' show Routes;
import '../models/buddy.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// Buddy 市场：分类筛选 + 搜索 + 订阅，展示陪伴天数与默契度。
class MarketScreen extends StatefulWidget {
  final AppState state;
  const MarketScreen({super.key, required this.state});

  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen> {
  String _category = '全部';
  final TextEditingController _search = TextEditingController();

  List<Buddy> get _list {
    final q = _search.text.trim().toLowerCase();
    return widget.state.allBuddies.where((b) {
      final catOk = _category == '全部' || b.category == _category;
      final qOk = q.isEmpty ||
          b.name.toLowerCase().contains(q) ||
          b.role.toLowerCase().contains(q) ||
          b.description.toLowerCase().contains(q);
      return catOk && qOk;
    }).toList();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.state,
      builder: (context, _) => Scaffold(
        appBar: AppBar(
          title: const Text('Buddy 市场'),
          actions: [
            IconButton(
              icon: const Icon(Icons.favorite_border),
              tooltip: '陪伴手册',
              onPressed: () => Routes.bond(context, widget.state),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => Routes.createBuddy(context, widget.state),
          backgroundColor: AppTheme.mint,
          child: const Icon(Icons.add, color: Colors.white),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: TextField(
                controller: _search,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: '搜索 Buddy 名字或能力…',
                  hintStyle: const TextStyle(color: AppTheme.inkSoft, fontSize: 13),
                  prefixIcon: const Icon(Icons.search, size: 20, color: AppTheme.inkSoft),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: kBuddyCategories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, idx) {
                  final c = kBuddyCategories[idx];
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
                },
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _list.isEmpty
                  ? const EmptyHint(icon: Icons.search_off, text: '没找到匹配的 Buddy')
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 90),
                      itemCount: _list.length,
                      itemBuilder: (context, idx) => _buildCard(_list[idx]),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(Buddy b) {
    final sub = widget.state.isSubscribed(b.id);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SoftCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                BuddyAvatar(buddy: b, size: 48, active: sub),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Text(b.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.ink)),
                        const SizedBox(width: 6),
                        Text('· ${b.role}', style: const TextStyle(fontSize: 12, color: AppTheme.inkSoft)),
                        if (b.isCustom) ...[
                          const SizedBox(width: 6),
                          const Chip(
                            label: Text('自建', style: TextStyle(fontSize: 10)),
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                          ),
                        ],
                      ]),
                      const SizedBox(height: 3),
                      Text(b.category, style: TextStyle(fontSize: 12, color: b.accent)),
                    ],
                  ),
                ),
                FilledButton.tonal(
                  onPressed: () {
                    widget.state.toggleSubscribe(b.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(sub ? '已取消订阅 ${b.name}' : '已订阅 ${b.name}'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: sub ? AppTheme.line : AppTheme.mint.withValues(alpha: 0.18),
                    foregroundColor: sub ? AppTheme.inkSoft : AppTheme.mintDark,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    minimumSize: Size.zero,
                  ),
                  child: Text(sub ? '已订阅' : '订阅', style: const TextStyle(fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(b.description, style: const TextStyle(fontSize: 13, color: AppTheme.ink, height: 1.5)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              children: b.abilities
                  .map((a) => Chip(
                        label: Text(a, style: const TextStyle(fontSize: 11, color: AppTheme.inkSoft)),
                        backgroundColor: AppTheme.paper,
                        side: BorderSide.none,
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                      ))
                  .toList(),
            ),
            if (sub) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.favorite_outline, size: 14, color: AppTheme.blush),
                  const SizedBox(width: 5),
                  Text('已陪伴 ${b.bondDays} 天', style: const TextStyle(fontSize: 12, color: AppTheme.inkSoft)),
                  const Spacer(),
                  Text('默契 ${b.rapport}%', style: const TextStyle(fontSize: 12, color: AppTheme.inkSoft)),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: b.rapport / 100,
                  minHeight: 5,
                  backgroundColor: AppTheme.line,
                  color: AppTheme.blush,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
