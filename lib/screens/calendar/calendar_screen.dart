import 'package:flutter/material.dart';
import '../../widgets/feature_placeholder.dart';

class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const FeaturePlaceholder(
      title: 'Calendar',
      description: 'Calendar integration will be implemented later.',
      icon: Icons.calendar_month_outlined,
    );
  }
}