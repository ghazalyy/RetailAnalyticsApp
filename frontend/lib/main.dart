import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/product_screen.dart';
import 'services/api_service.dart';

void main() {
  runApp(const MyApp());
}

final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, mode, __) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Retail App',
          themeMode: mode,
          // --- Konfigurasi Tema Terang ---
          theme: ThemeData(
            brightness: Brightness.light,
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.blue, 
              brightness: Brightness.light
            ),
            textTheme: GoogleFonts.poppinsTextTheme(),
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.white,
              elevation: 0,
              iconTheme: IconThemeData(color: Colors.black),
              titleTextStyle: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          // --- Konfigurasi Tema Gelap ---
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.blue, 
              brightness: Brightness.dark
            ),
            textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
            scaffoldBackgroundColor: const Color(0xFF121212),
          ),
          home: const CheckAuth(),
        );
      },
    );
  }
}

class CheckAuth extends StatefulWidget {
  const CheckAuth({super.key});
  @override
  State<CheckAuth> createState() => _CheckAuthState();
}

class _CheckAuthState extends State<CheckAuth> {
  @override
  void initState() {
    super.initState();
    _checkLogin();
  }

  void _checkLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('is_logged_in') ?? false;

    if (mounted) {
      if (isLoggedIn) {
        Navigator.pushReplacement(
          context, 
          MaterialPageRoute(builder: (_) => const MainLayout())
        );
      } else {
        Navigator.pushReplacement(
          context, 
          MaterialPageRoute(builder: (_) => const LoginScreen())
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;
  String _userRole = "staff"; 
  bool _isLoadingRole = true; 

  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  void _loadUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userRole = prefs.getString('user_role') ?? "staff";
      _isLoadingRole = false;
      if (_userRole != 'admin') {
        _currentIndex = 0;
      }
    });
  }

  // Fungsi Logout
  void _logout() async {
    await ApiService.logout(); 
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context, 
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false 
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingRole) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // --- LOGIKA MENU BERDASARKAN ROLE ---
    List<Widget> screens = [];
    List<NavigationDestination> navDestinations = [];

    if (_userRole == "admin") {
      screens = [
        const DashboardScreen(),
        const ProductScreen(),
      ];
      navDestinations = const [
        NavigationDestination(
          icon: Icon(Icons.dashboard_outlined), 
          selectedIcon: Icon(Icons.dashboard), 
          label: 'Dashboard'
        ),
        NavigationDestination(
          icon: Icon(Icons.inventory_2_outlined), 
          selectedIcon: Icon(Icons.inventory_2), 
          label: 'Produk'
        ),
      ];
    } else {
      screens = [
        const ProductScreen(),
      ];
      navDestinations = const [
        NavigationDestination(
          icon: Icon(Icons.inventory_2_outlined), 
          selectedIcon: Icon(Icons.inventory_2), 
          label: 'Kasir / Produk'
        ),
      ];
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _userRole == 'admin' ? "Admin Panel" : "Staff Area",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            tooltip: "Logout",
            onPressed: _logout,
          ),
          const SizedBox(width: 8),
        ],
      ),
      
      body: screens[_currentIndex],
      
      bottomNavigationBar: navDestinations.length > 1 
          ? NavigationBar(
              selectedIndex: _currentIndex,
              onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
              destinations: navDestinations,
            )
          : null, 
    );
  }
}