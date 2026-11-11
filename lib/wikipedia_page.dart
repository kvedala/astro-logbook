import 'package:flutter/foundation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

/// Open the Messier article in a browser on web or an in-app view on mobile.
Future<void> openMessierWikipedia(BuildContext context, int number) async {
  await _openWikipedia(context, 'M $number', 'Messier_$number');
}

/// Open the NGC article in a browser on web or an in-app view on mobile.
Future<void> openNgcWikipedia(BuildContext context, int number) async {
  await _openWikipedia(context, 'NGC $number', 'NGC_$number');
}

Future<void> _openWikipedia(
  BuildContext context,
  String title,
  String article,
) async {
  final uri = Uri.https('en.wikipedia.org', '/wiki/$article');
  if (kIsWeb) {
    final opened = await launchUrl(uri, webOnlyWindowName: '_blank');
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open Wikipedia.')),
      );
    }
  } else if (context.mounted) {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _WikipediaPage(title: title, uri: uri),
      ),
    );
  }
}

class _WikipediaPage extends StatelessWidget {
  final String title;
  final Uri uri;
  const _WikipediaPage({required this.title, required this.uri});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('$title · Wikipedia')),
      body: InAppWebView(
        initialUrlRequest: URLRequest(url: WebUri(uri.toString())),
        initialSettings: InAppWebViewSettings(transparentBackground: true),
        onLoadStop: (controller, url) async {
          await controller.evaluateJavascript(
            source: '''
            const style = document.createElement('style');
            style.textContent = 'html, body, body *:not(img):not(video):not(svg):not(path) { background-color: #000 !important; color: #c77 !important; border-color: #522 !important; }';
            document.head.appendChild(style);
          ''',
          );
        },
        onReceivedError: (controller, request, error) {
          if (request.isForMainFrame == true && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Could not load Wikipedia: ${error.description}'),
              ),
            );
          }
        },
      ),
    );
  }
}
