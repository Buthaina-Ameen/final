import 'package:flutter/material.dart';
import 'package:by_hex/constants/app_colors.dart';
import 'package:by_hex/screens/final_hex_editor_screen.dart';
import 'package:by_hex/screens/file_operations_screen.dart';
import 'package:by_hex/screens/security_screens.dart';
import 'package:by_hex/screens/whatsapp_scan_settings_screen.dart';
import 'package:by_hex/screens/whatsapp_scan_history_screen.dart';
import 'package:by_hex/screens/whatsapp_scan_test_screen.dart';
import 'package:by_hex/services/enhanced_file_service.dart';
import 'package:by_hex/services/enhanced_hex_editor_service.dart';
import 'package:by_hex/services/security_service.dart';
import 'package:by_hex/services/whatsapp_service.dart';
import 'package:by_hex/widgets/file_modification_tracker.dart';
import 'package:provider/provider.dart';
import 'dart:io';

class MainAppScreen extends StatefulWidget {
  const MainAppScreen({super.key});

  @override
  State<MainAppScreen> createState() => _MainAppScreenState();
}

class _MainAppScreenState extends State<MainAppScreen> {
  int _currentIndex = 0;
  final List<Widget> _screens = [
    const FinalHexEditorScreen(),
    const FileOperationsScreen(),
    const SecuritySettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final fileService = Provider.of<EnhancedFileService>(context);
    final securityService = Provider.of<SecurityService>(context);
    final whatsappService = Provider.of<WhatsAppService>(context);
    
    return WillPopScope(
      onWillPop: () async {
        // التحقق من وجود تعديلات غير محفوظة قبل الخروج
        if (fileService.isModified) {
          return await fileService.checkUnsavedChanges(context);
        }
        return true;
      },
      child: Scaffold(
        body: FileModificationTracker(
          child: _screens[_currentIndex],
        ),
        floatingActionButton: _buildFloatingActionButton(context, fileService, securityService, whatsappService),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          backgroundColor: AppColors.appBarColor,
          selectedItemColor: AppColors.deepPurple,
          unselectedItemColor: Colors.black54,
          items: const [
            BottomNavigationBar.item(
              icon: Icon(Icons.code),
              label: 'محرر Hex',
            ),
            BottomNavigationBar.item(
              icon: Icon(Icons.folder),
              label: 'الملفات',
            ),
            BottomNavigationBar.item(
              icon: Icon(Icons.security),
              label: 'الأمان',
            ),
          ],
        ),
      ),
    );
  }
  
  Widget? _buildFloatingActionButton(
    BuildContext context, 
    EnhancedFileService fileService,
    SecurityService securityService,
    WhatsAppService whatsappService
  ) {
    // عرض زر سجل التعديلات في شاشة المحرر عندما يكون هناك ملف مفتوح
    if (_currentIndex == 0 && fileService.currentFile != null) {
      return FloatingActionButton(
        backgroundColor: AppColors.mediumPurple,
        foregroundColor: Colors.white,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ModificationHistoryScreen(),
            ),
          );
        },
        child: const Icon(Icons.history),
      );
    }
    
    // عرض زر الفحص الأمني في شاشة الملفات عندما يكون هناك ملف محدد
    else if (_currentIndex == 1 && fileService.currentFile != null) {
      return FloatingActionButton(
        backgroundColor: AppColors.mediumPurple,
        foregroundColor: Colors.white,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SecurityScanScreen(file: fileService.currentFile!),
            ),
          );
        },
        child: const Icon(Icons.security),
      );
    }
    
    // عرض زر إعدادات فحص واتساب في شاشة الأمان
    else if (_currentIndex == 2) {
      return FloatingActionButton(
        backgroundColor: AppColors.mediumPurple,
        foregroundColor: Colors.white,
        onPressed: () {
          _showWhatsAppMenu(context, whatsappService);
        },
        child: const Icon(Icons.whatsapp),
      );
    }
    
    return null;
  }
  
  void _showWhatsAppMenu(BuildContext context, WhatsAppService whatsappService) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.darkGray,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'خيارات فحص واتساب',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.settings, color: AppColors.lightPurple),
                title: const Text(
                  'إعدادات فحص واتساب',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const WhatsAppScanSettingsScreen(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.history, color: AppColors.lightPurple),
                title: const Text(
                  'سجل فحص ملفات واتساب',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const WhatsAppScanHistoryScreen(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: Icon(
                  whatsappService.autoScanEnabled ? Icons.toggle_on : Icons.toggle_off,
                  color: whatsappService.autoScanEnabled ? Colors.green : Colors.grey,
                ),
                title: Text(
                  whatsappService.autoScanEnabled ? 'إيقاف الفحص التلقائي' : 'تشغيل الفحص التلقائي',
                  style: const TextStyle(color: Colors.white),
                ),
                onTap: () {
                  whatsappService.autoScanEnabled = !whatsappService.autoScanEnabled;
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        whatsappService.autoScanEnabled
                            ? 'تم تفعيل الفحص التلقائي لملفات واتساب'
                            : 'تم إيقاف الفحص التلقائي لملفات واتساب',
                      ),
                      backgroundColor: AppColors.deepPurple,
                    ),
                  );
                },
              ),
              if (!whatsappService.isInitialized)
                ListTile(
                  leading: const Icon(Icons.play_arrow, color: Colors.green),
                  title: const Text(
                    'تهيئة خدمة فحص واتساب',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    await whatsappService.initialize();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('تم تهيئة خدمة فحص واتساب'),
                        backgroundColor: AppColors.deepPurple,
                      ),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}

class ModificationHistoryScreen extends StatelessWidget {
  const ModificationHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('سجل التعديلات'),
        backgroundColor: AppColors.darkGrayLight,
      ),
      body: Container(
        color: AppColors.backgroundColor,
        child: const Center(
          child: Text(
            'سجل التعديلات',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }
}
