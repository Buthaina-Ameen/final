import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:by_hex/constants/app_colors.dart';
import 'package:by_hex/services/whatsapp_service.dart';

class WhatsAppScanSettingsScreen extends StatefulWidget {
  const WhatsAppScanSettingsScreen({super.key});

  @override
  State<WhatsAppScanSettingsScreen> createState() => _WhatsAppScanSettingsScreenState();
}

class _WhatsAppScanSettingsScreenState extends State<WhatsAppScanSettingsScreen> {
  final TextEditingController _pathController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final whatsappService = Provider.of<WhatsAppService>(context, listen: false);
      _pathController.text = whatsappService._whatsappMediaPath;
    });
  }

  @override
  void dispose() {
    _pathController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إعدادات فحص واتساب'),
        backgroundColor: AppColors.darkGrayLight,
      ),
      body: Consumer<WhatsAppService>(
        builder: (context, whatsappService, _) {
          return Container(
            color: AppColors.backgroundColor,
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                _buildSectionTitle('الإعدادات العامة'),
                _buildSwitchTile(
                  title: 'تفعيل الفحص التلقائي',
                  subtitle: 'فحص الملفات تلقائياً عند استلامها',
                  value: whatsappService.autoScanEnabled,
                  onChanged: (value) {
                    whatsappService.autoScanEnabled = value;
                  },
                ),
                _buildSwitchTile(
                  title: 'إشعارات الفحص',
                  subtitle: 'عرض إشعار عند اكتشاف تهديد',
                  value: whatsappService.notifyOnScan,
                  onChanged: (value) {
                    whatsappService.notifyOnScan = value;
                  },
                ),
                _buildSwitchTile(
                  title: 'استخدام VirusTotal',
                  subtitle: 'فحص الملفات باستخدام خدمة VirusTotal عبر الإنترنت',
                  value: whatsappService.useVirusTotal,
                  onChanged: (value) {
                    whatsappService.useVirusTotal = value;
                  },
                ),
                const Divider(color: Colors.grey),
                _buildSectionTitle('أنواع الملفات للفحص'),
                _buildSwitchTile(
                  title: 'فحص الصور',
                  subtitle: 'فحص ملفات الصور (JPG, PNG, GIF, ...)',
                  value: whatsappService.scanImages,
                  onChanged: (value) {
                    whatsappService.scanImages = value;
                  },
                ),
                _buildSwitchTile(
                  title: 'فحص المستندات',
                  subtitle: 'فحص المستندات (PDF, DOC, XLS, ...)',
                  value: whatsappService.scanDocuments,
                  onChanged: (value) {
                    whatsappService.scanDocuments = value;
                  },
                ),
                _buildSwitchTile(
                  title: 'فحص ملفات الصوت',
                  subtitle: 'فحص ملفات الصوت (MP3, WAV, ...)',
                  value: whatsappService.scanAudio,
                  onChanged: (value) {
                    whatsappService.scanAudio = value;
                  },
                ),
                _buildSwitchTile(
                  title: 'فحص ملفات الفيديو',
                  subtitle: 'فحص ملفات الفيديو (MP4, AVI, ...)',
                  value: whatsappService.scanVideo,
                  onChanged: (value) {
                    whatsappService.scanVideo = value;
                  },
                ),
                const Divider(color: Colors.grey),
                _buildSectionTitle('إعدادات متقدمة'),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: TextField(
                    controller: _pathController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'مسار مجلد وسائط واتساب',
                      labelStyle: TextStyle(color: Colors.white70),
                      hintText: '/storage/emulated/0/WhatsApp/Media',
                      hintStyle: TextStyle(color: Colors.white30),
                      border: OutlineInputBorder(),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white30),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: AppColors.lightPurple),
                      ),
                    ),
                    onChanged: (value) {
                      // لا نقوم بتحديث القيمة مباشرة لتجنب إعادة تهيئة المراقبة في كل تغيير
                    },
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    whatsappService.whatsappMediaPath = _pathController.text;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('تم حفظ المسار وإعادة تهيئة المراقبة'),
                        backgroundColor: AppColors.deepPurple,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.mediumPurple,
                  ),
                  child: const Text('حفظ المسار'),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: whatsappService.isInitialized
                      ? null
                      : () async {
                          await whatsappService.initialize();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('تم تهيئة خدمة فحص واتساب'),
                              backgroundColor: AppColors.deepPurple,
                            ),
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.mediumPurple,
                    disabledBackgroundColor: Colors.grey,
                  ),
                  child: Text(
                    whatsappService.isInitialized
                        ? 'تم تهيئة الخدمة'
                        : 'تهيئة خدمة فحص واتساب',
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    whatsappService.clearScanHistory();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('تم مسح سجل الفحص'),
                        backgroundColor: AppColors.deepPurple,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                  ),
                  child: const Text('مسح سجل الفحص'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          color: AppColors.lightPurple,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Card(
      color: AppColors.darkGray,
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      child: SwitchListTile(
        title: Text(
          title,
          style: const TextStyle(color: Colors.white),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: Colors.white70),
        ),
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.mediumPurple,
        activeTrackColor: AppColors.lightPurple.withOpacity(0.5),
      ),
    );
  }
}
