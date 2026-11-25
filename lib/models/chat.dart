/// 对话消息。kind: text / memory（记忆引用卡）/ action（结构化服务卡）
class ChatMessage {
  final String id;
  final bool isMe;
  final String text;
  final String kind;
  final String? buddyId;
  final DateTime time;

  ChatMessage({
    required this.id,
    required this.isMe,
    required this.text,
    this.kind = 'text',
    this.buddyId,
    DateTime? time,
  }) : time = time ?? DateTime.now();
}
