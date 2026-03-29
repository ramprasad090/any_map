import 'dart:async';

import 'package:flutter/material.dart';

import '../models/lat_lng.dart';
import '../search/search_provider.dart';

/// A ready-made Flutter search field with debounce, dropdown overlay, and
/// keyboard handling — backed by any [AnySearchProvider].
///
/// Drop this anywhere in your widget tree. It handles:
/// - 350 ms debounce by default (configurable)
/// - Loading indicator while searching
/// - Scrollable result dropdown with leading icons
/// - Clear button when the field has text
/// - `onPlaceSelected` callback with the chosen [AnyPlace]
/// - `onSearchChanged` for raw query text
///
/// ```dart
/// AnyPlacesSearchField(
///   provider: NominatimSearchProvider(),
///   hint: 'Search places...',
///   near: AnyLatLng(17.3850, 78.4867),
///   onPlaceSelected: (place) {
///     controller.animateCamera(
///       AnyCameraPosition(target: place.position, zoom: 16),
///     );
///   },
/// )
/// ```
class AnyPlacesSearchField extends StatefulWidget {
  /// The search/geocoding provider to use.
  final AnySearchProvider provider;

  /// Placeholder text in the empty field.
  final String hint;

  /// Bias search results toward this location.
  final AnyLatLng? near;

  /// Radius in km around [near] used to bias results.
  final double radiusKm;

  /// Maximum number of results to show in the dropdown.
  final int maxResults;

  /// Debounce interval. Searches fire after the user stops typing.
  final Duration debounceDuration;

  /// Called when the user selects a place from the dropdown.
  final ValueChanged<AnyPlace>? onPlaceSelected;

  /// Called on every keystroke with the raw query text.
  final ValueChanged<String>? onSearchChanged;

  /// Custom leading icon. Defaults to a search icon.
  final Widget? leadingIcon;

  /// Custom item builder for the dropdown rows.
  final Widget Function(BuildContext, AnyPlace)? itemBuilder;

  /// Optional [FocusNode] for the text field.
  final FocusNode? focusNode;

  /// Whether to automatically dismiss the keyboard after selection.
  final bool dismissKeyboardOnSelect;

  const AnyPlacesSearchField({
    super.key,
    required this.provider,
    this.hint = 'Search places…',
    this.near,
    this.radiusKm = 50,
    this.maxResults = 8,
    this.debounceDuration = const Duration(milliseconds: 350),
    this.onPlaceSelected,
    this.onSearchChanged,
    this.leadingIcon,
    this.itemBuilder,
    this.focusNode,
    this.dismissKeyboardOnSelect = true,
  });

  @override
  State<AnyPlacesSearchField> createState() => _AnyPlacesSearchFieldState();
}

class _AnyPlacesSearchFieldState extends State<AnyPlacesSearchField> {
  final _controller = TextEditingController();
  late final FocusNode _focusNode;
  Timer? _debounce;
  List<AnyPlace> _results = [];
  bool _loading = false;
  bool _showDropdown = false;
  OverlayEntry? _overlay;
  final _fieldKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);
    _controller.addListener(_onTextChange);
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) _hideDropdown();
  }

  void _onTextChange() {
    final q = _controller.text;
    widget.onSearchChanged?.call(q);
    _debounce?.cancel();
    if (q.trim().isEmpty) {
      setState(() => _results = []);
      _hideDropdown();
      return;
    }
    _debounce = Timer(widget.debounceDuration, () => _search(q));
  }

  Future<void> _search(String q) async {
    if (!mounted) return;
    setState(() => _loading = true);
    final results = await widget.provider.search(
      q,
      near: widget.near,
      radiusKm: widget.radiusKm,
      limit: widget.maxResults,
    );
    if (!mounted) return;
    setState(() {
      _results = results;
      _loading = false;
      _showDropdown = results.isNotEmpty;
    });
    if (_showDropdown) {
      if (_overlay != null) {
        // Overlay already shown — just rebuild it with new results
        _overlay!.markNeedsBuild();
      } else {
        _showOverlay();
      }
    }
  }

  void _onSelect(AnyPlace place) {
    _controller.removeListener(_onTextChange);
    _controller.text = place.name;
    _controller.addListener(_onTextChange);
    _hideDropdown();
    if (widget.dismissKeyboardOnSelect) _focusNode.unfocus();
    widget.onPlaceSelected?.call(place);
  }

  void _clear() {
    _controller.clear();
    setState(() => _results = []);
    _hideDropdown();
    _focusNode.requestFocus();
  }

  // ── Overlay management ──

  void _showOverlay() {
    _removeOverlay();
    final box = _fieldKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final offset = box.localToGlobal(Offset.zero);
    final size = box.size;

    _overlay = OverlayEntry(
      builder: (_) => Positioned(
        left: offset.dx,
        top: offset.dy + size.height + 2,
        width: size.width,
        child: _DropdownList(
          results: _results,
          itemBuilder: widget.itemBuilder,
          onSelect: _onSelect,
        ),
      ),
    );

    Overlay.of(context).insert(_overlay!);
  }

  void _hideDropdown() {
    setState(() => _showDropdown = false);
    _removeOverlay();
  }

  void _removeOverlay() {
    _overlay?.remove();
    _overlay = null;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _focusNode.removeListener(_onFocusChange);
    _controller.removeListener(_onTextChange);
    _controller.dispose();
    if (widget.focusNode == null) _focusNode.dispose();
    _removeOverlay();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      key: _fieldKey,
      elevation: 2,
      borderRadius: BorderRadius.circular(12),
      color: theme.colorScheme.surface,
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        decoration: InputDecoration(
          hintText: widget.hint,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
          prefixIcon: _loading
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : widget.leadingIcon ?? const Icon(Icons.search),
          suffixIcon: _controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: _clear,
                )
              : null,
        ),
      ),
    );
  }
}

class _DropdownList extends StatelessWidget {
  final List<AnyPlace> results;
  final Widget Function(BuildContext, AnyPlace)? itemBuilder;
  final ValueChanged<AnyPlace> onSelect;

  const _DropdownList({
    required this.results,
    required this.itemBuilder,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      elevation: 6,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 320),
        child: ListView.separated(
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          itemCount: results.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (ctx, i) {
            final place = results[i];
            if (itemBuilder != null) {
              return GestureDetector(
                onTap: () => onSelect(place),
                child: itemBuilder!(ctx, place),
              );
            }
            return ListTile(
              dense: true,
              leading: Icon(
                _iconForCategory(place.category),
                size: 20,
                color: theme.colorScheme.primary,
              ),
              title: Text(
                place.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium,
              ),
              subtitle: Text(
                place.address,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall,
              ),
              onTap: () => onSelect(place),
            );
          },
        ),
      ),
    );
  }

  IconData _iconForCategory(String? cat) {
    if (cat == null) return Icons.place;
    if (cat.contains('tourism') || cat.contains('attraction')) return Icons.attractions;
    if (cat.contains('amenity') || cat.contains('restaurant') || cat.contains('cafe')) {
      return Icons.restaurant;
    }
    if (cat.contains('shop')) return Icons.shopping_cart;
    if (cat.contains('highway') || cat.contains('road')) return Icons.route;
    if (cat.contains('city') || cat.contains('town')) return Icons.location_city;
    return Icons.place;
  }
}
