import 'package:flutter/material.dart';
import '../../widgets/feature_placeholder.dart';

class MeetingsScreen extends StatelessWidget {
  const MeetingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const FeaturePlaceholder(
      title: 'Meetings',
      description: 'Meeting management will be implemented later.',
      icon: Icons.groups_outlined,
    );
  }
}