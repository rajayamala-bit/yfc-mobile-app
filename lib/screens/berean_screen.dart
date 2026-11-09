import 'package:flutter/material.dart';
import '../widgets/berean_ai_widget.dart';

class BereanScreen extends StatelessWidget {
  final String? initialQuery;
  final String? preferredLanguage;

  const BereanScreen({
    super.key,
    this.initialQuery,
    this.preferredLanguage,
  });

  @override
  Widget build(BuildContext context) {
    return BereanAiWidget(
      initialQuery: initialQuery,
      preferredLanguage: preferredLanguage,
    );
  }
}
