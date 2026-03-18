part of '../menus.dart';

/// A text input field with an attached dropdown menu for quick suggestions.
///
/// [SuggestionField] combines a text field with a dropdown button, allowing users
/// to either type their own input or select from predefined suggestions. This is
/// perfect for fields where you want to allow custom input while also offering
/// common options.
///
/// ## Features
///
/// - **Dual Input**: Type custom text or select from dropdown
/// - **Flexible Alignment**: Customize dropdown position and text alignment
/// - **Custom Styling**: Apply BoxDecoration for border, background, and more
/// - **Compact Design**: Text field takes 75% width, dropdown button 25%
/// - **Submit on Enter**: Pressing Enter submits the current text value
///
/// ## Quick Start
///
/// ```dart
/// SuggestionField(
///   items: ['Option 1', 'Option 2', 'Option 3'],
///   onSelected: (value) {
///     print('Selected or typed: $value');
///   },
/// )
/// ```
///
/// ## Constructor Parameters
///
/// | Parameter | Type | Required | Default | Description |
/// |-----------|------|----------|---------|-------------|
/// | `items` | `List<dynamic>` | Yes | - | List of suggestion values for dropdown |
/// | `onSelected` | `Function(dynamic)` | Yes | - | Callback when value is selected or submitted |
/// | `height` | `double` | No | 30 | Height of the field |
/// | `width` | `double` | No | 100 | Total width of the field |
/// | `decoration` | `BoxDecoration` | No | White bg | Container decoration |
/// | `alignDropdown` | `AlignType` | No | `fill` | Dropdown width alignment |
/// | `alignDropdownText` | `TextAlign` | No | `left` | Text alignment in dropdown items |
///
/// ## Alignment Options
///
/// The `alignDropdown` parameter controls how the dropdown menu is sized:
///
/// - `AlignType.fill` - Dropdown fills the entire width of the field
/// - `AlignType.left` - Dropdown aligns to left edge
/// - `AlignType.right` - Dropdown aligns to right edge
/// - `AlignType.center` - Dropdown centered below field
///
/// ## Example with Custom Styling
///
/// ```dart
/// SuggestionField(
///   items: ['Red', 'Green', 'Blue', 'Yellow'],
///   height: 40,
///   width: 200,
///   decoration: BoxDecoration(
///     border: Border.all(color: Colors.grey),
///     borderRadius: BorderRadius.circular(8),
///     color: Colors.white,
///   ),
///   alignDropdown: AlignType.fill,
///   alignDropdownText: TextAlign.center,
///   onSelected: (color) {
///     print('Selected color: $color');
///   },
/// )
/// ```
///
/// ## Example with Theme Integration
///
/// ```dart
/// SuggestionField(
///   items: ['Arial', 'Times New Roman', 'Courier', 'Helvetica'],
///   height: 35,
///   width: 250,
///   decoration: BoxDecoration(
///     color: AppTheme.surface(context).colour,
///     border: Border.all(
///       color: AppTheme.outline(context).colour,
///     ),
///     borderRadius: BorderRadius.circular(4),
///   ),
///   onSelected: (font) {
///     setState(() {
///       selectedFont = font;
///     });
///   },
/// )
/// ```
///
/// ## Example for Custom Units
///
/// ```dart
/// // Perfect for entering measurements with unit suggestions
/// SuggestionField(
///   items: ['px', 'em', 'rem', '%', 'vh', 'vw'],
///   height: 30,
///   width: 120,
///   alignDropdown: AlignType.fill,
///   onSelected: (unit) {
///     // User either typed a custom value or selected a unit
///     print('Unit: $unit');
///   },
/// )
/// ```
///
/// ## Usage Notes
///
/// - The text field occupies 75% of the total width
/// - The dropdown button occupies 25% of the total width
/// - Pressing Enter in the text field triggers `onSelected` with current text
/// - Clicking a dropdown item populates the text field and triggers `onSelected`
/// - The dropdown uses [MenuDropDown] internally for the suggestion menu
///
/// ## When to Use
///
/// Use [SuggestionField] when:
/// - You want to allow both custom input and predefined options
/// - Common values should be easily selectable
/// - Users might need to enter variations of standard options
/// - Example use cases: units (px, em, %), file extensions, tags, categories
///
/// Use other menus instead when:
/// - [FilteredMenu] - Only predefined options allowed, large list needs search
/// - [SimpleMenu] - Only predefined options allowed, small list
/// - TextField - No suggestions needed, completely free-form input
///
/// ## See Also
///
/// - [FilteredMenu] - Searchable dropdown with type-to-filter
/// - [SimpleMenu] - Basic dropdown menu without search
/// - [MenuDropDown] - Internal component used for the dropdown portion
/// - [AlignType] - Enum defining dropdown alignment options
class SuggestionField extends StatefulWidget {
  final double height;
  final double width;
  final List<dynamic> items;
  final Function(dynamic value) onSelected;
  final BoxDecoration decoration;
  final InputDecoration inputDecoration;
  final AlignType alignDropdown;
  final TextAlign alignDropdownText;
  final String? initialValue;

  const SuggestionField({
    super.key,
    required this.items,
    required this.onSelected,
    this.height = 30,
    this.width = 100,
    this.decoration = const BoxDecoration(),
    this.inputDecoration = const InputDecoration(),
    this.alignDropdown = AlignType.fill,
    this.alignDropdownText = TextAlign.left,
    this.initialValue,
  });

  @override
  State<SuggestionField> createState() => _SuggestionFieldState();
}

class _SuggestionFieldState extends State<SuggestionField> {
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialValue != null) {
      _controller.text = widget.initialValue!;
    }
  }

  @override
  void didUpdateWidget(SuggestionField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue != widget.initialValue) {
      _controller.text = widget.initialValue ?? '';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      width: widget.width,
      decoration: widget.decoration.copyWith(
        color: Colours.white,
        borderRadius: BorderRadius.all(Radius.circular(5)),
      ),
      child: Row(
        children: [
          SizedBox(width: 10),
          SizedBox(
            width: ((widget.width * 0.75) - 10),
            child: Center(
              child: TextField(
                style: TextStyle(fontSize: 16),
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
                ),
                controller: _controller,
                onSubmitted: (value) {
                  widget.onSelected.call(value);
                },
              ),
            ),
          ),
          MenuDropDown(
            height: widget.height,
            dropdownWidth: widget.width,
            width: widget.width * 0.25,
            iconSize: 16,
            items: widget.items,
            alignDropdown: widget.alignDropdown,
            alignText: widget.alignDropdownText,
            onSelected: (value) {
              _controller.text = value.toString();
              widget.onSelected.call(value.toString());
              setState(() {});
            },
          ),
        ],
      ),
    );
  }
}
