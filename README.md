## diskrot-flutter-example-no-login

This project shows how to integrate with diskrot when you do not require user accounts for your application to function. If you don't require per user storage of data, then this is probably the project you want to use. If you require per user configuration or more advanced functionality then you should use the login project. https://github.com/diskrotrepo/diskrot-flutter-example

The goal of this project is to provide a bare minimum example of how to build an application that can communicate with the diskrot platform. This example assumes you have already registered your application with https://developer.diskrot.com. You are more than welcome
to fork, port, whatever this application.

The project is preconfigured to talk to the real diskrot authentication provider. That way you only need to worry about working on your local application.

## PreReq

- Flutter 3.35.1
- Chrome 

## Running the Project

This command should be run from the packages/sample directory. It will launch the project in debug mode in Chrome on port 8080

```bash
flutter run -d chrome --web-port 8080
```

Press `r` to perform a hot reload while developing your application.

## Bucket Setup

Flutter is configured to follow the URL, so if you're using Google Cloud Storage you'll need to run the following command to ensure the bucket is routing requests to the index.html:

```bash
gsutil web set -m index.html -e index.html gs://<yourSite>
```

## Configuration

After registering your project with the network you will need to update the `lib/configuration/configuration.dart` file. 

**applicationId**
The `applicationId` is not a secert, and can be checked into your repo. Unless you're working with a local version of the platform, the
values of `applicationId` will be the same. The value uniquely identifies your application to diskrot. 

**authentication**

The authentication logic happens in this section. There's no need to change this as it will handle all of the back and forth communication on your behalf.

```dart
   @override
  void initState() {
    super.initState();
    _login();
  }

  Future<void> _login() async {
    try {
      await di.get<AuthRepository>().loginAnonymously();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login failed: $e')),
      );
    }
  }
```

