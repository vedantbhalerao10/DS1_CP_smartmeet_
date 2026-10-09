import 'package:flutter/material.dart';
import '../../widgets/feature_placeholder.dart';

class CommunicationScreen extends StatelessWidget {
  const CommunicationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const FeaturePlaceholder(
      title: 'Communication',
      description: 'Communication management will be implemented later.',
      icon: Icons.chat_outlined,
    );
  }
}