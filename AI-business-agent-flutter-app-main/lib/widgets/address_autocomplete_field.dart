import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';

class AddressAutocompleteField extends StatefulWidget {
  const AddressAutocompleteField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.onSelected,
    this.isBottomInput = false,
    this.city = '',
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String hintText;
  final ValueChanged<Map<String, dynamic>> onSelected;
  final bool isBottomInput;
  final String city;
  final VoidCallback? onSubmitted;

  @override
  State<AddressAutocompleteField> createState() =>
      _AddressAutocompleteFieldState();
}

class _AddressAutocompleteFieldState extends State<AddressAutocompleteField> {
  List<Map<String, dynamic>> _suggestions = [];
  bool _isLoading = false;
  Timer? _debounce;

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    if (query.trim().length < 2) {
      setState(() {
        _suggestions = [];
        _isLoading = false;
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 300), () async {
      setState(() => _isLoading = true);
      try {
        final uri = Uri.parse(
          '${ApiConfig.baseUrl}/suggest?q=${Uri.encodeComponent(query)}&city=${Uri.encodeComponent(widget.city)}',
        );
        final res = await http.get(uri).timeout(const Duration(seconds: 5));
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          if (mounted) {
            setState(() {
              _suggestions = List<Map<String, dynamic>>.from(
                data['suggestions'] ?? [],
              );
            });
          }
        }
      } catch (_) {
        if (mounted) setState(() => _suggestions = []);
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    });
  }

  void _selectItem(Map<String, dynamic> item) {
    widget.controller.text = item['name'] ?? '';
    setState(() => _suggestions = []);
    FocusScope.of(context).unfocus();
    widget.onSelected(item);
  }

  Widget _buildSuggestionsBox() {
    if (_suggestions.isEmpty && !_isLoading) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: EdgeInsets.only(
        bottom: widget.isBottomInput ? 8.0 : 0.0,
        top: widget.isBottomInput ? 0.0 : 8.0,
      ),
      constraints: const BoxConstraints(maxHeight: 200),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E24) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: Offset(0, widget.isBottomInput ? -4 : 4),
          ),
        ],
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: _isLoading
            ? const Padding(
                padding: EdgeInsets.all(12),
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              )
            : ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: _suggestions.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final item = _suggestions[index];
                  return ListTile(
                    dense: true,
                    leading: const Icon(
                      Icons.location_on_outlined,
                      size: 18,
                      color: Color(0xFFA855F7),
                    ),
                    title: Text(
                      item['name'] ?? '',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () => _selectItem(item),
                  );
                },
              ),
      ),
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.isBottomInput) _buildSuggestionsBox(),
        TextField(
          controller: widget.controller,
          onChanged: _onSearchChanged,
          onSubmitted: (_) {
            setState(() => _suggestions = []);
            widget.onSubmitted?.call();
          },
          decoration: InputDecoration(
            hintText: widget.hintText,
            prefixIcon: const Icon(Icons.search, size: 20),
            suffixIcon: widget.controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () {
                      widget.controller.clear();
                      setState(() => _suggestions = []);
                    },
                  )
                : null,
          ),
        ),
        if (!widget.isBottomInput) _buildSuggestionsBox(),
      ],
    );
  }
}
