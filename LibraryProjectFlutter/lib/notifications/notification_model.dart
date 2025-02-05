
// Does this scheduled notification stuff even need to be stored in memory? It doesnt really need a create function right?
import 'package:firebase_database/firebase_database.dart';
import 'package:library_project/database/database.dart';
import 'package:library_project/notifications/notification_database.dart';

// it should store relevant info for a scheduled notification and my plan is to use firebase scheduler to execute at 8am 1pm and 6pm (it doesnt need to be
// super precise with these since its just lending notifications), polling this part of the database and sending notifications if the date to send is
// within the current time (in utc time of course), with leeway of + maybe 24 hrs after scheduled time or something to where it keeps trying in case of
// some failure, or maybe 12 hour leeway or something, you get the idea hopefully, some logic to retry sending the next time if needed.
// It's only needed for lending notifications, real-time notifications don't need some more complicated scheduling stuff.
// each of these notifications will have a push() database id, which should be added to teh book class as a nullable value, so its detectable when
// a book has a scheduled notificaiton, and this notification can easily be accessed whenever needed (like for lending extending, this would update these entries)
// also obviously when a notification actually gets succesfully sent, this needs to be removed from the database.
// TODO none of this works, this is just a model basically, cant even implement it yet anyways since it requires cloud functions and scheduler
// the plan is to just have 1 firebase scheduler (job) which runs 3 times a day (first 3 scheduling jobs are free) which calls cloud functions to read this, so
// it should be free, however it still requires blaze plan so.
class ScheduledNotification {
  String title;
  String data;
  String uidToSendTo;
  DateTime dateToSend;
  late DatabaseReference _id;

  ScheduledNotification(this.title, this.data, this.uidToSendTo, this.dateToSend); // does this even need to be instantiated? Yes right to write it to db but thats it right?

  void setId(DatabaseReference id) {
    _id = id;
  }

  void update() {
    updateScheduledNotification(this, _id);
  }

  void remove() {
    removeRef(_id);
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'data': data,
      'uidToSendTo': uidToSendTo,
      'dateToSend': dateToSend.toIso8601String(),
    };
  }
}
