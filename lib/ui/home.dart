import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../core/controller.dart';
import '../core/models.dart';
import 'common.dart';
import 'dashboard.dart';
import 'forms.dart';
import 'history.dart';
import 'theme.dart';
import 'visuals.dart';

class HomeScreen extends StatefulWidget {
  final AppController controller;
  const HomeScreen({super.key, required this.controller});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool history = false;
  int year = DateTime.now().year;
  String type = 'semua';
  final scroll = ScrollController();
  final draft = EntryDraft();
  double drag = 0, dx = 0, startX = 0;
  final watch = Stopwatch();
  int direction = 1;
  AppController get app => widget.controller;
  @override
  void dispose() {
    scroll.dispose();
    super.dispose();
  }

  Future<void> entry([String type = 'pengeluaran']) async {
    final message = await showEntryForm(context, app, type: type, draft: draft);
    if (message != null && mounted) toast(context, message);
  }

  Future<void> profile() async {
    final message = await showProfileForm(context, app);
    if (message != null && mounted) toast(context, message);
  }

  Future<void> run(Future<void> Function() action) async {
    try {
      await action();
    } catch (e) {
      if (mounted) toast(context, errorText(e), error: true);
    }
  }

  Future<void> delete(FinanceEntry e) async {
    final yes = await showAppDialog<bool>(
      context,
      (ctx) => AlertDialog(
        backgroundColor: ctx.palette.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(19)),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Eyebrow('HISTORI KEUANGAN'),
            const SizedBox(height: 7),
            Text('Hapus transaksi?', style: heading(19)),
          ],
        ),
        content: Text(
          'Hapus ${e.income ? 'pemasukan' : 'pengeluaran'} "${e.name}"?${e.addedToBudget ? ' Anggaran juga akan berkurang.' : ''}',
          style: TextStyle(fontSize: 12, height: 1.5, color: ctx.palette.muted),
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          PressScale(
            child: ElevatedButton(
              key: const Key('confirm-delete'),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Hapus'),
            ),
          ),
        ],
      ),
    );
    if (yes != true || !mounted) return;
    try {
      final message = await app.delete(e);
      if (mounted) toast(context, message);
    } catch (error) {
      if (mounted) toast(context, errorText(error), error: true);
    }
  }

  void changePage(bool next) {
    if (next == history) {
      if (drag != 0) setState(() => drag = 0);
      return;
    }
    setState(() {
      direction = next ? 1 : -1;
      history = next;
      drag = 0;
    });
    if (scroll.hasClients) scroll.jumpTo(0);
  }

  Widget header(bool mobile, bool tiny) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 1168),
      child: Container(
        key: const Key('app-header'),
        padding: EdgeInsets.symmetric(
          horizontal: tiny
              ? 12
              : mobile
              ? 16
              : 36,
          vertical: tiny
              ? 14
              : mobile
              ? 16
              : 24,
        ),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: context.palette.line)),
        ),
        child: Row(
          children: [
            InkWell(
              onTap: () => changePage(false),
              borderRadius: BorderRadius.circular(10),
              child: const Brand(),
            ),
            const Spacer(),
            SizedBox(width: mobile ? 10 : 16),
            if (!mobile) ...[
              CircleAvatar(
                radius: 18,
                backgroundColor: context.palette.soft,
                child: Text(
                  app.data.name.characters.first.toUpperCase(),
                  style: const TextStyle(
                    color: primary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
            ],
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: tiny
                        ? 62
                        : mobile
                        ? 90
                        : 110,
                  ),
                  child: Text(
                    app.data.name,
                    key: const Key('profile-name'),
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      height: 1.3,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (!mobile) ...[
                  const SizedBox(height: 3),
                  Text(
                    'Personal account',
                    style: TextStyle(
                      fontSize: 10,
                      color: context.palette.muted,
                    ),
                  ),
                ],
              ],
            ),
            SizedBox(width: mobile ? 5 : 10),
            SizedBox(
              width: 36,
              height: 36,
              child: TextButton(
                key: const Key('edit-profile'),
                onPressed: profile,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(36, 36),
                  foregroundColor: context.palette.muted,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: DgIcon(
                  DgSymbol.edit,
                  size: 14,
                  color: context.palette.muted,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
  Widget topbar(bool mobile) {
    final c = context.palette, now = DateTime.now();
    final title = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'KEUANGAN PRIBADI',
          style: TextStyle(
            fontSize: 10,
            height: 1.3,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
            color: c.muted,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          history ? 'Histori Keuangan' : 'Dashboard',
          key: const Key('page-title'),
          style: heading(
            mobile ? 26 : 30,
          ).copyWith(height: 36 / 26, letterSpacing: -1),
        ),
        const SizedBox(height: 6),
        Text(
          history
              ? 'Lihat grafik dan semua transaksi pemasukan serta pengeluaranmu.'
              : 'Halo ${app.data.name}, pantau pemasukan, pengeluaran, dan jaga anggaranmu tetap terarah.',
          style: TextStyle(fontSize: 12, height: 4 / 3, color: c.muted),
        ),
      ],
    );
    final actions = Row(
      mainAxisSize: mobile ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Container(
          height: 41,
          padding: const EdgeInsets.symmetric(horizontal: 13),
          decoration: BoxDecoration(
            color: c.surface,
            border: Border.all(
              color: c.dark ? c.line : const Color(0xffe9ebf3),
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const DgIcon(DgSymbol.clock, size: 17, color: primary),
              const SizedBox(width: 8),
              Text(
                '${now.day} ${monthNames[now.month - 1]} ${now.year}',
                style: TextStyle(
                  fontSize: 12,
                  color: c.dark ? c.muted : const Color(0xff737990),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 13),
        OutlinedButton(
          key: const Key('lock-app'),
          onPressed: () => run(app.lock),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 12),
            foregroundColor: c.dark
                ? const Color(0xffc2c8db)
                : const Color(0xff74798d),
            backgroundColor: c.dark ? const Color(0xff232843) : Colors.white,
          ),
          child: const Text('Kunci'),
        ),
      ],
    );
    return mobile
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [title, const SizedBox(height: 20), actions],
          )
        : Row(
            children: [
              Expanded(child: title),
              const SizedBox(width: 20),
              actions,
            ],
          );
  }

  Widget stage() {
    final reduced = MediaQuery.disableAnimationsOf(context);
    final duration = reduced
        ? Duration.zero
        : const Duration(milliseconds: 340);
    final incomingKey = ValueKey(history ? 'history' : 'dashboard');
    return GestureDetector(
      key: const Key('page-stage'),
      behavior: HitTestBehavior.translucent,
      dragStartBehavior: DragStartBehavior.down,
      onHorizontalDragStart: (e) {
        startX = e.globalPosition.dx;
        dx = 0;
        watch
          ..reset()
          ..start();
      },
      onHorizontalDragUpdate: (e) {
        if (startX < 24 || startX > MediaQuery.sizeOf(context).width - 24)
          return;
        dx += e.delta.dx;
        setState(() => drag = (dx * .15).clamp(-38, 38));
      },
      onHorizontalDragEnd: (e) {
        watch.stop();
        final elapsed = watch.elapsedMilliseconds;
        final enough =
            dx.abs() >= 65 ||
            (dx.abs() >= 36 && dx.abs() / ((elapsed < 1) ? 1 : elapsed) > .5);
        if (enough && elapsed < 1200) {
          changePage(dx < 0);
        } else {
          setState(() => drag = 0);
        }
      },
      onHorizontalDragCancel: () => setState(() => drag = 0),
      child: Transform.translate(
        offset: Offset(drag, 0),
        child: AnimatedSize(
          duration: duration,
          curve: pageCurve,
          alignment: Alignment.topCenter,
          child: AnimatedSwitcher(
            duration: duration,
            switchInCurve: pageCurve,
            switchOutCurve: pageCurve.flipped,
            layoutBuilder: (current, previous) => Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                for (final old in previous)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: IgnorePointer(child: ExcludeSemantics(child: old)),
                  ),
                if (current != null) current,
              ],
            ),
            transitionBuilder: (child, animation) {
              final incoming = child.key == incomingKey;
              return FadeTransition(
                opacity: Tween<double>(begin: .2, end: 1).animate(animation),
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: Offset(
                      (incoming ? direction : -direction).toDouble(),
                      0,
                    ),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              );
            },
            child: history
                ? HistoryView(
                    key: incomingKey,
                    data: app.data,
                    year: year,
                    type: type,
                    onYear: (v) => setState(() => year = v),
                    onType: (v) => setState(() => type = v),
                    onDelete: delete,
                    onAdd: entry,
                  )
                : DashboardView(
                    key: incomingKey,
                    data: app.data,
                    hidden: app.hideBudget,
                    onBudget: () => entry('anggaran'),
                  ),
          ),
        ),
      ),
    );
  }

  Widget navTab(
    bool selected,
    DgSymbol icon,
    String label,
    VoidCallback onPressed,
    bool mobile,
    Key key,
  ) {
    final c = context.palette, color = selected ? primary : c.muted;
    final contents = [
      DgIcon(icon, size: mobile ? 21 : 22, color: color),
      SizedBox(width: mobile ? 0 : 9, height: mobile ? 4 : 0),
      Text(
        label,
        style: TextStyle(
          fontSize: mobile ? 10 : 12,
          height: 1.3,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    ];
    return Semantics(
      selected: selected,
      button: true,
      label: label,
      child: TextButton(
        key: key,
        onPressed: onPressed,
        style: TextButton.styleFrom(
          backgroundColor: selected ? c.soft : Colors.transparent,
          foregroundColor: color,
          padding: EdgeInsets.symmetric(
            horizontal: mobile ? 2 : 16,
            vertical: mobile ? 5 : 0,
          ),
          minimumSize: Size(0, mobile ? 49 : 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(mobile ? 14 : 15),
          ),
        ),
        child: mobile
            ? Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: contents,
              )
            : Row(mainAxisSize: MainAxisSize.min, children: contents),
      ),
    );
  }

  Widget dock(bool mobile) {
    final c = context.palette;
    final screenSize = MediaQuery.sizeOf(context);
    final landscape =
        screenSize.width > screenSize.height && screenSize.height <= 500;
    final dashboard = navTab(
      !history,
      DgSymbol.dashboard,
      'Dashboard',
      () => changePage(false),
      mobile,
      const Key('nav-dashboard'),
    );
    final historyTab = navTab(
      history,
      DgSymbol.history,
      mobile ? 'Histori' : 'Histori Pengeluaran',
      () => changePage(true),
      mobile,
      const Key('nav-history'),
    );
    final add = PressScale(
      child: SizedBox(
        width: mobile ? 46 : null,
        height: mobile ? 46 : 48,
        child: ElevatedButton(
          key: const Key('add-entry'),
          onPressed: entry,
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: mobile ? 0 : 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(mobile ? 16 : 15),
            ),
          ),
          child: Semantics(
            label: 'Tambah data',
            button: true,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const DgIcon(DgSymbol.add, size: 21, color: Colors.white),
                if (!mobile) ...[
                  const SizedBox(width: 9),
                  const Text('Tambah Data'),
                ],
              ],
            ),
          ),
        ),
      ),
    );
    Widget tool(DgSymbol icon, String label, Key key, VoidCallback action) =>
        Tooltip(
          message: label,
          child: PressScale(
            child: SizedBox(
              width: 44,
              height: mobile ? 46 : 44,
              child: TextButton(
                key: key,
                onPressed: action,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size(44, mobile ? 46 : 44),
                  foregroundColor: c.text,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Semantics(
                  label: label,
                  button: true,
                  child: DgIcon(icon, size: mobile ? 21 : 22, color: c.text),
                ),
              ),
            ),
          ),
        );
    final eye = tool(
      app.hideBudget ? DgSymbol.eyeOff : DgSymbol.eye,
      app.hideBudget ? 'Tampilkan anggaran' : 'Sembunyikan anggaran',
      const Key('toggle-hidden'),
      () => run(app.toggleHidden),
    );
    final theme = tool(
      app.dark ? DgSymbol.moon : DgSymbol.sun,
      app.dark ? 'Gunakan tema terang' : 'Gunakan tema gelap',
      const Key('toggle-theme'),
      () => run(app.toggleDark),
    );
    return SizedBox(
      width: mobile
          ? (MediaQuery.sizeOf(context).width - 24).clamp(0, 460)
          : null,
      child: GlassSurface(
        key: const Key('bottom-dock'),
        dock: true,
        radius: mobile ? 23 : 22,
        padding: EdgeInsets.all(landscape ? 5 : 8),
        child: mobile
            ? SizedBox(
                height: 49,
                child: Row(
                  children: [
                    Expanded(flex: 10, child: dashboard),
                    const SizedBox(width: 4),
                    Expanded(flex: 10, child: historyTab),
                    const SizedBox(width: 4),
                    Expanded(flex: 10, child: Center(child: add)),
                    const SizedBox(width: 4),
                    Expanded(flex: 8, child: Center(child: eye)),
                    const SizedBox(width: 4),
                    Expanded(flex: 8, child: Center(child: theme)),
                  ],
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  dashboard,
                  const SizedBox(width: 6),
                  historyTab,
                  const SizedBox(width: 10),
                  add,
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.only(left: 8),
                    decoration: BoxDecoration(
                      border: Border(left: BorderSide(color: c.line)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [eye, const SizedBox(width: 6), theme],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context),
        mobile = size.width <= 760,
        tiny = size.width < 360;
    return PopScope(
      canPop: !history,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && history) changePage(false);
      },
      child: Scaffold(
        body: SafeArea(
          child: AppBackdrop(
            child: Stack(
              children: [
                SingleChildScrollView(
                  key: const Key('main-scroll'),
                  controller: scroll,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      header(mobile, tiny),
                      Align(
                        alignment: Alignment.topCenter,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1168),
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(
                              tiny
                                  ? 12
                                  : mobile
                                  ? 16
                                  : 36,
                              mobile ? 24 : 32,
                              tiny
                                  ? 12
                                  : mobile
                                  ? 16
                                  : 36,
                              mobile ? 118 : 126,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                topbar(mobile),
                                SizedBox(height: mobile ? 22 : 30),
                                stage(),
                                const SizedBox(height: 28),
                                Text(
                                  'DompetGueh | By Terry  •  Catat dengan bijak, rencanakan dengan baik.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 10,
                                    height: 1.7,
                                    color: context.palette.dark
                                        ? context.palette.muted
                                        : const Color(0xffa5a9b8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: size.width > size.height && size.height <= 500
                      ? 8
                      : mobile
                      ? 12
                      : 18,
                  child: Center(child: dock(mobile)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
