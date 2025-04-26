import 'package:flutter/material.dart';
import 'package:by_hex/constants/app_colors.dart';
import 'package:by_hex/services/auth_service.dart';
import 'package:provider/provider.dart';
import 'package:by_hex/screens/login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text('By Hex'),
        backgroundColor: AppColors.darkGrayLight,
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // سيتم تنفيذ وظيفة البحث لاحقًا
            },
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: _buildBody(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        backgroundColor: AppColors.darkGrayLight,
        selectedItemColor: AppColors.mediumPurple,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBar.item(
            icon: Icon(Icons.home),
            label: 'الرئيسية',
          ),
          BottomNavigationBar.item(
            icon: Icon(Icons.history),
            label: 'السجل',
          ),
          BottomNavigationBar.item(
            icon: Icon(Icons.settings),
            label: 'الإعدادات',
          ),
        ],
      ),
    );
  }
  
  Widget _buildDrawer() {
    final authService = Provider.of<AuthService>(context);
    
    return Drawer(
      child: Container(
        color: AppColors.darkGrayLight,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                color: AppColors.darkGray,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'By Hex',
                    style: TextStyle(
                      color: AppColors.lightPurple,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    authService.currentUser?.email ?? 'مستخدم',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            _buildDrawerItem(
              icon: Icons.folder_open,
              title: 'فتح ملف',
              onTap: () {
                Navigator.pop(context);
                // سيتم تنفيذ وظيفة فتح ملف لاحقًا
              },
            ),
            _buildDrawerItem(
              icon: Icons.create_new_folder,
              title: 'إنشاء ملف جديد',
              onTap: () {
                Navigator.pop(context);
                // سيتم تنفيذ وظيفة إنشاء ملف جديد لاحقًا
              },
            ),
            _buildDrawerItem(
              icon: Icons.save,
              title: 'حفظ الملف',
              onTap: () {
                Navigator.pop(context);
                // سيتم تنفيذ وظيفة حفظ الملف لاحقًا
              },
            ),
            const Divider(color: Colors.grey),
            _buildDrawerItem(
              icon: Icons.compare,
              title: 'مقارنة ملفين',
              onTap: () {
                Navigator.pop(context);
                // سيتم تنفيذ وظيفة مقارنة ملفين لاحقًا
              },
            ),
            const Divider(color: Colors.grey),
            _buildDrawerItem(
              icon: Icons.logout,
              title: 'تسجيل الخروج',
              onTap: () async {
                await authService.signOut();
                if (mounted) {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.lightPurple),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white),
      ),
      onTap: onTap,
    );
  }
  
  Widget _buildBody() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.insert_drive_file,
            size: 100,
            color: AppColors.lightPurple,
          ),
          const SizedBox(height: 20),
          const Text(
            'لم يتم فتح أي ملف',
            style: TextStyle(
              fontSize: 20,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              // سيتم تنفيذ وظيفة فتح ملف لاحقًا
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.mediumPurple,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
            ),
            child: const Text('فتح ملف'),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () {
              // سيتم تنفيذ وظيفة إنشاء ملف جديد لاحقًا
            },
            child: const Text(
              'إنشاء ملف جديد',
              style: TextStyle(color: AppColors.lightPurple),
            ),
          ),
        ],
      ),
    );
  }
}
