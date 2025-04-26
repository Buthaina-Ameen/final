import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:mime/mime.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:by_hex/services/security_service.dart';
import 'package:by_hex/services/virus_total_service.dart';
import 'package:permission_handler/permission_handler.dart';

class WhatsAppService extends ChangeNotifier {
  // إعدادات الخدمة
  bool _autoScanEnabled = true;
  bool _notifyOnScan = true;
  bool _scanImages = true;
  bool _scanDocuments = true;
  bool _scanAudio = false;
  bool _scanVideo = false;
  bool _useVirusTotal = true;
  
  // حالة الخدمة
  bool _isInitialized = false;
  bool _isScanning = false;
  
  // الخدمات المرتبطة
  final SecurityService _securityService;
  final VirusTotalService _virusTotalService;
  
  // إشعارات محلية
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  
  // سجل الملفات التي تم فحصها
  final List<ScannedFile> _scannedFiles = [];
  
  // مستمع لمشاركة الملفات
  StreamSubscription? _mediaStreamSubscription;
  StreamSubscription? _textStreamSubscription;
  
  // المجلد المؤقت لحفظ الملفات
  late Directory _tempDir;
  
  // المسار الافتراضي لمجلد واتساب
  String _whatsappMediaPath = '/storage/emulated/0/WhatsApp/Media';
  
  // المسارات الفرعية لمجلدات واتساب
  final List<String> _whatsappSubfolders = [
    'WhatsApp Images',
    'WhatsApp Documents',
    'WhatsApp Video',
    'WhatsApp Audio',
    'WhatsApp Animated Gifs',
  ];
  
  // نموذج للملف الذي تم فحصه
  class ScannedFile {
    final String path;
    final String name;
    final String type;
    final DateTime scanTime;
    final bool isClean;
    final String source; // واتساب، مشاركة، إلخ
    final List<SecurityService.SecurityThreat>? threats;
    
    ScannedFile({
      required this.path,
      required this.name,
      required this.type,
      required this.scanTime,
      required this.isClean,
      required this.source,
      this.threats,
    });
  }
  
  // المُنشئ
  WhatsAppService(this._securityService, this._virusTotalService);
  
  // الحصول على إعدادات الخدمة
  bool get autoScanEnabled => _autoScanEnabled;
  bool get notifyOnScan => _notifyOnScan;
  bool get scanImages => _scanImages;
  bool get scanDocuments => _scanDocuments;
  bool get scanAudio => _scanAudio;
  bool get scanVideo => _scanVideo;
  bool get useVirusTotal => _useVirusTotal;
  bool get isInitialized => _isInitialized;
  bool get isScanning => _isScanning;
  String get whatsappMediaPath => _whatsappMediaPath;
  
  // الحصول على سجل الملفات التي تم فحصها
  List<ScannedFile> get scannedFiles => List.unmodifiable(_scannedFiles);
  
  // تعيين إعدادات الخدمة
  set autoScanEnabled(bool value) {
    _autoScanEnabled = value;
    notifyListeners();
  }
  
  set notifyOnScan(bool value) {
    _notifyOnScan = value;
    notifyListeners();
  }
  
  set scanImages(bool value) {
    _scanImages = value;
    notifyListeners();
  }
  
  set scanDocuments(bool value) {
    _scanDocuments = value;
    notifyListeners();
  }
  
  set scanAudio(bool value) {
    _scanAudio = value;
    notifyListeners();
  }
  
  set scanVideo(bool value) {
    _scanVideo = value;
    notifyListeners();
  }
  
  set useVirusTotal(bool value) {
    _useVirusTotal = value;
    notifyListeners();
  }
  
  set whatsappMediaPath(String value) {
    _whatsappMediaPath = value;
    if (_isInitialized) {
      _startWhatsAppFolderMonitoring();
    }
    notifyListeners();
  }
  
  // تهيئة الخدمة
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // طلب الأذونات اللازمة
      await _requestPermissions();
      
      // تهيئة الإشعارات المحلية
      const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/launcher_icon');
      const InitializationSettings initSettings = InitializationSettings(android: androidSettings);
      await _notificationsPlugin.initialize(initSettings);
      
      // إنشاء المجلد المؤقت
      _tempDir = await Directory.systemTemp.createTemp('whatsapp_scan');
      
      // تسجيل مستمعي مشاركة الملفات
      _registerSharingListeners();
      
      // بدء مراقبة مجلدات واتساب
      _startWhatsAppFolderMonitoring();
      
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      print('خطأ في تهيئة خدمة واتساب: $e');
    }
  }
  
  // طلب الأذونات اللازمة
  Future<void> _requestPermissions() async {
    try {
      // طلب أذونات الوصول إلى التخزين الخارجي
      final status = await Permission.storage.request();
      if (status.isDenied || status.isPermanentlyDenied) {
        print('تم رفض أذونات الوصول إلى التخزين الخارجي');
      }
      
      // طلب أذونات الإشعارات
      final notificationStatus = await Permission.notification.request();
      if (notificationStatus.isDenied || notificationStatus.isPermanentlyDenied) {
        print('تم رفض أذونات الإشعارات');
      }
    } catch (e) {
      print('خطأ في طلب الأذونات: $e');
    }
  }
  
  // إلغاء تسجيل المستمعين عند التخلص من الخدمة
  @override
  void dispose() {
    _mediaStreamSubscription?.cancel();
    _textStreamSubscription?.cancel();
    _tempDir.delete(recursive: true);
    super.dispose();
  }
  
  // تسجيل مستمعي مشاركة الملفات
  void _registerSharingListeners() {
    // مستمع لمشاركة الوسائط
    _mediaStreamSubscription = ReceiveSharingIntent.getMediaStream().listen((List<SharedMediaFile> files) {
      if (_autoScanEnabled && files.isNotEmpty) {
        _handleSharedFiles(files);
      }
    }, onError: (err) {
      print('خطأ في مستمع مشاركة الوسائط: $err');
    });
    
    // مستمع لمشاركة النصوص (للروابط)
    _textStreamSubscription = ReceiveSharingIntent.getTextStream().listen((String text) {
      // يمكن إضافة معالجة للروابط المشتركة هنا إذا لزم الأمر
    }, onError: (err) {
      print('خطأ في مستمع مشاركة النصوص: $err');
    });
    
    // التحقق من وجود ملفات مشتركة عند بدء التطبيق
    ReceiveSharingIntent.getInitialMedia().then((List<SharedMediaFile> files) {
      if (_autoScanEnabled && files.isNotEmpty) {
        _handleSharedFiles(files);
      }
    });
  }
  
  // معالجة الملفات المشتركة
  Future<void> _handleSharedFiles(List<SharedMediaFile> files) async {
    if (_isScanning) return;
    
    _isScanning = true;
    notifyListeners();
    
    try {
      for (final file in files) {
        final File fileObj = File(file.path);
        if (await fileObj.exists()) {
          final String mimeType = lookupMimeType(file.path) ?? '';
          
          // التحقق من نوع الملف وإعدادات الفحص
          if (_shouldScanFile(mimeType)) {
            await _scanFile(fileObj, 'مشاركة');
          }
        }
      }
    } catch (e) {
      print('خطأ في معالجة الملفات المشتركة: $e');
    } finally {
      _isScanning = false;
      notifyListeners();
    }
  }
  
  // بدء مراقبة مجلدات واتساب
  void _startWhatsAppFolderMonitoring() {
    try {
      // التحقق من وجود مجلد واتساب
      final whatsappDir = Directory(_whatsappMediaPath);
      if (!whatsappDir.existsSync()) {
        print('مجلد واتساب غير موجود: $_whatsappMediaPath');
        return;
      }
      
      // إنشاء مراقب لكل مجلد فرعي
      for (final subfolder in _whatsappSubfolders) {
        final dir = Directory('$_whatsappMediaPath/$subfolder');
        if (dir.existsSync()) {
          _monitorDirectory(dir);
        } else {
          print('المجلد الفرعي غير موجود: $subfolder');
        }
      }
    } catch (e) {
      print('خطأ في بدء مراقبة مجلدات واتساب: $e');
    }
  }
  
  // مراقبة مجلد معين للملفات الجديدة
  void _monitorDirectory(Directory dir) {
    try {
      dir.watch(events: FileSystemEvent.create).listen((event) {
        if (_autoScanEnabled && event.type == FileSystemEvent.create) {
          final file = File(event.path);
          final String mimeType = lookupMimeType(event.path) ?? '';
          
          // التحقق من نوع الملف وإعدادات الفحص
          if (_shouldScanFile(mimeType)) {
            _scanFile(file, 'واتساب');
          }
        }
      }, onError: (error) {
        print('خطأ في مراقبة المجلد ${dir.path}: $error');
      });
    } catch (e) {
      print('خطأ في إنشاء مراقب للمجلد ${dir.path}: $e');
    }
  }
  
  // التحقق مما إذا كان يجب فحص الملف بناءً على نوعه
  bool _shouldScanFile(String mimeType) {
    if (mimeType.startsWith('image/') && _scanImages) {
      return true;
    } else if (mimeType.startsWith('application/') && _scanDocuments) {
      return true;
    } else if (mimeType.startsWith('audio/') && _scanAudio) {
      return true;
    } else if (mimeType.startsWith('video/') && _scanVideo) {
      return true;
    }
    return false;
  }
  
  // فحص ملف
  Future<void> _scanFile(File file, String source) async {
    try {
      // فحص الملف باستخدام SecurityService
      final securityScanResult = await _securityService.quickScanFile(file);
      
      // فحص الملف باستخدام VirusTotal إذا كان مفعلاً
      VirusTotalService.VirusTotalResult? virusTotalResult;
      if (_useVirusTotal && !securityScanResult.isClean) {
        virusTotalResult = await _virusTotalService.scanFile(file);
      }
      
      // تحديد ما إذا كان الملف نظيفًا
      final isClean = securityScanResult.isClean && (virusTotalResult == null || virusTotalResult.isClean);
      
      // إنشاء سجل للملف الذي تم فحصه
      final scannedFile = ScannedFile(
        path: file.path,
        name: path.basename(file.path),
        type: lookupMimeType(file.path) ?? 'غير معروف',
        scanTime: DateTime.now(),
        isClean: isClean,
        source: source,
        threats: securityScanResult.threats,
      );
      
      // إضافة الملف إلى سجل الملفات التي تم فحصها
      _scannedFiles.add(scannedFile);
      notifyListeners();
      
      // إرسال إشعار إذا كان الملف غير نظيف
      if (!isClean && _notifyOnScan) {
        _showThreatNotification(scannedFile);
      }
      
      // وضع الملف في الحجر الصحي إذا كان غير نظيف
      if (!isClean) {
        await _securityService.quarantineFile(file);
      }
    } catch (e) {
      print('خطأ في فحص الملف ${file.path}: $e');
    }
  }
  
  // إظهار إشعار بوجود تهديد
  Future<void> _showThreatNotification(ScannedFile file) async {
    try {
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'security_scan_channel',
        'فحص الأمان',
        channelDescription: 'إشعارات فحص الأمان للملفات',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/launcher_icon',
      );
      
      const NotificationDetails notificationDetails = NotificationDetails(android: androidDetails);
      
      await _notificationsPlugin.show(
        DateTime.now().millisecondsSinceEpoch.remainder(100000),
        'تم اكتشاف تهديد محتمل',
        'تم اكتشاف تهديد في الملف ${file.name} من ${file.source}',
        notificationDetails,
      );
    } catch (e) {
      print('خطأ في إظهار إشعار التهديد: $e');
    }
  }
  
  // فحص ملف يدويًا
  Future<ScannedFile?> scanFileManually(File file) async {
    if (_isScanning) return null;
    
    _isScanning = true;
    notifyListeners();
    
    try {
      // فحص الملف باستخدام SecurityService
      final securityScanResult = await _securityService.thoroughScanFile(file);
      
      // فحص الملف باستخدام VirusTotal إذا كان مفعلاً
      VirusTotalService.VirusTotalResult? virusTotalResult;
      if (_useVirusTotal) {
        virusTotalResult = await _virusTotalService.scanFile(file);
      }
      
      // تحديد ما إذا كان الملف نظيفًا
      final isClean = securityScanResult.isClean && (virusTotalResult == null || virusTotalResult.isClean);
      
      // إنشاء سجل للملف الذي تم فحصه
      final scannedFile = ScannedFile(
        path: file.path,
        name: path.basename(file.path),
        type: lookupMimeType(file.path) ?? 'غير معروف',
        scanTime: DateTime.now(),
        isClean: isClean,
        source: 'فحص يدوي',
        threats: securityScanResult.threats,
      );
      
      // إضافة الملف إلى سجل الملفات التي تم فحصها
      _scannedFiles.add(scannedFile);
      notifyListeners();
      
      // إرسال إشعار إذا كان الملف غير نظيف
      if (!isClean && _notifyOnScan) {
        _showThreatNotification(scannedFile);
      }
      
      return scannedFile;
    } catch (e) {
      print('خطأ في فحص الملف ${file.path}: $e');
      return null;
    } finally {
      _isScanning = false;
      notifyListeners();
    }
  }
  
  // مسح سجل الملفات التي تم فحصها
  void clearScanHistory() {
    _scannedFiles.clear();
    notifyListeners();
  }
}
