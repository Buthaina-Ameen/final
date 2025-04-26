import 'package:flutter/material.dart';
import 'package:by_hex/constants/app_colors.dart';
import 'package:by_hex/screens/login_screen.dart';
import 'package:by_hex/screens/main_app_screen.dart';
import 'package:by_hex/services/auth_service.dart';
import 'package:by_hex/services/enhanced_file_service.dart';
import 'package:by_hex/services/enhanced_hex_editor_service.dart';
import 'package:by_hex/services/security_service.dart';
import 'package:by_hex/services/virus_total_service.dart';
import 'package:by_hex/services/bookmark_service.dart';
import 'package:by_hex/services/whatsapp_service.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  // تعيين اتجاه التطبيق للعربية (من اليمين إلى اليسار)
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => EnhancedFileService()),
        ChangeNotifierProvider(create: (_) => EnhancedHexEditorService()),
        ChangeNotifierProvider(create: (_) => SecurityService()),
        ChangeNotifierProvider(create: (_) => VirusTotalService()),
        ChangeNotifierProvider(create: (_) => BookmarkService()),
        ProxyProvider2<SecurityService, VirusTotalService, WhatsAppService>(
          update: (_, securityService, virusTotalService, previousWhatsAppService) => 
              previousWhatsAppService ?? WhatsAppService(securityService, virusTotalService),
        ),
      ],
      child: const ByHexApp(),
    ),
  );
}

class ByHexApp extends StatefulWidget {
  const ByHexApp({super.key});

  @override
  State<ByHexApp> createState() => _ByHexAppState();
}

class _ByHexAppState extends State<ByHexApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // إعادة تسجيل مستمعي المشاركة عند استئناف التطبيق
      ReceiveSharingIntent.reset();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'By Hex',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ar', ''), // العربية
        Locale('en', ''), // الإنجليزية
      ],
      locale: const Locale('ar', ''),
      theme: ThemeData(
        primarySwatch: Colors.purple,
        scaffoldBackgroundColor: AppColors.backgroundColor,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.appBarColor,
          foregroundColor: Colors.black87,
          elevation: 0,
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: AppColors.textColor),
          bodyMedium: TextStyle(color: AppColors.textColor),
          bodySmall: TextStyle(color: AppColors.secondaryTextColor),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.buttonColor,
            foregroundColor: Colors.white,
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: AppColors.appBarColor,
          selectedItemColor: AppColors.deepPurple,
          unselectedItemColor: Colors.black54,
        ),
      ),
      home: Consumer<AuthService>(
        builder: (context, authService, _) {
          // تهيئة خدمة واتساب عند بدء التطبيق
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (authService.currentUser != null) {
              final whatsappService = Provider.of<WhatsAppService>(context, listen: false);
              if (!whatsappService.isInitialized) {
                whatsappService.initialize();
              }
            }
          });
          
          if (authService.currentUser != null) {
            return const MainAppScreen();
          } else {
            return const LoginScreen();
          }
        },
      ),
    );
  }
}
