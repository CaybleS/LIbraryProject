import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:library_project/database/database.dart';
import 'package:library_project/notifications/notification_model.dart';

// TODO do old tokens get detected when sending notifications? When exactly do tokens get reset? IDk.
// this function will just always overwrite the current user token spot
void writeUserTokenData(String userToken, User user, {required bool shouldSendToThisToken}) {
  // storing the token as the db key to make it easy to flag token as inactive or update it
  DatabaseReference id = dbReference.child('notifications/userTokens/${user.uid}/$userToken/');
  Map<String, dynamic> dataToWrite = {
    'lastModified': DateTime.now().toUtc().toIso8601String(),
    'shouldSendToThisToken': shouldSendToThisToken, // gets set to false upon logout and true upon login
  };
  id.set(dataToWrite);
}

// TODO this shouldnt even be called, right? It should only really be done from whatever service sends the notifications, it should check and see
// old lastModifieds or expired tokens or whatever and then perform this operation
void removeUserToken(String userToken, User user) {
  dbReference.child('notifications/userTokens/${user.uid}/$userToken/').remove();
}

// TODO no idea where this would be used, i guess by a cloud function or something? it works tho
Future<List<String>> getAllUserTokens(User user) async {
  DatabaseEvent allUserTokens = await FirebaseDatabase.instance.ref('notifications/userTokens/${user.uid}/').once();
  List<String> userTokensList = [];
  if (allUserTokens.snapshot.value != null) {
    for (DataSnapshot child in allUserTokens.snapshot.children) {
      dynamic record = child.value;
      DateTime lastModified = DateTime.parse(record['lastModified']);
      bool shouldSendToThisToken = record['shouldSendToThisToken'];
      if (shouldSendToThisToken) {
        userTokensList.add(child.key!);
      }
      print(child.key!);
      print(lastModified);
      print(shouldSendToThisToken);
    }
  }
  return userTokensList;
}

void updateScheduledNotification(ScheduledNotification scheduledNotification, DatabaseReference id) {
  id.update(scheduledNotification.toJson());
}
