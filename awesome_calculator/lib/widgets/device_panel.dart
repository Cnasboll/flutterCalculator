import 'dart:async';
import 'package:awesome_calculator/shql/engine/cancellation_token.dart';
import 'package:awesome_calculator/shql/execution/runtime.dart';
import 'package:awesome_calculator/shql/parser/constants_set.dart';
import 'package:awesome_calculator/widgets/post_it_note.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'steampunk_keyboard.dart';
import 'cash_register_display.dart';
import 'terminal_display.dart';
import 'package:awesome_calculator/shql/engine/engine.dart';
import 'package:awesome_calculator/utils/sound_manager.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

/// A retro-styled computer terminal with a steampunk mechanical keyboard.
///
/// Features:
/// - Green CRT-style terminal display with blinking cursor
/// - Full ASCII keyboard with shift support and drum rotation animations
/// - Command history navigation (up/down arrows)
/// - Multi-line input support (SHIFT-ENTER for soft returns)
/// - Click-to-position cursor placement
/// - Physical and virtual keyboard synchronization
class AncientComputer extends StatefulWidget {
  const AncientComputer({super.key});

  @override
  State<AncientComputer> createState() => _AncientComputerState();
}

class _AncientComputerState extends State<AncientComputer>
    with SingleTickerProviderStateMixin {
  late CancellationToken _cancellationToken;
  bool _isExecuting = false;

  Future<void> _copyAllShqlAssetsToExternalStorage() async {
    try {
      // List all .shql files in assets manually (since Flutter can't list assets at runtime)
      final assetFiles = [
        'hello_world.shql',
        'hello_name.shql',
        // Add more .shql files here as you add them to assets
      ];
      Directory extDir = Platform.isAndroid
          ? Directory('/storage/emulated/0/Download')
          : await getApplicationDocumentsDirectory();
      for (final filename in assetFiles) {
        final data = await rootBundle.loadString('assets/shql/$filename');
        final file = File('${extDir.path}/$filename');
        await file.writeAsString(data);
      }
    } catch (e) {
      // Optionally print or handle error
    }
  }

  Future<void> _handleLoadPressed() async {
    try {
      Directory extDir = Platform.isAndroid
          ? Directory('/storage/emulated/0/Download')
          : await getApplicationDocumentsDirectory();
      final result = await FilePicker.platform.pickFiles(
        initialDirectory: extDir.path,
        type: FileType.custom,
        allowedExtensions: ['shql'],
      );
      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final contents = await file.readAsString();
        setState(() {
          final promptLength = _readlinePrompt?.length ?? _promptSymbol.length;
          final inputStart = _currentPromptPosition + promptLength;
          _terminalText = _terminalText.substring(0, inputStart) + contents;
          _cursorPosition = _terminalText.length;
        });
      }
    } catch (e) {
      terminalPrint('LOAD ERROR: $e');
    }
  }

  void _printStartupBanner() {
    setState(() {
      // Clear terminal and print banner
      _terminalText = '';
      _cursorPosition = 0;
      _currentPromptPosition = 0;
      terminalPrint('SHQL v 3.0');
      showPrompt();
    });
  }

  void resetEngine() {
    setState(() {
      constantsSet = Runtime.prepareConstantsSet();
      runtime = Runtime.prepareRuntime(constantsSet);
      runtime.readlineFunction = () async => await readline();

      runtime.printFunction = (p1) => terminalPrint(p1.toString());

      // runtime.setNullaryFunction("READLINE", () async => await readline());
    });
    _printStartupBanner();
  }

  late ConstantsSet constantsSet;
  late Runtime runtime;
  // Constants
  static const String _promptSymbol = '> ';
  static const int _tabSpaces = 4;
  static const Duration _cursorBlinkDuration = Duration(milliseconds: 530);
  static const Duration _keyPressDuration = Duration(milliseconds: 150);

  // Terminal state
  String _terminalText = _promptSymbol;
  int _cursorPosition = _promptSymbol.length;
  int _currentPromptPosition =
      0; // Position of the current prompt in _terminalText
  final List<String> _commandHistory = [];
  int _historyIndex = -1;
  String _currentInput = '';

  // Terminal I/O state
  bool _waitingForInput = false;
  String? _readlinePrompt;
  void Function(String)? _readlineCallback;

  static const int maxWheels = 12;
  // Cash register display
  String _displayValue = 'NULL'.padLeft(maxWheels, ' ');

  // UI state
  String? _pressedKey;
  bool _showCursor = true;
  late AnimationController _cursorController;

  // Keyboard state
  bool _virtualShiftToggled = false;
  bool _physicalShiftPressed = false;
  bool get _shiftPressed => _virtualShiftToggled || _physicalShiftPressed;

  final FocusNode _focusNode = FocusNode();

  // Define keyboard layout - calculator-optimized (all calc symbols unshifted, QWERTY preserved)
  final List<List<String>> _keyboardLayout = [
    ['SIN', 'COS', 'TAN', 'ASIN', 'ACOS', 'ATAN', 'SQRT', 'EXP', 'LOG'],
    ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '.', '(', ')'],
    ['+', '-', '*', '/', '^', '%', '=', '<', '>', '!', '&', '|', '~'],
    ['TAB', 'q', 'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p', '[', ']'],
    ['a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l', ';', '\'', '\\'],
    ['z', 'x', 'c', 'v', 'b', 'n', 'm', ',', '.', '/', 'ENTER'],
    ['SHIFT', 'SPACE', 'BACK', 'DEL', '←', '↑', '↓', '→'],
    ['BREAK', 'LOAD', 'RESET'],
  ];

  // Shift mappings for characters
  final Map<String, String> _shiftMap = {
    '`': '~', '1': '!', '2': '@', '3': '#', '4': '\$', '5': '%',
    '6': '^', '7': '&', '8': '*', '9': '(', '0': ')', '-': '_', '=': '+',
    '[': '{', ']': '}', '\\': '|', ';': ':', '\'': '"',
    ',': '<', '.': '>', '/': '?',
    'a': 'A', 'b': 'B', 'c': 'C', 'd': 'D', 'e': 'E', 'f': 'F', 'g': 'G',
    'h': 'H', 'i': 'I', 'j': 'J', 'k': 'K', 'l': 'L', 'm': 'M', 'n': 'N',
    'o': 'O', 'p': 'P', 'q': 'Q', 'r': 'R', 's': 'S', 't': 'T', 'u': 'U',
    'v': 'V', 'w': 'W', 'x': 'X', 'y': 'Y', 'z': 'Z',
    'ENTER': '↵', // Soft return / line break
    // Arrow keys don't shift
  };

  // Function names that insert with parentheses
  final Set<String> _functionNames = {
    'SIN',
    'COS',
    'TAN',
    'ASIN',
    'ACOS',
    'ATAN',
    'SQRT',
    'EXP',
    'LOG',
  };

  @override
  void initState() {
    super.initState();
    _cancellationToken = CancellationToken();
    _copyAllShqlAssetsToExternalStorage();
    resetEngine();
    _cursorController = AnimationController(
      vsync: this,
      duration: _cursorBlinkDuration,
    )..repeat(reverse: true);

    _cursorController.addListener(() {
      setState(() {
        _showCursor = _cursorController.value > 0.5;
      });
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });

    _printStartupBanner();
    // Initialize display to show NULL for empty input
    _evaluateCurrentInput();
  }

  @override
  void dispose() {
    _cursorController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  /// Print text to terminal (appends to display, doesn't create new prompt)
  void terminalPrint(String text) {
    setState(() {
      // Move cursor to end and append text with newline
      _terminalText += '\n$text';
      _cursorPosition = _terminalText.length;
    });
  }

  /// Request input from user with an optional prompt
  /// Returns a Future that completes when user presses ENTER
  Future<String> readline([String? prompt]) async {
    final completer = Completer<String>();

    // If the execution is cancelled while waiting for input, complete immediately.
    if (await _cancellationToken.check()) {
      completer.complete('');
      return completer.future;
    }

    final subscription = Stream.periodic(const Duration(milliseconds: 100))
        .listen((_) async {
          if (await _cancellationToken.check()) {
            if (!completer.isCompleted) {
              completer.complete('');
            }
          }
        });

    completer.future.whenComplete(() {
      subscription.cancel();
    });

    setState(() {
      _waitingForInput = true;
      _readlinePrompt = prompt ?? "";
      _readlineCallback = (String input) {
        if (!completer.isCompleted) {
          completer.complete(input);
        }
        _waitingForInput = false;
        _readlinePrompt = null;
        _readlineCallback = null;
      };

      // Add prompt if provided, otherwise just position for input
      if (prompt != null && prompt.isNotEmpty) {
        _terminalText += '\n$prompt';
      } else {
        _terminalText += '\n';
      }
      _currentPromptPosition = _terminalText.length;
      _cursorPosition = _terminalText.length;
    });

    return completer.future;
  }

  /// Get the current input text (after the current prompt, may be multi-line)
  String _getCurrentLine() {
    final promptLength = _readlinePrompt?.length ?? _promptSymbol.length;
    final inputStart = _currentPromptPosition + promptLength;
    return _terminalText.substring(inputStart).trim();
  }

  /// Replace current input with text from history (handles multi-line)
  void _replaceCurrentLine(String text) {
    final promptLength = _readlinePrompt?.length ?? _promptSymbol.length;
    final inputStart = _currentPromptPosition + promptLength;
    _terminalText = _terminalText.substring(0, inputStart) + text;
    _cursorPosition = _terminalText.length;
  }

  /// Navigate command history (up/down arrows)
  void _navigateHistory(bool isUp) {
    if (_commandHistory.isEmpty) return;

    // Save current input when first navigating history
    if (_historyIndex == -1) {
      _currentInput = _getCurrentLine();
    }

    if (isUp) {
      // Move backward in history (older commands)
      if (_historyIndex < _commandHistory.length - 1) {
        _historyIndex++;
        final historyCommand =
            _commandHistory[_commandHistory.length - 1 - _historyIndex];
        _replaceCurrentLine(historyCommand);
      }
    } else {
      // Move forward in history (newer commands)
      if (_historyIndex > 0) {
        _historyIndex--;
        final historyCommand =
            _commandHistory[_commandHistory.length - 1 - _historyIndex];
        _replaceCurrentLine(historyCommand);
      } else if (_historyIndex == 0) {
        // Restore current input
        _historyIndex = -1;
        _replaceCurrentLine(_currentInput);
      }
    }
  }

  (String, String) _formatResult(dynamic result) {
    final String padding = ' ';

    if (result is UserFunction) {
      return ('USER FUNCTION ${result.name}', padding);
    }

    // Format result based on type
    if (result == null) {
      return ('NULL', padding);
    }

    if (result is int) {
      return (result.toString(), '0');
    }

    if (result is double) {
      if (result.isNaN) {
        return ('ERROR', padding);
      }
      if (result.isInfinite) {
        return (result.isNegative ? '-INFINITY' : 'INFINITY', padding);
      } // Format with up to 6 decimal places
      return (
        result
            .toStringAsFixed(6)
            .replaceAll(RegExp(r'0+$'), '')
            .replaceAll(RegExp(r'\.$'), ''),
        '0',
      );
    }

    if (result is String) {
      return (result, padding);
    }

    return (result.toString(), padding);
  }

  /// Evaluate the current input and update the cash register display
  void _evaluateCurrentInput() {
    final inputStart = _currentPromptPosition + _promptSymbol.length;
    final currentInput = _terminalText.substring(inputStart).trim();

    if (currentInput.isEmpty) {
      final (formatted, padding) = _formatResult(null);
      setState(() {
        _displayValue = formatted.padLeft(maxWheels, padding);
      });
      return;
    }

    Engine.calculate(
          currentInput,
          runtime: runtime.readOnlyChild(),
          constantsSet: constantsSet,
        )
        .then((result) {
          if (!mounted) return;
          final (formatted, padding) = _formatResult(result);
          setState(() {
            _displayValue = formatted.padLeft(maxWheels, padding);
          });
        })
        .catchError((e) {
          // Keep previous valid result
          if (!mounted) return;
          print(e);
        });
  }

  /// Handle up arrow: command history on last line, cursor movement otherwise
  void _handleArrowUp() {
    final isInInputSection = _cursorPosition >= _currentPromptPosition;

    if (!isInInputSection) return;

    // Don't navigate history if waiting for readline input
    if (_waitingForInput) {
      return; // Just stay in place, don't allow history navigation during readline
    }

    // Check if we're on the first line of input
    final promptLength = _readlinePrompt?.length ?? _promptSymbol.length;
    final inputStart = _currentPromptPosition + promptLength;
    final firstNewlineInInput = _terminalText.indexOf('\n', inputStart);
    final isOnFirstLine =
        firstNewlineInInput == -1 || _cursorPosition <= firstNewlineInInput;

    if (isOnFirstLine) {
      // On first line: navigate history
      _navigateHistory(true);
      _evaluateCurrentInput();
    } else {
      // Not on first line: move cursor up within current input
      int currentLineStart =
          _terminalText.lastIndexOf('\n', _cursorPosition - 1) + 1;
      int prevLineStart =
          _terminalText.lastIndexOf('\n', currentLineStart - 2) + 1;

      // Make sure we don't go before the prompt
      if (prevLineStart < inputStart) {
        prevLineStart = inputStart;
      }

      int offsetInLine = _cursorPosition - currentLineStart;
      _cursorPosition = prevLineStart + offsetInLine;

      int prevLineEnd = currentLineStart - 1;
      if (_cursorPosition > prevLineEnd) _cursorPosition = prevLineEnd;
    }
  }

  void showPrompt() {
    setState(() {
      _terminalText += '\n$_promptSymbol';
      _currentPromptPosition = _terminalText.length - _promptSymbol.length;
      _cursorPosition = _terminalText.length;
    });
  }

  /// Handle down arrow: command history on last line, cursor movement otherwise
  void _handleArrowDown() {
    final isInInputSection = _cursorPosition >= _currentPromptPosition;

    if (!isInInputSection) return;

    // Don't navigate history if waiting for readline input
    if (_waitingForInput) {
      return; // Just stay in place, don't allow history navigation during readline
    }

    // Check if there's a next line in the current input
    final nextNewline = _terminalText.indexOf('\n', _cursorPosition);
    final isOnLastLine = nextNewline == -1;

    if (isOnLastLine) {
      // On last line: navigate history
      _navigateHistory(false);
      _evaluateCurrentInput();
    } else {
      // Not on last line: move cursor down within current input
      int currentLineStart =
          _terminalText.lastIndexOf('\n', _cursorPosition - 1) + 1;
      int nextLineStart = nextNewline + 1;
      int offsetInLine = _cursorPosition - currentLineStart;
      _cursorPosition = nextLineStart + offsetInLine;

      int nextLineEnd = _terminalText.indexOf('\n', nextLineStart);
      if (nextLineEnd == -1) nextLineEnd = _terminalText.length;
      if (_cursorPosition > nextLineEnd) _cursorPosition = nextLineEnd;
    }
  }

  void _handleKeyPress(String key) async {
    // Play typewriter sound for key press
    SoundManager().playSound('sounds/typewriter_key.wav');

    if (key == 'ENTER' && !_shiftPressed) {
      final promptLength = _readlinePrompt?.length ?? _promptSymbol.length;
      final inputStart = _currentPromptPosition + promptLength;
      if (_waitingForInput && _readlineCallback != null) {
        _readlineCallback!(_terminalText.substring(_currentPromptPosition));
      } else {
        final currentInput = _terminalText.substring(inputStart).trim();
        if (currentInput.isNotEmpty) {
          setState(() {
            _commandHistory.add(currentInput);
            _historyIndex = -1;
            _currentInput = '';
            _isExecuting = true;
            _cancellationToken.reset();
          });

          await Future.delayed(Duration.zero);

          try {
            final result = await Engine.execute(
              currentInput,
              runtime: runtime,
              constantsSet: constantsSet,
              cancellationToken: _cancellationToken,
            );
            if (!mounted) return;
            final (formatted, padding) = _formatResult(result);
            terminalPrint(formatted);
          } catch (e) {
            if (!mounted) return;
            terminalPrint(e.toString());
          } finally {
            if (!mounted) return;
            setState(() {
              _isExecuting = false;
            });
            showPrompt();
          }
        } else {
          showPrompt();
        }
      }
      return;
    }

    setState(() {
      _pressedKey = key;

      // Handle arrow keys for cursor movement
      if (key == '←') {
        if (_cursorPosition > 0) {
          _cursorPosition--;
          // Don't allow cursor before the current prompt
          final promptLength = _readlinePrompt?.length ?? _promptSymbol.length;
          final promptEnd = _currentPromptPosition + promptLength;
          if (_cursorPosition < promptEnd) {
            _cursorPosition = promptEnd;
          }
        }
        return;
      } else if (key == '→') {
        if (_cursorPosition < _terminalText.length) {
          _cursorPosition++;
        }
        return;
      } else if (key == '↑') {
        _handleArrowUp();
        return;
      } else if (key == '↓') {
        _handleArrowDown();
        return;
      } else if (key == 'LOAD') {
        _handleLoadPressed();
        return;
      } else if (key == 'RESET') {
        resetEngine();
        return;
      } else if (key == 'BREAK') {
        if (_isExecuting) {
          _cancellationToken.cancel();
        }
        return;
      }

      if (key == 'SHIFT') {
        if (!_physicalShiftPressed) {
          _virtualShiftToggled = !_virtualShiftToggled;
        }
      } else if (key == 'TAB') {
        _terminalText =
            _terminalText.substring(0, _cursorPosition) +
            ' ' * _tabSpaces +
            _terminalText.substring(_cursorPosition);
        _cursorPosition += _tabSpaces;
      } else if (key == 'ENTER') {
        if (_shiftPressed) {
          // SHIFT-ENTER: Soft return (line break without prompt)
          _terminalText =
              '${_terminalText.substring(0, _cursorPosition)}\n${_terminalText.substring(_cursorPosition)}';
          _cursorPosition += 1;
        }
      } else if (key == 'BACK') {
        final promptLength = _readlinePrompt?.length ?? _promptSymbol.length;
        final promptEnd = _currentPromptPosition + promptLength;
        if (_cursorPosition > promptEnd) {
          _terminalText =
              _terminalText.substring(0, _cursorPosition - 1) +
              _terminalText.substring(_cursorPosition);
          _cursorPosition--;
        }
      } else if (key == 'DEL') {
        final promptLength = _readlinePrompt?.length ?? _promptSymbol.length;
        final promptEnd = _currentPromptPosition + promptLength;
        if (_cursorPosition >= promptEnd &&
            _cursorPosition < _terminalText.length) {
          _terminalText =
              _terminalText.substring(0, _cursorPosition) +
              _terminalText.substring(_cursorPosition + 1);
        }
      } else if (key == 'SPACE') {
        _terminalText =
            _terminalText.substring(0, _cursorPosition) +
            ' ' +
            _terminalText.substring(_cursorPosition);
        _cursorPosition++;
      } else {
        // Regular character input
        String char = key;
        if (_shiftPressed) {
          char = _shiftMap[key.toLowerCase()] ?? key.toUpperCase();
        }

        // Insert parentheses for function names
        if (_functionNames.contains(char)) {
          char += '()';
          _terminalText =
              _terminalText.substring(0, _cursorPosition) +
              char +
              _terminalText.substring(_cursorPosition);
          _cursorPosition += char.length - 1; // Position cursor inside ()
        } else {
          _terminalText =
              _terminalText.substring(0, _cursorPosition) +
              char +
              _terminalText.substring(_cursorPosition);
          _cursorPosition += char.length;
        }
      }

      // After any text modification, evaluate the current input for the cash register display
      _evaluateCurrentInput();

      // Reset one-time shift toggle after use
      if (_virtualShiftToggled && key != 'SHIFT') {
        _virtualShiftToggled = false;
      }

      // Reset pressed key visual feedback
      Future.delayed(_keyPressDuration, () {
        if (mounted) {
          setState(() {
            _pressedKey = null;
          });
        }
      });
    });
  }

  /// Handle physical keyboard events
  void _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      // Play typewriter sound for physical keyboard
      SoundManager().playSound('sounds/typewriter_key.wav');

      String? key;

      // Handle arrow keys for cursor movement
      if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        _handleKeyPress('←');
        return;
      } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
        _handleKeyPress('→');
        return;
      } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        _handleKeyPress('↑');
        return;
      } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        _handleKeyPress('↓');
        return;
      }

      // Map physical keyboard keys to our virtual keyboard
      if (event.logicalKey == LogicalKeyboardKey.tab) {
        key = 'TAB';
      } else if (event.logicalKey == LogicalKeyboardKey.space) {
        key = 'SPACE';
      } else if (event.logicalKey == LogicalKeyboardKey.enter) {
        key = 'ENTER';
      } else if (event.logicalKey == LogicalKeyboardKey.backspace) {
        key = 'BACK';
      } else if (event.logicalKey == LogicalKeyboardKey.delete) {
        key = 'DEL';
      } else {
        final label = event.logicalKey.keyLabel;
        if (label.length == 1) {
          final code = label.codeUnitAt(0);
          // Accept all printable ASCII characters
          if (code >= 32 && code <= 126) {
            // The physical keyboard sends the actual character already shifted
            // So we need to map back to the base key
            if (code >= 97 && code <= 122) {
              // a-z (lowercase)
              key = label;
            } else if (code >= 65 && code <= 90) {
              // A-Z (uppercase from shift)
              key = label.toLowerCase(); // Map back to base key
            } else {
              // For symbols, the physical keyboard sends the shifted version
              // Find which base key produces this character
              final baseKey = _shiftMap.entries
                  .firstWhere(
                    (entry) => entry.value == label,
                    orElse: () => MapEntry(label, label),
                  )
                  .key;
              key = baseKey;
            }
          }
        }
      }

      if (key != null) {
        _handleKeyPress(key);
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _focusNode.requestFocus(),
      child: KeyboardListener(
        focusNode: _focusNode,
        onKeyEvent: (KeyEvent event) {
          if (event is KeyDownEvent) {
            if (event.logicalKey == LogicalKeyboardKey.shiftLeft ||
                event.logicalKey == LogicalKeyboardKey.shiftRight) {
              setState(() {
                _physicalShiftPressed = true;
                _virtualShiftToggled = false;
              });
              return;
            }
          } else if (event is KeyUpEvent) {
            if (event.logicalKey == LogicalKeyboardKey.shiftLeft ||
                event.logicalKey == LogicalKeyboardKey.shiftRight) {
              setState(() {
                _physicalShiftPressed = false;
              });
              return;
            }
          }

          _handleKeyEvent(event);
        },
        child: Container(
          width: double.infinity,
          height: double.infinity,
          color: const Color(0xFF2B2B2B),
          child: Stack(
            children: [
              Column(
                children: [
                  // Terminal Display
                  TerminalDisplay(
                    terminalText: _terminalText,
                    cursorPosition: _cursorPosition,
                    showCursor: _showCursor,
                    currentPromptPosition: _currentPromptPosition,
                    promptSymbol: _promptSymbol,
                    onTapRequest: () => _focusNode.requestFocus(),
                    onCursorPositionChanged: (newPosition) {
                      setState(() {
                        _cursorPosition = newPosition;
                      });
                    },
                  ),

                  // Cash Register Display
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: CashRegisterDisplay(
                        value: _displayValue,
                        maxWheels: maxWheels,
                      ),
                    ),
                  ),

                  // Keyboard
                  SteampunkKeyboard(
                    keyboardLayout: _keyboardLayout,
                    shiftMap: _shiftMap,
                    pressedKey: _pressedKey,
                    isShifted: _shiftPressed,
                    virtualShiftToggled: _virtualShiftToggled,
                    physicalShiftPressed: _physicalShiftPressed,
                    onKeyPress: _handleKeyPress,
                    isExecuting: _isExecuting,
                  ),
                ],
              ),
              // Post-it note overlapping terminal lower right corner
              Positioned(
                top: null,
                bottom: 332,
                right: 10,
                child: PostItNote(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
