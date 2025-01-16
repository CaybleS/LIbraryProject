// random misc functions which will likely be called from many places
import 'dart:convert';
import 'package:http/http.dart' as http;

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
