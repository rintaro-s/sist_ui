import 'dart:ui';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'dart:async';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:window_manager/window_manager.dart';

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
  
  DesktopItem({
    required this.id,
    required this.type,
    required this.name,
    required this.icon,
    required this.position,
    this.children,
    this.command,
  });
}

class Window {
  final String id;
  final String title;
  final Widget content;
  Offset position;
  Size size;
  bool isFocused;

  Window({
    required this.id,
    required this.title,
    required this.content,
    this.position = const Offset(150, 150),
    this.size = const Size(600, 500),
    this.isFocused = true,
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
  // For Linux, window manager is needed to make window transparent
  if (Platform.isLinux) {
    await windowManager.ensureInitialized();
    WindowOptions windowOptions = const WindowOptions(
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.hidden,
    );
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }
  await initializeDateFormatting('ja_JP', null);
  runApp(const MementoMoriApp());
}

class MementoMoriApp extends StatelessWidget {
  const MementoMoriApp({super.key});
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SIST OS',
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
  List<Window> openWindows = [];
  String? _selectedItemId;
  OverlayEntry? _contextMenuEntry;
  DesktopSettings settings = DesktopSettings();
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
    _hideContextMenu();
    super.dispose();
  }
  
  void _initializeDesktop() {
    desktopItems = [
      DesktopItem(id: 'app-files', type: DesktopItemType.app, name: 'ファイル管理', icon: Icons.folder_open, position: const Offset(100, 100), command: _getFileManagerCommand()),
      DesktopItem(id: 'app-terminal', type: DesktopItemType.app, name: 'ターミナル', icon: Icons.terminal, position: const Offset(100, 220), command: _getTerminalCommand()),
      DesktopItem(id: 'app-browser', type: DesktopItemType.app, name: 'ブラウザ', icon: Icons.language, position: const Offset(220, 100), command: _getBrowserCommand()),
      DesktopItem(id: 'app-editor', type: DesktopItemType.app, name: 'テキスト編集', icon: Icons.edit_note, position: const Offset(220, 220), command: _getEditorCommand()),
      DesktopItem(id: 'app-calculator', type: DesktopItemType.app, name: '計算機', icon: Icons.calculate, position: const Offset(340, 100), command: _getCalculatorCommand()),
      DesktopItem(id: 'app-system-monitor', type: DesktopItemType.app, name: 'システム監視', icon: Icons.monitor_heart, position: const Offset(340, 220), command: _getSystemMonitorCommand()),
      DesktopItem(id: 'file-readme', type: DesktopItemType.file, name: 'readme.txt', icon: Icons.description, position: const Offset(460, 100)),
      DesktopItem(id: 'folder-documents', type: DesktopItemType.folder, name: 'ドキュメント', icon: Icons.folder_special, position: const Offset(460, 220), children: []),
    ];
  }
  
  String _getFileManagerCommand() {
    if (Platform.isLinux) return 'nautilus';
    if (Platform.isWindows) return 'explorer';
    if (Platform.isMacOS) return 'open -a Finder';
    return 'nautilus';
  }
  
  String _getTerminalCommand() {
    // Attempts to find a suitable terminal emulator on Linux.
    const linuxTerminals = ['kgx', 'gnome-terminal', 'konsole', 'xfce4-terminal', 'lxterminal', 'mate-terminal', 'xterm'];
    if (Platform.isLinux) {
      for (var term in linuxTerminals) {
        // A simple check. A more robust solution would be to check PATH.
        if (Process.runSync('which', [term]).exitCode == 0) {
          return term;
        }
      }
      return 'xterm'; // Fallback
    }
    if (Platform.isWindows) return 'cmd';
    if (Platform.isMacOS) return 'open -a Terminal';
    return 'gnome-terminal';
  }

  String _getBrowserCommand() => 'firefox';
  String _getEditorCommand() => 'gedit';
  String _getCalculatorCommand() => 'gnome-calculator';
  String _getSystemMonitorCommand() => 'gnome-system-monitor';
  
  Future<void> _launchApp(String? command) async {
    if (command == null || command.isEmpty) return;
    try {
      if (Platform.isWindows) {
        await Process.start('cmd', ['/c', 'start', command], runInShell: true);
      } else {
        // Detach the process so it doesn't die with the Flutter app if it closes.
        await Process.start(command, [], mode: ProcessStartMode.detached);
      }
    } catch (e) {
      _showErrorDialog('アプリケーションの起動に失敗しました: $e\nコマンド: $command');
    }
  }
  
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('エラー'),
        content: Text(message),
        actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK'))],
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
          ];
        } else {
          menuItems = [
            _buildContextMenuItem(Icons.sort, 'アイコンの整列', () => _arrangeInGrid()),
            _buildContextMenuItem(Icons.refresh, 'リフレッシュ', () => setState(() {})),
            const _ContextMenuDivider(),
            _buildContextMenuItem(Icons.create_new_folder, '新規フォルダ', () => _createNewFolder(details.localPosition)),
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
      if (item.id == 'app-files') {
        _openFileManager();
      } else {
        _launchApp(item.command);
      }
    } else if (item.type == DesktopItemType.folder) {
      _openFileManager(path: item.name);
    } else if (item.type == DesktopItemType.file) {
      _launchApp('${_getEditorCommand()} "${item.name}"');
    }
  }
  
  void _renameItem(DesktopItem item) {
    // ... (Implementation remains the same)
  }
  
  void _copyItem(DesktopItem item) {
    // ... (Implementation remains the same)
  }
  
  void _deleteItem(DesktopItem item) {
    // ... (Implementation remains the same)
  }
  
  void _arrangeInGrid() {
    setState(() {
      const double startX = 100;
      const double startY = 100;
      const double spacingX = 120;
      const double spacingY = 120;
      final double viewWidth = MediaQuery.of(context).size.width;
      final int itemsPerRow = ((viewWidth - startX) / spacingX).floor();
      
      for (int i = 0; i < desktopItems.length; i++) {
        final row = i ~/ itemsPerRow;
        final col = i % itemsPerRow;
        desktopItems[i].position = Offset(
          startX + (col * spacingX),
          startY + (row * spacingY),
        );
      }
    });
  }
  
  void _createNewFolder(Offset position) {
    // ... (Implementation remains the same)
  }
  
  Future<void> _changeWallpaper() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        settings.wallpaperPath = result.files.single.path!;
      });
    }
  }
  
  void _openWindow(Window window) {
    setState(() {
      for (var w in openWindows) {
        w.isFocused = false;
      }
      openWindows.add(window);
    });
  }

  void _closeWindow(String id) {
    setState(() {
      openWindows.removeWhere((w) => w.id == id);
    });
  }

  void _focusWindow(String id) {
    setState(() {
      final window = openWindows.firstWhere((w) => w.id == id);
      openWindows.remove(window);
      openWindows.add(window); // Move to the top of the stack
      for (var w in openWindows) {
        w.isFocused = (w.id == id);
      }
    });
  }

  void _openSettings() {
    final windowId = 'settings';
    if (openWindows.any((w) => w.id == windowId)) {
      _focusWindow(windowId);
      return;
    }
    _openWindow(Window(
      id: windowId,
      title: '設定',
      content: _SettingsScreen(
        settings: settings,
        onSettingsChanged: (newSettings) => setState(() => settings = newSettings),
      ),
    ));
  }

  void _openFileManager({String? path}) {
    final windowId = 'file-manager-${path ?? 'root'}';
     if (openWindows.any((w) => w.id == windowId)) {
      _focusWindow(windowId);
      return;
    }
    _openWindow(Window(
      id: windowId,
      title: 'ファイル管理',
      content: _FileManagerScreen(initialPath: path),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Listener(
        onPointerDown: (details) {
          _hideContextMenu();
          setState(() {
            _selectedItemId = null;
          });
        },
        child: GestureDetector(
          onSecondaryTapDown: (details) => _showContextMenu(context, details),
          child: Stack(
            children: [
              BackgroundLayer(wallpaperPath: settings.wallpaperPath),
              if (settings.showCharacter) CharacterLayer(characterPath: settings.characterPath),
              
              // Desktop Icons
              ..._buildDesktopIcons(),

              // Windows
              ...openWindows.map((w) => DraggableWindow(
                window: w,
                onClose: () => _closeWindow(w.id),
                onFocus: () => _focusWindow(w.id),
                onDrag: (offset) => setState(() => w.position = offset),
              )),

              // Taskbar
              const Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Taskbar(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildDesktopIcons() {
    return desktopItems.map((item) {
      Widget iconWidget = Positioned(
        left: item.position.dx,
        top: item.position.dy,
        child: GestureDetector(
          onTap: () => setState(() => _selectedItemId = item.id),
          onSecondaryTapDown: (details) => _showContextMenu(context, details, item: item),
          onDoubleTap: () => _handleItemDoubleClick(item),
          child: _DesktopIconWidget(
            item: item,
            iconSize: settings.iconSize,
            themeColor: settings.themeColor,
            isSelected: _selectedItemId == item.id,
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
          isSelected: _selectedItemId == item.id,
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
        child: iconWidget,
      );
    }).toList();
  }
}

// --- Widgets ---

class _DesktopIconWidget extends StatelessWidget {
  final DesktopItem item;
  final bool isDragging;
  final double iconSize;
  final Color themeColor;
  final bool isSelected;
  
  const _DesktopIconWidget({
    required this.item,
    this.isDragging = false,
    required this.iconSize,
    required this.themeColor,
    required this.isSelected,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: isSelected ? themeColor.withOpacity(0.2) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: isSelected ? Border.all(color: themeColor, width: 1) : Border.all(color: Colors.transparent, width: 1),
      ),
      child: Opacity(
        opacity: isDragging ? 0.7 : 1.0,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(item.icon, size: iconSize, color: Colors.white, shadows: const [Shadow(color: Colors.black, blurRadius: 10)]),
            const SizedBox(height: 8),
            Text(
              item.name,
              style: const TextStyle(fontSize: 12, color: Colors.white, shadows: [Shadow(color: Colors.black, blurRadius: 5)]),
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
  Widget build(BuildContext context) => Container(height: 1, margin: const EdgeInsets.symmetric(vertical: 4), color: const Color(0x33d7c9a7));
}

class BackgroundLayer extends StatelessWidget {
  final String wallpaperPath;
  const BackgroundLayer({super.key, required this.wallpaperPath});
  
  @override
  Widget build(BuildContext context) {
    final isAsset = wallpaperPath.startsWith('assets/');
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: (isAsset
              ? AssetImage(wallpaperPath)
              : FileImage(File(wallpaperPath))) as ImageProvider,
          fit: BoxFit.cover,
        ),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
        child: Container(color: Colors.black.withOpacity(0.3)),
      ),
    );
  }
}

class CharacterLayer extends StatelessWidget {
  final String characterPath;
  const CharacterLayer({super.key, required this.characterPath});
  
  @override
  Widget build(BuildContext context) {
    // This is just a decorative gradient, actual image can be added here
    return Positioned(
      bottom: 0,
      right: 0,
      height: MediaQuery.of(context).size.height * 0.8,
      width: MediaQuery.of(context).size.width * 0.4,
      child: Opacity(
        opacity: 0.5,
        child: Image.asset(
          characterPath,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}

class Taskbar extends StatelessWidget {
  const Taskbar({super.key});

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: 50,
          color: Colors.black.withOpacity(0.3),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              const Text('SIST', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xffd7c9a7))),
              const Spacer(),
              const TopRightClock(),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.power_settings_new),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('シャットダウン'),
                      content: const Text('システムをシャットダウンしますか？'),
                      actions: [
                        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('キャンセル')),
                        TextButton(
                          onPressed: () => Process.run('shutdown', ['-h', 'now']),
                          child: const Text('シャットダウン', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TopRightClock extends StatefulWidget {
  const TopRightClock({super.key});
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
        _timeString = DateFormat('HH:mm').format(now);
        _dateString = DateFormat('M月d日(E)', 'ja_JP').format(now);
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(_dateString, style: const TextStyle(fontSize: 14)),
        const SizedBox(width: 10),
        Text(_timeString, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class DraggableWindow extends StatelessWidget {
  final Window window;
  final VoidCallback onClose;
  final VoidCallback onFocus;
  final Function(Offset) onDrag;

  const DraggableWindow({
    super.key,
    required this.window,
    required this.onClose,
    required this.onFocus,
    required this.onDrag,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: window.position.dx,
      top: window.position.dy,
      child: GestureDetector(
        onTap: onFocus,
        child: Draggable(
          handle: const _WindowHeader(title: ''), // Use a dummy handle for the whole header
          feedback: Material(color: Colors.transparent, child: Container(width: window.size.width, height: window.size.height, decoration: BoxDecoration(border: Border.all(color: Colors.white.withOpacity(0.5))))),
          childWhenDragging: const SizedBox.shrink(),
          onDragEnd: (details) => onDrag(details.offset),
          child: Container(
            width: window.size.width,
            height: window.size.height,
            decoration: BoxDecoration(
              color: const Color(0xFF1a1816).withOpacity(0.9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: window.isFocused ? const Color(0xffd7c9a7) : Colors.white.withOpacity(0.2)),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 30, spreadRadius: 5)],
            ),
            child: Column(
              children: [
                _WindowHeader(title: window.title, onClose: onClose),
                Expanded(child: ClipRRect(
                  borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(12), bottomRight: Radius.circular(12)),
                  child: window.content,
                )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WindowHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onClose;

  const _WindowHeader({required this.title, this.onClose});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // This makes the whole header draggable
      onPanUpdate: (_) {}, // Dummy gesture handler
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: const BoxDecoration(
          color: Color(0xFF2a2826),
          borderRadius: BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
        ),
        child: Row(
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const Spacer(),
            if (onClose != null)
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: onClose,
                splashRadius: 20,
              ),
          ],
        ),
      ),
    );
  }
}

// --- Screens (now used as window content) ---

class _SettingsScreen extends StatefulWidget {
  final DesktopSettings settings;
  final Function(DesktopSettings) onSettingsChanged;
  
  const _SettingsScreen({required this.settings, required this.onSettingsChanged});
  
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
    return Padding(
      padding: const EdgeInsets.all(20),
      child: ListView(
        children: [
          SwitchListTile(
            title: const Text('時計を表示'),
            value: _settings.showClock,
            onChanged: (value) {
              setState(() => _settings.showClock = value);
              widget.onSettingsChanged(_settings);
            },
          ),
          SwitchListTile(
            title: const Text('キャラクターを表示'),
            value: _settings.showCharacter,
            onChanged: (value) {
              setState(() => _settings.showCharacter = value);
              widget.onSettingsChanged(_settings);
            },
          ),
          ListTile(
            title: const Text('アイコンサイズ'),
            subtitle: Slider(
              value: _settings.iconSize,
              min: 32, max: 96, divisions: 8,
              label: _settings.iconSize.round().toString(),
              onChanged: (value) {
                setState(() => _settings.iconSize = value);
                widget.onSettingsChanged(_settings);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FileManagerScreen extends StatelessWidget {
  final String? initialPath;
  const _FileManagerScreen({this.initialPath});
  
  @override
  Widget build(BuildContext context) {
    // This is a placeholder implementation.
    // A real file manager would require much more logic.
    return Center(
      child: Text('ファイル管理\nパス: ${initialPath ?? '/'}', textAlign: TextAlign.center),
    );
  }
}