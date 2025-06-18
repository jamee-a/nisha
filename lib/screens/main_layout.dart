import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'dashboard_screen.dart';
import 'settings_screen.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({Key? key}) : super(key: key);

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, size: 35, color: Color(0xFF004D40)),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'User Name',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                        ),
                  ),
                  Text(
                    'user@email.com',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white70,
                        ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: Text(AppLocalizations.of(context)!.dashboard),
              onTap: () {
                _onItemTapped(0);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: Text(AppLocalizations.of(context)!.settings),
              onTap: () {
                _onItemTapped(1);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: Text(AppLocalizations.of(context)!.profile),
              onTap: () {
                _onItemTapped(2);
                Navigator.pop(context);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: Text(AppLocalizations.of(context)!.logout),
              onTap: () {
                // Handle logout
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
        ),
        title: Text(_getTitle(context)),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              // Handle notifications
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: const [
          DashboardScreen(),
          SettingsScreen(),
          Center(child: Text('Profile Content')),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.dashboard),
            label: AppLocalizations.of(context)!.dashboard,
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings),
            label: AppLocalizations.of(context)!.settings,
          ),
          NavigationDestination(
            icon: const Icon(Icons.person),
            label: AppLocalizations.of(context)!.profile,
          ),
        ],
      ),
    );
  }

  String _getTitle(BuildContext context) {
    switch (_selectedIndex) {
      case 0:
        return AppLocalizations.of(context)!.dashboard;
      case 1:
        return AppLocalizations.of(context)!.settings;
      case 2:
        return AppLocalizations.of(context)!.profile;
      default:
        return AppLocalizations.of(context)!.appTitle;
    }
  }
} 