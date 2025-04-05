import 'package:shelfswap/models/notification.dart';
import 'package:shelfswap/notifications/aws_scheduler_interface.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

Future<void> sendNotification(NotificationData notificationData) async {
  dynamic messagePayload = notificationData.toJson();
  try {
    String endpoint = dotenv.env['AWS_SEND_NOTIFICATION_ENDPOINT'] ?? "";
    final response = await http.post(
      Uri.parse(endpoint),
      body: json.encode(messagePayload),
    ).timeout(
      const Duration(seconds: 25),
      onTimeout: () {
        throw "Timeout";
      },
    );

    if (response.statusCode == 200) {
      print("Notification sent succesfully!");
    }
    else {
      print("Error sending notification: ${response.body} with status code: ${response.statusCode}");
    }
  } catch (e) { // TODO how on earth should the error handling be. No feedback for user for sure so idk I guess just remove these print statements when done.
    print("Error $e");
  }
}

// if scheduleName is null then somehow aws did not successfully setup the scheduled notification job so dont bother
Future<String?> sendScheduledNotification(NotificationData notificationData, DateTime dateToSend) async {
  String awsAccountId = dotenv.env['AWS_ACCOUNT_ID'] ?? "";
  String lambdaArn = "arn:aws:lambda:us-east-2:$awsAccountId:function:sendNotification";
  Map<String, String> notificationJson = notificationData.toJson();
  String? scheduleName = await createScheduledJobWithLambdaTarget(notificationJson, lambdaArn, dateToSend);
  return scheduleName;
}

// currently this interface function only will extend the lending. No other stuff should need to be changed, its not
// like book titles or authors can possibly change for lent out books so (custom added books shouldnt be able to be edited if lent out)
// TODO this doesnt work and I have no clue why, literally why do you not work so weird, its just lend extending functionality for now tho so whatev
Future<void> updateScheduledNotification(String scheduleName, DateTime dateToSend) async {
  Map<String, dynamic>? scheduleStuff = await getScheduledJob(scheduleName);
  if (scheduleStuff == null) {
    return;
  }
  String dateToSendString = dateToSend.toUtc().toIso8601String();
  dateToSendString = truncateDateToSendToProperFormat(dateToSendString);
  scheduleStuff['ScheduleExpression'] = "at($dateToSendString)";
  bool? success = await updateScheduledJob(scheduleName, scheduleStuff);
  if (success == true) {
    print("notification successfully updated");
  }
}

Future<void> deleteScheduledNotification(String scheduleName) async {
  await deleteScheduledJob(scheduleName);
}