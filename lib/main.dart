import 'dart:html' as html;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:microfrontends/microfrontends.dart';

import 'gl_web/web/main.dart';

String? mesh;
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(App());

  ui.platformViewRegistry.registerViewFactory(
    'canvas',
    (viewId) {
      final canvas = html.CanvasElement();
      render(canvas, mesh!);
      return canvas;
    },
  );
}

class App extends FutureStateWidget<String> {
  final future = rootBundle.loadString('monkey.obj');
  // final future = Future.value('');

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        // body: Container(),
        body: CaseAsyncType<String>()
          ..loaded((context, state) {
            mesh = state.state;
            return HtmlElementView(viewType: 'canvas');
          })
          ..otherwise((context, state) => SizedBox.shrink())
          ..errored((context, state) {
            print(state.exception);
            return Text(state.exception.toString());
          }),
      ),
    );
  }
}
