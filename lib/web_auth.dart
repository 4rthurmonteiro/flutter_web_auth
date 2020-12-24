library web_auth;

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:webview_flutter/webview_flutter.dart';

final Logger _logger = Logger(printer: SimplePrinter());

class WebAuth extends StatefulWidget {
  const WebAuth(this.initialUrl, this.redirectUri,
      {Key key, this.userAgent, this.progressBarHeight})
      : super(key: key);

  final String initialUrl;
  final String redirectUri;
  final String userAgent;
  final double progressBarHeight;

  static Future<String> open(
      BuildContext context, String authorizationUrl, String redirectUri) {
    return Navigator.of(context).push<String>(MaterialPageRoute<String>(
        builder: (_) => WebAuth(authorizationUrl, redirectUri)));
  }

  @override
  _WebAuthState createState() => _WebAuthState();
}

class _WebAuthState extends State<WebAuth> {
  final Completer<WebViewController> _controller =
      Completer<WebViewController>();

  final CookieManager cookieManager = CookieManager();

  bool showLoading = true;

  @override
  void initState() {
    super.initState();
    if (Platform.isAndroid) {
      WebView.platform = SurfaceAndroidWebView();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await cookieManager.clearCookies();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        textTheme: const TextTheme(headline6: TextStyle(color: Colors.black)),
        brightness: Brightness.light,
        backgroundColor: Colors.white,
        title: Text(widget.initialUrl ?? ''),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        titleSpacing: 0,
        // This drop down menu demonstrates that Flutter widgets can be shown over the web view.
      ),
      // We're using a Builder here so we have a context that is below the Scaffold
      // to allow calling Scaffold.of(context) so we can show a snack bar.
      body: Builder(builder: (BuildContext context) {
        return Stack(
          children: <Widget>[
            Container(alignment: Alignment.center, color: Colors.white),
            WebView(
              initialUrl: widget.initialUrl,
              // Fix google sign in
              userAgent: widget.userAgent ??
                  'Mozilla/5.0 (Linux; Android 7.0; SM-G930V Build/NRD90M) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/59.0.3071.125 Mobile Safari/537.36',
              javascriptMode: JavascriptMode.unrestricted,
              onWebViewCreated: (WebViewController webViewController) {
                _controller.complete(webViewController);
                _logger.d('onWebViewCreated');
                setState(() {
                  showLoading = false;
                });
              },
              navigationDelegate: (NavigationRequest request) {
                if (request.url.startsWith(widget.redirectUri)) {
                  _logger.d('blocking navigation to $request}');
                  Navigator.of(context).pop<String>(request.url);
                  return NavigationDecision.prevent;
                }
                _logger.d('allowing navigation to $request');
                return NavigationDecision.navigate;
              },
              onPageStarted: (String url) {
                _logger.d('Page started loading: $url');

                setState(() {
                  showLoading = true;
                });
              },
              onPageFinished: (String url) {
                _logger.d('Page finished loading: $url');

                setState(() {
                  showLoading = false;
                });
              },
              gestureNavigationEnabled: true,
            ),
            if (showLoading == true)
              LinearProgressIndicator(
                backgroundColor: Colors.lightBlue,
                minHeight: widget.progressBarHeight ?? 2,
              ),
          ],
        );
      }),
    );
  }
}
