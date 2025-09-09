// ignore_for_file: library_private_types_in_public_api
import 'package:flutter/widgets.dart';
import 'package:flutter/rendering.dart';

typedef OnWidgetSizeChange = void Function(Size size);

class MeasureSize extends SingleChildRenderObjectWidget {
  const MeasureSize({super.key, required this.onChange, super.child});
  final OnWidgetSizeChange onChange;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderMeasure(onChange);

  @override
  void updateRenderObject(
      BuildContext context, covariant _RenderMeasure renderObject) {
    renderObject.onChange = onChange;
  }
}

class _RenderMeasure extends RenderProxyBox {
  _RenderMeasure(this.onChange);
  OnWidgetSizeChange onChange;
  Size? _oldSize;

  @override
  void performLayout() {
    super.performLayout();
    final newSize = child?.size;
    if (newSize == null || _oldSize == newSize) return;
    _oldSize = newSize;
    WidgetsBinding.instance.addPostFrameCallback((_) => onChange(newSize));
  }
}
