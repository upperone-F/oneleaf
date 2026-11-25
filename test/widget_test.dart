import 'package:flutter_test/flutter_test.dart';

import 'package:oneleaf/models/buddy.dart';
import 'package:oneleaf/models/diary.dart';

void main() {
  test('日期键格式正确', () {
    expect(dateKey(DateTime(2026, 11, 22)), '2026-11-22');
  });

  test('四档心情齐全', () {
    expect(kMoods.keys, containsAll(['happy', 'calm', 'tired', 'upset']));
  });

  test('内置 Buddy 示例数据非空', () {
    expect(kBuddies.isNotEmpty, true);
    expect(kBuddies.first.name, '小叶');
  });
}
