import 'package:firebase_database/firebase_database.dart';
import 'package:library_project/database/database.dart';

// add any setting you see fit. Made this last minute just to show the model, havent even ran it, and nothing instantiates this yet.
class UserSettings {
  // note that these are represented as non-nullable but imo the interface between this and the database should make them null in the database and assume
  // false if read as such just to prevent wasteful downloads. I know storing null isn't ideal but I think its fine in this scenario.
  bool showLendReceiverEarlyNotifications = false;
  bool showLendReceiverTimeToTurnInNotification = false;
  bool showLendReceiverLateNotifications = false;
  bool showLenderDidYouGetThisBookBackNotification = false;
  bool showChatNotifications = false;
  bool showIncomingFriendRequestNotifications = false;
  // this is needed for delete user functionality right? I guess you could just read the path and delete like that but this is better right?
  late DatabaseReference _id;

  UserSettings();

  void setId(DatabaseReference id) {
    _id = id;
  }

  void update() {
    //updateUserSettings(this, _id); // not implemented yet, might want to do this
  }

  void remove() {
    removeRef(_id);
  }

  Map<String, dynamic> toJson() {
    return {
      'showLendReceiverEarlyNotifications': (showLendReceiverEarlyNotifications == false) ? null : true,
      'showLendReceiverTimeToTurnInNotification': (showLendReceiverTimeToTurnInNotification == false) ? null : true,
      'showLendReceiverLateNotifications': (showLendReceiverLateNotifications == false) ? null : true,
      'showLenderDidYouGetThisBookBackNotification': (showLenderDidYouGetThisBookBackNotification == false) ? null : true,
      'showChatNotifications': (showChatNotifications == false) ? null : true,
      'showIncomingFriendRequestNotifications': (showIncomingFriendRequestNotifications == false) ? null : true,
    };
  }
}

UserSettings createUserSettings(record) {
  UserSettings userSettings = UserSettings();
  userSettings.showLendReceiverEarlyNotifications = (record['showLendReceiverEarlyNotifications'] == null) ? false : true;
  userSettings.showLendReceiverTimeToTurnInNotification = (record['showLendReceiverTimeToTurnInNotification'] == null) ? false : true;
  userSettings.showLendReceiverLateNotifications = (record['showLendReceiverLateNotifications'] == null) ? false : true;
  userSettings.showLenderDidYouGetThisBookBackNotification = (record['showLenderDidYouGetThisBookBackNotification'] == null) ? false : true;
  userSettings.showChatNotifications = (record['showChatNotifications'] == null) ? false : true;
  userSettings.showIncomingFriendRequestNotifications = (record['showIncomingFriendRequestNotifications'] == null) ? false : true;
  return userSettings;
}
