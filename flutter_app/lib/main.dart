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
      title: 'Terminal',
      theme: ThemeData.dark(),
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
      child: Scaffold(
        body: Column(
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
      ),
    );
  }
}

String _getUserHome() {
  return Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'] ?? '.';
}