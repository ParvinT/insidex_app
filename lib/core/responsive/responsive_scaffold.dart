import 'package:flutter/material.dart';
import 'context_ext.dart';

class ResponsiveScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? bottomNav;
  final Color bg;

  const ResponsiveScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.bottomNav,
    this.bg = const Color(0xFFF8F8F8),
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      appBar: appBar,
      body: SafeArea(
        top: true,
        bottom: bottomNav == null,
        child: body,
      ),
      bottomNavigationBar: bottomNav == null
          ? null
          : Builder(
              builder: (context) {
                final media = MediaQuery.of(context);
                final bottomInset =
                    media.padding.bottom; // çentik/gesture alanı
                final visualHeight = context.isTablet
                    ? 64.0
                    : (context.isCompactH ? 56.0 : 60.0);

                return SizedBox(
                  height: visualHeight + bottomInset, // toplam bar yüksekliği
                  child: Padding(
                    padding: EdgeInsets.only(bottom: bottomInset),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(20)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: .08),
                            blurRadius: 10,
                            offset: const Offset(0, -2),
                          ),
                        ],
                      ),
                      child: SizedBox.expand(child: bottomNav),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
