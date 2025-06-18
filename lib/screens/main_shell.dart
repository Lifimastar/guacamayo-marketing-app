import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:guacamayo_marketing_app/screens/admin_dashboard_page.dart';
import 'package:guacamayo_marketing_app/screens/contact_us_page.dart';
import '../providers/auth_provider.dart';
import 'home_page.dart';
import 'services_catalog_page.dart';
import 'user_bookings_page.dart';
import 'admin_bookings_page.dart';
import 'admin_services_page.dart';
import 'admin_users_page.dart';
import 'profile_page.dart';
import '../style/app_colors.dart';

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  MainShellState createState() => MainShellState();
}

class MainShellState extends ConsumerState<MainShell> {
  int _selectedIndex = 0;
  late PageController _pageController;
  List<Widget> _clientScreens = [];
  List<BottomNavigationBarItem> _clientNavItems = [];
  List<Widget> _adminScreens = [];
  List<BottomNavigationBarItem> _adminNavItems = [];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);
    _setupNavigation();

    _pageController.addListener(() {
      if (_pageController.page?.round() != _selectedIndex) {
        setState(() {
          _selectedIndex = _pageController.page!.round();
        });
        _refreshCurrentScreen();
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _setupNavigation() {
    // Pantalla e Items para Clientes
    _clientScreens = [
      HomePage(onNavigateToServices: () => _onItemTapped(1)),
      const ServicesCatalogPage(),
      const UserBookingsPage(),
      ProfilePage(),
      ContactUsPage(),
    ];
    _clientNavItems = [
      const BottomNavigationBarItem(
        icon: Icon(Icons.home_outlined),
        activeIcon: Icon(Icons.home),
        label: 'Inicio',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.store_outlined),
        activeIcon: Icon(Icons.store),
        label: 'Servicios',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.list_alt_outlined),
        activeIcon: Icon(Icons.list_alt),
        label: 'Mis Reservas',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.person_outline),
        activeIcon: Icon(Icons.person),
        label: 'Perfil',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.contact_support_outlined),
        activeIcon: Icon(Icons.contact_support),
        label: 'Contacto',
      ),
    ];

    // Pantallas e Items para Administradores
    _adminScreens = [
      const AdminDashboardPage(),
      const AdminBookingsPage(),
      const AdminServicesPage(),
      const AdminUsersPage(),
      ProfilePage(),
      ContactUsPage(),
    ];
    _adminNavItems = [
      const BottomNavigationBarItem(
        icon: Icon(Icons.dashboard_outlined),
        activeIcon: Icon(Icons.dashboard),
        label: 'Dashboard',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.list_alt_outlined),
        activeIcon: Icon(Icons.list_alt),
        label: 'Reservas',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.store_mall_directory_outlined),
        activeIcon: Icon(Icons.store_mall_directory),
        label: 'Servicios',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.people_alt_outlined),
        activeIcon: Icon(Icons.people_alt),
        label: 'Usuarios',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.person_outline),
        activeIcon: Icon(Icons.person),
        label: 'Perfil',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.contact_support_outlined),
        activeIcon: Icon(Icons.contact_support),
        label: 'Contacto',
      ),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _pageController.jumpToPage(index);
  }

  void _refreshCurrentScreen() {
    final currentScreens =
        ref.read(authProvider).isAdmin ? _adminScreens : _clientScreens;
    final currentScreen = currentScreens[_selectedIndex];
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isAdmin = authState.isAdmin;

    final currentScreens = isAdmin ? _adminScreens : _clientScreens;
    final currentNavItems = isAdmin ? _adminNavItems : _clientNavItems;

    if (_selectedIndex >= currentScreens.length) {
      _selectedIndex = 0;
    }

    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        children: currentScreens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: currentNavItems,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.shifting,
        backgroundColor: Theme.of(context).colorScheme.surface,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: AppColors.mediumGrey,
        showUnselectedLabels: true,
        selectedFontSize: 12,
        unselectedFontSize: 12,
      ),
    );
  }
}
