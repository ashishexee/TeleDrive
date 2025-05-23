    import 'package:flutter/material.dart';
    import 'package:webview_flutter/webview_flutter.dart';
    import 'dart:convert';
    // Add these imports for platform detection
    import 'dart:io';
    import 'package:webview_flutter_android/webview_flutter_android.dart';
    import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

    class Test extends StatefulWidget {
      const Test({super.key});

      @override
      State<Test> createState() => _TestState();
    }

    class _TestState extends State<Test> {
      late final WebViewController _controller;
      Map<String, dynamic>? _telegramUser;

      @override
      void initState() {
        super.initState();
        // Initialize WebView platform before using it
        _initPlatformState();
        _initWebView();
      }

      void _initPlatformState() {
        // Initialize the appropriate WebView implementation based on platform
        if (WebViewPlatform.instance == null) {
          if (Platform.isAndroid) {
            AndroidWebViewPlatform.registerWith();
          } else if (Platform.isIOS) {
            WebKitWebViewPlatform.registerWith();
          }
        }
      }

      void _initWebView() {
        _controller = WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..addJavaScriptChannel('TelegramLoginChannel',
              onMessageReceived: _handleTelegramAuth)
          ..loadHtmlString(_buildHtmlWithTelegramWidget());
      }

      void _handleTelegramAuth(JavaScriptMessage message) {
        // Parse user data from Telegram
        final userData = jsonDecode(message.message);
        setState(() {
          _telegramUser = userData;
        });
        // Here you can send this data to your backend
        print('Logged in user: ${userData['first_name']} ${userData['last_name']}');
      }

      String _buildHtmlWithTelegramWidget() {
        // Replace "your_bot_name" with your actual Telegram bot name
        return '''
          <!DOCTYPE html>
          <html>
          <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <style>
              body { display: flex; justify-content: center; align-items: center; height: 100vh; margin: 0; }
            </style>
          </head>
          <body>
          <script async src="https://telegram.org/js/telegram-widget.js?22" data-telegram-login="teledrive77_bot" data-size="large" data-onauth="onTelegramAuth(user)" data-request-access="write"></script>
<script type="text/javascript">
  function onTelegramAuth(user) {
    alert('Logged in as ' + user.first_name + ' ' + user.last_name + ' (' + user.id + (user.username ? ', @' + user.username : '') + ')');
  }
</script>
          </body>
          </html>
        ''';
      }

      @override
      Widget build(BuildContext context) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Telegram Login Example'),
          ),
          body: Column(
            children: [
              // WebView for Telegram login
              SizedBox(
                height: 300,
                child: WebViewWidget(controller: _controller),
              ),

              // Display user info after login
              if (_telegramUser != null) ...[
                const SizedBox(height: 20),
                const Text('Logged in as:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          'Name: ${_telegramUser!['first_name']} ${_telegramUser!['last_name']}'),
                      Text('ID: ${_telegramUser!['id']}'),
                      if (_telegramUser!['username'] != null)
                        Text('Username: @${_telegramUser!['username']}'),
                    ],
                  ),
                ),
              ]
            ],
          ),
        );
      }
    }
