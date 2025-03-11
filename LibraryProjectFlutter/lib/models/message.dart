enum MessageType { text, image, file, event }
// enum MessageStatus { sent, delivered, read }

class MessageModel {
  String id;
  String content;
  String? senderContent;
  String senderId;
  String? replyTo;
  String? userReply;
  bool isEdited;
  String? editedText;
  DateTime sentTime;
  MessageType type;

  // MessageStatus status;

  MessageModel({
    required this.id,
    required this.content,
    this.senderContent,
    required this.senderId,
    required this.sentTime,
    this.replyTo,
    this.userReply,
    this.isEdited = false,
    this.editedText,
    this.type = MessageType.text,
    // this.status = MessageStatus.sent,
  });

  factory MessageModel.fromJson(String messageId, Map<dynamic, dynamic> json) {
    return MessageModel(
      id: messageId,
      content: json['content'],
      senderContent: json['senderContent'],
      senderId: json['sender'],
      sentTime: DateTime.fromMillisecondsSinceEpoch(json['sentTime']),
      replyTo: json['replyTo'],
      userReply: json['userReply'],
      isEdited: json['isEdited'] ?? false,
      editedText: json['editedText'],
      type: MessageType.values.byName(json['type'] ?? 'content'),
      // status: MessageStatus.values.byName(json['status'] ?? 'sent'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'content': content,
      'senderContent': senderContent,
      'sender': senderId,
      'replyTo': replyTo,
      'userReply': userReply,
      'sentTime': sentTime.millisecondsSinceEpoch,
      'isEdited': isEdited,
      'editedText': editedText,
      'type': type.name,
      // 'status': status.name,
    };
  }
}
