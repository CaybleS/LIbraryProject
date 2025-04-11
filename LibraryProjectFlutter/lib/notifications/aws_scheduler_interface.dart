import 'package:aws_common/aws_common.dart';
import 'package:aws_signature_v4/aws_signature_v4.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// if response is null then an error occured in the try catch and thus we couldnt complete the execution flow to get to the http response (should be rare case)
Future<http.Response?> sendAwsRequest(String region, String service, Uri endpoint, AWSHttpMethod httpMethod, Map<String, String> headers, Map<dynamic, dynamic>? payload) async {
  try {
    List<int>? payloadAsBytes = payload != null ? utf8.encode(json.encode(payload)) : null;
    AWSSigV4Signer signer = _getAwsSigner();

    AWSSignedRequest signedRequest = await signer.sign(
      AWSHttpRequest(
        method: httpMethod,
        uri: endpoint,
        headers: headers,
        body: payloadAsBytes,
      ),
      credentialScope: AWSCredentialScope(
        region: region,
        service: AWSService(service),
      ),
    );

    late http.Response response;
    switch (httpMethod) {
      case AWSHttpMethod.get:
        // get has a different request format than the others it doesnt have a body so
        response = await http.get(
          endpoint,
          headers: signedRequest.headers,
        );
        break;
      case AWSHttpMethod.post:
        response = await http.post(
          endpoint,
          headers: signedRequest.headers,
          body: await streamToList(signedRequest.body),
        );
        break;
      case AWSHttpMethod.put:
        response = await http.put(
          endpoint,
          headers: signedRequest.headers,
          body: await streamToList(signedRequest.body),
        );
        break;
      case AWSHttpMethod.delete:
        response = await http.delete(
          endpoint,
          headers: signedRequest.headers,
          body: await streamToList(signedRequest.body),
        );
        break;
      default:
        throw "You have used an invalid AWSHttpMethod. Please only use the ones specified in the sendAwsRequest function";
    }
    return response;
  } catch (e) {
    print("Failure with sending AWS request: $e");
    return null;
  }
}

// for some reason the signedRequest body getter returns a stream list rather than the list itself, who knows, I just convert it back to List<int> here
Future<List<int>> streamToList(Stream<List<int>> stream) async {
  List<int> result = [];
  await for (List<int> chunk in stream) {
    result.addAll(chunk);
  }
  return result;
}

// For all of these it seems we need to "sign" the http request with some secure signer thing to authenticate
// the request so thats why the signer stuff is happening
AWSSigV4Signer _getAwsSigner() {
  String awsAccessKey = dotenv.env['AWS_ACCESS_KEY'] ?? "";
  String awsSecretAccessKey = dotenv.env['AWS_SECRET_ACCESS_KEY'] ?? "";
  AWSSigV4Signer signer = AWSSigV4Signer(
    credentialsProvider: AWSCredentialsProvider(AWSCredentials(awsAccessKey, awsSecretAccessKey)),
  );
  return signer;
}

// truncating date to send to the supported format (no milliseconds or Z)
String truncateDateToSendToProperFormat(String dateToSendString) {
  // at expression - at(yyyy-mm-ddThh:mm:ss)
  return dateToSendString.substring(0, dateToSendString.indexOf(RegExp(r'[.]')));
}

Future<String?> createScheduledJobWithLambdaTarget(Map<String, String> notificationJson, String lambdaArn, DateTime dateToSend) async {
  String awsAccountId = dotenv.env['AWS_ACCOUNT_ID'] ?? "";
  const String region = "us-east-2";
  const String service = "scheduler";
  String clientToken = const Uuid().v4(); // to uniquely identify the request so if I send it twice aws will know, they call it "idempotent"
  String randomScheduleName = "schedule-${const Uuid().v4()}";
  String dateToSendString = dateToSend.toUtc().toIso8601String();
  dateToSendString = truncateDateToSendToProperFormat(dateToSendString);
  Map<dynamic, dynamic> payloadToSendToLambda = {
    "body": notificationJson, "scheduleName": randomScheduleName,
  };

  Map<dynamic, dynamic> schedulePayload = {
    "Name": randomScheduleName,
    "ScheduleExpression": "at($dateToSendString)",
    "FlexibleTimeWindow": {"Mode": "OFF"},
    "State": "ENABLED",
    "ActionAfterCompletion": "DELETE",
    "ClientToken": clientToken,
    "Target": {
      "Arn": lambdaArn,
      "RoleArn": "arn:aws:iam::$awsAccountId:role/service-role/Amazon_EventBridge_Scheduler_LAMBDA_d338db1cc0",
      "RetryPolicy": {"MaximumRetryAttempts": 5}, // 5 retries, its arbitrary, no earthly idea what is optimal
      "Input": json.encode(payloadToSendToLambda)
    },
  };

  Uri endpoint = Uri.parse("https://$service.$region.amazonaws.com/schedules/$randomScheduleName");

  Map<String, String> headers = {
    'Content-Type': 'application/json',
    'X-Amz-Target': 'AWSScheduler.CreateSchedule',
  };

  http.Response? response = await sendAwsRequest(region, service, endpoint, AWSHttpMethod.post, headers, schedulePayload);
  if (response == null) {
    return null;
  }

  if (response.statusCode == 200) {
    return randomScheduleName;

  } else {
    print("Failed to CREATE: ${response.body}");
    return null;
  }
}

// I think get and updated both will be part of the lend extend stuff right? We need to get to update it or no? Who knows !
Future<Map<String, dynamic>?> getScheduledJob(String scheduleName) async {
  const String region = "us-east-2";
  const String service = "scheduler";
  Uri endpoint = Uri.parse("https://$service.$region.amazonaws.com/schedules/$scheduleName");
  Map<String, String> headers = {
    'Content-Type': 'application/json',
    'X-Amz-Target': 'AWSScheduler.GetSchedule',
  };

  http.Response? response = await sendAwsRequest(region, service, endpoint, AWSHttpMethod.get, headers, null);
  if (response == null) {
    return null;
  }

  if (response.statusCode == 200) {
    print("GET worked");
    return json.decode(response.body);
  } else {
    print("Failed to GET: ${response.body}");
    return null;
  }
}

// https://docs.aws.amazon.com/pdfs/scheduler/latest/APIReference/eventbridge-scheduler-api.pdf.pdf#API_UpdateSchedule
// TODO i dont even kno also make sure bool return value is fine idk honestly maybe when it works ill know the truth
Future<bool?> updateScheduledJob(String scheduleName, Map<String, dynamic> updates) async {
  const String region = "us-east-2";
  const String service = "scheduler";
  Uri endpoint = Uri.parse("https://$service.$region.amazonaws.com/schedules/$scheduleName");
  Map<String, String> headers = {
    'Content-Type': 'application/json',
    'X-Amz-Target': 'AWSScheduler.UpdateSchedule',
  };

  http.Response? response = await sendAwsRequest(region, service, endpoint, AWSHttpMethod.put, headers, null);
  if (response == null) {
    return null;
  }

  if (response.statusCode == 200) {
    print("PUT worked: ${response.body}");
    return true;
  } else {
    print("Failed to PUT: ${response.body}");
    return false;
  }
}

Future<void> deleteScheduledJob(String scheduleName) async {
  const String region = "us-east-2";
  const String service = "scheduler";
  String clientToken = const Uuid().v4();
  Uri endpoint = Uri.parse("https://$service.$region.amazonaws.com/schedules/$scheduleName?clientToken=$clientToken");

  Map<String, String> headers = {
    'Content-Type': 'application/json',
    'X-Amz-Target': 'AWSScheduler.DeleteSchedule',
  };
  await sendAwsRequest(region, service, endpoint, AWSHttpMethod.delete, headers, null);
  // currently not using the response for anything, I really just don't think its needed but maybe I'm wrong
}
