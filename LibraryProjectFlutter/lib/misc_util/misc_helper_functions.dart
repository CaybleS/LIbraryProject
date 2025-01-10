// random misc functions
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';

Future<DateTime> getCurrentTimeUTC() async {
  try {
    final response = await http.get(Uri.parse("https://worldtimeapi.org/api/timezone/Etc/UTC"));
    if (response.statusCode == 200) {
      final responseBody = jsonDecode(response.body);
      String time = responseBody['utc_datetime'];
      return DateTime.parse(time);
    }
  } catch (_) {}
  return DateTime.now().toUtc();
}

Future<String> calcLentBooksChecksum(List<dynamic> lentBookData) async {
  String concatenatedData = lentBookData.map((record) {
    return '${record['bookDbKey']}${record['lenderId']}';
  }).join('');

  var bytes = utf8.encode(concatenatedData);
  var digest = sha256.convert(bytes);
  return digest.toString();
}
