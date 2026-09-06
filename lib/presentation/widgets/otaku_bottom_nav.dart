import 'package:flutter/material.dart';

/// Description d'un onglet de la [OtakuBottomNav].
class OtakuNavItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  const OtakuNavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });
}

/// Bottom navigation bar à l'identité "encre de manga" :
/// - fond sombre/planche avec un hairline rouge sceau en bordure haute ;
/// - un trait rouge qui glisse sous l'onglet actif ;
/// - icône et libellé qui réagissent (scale + fade) à la sélection.
///
/// Volontairement custom (plutôt que [NavigationBar]) pour garder un
/// contrôle total sur l'identité visuelle et les micro-animations.
class OtakuBottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final List<OtakuNavItem> items;

  const OtakuBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        border: Border(
          top: BorderSide(color: scheme.primary.withOpacity(0.32), width: 1.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.32),
            blurRadius: 18,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 66,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final itemWidth = constraints.maxWidth / items.length;
              return Stack(
                children: [
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                    left: itemWidth * selectedIndex,
                    top: 0,
                    width: itemWidth,
                    height: 3,
                    child: Center(
                      child: Container(
                        width: 26,
                        height: 3,
                        decoration: BoxDecoration(
                          color: scheme.primary,
                          borderRadius: BorderRadius.circular(2),
                          boxShadow: [
                            BoxShadow(
                              color: scheme.primary.withOpacity(0.55),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Row(
                    children: List.generate(items.length, (i) {
                      return Expanded(
                        child: _NavTile(
                          item: items[i],
                          selected: i == selectedIndex,
                          onTap: () => onSelected(i),
                        ),
                      );
                    }),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _NavTile extends StatefulWidget {
  final OtakuNavItem item;
  final bool selected;
  final VoidCallback onTap;

  const _NavTile({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_NavTile> createState() => _NavTileState();
}

class _NavTileState extends State<_NavTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bounce = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 160),
  );

  @override
  void dispose() {
    _bounce.dispose();
    super.dispose();
  }

  Future<void> _playBounce() async {
    await _bounce.forward();
    if (mounted) await _bounce.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color =
        widget.selected ? scheme.primary : scheme.onSurface.withOpacity(0.5);
    final scaleAnim = Tween<double>(begin: 1, end: 0.86)
        .chain(CurveTween(curve: Curves.easeOut))
        .animate(_bounce);

    return Semantics(
      selected: widget.selected,
      button: true,
      label: widget.item.label,
      child: InkResponse(
        onTap: () {
          _playBounce();
          widget.onTap();
        },
        radius: 40,
        highlightShape: BoxShape.rectangle,
        child: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: ScaleTransition(
            scale: scaleAnim,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  transitionBuilder: (child, anim) => ScaleTransition(
                    scale: anim,
                    child: FadeTransition(opacity: anim, child: child),
                  ),
                  child: Icon(
                    widget.selected ? widget.item.selectedIcon : widget.item.icon,
                    key: ValueKey(widget.selected),
                    color: color,
                    size: 23,
                  ),
                ),
                const SizedBox(height: 4),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: widget.selected ? FontWeight.w700 : FontWeight.w500,
                    color: color,
                    letterSpacing: 0.15,
                  ),
                  child: Text(widget.item.label, maxLines: 1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
