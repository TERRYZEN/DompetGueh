import 'dart:ui';
import 'package:flutter/material.dart';
import '../core/controller.dart';
import '../core/models.dart';
import 'common.dart';
import 'dashboard.dart';
import 'forms.dart';
import 'history.dart';
import 'theme.dart';

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
  AppController get app => widget.controller;
  @override
  void dispose() {
    scroll.dispose();
    super.dispose();
  }

  Future<void> entry([String type = 'pengeluaran']) async {
    final message = await showEntryForm(context, app, type: type);
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
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ctx.palette.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('Hapus transaksi?', style: heading(19)),
        content: Text(
          'Hapus ${e.income ? 'pemasukan' : 'pengeluaran'} "${e.name}"?${e.addedToBudget ? ' Anggaran juga akan berkurang.' : ''}',
          style: TextStyle(fontSize: 13, height: 1.6, color: ctx.palette.muted),
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            key: const Key('confirm-delete'),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
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
    setState(() => history = next);
    if (scroll.hasClients) scroll.jumpTo(0);
  }

  Widget navigation() => Wrap(
    spacing: 6,
    runSpacing: 4,
    children: [
      for (final item in [
        (false, 'Dashboard', Icons.grid_view_rounded),
        (true, 'Histori Keuangan', Icons.north_east_rounded),
      ])
        TextButton.icon(
          key: Key(item.$1 ? 'nav-history' : 'nav-dashboard'),
          onPressed: () => changePage(item.$1),
          icon: Icon(item.$3, size: 15),
          label: Text(item.$2),
          style: TextButton.styleFrom(
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            backgroundColor: history == item.$1
                ? context.palette.soft
                : Colors.transparent,
            foregroundColor: history == item.$1
                ? primary
                : context.palette.muted,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            minimumSize: const Size(0, 35),
            textStyle: const TextStyle(
              fontFamily: 'DMSans',
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
    ],
  );

  Widget profileRow() => Row(
    children: [
      CircleAvatar(
        radius: 17.5,
        backgroundColor: context.palette.soft,
        child: Text(
          app.data.name.isEmpty
              ? 'U'
              : app.data.name.characters.first.toUpperCase(),
          style: const TextStyle(
            color: primary,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              app.data.name,
              key: const Key('profile-name'),
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 3),
            Text(
              'Personal account',
              style: TextStyle(fontSize: 10, color: context.palette.muted),
            ),
          ],
        ),
      ),
      const SizedBox(width: 8),
      TextButton.icon(
        key: const Key('edit-profile'),
        onPressed: profile,
        icon: const Icon(Icons.edit_outlined, size: 13),
        label: const Text('Ubah nama'),
        style: TextButton.styleFrom(
          backgroundColor: context.palette.soft,
          minimumSize: const Size(0, 40),
          padding: const EdgeInsets.symmetric(horizontal: 12),
        ),
      ),
    ],
  );

  Widget mobileHeader() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
    decoration: BoxDecoration(
      color: context.palette.surface,
      border: Border(bottom: BorderSide(color: context.palette.line)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Brand(),
        const SizedBox(height: 12),
        navigation(),
        const SizedBox(height: 10),
        Divider(color: context.palette.line, height: 1),
        const SizedBox(height: 10),
        profileRow(),
      ],
    ),
  );

  Widget sidebar() => Container(
    width: 248,
    padding: const EdgeInsets.fromLTRB(18, 30, 18, 20),
    decoration: BoxDecoration(
      color: context.palette.surface,
      border: Border(right: BorderSide(color: context.palette.line)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Brand(),
        const SizedBox(height: 48),
        const Eyebrow('MENU UTAMA'),
        const SizedBox(height: 12),
        navigation(),
        const Spacer(),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.palette.soft,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.auto_awesome, color: primary),
              const SizedBox(height: 14),
              Text('Kelola uang lu', style: heading(13)),
              const SizedBox(height: 8),
              Text(
                'Catat pengeluaran kecil hari ini untuk rencana yang lebih besar esok hari.',
                style: TextStyle(
                  fontSize: 11,
                  height: 1.7,
                  color: context.palette.muted,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        profileRow(),
      ],
    ),
  );

  Widget mainContent() {
    final c = context.palette;
    final now = DateTime.now();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 25, 16, 110),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Eyebrow('KEUANGAN PRIBADI'),
          const SizedBox(height: 7),
          Text(history ? 'Histori Keuangan' : 'Dashboard', style: heading(26)),
          const SizedBox(height: 6),
          Text(
            history
                ? 'Lihat grafik dan semua transaksi pemasukan serta pengeluaranmu.'
                : 'Halo ${app.data.name}, pantau pemasukan, pengeluaran, dan jaga anggaranmu tetap terarah.',
            style: TextStyle(fontSize: 12, height: 1.45, color: c.muted),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 13,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                height: 41,
                padding: const EdgeInsets.symmetric(horizontal: 13),
                decoration: BoxDecoration(
                  color: c.surface,
                  border: Border.all(color: c.line),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.schedule, color: primary, size: 17),
                    const SizedBox(width: 8),
                    Text(
                      '${now.day} ${monthNames[now.month - 1]} ${now.year}',
                      style: TextStyle(fontSize: 12, color: c.muted),
                    ),
                  ],
                ),
              ),
              OutlinedButton(
                key: const Key('lock-app'),
                onPressed: () => run(app.lock),
                child: const Text('Kunci'),
              ),
            ],
          ),
          const SizedBox(height: 22),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: history
                ? HistoryView(
                    key: const ValueKey('history'),
                    data: app.data,
                    year: year,
                    type: type,
                    onYear: (v) => setState(() => year = v),
                    onType: (v) => setState(() => type = v),
                    onDelete: delete,
                    onAdd: entry,
                  )
                : DashboardView(
                    key: const ValueKey('dashboard'),
                    data: app.data,
                    hidden: app.hideBudget,
                    onBudget: () => entry('anggaran'),
                  ),
          ),
          const SizedBox(height: 38),
          Text(
            'DompetGueh | By Terry  •  Catat dengan bijak, rencanakan dengan baik.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 10, height: 1.7, color: c.muted),
          ),
        ],
      ),
    );
  }

  Widget floatingActions() => ClipRRect(
    borderRadius: BorderRadius.circular(19),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
      child: Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: context.palette.surface.withValues(alpha: .93),
          borderRadius: BorderRadius.circular(19),
          border: Border.all(color: context.palette.line),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SmallIconButton(
              key: const Key('toggle-hidden'),
              icon: app.hideBudget
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              label: app.hideBudget
                  ? 'Tampilkan anggaran'
                  : 'Sembunyikan anggaran',
              onPressed: () => run(app.toggleHidden),
            ),
            const SizedBox(width: 10),
            ElevatedButton.icon(
              key: const Key('add-entry'),
              onPressed: entry,
              icon: const Icon(Icons.add, size: 17),
              label: const Text('Tambah Data'),
            ),
            const SizedBox(width: 10),
            SmallIconButton(
              key: const Key('toggle-theme'),
              icon: app.dark
                  ? Icons.dark_mode_outlined
                  : Icons.light_mode_outlined,
              label: app.dark ? 'Gunakan tema terang' : 'Gunakan tema gelap',
              onPressed: () => run(app.toggleDark),
            ),
          ],
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !history,
    onPopInvokedWithResult: (didPop, result) {
      if (!didPop && history) changePage(false);
    },
    child: Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, bounds) {
            final wide = bounds.maxWidth > 760;
            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (wide) sidebar(),
                Expanded(
                  child: Stack(
                    children: [
                      SingleChildScrollView(
                        key: const Key('main-scroll'),
                        controller: scroll,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [if (!wide) mobileHeader(), mainContent()],
                        ),
                      ),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 14,
                        child: Center(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(19),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: .12),
                                  blurRadius: 38,
                                  offset: const Offset(0, 14),
                                ),
                              ],
                            ),
                            child: floatingActions(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    ),
  );
}
