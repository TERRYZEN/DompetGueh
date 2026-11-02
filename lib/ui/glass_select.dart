import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme.dart';
import 'visuals.dart';

class GlassSelect<T> extends StatefulWidget {
  final T value;
  final Map<T, String> options;
  final Map<T, String> descriptions;
  final ValueChanged<T> onChanged;
  final bool enabled;
  const GlassSelect({
    super.key,
    required this.value,
    required this.options,
    required this.onChanged,
    this.descriptions = const {},
    this.enabled = true,
  });
  static VoidCallback? _closeCurrent;
  static void closeAll() => _closeCurrent?.call();
  @override
  State<GlassSelect<T>> createState() => _GlassSelectState<T>();
}

class _GlassSelectState<T> extends State<GlassSelect<T>>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final link = LayerLink(), triggerKey = GlobalKey();
  final triggerFocus = FocusNode(),
      menuFocus = FocusNode(),
      menuScroll = ScrollController();
  OverlayEntry? entry;
  late final AnimationController animation;
  int highlight = 0;
  String search = '';
  Timer? searchTimer;
  bool get open => entry != null;
  @override
  void initState() {
    super.initState();
    animation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeMetrics() {
    if (open) close(focus: false);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    searchTimer?.cancel();
    entry?.remove();
    entry?.dispose();
    entry = null;
    if (GlassSelect._closeCurrent == closeFromOutside)
      GlassSelect._closeCurrent = null;
    animation.dispose();
    triggerFocus.dispose();
    menuFocus.dispose();
    menuScroll.dispose();
    super.dispose();
  }

  void closeFromOutside() => close(focus: false);
  void close({bool focus = true}) {
    if (!open) return;
    entry!.remove();
    entry!.dispose();
    entry = null;
    if (GlassSelect._closeCurrent == closeFromOutside)
      GlassSelect._closeCurrent = null;
    if (mounted) {
      setState(() {});
      if (focus) triggerFocus.requestFocus();
    }
  }

  void choose(int index) {
    final value = widget.options.keys.elementAt(index);
    close();
    widget.onChanged(value);
  }

  void moveTo(int index) {
    highlight = (index + widget.options.length) % widget.options.length;
    entry?.markNeedsBuild();
    final height = widget.descriptions.isEmpty ? 44.0 : 55.0;
    if (menuScroll.hasClients) {
      final top = highlight * height;
      final bottom = top + height;
      if (top < menuScroll.offset)
        menuScroll.jumpTo(top);
      else if (bottom >
          menuScroll.offset + menuScroll.position.viewportDimension)
        menuScroll.jumpTo(
          (bottom - menuScroll.position.viewportDimension).clamp(
            0,
            menuScroll.position.maxScrollExtent,
          ),
        );
    }
  }

  KeyEventResult key(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final k = event.logicalKey;
    if (k == LogicalKeyboardKey.escape && open) {
      close();
      return KeyEventResult.handled;
    }
    if (k == LogicalKeyboardKey.tab && open) {
      close();
      return KeyEventResult.ignored;
    }
    if (k == LogicalKeyboardKey.arrowDown ||
        k == LogicalKeyboardKey.arrowUp ||
        k == LogicalKeyboardKey.home ||
        k == LogicalKeyboardKey.end) {
      if (!open) {
        show();
        if (k == LogicalKeyboardKey.home) moveTo(0);
        if (k == LogicalKeyboardKey.end) moveTo(widget.options.length - 1);
      } else
        moveTo(
          k == LogicalKeyboardKey.home
              ? 0
              : k == LogicalKeyboardKey.end
              ? widget.options.length - 1
              : highlight + (k == LogicalKeyboardKey.arrowDown ? 1 : -1),
        );
      return KeyEventResult.handled;
    }
    if (open &&
        (k == LogicalKeyboardKey.enter || k == LogicalKeyboardKey.space)) {
      choose(highlight);
      return KeyEventResult.handled;
    }
    if (open &&
        event.character != null &&
        event.character!.trim().isNotEmpty &&
        !HardwareKeyboard.instance.isControlPressed &&
        !HardwareKeyboard.instance.isMetaPressed) {
      search += event.character!.toLowerCase();
      searchTimer?.cancel();
      searchTimer = Timer(const Duration(milliseconds: 600), () => search = '');
      final index = widget.options.values.toList().indexWhere(
        (s) => s.toLowerCase().startsWith(search),
      );
      if (index >= 0) moveTo(index);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void show() {
    if (!widget.enabled || open) return;
    GlassSelect.closeAll();
    final box = triggerKey.currentContext!.findRenderObject()! as RenderBox;
    final rect = box.localToGlobal(Offset.zero) & box.size;
    final screen = MediaQuery.of(context);
    Rect bounds = Rect.fromLTWH(
      0,
      screen.padding.top,
      screen.size.width,
      screen.size.height -
          screen.viewInsets.bottom -
          screen.padding.top -
          screen.padding.bottom,
    );
    context.visitAncestorElements((element) {
      if (element.widget is SingleChildScrollView) {
        final object = element.findRenderObject();
        if (object is RenderBox) {
          bounds = object.localToGlobal(Offset.zero) & object.size;
        }
        return false;
      }
      return true;
    });
    final below =
        math.min(
          bounds.bottom - 8,
          screen.size.height - screen.viewInsets.bottom - 8,
        ) -
        rect.bottom -
        7;
    final above =
        rect.top - math.max(bounds.top + 8, screen.padding.top + 8) - 7;
    final fullHeight =
        (widget.descriptions.isEmpty ? 44.0 : 55.0) * widget.options.length +
        12;
    final up = below < math.min(fullHeight, 180) && above > below;
    final maxHeight = math.max(60.0, math.min(280.0, up ? above : below));
    final c = context.palette;
    highlight = widget.options.keys.toList().indexOf(widget.value);
    entry = OverlayEntry(
      builder: (overlayContext) => Stack(
        children: [
          CompositedTransformFollower(
            link: link,
            showWhenUnlinked: false,
            targetAnchor: up ? Alignment.topLeft : Alignment.bottomLeft,
            followerAnchor: up ? Alignment.bottomLeft : Alignment.topLeft,
            offset: Offset(0, up ? -7 : 7),
            child: TapRegion(
              groupId: this,
              onTapOutside: (_) => close(focus: false),
              child: Focus(
                focusNode: menuFocus,
                onKeyEvent: key,
                child: AnimatedBuilder(
                  animation: animation,
                  builder: (context, child) {
                    final t = cssEase.transform(animation.value);
                    return Opacity(
                      opacity: t,
                      child: Transform.translate(
                        offset: Offset(0, -5 * (1 - t)),
                        child: child,
                      ),
                    );
                  },
                  child: Material(
                    type: MaterialType.transparency,
                    child: SizedBox(
                      width: rect.width,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(
                                alpha: c.dark ? 0.30 : 0.19,
                              ),
                              blurRadius: 40,
                              offset: const Offset(0, 14),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: BackdropFilter(
                            filter: saturatedBlur(22, 1.6),
                            child: Container(
                              constraints: BoxConstraints(maxHeight: maxHeight),
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: c.dark
                                    ? const Color.fromRGBO(36, 49, 69, .8)
                                    : const Color.fromRGBO(244, 248, 255, .78),
                                border: Border.all(
                                  color: c.dark
                                      ? const Color.fromRGBO(173, 198, 229, .23)
                                      : const Color.fromRGBO(
                                          255,
                                          255,
                                          255,
                                          .85,
                                        ),
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: ListView.builder(
                                controller: menuScroll,
                                padding: EdgeInsets.zero,
                                shrinkWrap: true,
                                itemCount: widget.options.length,
                                itemBuilder: (context, index) {
                                  final value = widget.options.keys.elementAt(
                                        index,
                                      ),
                                      selected = value == widget.value;
                                  return MouseRegion(
                                    onEnter: (_) {
                                      highlight = index;
                                      entry?.markNeedsBuild();
                                    },
                                    child: Semantics(
                                      selected: selected,
                                      button: true,
                                      child: InkWell(
                                        onTap: () => choose(index),
                                        borderRadius: BorderRadius.circular(10),
                                        child: Container(
                                          constraints: const BoxConstraints(
                                            minHeight: 44,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 11,
                                          ),
                                          decoration: BoxDecoration(
                                            color: selected
                                                ? primary.withValues(
                                                    alpha: 0.09,
                                                  )
                                                : index == highlight
                                                ? primary.withValues(
                                                    alpha: 0.12,
                                                  )
                                                : Colors.transparent,
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      widget.options[value]!,
                                                      style: TextStyle(
                                                        fontFamily: 'DMSans',
                                                        fontSize: 12,
                                                        height: 4 / 3,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: selected
                                                            ? (c.dark
                                                                  ? const Color(
                                                                      0xff69baff,
                                                                    )
                                                                  : primary)
                                                            : c.text,
                                                      ),
                                                    ),
                                                    if (widget
                                                            .descriptions[value] !=
                                                        null) ...[
                                                      const SizedBox(height: 4),
                                                      Text(
                                                        widget
                                                            .descriptions[value]!,
                                                        style: TextStyle(
                                                          fontFamily: 'DMSans',
                                                          fontSize: 10,
                                                          height: 1.3,
                                                          color: c.muted,
                                                        ),
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Opacity(
                                                opacity: selected ? 1 : 0,
                                                child: const Icon(
                                                  Icons.check,
                                                  size: 14,
                                                  color: primary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
    Overlay.of(context).insert(entry!);
    GlassSelect._closeCurrent = closeFromOutside;
    animation.duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 180);
    animation.forward(from: 0);
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && open) menuFocus.requestFocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    return CompositedTransformTarget(
      link: link,
      child: TapRegion(
        groupId: this,
        onTapOutside: (_) {
          if (open) close(focus: false);
        },
        child: Focus(
          focusNode: triggerFocus,
          onKeyEvent: key,
          child: Semantics(
            button: true,
            expanded: open,
            value: widget.options[widget.value],
            child: Container(
              key: triggerKey,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: open
                    ? [
                        BoxShadow(
                          color: primary.withValues(alpha: 0.10),
                          blurRadius: 0,
                          spreadRadius: 3,
                        ),
                      ]
                    : null,
              ),
              child: SizedBox(
                height: 46,
                child: TextButton(
                  onPressed: !widget.enabled
                      ? null
                      : () {
                          if (open) {
                            close();
                          } else {
                            show();
                          }
                        },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 11,
                    ),
                    minimumSize: const Size(0, 46),
                    side: BorderSide(
                      color: open
                          ? primary
                          : c.dark
                          ? c.line
                          : const Color(0xffdfe5ef),
                    ),
                    backgroundColor: c.dark
                        ? (open
                              ? const Color.fromRGBO(33, 46, 66, .85)
                              : const Color.fromRGBO(18, 25, 42, .7))
                        : (open
                              ? const Color.fromRGBO(255, 255, 255, .80)
                              : const Color.fromRGBO(255, 255, 255, .62)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.options[widget.value] ?? 'Pilih opsi',
                          style: TextStyle(
                            fontSize: 12,
                            height: 4 / 3,
                            fontWeight: FontWeight.w500,
                            color: c.text,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      AnimatedRotation(
                        turns: open ? 0.5 : 0,
                        duration: MediaQuery.disableAnimationsOf(context)
                            ? Duration.zero
                            : const Duration(milliseconds: 200),
                        curve: cssEase,
                        child: Icon(
                          Icons.expand_more,
                          size: 18,
                          color: c.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
