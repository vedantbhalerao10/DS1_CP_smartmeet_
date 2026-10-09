import 'package:flutter/material.dart';
import '../../widgets/feature_placeholder.dart';

class TasksScreen extends StatelessWidget {
  const TasksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const FeaturePlaceholder(
      title: 'Tasks',
      description: 'Task management will be implemented later.',
      icon: Icons.task_alt_outlined,
    );
  }
}