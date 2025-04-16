import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../utils/auth_service.dart';
import '../../utils/database.dart';
import '../../models/poop_model.dart';
import '../../widgets/poop_card.dart';
import '../../theme/app_theme.dart';
import '../poops/add_poop_page.dart';
import '../rankings/rankings_page.dart';

class HomePage extends StatefulWidget {
  static const String routeName = '/home';

  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  late User user;

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    user = authService.currentUser!;


    if (user == null) {
      // This should not happen, but just in case
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shpalman app'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _showLogoutDialog(context),
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
              backgroundColor: AppTheme.primaryColor,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddPoopPage(),
                  ),
                );
              },
              child: const Icon(Icons.add),
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'Today\'s shits',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.leaderboard),
            label: 'Rankings',
          ),
        ],
        selectedItemColor: AppTheme.primaryColor,
      ),
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildMyPoops();
      case 1:
        return RankingsPage();
      default:
        return _buildMyPoops();
    }
  }

  Widget _buildMyPoops() {
    final databaseService = Provider.of<DatabaseService>(context);

    return StreamBuilder<List<PoopModel>>(
      stream: databaseService.getPoops(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error: ${snapshot.error}',
              style: TextStyle(color: AppTheme.errorColor),
            ),
          );
        }

        final poops = snapshot.data ?? [];

        if (poops.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.assignment_outlined,
                  size: 72,
                  color: AppTheme.textSecondaryColor.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'No poops yet',
                  style: TextStyle(
                    fontSize: 18,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap the + button to add your first poop',
                  style: TextStyle(
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
              ],
            ),
          );
        }

        return Center(
          child: SizedBox(
            width: 700,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: poops.length,
              itemBuilder: (context, index) {
                return PoopCard(poop: poops[index], user: user);
              },
            ),
          ),
        );
      },
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Sign Out'),
          content: const Text('Are you sure you want to sign out?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Provider.of<AuthService>(context, listen: false).signOut();
              },
              child: Text(
                'Sign Out',
                style: TextStyle(color: AppTheme.errorColor),
              ),
            ),
          ],
        );
      },
    );
  }
}
