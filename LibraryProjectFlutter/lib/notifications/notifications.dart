import 'package:app_badge_plus/app_badge_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:library_project/app_startup/global_variables.dart';
import 'package:library_project/notifications/notification_database.dart';
import 'dart:convert';
import 'dart:async';

// some notifications are "High Importance Channel" and some "Miscellaneous" notifciations because of the way
// notifications are handled by the OS - background notifications will be miscellaneous, so there is a way to fix by formatting the stuff a certain way I think
// https://stackoverflow.com/questions/45937291/how-to-specify-android-notification-channel-for-fcm-push-messages-in-android-8 ensure this no happen k?
// one known error is that powering off device and turning it back on, notifications just arent coming. This is indeed still happening so TODO <--
// its a weird problem, dont know if its even something we can reasonably solve. Kind of feels like some OS limitation. I also had times where I startup
// the phone and get notifications that I went to myself 12 hours ago or something like this. Could be due to the above problem or no internet idk. It's just complicated stuff.


// TODO read https://firebase.google.com/docs/cloud-messaging/flutter/receive

// called setup device notifications since these things which run should be independent of the user. It's basically everything
// except the stuff which deals with tokens; the general receiving functionality doesn't really care who's signed in, it's just receiving
Future<void> setupDeviceNotifications() async {
  await requestNotificationPermission(); // ensure this is first, many things rely on this being true, to work
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  notificationInstance = NotificationService();
  notificationInstance.initialize();
}

Future<void> requestNotificationPermission() async {
  // this requests for permissions
  final NotificationSettings settings = await FirebaseMessaging.instance.requestPermission(
    alert: true,
    announcement: false,
    badge: true,
    carPlay: false,
    criticalAlert: false,
    provisional: true, // this is what allows users to disable specific notifications
    sound: true,
    providesAppNotificationSettings: false, // TODO what is this even?
  );
  print('user granted permission: ${settings.authorizationStatus}');
}

// this just be a global method outside the class, it prevents this app from killing whatever app is running
// from the background when notifications are called (or so I'm told).
// I believe this function is what allows you to receive notifications when the app is in "background" and "terminated" state,
// the only thing which needs to be handled differently is "foreground" messages when the app is open.
// TODO test all 3 k?
// TODO an issue is that this i think is just existing
@pragma('vm:entry-point') // idk why this is needed, google it, its some background stuff
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // TODO I believe when notification part of the message is set, the OS takes it over, but when its not set, and only data field is set, this gets called
  // so in theory it works, but we need some api to send notificaitons in this exact way. That's meant to be cloud functions. So it may work, may not.
  AppBadgePlus.updateBadge(1);
  NotificationService notificationService = NotificationService();
  // when notifications are setup its done and it wont be called again, plus the show notification is independent of notification service instance
  // so its fine to call this object rather than another one I believe TODO confirm
  // also TODO does this get closed when device shuts down, and never reinitialized? Or is void main called when app reopens in this case? Notifs arent happening there at all so idk
  await notificationService.setupNotifications();
  await notificationService.showNotification(message);
}

class NotificationService {
  String? token;
  final _localNotifications = FlutterLocalNotificationsPlugin();
  bool _isFlutterLocalNotificationsInitialized = false; // TODO is this what needs to be set for logouts?
  late StreamSubscription<RemoteMessage> showNotificationListener;
  late StreamSubscription<RemoteMessage> notificationClickedListener;

  // so with this, all the notification logic is setup when the app starts; this is the only stuff which runs upon login or logout.
  // I believe it works correctly with this being the case, if you log out it says should not sent to this token so any logic wont send
  // to the token, and if you uninstall the app I believe it changes the token when you reinstall.
  Future<void> userLoggedIn(User user) async {
    token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      writeUserTokenData(token!, user, shouldSendToThisToken: true);
    }
  }

  void userLoggedOut(User user) {
    if (token != null) {
      writeUserTokenData(token!, user, shouldSendToThisToken: false);
      token = null;
    }
  }

  Future<void> initialize() async {
    await _setupMessageHandlers();
  }

  // creating notification channels for every different notification. This is exactly what allows users to disable
  // specific notifications in their settings. Each notification name (2nd parameter) will be visible like that in settings.
  // note this is only for android. No idea how ios supports these provisional notifications.
  // TODO this doesnt work yet, it needs good control over the http request which sends the notification which i dont know how to do yet.
  Future<void> _createAllNotificationChannels() async {
    const channel1 = AndroidNotificationChannel(
      "lend_receiver_early",
      "Lend Receiver Early Notifications",
      description: "This notification can be sent a week before a book's lent \"due date\", to serve as a reminder.",
      importance: Importance.low,
    );
    const channel2 = AndroidNotificationChannel(
      "lend_receiver_time_to_return",
      "Lend Receiver Early Notifications",
      description: "This notification is sent when the lender's specified \"due date\" has come.",
      importance: Importance.defaultImportance,
    );
    const channel3 = AndroidNotificationChannel(
      "lend_receiver_late",
      "Lend Receiver Late Notifications",
      description: "This notification is sent a week after a book's lent \"due date\", to serve as a reminder.",
      importance: Importance.defaultImportance,
    );
    const channel4 = AndroidNotificationChannel(
      "lend_sender_did_you_get_book_back",
      "Lender Got Book Back Asking Notifications",
      description: "This notification is sent when the lender's specified \"due date\" has come.",
      importance: Importance.low,
    );
    const channel5 = AndroidNotificationChannel(
      "chat_notifications",
      "Chat Notifications",
      description: "Notifications for chat messages.",
      importance: Importance.defaultImportance,
    );
    const channel6 = AndroidNotificationChannel(
      "incoming_friend_request",
      "Friend Request Notifications",
      description: "This notification is sent when you receive a friend request.",
      importance: Importance.low,
    );

    await _localNotifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(channel1);
    await _localNotifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(channel2);
    await _localNotifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(channel3);
    await _localNotifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(channel4);
    await _localNotifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(channel5);
    await _localNotifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(channel6);
  }

  // its only called from the background listener btw, but idk if its tied to other stuff or not.
  Future<void> setupNotifications() async {
    if (_isFlutterLocalNotificationsInitialized) {
      return;
    }

    await _createAllNotificationChannels();
    // TODO icon for android notification, change this when logo
    const initializationSettingsAndroid = AndroidInitializationSettings("@mipmap/ic_launcher");

    // ios setup
    final initializationSettingsDarwin = DarwinInitializationSettings(
      onDidReceiveLocalNotification: (id, title, body, payload) async {
        // handle ios foreground notification idk how but yeah
      },
    );

    final initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    // flutter local notification setup
    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        // handle on tap of notification or whatever TODO put some stuff here idk
      }
    );

    _isFlutterLocalNotificationsInitialized = true;
  }

  // TODO make this somehow get the android notification details from the remoteMessage or something, so routing that message to its appropriate channel as needed.
  Future<void> showNotification(RemoteMessage message) async {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;
    if (notification != null && android != null) {
      await _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        const NotificationDetails(
          // TODO I believe this is the details for a specific notification or something idk, it also prob
          // should be changed to a more relevant channel but idk how to fetch the channel from the http request yet
          android: AndroidNotificationDetails(
            "high_importance_channel",
            "High Importance Channel",
            channelDescription: "This channel is used for important notifications",
            importance: Importance.high,
            priority: Priority.high,
            icon: "@mipmap/ic_launcher", // TODO icon here change it
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: message.data.toString(),
      );
    }
  }

  Future<void> _setupMessageHandlers() async {
    // listener for foreground message (when user is in the app)
    showNotificationListener = FirebaseMessaging.onMessage.listen((message) {
      showNotification(message);
    });

    // listener which listens for the event where user clicks on a notification which opens the app
    notificationClickedListener = FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);

    // opened app (from being closed I think)
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      _handleBackgroundMessage(initialMessage);
    }
  }

  void _handleBackgroundMessage(RemoteMessage message) {
    AppBadgePlus.updateBadge(0); // TODO ensure this goes here
    // TODO much to consider:
    // by default if you click on a notification which comes in the background, it will just open the app, but you can also pass
    // extra data from your firebase and specify which screen should be opened.
    // https://developer.android.com/develop/ui/views/notifications#Actions
    // if (message.data['type'] == 'chat') { // this is just an example
    //   // open chat screen
    // }
  }

  // TODO found from https://www.youtube.com/watch?v=dXbd0GcKERU delete this comment k?
  // this dont work, basically this needs to be done through cloud functions using firebase admin sdk
  // since the access token is weird to get otherwise, its just something which is done by server not client. 
  Future<void> sendNotification(String title, String body) async {
    String accessToken = "";
    dynamic messagePayload = {
      'message': {
        'topic': 'all_devices',
        'data': {
          'title': title,
          'body': body,
          // if you do a type in this data you can use that to navigate to specific screens when clicking on the notif
          // also im excluding notification field here since I think that allows for the prevention of background notifications become "misc"
        },
        'android': {
          'priority': 'high',
          'notification': {'channel_id': 'high_importance_channel'}
        }
      }
    };
    const String url = 'https://fcm.googleapis.com/v1/projects/libraryproject10-2f3aa/messages:send';
    final headers = {
      'Authorization': 'Bearer $accessToken',
      'Content-Type': 'application/json',
    };

    final response = await http.post(
      Uri.parse(url),
      headers: headers,
      body: json.encode(messagePayload),
    );

    if (response.statusCode == 200) {
      print("Notification sent succesfully!");
    }
    else {
      print("Error sending notification: ${response.body} with status code: ${response.statusCode}");
    }
  }
}
