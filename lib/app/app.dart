import 'package:flutter/material.dart';
import 'routes.dart';

class SmartMeetApp extends StatelessWidget {
const SmartMeetApp({super.key});

@override
Widget build(BuildContext context) {
return MaterialApp(
debugShowCheckedModeBanner: false,
title: 'DS1CPSmartMeet',
theme: ThemeData(
useMaterial3: true,
colorSchemeSeed: Colors.indigo,
scaffoldBackgroundColor: const Color(0xfff6f7fb),
),
initialRoute: AppRoutes.dashboard,
routes: AppRoutes.routes,
);
}
}
