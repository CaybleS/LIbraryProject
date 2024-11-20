class Chat {
  final String id;
  final String sender;
  final String receiver;
  final String message;
  final DateTime timestamp;

  Chat({
    required this.id,
    required this.sender,
    required this.receiver,
    required this.message,
    required this.timestamp,
  });
}
