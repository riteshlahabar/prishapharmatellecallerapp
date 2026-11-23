import 'package:material_ui/material_ui.dart';

import '../app_theme.dart';

/// The brand furniture every screen is built from.
///
/// Four widgets, each one a thing the design does repeatedly: a gradient app
/// bar, a gradient hero panel, a coloured statistic card and a tinted icon
/// pad. They are here rather than copied into screens so that a change to the
/// brand is a change to two files — this one and [AppTheme].

/// A gradient app bar. The theme already tints a plain [AppBar]; this adds
/// the pale teal-to-green sweep, which a plain AppBar cannot express.
class BrandAppBar extends StatelessWidget implements PreferredSizeWidget {
  const BrandAppBar({
    required this.title,
    this.subtitle,
    this.actions,
    this.leading,
    super.key,
  });

  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final Widget? leading;

  @override
  Size get preferredSize => Size.fromHeight(subtitle == null ? 56 : 72);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: leading,
      actions: actions,
      toolbarHeight: preferredSize.height,
      flexibleSpace: const DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppTheme.barGradient,
          border: Border(bottom: BorderSide(color: AppTheme.line)),
        ),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title),
          if (subtitle != null)
            Text(
              subtitle!,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: AppTheme.textSecondary,
              ),
            ),
        ],
      ),
    );
  }
}

/// The panel a screen opens with: who you are, what day it is, and whatever
/// one fact matters most. A pale brand wash rounded off at the bottom, so
/// the content below looks like it is sliding out from under it.
class BrandHeader extends StatelessWidget {
  const BrandHeader({
    required this.title,
    this.subtitle,
    this.trailing,
    this.child,
    this.onBack,
    super.key,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Widget? child;

  /// Set on a screen that was pushed rather than reached from a tab: the
  /// header replaces the app bar, so the way back has to live in it.
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
      decoration: const BoxDecoration(
        gradient: AppTheme.brandGradient,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(26)),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (onBack != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: IconButton(
                      onPressed: onBack,
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(
                        Icons.arrow_back,
                        color: AppTheme.tealDark,
                      ),
                      tooltip: 'Back',
                    ),
                  ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: AppTheme.tealDark,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                ?trailing,
              ],
            ),
            if (child != null) ...[const SizedBox(height: 16), child!],
          ],
        ),
      ),
    );
  }
}

/// One headline number on a pale coloured card. The hue carries meaning —
/// the caller picks it from [AppTheme]'s tile palette — so a glance at the
/// row tells the rep which figure is which before they read a word. The wash
/// stays light; the icon and the number are what carry the colour.
class StatCard extends StatelessWidget {
  const StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.colour,
    this.footnote,
    this.onTap,
    super.key,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color colour;
  final String? footnote;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            gradient: AppTheme.tileGradient(colour),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.tint(colour)),
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(icon, size: 15, color: colour),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppTheme.ink(colour),
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (footnote != null) ...[
                const SizedBox(height: 2),
                Text(
                  footnote!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// A rounded, tinted square with an icon in it — the leading element on most
/// list rows. Tinting rather than filling keeps a long list calm.
class IconPad extends StatelessWidget {
  const IconPad({
    required this.icon,
    required this.colour,
    this.size = 40,
    super.key,
  });

  final IconData icon;
  final Color colour;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppTheme.tint(colour),
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      child: Icon(icon, size: size * 0.5, color: colour),
    );
  }
}

/// A small status word on a tinted pill.
class StatusChip extends StatelessWidget {
  const StatusChip({required this.label, required this.colour, super.key});

  final String label;
  final Color colour;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.tint(colour),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          color: colour,
        ),
      ),
    );
  }
}
