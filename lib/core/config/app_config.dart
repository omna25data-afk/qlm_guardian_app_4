enum AppEnvironment { dev, prod }

class AppConfig {
  final String appName;
  final String apiBaseUrl;
  final AppEnvironment environment;

  AppConfig({
    required this.appName,
    required this.apiBaseUrl,
    required this.environment,
  });
  
  bool get isDev => environment == AppEnvironment.dev;
  bool get isProd => environment == AppEnvironment.prod;
}
