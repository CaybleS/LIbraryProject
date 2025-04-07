import 'package:flutter_dotenv/flutter_dotenv.dart';

class AwsConfig {
  static String accessKey = dotenv.env['AWS_ACCESS_KEY'] ?? '';
  static String secretKey = dotenv.env['AWS_SECRET_KEY'] ?? '';
  static String bucketName = dotenv.env['AWS_BUCKET_NAME'] ?? '';
  static String region = dotenv.env['AWS_REGION'] ?? '';
}
