import 'dart:ui';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'dart:async';
import 'dart:io';
import 'dart:math';

// --- データモデル ---
enum DesktopItemType { app, file, folder }

class DesktopItem {
  String id;
  DesktopItemType type;
  String name;
  IconData icon;
  Offset position;
  List<DesktopItem>? children;
  String? command;
  bool isSelected;
  
  DesktopItem({
    required this.id,
    required this.type,
    required this.name,
    required this.icon,
    required this.position,
    this.children,
    this.command,
    this.isSelected = false,
  });
}

class DesktopSettings {
  String wallpaperPath;
  bool showClock;
  bool showWeather;
  double iconSize;
  Color themeColor;
  String characterPath;
  bool showCharacter;
  bool enableAnimations;
  
  DesktopSettings({
    this.wallpaperPath = 'assets/wallpaper.png',
    this.showClock = true,
    this.showWeather = true,
    this.iconSize = 48.0,
    this.themeColor = const Color(0xffd7c9a7),
    this.characterPath = 'assets/character.png',
    this.showCharacter = true,
    this.enableAnimations = true,
  });
}

// --- メインエントリーポイント ---
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ja_JP', null);
  runApp(const MementoMoriApp());
}

class MementoMoriApp extends StatelessWidget {
  const MementoMoriApp({super.key});
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Memento Mori OS',
      theme: ThemeData(
        fontFamily: 'Noto Sans JP',
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xffd7c9a7),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const DesktopShell(),
    );
  }
}

class DesktopShell extends StatefulWidget {
  const DesktopShell({super.key});
  
  @override
  State<DesktopShell> createState() => _DesktopShellState();
}

class _DesktopShellState extends State<DesktopShell> with TickerProviderStateMixin {
  List<DesktopItem> desktopItems = [];
  OverlayEntry? _contextMenuEntry;
  DesktopSettings settings = DesktopSettings();
  bool _showingSettings = false;
  bool _showingFileManager = false;
  late AnimationController _fadeController;
  
  @override
  void initState() {
    super.initState();
    _initializeDesktop();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeController.forward();
  }
  
  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }
  
  void _initializeDesktop() {
    desktopItems = [
      DesktopItem(
        id: 'app-files',
        type: DesktopItemType.app,
        name: 'ファイル管理',
        icon: Icons.folder_open,
        position: const Offset(100, 100),
        command: _getFileManagerCommand(),
      ),
      DesktopItem(
        id: 'app-terminal',
        type: DesktopItemType.app,
        name: 'ターミナル',
        icon: Icons.terminal,
        position: const Offset(100, 220),
        command: _getTerminalCommand(),
      ),
      DesktopItem(
        id: 'app-browser',
        type: DesktopItemType.app,
        name: 'ブラウザ',
        icon: Icons.language,
        position: const Offset(220, 100),
        command: _getBrowserCommand(),
      ),
      DesktopItem(
        id: 'app-editor',
        type: DesktopItemType.app,
        name: 'テキスト編集',
        icon: Icons.edit_note,
        position: const Offset(220, 220),
        command: _getEditorCommand(),
      ),
      DesktopItem(
        id: 'app-calculator',
        type: DesktopItemType.app,
        name: '計算機',
        icon: Icons.calculate,
        position: const Offset(340, 100),
        command: _getCalculatorCommand(),
      ),
      DesktopItem(
        id: 'app-system-monitor',
        type: DesktopItemType.app,
        name: 'システム監視',
        icon: Icons.monitor_heart,
        position: const Offset(340, 220),
        command: _getSystemMonitorCommand(),
      ),
      DesktopItem(
        id: 'file-readme',
        type: DesktopItemType.file,
        name: 'readme.txt',
        icon: Icons.description,
        position: const Offset(460, 100),
      ),
      DesktopItem(
        id: 'folder-documents',
        type: DesktopItemType.folder,
        name: 'ドキュメント',
        icon: Icons.folder_special,
        position: const Offset(460, 220),
        children: [],
      ),
    ];
  }
  
  String _getFileManagerCommand() {
    if (Platform.isLinux) return 'nautilus';
    if (Platform.isWindows) return 'explorer';
    if (Platform.isMacOS) return 'open -a Finder';
    return 'nautilus';
  }
  
  String _getTerminalCommand() {
    if (Platform.isLinux) return 'gnome-terminal';
    if (Platform.isWindows) return 'cmd';
    if (Platform.isMacOS) return 'open -a Terminal';
    return 'gnome-terminal';
  }
  
  String _getBrowserCommand() {
    if (Platform.isLinux) return 'firefox';
    if (Platform.isWindows) return 'start chrome';
    if (Platform.isMacOS) return 'open -a "Google Chrome"';
    return 'firefox';
  }
  
  String _getEditorCommand() {
    if (Platform.isLinux) return 'gedit';
    if (Platform.isWindows) return 'notepad';
    if (Platform.isMacOS) return 'open -a TextEdit';
    return 'gedit';
  }
  
  String _getCalculatorCommand() {
    if (Platform.isLinux) return 'gnome-calculator';
    if (Platform.isWindows) return 'calc';
    if (Platform.isMacOS) return 'open -a Calculator';
    return 'gnome-calculator';
  }
  
  String _getSystemMonitorCommand() {
    if (Platform.isLinux) return 'gnome-system-monitor';
    if (Platform.isWindows) return 'taskmgr';
    if (Platform.isMacOS) return 'open -a "Activity Monitor"';
    return 'gnome-system-monitor';
  }
  
  Future<void> _launchApp(String? command) async {
    if (command == null || command.isEmpty) return;
    
    try {
      if (Platform.isWindows) {
        await Process.start('cmd', ['/c', command], runInShell: true);
      } else {
        await Process.start('/bin/sh', ['-c', command]);
      }
    } catch (e) {
      _showErrorDialog('アプリケーションの起動に失敗しました: $e');
    }
  }
  
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('エラー'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showContextMenu(BuildContext context, TapDownDetails details, {DesktopItem? item}) {
    _hideContextMenu();
    _contextMenuEntry = OverlayEntry(
      builder: (context) {
        List<Widget> menuItems;
        if (item != null) {
          menuItems = [
            _buildContextMenuItem(Icons.open_in_new, '開く', () => _handleItemDoubleClick(item)),
            const _ContextMenuDivider(),
            _buildContextMenuItem(Icons.drive_file_rename_outline, '名前の変更', () => _renameItem(item)),
            _buildContextMenuItem(Icons.content_copy, 'コピー', () => _copyItem(item)),
            _buildContextMenuItem(Icons.delete, '削除', () => _deleteItem(item)),
            const _ContextMenuDivider(),
            _buildContextMenuItem(Icons.info, 'プロパティ', () => _showItemProperties(item)),
          ];
        } else {
          menuItems = [
            _buildContextMenuItem(Icons.sort, '表示順の変更', () => _showSortOptions()),
            _buildContextMenuItem(Icons.refresh, 'リフレッシュ', () => _refreshDesktop()),
            const _ContextMenuDivider(),
            _buildContextMenuItem(Icons.create_new_folder, '新規フォルダ', () => _createNewFolder(details.localPosition)),
            _buildContextMenuItem(Icons.note_add, '新規ファイル', () => _createNewFile(details.localPosition)),
            const _ContextMenuDivider(),
            _buildContextMenuItem(Icons.wallpaper, '壁紙の変更', () => _changeWallpaper()),
            _buildContextMenuItem(Icons.settings, '設定', () => _openSettings()),
          ];
        }
        return Positioned(
          left: details.globalPosition.dx,
          top: details.globalPosition.dy,
          child: Material(
            color: Colors.transparent,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.8),
                    border: Border.all(color: settings.themeColor.withOpacity(0.5)),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: menuItems,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
    Overlay.of(context).insert(_contextMenuEntry!);
  }

  void _hideContextMenu() {
    _contextMenuEntry?.remove();
    _contextMenuEntry = null;
  }

  Widget _buildContextMenuItem(IconData icon, String text, VoidCallback onTap) {
    return InkWell(
      onTap: () {
        onTap();
        _hideContextMenu();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 20, color: settings.themeColor),
            const SizedBox(width: 12),
            Text(text, style: const TextStyle(fontSize: 14)),
          ],
        ),
      ),
    );
  }

  void _handleItemDoubleClick(DesktopItem item) {
    if (item.type == DesktopItemType.app) {
      _launchApp(item.command);
    } else if (item.type == DesktopItemType.folder) {
      _openFolder(item);
    } else if (item.type == DesktopItemType.file) {
      _openFile(item);
    }
  }
  
  void _openFolder(DesktopItem folder) {
    setState(() {
      _showingFileManager = true;
    });
  }
  
  void _openFile(DesktopItem file) {
    _launchApp(_getEditorCommand());
  }
  
  void _renameItem(DesktopItem item) {
    showDialog(
      context: context,
      builder: (context) {
        String newName = item.name;
        return AlertDialog(
          title: const Text('名前の変更'),
          content: TextField(
            controller: TextEditingController(text: item.name),
            onChanged: (value) => newName = value,
            decoration: const InputDecoration(labelText: '新しい名前'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('キャンセル'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  item.name = newName;
                });
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
  
  void _copyItem(DesktopItem item) {
    setState(() {
      desktopItems.add(DesktopItem(
        id: '${item.id}-copy-${DateTime.now().millisecondsSinceEpoch}',
        type: item.type,
        name: '${item.name} - コピー',
        icon: item.icon,
        position: Offset(item.position.dx + 50, item.position.dy + 50),
        command: item.command,
        children: item.children,
      ));
    });
  }
  
  void _deleteItem(DesktopItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('削除の確認'),
        content: Text('「${item.name}」を削除しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                desktopItems.removeWhere((i) => i.id == item.id);
              });
              Navigator.of(context).pop();
            },
            child: const Text('削除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
  
  void _showItemProperties(DesktopItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${item.name} のプロパティ'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('名前: ${item.name}'),
            Text('種類: ${_getTypeString(item.type)}'),
            Text('位置: (${item.position.dx.toInt()}, ${item.position.dy.toInt()})'),
            if (item.command != null) Text('コマンド: ${item.command}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }
  
  String _getTypeString(DesktopItemType type) {
    switch (type) {
      case DesktopItemType.app:
        return 'アプリケーション';
      case DesktopItemType.file:
        return 'ファイル';
      case DesktopItemType.folder:
        return 'フォルダ';
    }
  }
  
  void _showSortOptions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('表示順の変更'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('名前順'),
              onTap: () {
                _sortItemsByName();
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              title: const Text('種類順'),
              onTap: () {
                _sortItemsByType();
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              title: const Text('グリッド配置'),
              onTap: () {
                _arrangeInGrid();
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }
  
  void _sortItemsByName() {
    setState(() {
      desktopItems.sort((a, b) => a.name.compareTo(b.name));
      _arrangeInGrid();
    });
  }
  
  void _sortItemsByType() {
    setState(() {
      desktopItems.sort((a, b) => a.type.index.compareTo(b.type.index));
      _arrangeInGrid();
    });
  }
  
  void _arrangeInGrid() {
    setState(() {
      const double startX = 100;
      const double startY = 100;
      const double spacing = 120;
      const int itemsPerRow = 6;
      
      for (int i = 0; i < desktopItems.length; i++) {
        final row = i ~/ itemsPerRow;
        final col = i % itemsPerRow;
        desktopItems[i].position = Offset(
          startX + (col * spacing),
          startY + (row * spacing),
        );
      }
    });
  }
  
  void _refreshDesktop() {
    setState(() {
      // デスクトップをリフレッシュ
    });
  }
  
  void _createNewFolder(Offset position) {
    setState(() {
      desktopItems.add(DesktopItem(
        id: 'folder-${DateTime.now().millisecondsSinceEpoch}',
        type: DesktopItemType.folder,
        name: '新しいフォルダ',
        icon: Icons.folder_special,
        position: position,
        children: [],
      ));
    });
  }
  
  void _createNewFile(Offset position) {
    setState(() {
      desktopItems.add(DesktopItem(
        id: 'file-${DateTime.now().millisecondsSinceEpoch}',
        type: DesktopItemType.file,
        name: '新しいファイル.txt',
        icon: Icons.description,
        position: position,
      ));
    });
  }
  
  void _changeWallpaper() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('壁紙の変更'),
        content: const Text('壁紙の変更機能は準備中です。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
  
  void _openSettings() {
    setState(() {
      _showingSettings = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // メインデスクトップ
          if (!_showingSettings && !_showingFileManager)
            _buildMainDesktop(),
          
          // 設定画面
          if (_showingSettings)
            _SettingsScreen(
              settings: settings,
              onClose: () => setState(() => _showingSettings = false),
              onSettingsChanged: (newSettings) => setState(() => settings = newSettings),
            ),
          
          // ファイルマネージャー
          if (_showingFileManager)
            _FileManagerScreen(
              onClose: () => setState(() => _showingFileManager = false),
            ),
        ],
      ),
    );
  }
  
  Widget _buildMainDesktop() {
    return FadeTransition(
      opacity: _fadeController,
      child: Listener(
        onPointerDown: (details) {
          if (details.kind == PointerDeviceKind.mouse && details.buttons == kSecondaryMouseButton) {
          } else {
            _hideContextMenu();
            setState(() {
              for (var item in desktopItems) {
                item.isSelected = false;
              }
            });
          }
        },
        child: GestureDetector(
          onSecondaryTapDown: (details) => _showContextMenu(context, details),
          child: Stack(
            children: [
              BackgroundLayer(wallpaperPath: settings.wallpaperPath),
              if (settings.showCharacter)
                CharacterLayer(characterPath: settings.characterPath),
              ..._buildDesktopIcons(),
              Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  BottomNavigation(
                    onAppLaunch: _launchApp,
                    onLogout: () => _showLogoutDialog(),
                    onSettings: _openSettings,
                    themeColor: settings.themeColor,
                  ),
                ],
              ),
              if (settings.showClock)
                TopRightClock(themeColor: settings.themeColor),
            ],
          ),
        ),
      ),
    );
  }
  
  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ログアウト'),
        content: const Text('ログアウトしますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => SystemNavigator.pop(),
            child: const Text('ログアウト', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildDesktopIcons() {
    return desktopItems.map((item) {
      Widget iconWidget = Positioned(
        left: item.position.dx,
        top: item.position.dy,
        child: GestureDetector(
          onTap: () => setState(() {
            for (var i in desktopItems) {
              i.isSelected = false;
            }
            item.isSelected = true;
          }),
          onSecondaryTapDown: (details) => _showContextMenu(context, details, item: item),
          onDoubleTap: () => _handleItemDoubleClick(item),
          child: _DesktopIconWidget(
            item: item,
            iconSize: settings.iconSize,
            themeColor: settings.themeColor,
          ),
        ),
      );
      
      return Draggable<DesktopItem>(
        data: item,
        feedback: _DesktopIconWidget(
          item: item,
          isDragging: true,
          iconSize: settings.iconSize,
          themeColor: settings.themeColor,
        ),
        childWhenDragging: const SizedBox.shrink(),
        onDragEnd: (details) {
          setState(() {
            final index = desktopItems.indexWhere((i) => i.id == item.id);
            if (index != -1) {
              desktopItems[index].position = details.offset;
            }
          });
        },
        child: DragTarget<DesktopItem>(
          builder: (context, candidateData, rejectedData) => iconWidget,
          onWillAcceptWithDetails: (details) => details.data.id != item.id,
          onAcceptWithDetails: (details) {
            final droppedItem = details.data;
            if (item.type == DesktopItemType.folder) {
              setState(() {
                item.children ??= [];
                item.children!.add(droppedItem);
                desktopItems.removeWhere((i) => i.id == droppedItem.id);
              });
            }
          },
        ),
      );
    }).toList();
  }
}

class _DesktopIconWidget extends StatelessWidget {
  final DesktopItem item;
  final bool isDragging;
  final double iconSize;
  final Color themeColor;
  
  const _DesktopIconWidget({
    required this.item,
    this.isDragging = false,
    required this.iconSize,
    required this.themeColor,
  });
  
  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 100,
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: item.isSelected ? themeColor.withOpacity(0.2) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: item.isSelected ? Border.all(color: themeColor, width: 2) : null,
      ),
      child: Opacity(
        opacity: isDragging ? 0.7 : 1.0,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              item.icon,
              size: iconSize,
              color: Colors.white,
              shadows: const [
                Shadow(color: Colors.black, blurRadius: 10),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              item.name,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white,
                shadows: [
                  Shadow(color: Colors.black, blurRadius: 5),
                ],
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _ContextMenuDivider extends StatelessWidget {
  const _ContextMenuDivider();
  
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(vertical: 4),
      color: const Color(0x33d7c9a7),
    );
  }
}

class BackgroundLayer extends StatelessWidget {
  final String wallpaperPath;
  
  const BackgroundLayer({super.key, required this.wallpaperPath});
  
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1a1816),
            const Color(0xFF2a2826),
            const Color(0xFF1a1816),
          ],
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.5,
            colors: [
              Colors.transparent,
              Colors.black.withOpacity(0.3),
            ],
          ),
        ),
      ),
    );
  }
}

class CharacterLayer extends StatelessWidget {
  final String characterPath;
  
  const CharacterLayer({super.key, required this.characterPath});
  
  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: -50,
      height: MediaQuery.of(context).size.height * 0.95,
      child: Opacity(
        opacity: 0.6,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Colors.transparent,
                Colors.black.withOpacity(0.8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class BottomNavigation extends StatelessWidget {
  final Function(String?) onAppLaunch;
  final VoidCallback onLogout;
  final VoidCallback onSettings;
  final Color themeColor;
  
  const BottomNavigation({
    super.key,
    required this.onAppLaunch,
    required this.onLogout,
    required this.onSettings,
    required this.themeColor,
  });
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(25),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                height: 80,
                width: MediaQuery.of(context).size.width * 0.6,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: themeColor.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    NavButton(
                      icon: Icons.folder_open,
                      label: 'ファイル',
                      onPressed: () => onAppLaunch('nautilus'),
                      themeColor: themeColor,
                    ),
                    NavButton(
                      icon: Icons.terminal,
                      label: 'ターミナル',
                      onPressed: () => onAppLaunch('gnome-terminal'),
                      themeColor: themeColor,
                    ),
                    NavButton(
                      icon: Icons.language,
                      label: 'ブラウザ',
                      onPressed: () => onAppLaunch('firefox'),
                      themeColor: themeColor,
                    ),
                    NavButton(
                      icon: Icons.settings,
                      label: '設定',
                      onPressed: onSettings,
                      themeColor: themeColor,
                    ),
                    NavButton(
                      icon: Icons.logout,
                      label: 'ログアウト',
                      onPressed: onLogout,
                      themeColor: themeColor,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TopRightClock extends StatefulWidget {
  final Color themeColor;
  
  const TopRightClock({super.key, required this.themeColor});
  
  @override
  State<TopRightClock> createState() => _TopRightClockState();
}

class _TopRightClockState extends State<TopRightClock> {
  late String _timeString;
  late String _dateString;
  late Timer _timer;
  
  @override
  void initState() {
    super.initState();
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) => _updateTime());
  }
  
  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }
  
  void _updateTime() {
    if (mounted) {
      final now = DateTime.now();
      setState(() {
        _timeString = DateFormat('HH:mm:ss', 'ja_JP').format(now);
        _dateString = DateFormat('M月d日(E)', 'ja_JP').format(now);
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 30,
      right: 30,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: widget.themeColor.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              _timeString,
              style: TextStyle(
                color: widget.themeColor,
                fontSize: 28,
                fontWeight: FontWeight.w300,
                shadows: const [
                  Shadow(color: Colors.black, blurRadius: 10),
                ],
              ),
            ),
            Text(
              _dateString,
              style: TextStyle(
                color: widget.themeColor.withOpacity(0.8),
                fontSize: 14,
                shadows: const [
                  Shadow(color: Colors.black, blurRadius: 5),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TopLeftWeather extends StatelessWidget {
  const TopLeftWeather({super.key});
  
  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

class NavButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final Color themeColor;
  
  const NavButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    required this.themeColor,
  });
  
  @override
  State<NavButton> createState() => _NavButtonState();
}

class _NavButtonState extends State<NavButton> {
  bool _isHovering = false;
  
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: _isHovering ? widget.themeColor.withOpacity(0.2) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                size: 24,
                color: _isHovering ? Colors.white : widget.themeColor,
              ),
              const SizedBox(height: 4),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 10,
                  color: _isHovering ? Colors.white : widget.themeColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 設定画面
class _SettingsScreen extends StatefulWidget {
  final DesktopSettings settings;
  final VoidCallback onClose;
  final Function(DesktopSettings) onSettingsChanged;
  
  const _SettingsScreen({
    required this.settings,
    required this.onClose,
    required this.onSettingsChanged,
  });
  
  @override
  State<_SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<_SettingsScreen> {
  late DesktopSettings _settings;
  
  @override
  void initState() {
    super.initState();
    _settings = widget.settings;
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.8),
      child: Center(
        child: Container(
          width: 600,
          height: 500,
          decoration: BoxDecoration(
            color: const Color(0xFF2a2826),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _settings.themeColor.withOpacity(0.5)),
          ),
          child: Column(
            children: [
              // ヘッダー
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _settings.themeColor.withOpacity(0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.settings, color: _settings.themeColor),
                    const SizedBox(width: 10),
                    const Text(
                      'デスクトップ設定',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: widget.onClose,
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              
              // 設定内容
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      SwitchListTile(
                        title: const Text('時計を表示'),
                        value: _settings.showClock,
                        onChanged: (value) {
                          setState(() {
                            _settings.showClock = value;
                          });
                          widget.onSettingsChanged(_settings);
                        },
                      ),
                      SwitchListTile(
                        title: const Text('天気を表示'),
                        value: _settings.showWeather,
                        onChanged: (value) {
                          setState(() {
                            _settings.showWeather = value;
                          });
                          widget.onSettingsChanged(_settings);
                        },
                      ),
                      SwitchListTile(
                        title: const Text('キャラクターを表示'),
                        value: _settings.showCharacter,
                        onChanged: (value) {
                          setState(() {
                            _settings.showCharacter = value;
                          });
                          widget.onSettingsChanged(_settings);
                        },
                      ),
                      SwitchListTile(
                        title: const Text('アニメーションを有効化'),
                        value: _settings.enableAnimations,
                        onChanged: (value) {
                          setState(() {
                            _settings.enableAnimations = value;
                          });
                          widget.onSettingsChanged(_settings);
                        },
                      ),
                      
                      // アイコンサイズ
                      ListTile(
                        title: const Text('アイコンサイズ'),
                        subtitle: Slider(
                          value: _settings.iconSize,
                          min: 32,
                          max: 96,
                          divisions: 8,
                          label: _settings.iconSize.round().toString(),
                          onChanged: (value) {
                            setState(() {
                              _settings.iconSize = value;
                            });
                            widget.onSettingsChanged(_settings);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ファイルマネージャー画面
class _FileManagerScreen extends StatelessWidget {
  final VoidCallback onClose;
  
  const _FileManagerScreen({required this.onClose});
  
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.8),
      child: Center(
        child: Container(
          width: 800,
          height: 600,
          decoration: BoxDecoration(
            color: const Color(0xFF2a2826),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xffd7c9a7).withOpacity(0.5)),
          ),
          child: Column(
            children: [
              // ヘッダー
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Color(0xFF3a3836),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.folder_open, color: Color(0xffd7c9a7)),
                    const SizedBox(width: 10),
                    const Text(
                      'ファイルマネージャー',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: onClose,
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              
              // ファイル一覧
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 6,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: 12,
                    itemBuilder: (context, index) {
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              index % 3 == 0 ? Icons.folder : Icons.description,
                              size: 40,
                              color: const Color(0xffd7c9a7),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'ファイル$index',
                              style: const TextStyle(fontSize: 12),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}