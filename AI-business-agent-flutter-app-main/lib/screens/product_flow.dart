import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import '../services/ai_service.dart';
import '../widgets/address_autocomplete_field.dart';
import 'flow_localizations.dart';

const _accent = Color(0xFF8E44FF);
const _success = Color(0xFF30D158);

typedef AuditCallback =
    Future<Map<String, dynamic>?> Function({
      required String businessType,
      required List<String> problems,
      required String address,
    });

Future<String?> confirmUserLocation(BuildContext context) async {
  String? detectedCity;
  try {
    if (await Geolocator.isLocationServiceEnabled()) {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission != LocationPermission.denied &&
          permission != LocationPermission.deniedForever) {
        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
          ),
        );
        final url = Uri.https('nominatim.openstreetmap.org', '/reverse', {
          'format': 'json',
          'lat': position.latitude.toString(),
          'lon': position.longitude.toString(),
        });
        final response = await http.get(
          url,
          headers: const {'User-Agent': 'AI-Business-Agent'},
        );
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          final address = data['address'] as Map<String, dynamic>? ?? {};
          final city = address['city'] ?? address['town'] ?? address['municipality'];
          if (city != null && city.toString().trim().isNotEmpty) {
            detectedCity = city.toString().trim();
          }
        }
      }
    }
  } catch (_) {
    // GPS əlçatan olmadıqda istifadəçi şəhəri dialoqdan seçə bilər.
  }
  if (!context.mounted) return detectedCity;
  final cityController = TextEditingController(text: detectedCity ?? '');
  final result = await showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Axtarış şəhəri'),
      content: TextField(
        controller: cityController,
        autofocus: detectedCity == null,
        textInputAction: TextInputAction.done,
        decoration: const InputDecoration(
          labelText: 'Şəhər',
          hintText: 'Məsələn: Aktau, Bakı, Almatı',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            final city = cityController.text.trim();
            Navigator.pop(dialogContext, city.isEmpty ? null : city);
          },
          child: const Text('Dəyiş'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, cityController.text.trim()),
          child: const Text('Təsdiqlə'),
        ),
      ],
    ),
  );
  cityController.dispose();
  return result;
}

const businessCategoryIds = <String>[
  'business_cafe',
  'business_restaurant',
  'business_retail',
  'business_beauty',
  'business_health',
  'business_auto',
  'business_zoo',
  'business_lab',
  'business_fitness',
  'business_hotel_guesthouse',
  'business_pharmacy',
  'business_dentistry',
  'business_education',
  'business_pickup',
  'business_electronics',
  'business_repair',
  'business_flowers',
  'business_telecom',
];

class ProductDashboardScreen extends StatelessWidget {
  const ProductDashboardScreen({
    super.key,
    required this.onOldPoint,
    required this.onNewPoint,
    required this.audits,
    required this.onAuditSelected,
    required this.onAuditDeleted,
    required this.mapProvider,
    required this.onMapProviderChanged,
    required this.localeCode,
  });

  final VoidCallback onOldPoint;
  final VoidCallback onNewPoint;
  final List<Map<String, dynamic>> audits;
  final ValueChanged<Map<String, dynamic>> onAuditSelected;
  final ValueChanged<Map<String, dynamic>> onAuditDeleted;
  final String mapProvider;
  final ValueChanged<String> onMapProviderChanged;
  final String localeCode;

  @override
  Widget build(BuildContext context) {
    final oldPointCount = audits
      .where(
        (audit) =>
          audit['flowType'] == null || audit['flowType'] == 'old',
      )
      .length;
    final newPointCount = audits
      .where((audit) => audit['flowType'] == 'new')
      .length;
    final scheme = Theme.of(context).colorScheme;
    final t = (String key) => FlowLocalizations.t(localeCode, key);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1B1E28);
    final mutedColor = isDark ? Colors.grey : Colors.black54;
    final surfaceColor = isDark ? const Color(0xFF1E1E22) : Colors.white;
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      t('assistantTitle'),
                      style: TextStyle(color: mutedColor, fontSize: 11),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      t('dashboardSubtitle'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _DashboardActionCard(
                            icon: Icons.trending_up,
                            title: t('oldPoint'),
                            subtitle: t('oldPointSubtitle'),
                            onTap: onOldPoint,
                            surfaceColor: surfaceColor,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _DashboardActionCard(
                            icon: Icons.search,
                            title: t('newPoint'),
                            subtitle: t('newPointSubtitle'),
                            onTap: onNewPoint,
                            surfaceColor: surfaceColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _DashboardStatCard(
                            title: t('oldPoint'),
                            value: oldPointCount.toString(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _DashboardStatCard(
                            title: t('newPoint'),
                            value: newPointCount.toString(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    if (audits.isNotEmpty) ...[
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          t('savedAudits'),
                          style: TextStyle(
                            color: textColor,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 112,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: audits.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            final audit = audits[index];
                            final analysis = audit['analysis'] is Map
                                ? audit['analysis'] as Map
                                : const <dynamic, dynamic>{};
                            final title =
                                (audit['displayAddress'] ??
                                        audit['address'] ??
                                        analysis['address'] ??
                                        t('mapTitle'))
                                    .toString();
                            return SizedBox(
                              width: 220,
                              child: _DashboardAuditCard(
                                address: title,
                                date: (audit['displayDate'] ?? '').toString(),
                                onTap: () => onAuditSelected(audit),
                                onDelete: () =>
                                    _confirmAuditDelete(context, audit),
                                deleteLabel: t('deleteAudit'),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                    Text(
                      t('dashboardFooter'),
                      textAlign: TextAlign.center,
                      style: TextStyle(color: scheme.outline, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmAuditDelete(
    BuildContext context,
    Map<String, dynamic> audit,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(FlowLocalizations.t(localeCode, 'deleteAudit')),
        content: Text(FlowLocalizations.t(localeCode, 'deleteAuditConfirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(FlowLocalizations.t(localeCode, 'cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(FlowLocalizations.t(localeCode, 'deleteAudit')),
          ),
        ],
      ),
    );
    if (confirmed == true) onAuditDeleted(audit);
  }
}

class _DashboardActionCard extends StatelessWidget {
  const _DashboardActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.surfaceColor,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color surfaceColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: surfaceColor,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          height: 140,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _accent, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: _accent.withValues(alpha: .24),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const Spacer(),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  color: _accent,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardStatCard extends StatelessWidget {
  const _DashboardStatCard({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E22) : Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: isDark ? Colors.grey : Colors.black54,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF1B1E28),
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardAuditCard extends StatelessWidget {
  const _DashboardAuditCard({
    required this.address,
    required this.date,
    required this.onTap,
    required this.onDelete,
    required this.deleteLabel,
  });

  final String address;
  final String date;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final String deleteLabel;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.assignment_turned_in_outlined, size: 18),
                  const Spacer(),
                  Text(
                    address,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (date.isNotEmpty)
                    Text(
                      date,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                ],
              ),
              Positioned(
                top: -10,
                right: -10,
                child: IconButton(
                  onPressed: onDelete,
                  tooltip: deleteLabel,
                  icon: const Icon(Icons.delete_outline, size: 18),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class OldPointSurveyScreen extends StatefulWidget {
  const OldPointSurveyScreen({
    super.key,
    required this.onBack,
    required this.onAudit,
    required this.localeCode,
    this.city = '',
  });

  final VoidCallback onBack;
  final AuditCallback onAudit;
  final String localeCode;
  final String city;

  @override
  State<OldPointSurveyScreen> createState() => _OldPointSurveyScreenState();
}

class _OldPointSurveyScreenState extends State<OldPointSurveyScreen> {
  final _addressController = TextEditingController();
  final _otherSectorController = TextEditingController();
  final _otherBusinessController = TextEditingController();
  final _otherProblemController = TextEditingController();
  final _businesses = businessCategoryIds;
  final _problems = const [
    'problem_traffic',
    'problem_competitors',
    'problem_ticket',
    'problem_customers',
    'problem_visibility',
  ];
  final Set<String> _selectedBusinesses = {};
  final Set<String> _selectedProblems = {};
  bool _otherSector = false;
  bool _otherBusiness = false;
  bool _otherProblem = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _addressController.dispose();
    _otherSectorController.dispose();
    _otherBusinessController.dispose();
    _otherProblemController.dispose();
    super.dispose();
  }

  Future<void> _audit() async {
    final hasCustomBusiness =
        _otherSectorController.text.trim().isNotEmpty ||
        _otherBusinessController.text.trim().isNotEmpty;
    if ((_selectedBusinesses.isEmpty && !hasCustomBusiness) ||
        _addressController.text.trim().isEmpty) {
      return;
    }
    setState(() => _isLoading = true);
    final business = [
      ..._selectedBusinesses.map(
        (id) => FlowLocalizations.t(widget.localeCode, id),
      ),
      if (_otherSectorController.text.trim().isNotEmpty)
        _otherSectorController.text.trim(),
      if (_otherBusinessController.text.trim().isNotEmpty)
        _otherBusinessController.text.trim(),
    ].join(', ');
    final problems = [
      ..._selectedProblems.map(
        (id) => FlowLocalizations.t(widget.localeCode, id),
      ),
      if (_otherProblemController.text.trim().isNotEmpty)
        _otherProblemController.text.trim(),
    ];
    try {
      await widget.onAudit(
        businessType: business,
        problems: problems,
        address: _addressController.text.trim(),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${FlowLocalizations.t(widget.localeCode, 'auditFailed')}: $error',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final t = (String key) => FlowLocalizations.t(widget.localeCode, key);
    final canAudit =
        (_selectedBusinesses.isNotEmpty ||
            _otherSectorController.text.trim().isNotEmpty ||
            _otherBusinessController.text.trim().isNotEmpty) &&
        _addressController.text.trim().isNotEmpty;
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  TextButton.icon(
                    onPressed: widget.onBack,
                    icon: const Icon(Icons.arrow_back_ios, size: 14),
                    label: Text(t('close')),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey,
                      padding: EdgeInsets.zero,
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      t('oldPointHeader'),
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 19,
                      ),
                    ),
                  ),
                  _FreeBadge(localeCode: widget.localeCode),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: _SectionTitle(
              title: t('businessSection'),
              subtitle: t('businessSectionSubtitle'),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate((context, index) {
                final id = _businesses[index];
                final label = t(id);
                return _ToggleTile(
                  label: label,
                  selected: _selectedBusinesses.contains(id),
                  onTap: () => setState(() {
                    if (!_selectedBusinesses.add(id)) {
                      _selectedBusinesses.remove(id);
                    }
                  }),
                );
              }, childCount: _businesses.length),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 2.4,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: _OtherInputTile(
                label: t('otherSector'),
                active: _otherSector,
                controller: _otherSectorController,
                suggestions: [
                  t('business_cafe'),
                  t('business_restaurant'),
                  t('business_hotel_guesthouse'),
                  t('business_auto'),
                  t('business_education'),
                ],
                closeLabel: t('close'),
                hintText: t('autocompleteHint'),
                onTap: () => setState(() => _otherSector = !_otherSector),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: _OtherInputTile(
                label: t('otherBusiness'),
                active: _otherBusiness,
                controller: _otherBusinessController,
                suggestions: const [],
                closeLabel: t('close'),
                hintText: t('autocompleteHint'),
                onTap: () => setState(() => _otherBusiness = !_otherBusiness),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: _SectionTitle(
              title: t('problemSection'),
              subtitle: t('problemSectionSubtitle'),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final id = _problems[index];
                final label = t(id);
                final selected = _selectedProblems.contains(id);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _CheckboxTile(
                    label: label,
                    selected: selected,
                    onTap: () => setState(() {
                      if (selected) {
                        _selectedProblems.remove(id);
                      } else if (_selectedProblems.length < 2) {
                        _selectedProblems.add(id);
                      }
                    }),
                  ),
                );
              }, childCount: _problems.length),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: _OtherInputTile(
                label: t('otherProblem'),
                active: _otherProblem,
                controller: _otherProblemController,
                closeLabel: t('close'),
                hintText: t('autocompleteHint'),
                onTap: () => setState(() => _otherProblem = !_otherProblem),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: _SectionTitle(
              title: t('addressSection'),
              subtitle: t('addressSectionSubtitle'),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: AddressAutocompleteField(
                controller: _addressController,
                hintText: t('addressHint'),
                isBottomInput: true,
                city: widget.city,
                onSelected: (_) => setState(() {}),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFD946EF), Color(0xFFA855F7)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFD946EF).withValues(alpha: .45),
                      blurRadius: 15,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: canAudit && !_isLoading ? _audit : null,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.auto_awesome, size: 16),
                  label: Text(_isLoading ? t('auditLoading') : t('auditStart')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    disabledBackgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 30),
              child: Text(
                t('freeAuditNote'),
                textAlign: TextAlign.center,
                style: TextStyle(color: scheme.outline, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AuditReportScreen extends StatelessWidget {
  const AuditReportScreen({
    super.key,
    required this.analysis,
    required this.address,
    required this.onBack,
    required this.onMap,
    required this.localeCode,
  });

  final Map<String, dynamic>? analysis;
  final String address;
  final VoidCallback onBack;
  final VoidCallback onMap;
  final String localeCode;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final t = (String key) => FlowLocalizations.t(localeCode, key);
    final rawScore = num.tryParse('${analysis?['score'] ?? ''}') ?? 0;
    final score = rawScore > 10 ? rawScore / 10 : rawScore;
    final traffic = analysis?['pedestrian_traffic'];
    final trafficEstimate = analysis?['pedestrian_traffic_estimate'];
    final reportAddress = address.isEmpty ? 'Актау, 14 мкр' : address;
    final competitors = analysis?['competitors'] is List
        ? (analysis!['competitors'] as List).whereType<Map>().toList()
        : <Map>[];
    final insights = analysis?['insights'] is Map
        ? analysis!['insights'] as Map
        : <dynamic, dynamic>{};
    final noise = insights['digital_noise'] is Map
        ? insights['digital_noise'] as Map
        : <dynamic, dynamic>{};
    final peak = insights['peak_comparison'] is Map
        ? insights['peak_comparison'] as Map
        : <dynamic, dynamic>{};
    final magnets = insights['location_magnets'] is Map
        ? insights['location_magnets'] as Map
        : <dynamic, dynamic>{};
    final transportStops = analysis?['transport_stops'] is List
        ? (analysis!['transport_stops'] as List).whereType<Map>().toList()
        : <Map>[];
    final parking = analysis?['parking'] is List
        ? (analysis!['parking'] as List).whereType<Map>().toList()
        : <Map>[];
    final reviewLeaders = noise['leaders'] is List
        ? (noise['leaders'] as List).whereType<Map>().toList()
        : <Map>[];
    return SafeArea(
      child: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 86),
            children: [
              Row(
                children: [
                  TextButton.icon(
                    onPressed: onBack,
                    icon: const Icon(Icons.arrow_back_ios, size: 14),
                    label: Text(t('close')),
                    style: TextButton.styleFrom(foregroundColor: Colors.grey),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        t('auditReady'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => _showUpgrade(context),
                    icon: const Icon(Icons.download_outlined),
                  ),
                ],
              ),
              _ReportBlock(
                child: Row(
                  children: [
                    _ScoreRing(score: score),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'ОЦЕНКА ЛОКАЦИИ',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${score.toStringAsFixed(1)}/10',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const _StatusBadge(label: 'Высокий потенциал'),
                          const SizedBox(height: 5),
                          Text(
                            reportAddress,
                            style: TextStyle(
                              fontSize: 11,
                              color: scheme.outline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _ReportBlock(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t('stops'),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (transportStops.isEmpty)
                      Text(_insightText('noStopsData'))
                    else
                      ...transportStops
                          .take(5)
                          .map(
                            (item) => Text(
                              '${item['name'] ?? t('stops')} • ${_formatMeters(item['distance_meters'])}${item['address'] == null || item['address'] == '' ? '' : ' • ${item['address']}'}',
                              style: const TextStyle(fontSize: 11),
                            ),
                          ),
                    const SizedBox(height: 12),
                    Text(
                      t('parking'),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (parking.isEmpty)
                      Text(_insightText('noParkingData'))
                    else
                      ...parking
                          .take(5)
                          .map(
                            (item) => Text(
                              '${item['name'] ?? t('parking')} • ${_formatMeters(item['distance_meters'])}${item['capacity'] == null ? '' : ' • ${item['capacity']}'}',
                              style: const TextStyle(fontSize: 11),
                            ),
                          ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _ReportBlock(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t('traffic'),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _insightText('activityByHours'),
                      style: TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                    const SizedBox(height: 14),
                    if (traffic is List && traffic.isNotEmpty)
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: traffic.whereType<Map>().map((item) {
                            final label = (item['hour'] ?? item['time'] ?? '')
                                .toString();
                            final value =
                                (num.tryParse(
                                          '${item['value'] ?? item['level'] ?? 0}',
                                        ) ??
                                        0)
                                    .clamp(0, 1)
                                    .toDouble();
                            return Padding(
                              padding: const EdgeInsets.only(right: 10),
                              child: _TrafficBar(label, value),
                            );
                          }).toList(),
                        ),
                      )
                    else
                      Text(
                        trafficEstimate == null
                            ? _insightText('noTrafficData')
                            : '~$trafficEstimate • ${_insightText('estimatedTraffic')}',
                        style: TextStyle(fontSize: 12, color: scheme.primary),
                      ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(
                          Icons.show_chart,
                          size: 14,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          traffic == null
                              ? _insightText('trafficSourceNote')
                              : '$traffic • ${_insightText('peakDataNote')}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _ReportBlock(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t('competitors'),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12),
                    if (competitors.isEmpty)
                      Text(_insightText('noCompetitorData'))
                    else
                      ...competitors.map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _CompetitorTile(
                            item['name']?.toString() ?? '2GIS',
                            item['rubrics'] is List &&
                                    (item['rubrics'] as List).isNotEmpty
                                ? (item['rubrics'] as List).first.toString()
                                : _insightText('businessObject'),
                            item['rating']?.toString() ?? '—',
                            _formatMeters(item['distance_meters']),
                            details: [
                              '${t('parking')}: ${_formatMeters(item['nearest_parking_meters'])}${item['parking_within_500m'] == null ? '' : ' (${item['parking_within_500m']})'}',
                              '${t('stops')}: ${_formatMeters(item['nearest_transport_meters'])}${item['transport_stops_within_500m'] == null ? '' : ' (${item['transport_stops_within_500m']})'}',
                              '${t('reviews')}: ${item['review_count'] ?? '—'}',
                              if (item['comments'] is List &&
                                  (item['comments'] as List).isNotEmpty)
                                '${t('comments')}: ${(item['comments'] as List).take(2).map((comment) => comment is Map ? comment['text'] : comment).join(' • ')}',
                              '${t('traffic')}: ${t('trafficUnavailable')}',
                              if (item['schedule_available'] == true ||
                                  item['schedule'] != null)
                                t('hoursAvailable'),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 4),
                    _ReportBlock(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _insightText('digitalNoise'),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            reviewLeaders.isEmpty
                                ? _insightText('noReviewData')
                                : reviewLeaders
                                      .take(3)
                                      .map(
                                        (item) =>
                                            '${item['name']}: ${item['review_count']}',
                                      )
                                      .join(' • '),
                            style: TextStyle(
                              color: scheme.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            _insightText('reviewDataNote'),
                            style: TextStyle(
                              color: scheme.outline,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _ReportBlock(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _insightText('peakComparison'),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${_insightText('scheduleSources')}: ${peak['schedule_available_for'] ?? 0}/${peak['competitors_sample'] ?? competitors.length}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            peak['comparison_available'] == true
                                ? '${_insightText('scheduleNote')} ${_insightText('scheduleAvailable')}'
                                : _insightText('scheduleUnavailable'),
                            style: TextStyle(
                              color: scheme.outline,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _ReportBlock(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _insightText('locationMagnets'),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _insightText(
                              'magnetSummary',
                              values: {
                                'transport':
                                    magnets['nearest_transport_meters'] ?? '—',
                                'place': magnets['nearest_place_name'] ?? '—',
                                'competitor':
                                    magnets['competitor_distance_meters'] ??
                                    '—',
                              },
                            ),
                            style: const TextStyle(fontSize: 12, height: 1.35),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 16,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: const LinearGradient(
                  colors: [Color(0xFF8B5CF6), Color(0xFFD946EF)],
                ),
                boxShadow: [
                  BoxShadow(color: Color(0x66D946EF), blurRadius: 12),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: () => _showAiQuestion(context, onMap),
                icon: const Icon(
                  Icons.auto_awesome,
                  color: Colors.white,
                  size: 16,
                ),
                label: const Text(
                  'Задать вопрос ИИ по отчёту',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  minimumSize: const Size.fromHeight(44),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatMeters(dynamic value) {
    final meters = num.tryParse(value?.toString() ?? '');
    if (meters == null) return '—';
    return meters >= 1000
        ? '${(meters / 1000).toStringAsFixed(1)} km'
        : '${meters.round()} m';
  }

  String _insightText(String key, {Map<String, Object?> values = const {}}) {
    const texts = {
      'az': {
        'digitalNoise': 'Rəqəmsal küy — rəylərin dinamikası',
        'activityByHours': 'Pik saatların müqayisəsi',
        'noTrafficData': 'Saatlıq real piyada məlumatı yoxdur',
        'estimatedTraffic': 'canlı yerlər əsasında təxmini indeks',
        'trafficSourceNote':
            'Piyada sayı 2GIS Pro məlumatı olmadan dəqiq hesablanmır.',
        'peakDataNote': 'Məşğulluq məlumatı 2GIS cədvəlləri olduqda göstərilir',
        'nearestPoints': 'ən yaxın nöqtə',
        'noCompetitorData': 'Bu ərazi üçün rəqib məlumatı tapılmadı',
        'noStopsData': 'Dayanacaq məlumatı tapılmadı',
        'noParkingData': 'Parking məlumatı tapılmadı',
        'businessObject': 'Biznes obyekti',
        'noReviewData': 'Rəylər üzrə kifayət qədər məlumat yoxdur',
        'reviewDataNote':
            'Müqayisə 2GIS-də görünən cari rəy saylarına əsaslanır; son 30 günlük artım API-də açıq deyil.',
        'peakComparison': 'Pik saatların müqayisəsi',
        'scheduleSources': 'İş qrafiki olan rəqiblər',
        'scheduleNote': 'Real doluluq faizi 2GIS məlumatı olduqda hesablanır.',
        'scheduleAvailable': 'Qrafik məlumatı müqayisə üçün mövcuddur.',
        'scheduleUnavailable': 'Müqayisə üçün 2GIS qrafik məlumatı yoxdur.',
        'locationMagnets': 'Lokasiya maqnitləri',
        'magnetSummary':
            'Ən yaxın dayanacaq: {transport} m. Yaxın trafik obyekti: {place} ({competitor} m məsafədəki ən yaxın rəqib).',
      },
      'en': {
        'digitalNoise': 'Digital noise — review dynamics',
        'activityByHours': 'Peak-hour comparison',
        'noTrafficData': 'No real hourly pedestrian data',
        'estimatedTraffic': 'estimated index from live places',
        'trafficSourceNote': 'Pedestrian counts require the 2GIS Pro dataset.',
        'peakDataNote':
            'Occupancy data is shown when 2GIS schedules are available',
        'nearestPoints': 'nearest locations',
        'noCompetitorData': 'No competitor data found for this area',
        'noStopsData': 'No stop data found',
        'noParkingData': 'No parking data found',
        'businessObject': 'Business location',
        'noReviewData': 'Not enough review data',
        'reviewDataNote':
            'Comparison uses current review totals visible in 2GIS; a 30-day delta is not public in the API.',
        'peakComparison': 'Peak-hour comparison',
        'scheduleSources': 'Competitors with schedules',
        'scheduleNote':
            'Real occupancy is calculated when 2GIS data is available.',
        'scheduleAvailable': 'Schedule data is available for comparison.',
        'scheduleUnavailable':
            'No 2GIS schedule data is available for comparison.',
        'locationMagnets': 'Location magnets',
        'magnetSummary':
            'Nearest stop: {transport} m. Nearby traffic place: {place}. Nearest competitor: {competitor} m.',
      },
      'ru': {
        'digitalNoise': 'Цифровой шум — динамика отзывов',
        'activityByHours': 'Сравнение пиковых часов',
        'noTrafficData': 'Нет реальных почасовых данных о пешеходах',
        'estimatedTraffic': 'оценочный индекс по живым объектам',
        'trafficSourceNote': 'Точный поток требует набора данных 2GIS Pro.',
        'peakDataNote':
            'Данные о загрузке показываются при наличии расписаний 2GIS',
        'nearestPoints': 'ближайших точек',
        'noCompetitorData': 'Для этой зоны данные о конкурентах не найдены',
        'businessObject': 'Бизнес-объект',
        'noReviewData': 'Недостаточно данных об отзывах',
        'reviewDataNote':
            'Сравнение основано на текущем числе отзывов в 2GIS; прирост за 30 дней публично не доступен.',
        'peakComparison': 'Сравнение пиковых часов',
        'scheduleSources': 'Конкуренты с графиком',
        'scheduleNote':
            'Реальная загрузка рассчитывается при наличии данных 2GIS.',
        'scheduleAvailable': 'Данные графика доступны для сравнения.',
        'scheduleUnavailable': 'Нет данных графика 2GIS для сравнения.',
        'locationMagnets': 'Магниты локации',
        'magnetSummary':
            'Ближайшая остановка: {transport} м. Объект-трафикогенератор: {place}. Ближайший конкурент: {competitor} м.',
      },
      'kk': {
        'digitalNoise': 'Цифрлық шу — пікір динамикасы',
        'activityByHours': 'Қарбалас уақыттарды салыстыру',
        'noTrafficData': 'Нақты сағаттық жаяу жүргінші дерегі жоқ',
        'estimatedTraffic':
            'жұмыс істеп тұрған нысандар бойынша болжамды индекс',
        'trafficSourceNote':
            'Жаяу жүргінші саны 2GIS Pro деректерін қажет етеді.',
        'peakDataNote': 'Толу деректері 2GIS кестелері болғанда көрсетіледі',
        'nearestPoints': 'ең жақын нүкте',
        'noCompetitorData': 'Бұл аймақ бойынша бәсекелес дерегі табылмады',
        'businessObject': 'Бизнес нысаны',
        'noReviewData': 'Пікірлер туралы дерек жеткіліксіз',
        'reviewDataNote':
            'Салыстыру 2GIS-тегі ағымдағы пікір санына негізделеді; 30 күндік өсім API-де ашық емес.',
        'peakComparison': 'Қарбалас уақыттарды салыстыру',
        'scheduleSources': 'Кестесі бар бәсекелестер',
        'scheduleNote': 'Нақты толу 2GIS деректері болғанда есептеледі.',
        'scheduleAvailable': 'Кесте деректері салыстыруға қолжетімді.',
        'scheduleUnavailable': 'Салыстыру үшін 2GIS кесте деректері жоқ.',
        'locationMagnets': 'Орын магниттері',
        'magnetSummary':
            'Ең жақын аялдама: {transport} м. Жақын нысан: {place}. Ең жақын бәсекелес: {competitor} м.',
      },
    };
    var result = texts[localeCode]?[key] ?? texts['az']![key] ?? key;
    values.forEach(
      (name, value) => result = result!.replaceAll('{$name}', '$value'),
    );
    return result!;
  }

  void _showAiQuestion(BuildContext context, VoidCallback mapCallback) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.auto_awesome, color: _accent),
              title: Text(FlowLocalizations.t(localeCode, 'askAiReport')),
            ),
            ListTile(
              leading: const Icon(Icons.map_outlined),
              title: Text(FlowLocalizations.t(localeCode, 'viewMap')),
              onTap: () {
                Navigator.pop(sheetContext);
                mapCallback();
              },
            ),
            ListTile(
              leading: const Icon(Icons.lock_open_outlined),
              title: Text(FlowLocalizations.t(localeCode, 'fullReport')),
              onTap: () {
                Navigator.pop(sheetContext);
                _showUpgrade(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showUpgrade(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          FlowLocalizations.t(localeCode, 'paidUpgrade'),
          style: TextStyle(fontSize: 16, height: 1.4),
        ),
      ),
    );
  }
}

class _ReportBlock extends StatelessWidget {
  const _ReportBlock({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF1E1E22)
          : Colors.white,
      borderRadius: BorderRadius.circular(16),
    ),
    child: child,
  );
}

class _ScoreRing extends StatelessWidget {
  const _ScoreRing({required this.score});
  final num score;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 65,
    height: 65,
    child: Stack(
      alignment: Alignment.center,
      children: [
        SizedBox.expand(
          child: CircularProgressIndicator(
            value: (score / 10).clamp(0, 1).toDouble(),
            strokeWidth: 6,
            valueColor: const AlwaysStoppedAnimation(Color(0xFF10B981)),
            backgroundColor: Color(0xFF1F2937),
          ),
        ),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              score.toStringAsFixed(1),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Text(
              'из 10',
              style: TextStyle(fontSize: 8, color: Colors.grey),
            ),
          ],
        ),
      ],
    ),
  );
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: const Color(0xFF064E3B),
      borderRadius: BorderRadius.circular(6),
    ),
    child: const Text(
      'Высокий потенциал',
      style: TextStyle(
        color: Color(0xFF34D399),
        fontSize: 10,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}

class _TrafficBar extends StatelessWidget {
  const _TrafficBar(this.time, this.factor, {this.highlighted = false});
  final String time;
  final double factor;
  final bool highlighted;
  @override
  Widget build(BuildContext context) => Column(
    mainAxisAlignment: MainAxisAlignment.end,
    children: [
      Container(
        width: 24,
        height: 60 * factor,
        decoration: BoxDecoration(
          color: highlighted
              ? const Color(0xFFA855F7)
              : const Color(0xFF3F3F46),
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      const SizedBox(height: 6),
      Text(time, style: const TextStyle(fontSize: 8, color: Colors.grey)),
    ],
  );
}

class _CompetitorTile extends StatelessWidget {
  const _CompetitorTile(
    this.name,
    this.category,
    this.rating,
    this.distance, {
    this.details = const [],
  });
  final String name;
  final String category;
  final String rating;
  final String distance;
  final List<String> details;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      color: const Color(0xFF18181B),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.purple.withValues(alpha: .2),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.store, color: Colors.purpleAccent, size: 16),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                category,
                style: const TextStyle(color: Colors.grey, fontSize: 10),
              ),
              if (details.isNotEmpty) ...[
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  runSpacing: 2,
                  children: details
                      .map(
                        (detail) => Text(
                          detail,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 9,
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ],
          ),
        ),
        const Icon(Icons.star, color: Colors.amber, size: 12),
        const SizedBox(width: 2),
        Text(
          rating,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          distance,
          style: const TextStyle(color: Colors.grey, fontSize: 10),
        ),
      ],
    ),
  );
}

class _ReportMetric extends StatelessWidget {
  const _ReportMetric({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );
}

class NewPointAssistantScreen extends StatefulWidget {
  const NewPointAssistantScreen({
    super.key,
    required this.onBack,
    required this.onMap,
    required this.onAnalyze,
    required this.localeCode,
    this.initialCity = '',
  });
  final VoidCallback onBack;
  final VoidCallback onMap;
  final Future<void> Function(String businessType, String address, String city) onAnalyze;
  final String localeCode;
  final String initialCity;

  @override
  State<NewPointAssistantScreen> createState() =>
      _NewPointAssistantScreenState();
}

class _NewPointAssistantScreenState extends State<NewPointAssistantScreen> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  final _ai = AiService();
  late List<_FlowMessage> _messages;
  String? _mode;
  String? _business;
  String? _address;
  bool _loading = false;
  String _city = '';

  String _t(String key) => FlowLocalizations.t(widget.localeCode, key);

  @override
  void initState() {
    super.initState();
    _messages = [
      _FlowMessage(
        'assistant',
        _t('assistantWelcome'),
        actions: const ['startNew', 'ownAddress'],
      ),
    ];
    _city = widget.initialCity;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_messages.length == 1) {
      _messages[0] = _FlowMessage(
        'assistant',
        _t('assistantWelcome'),
        actions: const ['startNew', 'ownAddress'],
      );
    }
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _add(String author, String text, {List<String> actions = const []}) {
    setState(() => _messages.add(_FlowMessage(author, text, actions: actions)));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _choose(String value) async {
    _add('user', _t(value));
    if (value == 'startNew') {
      _mode = 'new';
      _add(
        'assistant',
        _t('chooseBusiness'),
        actions: const [...businessCategoryIds, 'otherSector', 'otherBusiness'],
      );
    } else if (value == 'otherSector' || value == 'otherBusiness') {
      _mode = 'customBusiness';
      _add('assistant', _t('writeCustomBusiness'));
    } else if (value == 'ownAddress') {
      _mode = 'address';
      _add('assistant', _t('writeAddress'));
    } else if (_mode == 'new' && _business == null) {
      _business = value;
      _add('assistant', _t('writeArea'));
    } else if (_mode == 'address' && _address != null && _business == null) {
      _business = value;
      await _finishFlow();
    } else if (_business == null) {
      _business = value;
      _add('assistant', _t('writeAddressOrCity'));
    } else {
      _address = value;
      await _finishFlow();
    }
  }

  Future<void> _finishFlow() async {
    if (_business == null || _address == null) return;
    setState(() => _loading = true);
    try {
      await widget.onAnalyze(_t(_business!), _address!, _city);
      if (!mounted) return;
      setState(() => _loading = false);
      _add('assistant', _t('analysisReady'), actions: const ['mapZones']);
    } catch (error) {
      if (!mounted) return;
      setState(() => _loading = false);
      _add('assistant', '${_t('analysisFailed')}: $error');
    }
  }

  Future<void> _send() async {
    final text = _inputController.text.trim();
    if (text.isEmpty || _loading) return;
    _inputController.clear();
    _add('user', text);
    if (_mode == 'customBusiness' && _business == null) {
      _business = text;
      if (_address != null) {
        await _finishFlow();
      } else {
        _mode = 'new';
        _add('assistant', _t('writeArea'));
      }
      return;
    }
    if (_mode == 'address' && _business == null) {
      _address = text;
      _add(
        'assistant',
        _t('selectBusiness'),
        actions: const [...businessCategoryIds, 'otherSector', 'otherBusiness'],
      );
      return;
    }
    if (_business != null && _address == null) {
      _address = text;
      await _finishFlow();
      return;
    }
    setState(() => _loading = true);
    final answer = await _ai.generateResponse(
      text,
      language: widget.localeCode,
    );
    if (!mounted) return;
    setState(() => _loading = false);
    _add('assistant', answer);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 16, 8),
            child: Row(
              children: [
                IconButton(
                  onPressed: widget.onBack,
                  icon: const Icon(Icons.arrow_back),
                ),
                const CircleAvatar(
                  backgroundColor: Color(0x268E44FF),
                  child: Icon(Icons.smart_toy_outlined, color: _accent),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _t('assistantTitle'),
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        _t('assistantSubtitle'),
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.circle, color: _success, size: 10),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final isUser = message.author == 'user';
                return Align(
                  alignment: isUser
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    constraints: const BoxConstraints(maxWidth: 340),
                    child: Column(
                      crossAxisAlignment: isUser
                          ? CrossAxisAlignment.end
                          : CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isUser
                                ? _accent
                                : Theme.of(context).cardTheme.color,
                            borderRadius: BorderRadius.circular(16),
                            border: isUser
                                ? null
                                : Border.all(
                                    color: Theme.of(context).dividerColor,
                                  ),
                          ),
                          child: Text(
                            message.text,
                            style: TextStyle(
                              color: isUser ? Colors.white : null,
                              height: 1.35,
                            ),
                          ),
                        ),
                        if (message.actions.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: message.actions
                                  .map(
                                    (action) => OutlinedButton(
                                      onPressed: action == 'mapZones'
                                          ? widget.onMap
                                          : () => _choose(action),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: _accent,
                                        side: const BorderSide(color: _accent),
                                      ),
                                      child: Text(_t(action)),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          if (_loading)
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: LinearProgressIndicator(minHeight: 2, color: _accent),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: AddressAutocompleteField(
                    controller: _inputController,
                    hintText: _t('chatHint'),
                    isBottomInput: true,
                    city: _city,
                    onSelected: (_) => _send(),
                    onSubmitted: _send,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _loading ? null : _send,
                  icon: const Icon(Icons.send_rounded),
                  style: IconButton.styleFrom(
                    backgroundColor: _accent,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FlowMessage {
  const _FlowMessage(this.author, this.text, {this.actions = const []});
  final String author;
  final String text;
  final List<String> actions;
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});
  final String title;
  final String subtitle;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: TextStyle(
            color: Theme.of(context).colorScheme.outline,
            fontSize: 12,
          ),
        ),
      ],
    ),
  );
}

class _FreeBadge extends StatelessWidget {
  const _FreeBadge({required this.localeCode});
  final String localeCode;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: _success.withValues(alpha: .14),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      FlowLocalizations.t(localeCode, 'free'),
      style: TextStyle(
        color: _success,
        fontWeight: FontWeight.w700,
        fontSize: 12,
      ),
    ),
  );
}

class _ToggleTile extends StatelessWidget {
  const _ToggleTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
    color: selected ? const Color(0xFF24103F) : const Color(0xFF141414),
    borderRadius: BorderRadius.circular(8),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected
                ? const Color(0xFFB026FF)
                : const Color(0xFFB026FF).withValues(alpha: .38),
            width: selected ? 2 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: const Color(0xFFB026FF).withValues(alpha: .55),
                    blurRadius: 16,
                    spreadRadius: 1,
                  ),
                ]
              : const [],
        ),
        child: Center(
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ),
      ),
    ),
  );
}

class _CheckboxTile extends StatelessWidget {
  const _CheckboxTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: selected ? const Color(0xFF24103F) : const Color(0xFF141414),
    borderRadius: BorderRadius.circular(8),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        constraints: const BoxConstraints(minHeight: 48),
        padding: const EdgeInsets.only(left: 12, right: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected
                ? const Color(0xFFB026FF)
                : const Color(0xFFB026FF).withValues(alpha: .38),
            width: selected ? 2 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: const Color(0xFFB026FF).withValues(alpha: .45),
                    blurRadius: 12,
                  ),
                ]
              : const [],
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ),
            Checkbox(
              value: selected,
              onChanged: (_) => onTap(),
              activeColor: _accent,
              checkColor: Colors.white,
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    ),
  );
}

class _OtherInputTile extends StatelessWidget {
  const _OtherInputTile({
    required this.label,
    required this.active,
    required this.controller,
    required this.onTap,
    required this.closeLabel,
    required this.hintText,
    this.suggestions = const [],
  });
  final String label;
  final bool active;
  final TextEditingController controller;
  final VoidCallback onTap;
  final String closeLabel;
  final String hintText;
  final List<String> suggestions;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(active ? Icons.close : Icons.add),
        label: Text(active ? closeLabel : label),
        style: OutlinedButton.styleFrom(
          foregroundColor: _accent,
          side: const BorderSide(color: _accent),
        ),
      ),
      if (active)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Autocomplete<String>(
            optionsBuilder: (value) => value.text.trim().isEmpty
                ? suggestions
                : suggestions.where(
                    (item) =>
                        item.toLowerCase().startsWith(value.text.toLowerCase()),
                  ),
            onSelected: (value) => controller.text = value,
            fieldViewBuilder:
                (context, textController, focusNode, onFieldSubmitted) {
                  textController.text = controller.text;
                  textController.selection = TextSelection.collapsed(
                    offset: textController.text.length,
                  );
                  return TextField(
                    controller: textController,
                    focusNode: focusNode,
                    onChanged: (value) => controller.text = value,
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: hintText,
                    ),
                  );
                },
          ),
        ),
    ],
  );
}
