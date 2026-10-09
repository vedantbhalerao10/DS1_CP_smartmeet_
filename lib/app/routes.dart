import 'package:flutter/material.dart';

import '../screens/dashboard/dashboard_screen.dart';
import '../screens/contacts/contacts_screen.dart';
import '../screens/meetings/meetings_screen.dart';
import '../screens/tasks/tasks_screen.dart';
import '../screens/communication/communication_screen.dart';
import '../screens/calendar/calendar_screen.dart';
import '../screens/search/search_screen.dart';
import '../screens/profile/profile_screen.dart';

Map<String, WidgetBuilder> appRoutes = {
  '/dashboard': (context) => const DashboardScreen(),
  '/contacts': (context) => const ContactsScreen(),
  '/meetings': (context) => const MeetingsScreen(),
  '/tasks': (context) => const TasksScreen(),
  '/communication': (context) => const CommunicationScreen(),
  '/calendar': (context) => const CalendarScreen(),
  '/search': (context) => const SearchScreen(),
  '/profile': (context) => const ProfileScreen(),
};