import 'package:shelfswap/notifications/notification_channel_manager.dart';

class NotificationData {
  final String title;
  final String body;
  final NotificationChannel notificationChannel;
  final String uidToSendTo;
  
  NotificationData(this.title, this.body, this.notificationChannel, this.uidToSendTo);
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType || other is! NotificationData) {
      return false;
    }
    if (title == other.title && body == other.body && notificationChannel.name == other.notificationChannel.name && uidToSendTo == other.uidToSendTo) {
      return true;
    }
    return false;
  }

  @override
  int get hashCode {
    return Object.hash(title, body, notificationChannel, uidToSendTo);
  }
  
  Map<String, String> toJson() {
    String notificationChannelName = notificationChannel.name;
    return {
      "title": title,
      "body": body,
      "channelId": notificationChannelName,
      "uid": uidToSendTo,
    };
  }
}