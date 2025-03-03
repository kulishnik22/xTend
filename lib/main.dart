import 'dart:io';

import 'package:flutter/material.dart';
import 'package:xtend/app/app.dart';
import 'package:xtend/view/xtend_view.dart';

void main() async {
  if (!Platform.isWindows) {
    exit(0);
  }
  WidgetsFlutterBinding.ensureInitialized();
  XtendApp().registerDependencies();
  runApp(const XtendFlutterApp());
}

class XtendFlutterApp extends StatelessWidget {
  const XtendFlutterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: XtendApp().get<XtendView>(),
    );
  }
}
