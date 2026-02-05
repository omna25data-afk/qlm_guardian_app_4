import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// مكون تبويبات موحد بتصميم Segment (متصلة داخل إطار)
/// 
/// Example:
/// ```dart
/// CustomSegmentedTabBar(
///   controller: _tabController,
///   tabs: const ['الأمناء', 'التراخيص', 'البطائق'],
/// )
/// ```
class CustomSegmentedTabBar extends StatelessWidget {
  final TabController controller;
  final List<String> tabs;
  final Color? activeColor;
  final Color? inactiveColor;
  final Color? backgroundColor;
  final double height;
  final double borderRadius;
  final EdgeInsets padding;
  final EdgeInsets margin;

  const CustomSegmentedTabBar({
    super.key,
    required this.controller,
    required this.tabs,
    this.activeColor,
    this.inactiveColor,
    this.backgroundColor,
    this.height = 42,
    this.borderRadius = 12,
    this.padding = const EdgeInsets.all(4),
    this.margin = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = activeColor ?? const Color(0xFF006400);
    final bgColor = backgroundColor ?? Colors.grey[100];
    final inactiveTextColor = inactiveColor ?? Colors.grey[700];

    return Container(
      margin: margin,
      height: height,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: padding,
        child: TabBar(
          controller: controller,
          tabs: tabs.map((t) => Tab(text: t)).toList(),
          indicator: BoxDecoration(
            color: primaryColor,
            borderRadius: BorderRadius.circular(borderRadius - 2),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withValues(alpha: 0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          labelColor: Colors.white,
          unselectedLabelColor: inactiveTextColor,
          labelStyle: GoogleFonts.tajawal(
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
          unselectedLabelStyle: GoogleFonts.tajawal(
            fontWeight: FontWeight.w500,
            fontSize: 13,
          ),
          splashFactory: NoSplash.splashFactory,
          overlayColor: WidgetStateProperty.all(Colors.transparent),
          labelPadding: const EdgeInsets.symmetric(horizontal: 8),
        ),
      ),
    );
  }
}

/// مكون تبويبات صغير للاستخدام في الأقسام الداخلية
class CustomMiniTabBar extends StatelessWidget {
  final TabController controller;
  final List<String> tabs;
  final Color? activeColor;

  const CustomMiniTabBar({
    super.key,
    required this.controller,
    required this.tabs,
    this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = activeColor ?? const Color(0xFF006400);

    return Container(
      height: 36,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(10),
      ),
      child: TabBar(
        controller: controller,
        isScrollable: true,
        tabs: tabs.map((t) => Tab(text: t)).toList(),
        indicator: BoxDecoration(
          color: primaryColor,
          borderRadius: BorderRadius.circular(8),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey[600],
        labelStyle: GoogleFonts.tajawal(
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
        unselectedLabelStyle: GoogleFonts.tajawal(
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
        splashFactory: NoSplash.splashFactory,
        overlayColor: WidgetStateProperty.all(Colors.transparent),
        labelPadding: const EdgeInsets.symmetric(horizontal: 12),
        tabAlignment: TabAlignment.start,
      ),
    );
  }
}

/// تبويبات سفلية للاستخدام داخل الـ Cards
class CustomInlineTabBar extends StatelessWidget {
  final TabController controller;
  final List<String> tabs;
  final Color? indicatorColor;

  const CustomInlineTabBar({
    super.key,
    required this.controller,
    required this.tabs,
    this.indicatorColor,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = indicatorColor ?? const Color(0xFF006400);

    return TabBar(
      controller: controller,
      tabs: tabs.map((t) => Tab(text: t)).toList(),
      labelColor: activeColor,
      unselectedLabelColor: Colors.grey,
      labelStyle: GoogleFonts.tajawal(fontWeight: FontWeight.bold, fontSize: 14),
      unselectedLabelStyle: GoogleFonts.tajawal(fontWeight: FontWeight.w500, fontSize: 14),
      indicatorColor: activeColor,
      indicatorWeight: 3,
      indicatorSize: TabBarIndicatorSize.label,
      dividerColor: Colors.grey.shade200,
    );
  }
}
