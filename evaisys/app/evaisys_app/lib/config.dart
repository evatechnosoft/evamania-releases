// EvaISYS uygulama yapılandırması.
// Backend adresinizi buradan ayarlayın.
//
// Notlar:
//  - Android emülatöründe host makineye erişim için 10.0.2.2 kullanın.
//  - Gerçek cihazda backend'in LAN IP'sini yazın (ör. http://192.168.1.100:3000).
class Config {
  static const String apiBase = String.fromEnvironment(
    'API_BASE',
    defaultValue: 'http://10.0.2.2:3000',
  );

  // Telemetri yenileme aralığı.
  static const Duration pollInterval = Duration(seconds: 2);
}
