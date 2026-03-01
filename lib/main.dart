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
  // 10.0.2.2 is the special alias to your host loopback interface in the Android emulator
  final String baseUrl = identical(0, 0.0) // Web check
      ? 'http://localhost:5000'
      : (ThemeData().platform == TargetPlatform.android
          ? 'http://10.0.2.2:5000'
          : 'http://localhost:5000');

  
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
          seedColor: appOrange,
          primary: appOrange,
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
        title: const Text('Kitchen Commander',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: appOrange,
        elevation: 1,
        centerTitle: true,
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
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
