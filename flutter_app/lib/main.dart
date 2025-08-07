import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const SettingsApp());
}

class SettingsApp extends StatelessWidget {
  const SettingsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SIST Settings',
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF1A1A1A), // Dark background
        scaffoldBackgroundColor: const Color(0xFF1A1A1A),
        fontFamily: 'KTEGAKI',
        textTheme: const TextTheme(
          displayLarge: TextStyle(color: Colors.white, fontFamily: 'KTEGAKI'),
          displayMedium: TextStyle(color: Colors.white, fontFamily: 'KTEGAKI'),
          displaySmall: TextStyle(color: Colors.white, fontFamily: 'KTEGAKI'),
          headlineLarge: TextStyle(color: Colors.white, fontFamily: 'KTEGAKI'),
          headlineMedium: TextStyle(color: Colors.white, fontFamily: 'KTEGAKI'),
          headlineSmall: TextStyle(color: Colors.white, fontFamily: 'KTEGAKI'),
          titleLarge: TextStyle(color: Colors.white, fontFamily: 'KTEGAKI'),
          titleMedium: TextStyle(color: Colors.white, fontFamily: 'KTEGAKI'),
          titleSmall: TextStyle(color: Colors.white, fontFamily: 'KTEGAKI'),
          bodyLarge: TextStyle(color: Colors.white, fontFamily: 'KTEGAKI'),
          bodyMedium: TextStyle(color: Colors.white70, fontFamily: 'KTEGAKI'),
          bodySmall: TextStyle(color: Colors.white54, fontFamily: 'KTEGAKI'),
          labelLarge: TextStyle(color: Colors.white, fontFamily: 'KTEGAKI'),
          labelMedium: TextStyle(color: Colors.white70, fontFamily: 'KTEGAKI'),
          labelSmall: TextStyle(color: Colors.white54, fontFamily: 'KTEGAKI'),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF2A2A2A), // Slightly lighter AppBar
          foregroundColor: Colors.white,
          elevation: 0,
          titleTextStyle: TextStyle(
            fontFamily: 'KTEGAKI',
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        listTileTheme: ListTileThemeData(
          tileColor: const Color(0xFF2A2A2A), // Background for list tiles
          textColor: Colors.white,
          iconColor: const Color(0xFFFFD700), // Gold accent for icons
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          minVerticalPadding: 15,
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF2A2A2A),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          elevation: 5,
          shadowColor: Colors.black.withValues(alpha: 0.5),
        ),
        dividerColor: Colors.white.withValues(alpha: 0.1),
      ),
      home: const SettingsScreen(),
    );
  }
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    _loadFont();
  }

  Future<void> _loadFont() async {
    // Ensure the custom font is loaded
    await FontLoader('KTEGAKI').load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('設定'),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Background Image (optional, if you want a different background for settings)
          // Positioned.fill(
          //   child: Image.asset(
          //     'assets/wallpaper.png',
          //     fit: BoxFit.cover,
          //   ),
          // ),
          ListView(
            padding: const EdgeInsets.all(20.0),
            children: [
              _buildSettingsSection(
                context,
                '一般',
                [
                  _buildSettingsTile(
                    context,
                    Icons.display_settings,
                    'ディスプレイ',
                    '画面の解像度、明るさなどを設定します',
                    () { /* Navigate to Display Settings */ },
                  ),
                  _buildSettingsTile(
                    context,
                    Icons.volume_up,
                    'サウンド',
                    '音量、出力デバイスなどを設定します',
                    () { /* Navigate to Sound Settings */ },
                  ),
                  _buildSettingsTile(
                    context,
                    Icons.mouse,
                    'マウス＆タッチパッド',
                    'ポインター速度、スクロール方向などを設定します',
                    () { /* Navigate to Mouse Settings */ },
                  ),
                ],
              ),
              const SizedBox(height: 30),
              _buildSettingsSection(
                context,
                'ネットワーク',
                [
                  _buildSettingsTile(
                    context,
                    Icons.wifi,
                    'Wi-Fi',
                    'ワイヤレスネットワークに接続します',
                    () { /* Navigate to Wi-Fi Settings */ },
                  ),
                  _buildSettingsTile(
                    context,
                    Icons.lan,
                    '有線ネットワーク',
                    '有線接続の設定を行います',
                    () { /* Navigate to Wired Settings */ },
                  ),
                ],
              ),
              const SizedBox(height: 30),
              _buildSettingsSection(
                context,
                'システム',
                [
                  _buildSettingsTile(
                    context,
                    Icons.info,
                    'バージョン情報',
                    'OSのバージョン、システム情報などを確認します',
                    () { /* Navigate to About System */ },
                  ),
                  _buildSettingsTile(
                    context,
                    Icons.update,
                    'ソフトウェアアップデート',
                    'システムの更新を確認します',
                    () { /* Navigate to Software Update */ },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(BuildContext context, String title, List<Widget> tiles) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 10.0, bottom: 10.0),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: const Color(0xFFFFD700), // Gold for section titles
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        Card(
          margin: EdgeInsets.zero,
          child: Column(
            children: tiles.map((tile) {
              return Column(
                children: [
                  tile,
                  if (tile != tiles.last) const Divider(height: 1, indent: 20, endIndent: 20), // Divider between tiles
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsTile(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Icon(icon, size: 30),
      title: Text(title, style: Theme.of(context).textTheme.titleMedium),
      subtitle: Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
      trailing: const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.white54),
      onTap: () {
        // Add a subtle visual feedback on tap
        HapticFeedback.lightImpact();
        onTap();
      },
      // Add a subtle hover effect for desktop
      hoverColor: Colors.white.withValues(alpha: 0.05),
    );
  }
}
