import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/controller.dart';
import 'ui/auth.dart';
import 'ui/home.dart';
import 'ui/theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final controller = AppController(AndroidLocalApi());
  runApp(DompetGuehApp(controller: controller));
  controller.initialize();
}

class DompetGuehApp extends StatelessWidget {
  final AppController controller;
  const DompetGuehApp({super.key, required this.controller});
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (context, _) {
      final c = Palette(controller.dark);
      return MaterialApp(
        title: 'DompetGueh',
        debugShowCheckedModeBanner: false,
        theme: appTheme(false),
        darkTheme: appTheme(true),
        themeMode: controller.dark ? ThemeMode.dark : ThemeMode.light,
        builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle(
            statusBarColor: c.bg,
            systemNavigationBarColor: c.bg,
            statusBarIconBrightness: controller.dark
                ? Brightness.light
                : Brightness.dark,
            systemNavigationBarIconBrightness: controller.dark
                ? Brightness.light
                : Brightness.dark,
          ),
          child: child!,
        ),
        home: controller.loading
            ? const Scaffold(body: Center(child: CircularProgressIndicator()))
            : controller.startupError != null
            ? Scaffold(
                body: SafeArea(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(30),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            controller.startupError!,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 18),
                          ElevatedButton(
                            onPressed: controller.initialize,
                            child: const Text('Coba Lagi'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              )
            : controller.unlocked
            ? HomeScreen(controller: controller)
            : AuthScreen(controller: controller),
      );
    },
  );
}
