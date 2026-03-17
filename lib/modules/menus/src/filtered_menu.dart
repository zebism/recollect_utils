part of '../menus.dart';

/// A searchable dropdown menu with keyboard navigation and text filtering.
///
/// [FilteredMenu] combines a text field with a dropdown menu, allowing users to
/// search through options by typing. As the user types, the menu filters to show
/// only matching items. Perfect for large lists where users need to quickly find
/// specific options.
///
/// ## Features
///
/// - **Live Search**: Filter menu items as you type
/// - **Keyboard Navigation**: Use arrow keys to navigate, Enter to select, Escape to close
/// - **Auto-Highlighting**: Automatically highlights the first matching item
/// - **Visual Feedback**: Highlights current selection and keyboard-focused items
/// - **Customizable Size**: Adjustable height, width, and cursor height
///
/// ## Quick Start
///
/// ```dart
/// FilteredMenu<String>(
///   items: [
///     MenuItem(label: 'Apple', value: 'apple'),
///     MenuItem(label: 'Banana', value: 'banana'),
///     MenuItem(label: 'Cherry', value: 'cherry'),
///   ],
///   setStateCallback: () => setState(() {}),
///   label: 'Select Fruit',
///   onSelected: (value) {
///     print('Selected: $value');
///   },
/// )
/// ```
///
/// ## Constructor Parameters
///
/// | Parameter | Type | Required | Description |
/// |-----------|------|----------|-------------|
/// | `items` | `List<MenuItem>` | Yes | List of menu items to display |
/// | `setStateCallback` | `VoidCallback` | Yes | Callback to trigger parent widget rebuild |
/// | `initialSelection` | `T?` | No | Value to pre-select when widget loads |
/// | `onSelected` | `ValueChanged<T?>?` | No | Callback when user selects an item |
/// | `height` | `double?` | No | Height of the text field (default: 40) |
/// | `width` | `double?` | No | Width of the text field and dropdown |
/// | `label` | `String?` | No | Label text displayed above the field |
/// | `keyboardType` | `TextInputType?` | No | Keyboard type for the text field |
/// | `cursorHeight` | `double?` | No | Height of the text cursor |
///
/// ## Keyboard Shortcuts
///
/// - **Arrow Down**: Move to next item
/// - **Arrow Up**: Move to previous item
/// - **Enter**: Select highlighted item
/// - **Escape**: Close the dropdown
///
/// ## Filtering Behavior
///
/// The menu filters items using case-insensitive substring matching. When you type:
/// - Items containing the search text anywhere in their label are shown
/// - The first item starting with the search text is automatically highlighted
/// - The dropdown scrolls to keep the highlighted item visible
///
/// ## Example with Custom Sizing
///
/// ```dart
/// FilteredMenu<int>(
///   items: List.generate(
///     100,
///     (i) => MenuItem(label: 'Option ${i + 1}', value: i),
///   ),
///   setStateCallback: () => setState(() {}),
///   height: 50,
///   width: 300,
///   cursorHeight: 24,
///   label: 'Pick a Number',
///   initialSelection: 42,
///   onSelected: (value) {
///     print('You picked: $value');
///   },
/// )
/// ```
///
/// ## Example with Custom Types
///
/// ```dart
/// class Product {
///   final String name;
///   final double price;
///   Product(this.name, this.price);
/// }
///
/// FilteredMenu<Product>(
///   items: [
///     MenuItem(label: 'Laptop', value: Product('Laptop', 999.99)),
///     MenuItem(label: 'Mouse', value: Product('Mouse', 29.99)),
///     MenuItem(label: 'Keyboard', value: Product('Keyboard', 79.99)),
///   ],
///   setStateCallback: () => setState(() {}),
///   onSelected: (product) {
///     if (product != null) {
///       print('${product.name}: \$${product.price}');
///     }
///   },
/// )
/// ```
///
/// ## See Also
///
/// - [SimpleMenu] - A basic dropdown without search functionality
/// - [SuggestionField] - Text field with dropdown suggestions
/// - [MenuItem] - Individual menu item data structure
class FilteredMenu<T> extends StatefulWidget {
  const FilteredMenu({
    super.key,
    required this.items,
    required this.setStateCallback,
    this.initialSelection,
    this.onSelected,
    this.height = 40,
    this.width,
    this.keyboardType,
    this.cursorHeight,
    this.decoration = const BoxDecoration(),
    this.inputDecoration = const InputDecoration(),
  });

  final List<MenuItem> items;
  final VoidCallback setStateCallback;
  final double? height;
  final double? width;
  final T? initialSelection;
  final ValueChanged<T?>? onSelected;
  final TextInputType? keyboardType;
  final double? cursorHeight;
  final BoxDecoration decoration;
  final InputDecoration inputDecoration;

  @override
  State<FilteredMenu<T>> createState() => _FilteredMenuState<T>();
}

class _FilteredMenuState<T> extends State<FilteredMenu<T>> {
  late final TextEditingController _textController;
  late final FocusNode _focusNode;
  final LayerLink _layerLink = LayerLink();
  final ScrollController _scrollController = ScrollController();

  OverlayEntry? _overlayEntry;
  List<MenuItem> _filteredEntries = [];
  int? _currentHighlight;
  int? _selectedEntryIndex;
  bool _isOverlayVisible = false;

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: Container(
        height: widget.height,
        width: widget.width,
        padding: EdgeInsets.only(left: 10),
        decoration: widget.decoration.copyWith(
          color: Colours.white,
          borderRadius: BorderRadius.all(Radius.circular(5)),
        ),
        child: TextField(
          controller: _textController,
          focusNode: _focusNode,
          keyboardType: widget.keyboardType,
          textAlign: TextAlign.start,
          textAlignVertical: TextAlignVertical.center,
          maxLines: 1,
          cursorHeight: widget.cursorHeight,
          onTap: _toggleOverlay,
          onChanged: (text) {
            if (!_isOverlayVisible) {
              _showOverlay();
            }
          },
          decoration: widget.inputDecoration.copyWith(
            isDense: true,
            contentPadding: EdgeInsets.zero,
            fillColor: Colours.transparent,
            disabledBorder: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            errorBorder: InputBorder.none,
            focusedErrorBorder: InputBorder.none,
            hoverColor: Colours.transparent,
            focusColor: Colours.transparent,
            suffixIcon: IconButton(
              icon: _isOverlayVisible
                  ? const Icon(Icons.arrow_drop_up)
                  : const Icon(Icons.arrow_drop_down),
              onPressed: _toggleOverlay,
            ),
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
    _focusNode = FocusNode();
    _filteredEntries = widget.items;

    _textController.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);

    _initializeSelection();

    HardwareKeyboard.instance.addHandler(_handleKeyEvent);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    _textController.removeListener(_onTextChanged);
    _focusNode.removeListener(_onFocusChanged);
    _overlayEntry?.remove();
    _scrollController.dispose();

    _textController.dispose();
    _focusNode.dispose();

    super.dispose();
  }

  @override
  void didUpdateWidget(FilteredMenu<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.items != widget.items) {
      _filteredEntries = widget.items;
      _currentHighlight = null;
    }

    if (oldWidget.initialSelection != widget.initialSelection) {
      _initializeSelection();
    }
  }

  void _updateFilteredEntries() {
    final text = _textController.text;

    if (text.isNotEmpty) {
      _filteredEntries = widget.items.where((entry) {
        return entry.label.toLowerCase().contains(text.toLowerCase());
      }).toList();
      final searchText = text.toLowerCase();
      final index = _filteredEntries.indexWhere(
        (entry) => entry.label.toLowerCase().startsWith(searchText),
      );
      _currentHighlight = index != -1 ? index : null;

      if (_currentHighlight != null) {
        _scrollToHighlight();
      }
      setState(() {});
      widget.setStateCallback.call();
    } else {
      _filteredEntries = widget.items;
    }
  }

  void _initializeSelection() {
    if (widget.initialSelection != null) {
      final index = widget.items.indexWhere(
        (e) => e.value == widget.initialSelection,
      );
      if (index != -1) {
        _updateTextController(widget.items[index].label);
        _selectedEntryIndex = index;
      }
    }
  }

  void _updateTextController(String text) {
    _textController.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  void _onTextChanged() {
    if (_isOverlayVisible) {
      setState(() {
        _updateFilteredEntries();
      });
    }
  }

  void _onFocusChanged() {
    if (!_focusNode.hasFocus && _isOverlayVisible) {
      Future.delayed(Duration(milliseconds: 100), () {
        _hideOverlay();
      });
    }
  }

  bool _handleKeyEvent(KeyEvent event) {
    if (!_isOverlayVisible) return false;
    if (event is! KeyDownEvent) return false;

    final key = event.logicalKey;

    if (key == LogicalKeyboardKey.arrowDown) {
      _highlightNext();
      return true;
    }

    if (key == LogicalKeyboardKey.arrowUp) {
      _highlightPrevious();
      return true;
    }

    if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter) {
      _handleEnter();
      return true;
    }

    if (key == LogicalKeyboardKey.escape) {
      _hideOverlay();
      return true;
    }

    return false;
  }

  void _highlightNext() {
    setState(() {
      if (_filteredEntries.isEmpty) {
        _currentHighlight = null;
        return;
      }

      int next = ((_currentHighlight ?? -1) + 1) % _filteredEntries.length;

      _currentHighlight = next;
      _updateTextController(_filteredEntries[next].label);
    });
    _scrollToHighlight();
  }

  void _highlightPrevious() {
    setState(() {
      if (_filteredEntries.isEmpty) {
        _currentHighlight = null;
        return;
      }

      int prev = _currentHighlight ?? 0;
      prev = (prev - 1) % _filteredEntries.length;
      if (prev < 0) prev = _filteredEntries.length - 1;

      _currentHighlight = prev;
      _updateTextController(_filteredEntries[prev].label);
    });
    _scrollToHighlight();
  }

  void _handleEnter() {
    if (_currentHighlight != null &&
        _currentHighlight! < _filteredEntries.length) {
      final entry = _filteredEntries[_currentHighlight!];
      _selectEntry(entry, _currentHighlight!);
    }
  }

  void _scrollToHighlight() {
    if (_currentHighlight == null) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients &&
          _currentHighlight! < _filteredEntries.length) {
        final itemHeight = 48.0;
        final offset = _currentHighlight! * itemHeight;
        final viewportHeight = _scrollController.position.viewportDimension;
        final currentScroll = _scrollController.offset;

        if (offset < currentScroll ||
            offset + itemHeight > currentScroll + viewportHeight) {
          _scrollController.animateTo(
            offset - (viewportHeight / 2) + (itemHeight / 2),
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      }
    });
  }

  void _toggleOverlay() {
    if (_isOverlayVisible) {
      _hideOverlay();
    } else {
      _showOverlay();
    }
  }

  void _showOverlay() {
    if (_isOverlayVisible) return;

    setState(() {
      _filteredEntries = widget.items;
      _isOverlayVisible = true;
    });

    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
    _focusNode.requestFocus();
  }

  void _hideOverlay() {
    if (!_isOverlayVisible) return;

    setState(() {
      _isOverlayVisible = false;
      _currentHighlight = null;
    });

    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _selectEntry(MenuItem entry, int index) {
    _updateTextController(entry.label);
    _selectedEntryIndex = index;
    _currentHighlight = index;
    widget.onSelected?.call(entry.value);

    _hideOverlay();
  }

  OverlayEntry _createOverlayEntry() {
    return OverlayEntry(
      builder: (context) => GestureDetector(
        onTap: () {
          _hideOverlay();
        },
        behavior: HitTestBehavior.translucent,
        child: SizedBox.expand(
          child: Stack(
            children: [
              CompositedTransformFollower(
                link: _layerLink,
                targetAnchor: Alignment.bottomLeft,
                followerAnchor: Alignment.topLeft,
                showWhenUnlinked: false,
                child: SizedBox(
                  width: widget.width,

                  child: Material(
                    borderRadius: BorderRadius.circular(5),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.4,
                      ),
                      child: ListView.builder(
                        controller: _scrollController,
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: _filteredEntries.length,
                        itemBuilder: (context, index) =>
                            _buildItem(_filteredEntries[index], index),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItem(MenuItem entry, int index) {
    final isHighlighted = index == _currentHighlight;
    final isSelected = index == _selectedEntryIndex;

    Color? backgroundColor;
    if (isHighlighted) {
      backgroundColor = widget.decoration.color?.withOpacity(0.12);
    } else if (isSelected) {
      backgroundColor = AppTheme.primarySage.withOpacity(0.08);
    }

    return Material(
      color: backgroundColor,
      child: InkWell(
        onTap: () => _selectEntry(entry, index),
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(children: [Expanded(child: Text(entry.label))]),
        ),
      ),
    );
  }
}
