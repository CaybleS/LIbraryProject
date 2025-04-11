import 'dart:convert';
import 'dart:io';
import 'package:aws_common/aws_common.dart';
import 'package:aws_signature_v4/aws_signature_v4.dart';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:shelfswap/notifications/aws_scheduler_interface.dart';

Future<String> uploadImage(BuildContext context, String key, File file) async {
  // To get the download url add "https://shelfswap.s3.amazonaws.com/" to the beginning of the key
  // example: if the key is 9091bba0-1714-11f0-a42f-7790cfcd5bcf
  // your download url is https://shelfswap.s3.amazonaws.com/9091bba0-1714-11f0-a42f-7790cfcd5bcf
  
  try {
    Stream<List<int>> stream = file.openRead();
    int length = await file.length();

    Response response = await Dio().put(_getPresignedURL(key),
        data: stream,
        options: Options(
          headers: {
            'Content-Type': 'application/octet-stream',
            'Content-Length': length,
          },
          sendTimeout: const Duration(minutes: 1),
          receiveTimeout: const Duration(minutes: 1),
        ));

    if (response.statusCode == 200) {
      return "good";
    } else {
      return "Failed: ${response.statusCode}";
    }
  } catch (e) {
    return e.toString();
  }
}

Future<void> deleteImage(String url) async {
  Uri uriWithKey = Uri.parse(url);

  AWSSigV4Signer signer = AWSSigV4Signer(
      credentialsProvider: AWSCredentialsProvider(AWSCredentials(
          dotenv.env['AWS_ACCESS_KEY'] ?? "",
          dotenv.env['AWS_SECRET_ACCESS_KEY'] ?? "")));

  AWSSignedRequest signedRequest = await signer.sign(
      AWSHttpRequest(method: AWSHttpMethod.delete, uri: uriWithKey),
      credentialScope: AWSCredentialScope(
          region: "us-east-2", service: const AWSService("s3")));

  await http.delete(
    uriWithKey,
    headers: signedRequest.headers,
    body: await streamToList(signedRequest.body)
  );
}

// This function lets me skip the AWS Signer that was used for notifications
// When I tried that, I was geting a "message is too long" error
String _getPresignedURL(String key) {
  String url = "shelfswap.s3.amazonaws.com";
  String region = "us-east-2";

  DateTime date = DateTime.now().toUtc();
  String dateStamp = DateFormat('yyyyMMdd').format(date);
  String awsDate = DateFormat("yyyyMMdd'T'HHmmss'Z'").format(date);

  String scope = "$dateStamp/$region/s3/aws4_request";

  String query = 'X-Amz-Algorithm=AWS4-HMAC-SHA256'
      '&X-Amz-Credential=${Uri.encodeComponent('${dotenv.env['AWS_ACCESS_KEY'] ?? ""}/$scope')}'
      '&X-Amz-Date=$awsDate'
      '&X-Amz-Expires=60000'
      '&X-Amz-SignedHeaders=host';

  String request = 'PUT\n'
      '/$key\n'
      '$query\n'
      'host:$url\n'
      '\n'
      'host\n'
      'UNSIGNED-PAYLOAD';

  String stringToSign = 'AWS4-HMAC-SHA256\n'
      '$awsDate\n'
      '$scope\n'
      '${sha256.convert(utf8.encode(request)).toString()}';

  List<int> signingKey = _getSignatureKey(
      dotenv.env['AWS_SECRET_ACCESS_KEY'] ?? "", dateStamp, region, 's3');
  String signature =
      Hmac(sha256, signingKey).convert(utf8.encode(stringToSign)).toString();

  return 'https://$url/$key?$query'
      '&X-Amz-Signature=$signature';
}

List<int> _getSignatureKey(
    String key, String dateStamp, String region, String service) {
  List<int> date = Hmac(sha256, utf8.encode('AWS4$key'))
      .convert(utf8.encode(dateStamp))
      .bytes;
  List<int> encRegion = Hmac(sha256, date).convert(utf8.encode(region)).bytes;
  List<int> encService =
      Hmac(sha256, encRegion).convert(utf8.encode(service)).bytes;
  List<int> sign =
      Hmac(sha256, encService).convert(utf8.encode('aws4_request')).bytes;
  return sign;
}
