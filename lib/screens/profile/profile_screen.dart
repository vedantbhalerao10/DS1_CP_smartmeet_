import 'package:flutter/material.dart';
import '../../widgets/feature_placeholder.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const FeaturePlaceholder(
      title: 'Profile',
      description: 'User profile management will be implemented later.',
      icon: Icons.person_outline,
    );
  }
}