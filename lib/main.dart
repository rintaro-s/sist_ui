
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
import 'package:provider/provider.dart';

// --- データモデル & 状態管理 ---

enum DesktopItemType { app, file, folder }

class DesktopItem extends ChangeNotifier {
  String id;
  DesktopItemType type;
  String name;
  IconData icon;
  Offset _position;
  List<DesktopItem>? children;
  String? command;
  bool _isSelected = false;

  DesktopItem({
    required this.id,
    required this.type,
    required this.name,
    required this.icon,
    required Offset position,
    this.children,
    this.command,
  }) : _position = position;

  Offset get position => _position;
  set position(Offset newPosition) {
    _position = newPosition;
    notifyListeners();
  }

  bool get isSelected => _isSelected;
  set isSelected(bool value) {
    if (_isSelected != value) {
      _isSelected = value;
      notifyListeners();
    }
  }
}

class Window extends ChangeNotifier {
  final String id;
  final String title;
  final Widget content;
  Offset _position;
  Size _size;
  bool _isFocused = true;

  Window({
    required this.id,
    required this.title,
    required this.content,
    Offset position = const Offset(150, 150),
    Size size = const Size(600, 500),
  }) : _position = position, _size = size;

  Offset get position => _position;
  set position(Offset newPosition) {
    _position = newPosition;
    notifyListeners();
  }

  Size get size => _size;
  set size(Size newSize) {
    _size = newSize;
    notifyListeners();
  }

  bool get isFocused => _isFocused;
  set isFocused(bool value) {
    if (_isFocused != value) {
      _isFocused = value;
      notifyListeners();
    }
  }
}

class DesktopViewModel extends ChangeNotifier {
  final List<DesktopItem> _items = [];
  final List<Window> _windows = [];
  DesktopSettings settings = DesktopSettings();
  String? _selectedItemId;

  List<DesktopItem> get items => _items;
  List<Window> get windows => _windows;

  DesktopViewModel() {
    _initializeDesktop();
  }

  void _initializeDesktop() {
    _items.addAll([
      DesktopItem(id: 'app-files', type: DesktopItemType.app, name: 'ファイル管理', icon: Icons.folder_open, position: const Offset(100, 100), command: _getFileManagerCommand()),
      DesktopItem(id: 'app-terminal', type: DesktopItemType.app, name: 'ターミナル', icon: Icons.terminal, position: const Offset(100, 220), command: _getTerminalCommand()),
      DesktopItem(id: 'app-browser', type: DesktopItemType.app, name: 'ブラウザ', icon: Icons.language, position: const Offset(220, 100), command: _getBrowserCommand()),
    ]);
    notifyListeners();
  }

  void selectItem(String? itemId) {
    if (_selectedItemId == itemId) return;

    if (_selectedItemId != null) {
      items.firstWhere((it) => it.id == _selectedItemId).isSelected = false;
    }
    _selectedItemId = itemId;
    if (itemId != null) {
      items.firstWhere((it) => it.id == itemId).isSelected = true;
    }
    // No need to call notifyListeners() here because the item itself will notify.
  }

  void openWindow(Window window) {
    for (var w in _windows) {
      w.isFocused = false;
    }
    _windows.add(window);
    notifyListeners();
  }

  void closeWindow(String id) {
    _windows.removeWhere((w) => w.id == id);
    notifyListeners();
  }

  void focusWindow(String id) {
    final window = _windows.firstWhere((w) => w.id == id);
    _windows.remove(window);
    _windows.add(window); // Move to top
    for (var w in _windows) {
      w.isFocused = (w.id == id);
    }
    // No need to call notifyListeners() here because the window itself will notify.
  }

  Future<void> changeWallpaper() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null && result.files.single.path != null) {
      settings.wallpaperPath = result.files.single.path!;
      notifyListeners();
    }
  }

  void arrangeInGrid() {
    const double startX = 100, startY = 100, spacingX = 120, spacingY = 120;
    const itemsPerRow = 6;
    for (int i = 0; i < _items.length; i++) {
      final row = i ~/ itemsPerRow;
      final col = i % itemsPerRow;
      _items[i].position = Offset(startX + (col * spacingX), startY + (row * spacingY));
    }
    notifyListeners();
  }
}

class DesktopSettings {
  String wallpaperPath = 'assets/wallpaper.png';
  double iconSize = 48.0;
  Color themeColor = const Color(0xffd7c9a7);
  String characterPath = 'assets/character.png';
  bool showCharacter = true;
}

// --- メインエントリーポイント ---
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
    return ChangeNotifierProvider(
      create: (_) => DesktopViewModel(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'SIST OS',
        theme: ThemeData(
          fontFamily: 'Noto Sans JP',
          brightness: Brightness.dark,
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xffd7c9a7), brightness: Brightness.dark),
          useMaterial3: true,
        ),
        home: const DesktopShell(),
      ),
    );
  }
}

class DesktopShell extends StatelessWidget {
  const DesktopShell({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<DesktopViewModel>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Listener(
        onPointerDown: (_) => viewModel.selectItem(null),
        child: GestureDetector(
          onSecondaryTapDown: (details) => _showContextMenu(context, details, viewModel),
          child: Stack(
            children: [
              BackgroundLayer(wallpaperPath: viewModel.settings.wallpaperPath),
              if (viewModel.settings.showCharacter) CharacterLayer(characterPath: viewModel.settings.characterPath),
              
              ...viewModel.items.map((item) => DesktopIcon(item: item)),

              ...viewModel.windows.map((window) => DraggableWindow(window: window)),

              const Positioned(top: 0, left: 0, right: 0, child: Taskbar()),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Widgets ---

class DesktopIcon extends StatelessWidget {
  final DesktopItem item;
  const DesktopIcon({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.read<DesktopViewModel>();
    return ChangeNotifierProvider.value(
      value: item,
      child: Consumer<DesktopItem>(
        builder: (context, item, child) {
          return Positioned(
            left: item.position.dx,
            top: item.position.dy,
            child: GestureDetector(
              onTap: () => viewModel.selectItem(item.id),
              onSecondaryTapDown: (details) => _showContextMenu(context, details, viewModel, item: item),
              onDoubleTap: () => _handleItemDoubleClick(item),
              child: Draggable<DesktopItem>(
                data: item,
                feedback: _DesktopIconWidget(item: item, isDragging: true),
                childWhenDragging: const SizedBox.shrink(),
                onDragEnd: (details) => item.position = details.offset,
                child: _DesktopIconWidget(item: item),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DesktopIconWidget extends StatelessWidget {
  final DesktopItem item;
  final bool isDragging;

  const _DesktopIconWidget({required this.item, this.isDragging = false});

  @override
  Widget build(BuildContext context) {
    final settings = context.read<DesktopViewModel>().settings;
    return Opacity(
      opacity: isDragging ? 0.7 : 1.0,
      child: Container(
        width: 100,
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: item.isSelected ? settings.themeColor.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: item.isSelected ? settings.themeColor : Colors.transparent,
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(item.icon, size: settings.iconSize, color: Colors.white, shadows: const [Shadow(color: Colors.black, blurRadius: 10)]),
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

class DraggableWindow extends StatelessWidget {
  final Window window;
  const DraggableWindow({super.key, required this.window});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.read<DesktopViewModel>();
    return ChangeNotifierProvider.value(
      value: window,
      child: Consumer<Window>(
        builder: (context, window, child) {
          return Positioned(
            left: window.position.dx,
            top: window.position.dy,
            child: GestureDetector(
              onTap: () => viewModel.focusWindow(window.id),
              child: Container(
                width: window.size.width,
                height: window.size.height,
                decoration: BoxDecoration(
                  color: const Color(0xFF1a1816).withOpacity(0.9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: window.isFocused ? context.read<DesktopViewModel>().settings.themeColor : Colors.white.withOpacity(0.2)),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 30, spreadRadius: 5)],
                ),
                child: Column(
                  children: [
                    GestureDetector(
                      onPanUpdate: (details) => window.position += details.delta,
                      child: _WindowHeader(title: window.title, onClose: () => viewModel.closeWindow(window.id)),
                    ),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(12), bottomRight: Radius.circular(12)),
                        child: window.content,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
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
    return Container(
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
          if (onClose != null) IconButton(icon: const Icon(Icons.close, size: 18), onPressed: onClose, splashRadius: 20),
        ],
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
                onPressed: () => Process.run('shutdown', ['-h', 'now']),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Other Widgets (Background, Clock, etc.) ---

class BackgroundLayer extends StatelessWidget {
  final String wallpaperPath;
  const BackgroundLayer({super.key, required this.wallpaperPath});
  
  @override
  Widget build(BuildContext context) {
    final isAsset = wallpaperPath.startsWith('assets/');
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: (isAsset ? AssetImage(wallpaperPath) : FileImage(File(wallpaperPath))) as ImageProvider,
          fit: BoxFit.cover,
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
      right: 0,
      height: MediaQuery.of(context).size.height * 0.8,
      width: MediaQuery.of(context).size.width * 0.4,
      child: Opacity(
        opacity: 0.5,
        child: Image.asset(characterPath, fit: BoxFit.contain),
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
  late Timer _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) => setState(() => _now = DateTime.now()));
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(DateFormat('M月d日(E)', 'ja_JP').format(_now), style: const TextStyle(fontSize: 14)),
        const SizedBox(width: 10),
        Text(DateFormat('HH:mm').format(_now), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

// --- Utility Functions and Dialogs ---

void _showContextMenu(BuildContext context, TapDownDetails details, DesktopViewModel viewModel, {DesktopItem? item}) {
  final overlay = Overlay.of(context);
  OverlayEntry? entry;

  List<Widget> buildMenuItems() {
    if (item != null) {
      return [
        _buildContextMenuItem(Icons.open_in_new, '開く', () => _handleItemDoubleClick(item)),
      ];
    } else {
      return [
        _buildContextMenuItem(Icons.sort, 'アイコンの整列', () => viewModel.arrangeInGrid()),
        _buildContextMenuItem(Icons.wallpaper, '壁紙の変更', () => viewModel.changeWallpaper()),
        _buildContextMenuItem(Icons.settings, '設定', () => _openSettings(context)),
      ];
    }
  }

  entry = OverlayEntry(
    builder: (context) => Stack(
      children: [
        GestureDetector(onTap: () => entry?.remove()),
        Positioned(
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
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: buildMenuItems().map((e) => e).toList()),
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
  overlay.insert(entry);
}

Widget _buildContextMenuItem(IconData icon, String text, VoidCallback onTap) {
  return InkWell(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xffd7c9a7)),
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
  } 
}

Future<void> _launchApp(String? command) async {
  if (command == null || command.isEmpty) return;
  try {
    await Process.start(command, [], runInShell: true, mode: ProcessStartMode.detached);
  } catch (e) {
    // Consider showing an error dialog
    print('Failed to launch app: $e');
  }
}

void _openSettings(BuildContext context) {
  final viewModel = context.read<DesktopViewModel>();
  final windowId = 'settings';
  if (viewModel.windows.any((w) => w.id == windowId)) {
    viewModel.focusWindow(windowId);
    return;
  }
  viewModel.openWindow(Window(
    id: windowId,
    title: '設定',
    content: const _SettingsScreen(),
  ));
}

class _SettingsScreen extends StatelessWidget {
  const _SettingsScreen();

  @override
  Widget build(BuildContext context) {
    // A real settings screen would be more complex
    return const Center(child: Text('設定画面'));
  }
}

// --- Platform-specific command getters ---
String _getFileManagerCommand() => 'nautilus';
String _getTerminalCommand() => 'gnome-terminal';
String _getBrowserCommand() => 'firefox';
