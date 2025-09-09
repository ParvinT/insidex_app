import 'package:flutter/material.dart';
import 'context_ext.dart';

class FormScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget body;
  final Color? backgroundColor;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;

  const FormScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.backgroundColor,
    this.bottomNavigationBar,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    final kb = MediaQuery.of(context).viewInsets.bottom;
    final isCompact = context.isCompactH;

    final bool useScroll = kb > 0 || isCompact;

    Widget child = Padding(
      padding: EdgeInsets.only(bottom: kb),
      child: body,
    );

    if (useScroll) {
      child = SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: child,
      );
    }

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: backgroundColor ?? const Color(0xFFF8F8F8),
      appBar: appBar,
      body: SafeArea(
          top: true, bottom: bottomNavigationBar == null, child: child),
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
    );
  }
}
