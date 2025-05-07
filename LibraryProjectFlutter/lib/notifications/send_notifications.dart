import 'package:shelfswap/core/global_variables.dart';
import 'package:shelfswap/models/notification.dart';
import 'package:shelfswap/notifications/aws_scheduler_interface.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

Future<void> sendNotification(NotificationData notificationData) async {
  if (repeatNotificationManager.wasNotificationAlreadySent(notificationData)) {
    return;
  }
  else {
    repeatNotificationManager.addSentNotification(notificationData);
  }
  dynamic messagePayload = notificationData.toJson();
  try {
    String endpoint = dotenv.env['AWS_SEND_NOTIFICATION_ENDPOINT'] ?? "";
    await http.post(
      Uri.parse(endpoint),
      body: json.encode(messagePayload),
    ).timeout(
      const Duration(seconds: 25),
      onTimeout: () {
        throw "Timeout";
      },
    );

    // can get this response from the await http.post() if you want to debug it
    // if (response.statusCode == 200) {
    //   print("Notification sent succesfully!");
    // }
    // else {
    //   print("Error sending notification: ${response.body} with status code: ${response.statusCode}");
    // }
  } catch (e) {
    // no clue how I should handle these errors, I think its fine for the sender to get no feedback if somehow something doesnt send their notification
    // print("Error $e");
  }
}

// if scheduleName is null then somehow aws did not successfully setup the scheduled notification job so dont bother
Future<String?> sendScheduledNotification(NotificationData notificationData, DateTime dateToSend, String userId, String bookDbKey) async {
  String awsAccountId = dotenv.env['AWS_ACCOUNT_ID'] ?? "";
  String lambdaArn = "arn:aws:lambda:us-east-2:$awsAccountId:function:sendNotification";
  Map<String, String> notificationJson = notificationData.toJson();
  String? scheduleName = await createScheduledJobWithLambdaTarget(notificationJson, lambdaArn, dateToSend, userId, bookDbKey);
  return scheduleName;
}

// currently this interface function, if needed, will only extend the lending by extending the notifications which occur
// relative to the "return date". No other stuff should need to be changed, its not like book titles or authors can
// possibly change for lent out books so (custom added books shouldnt be able to be edited if lent out)
// this doesnt work and I have no clue why, literally why do you not work so weird, its just lend extending functionality for now tho so whatev
// Future<void> updateScheduledNotification(String scheduleName, DateTime dateToSend) async {
//   Map<String, dynamic>? scheduleStuff = await getScheduledJob(scheduleName);
//   if (scheduleStuff == null) {
//     return;
//   }
//   String dateToSendString = dateToSend.toUtc().toIso8601String();
//   dateToSendString = truncateDateToSendToProperFormat(dateToSendString);
//   scheduleStuff['ScheduleExpression'] = "at($dateToSendString)";
//   bool? success = await updateScheduledJob(scheduleName, scheduleStuff);
//   if (success == true) {
//     print("notification successfully updated");
//   }
// }

// literally the same as deleteScheduledJob but I think this is a better abstraction since its an intuitive name
Future<void> deleteScheduledNotification(String scheduleName) async {
  await deleteScheduledJob(scheduleName);
}
