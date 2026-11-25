import 'package:flutter/material.dart';

import '../models/diary.dart';
import '../services/buddy.dart';
import '../services/storage.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// 语音页：模拟端侧 ASR（点击说话→转文字）与 Buddy 朗读（TTS 状态演示）。
class VoiceScreen extends StatefulWidget {
  final StorageService storage;
  final BuddyService buddy;
  const VoiceScreen({super.key, required this.storage, required this.buddy});

  @override
  State<VoiceScreen> createState() => _VoiceScreenState();
}

class _VoiceScreenState extends State<VoiceScreen> {
  bool _listening = false;
  bool _punctuation = true; // true=标点模式 false=转录模式
  String _transcript = '';
  bool _speaking = false;

  static const _samples = [
    '今天项目终于上线了，虽然忙了一整天，但心里挺踏实的。',
    '有点累，不太想说话，就想安安静静待一会儿。',
    '今天天气很好，中午出去走了走，看到路边的花开了。',
  ];
  int _sampleIdx = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('语音')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const DemoTag(),
              const SizedBox(height: 14),
              SoftCard(
                color: AppTheme.mint.withValues(alpha: 0.10),
                child: Row(
                  children: const [
                    Icon(Icons.lock_outline, size: 18, color: AppTheme.mintDark),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text('端侧识别 · 不联网、不上传，你的声音只留在设备里。',
                          style: TextStyle(fontSize: 13, color: AppTheme.ink, height: 1.5)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SoftCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionTitle(title: '语音输入', subtitle: '模拟识别，把说的话写进日记'),
                    const SizedBox(height: 16),
                    Center(
                      child: GestureDetector(
                        onTap: _startListening,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            color: _listening ? AppTheme.blush : AppTheme.mint,
                            shape: BoxShape.circle,
                            boxShadow: _listening
                                ? [
                                    BoxShadow(
                                        color: AppTheme.blush.withValues(alpha: 0.5),
                                        blurRadius: 20,
                                        spreadRadius: 8)
                                  ]
                                : [],
                          ),
                          child: Icon(_listening ? Icons.hearing : Icons.mic,
                              size: 42, color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: Text(_listening ? '正在听…再点一下结束' : '点一下开始说话',
                          style: const TextStyle(fontSize: 13, color: AppTheme.inkSoft)),
                    ),
                    const SizedBox(height: 14),
                    if (_transcript.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppTheme.paper,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('识别结果',
                                    style: TextStyle(fontSize: 12, color: AppTheme.inkSoft)),
                                Text(_punctuation ? '标点模式' : '转录模式',
                                    style: const TextStyle(fontSize: 11, color: AppTheme.inkSoft)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(_transcript,
                                style: const TextStyle(fontSize: 14, color: AppTheme.ink, height: 1.6)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                final now = DateTime.now();
                                final key = dateKey(now);
                                final old = widget.storage.read(key);
                                widget.storage.save(old.copyWith(content: _transcript));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('已写入今天的日记'),
                                      behavior: SnackBarBehavior.floating),
                                );
                              },
                              icon: const Icon(Icons.save_alt, size: 16),
                              label: const Text('写入日记'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => setState(() => _transcript = ''),
                              icon: const Icon(Icons.close, size: 16),
                              label: const Text('清除'),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Text('识别模式', style: TextStyle(fontSize: 13, color: AppTheme.ink)),
                        const Spacer(),
                        SegmentedButton<bool>(
                          segments: const [
                            ButtonSegment(value: true, label: Text('标点')),
                            ButtonSegment(value: false, label: Text('转录')),
                          ],
                          selected: {_punctuation},
                          onSelectionChanged: (s) => setState(() => _punctuation = s.first),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              SoftCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionTitle(title: 'Buddy 朗读', subtitle: '让它把日记读给你听'),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppTheme.blush.withValues(alpha: 0.22),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: const Text('🍃', style: TextStyle(fontSize: 22)),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text('小叶为你朗读今天写的日记',
                              style: TextStyle(fontSize: 14, color: AppTheme.ink)),
                        ),
                        IconButton(
                          onPressed: _toggleSpeaking,
                          icon: Icon(_speaking ? Icons.stop_circle : Icons.play_circle_filled,
                              size: 36, color: AppTheme.mintDark),
                        ),
                      ],
                    ),
                    if (_speaking) ...[
                      const SizedBox(height: 8),
                      const LinearProgressIndicator(minHeight: 3, color: AppTheme.mint),
                      const SizedBox(height: 6),
                      const Text('正在朗读…（演示状态，真实版用 flutter_tts 离线朗读）',
                          style: TextStyle(fontSize: 11, color: AppTheme.inkSoft)),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 14),
              SoftCard(
                color: AppTheme.mist.withValues(alpha: 0.14),
                child: Row(
                  children: const [
                    Icon(Icons.record_voice_over, size: 18, color: AppTheme.mist),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text('喊一声「Hi buddy」，就能唤起它回应。',
                          style: TextStyle(fontSize: 13, color: AppTheme.ink)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _startListening() {
    if (_listening) {
      // 结束识别，填入示例结果
      setState(() {
        _listening = false;
        var text = _samples[_sampleIdx % _samples.length];
        if (!_punctuation) text = text.replaceAll(RegExp(r'[,。！？、]'), '');
        _transcript = text;
        _sampleIdx++;
      });
    } else {
      setState(() => _listening = true);
    }
  }

  void _toggleSpeaking() {
    setState(() => _speaking = !_speaking);
    if (_speaking) {
      Future.delayed(const Duration(seconds: 4), () {
        if (mounted) setState(() => _speaking = false);
      });
    }
  }
}
