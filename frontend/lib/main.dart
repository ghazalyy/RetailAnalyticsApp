import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/product_screen.dart';
import 'services/api_service.dart';
import 'screens/splash_screen.dart';

// Variabel Global untuk Tema (Agar bisa diakses dari mana saja)
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

void main() {
  runApp(const MyApp());
}

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
          
          // --- TEMA TERANG (Light Mode) ---
          theme: ThemeData(
            brightness: Brightness.light,
            useMaterial3: true,
            scaffoldBackgroundColor: const Color(0xFFF7F8FA), // Warna abu-abu muda bersih
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.blueAccent,
              brightness: Brightness.light,
              surface: Colors.white, // Warna kartu/permukaan
            ),
            textTheme: GoogleFonts.poppinsTextTheme(),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFFF7F8FA), // Samakan dengan background
              elevation: 0,
              iconTheme: IconThemeData(color: Colors.black87),
              titleTextStyle: TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            // Style Navigasi Bawah Terang
            bottomNavigationBarTheme: const BottomNavigationBarThemeData(
              backgroundColor: Colors.white,
              selectedItemColor: Colors.blueAccent,
              unselectedItemColor: Colors.grey,
              elevation: 10,
            ),
          ),

          // --- TEMA GELAP (Dark Mode) ---
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            useMaterial3: true,
            scaffoldBackgroundColor: const Color(0xFF121212), // Hitam pekat modern
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.blueAccent,
              brightness: Brightness.dark,
              surface: const Color(0xFF1E1E1E), // Warna kartu gelap
            ),
            textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF121212),
              elevation: 0,
              iconTheme: IconThemeData(color: Colors.white),
              titleTextStyle: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            // Style Navigasi Bawah Gelap
            bottomNavigationBarTheme: const BottomNavigationBarThemeData(
              backgroundColor: Color(0xFF1E1E1E),
              selectedItemColor: Colors.blueAccent,
              unselectedItemColor: Colors.grey,
              elevation: 10,
            ),
          ),
          
          home: const SplashScreen(),
        );
      },
    );
  }
}

// --- LOGIKA CEK LOGIN ---
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
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainLayout()));
      } else {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

// --- LAYOUT UTAMA (NAVIGASI) ---
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
      // Jika bukan admin, pastikan index kembali ke 0 (karena staff cuma punya 1 menu)
      if (_userRole != 'admin') {
        _currentIndex = 0;
      }
    });
  }

  void _logout() async {
    // Tampilkan dialog konfirmasi biar keren
    bool confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Konfirmasi Logout", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text("Apakah anda yakin ingin keluar aplikasi?", style: GoogleFonts.poppins()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Batal")),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true), 
            child: const Text("Logout", style: TextStyle(color: Colors.red))
          ),
        ],
      ),
    ) ?? false;

    if (confirm) {
      await ApiService.logout(); 
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context, 
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false 
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingRole) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // --- LIST MENU ---
    List<Widget> screens = [];
    List<BottomNavigationBarItem> navItems = [];

    if (_userRole == "admin") {
      screens = [
        const DashboardScreen(),
        const ProductScreen(),
      ];
      navItems = const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard_outlined), 
          activeIcon: Icon(Icons.dashboard),
          label: 'Dashboard'
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.inventory_2_outlined), 
          activeIcon: Icon(Icons.inventory_2),
          label: 'Produk'
        ),
      ];
    } else {
      // Staff hanya melihat Produk/Kasir
      screens = [
        const ProductScreen(),
      ];
      navItems = const [
        BottomNavigationBarItem(
          icon: Icon(Icons.point_of_sale), 
          activeIcon: Icon(Icons.point_of_sale),
          label: 'Kasir & Produk'
        ),
      ];
    }

    return Scaffold(
      // AppBar dibuat transparan/menyatu dengan background agar Header Dashboard lebih menonjol
      appBar: AppBar(
        title: Text(
          _userRole == 'admin' ? "" : "Staff Area", // Kosongkan judul untuk admin (karena ada di Dashboard)
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.red),
            tooltip: "Logout",
            onPressed: _logout,
          ),
          const SizedBox(width: 10),
        ],
      ),
      
      body: screens[_currentIndex],
      
      // Menggunakan BottomNavigationBar (Klasik) agar tidak ada background "kapsul"
      // Hanya ditampilkan jika menu lebih dari 1
      bottomNavigationBar: navItems.length > 1 
          ? BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (idx) => setState(() => _currentIndex = idx),
              items: navItems,
              type: BottomNavigationBarType.fixed,
              showSelectedLabels: true,
              showUnselectedLabels: true,
              selectedLabelStyle: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold),
              unselectedLabelStyle: GoogleFonts.poppins(fontSize: 12),
            )
          : null, 
    );
  }
}