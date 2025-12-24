import 'dart:io'; // ← Tambahan untuk bypass SSL
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:window_manager/window_manager.dart';

import 'pages/login_page.dart';
import 'pages/register_page.dart';
import 'pages/dashboard_page.dart';
import 'pages/user_management_page.dart';
import 'pages/presensi_page.dart';
import 'pages/history_page.dart';
import 'pages/admin_presensi_page.dart';
import 'pages/admin_user_list_page.dart';
import 'pages/rekap_page.dart';
import 'pages/rekap_hari_ini_page.dart';
import 'models/user_model.dart';
import 'api/api_service.dart';

// === TAMBAHAN: Bypass self-signed certificate (HANYA UNTUK TESTING/DEVELOPMENT) ===
class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}
// ==============================================================================

// Class listener yang benar
class _MyWindowListener extends WindowListener {
  @override
  void onWindowMaximize() async {
    await windowManager.setFullScreen(true);
  }

  @override
  void onWindowUnmaximize() async {
    await windowManager.setFullScreen(false);
    await windowManager.setSize(const Size(1920, 1080));
    await windowManager.center();
  }

  @override
  void onWindowEnterFullScreen() async {
    // Opsional, bisa dibiarkan kosong
  }

  @override
  void onWindowLeaveFullScreen() async {
    await windowManager.setSize(const Size(1920, 1080));
    await windowManager.center();
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // === AKTIFKAN BYPASS SSL (self-signed certificate) ===
  HttpOverrides.global = MyHttpOverrides();
  // ====================================================

  if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
    await windowManager.ensureInitialized();

    WindowOptions windowOptions = const WindowOptions(
      size: Size(1920, 1080),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      title: 'Skaduta Presensi',
      titleBarStyle: TitleBarStyle.normal,
      fullScreen: false,
    );

    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.setResizable(true);
      await windowManager.setMaximizable(true);
      await windowManager.setMinimizable(true);
      await windowManager.setMinimumSize(const Size(1920, 1080));

      // Tambahkan listener dengan class yang extends WindowListener
      windowManager.addListener(_MyWindowListener());

      await windowManager.focus();
      await windowManager.show();
    });
  }

  runApp(const SkadutaApp());
}

class SkadutaApp extends StatefulWidget {
  const SkadutaApp({super.key});

  @override
  State<SkadutaApp> createState() => _SkadutaAppState();
}

class _SkadutaAppState extends State<SkadutaApp> {
  Widget _initialPage = const Scaffold(
    body: Center(child: CircularProgressIndicator()),
  );

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final userInfo = await ApiService.getCurrentUser();
    if (userInfo != null) {
      final user = UserModel(
        id: userInfo['id']!,
        username: '',
        namaLengkap: userInfo['nama_lengkap']!,
        nipNisn: '',
        role: userInfo['role']!,
      );
      if (mounted) {
        setState(() {
          _initialPage = DashboardPage(user: user);
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _initialPage = const LoginPage();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Skaduta Presensi',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('id', 'ID'), Locale('en', 'US')],
      locale: const Locale('id', 'ID'),
      theme: ThemeData(
        colorSchemeSeed: Colors.blueGrey,
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.grey.shade50,
        textTheme: const TextTheme(bodyLarge: TextStyle(fontSize: 18)),
        cardTheme: const CardThemeData(elevation: 6),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          backgroundColor: Colors.blueGrey,
          foregroundColor: Colors.white,
        ),
      ),
      home: _initialPage,
      routes: {
        '/login': (_) => const LoginPage(),
        '/register': (_) => const RegisterPage(),
        '/admin-presensi': (_) => const AdminPresensiPage(),
        '/rekap-hari-ini': (_) => const RekapHariIniPage(),
        '/rekap': (_) => const RekapPage(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/dashboard') {
          final user = settings.arguments as UserModel;
          return MaterialPageRoute(builder: (_) => DashboardPage(user: user));
        }
        if (settings.name == '/user-management') {
          return MaterialPageRoute(builder: (_) => const UserManagementPage());
        }
        if (settings.name == '/presensi') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (_) =>
                PresensiPage(user: args['user'], initialJenis: args['jenis']),
          );
        }
        if (settings.name == '/history') {
          final user = settings.arguments as UserModel;
          return MaterialPageRoute(builder: (_) => HistoryPage(user: user));
        }
        if (settings.name == '/admin-user-list') {
          return MaterialPageRoute(builder: (_) => const AdminUserListPage());
        }
        return null;
      },
    );
  }
}
