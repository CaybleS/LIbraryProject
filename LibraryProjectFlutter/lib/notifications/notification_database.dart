import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:library_project/database/database.dart';

// TODO do old tokens get detected when sending notifications? When exactly do tokens get reset? IDk.
// this function will just always overwrite the current user token spot
void writeUserTokenData(String userToken, User user, {required bool shouldSendToThisToken}) {
  // storing the token as the db key to make it easy to flag token as inactive or update it
  DatabaseReference id = dbReference.child('notifications/userTokens/${user.uid}/$userToken/');
  Map<String, dynamic> dataToWrite = {
    'lastModified': DateTime.now().toUtc().toIso8601String(),
    'shouldSendToThisToken': shouldSendToThisToken, // gets set to false upon logout and true upon login
  };
  id.update(dataToWrite);
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

// scheduled notification info: TODO remove this when its implemented
// it should store relevant info for a scheduled notification and my plan is to use firebase scheduler to execute at 8am 1pm and 6pm (it doesnt need to be
// super precise with these since its just lending notifications), polling this part of the database and sending notifications if the date to send is
// within the current time (in utc time of course), and after sending we delete the database entry.
// It's only needed for lending notifications, real-time notifications don't need some more complicated scheduling stuff.
// each of these notifications will have a push() database id, which should be added to teh book class as a nullable value, so its detectable when
// a book has a scheduled notificaiton, and this notification can easily be accessed whenever needed (like for lending extending or book return, this would update these entries)
// TODO how should book removal of a lent out book affect this? Should it have another confirm dialog if a lent out book is removed or something? Or change the dialog in this case?
// or maybe users shouldnt even be able to remove lent out books, to where they should unlend it, and then remove. Something to think about.
// TODO none of this works, this is just a model basically, cant even implement it yet anyways since it requires cloud functions and scheduler
// the plan is to just have 1 firebase scheduler (job) which runs 3 times a day (first 3 scheduling jobs are free) which calls cloud functions to read this, so
// it should be free, however it still requires blaze plan so.

// ensure dateToSend is UTC. Also this function needs to be extended since I believe every notifications
// should have some routing data to specify where in the app a user should go if they click on it when the
// app is backgrounded. That parameter should be required, but maybe others should be specified and optional when
// extending this function TODO do this when its determined.
// 1.) ensure the book gets the databaseReference tied to it, also ensure uidToSendTo is valid.
// TODO I believe this implies deleting this when deleting a user. How, idk.
DatabaseReference addScheduledNotification(String title, String data, String uidToSendTo, DateTime dateToSend) {
  DatabaseReference id = dbReference.child('notifications/scheduled/$uidToSendTo/').push();
  Map<String, dynamic> dataToWrite = {
    'title': title,
    'data': data,
    'dateToSend': dateToSend.toIso8601String(),
  };
  id.set(dataToWrite);
  return id;
}

// TODO how to update these? They would be updated when 1.) removing a book 2.) lend extending 3.) book returnning
// or 4.) deleting a user. For deleting a user it would just iterate through all their books and if they are flagged to notify then delete them ig right?
// would booksLentToMe be able to edit the book itself in this case? Like if a user deletes an account, all books lent to them
// will get unlent, so I guess yes those books themselves need to be updated. It all works for all scenarios I think.
// TODO delete these comments, the stuff which calls this function still needs to be implemented also so yeah
void updateScheduledNotification(String title, String data, String uidToSendTo, DateTime dateToSend, String dbKey, {bool removeThisScheduledNotification = false}) {
  DatabaseReference id = dbReference.child('notifications/scheduled/$uidToSendTo/$dbKey/');
  if (removeThisScheduledNotification) {
    removeRef(id);
  }
  else {
    Map<String, dynamic> dataToWrite = {
      'title': title,
      'data': data,
      'dateToSend': dateToSend.toIso8601String(),
    };
    id.update(dataToWrite);
  }
}
