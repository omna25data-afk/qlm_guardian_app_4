// Material import removed (unused)
import 'package:guardian_app/core/config/app_config.dart';
import 'package:guardian_app/main_common.dart';

void main() {
  final devConfig = AppConfig(
    appName: 'إدارة قلم التوثيق (تجريبي)',
    // 10.0.2.2 is special alias to your host loopback interface (i.e., 127.0.0.1 on your development machine)
    apiBaseUrl: 'http://10.0.2.2:8000/api', 
    environment: AppEnvironment.dev,
  );

  mainCommon(devConfig);
}
