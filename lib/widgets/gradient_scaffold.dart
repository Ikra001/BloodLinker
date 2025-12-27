import 'package:flutter/material.dart';

import 'package:blood_linker/constants.dart';
import 'package:blood_linker/widgets/common_app_bar.dart';

class GradientScaffold extends StatelessWidget {
  final Widget body;
  final bool showAppBar;

  const GradientScaffold({
    super.key,
    required this.body,
    this.showAppBar = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: showAppBar,
      appBar: showAppBar ? const CommonAppBar() : null,
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Constants.primaryColor, Constants.secondaryColor],
          ),
        ),
        child: SafeArea(child: body),
      ),
    );
  }
}
