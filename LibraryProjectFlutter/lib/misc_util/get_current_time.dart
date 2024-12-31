// yeah i just have no idea where to put this function but its gotta be somewhere and its gonna be called from lots of places so
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
