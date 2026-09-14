import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';

Future<Map<String, dynamic>?> showCitySelectionDialog({
  required BuildContext context,
  required String query,
  required List<Map<String, dynamic>> options,
}) async {
  return showDialog<Map<String, dynamic>>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('"$query" üçün şəhər seçin'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.separated(
          shrinkWrap: true,
          itemCount: options.length,
          separatorBuilder: (_, __) => const Divider(),
          itemBuilder: (context, index) {
            final item = options[index];
            final cityName = item['city'] ?? item['address'] ?? 'Məlum olmayan şəhər';
            final title = item['name'] ?? query;
            return ListTile(
              leading: const Icon(Icons.location_city, color: Color(0xFFA855F7)),
              title: Text(title.toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(cityName.toString()),
              onTap: () => Navigator.pop(context, item),
            );
          },
        ),
      ),
    ),
  );
}

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
  bool _hasSearched = false;
  Timer? _debounce;

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    if (query.trim().length < 2) {
      setState(() {
        _suggestions = [];
        _isLoading = false;
        _hasSearched = false;
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 300), () async {
      setState(() {
        _isLoading = true;
        _hasSearched = true;
      });
      try {
        final uri = Uri.parse(
          '${ApiConfig.backendUrl}/api/suggest?q=${Uri.encodeComponent(query)}&city=${Uri.encodeComponent(widget.city)}',
        );
        final res = await http.get(uri).timeout(const Duration(seconds: 10));
        var results = <Map<String, dynamic>>[];
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          results = List<Map<String, dynamic>>.from(data['suggestions'] ?? []);
        }

        if (results.isEmpty) {
          final osmUri = Uri.https('nominatim.openstreetmap.org', '/search', {
            'q': widget.city.isNotEmpty ? '${widget.city}, $query' : query,
            'format': 'jsonv2',
            'limit': '5',
          });
          final osmRes = await http
              .get(
                osmUri,
                headers: const {'User-Agent': 'AI-Business-Agent'},
              )
              .timeout(const Duration(seconds: 10));
          if (osmRes.statusCode == 200) {
            final osmData = jsonDecode(osmRes.body) as List;
            results = osmData.map<Map<String, dynamic>>((item) => {
              'name': item['display_name'],
              'city': widget.city,
              'lat': item['lat'],
              'lon': item['lon'],
            }).toList();
          }
        }

        if (mounted) {
          setState(() => _suggestions = results);
        }
      } catch (_) {
        if (mounted) setState(() => _suggestions = []);
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    });
  }

  Future<void> _selectItem(Map<String, dynamic> item) async {
    final cities = <String>{
      for (final suggestion in _suggestions)
        (suggestion['city']?.toString() ?? '').trim(),
    }..removeWhere((city) => city.isEmpty);
    if (cities.length > 1) {
      final selected = await showCitySelectionDialog(
        context: context,
        query: widget.controller.text.trim(),
        options: _suggestions,
      );
      if (selected == null || !mounted) return;
      item = selected;
    }
    widget.controller.text = item['name'] ?? '';
    setState(() {
      _suggestions = [];
      _hasSearched = false;
    });
    FocusScope.of(context).unfocus();
    widget.onSelected(item);
  }

  Widget _buildSuggestionsBox() {
    if (!_hasSearched && _suggestions.isEmpty) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: EdgeInsets.only(
        bottom: widget.isBottomInput ? 8.0 : 0.0,
        top: widget.isBottomInput ? 0.0 : 8.0,
      ),
      constraints: const BoxConstraints(maxHeight: 220),
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
            : _suggestions.isEmpty
            ? const Padding(
                padding: EdgeInsets.all(14),
                child: Row(
                  children: [
                    Icon(Icons.search_off, size: 18, color: Colors.grey),
                    SizedBox(width: 8),
                    Text(
                      'Nəticə tapılmadı',
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                  ],
                ),
              )
            : ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: _suggestions.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final item = _suggestions[index];
                  final city = item['city']?.toString() ?? widget.city;
                  return ListTile(
                    dense: true,
                    leading: const Icon(
                      Icons.location_on_outlined,
                      size: 18,
                      color: Color(0xFFA855F7),
                    ),
                    title: Text(
                      item['name']?.toString() ?? '',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: city.isNotEmpty
                        ? Text(
                            city,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                          )
                        : null,
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
            setState(() {
              _suggestions = [];
              _hasSearched = false;
            });
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
                      setState(() {
                        _suggestions = [];
                        _hasSearched = false;
                      });
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
