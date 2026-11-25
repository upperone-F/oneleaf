import 'package:flutter/material.dart';

import '../services/storage.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// 天气页：当前天气 + 24h 趋势 + 5 天预报，可切换城市 / 今明。示例数据可交互。
class WeatherScreen extends StatefulWidget {
  final StorageService storage;
  const WeatherScreen({super.key, required this.storage});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  final _cities = ['杭州', '北京', '成都'];
  int _city = 0;
  bool _tomorrow = false;

  static const _cityTemps = [24, 19, 27];
  static const _cityCond = ['多云转晴', '晴', '小雨'];

  @override
  Widget build(BuildContext context) {
    final temp = _cityTemps[_city] + (_tomorrow ? 2 : 0);
    final cond = _cityCond[_city];
    return Scaffold(
      appBar: AppBar(title: const Text('天气')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const DemoTag(),
              const SizedBox(height: 14),
              // 城市切换
              Row(
                children: _cities.asMap().entries.map((e) {
                  final active = e.key == _city;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(e.value, style: TextStyle(fontSize: 12, color: active ? Colors.white : AppTheme.ink)),
                      selected: active,
                      onSelected: (_) => setState(() => _city = e.key),
                      selectedColor: AppTheme.mint,
                      backgroundColor: AppTheme.card,
                      side: BorderSide(color: active ? AppTheme.mint : AppTheme.line),
                      showCheckmark: false,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),
              // 当前天气大卡
              SoftCard(
                color: AppTheme.mist.withValues(alpha: 0.18),
                padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
                child: Column(
                  children: [
                    Text(_cities[_city], style: const TextStyle(fontSize: 15, color: AppTheme.inkSoft)),
                    const SizedBox(height: 6),
                    Text('$temp°', style: const TextStyle(fontSize: 56, fontWeight: FontWeight.w300, color: AppTheme.ink)),
                    const SizedBox(height: 4),
                    Text(cond, style: const TextStyle(fontSize: 15, color: AppTheme.ink)),
                    const SizedBox(height: 4),
                    Text('降水概率 ${10 + _city * 15}%  ·  ${_tomorrow ? '明天' : '今天'}',
                        style: const TextStyle(fontSize: 12, color: AppTheme.inkSoft)),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment(value: false, label: Text('今天')),
                        ButtonSegment(value: true, label: Text('明天')),
                      ],
                      selected: {_tomorrow},
                      onSelectionChanged: (s) => setState(() => _tomorrow = s.first),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SoftCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionTitle(title: '24 小时趋势', subtitle: '示例数据'),
                    const SizedBox(height: 18),
                    _buildTrend(temp),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              SoftCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionTitle(title: '未来 5 天', subtitle: '点按可切换查看'),
                    const SizedBox(height: 12),
                    ...List.generate(5, (i) => _buildForecast(i, temp)),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              SoftCard(
                color: AppTheme.blush.withValues(alpha: 0.14),
                child: Row(
                  children: const [
                    Icon(Icons.cloudy_snowing, color: AppTheme.blush, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text('天气女孩 Tina 说：今天适合出门，早晚温差大带件外套。',
                          style: TextStyle(fontSize: 13, color: AppTheme.ink, height: 1.5)),
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

  Widget _buildTrend(int base) {
    final hours = [0, 4, 8, 12, 16, 20];
    final values = hours.map((h) => base - 4 + ((h * 7) % 9)).toList();
    final min = values.reduce((a, b) => a < b ? a : b) - 1;
    final max = values.reduce((a, b) => a > b ? a : b) + 1;
    return SizedBox(
      height: 110,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(values.length, (i) {
          final h = (values[i] - min) / (max - min);
          final barHeight = 20 + h * 60;
          return Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text('${values[i]}°', style: const TextStyle(fontSize: 11, color: AppTheme.inkSoft)),
                const SizedBox(height: 4),
                Container(
                  width: 14,
                  height: barHeight,
                  decoration: BoxDecoration(
                    color: AppTheme.mint.withValues(alpha: 0.55 + i * 0.06),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(height: 6),
                Text('${hours[i]}时', style: const TextStyle(fontSize: 10, color: AppTheme.inkSoft)),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildForecast(int i, int base) {
    final conds = ['晴', '多云', '小雨', '阴', '晴'];
    final icons = [Icons.wb_sunny, Icons.cloud, Icons.umbrella, Icons.cloud_outlined, Icons.wb_sunny];
    final day = i == 0 ? '今天' : (i == 1 ? '明天' : '周${['一','二','三','四'][i - 2]}');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          SizedBox(width: 40, child: Text(day, style: const TextStyle(fontSize: 13, color: AppTheme.ink))),
          Icon(icons[i], size: 20, color: AppTheme.mist),
          const SizedBox(width: 12),
          Text(conds[i], style: const TextStyle(fontSize: 13, color: AppTheme.inkSoft)),
          const Spacer(),
          Text('${base + i - 1}°', style: const TextStyle(fontSize: 13, color: AppTheme.ink)),
        ],
      ),
    );
  }
}
