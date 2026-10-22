import 'package:flutter/material.dart';

import '../screens/dashboard/dashboard_screen.dart';
import '../screens/contacts/contacts_screen.dart';
import '../screens/meetings/meetings_screen.dart';
import '../screens/meetings/meeting_extraction_screen.dart';
import '../screens/tasks/tasks_screen.dart';
import '../screens/calendar/calendar_screen.dart';
import '../screens/search/search_screen.dart';
import '../screens/profile/profile_screen.dart';

class AppRoutes {
  static const String dashboard = '/dashboard';
  static const String contacts = '/contacts';
  static const String meetings = '/meetings';
  static const String meetingExtraction = '/meeting-extraction';
  static const String tasks = '/tasks';
  static const String calendar = '/calendar';
  static const String search = '/search';
  static const String profile = '/profile';

  static Map<String, WidgetBuilder> get routes => {
        dashboard: (context) => const DashboardScreen(),
        contacts: (context) => const ContactsScreen(),
        meetings: (context) => const MeetingsScreen(),
        meetingExtraction: (context) => const MeetingExtractionScreen(),
        tasks: (context) => const TasksScreen(),
        calendar: (context) => const CalendarScreen(),
        search: (context) => const SearchScreen(),
        profile: (context) => const ProfileScreen(),
      };
}