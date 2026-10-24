import 'dart:async';

import 'package:flutter/material.dart';

import '../services/place_search_service.dart';

const _typeLabels = {
  'az': {
    'country': 'Ölkə',
    'city': 'Şəhər',
    'address': 'Ünvan',
    'poi': 'Məkan',
    'noResults': 'Nəticə tapılmadı',
    'error': 'Axtarış serverinə qoşulmaq alınmadı',
    'searching': 'Axtarılır...',
    'hintExample': 'Şəhər, küçə və ya biznes adı',
  },
  'en': {
    'country': 'Country',
    'city': 'City',
    'address': 'Address',
    'poi': 'Place',
    'noResults': 'No results found',
    'error': 'Could not reach the search service',
    'searching': 'Searching...',
    'hintExample': 'City, street or business name',
  },
  'ru': {
    'country': 'Страна',
    'city': 'Город',
    'address': 'Адрес',
    'poi': 'Место',
    'noResults': 'Ничего не найдено',
    'error': 'Не удалось связаться с сервисом поиска',
    'searching': 'Поиск...',
    'hintExample': 'Город, улица или название бизнеса',
  },
  'kk': {
    'country': 'Ел',
    'city': 'Қала',
    'address': 'Мекенжай',
    'poi': 'Орын',
    'noResults': 'Нәтиже табылмады',
    'error': 'Іздеу серверіне қосылу мүмкін болмады',
    'searching': 'Ізделуде...',
    'hintExample': 'Қала, көше немесе бизнес атауы',
  },
};

String _label(String language, String key) =>
    _typeLabels[language]?[key] ?? _typeLabels['az']![key]!;

class AddressAutocompleteField extends StatefulWidget {
  const AddressAutocompleteField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.onSelected,
    this.isBottomInput = false,
    this.city = '',
    this.countryCode = '',
    this.allowedTypes,
    this.onSubmitted,
    this.language,
  });

  final TextEditingController controller;
  final String hintText;

  /// Receives the full resolved place: `id`, `name`, `subtitle`, `type`,
  /// `city`, `lat`, `lon`, `point`, `bbox`, `zoom` and `source`.
  final ValueChanged<Map<String, dynamic>> onSelected;
  final bool isBottomInput;
  final String city;
  final String countryCode;
  final Set<String>? allowedTypes;
  final VoidCallback? onSubmitted;
  final String? language;

  @override
  State<AddressAutocompleteField> createState() =>
      _AddressAutocompleteFieldState();
}

class _AddressAutocompleteFieldState extends State<AddressAutocompleteField> {
  final PlaceSearchService _searchService = PlaceSearchService();
  List<Map<String, dynamic>> _suggestions = [];
  bool _isLoading = false;
  bool _hasSearched = false;
  bool _failed = false;
  Timer? _debounce;
  int _requestId = 0;

  String get _language {
    if (widget.language != null && widget.language!.isNotEmpty) {
      return widget.language!;
    }
    return Localizations.maybeLocaleOf(context)?.languageCode ?? 'az';
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    if (query.trim().length < 2) {
      setState(() {
        _suggestions = [];
        _isLoading = false;
        _hasSearched = false;
        _failed = false;
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 320), () {
      _runSearch(query.trim());
    });
  }

  Future<void> _runSearch(String query) async {
    final requestId = ++_requestId;
    setState(() {
      _isLoading = true;
      _hasSearched = true;
      _failed = false;
    });
    final result = await _searchService.search(
      query,
      city: widget.city,
      countryCode: widget.countryCode,
      types: widget.allowedTypes,
      language: _language,
    );
    if (!mounted || requestId != _requestId) return;
    setState(() {
      _suggestions = widget.allowedTypes == null
          ? result.items
          : result.items
            .where((item) => widget.allowedTypes!.contains(item['type']))
            .toList();
      _isLoading = false;
      // An empty list after a failed request is an error, not "no results";
      // the two states must look different to the user.
      _failed = result.failed;
    });
  }

  Future<void> _selectItem(Map<String, dynamic> item) async {
    widget.controller.text = (item['name'] ?? '').toString();
    setState(() {
      _suggestions = [];
      _hasSearched = false;
      _failed = false;
    });
    FocusScope.of(context).unfocus();
    widget.onSelected(item);
  }

  Future<void> _submit() async {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    if (_suggestions.isNotEmpty) {
      await _selectItem(_suggestions.first);
      return;
    }
    final query = widget.controller.text.trim();
    if (query.length >= 2) {
      await _runSearch(query);
      if (_suggestions.isNotEmpty) {
        await _selectItem(_suggestions.first);
        return;
      }
    }
    setState(() {
      _suggestions = [];
      _hasSearched = false;
    });
    widget.onSubmitted?.call();
  }

  IconData _iconFor(String type) => switch (type) {
    'country' => Icons.public,
    'city' => Icons.location_city,
    'address' => Icons.home_work_outlined,
    _ => Icons.storefront_outlined,
  };

  Widget _buildSuggestionsBox() {
    if (!_hasSearched && _suggestions.isEmpty) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final availableHeight =
      MediaQuery.sizeOf(context).height - MediaQuery.viewInsetsOf(context).bottom;
    final suggestionsHeight = (availableHeight * 0.7)
      .clamp(260.0, 480.0)
      .toDouble();
    return Container(
      margin: EdgeInsets.only(
        bottom: widget.isBottomInput ? 8.0 : 0.0,
        top: widget.isBottomInput ? 0.0 : 8.0,
      ),
      constraints: BoxConstraints(maxHeight: suggestionsHeight),
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
            ? Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _label(_language, 'searching'),
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              )
            : _suggestions.isEmpty
            ? Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Icon(
                      _failed ? Icons.cloud_off : Icons.search_off,
                      size: 18,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _failed
                            ? _label(_language, 'error')
                            : _label(_language, 'noResults'),
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : Scrollbar(
                thumbVisibility: true,
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  itemCount: _suggestions.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = _suggestions[index];
                    final type = (item['type'] ?? 'poi').toString();
                    final subtitle = (item['subtitle'] ?? item['city'] ?? '')
                        .toString();
                    return ListTile(
                      dense: true,
                      leading: Icon(
                        _iconFor(type),
                        size: 18,
                        color: const Color(0xFFA855F7),
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
                      subtitle: Text(
                        [
                          _label(_language, type),
                          if (subtitle.isNotEmpty) subtitle,
                        ].join(' · '),
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: const Icon(
                        Icons.north_west,
                        size: 14,
                        color: Colors.grey,
                      ),
                      onTap: () => _selectItem(item),
                    );
                  },
                ),
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
          onSubmitted: (_) => _submit(),
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: widget.hintText,
            prefixIcon: const Icon(Icons.search, size: 20),
            suffixIcon: _isLoading
                ? const Padding(
                    padding: EdgeInsets.all(14),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : widget.controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () {
                      widget.controller.clear();
                      setState(() {
                        _suggestions = [];
                        _hasSearched = false;
                        _failed = false;
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
