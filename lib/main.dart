
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:window_manager/window_manager.dart';
import 'package:provider/provider.dart';

OverlayEntry? _contextMenuEntry;

void _hideContextMenu() {
  _contextMenuEntry?.remove();
  _contextMenuEntry = null;
}

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
    _loadDesktopFiles();
  }

  void _initializeDesktop() {
    _items.addAll([
      DesktopItem(id: 'app-files', type: DesktopItemType.app, name: 'ファイル管理', icon: Icons.folder_open, position: const Offset(100, 100), command: _getFileManagerCommand()),
      DesktopItem(id: 'app-terminal', type: DesktopItemType.app, name: 'ターミナル', icon: Icons.terminal, position: const Offset(100, 220), command: _getTerminalCommand()),
      DesktopItem(id: 'app-browser', type: DesktopItemType.app, name: 'ブラウザ', icon: Icons.language, position: const Offset(220, 100), command: _getBrowserCommand()),
    ]);
    notifyListeners();
  }

  Future<void> _loadDesktopFiles() async {
    try {
      final desktopPath = '${_getUserHome()}/Desktop';
      final directory = Directory(desktopPath);
      if (!await directory.exists()) {
        // Desktop directory may not exist, which is fine.
        return;
      }

      final files = await directory.list().toList();
      final desktopItems = files.map((file) {
        final type = file is File ? DesktopItemType.file : DesktopItemType.folder;
        final name = file.path.split(Platform.pathSeparator).last;
        return DesktopItem(
          id: file.path, // Use path as a unique ID
          type: type,
          name: name,
          icon: type == DesktopItemType.folder ? Icons.folder : Icons.article,
          position: const Offset(0, 0), // Position will be set by arrangeInGrid
          command: file.path,
        );
      }).toList();

      _items.addAll(desktopItems);
      arrangeInGrid(); // Arrange all items nicely
    } catch (e) {
      // Silently ignore errors, e.g. permission errors
    }
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
      body: GestureDetector(
        onTap: () {
          viewModel.selectItem(null);
          _hideContextMenu();
        },
        onSecondaryTapDown: (details) => _showContextMenu(context, details.globalPosition, viewModel),
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
              onSecondaryTapDown: (details) {
                viewModel.selectItem(item.id);
                _showContextMenu(context, details.globalPosition, viewModel, item: item);
              },
              onDoubleTap: () => _handleItemDoubleClick(context, item),
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
          color: item.isSelected ? settings.themeColor.withAlpha(51) : Colors.transparent,
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
                  color: const Color(0xFF1a1816).withAlpha(230),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: window.isFocused ? context.read<DesktopViewModel>().settings.themeColor : Colors.white.withAlpha(51)),
                  boxShadow: [BoxShadow(color: Colors.black.withAlpha(128), blurRadius: 30, spreadRadius: 5)],
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
    final viewModel = context.watch<DesktopViewModel>();
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: 50,
          color: Colors.black.withAlpha(77),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              const Text('SIST', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xffd7c9a7))),
              const SizedBox(width: 20),
              Expanded(
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: viewModel.windows.length,
                  itemBuilder: (context, index) {
                    final window = viewModel.windows[index];
                    return TaskbarItem(window: window, onTap: () => viewModel.focusWindow(window.id));
                  },
                ),
              ),
              const TopRightClock(),
              const SizedBox(width: 20),
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

class TaskbarItem extends StatelessWidget {
  final Window window;
  final VoidCallback onTap;

  const TaskbarItem({super.key, required this.window, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        decoration: BoxDecoration(
          color: window.isFocused ? Colors.white.withAlpha(51) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            window.title,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            overflow: TextOverflow.ellipsis,
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

void _showContextMenu(BuildContext context, Offset position, DesktopViewModel viewModel, {DesktopItem? item}) {
  _hideContextMenu(); // Ensure old menu is gone
  final overlay = Overlay.of(context);

  List<Widget> buildMenuItems() {
    if (item != null) {
      return [
        _buildContextMenuItem(Icons.open_in_new, '開く', () {
          _handleItemDoubleClick(context, item);
          _hideContextMenu();
        }),
        // Add more item-specific actions here if needed
      ];
    } else {
      return [
        _buildContextMenuItem(Icons.sort, 'アイコンの整列', () {
          viewModel.arrangeInGrid();
          _hideContextMenu();
        }),
        _buildContextMenuItem(Icons.wallpaper, '壁紙の変更', () {
          viewModel.changeWallpaper();
          _hideContextMenu();
        }),
        _buildContextMenuItem(Icons.settings, '設定', () {
          _openSettings(context);
          _hideContextMenu();
        }),
      ];
    }
  }

  _contextMenuEntry = OverlayEntry(
    builder: (ctx) => Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: _hideContextMenu,
            onSecondaryTapDown: (_) => _hideContextMenu(),
            child: Container(color: Colors.transparent),
          ),
        ),
        Positioned(
          left: position.dx,
          top: position.dy,
          child: Material(
            color: Colors.transparent,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(204),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: buildMenuItems(),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
  overlay.insert(_contextMenuEntry!);
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

void _handleItemDoubleClick(BuildContext context, DesktopItem item) {
  final viewModel = context.read<DesktopViewModel>();
  if (item.id == 'app-terminal') {
    // Open the custom terminal window
    final windowId = 'app-window-terminal';
    if (viewModel.windows.any((w) => w.id == windowId)) {
      viewModel.focusWindow(windowId);
      return;
    }
    viewModel.openWindow(Window(
      id: windowId,
      title: 'ターミナル',
      content: const TerminalScreen(),
    ));
  } else if (item.type == DesktopItemType.app) {
    // Launch external apps
    _launchApp(item.command);
  } else {
    // Handle file/folder double clicks (e.g., open with default app)
    _launchApp(item.command);
  }
}

Future<void> _launchApp(String? command) async {
  if (command == null || command.isEmpty) return;
  try {
    if (Platform.isWindows) {
      await Process.start(command, [], runInShell: true);
    } else {
      await Process.start(command, [], runInShell: true, mode: ProcessStartMode.detached);
    }
  } catch (e) {
    // Consider showing an error dialog
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

class TerminalScreen extends StatefulWidget {
  const TerminalScreen({super.key});

  @override
  State<TerminalScreen> createState() => _TerminalScreenState();
}

class _TerminalScreenState extends State<TerminalScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  final List<String> _output = [];
  final List<String> _history = [];
  int _historyIndex = 0;

  // Command templates
  final List<Map<String, String>> _templates = [
    {'name': 'Update packages', 'command': 'sudo apt update && sudo apt upgrade -y'},
    {'name': 'Install package', 'command': 'sudo apt install '},
    {'name': 'List files', 'command': 'ls -la'},
    {'name': 'Show disk space', 'command': 'df -h'},
  ];

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _runCommand(String command) {
    if (command.isEmpty) return;

    setState(() {
      _output.add('> $command');
      if (_history.isEmpty || _history.last != command) {
        _history.add(command);
      }
      _historyIndex = _history.length;
    });

    // Run command in shell
    final shell = Platform.isWindows ? 'cmd' : 'bash';
    final args = Platform.isWindows ? ['/c', command] : ['-c', command];

    Process.start(shell, args, workingDirectory: _getUserHome(), runInShell: true).then((process) {
      process.stdout.transform(utf8.decoder).listen((data) {
        setState(() {
          _output.addAll(data.trim().split('\n'));
          _scrollToBottom();
        });
      });
      process.stderr.transform(utf8.decoder).listen((data) {
        setState(() {
          _output.addAll(data.trim().split('\n'));
          _scrollToBottom();
        });
      });
    }).catchError((e) {
      setState(() {
        _output.add('Error: $e');
        _scrollToBottom();
      });
    });

    _controller.clear();
    _focusNode.requestFocus();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  void _navigateHistory(bool up) {
    if (_history.isEmpty) return;
    setState(() {
      if (up) {
        if (_historyIndex > 0) _historyIndex--;
      } else {
        if (_historyIndex < _history.length - 1) _historyIndex++;
      }
      _controller.text = _history[_historyIndex];
      _controller.selection = TextSelection.fromPosition(TextPosition(offset: _controller.text.length));
    });
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _focusNode,
      onKeyEvent: (event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
            _navigateHistory(true);
          } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
            _navigateHistory(false);
          }
        }
      },
      child: Column(
        children: [
          // Template buttons
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Wrap(
              spacing: 8.0,
              runSpacing: 4.0,
              children: _templates.map((template) {
                return ElevatedButton(
                  onPressed: () {
                    _controller.text = template['command']!;
                    _focusNode.requestFocus();
                    _controller.selection = TextSelection.fromPosition(TextPosition(offset: _controller.text.length));
                  },
                  child: Text(template['name']!),
                );
              }).toList(),
            ),
          ),
          // Terminal output
          Expanded(
            child: Container(
              color: Colors.black,
              width: double.infinity,
              padding: const EdgeInsets.all(8.0),
              child: ListView.builder(
                controller: _scrollController,
                itemCount: _output.length,
                itemBuilder: (context, index) {
                  return Text(
                    _output[index],
                    style: const TextStyle(fontFamily: 'monospace', color: Colors.white, fontSize: 12),
                  );
                },
              ),
            ),
          ),
          // Input field
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _controller,
              onSubmitted: _runCommand,
              autofocus: true,
              style: const TextStyle(fontFamily: 'monospace', color: Colors.white),
              decoration: const InputDecoration(
                prefixText: '> ',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- Platform-specific command getters ---
// Updated for better cross-platform support, with Windows as a priority
String _getFileManagerCommand() {
  if (Platform.isWindows) return 'explorer';
  if (Platform.isMacOS) return 'open .';
  return 'nautilus'; // Linux fallback
}

String _getTerminalCommand() {
  if (Platform.isWindows) return 'wt'; // Windows Terminal, or 'cmd'
  if (Platform.isMacOS) return 'open -a Terminal';
  return 'gnome-terminal'; // Linux fallback
}

String _getBrowserCommand() {
  if (Platform.isWindows) return 'start chrome'; // Tries to open chrome
  if (Platform.isMacOS) return 'open -a "Google Chrome"';
  return 'firefox'; // Linux fallback
}

String _getUserHome() {
  return Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'] ?? '.';
}
