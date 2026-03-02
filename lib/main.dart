import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import 'core/utils/constants.dart';
import 'infrastructure/datasources/remote_datasource.dart';
import 'infrastructure/repositories/restaurant_repository_impl.dart';
import 'application/restaurant_provider.dart';
import 'presentation/screens/tables_screen.dart';
import 'presentation/screens/pending_orders_screen.dart';
import 'presentation/screens/completed_orders_screen.dart';
import 'presentation/screens/stats_screen.dart';
import 'presentation/screens/menu_manager_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Update this to your local machine IP if testing on a real device
  // Using 192.168.1.24 so a physical Android phone on the same Wi-Fi can connect
  final String baseUrl = 'http://192.168.1.24:5000';
  
  // Infrastructure Layer
  final remoteDataSource = RemoteDataSource(baseUrl: baseUrl);
  final repository = RestaurantRepositoryImpl(remoteDataSource);

  runApp(
    ChangeNotifierProvider(
      create: (context) => RestaurantProvider(repository),
      child: const RestauranteApp(),
    ),
  );
}

class RestauranteApp extends StatelessWidget {
  const RestauranteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Restaurante App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: scaffoldBg,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFE53935), // Corvina Red
          primary: const Color(0xFFE53935),
          secondary: const Color(0xFFFFD600), // Sunshine Yellow
          surface: Colors.white,
        ),
        textTheme: GoogleFonts.plusJakartaSansTextTheme(),
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const TablesScreen(),
    const PendingOrdersScreen(),
    const CompletedOrdersScreen(),
    const StatsScreen(),
    const MenuManagerScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Image.asset(
          'assets/images/logo.png',
          height: 40,
          fit: BoxFit.contain,
        ),
        backgroundColor: Colors.white,
        foregroundColor: appOrange,
        elevation: 1,
        centerTitle: true,
        actions: [
          Consumer<RestaurantProvider>(
            builder: (context, provider, child) {
              return Container(
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: provider.isLocalMode ? Colors.blue.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: provider.isLocalMode ? Colors.blue : Colors.green,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      provider.isLocalMode ? Icons.storage : Icons.cloud_done,
                      size: 14,
                      color: provider.isLocalMode ? Colors.blue : Colors.green,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      provider.isLocalMode ? 'Local' : 'Servidor',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: provider.isLocalMode ? Colors.blue : Colors.green,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: const AssetImage('assets/images/logo.png'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.white.withOpacity(0.9),
              BlendMode.lighten,
            ),
          ),
        ),
        child: IndexedStack(
          index: _currentIndex,
          children: _pages,
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: appOrange,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined), label: 'Mesas'),
          BottomNavigationBarItem(
              icon: Icon(Icons.assignment_outlined), label: 'Pendientes'),
          BottomNavigationBarItem(
              icon: Icon(Icons.check_circle_outline), label: 'Completados'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Ventas'),
          BottomNavigationBarItem(
              icon: Icon(Icons.restaurant_menu), label: 'Menú'),
        ],
      ),
    );
  }
}
