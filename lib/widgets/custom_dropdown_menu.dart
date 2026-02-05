import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// عنصر في القائمة المنسدلة
class CustomMenuItem {
  final String label;
  final IconData icon;
  final Color? iconColor;
  final Color? textColor;
  final VoidCallback? onTap;
  final bool isDivider;
  final bool isDestructive;

  const CustomMenuItem({
    required this.label,
    required this.icon,
    this.iconColor,
    this.textColor,
    this.onTap,
    this.isDivider = false,
    this.isDestructive = false,
  });

  /// إنشاء فاصل
  factory CustomMenuItem.divider() => const CustomMenuItem(
        label: '',
        icon: Icons.horizontal_rule,
        isDivider: true,
      );
}

/// قائمة منسدلة محسّنة ومتناسقة مع تصميم التطبيق
/// 
/// Example:
/// ```dart
/// CustomDropdownMenu(
///   trigger: CircleAvatar(),
///   items: [
///     CustomMenuItem(label: 'الملف الشخصي', icon: Icons.person, onTap: () {}),
///     CustomMenuItem.divider(),
///     CustomMenuItem(label: 'تسجيل الخروج', icon: Icons.logout, isDestructive: true, onTap: () {}),
///   ],
/// )
/// ```
class CustomDropdownMenu extends StatelessWidget {
  final Widget trigger;
  final List<CustomMenuItem> items;
  final Offset offset;
  final double menuWidth;
  final Color? backgroundColor;
  final double borderRadius;

  const CustomDropdownMenu({
    super.key,
    required this.trigger,
    required this.items,
    this.offset = const Offset(0, 50),
    this.menuWidth = 220,
    this.backgroundColor,
    this.borderRadius = 16,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<int>(
      offset: offset,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      color: backgroundColor ?? Colors.white,
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: 0.15),
      surfaceTintColor: Colors.transparent,
      child: trigger,
      onSelected: (index) {
        if (index >= 0 && index < items.length) {
          items[index].onTap?.call();
        }
      },
      itemBuilder: (context) {
        return List.generate(items.length, (index) {
          final item = items[index];

          if (item.isDivider) {
            return PopupMenuItem<int>(
              enabled: false,
              height: 1,
              padding: EdgeInsets.zero,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                height: 1,
                color: Colors.grey.shade200,
              ),
            );
          }

          final textColor = item.isDestructive
              ? Colors.red
              : (item.textColor ?? Colors.grey[800]);
          final iconColor = item.isDestructive
              ? Colors.red
              : (item.iconColor ?? Colors.grey[600]);

          return PopupMenuItem<int>(
            value: index,
            padding: EdgeInsets.zero,
            child: Container(
              width: menuWidth,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: (item.isDestructive ? Colors.red : Colors.grey)
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(item.icon, color: iconColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item.label,
                      style: GoogleFonts.tajawal(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: textColor,
                      ),
                    ),
                  ),
                  if (!item.isDestructive)
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: Colors.grey[400],
                    ),
                ],
              ),
            ),
          );
        });
      },
    );
  }
}

/// قائمة منسدلة مع Header
class CustomDropdownMenuWithHeader extends StatelessWidget {
  final Widget trigger;
  final Widget header;
  final List<CustomMenuItem> items;
  final Offset offset;
  final double menuWidth;

  const CustomDropdownMenuWithHeader({
    super.key,
    required this.trigger,
    required this.header,
    required this.items,
    this.offset = const Offset(0, 50),
    this.menuWidth = 240,
  });

  void _showMenu(BuildContext context) {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final RenderBox overlay =
        Navigator.of(context).overlay!.context.findRenderObject() as RenderBox;
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(offset, ancestor: overlay),
        button.localToGlobal(button.size.bottomRight(Offset.zero) + offset,
            ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );

    showMenu<int>(
      context: context,
      position: position,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: 0.15),
      surfaceTintColor: Colors.transparent,
      items: [
        // Header
        PopupMenuItem<int>(
          enabled: false,
          padding: EdgeInsets.zero,
          child: Container(
            width: menuWidth,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF006400).withValues(alpha: 0.05),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: header,
          ),
        ),
        // Divider
        PopupMenuItem<int>(
          enabled: false,
          height: 1,
          padding: EdgeInsets.zero,
          child: Container(height: 1, color: Colors.grey.shade200),
        ),
        // Items
        ...List.generate(items.length, (index) {
          final item = items[index];

          if (item.isDivider) {
            return PopupMenuItem<int>(
              enabled: false,
              height: 1,
              padding: EdgeInsets.zero,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                height: 1,
                color: Colors.grey.shade200,
              ),
            );
          }

          final textColor =
              item.isDestructive ? Colors.red : (item.textColor ?? Colors.grey[800]);
          final iconColor =
              item.isDestructive ? Colors.red : (item.iconColor ?? Colors.grey[600]);

          return PopupMenuItem<int>(
            value: index,
            padding: EdgeInsets.zero,
            onTap: item.onTap,
            child: Container(
              width: menuWidth,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: (item.isDestructive ? Colors.red : Colors.grey)
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(item.icon, color: iconColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item.label,
                      style: GoogleFonts.tajawal(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: textColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showMenu(context),
      child: trigger,
    );
  }
}

/// ورقة سفلية محسّنة للفلتر والفرز
class CustomBottomSheet extends StatelessWidget {
  final String title;
  final Widget child;
  final VoidCallback? onApply;
  final String applyLabel;

  const CustomBottomSheet({
    super.key,
    required this.title,
    required this.child,
    this.onApply,
    this.applyLabel = 'تطبيق',
  });

  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required Widget child,
    VoidCallback? onApply,
    String applyLabel = 'تطبيق',
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CustomBottomSheet(
        title: title,
        onApply: onApply,
        applyLabel: applyLabel,
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF006400).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.tune, color: Color(0xFF006400), size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: GoogleFonts.tajawal(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, color: Colors.grey[400]),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: child,
            ),
          ),
          // Apply Button
          if (onApply != null)
            Container(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    onApply?.call();
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF006400),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 2,
                  ),
                  child: Text(
                    applyLabel,
                    style: GoogleFonts.tajawal(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
