import 'dart:ui';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart'; // 【追加】
import 'dart:async';
import 'package:process_run/process_run.dart'; // 【修正】ドット(.)をコロン(:)に修正

// --- データモデル (変更なし) ---
enum DesktopItemType { app, file, folder }
class DesktopItem {
  String id;
  DesktopItemType type;
  String name;
  IconData icon;
  Offset position;
  List<DesktopItem>? children;
  DesktopItem({ required this.id, required this.type, required this.name, required this.icon, required this.position, this.children });
}

// --- メインエントリーポイント ---
Future<void> main() async { // 【変更】
  WidgetsFlutterBinding.ensureInitialized(); // 【追加】
  await initializeDateFormatting('ja_JP', null); // 【追加】
  runApp(const MementoMoriApp());
}

// --- これ以降のコードは変更ありません ---
class MementoMoriApp extends StatelessWidget {
  const MementoMoriApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Sist OS - Memento Mori',
      theme: ThemeData(
        fontFamily: 'Cinzel',
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xffd7c9a7), brightness: Brightness.dark),
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

class _DesktopShellState extends State<DesktopShell> {
  List<DesktopItem> desktopItems = [
    DesktopItem(id: 'item-1', type: DesktopItemType.app, name: 'ギャラリー', icon: Icons.photo_library, position: const Offset(100, 100)),
    DesktopItem(id: 'item-2', type: DesktopItemType.app, name: 'ミュージック', icon: Icons.music_note, position: const Offset(100, 220)),
    DesktopItem(id: 'item-3', type: DesktopItemType.file, name: 'character_story.txt', icon: Icons.description, position: const Offset(220, 100)),
  ];
  OverlayEntry? _contextMenuEntry;

  void _launchApp(String command) {
    if (command.isEmpty) return;
    try {
      run('$command &', runInShell: true);
    } catch (e) {
      // print('Could not launch $command: $e');
    }
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
            _buildContextMenuItem(Icons.drive_file_rename_outline, '名前の変更', () {}),
            _buildContextMenuItem(Icons.delete, '削除', () {
              setState(() => desktopItems.removeWhere((i) => i.id == item.id));
            }),
          ];
        } else {
          menuItems = [
            _buildContextMenuItem(Icons.sort, '表示順の変更', () {}),
            _buildContextMenuItem(Icons.refresh, 'リフレッシュ', () => setState((){})),
            const _ContextMenuDivider(),
            _buildContextMenuItem(Icons.create_new_folder, '新規フォルダ', () {
               setState(() {
                desktopItems.add(DesktopItem(
                  id: 'folder-${DateTime.now().millisecondsSinceEpoch}',
                  type: DesktopItemType.folder,
                  name: '新しいフォルダ',
                  icon: Icons.folder_special,
                  position: details.localPosition,
                  children: [],
                ));
              });
            }),
            _buildContextMenuItem(Icons.wallpaper, '壁紙の変更', () {}),
          ];
        }
        return Positioned(
          left: details.globalPosition.dx,
          top: details.globalPosition.dy,
          child: Material(
            color: Colors.transparent,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xE61a1816),
                    border: Border.all(color: const Color(0x80d7c9a7)),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: menuItems),
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(children: [
          Icon(icon, size: 20, color: const Color(0xffd7c9a7)),
          const SizedBox(width: 12),
          Text(text, style: const TextStyle(fontSize: 14)),
        ]),
      ),
    );
  }

  void _handleItemDoubleClick(DesktopItem item) {}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Listener(
        onPointerDown: (details) {
          if (details.kind == PointerDeviceKind.mouse && details.buttons == kSecondaryMouseButton) {
          } else {
            _hideContextMenu();
          }
        },
        child: GestureDetector(
          onSecondaryTapDown: (details) => _showContextMenu(context, details),
          child: Stack(
            children: [
              const BackgroundLayer(),
              const CharacterLayer(),
              ..._buildDesktopIcons(),
              Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  BottomNavigation(onAppLaunch: _launchApp, onLogout: () {}),
                ],
              ),
              const TopRightClock(),
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
          onSecondaryTapDown: (details) => _showContextMenu(context, details, item: item),
          onDoubleTap: () => _handleItemDoubleClick(item),
          child: _DesktopIconWidget(item: item),
        ),
      );
      return Draggable<DesktopItem>(
        data: item,
        feedback: _DesktopIconWidget(item: item, isDragging: true),
        childWhenDragging: const SizedBox.shrink(),
        onDragEnd: (details) {
          setState(() {
            final index = desktopItems.indexWhere((i) => i.id == item.id);
            if (index != -1) desktopItems[index].position = details.offset;
          });
        },
        child: DragTarget<DesktopItem>(
          builder: (context, candidateData, rejectedData) => iconWidget,
          onWillAcceptWithDetails: (details) => details.data.id != item.id,
          onAcceptWithDetails: (details) {
            final droppedItem = details.data;
            setState(() {
              desktopItems.add(DesktopItem(
                id: 'folder-${DateTime.now().millisecondsSinceEpoch}',
                type: DesktopItemType.folder,
                name: '新しいフォルダ',
                icon: Icons.folder_special,
                position: item.position,
                children: [item, droppedItem],
              ));
              desktopItems.removeWhere((i) => i.id == item.id || i.id == droppedItem.id);
            });
          },
        ),
      );
    }).toList();
  }
}

class _DesktopIconWidget extends StatelessWidget {
  final DesktopItem item;
  final bool isDragging;
  const _DesktopIconWidget({required this.item, this.isDragging = false});
  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: isDragging ? 0.7 : 1.0,
      child: Container(
        width: 100,
        padding: const EdgeInsets.all(8.0),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(item.icon, size: 48, color: Colors.white, shadows: const [Shadow(color: Colors.black, blurRadius: 10)]),
          const SizedBox(height: 8),
          Text(item.name, style: const TextStyle(fontSize: 12, color: Colors.white, shadows: [Shadow(color: Colors.black, blurRadius: 5)]), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
        ]),
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
  const BackgroundLayer({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(image: AssetImage('assets/wallpaper.png'), fit: BoxFit.cover, colorFilter: ColorFilter.mode(Colors.black54, BlendMode.darken)),
      ),
      child: Container(decoration: BoxDecoration(gradient: RadialGradient(center: Alignment.center, radius: 1.0, colors: [Colors.transparent, Colors.black.withOpacity(0.8)]))),
    );
  }
}

class CharacterLayer extends StatelessWidget {
  const CharacterLayer({super.key});
  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: -50,
      height: MediaQuery.of(context).size.height * 0.95,
      child: Image.asset('assets/character.png', fit: BoxFit.fitHeight, errorBuilder: (context, error, stackTrace) => const SizedBox.shrink()),
    );
  }
}

class BottomNavigation extends StatelessWidget {
  final Function(String) onAppLaunch;
  final VoidCallback onLogout;
  const BottomNavigation({super.key, required this.onAppLaunch, required this.onLogout});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          CustomPaint(
            painter: InkstainPainter(),
            child: ClipPath(
              clipper: InkstainClipper(),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                child: Container(
                  height: 100,
                  width: MediaQuery.of(context).size.width * 0.7,
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                    NavButton(icon: Icons.folder_open, label: 'ファイル', onPressed: () => onAppLaunch('nautilus')),
                    NavButton(icon: Icons.edit_note, label: 'ターミナル', onPressed: () => onAppLaunch('xterm')),
                    NavButton(icon: Icons.language, label: 'ブラウザ', onPressed: () => onAppLaunch('firefox')),
                    NavButton(icon: Icons.settings, label: '設定', onPressed: () => onAppLaunch('gnome-control-center')),
                    NavButton(icon: Icons.logout, label: 'ログアウト', onPressed: onLogout),
                  ]),
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
  const TopRightClock({super.key});
  @override
  State<TopRightClock> createState() => _TopRightClockState();
}

class _TopRightClockState extends State<TopRightClock> {
  late String _timeString;
  late Timer _timer;
  @override
  void initState() {
    super.initState();
    _timeString = DateFormat('HH:mm').format(DateTime.now());
    _timer = Timer.periodic(const Duration(seconds: 1), (t) => _updateTime());
  }
  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }
  void _updateTime() {
    if (mounted) setState(() => _timeString = DateFormat('HH:mm').format(DateTime.now()));
  }
  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 20,
      right: 30,
      child: Text(_timeString, style: const TextStyle(color: Color(0xffd7c9a7), fontSize: 32, fontWeight: FontWeight.w100, shadows: [Shadow(color: Colors.black, blurRadius: 10)])),
    );
  }
}

class NavButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  const NavButton({super.key, required this.icon, required this.label, required this.onPressed});
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
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: _isHovering ? const Color(0xffd7c9a7) : Colors.transparent, width: 2))),
            child: Icon(widget.icon, size: 32, color: _isHovering ? Colors.white : const Color(0xffd7c9a7)),
          ),
          const SizedBox(height: 4),
          Text(widget.label, style: TextStyle(fontSize: 12, color: _isHovering ? Colors.white : const Color(0xffd7c9a7))),
        ]),
      ),
    );
  }
}

class InkstainPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xB31a1816)..style = PaintingStyle.fill;
    final borderPaint = Paint()..color = const Color(0x80d7c9a7)..strokeWidth = 1.5..style = PaintingStyle.stroke;
    final path = _getInkstainPath(size);
    canvas.drawPath(path, paint);
    canvas.drawPath(path, borderPaint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class InkstainClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) => _getInkstainPath(size);
  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

Path _getInkstainPath(Size size) {
  final path = Path();
  final w = size.width;
  final h = size.height;
  path.moveTo(w * 0.05, h * 0.2);
  path.quadraticBezierTo(w * 0.1, h * 0.1, w * 0.2, h * 0.3);
  path.quadraticBezierTo(w * 0.3, h * 0.8, w * 0.5, h * 0.6);
  path.quadraticBezierTo(w * 0.7, h * 0.3, w * 0.8, h * 0.5);
  path.quadraticBezierTo(w * 0.95, h * 0.9, w * 0.9, h * 0.2);
  path.quadraticBezierTo(w * 0.85, -h * 0.1, w * 0.7, h * 0.1);
  path.quadraticBezierTo(w * 0.5, h * 0.5, w * 0.3, h * 0.2);
  path.quadraticBezierTo(w * 0.1, -h * 0.2, w * 0.05, h * 0.2);
  return path;
}