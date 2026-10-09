import 'package:flutter/material.dart';
import '../../widgets/feature_placeholder.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const FeaturePlaceholder(
      title: 'Global Search',
      description: 'Global search will use the DSA engine later.',
      icon: Icons.search,
    );
  }
}