import 'package:flutter/material.dart';
import 'measure_size.dart';

/// AuthScaffold v4
/// - Fixes assertion on short-height screens when BODY is a Column with Expanded.
/// - Uses IntrinsicHeight ONLY when body is NOT scrollable (Column/Stack).
/// - If body IS scrollable (ListView/ScrollView), it does NOT wrap with another scroll;
///   it only adds bottom padding equal to the measured bottomArea height.
class AuthScaffold extends StatefulWidget {
  final PreferredSizeWidget? appBar;
  final Widget body;
  final Color? backgroundColor;
  final Widget? bottomArea;
  final Widget? floatingActionButton;
  final double bottomAreaVisualHeight;
  final bool? bodyIsScrollable;

  const AuthScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.backgroundColor,
    this.bottomArea,
    this.floatingActionButton,
    this.bottomAreaVisualHeight = 72.0,
    this.bodyIsScrollable,
  });

  @override
  State<AuthScaffold> createState() => _AuthScaffoldState();
}

class _AuthScaffoldState extends State<AuthScaffold> {
  double? _measuredBottomH;

  bool _looksScrollable(Widget w) {
    return w is ScrollView ||
        w is SingleChildScrollView ||
        w is ListView ||
        w is CustomScrollView ||
        w is GridView;
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final kbInset = media.viewInsets.bottom;
    final safeBottom = media.padding.bottom;
    final shortHeight = media.size.height <= 820; // Nest Hub / Max
    const double kFooterExtra = 8.0; // extra breathing room to avoid clipping

    final bodyIsScrollable =
        widget.bodyIsScrollable ?? _looksScrollable(widget.body);
    final needsScrollWrapper =
        !bodyIsScrollable && (shortHeight || kbInset > 0);

    final bottomVisual =
        (_measuredBottomH ?? widget.bottomAreaVisualHeight).clamp(48.0, 160.0);

    Widget content = widget.body;

    if (needsScrollWrapper) {
      // Body is NOT scrollable (Column/Stack). We wrap it with a SingleChildScrollView,
      // and use ConstrainedBox(minHeight) + IntrinsicHeight so that any Expanded inside Column works.
      content = LayoutBuilder(
        builder: (context, viewport) {
          return SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.only(
              bottom: widget.bottomArea == null
                  ? 0.0
                  : bottomVisual + safeBottom + 12.0 + kFooterExtra,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: viewport.maxHeight),
              child: IntrinsicHeight(child: widget.body),
            ),
          );
        },
      );
    } else if (widget.bottomArea != null) {
      // Body IS scrollable. Don't add another scroll; just ensure bottom padding.
      content = Padding(
        padding: EdgeInsets.only(
            bottom: bottomVisual + safeBottom + 12.0 + kFooterExtra),
        child: widget.body,
      );
    }

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: widget.backgroundColor ?? const Color(0xFFFFFFFF),
      appBar: widget.appBar,
      body: SafeArea(
        top: true,
        bottom: widget.bottomArea == null,
        child: content,
      ),
      bottomNavigationBar: widget.bottomArea == null
          ? null
          : SafeArea(
              top: false,
              bottom: true,
              minimum: EdgeInsets.only(bottom: kFooterExtra),
              child: MeasureSize(
                onChange: (s) => setState(() => _measuredBottomH = s.height),
                child: widget.bottomArea!,
              ),
            ),
      floatingActionButton: widget.floatingActionButton,
    );
  }
}
