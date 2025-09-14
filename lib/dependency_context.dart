import 'package:flutter_no_login/auth/auth_repository.dart';
import 'package:flutter_no_login/configuration/configuration.dart';
import 'package:flutter_no_login/http/http_client.dart';
import 'package:flutter_no_login/logger/logger.dart';
import 'package:get_it/get_it.dart';

final di = GetIt.I;
final logger = Logger();

Future<void> dependencySetup() async {
  di.registerSingleton<Configuration>(Configuration.fromEnvironment());
  di.registerSingleton<DiskRotHttpClient>(
      DiskRotHttpClient(di<Configuration>()));
  di.registerSingleton<AuthRepository>(AuthRepository());
}
