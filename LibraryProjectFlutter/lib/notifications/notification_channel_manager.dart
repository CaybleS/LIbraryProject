import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// ignore_for_file: constant_identifier_names
// if you add another channel make sure you ensure you add it throughout this whole file
enum NotificationChannel {
  lend_receiver_early, // scheduled, lending, updated with lend extending, deleted with return
  lend_receiver_time_to_return, // scheduled, lending, updated with lend extending, deleted with return
  lend_receiver_late, // scheduled, scheduled, lending, updated with lend extending, deleted with return
  lend_sender_did_you_get_book_back, //scheduled, lending, updated with lend extending, deleted with return
  book_is_ready_to_return, // insta
  chat_notification, // insta
  incoming_friend_request, // insta
  incoming_book_request, // insta
}

class NotificationChannelManager {

  // creating notification channels for every different notification. This is exactly what allows users to disable
  // specific notifications in their settings. Each notification name (2nd parameter) will be visible like that in settings.
  // note this is only for android. No idea how ios supports these provisional notifications.
  static Future<void> createAllNotificationChannels(FlutterLocalNotificationsPlugin localNotifications) async {
    for (int i = 0; i < NotificationChannel.values.length; i++) {
      String currentChannelName = NotificationChannel.values[i].name;
      AndroidNotificationChannel channel = AndroidNotificationChannel(
        currentChannelName,
        getChannelName(currentChannelName),
        description: getChannelDescription(currentChannelName),
        importance: getChannelImportance(currentChannelName),
      );
      await localNotifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(channel);
    }
  }

  static String getChannelName(String channelName) {
    switch (channelName) {
      case 'lend_receiver_early':
        return 'Lend Receiver Early Notifications';
      case 'lend_receiver_time_to_return':
        return 'Lend Receiver Time to Return Notifications';
      case 'lend_receiver_late':
        return 'Lend Receiver Late Notifications';
      case 'lend_sender_did_you_get_book_back':
        return 'Lender Got Book Back Asking Notifications';
      case 'book_is_ready_to_return':
        return 'A book you lent out is ready to return';
      case 'chat_notification':
        return 'Chat Notification';
      case 'incoming_friend_request':
        return 'Friend Request Notifications';
      case 'incoming_book_request':
        return 'Book Request Notifications';
      default:
        return 'Misc Notifications';
    }
  }

  static String getChannelDescription(String channelName) {
    switch (channelName) {
      case 'lend_receiver_early':
        return 'This notification is sent a week before a book\'s lent "due date", to serve as a reminder.';
      case 'lend_receiver_time_to_return':
        return 'This notification is sent when the lender\'s specified "due date" has come.';
      case 'lend_receiver_late':
        return 'This notification is sent a week after a book\'s lent "due date", to serve as a reminder.';
      case 'lend_sender_did_you_get_book_back':
        return 'This notification is sent when the lender\'s specified "due date" has come.';
      case 'book_is_ready_to_return':
        return 'This notification is sent when a lent out book has been marked as "ready to return"';
      case 'chat_notification':
        return 'Notifications for chat messages.';
      case 'incoming_friend_request':
        return 'This notification is sent when you receive a friend request.';
      case 'incoming_book_request':
        return 'This notification is sent when you receive a book request.';
      default:
        return 'Misc notifications';
    }
  }

  // only high importance channels show up on screen, also when a channel is created it exists in the apps settings and its importance 
  // cannot change unless the user uninstalls. So if you go to your settings you will see all the notification channels
  // TODO ensure these are acceptable, they arent really changable so
  // I tentatively just made them all high importance mainly for demonstration purposes, I guess we can decide as we go.
  static Importance getChannelImportance(String channelName) {
    switch (channelName) {
      case 'lend_receiver_early':
        return Importance.high;
      case 'lend_receiver_time_to_return':
        return Importance.high;
      case 'lend_receiver_late':
        return Importance.high;
      case 'lend_sender_did_you_get_book_back':
        return Importance.high; // was default before
      case 'book_is_ready_to_return':
        return Importance.high; // was default before
      case 'chat_notification':
        return Importance.high; // was low before
      case 'incoming_friend_request':
        return Importance.high; // was default before
      case 'incoming_book_request':
        return Importance.high;
      default:
        return Importance.defaultImportance;
    }
  }
}
