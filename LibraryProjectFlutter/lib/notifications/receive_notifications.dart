import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shelfswap/core/global_variables.dart';
import 'package:shelfswap/database/database.dart';
import 'package:shelfswap/database/firebase_options.dart';
import 'dart:async';
import 'package:shelfswap/notifications/notification_channel_manager.dart';

// called setup device notifications since these things which run should be independent of the user. It's basically everything
// except the stuff which deals with tokens; the general receiving functionality doesn't really care who's signed in, it's just receiving
Future<void> setupDeviceNotifications() async {
  // when re-adding notification stuff, its the dead code places where I early return, and then I commented out uses of
  // the notificationInstance object, in persistent_bottombar file and logout function.
  // also friend_book_page sendNotification function
  return;
  await requestNotificationPermission(); // ensure this is first, many things rely on this being true to work
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  notificationInstance = NotificationService();
  notificationInstance.initialize(); // TODO check this
}

Future<void> requestNotificationPermission() async {
  await FirebaseMessaging.instance.requestPermission(
    alert: true,
    announcement: false,
    badge: true,
    carPlay: false,
    criticalAlert: false,
    provisional: true, // this is what allows users to disable specific notifications
    sound: true,
    providesAppNotificationSettings: false,
  );
}

// I believe this function is what allows you to receive notifications when the app is in "background" and "terminated" state,
// the only thing which needs to be handled differently is "foreground" messages when the app is open. It allegedly spawns
// an "isolate" (on android) to handle messages when the app isnt running
@pragma('vm:entry-point') // needed so this background isolate spawner doesnt get removed during tree shaking for release mode
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  NotificationService notificationService = NotificationService();
  await notificationService.setupNotificationsForShowingOutOfTheApp();
  await notificationService.showNotification(message);
}

class NotificationService {
  String? token;
  final _localNotifications = FlutterLocalNotificationsPlugin();
  bool _isFlutterLocalNotificationsInitialized = false;
  late StreamSubscription<RemoteMessage> showNotificationListener;
  late StreamSubscription<RemoteMessage> notificationClickedListener;

  // so with this, all the notification logic is setup when the app starts; this is the only stuff which runs upon login or logout.
  // I believe it works correctly with this being the case, if you log out it says should not sent to this token so any logic wont send
  // to the token, and if you uninstall the app I believe it changes the token when you reinstall.
  Future<void> userLoggedIn(String userId) async {
    token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      writeUserTokenData(token!, userId);
    }
  }

  void userLoggedOut(String userId) {
    if (token != null) {
      removeUserTokenData(token!, userId);
      token = null;
    }
  }

  Future<void> initialize() async {
    await NotificationChannelManager.createAllNotificationChannels(_localNotifications);
    await _setupMessageHandlers();
  }

  // its only called from the background listener btw, but idk if its tied to other stuff or not.
  Future<void> setupNotificationsForShowingOutOfTheApp() async {
    if (_isFlutterLocalNotificationsInitialized) {
      return;
    }

    await NotificationChannelManager.createAllNotificationChannels(_localNotifications);
    // TODO why the crud logo doesnt work
    const initializationSettingsAndroid = AndroidInitializationSettings("@mipmap/app_logo_alt");

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
        // handle on tap of notification or whatever TODO implement this functionality
      }
    );

    _isFlutterLocalNotificationsInitialized = true;
  }

  Future<void> showNotification(RemoteMessage message) async {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;
    String channelId = message.data['channelId'] ?? 'default_channel';
    String channelName = NotificationChannelManager.getChannelName(channelId);
    //print("channelName is: $channelName");
    String channelDescription = NotificationChannelManager.getChannelDescription(channelId);

    // for some reason background notifications are having freaky stuff happen -_- its not registering the channel even though the channel name
    // is clearly fetched correctly and the channel SHOULD be created
    // await _localNotifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(
    //   AndroidNotificationChannel(
    //     channelId,
    //     channelName,
    //     description: channelDescription,
    //     importance: NotificationChannelManager.getChannelImportance(channelId),
    //   )
    // );


    if (notification != null && android != null) {
      await _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channelId,
            channelName,
            channelDescription: channelDescription,
            icon: "@mipmap/app_logo_alt", // TODO icon here it doesnt work i think no I think it does work ... I think this one works and the other doesnt or smth
          ),
          iOS: const DarwinNotificationDetails(
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
    // TODO much to consider:
    // by default if you click on a notification which comes in the background, it will just open the app, but you can also pass
    // extra data from your firebase and specify which screen should be opened.
    // https://developer.android.com/develop/ui/views/notifications#Actions
    // if (message.data['type'] == 'chat') { // this is just an example
    //   // open chat screen
    // }
  }
}
