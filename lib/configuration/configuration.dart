Configuration? _configuration;

Configuration get configuration {
  _configuration ??= Configuration.fromEnvironment();
  return _configuration!;
}

class Configuration {
  const Configuration({
    required this.buildEnvironment,
    required this.apiHost,
    required this.loginUri,
    required this.secure,
    required this.applicationId,
    required this.redirectUri,
  });

  factory Configuration.fromEnvironment() {
    final buildEnv = environmentLookup();
    final env = switch (buildEnv) {
      'local' => BuildEnvironment.local,
      'prod' => BuildEnvironment.prod,
      _ => throw ArgumentError('Unknown build environment: $buildEnv'),
    };

    return Configuration(
      buildEnvironment: env,
      applicationId: switch (env) {
        BuildEnvironment.local => '9973491f-d668-4e30-994c-99354e1b8c40',
        BuildEnvironment.prod => '9973491f-d668-4e30-994c-99354e1b8c40',
      },
      redirectUri: switch (env) {
        BuildEnvironment.local => '',
        BuildEnvironment.prod => '',
      },
      secure: switch (env) {
        BuildEnvironment.local => true,
        BuildEnvironment.prod => true,
      },
      apiHost: switch (env) {
        BuildEnvironment.local => 'api.diskrot.com',
        BuildEnvironment.prod => 'api.diskrot.com',
      },
      loginUri: switch (env) {
        BuildEnvironment.local => 'login.diskrot.com',
        BuildEnvironment.prod => 'login.diskrot.com',
      },
    );
  }

  final BuildEnvironment buildEnvironment;
  final String apiHost;
  final String loginUri;
  final bool secure;
  final String applicationId;
  final String redirectUri;

  static environmentLookup() {
    bool inDebug = false;
    assert(() {
      inDebug = true;
      return true;
    }());

    if (inDebug) {
      return 'local';
    } else {
      return 'prod';
    }
  }
}

enum BuildEnvironment { local, prod }
