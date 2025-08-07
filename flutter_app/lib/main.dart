import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const TerminalApp());
}

class TerminalApp extends StatelessWidget {
  const TerminalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SIST Terminal',
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.grey[900],
        scaffoldBackgroundColor: Colors.grey[850],
        fontFamily: 'KTEGAKI',
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white70),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.grey[900],
          foregroundColor: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey[700],
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey[900],
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
          hintStyle: TextStyle(color: Colors.white54),
        ),
      ),
      home: const TerminalScreen(),
    );
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
  void initState() {
    super.initState();
    _loadFont();
  }

  Future<void> _loadFont() async {
    await FontLoader('KTEGAKI').load();
  }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset(
              'assets/wallpaper.png',
              fit: BoxFit.cover,
            ),
          ),
          Column(
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
                  color: Colors.black.withAlpha((255 * 0.7).round()), // Semi-transparent background
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
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

String _getUserHome() {
  return Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'] ?? '.';
}