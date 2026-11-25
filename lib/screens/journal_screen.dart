import 'dart:async';

import 'package:flutter/material.dart';

import '../config.dart';
import '../main.dart' show Routes;
import '../models/buddy.dart';
import '../models/diary.dart';
import '../models/gallery.dart';
import '../services/buddy.dart';
import '../services/storage.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// 沉浸式日记页。
/// 设计原则：
/// - 沉浸：无 AppBar，封面从顶端铺开占 1/3；横线纸连续无卡片；控件降到极轻。
/// - 主动：Buddy 常驻封面角落（呼吸动画），并主动开口——记忆回流 / 停顿陪伴 / 情绪关怀。
/// - 方便：主动的话一键收进日记；@Buddy 兜底；底栏保留二级入口。
class JournalScreen extends StatefulWidget {
  final StorageService storage;
  final BuddyService buddy;
  final AppState state;

  const JournalScreen({
    super.key,
    required this.storage,
    required this.buddy,
    required this.state,
  });

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen>
    with SingleTickerProviderStateMixin {
  DateTime _day = DateTime.now();
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focus = FocusNode();

  Timer? _saveTimer;
  Timer? _pauseTimer;
  Timer? _openTimer;

  bool _asking = false;

  // Buddy 常驻呼吸动画——它在"陪着"的视觉信号。
  late final AnimationController _breathe = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  )..repeat(reverse: true);

  // 主动陪伴状态
  String? _activeText;
  Buddy? _activeBuddy;
  int _proactiveCount = 0;
  bool _dismissed = false;
  bool _emotionCared = false;

  DiaryEntry get _current => widget.storage.read(dateKey(_day));
  int get _coverIndex => _current.coverIndex ?? defaultCoverIndex(_day);
  bool get _isToday => dateKey(_day) == dateKey(DateTime.now());
  bool get _careOn => widget.state.setting('proactiveCare');

  Buddy get _primaryBuddy {
    final subs = widget.state.subscribedBuddies;
    if (subs.isNotEmpty) return subs.first;
    return kBuddies.first;
  }

  @override
  void initState() {
    super.initState();
    _controller.text = _current.content;
    _controller.addListener(_onTextChanged);
    _scheduleOpening();
  }

  @override
  void dispose() {
    _flushSave();
    _saveTimer?.cancel();
    _pauseTimer?.cancel();
    _openTimer?.cancel();
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focus.dispose();
    _breathe.dispose();
    super.dispose();
  }

  // ---------- 输入：自动保存 + 主动陪伴触发 ----------
  void _onTextChanged() {
    _scheduleSave();
    _schedulePause();
    _maybeCareOnEmotion();
  }

  void _scheduleSave() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 600), _flushSave);
  }

  void _flushSave() {
    _saveTimer?.cancel();
    final entry = _current;
    if (entry.content != _controller.text) {
      widget.storage.save(entry.copyWith(content: _controller.text));
    }
  }

  /// 打开页面/翻到今天：若还没写，稍等一下让 Buddy 先开口（记忆回流）。
  void _scheduleOpening() {
    _openTimer?.cancel();
    if (!_isToday || !_careOn || _dismissed) return;
    if (_controller.text.trim().isNotEmpty) return;
    _openTimer = Timer(const Duration(milliseconds: 1300), () {
      if (mounted && !_dismissed && _controller.text.trim().isEmpty) {
        _speak('open');
      }
    });
  }

  /// 打字停顿：轻声陪伴一句（有节制，本篇最多 3 次主动）。
  void _schedulePause() {
    _pauseTimer?.cancel();
    if (!_careOn || _dismissed) return;
    _pauseTimer = Timer(const Duration(milliseconds: 4500), () {
      if (!mounted || _dismissed) return;
      if (_controller.text.trim().length < 4) return;
      _speak('pause');
    });
  }

  /// 写出情绪词：立刻关怀一次。
  void _maybeCareOnEmotion() {
    if (!_careOn || _dismissed || _emotionCared) return;
    final t = _controller.text;
    final hit = ['累', '烦', '难过', '崩溃', '压力', '委屈', '焦虑', '无语']
        .any(t.contains);
    if (hit) {
      _emotionCared = true;
      _pauseTimer?.cancel();
      _speak('emotion');
    }
  }

  Future<void> _speak(String trigger) async {
    if (_proactiveCount >= 3 || _activeText != null) return;
    _proactiveCount++;
    final buddy = _primaryBuddy;
    final recent = widget.storage.recentFilled(dateKey(_day), count: 3);
    final text = await widget.buddy.proactive(
      buddy: buddy,
      trigger: trigger,
      content: _controller.text,
      recent: recent,
    );
    if (!mounted || _dismissed) return;
    setState(() {
      _activeBuddy = buddy;
      _activeText = text;
    });
  }

  /// 把 Buddy 主动说的话写进横线纸：作为正文里的一行文本，默认保留。
  void _keepActive() {
    final text = _activeText;
    final buddy = _activeBuddy;
    if (text == null || buddy == null) return;
    final base = _controller.text.trimRight();
    final line = text.trim().replaceAll('\n', ' ');
    _controller.text = '$base\n@ ${buddy.name}：$line\n';
    _controller.selection =
        TextSelection.collapsed(offset: _controller.text.length);
    _clearActive();
    _flushSave();
    setState(() {});
  }

  /// 轻轻划走：本次不再主动打扰。
  void _dismissActive() {
    _dismissed = true;
    _clearActive();
    setState(() {});
  }

  void _clearActive() {
    _pauseTimer?.cancel();
    _activeText = null;
    _activeBuddy = null;
  }

  // ---------- 翻页 ----------
  void _changeDay(int delta) {
    _flushSave();
    _clearActive();
    _openTimer?.cancel();
    FocusScope.of(context).unfocus();
    setState(() {
      _day = _day.add(Duration(days: delta));
      _controller.text = _current.content;
      _proactiveCount = 0;
      _dismissed = false;
      _emotionCared = false;
    });
    _scheduleOpening();
  }

  // ---------- 封面 ----------
  void _pickCover() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('给今天挑一张封面',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.ink)),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('取消'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 0.8,
                ),
                itemCount: kGallery.length,
                itemBuilder: (context, idx) {
                  final art = kGallery[idx];
                  final selected = idx == _coverIndex;
                  return GestureDetector(
                    onTap: () {
                      widget.storage.save(_current.copyWith(coverIndex: idx));
                      Navigator.pop(ctx);
                      setState(() {});
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: LinearGradient(
                          colors: art.colors,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        border: selected
                            ? Border.all(color: AppTheme.mintDark, width: 2.5)
                            : null,
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Text(art.emoji, style: const TextStyle(fontSize: 30)),
                          if (selected)
                            const Positioned(
                              right: 5,
                              top: 5,
                              child: Icon(Icons.check_circle,
                                  size: 16, color: AppTheme.mintDark),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              const Text('每天一张，也可以随时换成喜欢的样子。',
                  style: TextStyle(fontSize: 12, color: AppTheme.inkSoft)),
            ],
          ),
        ),
      ),
    );
  }

  // ---------- @Buddy ----------
  void _showMentionPicker() {
    final buddies = widget.state.subscribedBuddies;
    if (buddies.isEmpty) {
      _toast('还没有订阅 Buddy，去 Buddy 页挑一个吧');
      return;
    }
    _clearActive();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('@ 谁来陪你说两句',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.ink)),
              const SizedBox(height: 12),
              ...buddies.map((b) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: BuddyAvatar(buddy: b, size: 42),
                    title: Text('${b.name} · ${b.role}',
                        style: const TextStyle(
                            fontSize: 14, color: AppTheme.ink)),
                    subtitle: Text(b.description,
                        style: const TextStyle(
                            fontSize: 12, color: AppTheme.inkSoft)),
                    onTap: () {
                      Navigator.pop(ctx);
                      _askBuddy(b);
                    },
                  )),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _askBuddy(Buddy buddy) async {
    _flushSave();
    final text = _controller.text.trim();
    if (text.isEmpty) {
      _toast('先写几句，再 @ 它来回应');
      return;
    }
    setState(() => _asking = true);
    final recent = widget.storage.recentFilled(dateKey(_day), count: 3);
    final res = await widget.buddy.chatRespond(
      buddy: buddy,
      input: text,
      recent: recent,
      proactiveCare: widget.state.setting('proactiveCare'),
      longMemory: widget.state.setting('longMemory'),
      moodEcho: widget.state.setting('moodEcho'),
    );
    if (!mounted) return;
    // 回复直接落在横线上，作为正文的一行：@ 小叶：……
    final base = _controller.text.trimRight();
    final reply = res.text.trim().replaceAll('\n', ' ');
    _controller.text = '$base\n@ ${buddy.name}：$reply\n';
    _controller.selection =
        TextSelection.collapsed(offset: _controller.text.length);
    _asking = false;
    _flushSave();
    setState(() {});
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final art = kGallery[_coverIndex];

    return Scaffold(
      backgroundColor: AppTheme.paper,
      body: GestureDetector(
        onHorizontalDragEnd: (d) {
          final v = d.primaryVelocity ?? 0;
          if (v < -320) _changeDay(1);
          if (v > 320) _changeDay(-1);
        },
        child: SafeArea(
          bottom: false,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              _buildCover(art),
              Transform.translate(
                offset: const Offset(0, -22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildWritingPaper(),
                    const SizedBox(height: 6),
                    _buildActiveZone(),
                    if (_asking) _buildThinking(),
                    const SizedBox(height: 28),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  // ---------- 封面：占据上部，日期雕在图上，Buddy 常驻角落 ----------
  Widget _buildCover(CoverArt art) {
    final buddy = _primaryBuddy;
    return Stack(
      children: [
        GestureDetector(
          onTap: _pickCover,
          child: ClipPath(
            clipper: _CoverClipper(),
            child: Container(
              height: MediaQuery.of(context).size.height * 0.33,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: art.colors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Text(art.emoji,
                        style: const TextStyle(fontSize: 84)),
                  ),
                  // 顶部：极轻的翻页提示（手势为主）
                  Positioned(
                    top: 10,
                    left: 20,
                    right: 20,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _ghostNav(Icons.chevron_left, () => _changeDay(-1)),
                        if (AppConfig.isDemoMode)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 9, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text('演示模式',
                                style: TextStyle(
                                    fontSize: 10, color: AppTheme.ink)),
                          ),
                        _ghostNav(Icons.chevron_right, () => _changeDay(1)),
                      ],
                    ),
                  ),
                  // 日期：直接雕在封面左下
                  Positioned(
                    left: 26,
                    bottom: 34,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_day.month}月${_day.day}日',
                          style: const TextStyle(
                            fontSize: 38,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF3E4A45),
                            letterSpacing: 0.5,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _isToday ? '今天' : _weekday(_day.weekday),
                          style: TextStyle(
                            fontSize: 14,
                            color: const Color(0xFF3E4A45)
                                .withValues(alpha: 0.72),
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // 换封面：底部极轻的文字
                  Positioned(
                    right: 20,
                    bottom: 22,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.auto_awesome,
                            size: 13,
                            color: AppTheme.ink.withValues(alpha: 0.55)),
                        const SizedBox(width: 4),
                        Text('换封面',
                            style: TextStyle(
                                fontSize: 11,
                                color: AppTheme.ink.withValues(alpha: 0.6))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Buddy 常驻呼吸头像：探在封面右下角，表示"它一直在"
        Positioned(
          right: 22,
          bottom: 6,
          child: _buildCompanion(buddy),
        ),
      ],
    );
  }

  Widget _ghostNav(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.3),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 18, color: AppTheme.ink.withValues(alpha: 0.7)),
      ),
    );
  }

  Widget _buildCompanion(Buddy buddy) {
    final awake = _activeText != null;
    return GestureDetector(
      onTap: _showMentionPicker,
      child: AnimatedBuilder(
        animation: _breathe,
        builder: (context, child) {
          final s = awake ? 1.08 : 0.96 + _breathe.value * 0.07;
          return Transform.scale(
            scale: s,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.55),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: buddy.accent.withValues(alpha: awake ? 0.5 : 0.3),
                    blurRadius: awake ? 18 : 10,
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 25,
                backgroundColor: buddy.accent.withValues(alpha: 0.28),
                child: Text(buddy.emoji, style: const TextStyle(fontSize: 26)),
              ),
            ),
          );
        },
      ),
    );
  }

  // ---------- 横线纸：正文与 Buddy 的回复都是同一段文本 ----------
  // 用户在正文里 @Buddy，回复会以「@ 小叶：……」直接写进正文下一行，
  // 和「今天入职成功了」处在同一个输入框里，像一只笔接着写下去。
  Widget _buildWritingPaper() {
    const lineHeight = 36.0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.paper,
          borderRadius: BorderRadius.circular(16),
        ),
        child: CustomPaint(
          painter: _LinedPaperPainter(
            lineHeight: lineHeight,
            color: AppTheme.mist.withValues(alpha: 0.4),
          ),
          child: TextField(
            controller: _controller,
            focusNode: _focus,
            maxLines: null,
            minLines: 6,
            style: const TextStyle(
                fontSize: 16.5,
                height: lineHeight / 16.5,
                color: AppTheme.ink),
            decoration: const InputDecoration(
              hintText: '写下今天想说的话…',
              hintStyle: TextStyle(color: AppTheme.inkSoft, fontSize: 15),
              filled: false,
              border: InputBorder.none,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 14, vertical: 20),
            ),
          ),
        ),
      ),
    );
  }

  // ---------- Buddy 主动浮现区 ----------
  Widget _buildActiveZone() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 420),
      switchInCurve: Curves.easeOutBack,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: anim,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.25),
            end: Offset.zero,
          ).animate(anim),
          child: child,
        ),
      ),
      child: (_activeText != null && _activeBuddy != null)
          ? _activeCard()
          : const SizedBox(width: double.infinity, key: ValueKey('none')),
    );
  }

  Widget _activeCard() {
    final buddy = _activeBuddy!;
    return Container(
      key: ValueKey(_activeText),
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.fromLTRB(16, 14, 14, 12),
      decoration: BoxDecoration(
        color: buddy.accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: buddy.accent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(buddy.emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Text('${buddy.name} 想跟你说',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: buddy.accent)),
              const Spacer(),
              GestureDetector(
                onTap: _dismissActive,
                child: Icon(Icons.close,
                    size: 16, color: AppTheme.inkSoft.withValues(alpha: 0.8)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(_activeText!,
              style: const TextStyle(
                  fontSize: 14.5, color: AppTheme.ink, height: 1.7)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              GestureDetector(
                onTap: _keepActive,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: buddy.accent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.bookmark_add_outlined,
                          size: 14, color: Colors.white),
                      SizedBox(width: 5),
                      Text('收进日记',
                          style: TextStyle(fontSize: 12, color: Colors.white)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildThinking() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      child: Row(
        children: [
          const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.mint),
          ),
          const SizedBox(width: 10),
          Text('${_primaryBuddy.name} 正在回应…',
              style: const TextStyle(fontSize: 12, color: AppTheme.inkSoft)),
        ],
      ),
    );
  }

  // ---------- 底栏：极轻的二级入口 + @Buddy ----------
  Widget _buildBottomBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.card,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          child: Row(
            children: [
              _miniAction(Icons.mic_none, '语音',
                  () => Routes.voice(context, widget.storage, widget.buddy)),
              _miniAction(Icons.cloud_outlined, '天气',
                  () => Routes.weather(context, widget.storage)),
              _miniAction(Icons.insert_chart_outlined, '洞察',
                  () => Routes.insights(context, widget.storage)),
              _miniAction(Icons.ios_share, '分享',
                  () => Routes.share(context, widget.storage)),
              const Spacer(),
              GestureDetector(
                onTap: _asking ? null : _showMentionPicker,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.mint.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('@',
                          style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.mintDark)),
                      const SizedBox(width: 5),
                      Text('Buddy',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.mintDark)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _miniAction(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 19, color: AppTheme.inkSoft),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(fontSize: 10, color: AppTheme.inkSoft)),
          ],
        ),
      ),
    );
  }

  String _weekday(int w) {
    const names = ['一', '二', '三', '四', '五', '六', '日'];
    return '星期${names[w - 1]}';
  }
}

/// 封面底部裁出柔和的圆角弧，让封面与横线纸自然衔接。
class _CoverClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    const r = 34.0;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height - r)
      ..quadraticBezierTo(size.width, size.height, size.width - r, size.height)
      ..lineTo(r, size.height)
      ..quadraticBezierTo(0, size.height, 0, size.height - r)
      ..close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldDelegate) => false;
}

/// 横线纸背景：在米白底上画浅色横线，替代白底卡片。
class _LinedPaperPainter extends CustomPainter {
  final double lineHeight;
  final Color color;

  const _LinedPaperPainter({required this.lineHeight, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0;
    const topPadding = 20.0;
    final start = topPadding + lineHeight;
    for (double y = start; y < size.height - 6; y += lineHeight) {
      canvas.drawLine(Offset(14, y), Offset(size.width - 14, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
