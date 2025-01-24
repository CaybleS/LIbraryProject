// random misc functions which will likely be called from many places
import 'dart:convert';
import 'package:http/http.dart' as http;

// not sure if this is needed, its debatable. The issue is that in the case where user has slow internet connection and also
// adjusted their date and time on their phone it will behave randomly, sometimes giving accurate times and sometimes giving
// their device-specific time. Maybe its just unnecessary, I guess it depends on the implications of storing inaccurate times for our use cases.
// personally I'm learning towards deleting this rn but I'll wait to do so until more thought is put in. Seems maybe extra.
Future<DateTime> getCurrentTimeUTC() async {
  try {
    final response = await http.get(Uri.parse("https://worldtimeapi.org/api/timezone/Etc/UTC")).timeout(
      const Duration(milliseconds: 150), // arbitarily chosen; dont go below 100 for sure
      onTimeout: () {
        throw "Timeout";
      },
    );
    if (response.statusCode == 200) {
      final responseBody = jsonDecode(response.body);
      String time = responseBody['utc_datetime'];
      return DateTime.parse(time);
    }
  } catch (_) {}
  return DateTime.now().toUtc();
}
