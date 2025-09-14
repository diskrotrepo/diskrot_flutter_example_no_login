import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_no_login/auth/auth_repository.dart';
import 'package:flutter_no_login/dependency_context.dart';
import 'package:flutter_no_login/http/http_client.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dependencySetup();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'No Login Example',
      theme: ThemeData(useMaterial3: true),
      home: const PromptPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class PromptPage extends StatefulWidget {
  const PromptPage({super.key});
  @override
  State<PromptPage> createState() => _PromptPageState();
}

class _PromptPageState extends State<PromptPage> {
  String _prompt = '';

  bool get _hasPrompt => _prompt.isNotEmpty;

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

  Future<void> _generatePrompt() async {
    late String? prompt;

    final client = di.get<DiskRotHttpClient>();

    final magicF = client.get(endpoint: '/genre/magic');
    final adjectivesF = client.get(endpoint: '/genre/magic/adjectives');
    final fullF = client.get(endpoint: '/genre/full');
    final prefixesF = client.get(endpoint: '/genre/magic/prefixes');
    final suffixesF = client.get(endpoint: '/genre/magic/suffixes');
    final partialsF = client.get(endpoint: '/genre/magic/partials');

    final responses = await Future.wait([
      magicF,
      adjectivesF,
      fullF,
      prefixesF,
      suffixesF,
      partialsF,
    ], eagerError: true);

    final magicResponse = responses[0];

    Map<String, dynamic> asJson(dynamic r) {
      final body = r.body as String? ?? '';
      if (body.isEmpty) return <String, dynamic>{};
      return Map<String, dynamic>.from(jsonDecode(body) as Map);
    }

    if (magicResponse.statusCode == 200) {
      final data = asJson(magicResponse);
      prompt = data['magic'] as String?;
    }

    if (prompt != null && mounted) {
      setState(() {
        _prompt = prompt ?? '';
      });
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to generate prompt')),
      );
    }
  }

  Future<void> _copyPrompt(String prompt) async {
    await Clipboard.setData(ClipboardData(text: prompt));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Data copied to clipboard')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
          title: const Text(
        'No Login Example',
        style: TextStyle(
            fontSize: 40, fontWeight: FontWeight.bold, color: Colors.black),
      )),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_hasPrompt)
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () => _copyPrompt(_prompt),
                  child: SelectableText(
                    _prompt,
                    textAlign: TextAlign.center,
                    style: textTheme.titleLarge,
                  ),
                ),
              )
            else
              Text('Tap “Generate” to start', style: textTheme.titleLarge),
            const SizedBox(height: 24),
            if (_hasPrompt)
              ElevatedButton.icon(
                onPressed: () => _copyPrompt(_prompt),
                icon: const Icon(Icons.copy),
                label: const Text('Copy',
                    style: TextStyle(
                        fontSize: 20,
                        color: Colors.black,
                        fontWeight: FontWeight.bold)),
              ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _generatePrompt,
              child: const Text('Generate',
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  )),
            ),
          ],
        ),
      ),
    );
  }
}
