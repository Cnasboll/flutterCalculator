import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'steampunk_keyboard.dart';
import 'cash_register_display.dart';
import 'package:awesome_calculator/shql/engine/engine.dart';

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

class _AncientComputerState extends State<AncientComputer> with SingleTickerProviderStateMixin {
  // Constants
  static const String _promptSymbol = '> ';
  static const int _tabSpaces = 4;
  static const Duration _cursorBlinkDuration = Duration(milliseconds: 530);
  static const Duration _keyPressDuration = Duration(milliseconds: 150);
  
  // Terminal state
  String _terminalText = _promptSymbol;
  int _cursorPosition = _promptSymbol.length;
  int _currentPromptPosition = 0; // Position of the current prompt in _terminalText
  final List<String> _commandHistory = [];
  int _historyIndex = -1;
  String _currentInput = '';
  
  static const int maxWheels = 12;
  // Cash register display
  String _displayValue = 'NULL'.padLeft(maxWheels, ' ');  
  String _lastDisplayDebug = '';
  
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
    ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '.', '(', ')'],
    ['+', '-', '*', '/', '^', '%', '=', '<', '>', '!', '&', '|', '~'],
    ['TAB', 'q', 'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p', '[', ']'],
    ['a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l', ';', '\'', '\\'],
    ['z', 'x', 'c', 'v', 'b', 'n', 'm', ',', '.', '/', 'ENTER'],
    ['SHIFT', 'SPACE', 'BACK', 'DEL', '←', '↑', '↓', '→'],
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
    'ENTER': '↵',  // Soft return / line break
    // Arrow keys don't shift
  };

  @override
  void initState() {
    super.initState();
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
    
    // Initialize display to show NULL for empty input
    _evaluateCurrentInput();
  }

  @override
  void dispose() {
    _cursorController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  /// Get the current input text (after the current prompt, may be multi-line)
  String _getCurrentLine() {
    final inputStart = _currentPromptPosition + _promptSymbol.length;
    return _terminalText.substring(inputStart).trim();
  }

  /// Replace current input with text from history (handles multi-line)
  void _replaceCurrentLine(String text) {
    final inputStart = _currentPromptPosition + _promptSymbol.length;
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
        final historyCommand = _commandHistory[_commandHistory.length - 1 - _historyIndex];
        _replaceCurrentLine(historyCommand);
      }
    } else {
      // Move forward in history (newer commands)
      if (_historyIndex > 0) {
        _historyIndex--;
        final historyCommand = _commandHistory[_commandHistory.length - 1 - _historyIndex];
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
        return (result.toStringAsFixed(6).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), ''), '0');      
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
    
    try {
      final result = currentInput.isEmpty ? null : Engine.calculate(currentInput); 
      
      final (formatted, padding) = _formatResult(result);
      _displayValue = formatted.padLeft(maxWheels, padding);      

    } catch (e) {
      // Keep previous valid result
      print(e);
    }
    
    // Print a concise mapping of display characters -> wheel indices once per display change
    if (_displayValue != _lastDisplayDebug) {
      const _wheelChars =
          ' 0123456789'
          'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
          'abcdefghijklmnopqrstuvwxyz'
          '+-*/=<>!?.,;:\'"()[]{}@#\$%&_|\\';
      final indices = _displayValue.split('').map((c) {
        final idx = _wheelChars.indexOf(c);
        return idx == -1 ? '?': idx.toString();
      }).join(',');
      // Single-line debug print (non-spammy)
      // ignore: avoid_print
      _lastDisplayDebug = _displayValue;
    }
  }

  /// Handle up arrow: command history on last line, cursor movement otherwise
  void _handleArrowUp() {
    final isInInputSection = _cursorPosition >= _currentPromptPosition;
    
    if (!isInInputSection) return;
    
    // Check if we're on the first line of input
    final inputStart = _currentPromptPosition + _promptSymbol.length;
    final firstNewlineInInput = _terminalText.indexOf('\n', inputStart);
    final isOnFirstLine = firstNewlineInInput == -1 || _cursorPosition <= firstNewlineInInput;
    
    if (isOnFirstLine) {
      // On first line: navigate history
      _navigateHistory(true);
      _evaluateCurrentInput();
    } else {
      // Not on first line: move cursor up within current input
      int currentLineStart = _terminalText.lastIndexOf('\n', _cursorPosition - 1) + 1;
      int prevLineStart = _terminalText.lastIndexOf('\n', currentLineStart - 2) + 1;
      
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

  /// Handle down arrow: command history on last line, cursor movement otherwise
  void _handleArrowDown() {
    final isInInputSection = _cursorPosition >= _currentPromptPosition;
    
    if (!isInInputSection) return;
    
    // Check if there's a next line in the current input
    final nextNewline = _terminalText.indexOf('\n', _cursorPosition);
    final isOnLastLine = nextNewline == -1;
    
    if (isOnLastLine) {
      // On last line: navigate history
      _navigateHistory(false);
      _evaluateCurrentInput();
    } else {
      // Not on last line: move cursor down within current input
      int currentLineStart = _terminalText.lastIndexOf('\n', _cursorPosition - 1) + 1;
      int nextLineStart = nextNewline + 1;
      int offsetInLine = _cursorPosition - currentLineStart;
      _cursorPosition = nextLineStart + offsetInLine;
      
      int nextLineEnd = _terminalText.indexOf('\n', nextLineStart);
      if (nextLineEnd == -1) nextLineEnd = _terminalText.length;
      if (_cursorPosition > nextLineEnd) _cursorPosition = nextLineEnd;
    }
  }

  void _handleKeyPress(String key) {
    setState(() {
      _pressedKey = key;
      
      // Handle arrow keys for cursor movement
      if (key == '←') {
        if (_cursorPosition > 0) {
          _cursorPosition--;
          // Don't allow cursor before the current prompt
          final promptEnd = _currentPromptPosition + _promptSymbol.length;
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
      }
      
      if (key == 'SHIFT') {
        if (!_physicalShiftPressed) {
          _virtualShiftToggled = !_virtualShiftToggled;
        }
      } else if (key == 'TAB') {
        _terminalText = _terminalText.substring(0, _cursorPosition) + 
                       ' ' * _tabSpaces + 
                       _terminalText.substring(_cursorPosition);
        _cursorPosition += _tabSpaces;
      } else if (key == 'ENTER') {
        if (_shiftPressed) {
          // SHIFT-ENTER: Soft return (line break without prompt)
          _terminalText = _terminalText.substring(0, _cursorPosition) + 
                         '\n' + 
                         _terminalText.substring(_cursorPosition);
          _cursorPosition += 1;
        } else {
          // Regular ENTER: Execute command and create new prompt
          final inputStart = _currentPromptPosition + _promptSymbol.length;
          final currentInput = _terminalText.substring(inputStart).trim();
          
          if (currentInput.isNotEmpty) {
            _commandHistory.add(currentInput);
            _historyIndex = -1;
            _currentInput = '';
            // TODO: Execute/evaluate command here
          }
          
          // Move cursor to end and add new prompt
          _terminalText += '\n$_promptSymbol';
          _currentPromptPosition = _terminalText.length - _promptSymbol.length;
          _cursorPosition = _terminalText.length;
        }
      } else if (key == 'BACK') {
        if (_cursorPosition > 0) {
          // Don't allow deleting the prompt or before it
          final promptEnd = _currentPromptPosition + _promptSymbol.length;
          
          if (_cursorPosition > promptEnd) {
            _terminalText = _terminalText.substring(0, _cursorPosition - 1) + 
                           _terminalText.substring(_cursorPosition);
            _cursorPosition--;
            _evaluateCurrentInput();
          }
        }
      } else if (key == 'DEL') {
        if (_cursorPosition < _terminalText.length) {
          // Delete character at cursor position (forward delete)
          _terminalText = _terminalText.substring(0, _cursorPosition) + 
                         _terminalText.substring(_cursorPosition + 1);
          _evaluateCurrentInput();
        }
      } else if (key == 'SPACE') {
        _terminalText = _terminalText.substring(0, _cursorPosition) + 
                       ' ' + 
                       _terminalText.substring(_cursorPosition);
        _cursorPosition++;
      } else {
        // Apply shift mapping if shift is pressed
        String charToInsert = key;
        if (_shiftPressed && _shiftMap.containsKey(key)) {
          charToInsert = _shiftMap[key]!;
        } else {
          // Make letters lowercase if shift not pressed
          if (key.length == 1 && key.codeUnitAt(0) >= 65 && key.codeUnitAt(0) <= 90) {
            charToInsert = key.toLowerCase();
          }
        }
        
        _terminalText = _terminalText.substring(0, _cursorPosition) + 
                       charToInsert + 
                       _terminalText.substring(_cursorPosition);
        _cursorPosition++;
      }
      
      // Evaluate expression after every keystroke
      _evaluateCurrentInput();
    });

    // Reset pressed key animation after a short delay
    Future.delayed(_keyPressDuration, () {
      if (mounted) {
        setState(() {
          _pressedKey = null;
        });
      }
    });
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent) {
      String? key;
      
      // Handle arrow keys for cursor movement
      if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        setState(() {
          if (_cursorPosition > 0) {
            _cursorPosition--;
            // Don't allow cursor before the current prompt
            final promptEnd = _currentPromptPosition + _promptSymbol.length;
            if (_cursorPosition < promptEnd) {
              _cursorPosition = promptEnd;
            }
          }
        });
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
        setState(() {
          if (_cursorPosition < _terminalText.length) {
            _cursorPosition++;
          }
        });
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        setState(() {
          _handleArrowUp();
        });
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        setState(() {
          _handleArrowDown();
        });
        return KeyEventResult.handled;
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
            if (code >= 97 && code <= 122) { // a-z (lowercase)
              key = label;
            } else if (code >= 65 && code <= 90) { // A-Z (uppercase from shift)
              key = label.toLowerCase(); // Map back to base key
            } else {
              // For symbols, the physical keyboard sends the shifted version
              // Find which base key produces this character
              final baseKey = _shiftMap.entries
                  .firstWhere((entry) => entry.value == label, orElse: () => MapEntry(label, label))
                  .key;
              key = baseKey;
            }
          }
        }
      }
      
      if (key != null) {
        _handleKeyPress(key);
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
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
              _physicalShiftPressed = true;
              _virtualShiftToggled = false;
              setState(() {});
              return;
            }
          } else if (event is KeyUpEvent) {
            if (event.logicalKey == LogicalKeyboardKey.shiftLeft || 
                event.logicalKey == LogicalKeyboardKey.shiftRight) {
              _physicalShiftPressed = false;
              setState(() {});
              return;
            }
          }
          
          if (event is KeyDownEvent) {
            _handleKeyEvent(_focusNode, event);
          }
        },
        child: Container(
          width: double.infinity,
          height: double.infinity,
          color: const Color(0xFF2B2B2B),
          child: Column(
            children: [
              // Terminal Display
              Expanded(
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: GestureDetector(
                    onTapDown: (details) {
                      // Calculate cursor position from tap location
                      _focusNode.requestFocus();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFF001100),
                        borderRadius: BorderRadius.circular(48),
                        border: Border.all(
                          color: const Color(0xFF00FF00),
                          width: 4,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00FF00).withValues(alpha: 0.6),
                            blurRadius: 40,
                            spreadRadius: 6,
                          ),
                          const BoxShadow(
                            color: Colors.black87,
                            blurRadius: 15,
                            offset: Offset(0, 6),
                          ),
                        ],
                      ),
                      child: SingleChildScrollView(
                        reverse: true,
                        child: LayoutBuilder(
                        builder: (context, constraints) {
                          return GestureDetector(
                            onTapDown: (details) {
                                // Calculate approximate cursor position
                                final textPainter = TextPainter(
                                  text: TextSpan(
                                    text: _terminalText,
                                    style: const TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 20,
                                      color: Color(0xFF00FF00),
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                  textDirection: TextDirection.ltr,
                                  maxLines: null,
                                )..layout(maxWidth: constraints.maxWidth);
                                
                                final position = textPainter.getPositionForOffset(
                                  details.localPosition,
                                );
                                
                                setState(() {
                                  final clickedPosition = position.offset.clamp(0, _terminalText.length);
                                  
                                  // Only allow clicking within current input section (after current prompt)
                                  final minPosition = _currentPromptPosition + _promptSymbol.length;
                                  _cursorPosition = clickedPosition.clamp(minPosition, _terminalText.length);
                                });
                                _focusNode.requestFocus();
                              },
                              child: RichText(
                                text: TextSpan(
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 20,
                                    color: Color(0xFF00FF00),
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: 1.2,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: _terminalText.substring(0, _cursorPosition),
                                    ),
                                    WidgetSpan(
                                      alignment: PlaceholderAlignment.baseline,
                                      baseline: TextBaseline.alphabetic,
                                      child: Container(
                                        width: 12,
                                        height: 24,
                                        color: _showCursor ? const Color(0xFF00FF00) : Colors.transparent,
                                      ),
                                    ),
                                    TextSpan(
                                      text: _terminalText.substring(_cursorPosition),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}