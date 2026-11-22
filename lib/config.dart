/// 运行时配置。
///
/// 所有敏感值通过 `flutter run --dart-define=KEY=VALUE` 注入，绝不写进源码或提交到仓库。
/// 未提供 API Key 时自动进入「演示模式」，用本地规则生成回应，方便无后端、无 Key 时体验完整闭环。
class AppConfig {
  /// OpenAI 兼容接口地址（OpenAI / DeepSeek / 通义 / Moonshot 等都兼容）。
  /// 例：https://api.deepseek.com/v1
  static const String baseUrl = String.fromEnvironment(
    'LLM_BASE_URL',
    defaultValue: 'https://api.openai.com/v1',
  );

  /// API Key。为空则进入演示模式。
  static const String apiKey = String.fromEnvironment('LLM_API_KEY');

  /// 模型名。例：gpt-4o-mini / deepseek-chat
  static const String model = String.fromEnvironment(
    'LLM_MODEL',
    defaultValue: 'gpt-4o-mini',
  );

  /// 是否演示模式（没有 Key）。
  static bool get isDemoMode => apiKey.trim().isEmpty;
}
