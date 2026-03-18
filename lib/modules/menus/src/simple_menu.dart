part of '../menus.dart';

/// A simple dropdown menu with keyboard navigation and click selection.
///
/// [SimpleMenu] is a lightweight dropdown menu that displays a list of options
/// when clicked. Unlike [FilteredMenu], it doesn't have search functionality,
/// making it ideal for shorter lists where users can easily scan all options.
///
/// ## Features
///
/// - **Clean Interface**: Simple click-to-open dropdown design
/// - **Keyboard Navigation**: Use arrow keys to navigate, Enter to select, Escape to close
/// - **Visual Feedback**: Highlights current selection and keyboard-focused items
/// - **Customizable Size**: Adjustable height and width
/// - **Auto-Scroll**: Automatically scrolls to keep highlighted items visible
///
/// ## Quick Start
///
/// ```dart
/// SimpleMenu<String>(
///   items: [
///     MenuItem(label: 'Small', value: 's'),
///     MenuItem(label: 'Medium', value: 'm'),
///     MenuItem(label: 'Large', value: 'l'),
///   ],
///   setStateCallback: () => setState(() {}),
///   label: 'Size',
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
/// | `height` | `double?` | No | Height of the field (default: 40) |
/// | `width` | `double?` | No | Width of the field and dropdown |
/// | `label` | `String?` | No | Label text displayed above the field |
///
/// ## Keyboard Shortcuts
///
/// - **Arrow Down**: Move to next item
/// - **Arrow Up**: Move to previous item
/// - **Enter**: Select highlighted item
/// - **Escape**: Close the dropdown
///
/// ## When to Use
///
/// Use [SimpleMenu] when:
/// - You have a small to medium list of options (< 20 items)
/// - Users can easily scan the entire list
/// - You don't need search/filter functionality
/// - You want a clean, minimal dropdown interface
///
/// Use [FilteredMenu] instead when:
/// - You have many options (20+ items)
/// - Users need to search for specific items
/// - Option labels are long or complex
///
/// ## Example with Initial Selection
///
/// ```dart
/// String selectedSize = 'm';
///
/// SimpleMenu<String>(
///   items: [
///     MenuItem(label: 'Small', value: 's'),
///     MenuItem(label: 'Medium', value: 'm'),
///     MenuItem(label: 'Large', value: 'l'),
///     MenuItem(label: 'Extra Large', value: 'xl'),
///   ],
///   setStateCallback: () => setState(() {}),
///   initialSelection: selectedSize,
///   label: 'Shirt Size',
///   onSelected: (value) {
///     setState(() {
///       selectedSize = value ?? 'm';
///     });
///   },
/// )
/// ```
///
/// ## Example with Custom Width
///
/// ```dart
/// SimpleMenu<int>(
///   items: List.generate(
///     10,
///     (i) => MenuItem(label: '${i + 1} item(s)', value: i + 1),
///   ),
///   setStateCallback: () => setState(() {}),
///   width: 200,
///   height: 48,
///   label: 'Quantity',
///   onSelected: (quantity) {
///     print('Quantity: $quantity');
///   },
/// )
/// ```
///
/// ## Example with Enum Values
///
/// ```dart
/// enum Priority { low, medium, high, critical }
///
/// SimpleMenu<Priority>(
///   items: [
///     MenuItem(label: 'Low', value: Priority.low),
///     MenuItem(label: 'Medium', value: Priority.medium),
///     MenuItem(label: 'High', value: Priority.high),
///     MenuItem(label: 'Critical', value: Priority.critical),
///   ],
///   setStateCallback: () => setState(() {}),
///   initialSelection: Priority.medium,
///   onSelected: (priority) {
///     print('Priority level: ${priority?.name}');
///   },
/// )
/// ```
///
/// ## See Also
///
/// - [FilteredMenu] - Searchable dropdown menu for large lists
/// - [SuggestionField] - Text field with dropdown suggestions
/// - [MenuItem] - Individual menu item data structure
class SimpleMenu<T> extends StatefulWidget {
  const SimpleMenu({
    super.key,
    required this.items,
    required this.setStateCallback,
    this.initialSelection,
    this.onSelected,
    this.height = 40,
    this.width = 200,
    this.label,
    this.decoration = const BoxDecoration(
      color: Colours.white,
      borderRadius: BorderRadius.all(Radius.circular(4.0)),
    ),
  });

  final List<MenuItem> items;
  final VoidCallback setStateCallback;
  final double height;
  final double width;
  final T? initialSelection;
  final ValueChanged<T?>? onSelected;
  final String? label;
  final BoxDecoration decoration;

  @override
  State<SimpleMenu<T>> createState() => _SimpleMenuState<T>();
}

class _SimpleMenuState<T> extends State<SimpleMenu<T>> {
  final LayerLink _layerLink = LayerLink();
  final ScrollController _scrollController = ScrollController();

  OverlayEntry? _overlayEntry;
  int? _currentHighlight;
  int? _selectedEntryIndex;
  bool _isOverlayVisible = false;
  String _displayText = '';

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(
        onTap: _toggleOverlay,
        child: Container(
          height: widget.height,
          width: widget.width,
          decoration: widget.decoration,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            children: [
              if (widget.label != null) ...[
                Text(widget.label!),
                const SizedBox(width: 8),
              ],
              Expanded(child: Text(_displayText)),
              Icon(
                _isOverlayVisible ? Icons.arrow_drop_up : Icons.arrow_drop_down,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _initializeSelection();
    HardwareKeyboard.instance.addHandler(_handleKeyEvent);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    _overlayEntry?.remove();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(SimpleMenu<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.items != widget.items) {
      _currentHighlight = null;
    }

    if (oldWidget.initialSelection != widget.initialSelection) {
      _initializeSelection();
    }
  }

  void _initializeSelection() {
    if (widget.initialSelection != null) {
      final index = widget.items.indexWhere(
        (e) => e.value == widget.initialSelection,
      );
      if (index != -1) {
        _displayText = widget.items[index].label;
        _selectedEntryIndex = index;
      }
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
      if (widget.items.isEmpty) {
        _currentHighlight = null;
        return;
      }

      int next = ((_currentHighlight ?? -1) + 1) % widget.items.length;
      _currentHighlight = next;
    });
    _scrollToHighlight();
  }

  void _highlightPrevious() {
    setState(() {
      if (widget.items.isEmpty) {
        _currentHighlight = null;
        return;
      }

      int prev = _currentHighlight ?? 0;
      prev = (prev - 1) % widget.items.length;
      if (prev < 0) prev = widget.items.length - 1;

      _currentHighlight = prev;
    });
    _scrollToHighlight();
  }

  void _handleEnter() {
    if (_currentHighlight != null && _currentHighlight! < widget.items.length) {
      final entry = widget.items[_currentHighlight!];
      _selectEntry(entry, _currentHighlight!);
    }
  }

  void _scrollToHighlight() {
    if (_currentHighlight == null) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients &&
          _currentHighlight! < widget.items.length) {
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
      _isOverlayVisible = true;
    });

    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
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
    setState(() {
      _displayText = entry.label;
      _selectedEntryIndex = index;
      _currentHighlight = index;
    });
    widget.onSelected?.call(entry.value);
    widget.setStateCallback.call();

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
                    elevation: 8,
                    borderRadius: BorderRadius.circular(8),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.4,
                      ),
                      child: ListView.builder(
                        controller: _scrollController,
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: widget.items.length,
                        itemBuilder: (context, index) =>
                            _buildItem(widget.items[index], index),
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
      backgroundColor = AppTheme.background(context).colour.withOpacity(0.12);
    } else if (isSelected) {
      backgroundColor = AppTheme.primarySage.colour.withOpacity(0.08);
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
