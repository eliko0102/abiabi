import 'package:flutter/material.dart';

import '../services/ai_service.dart';
import 'flow_localizations.dart';

const _accent = Color(0xFF8E44FF);
const _success = Color(0xFF30D158);

typedef AuditCallback =
    Future<Map<String, dynamic>?> Function({
      required String businessType,
      required List<String> problems,
      required String address,
    });

class ProductDashboardScreen extends StatelessWidget {
  const ProductDashboardScreen({
    super.key,
    required this.onOldPoint,
    required this.onNewPoint,
    required this.localeCode,
  });

  final VoidCallback onOldPoint;
  final VoidCallback onNewPoint;
  final String localeCode;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final t = (String key) => FlowLocalizations.t(localeCode, key);
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: Column(
              children: [
                Container(
                  width: 74,
                  height: 74,
                  decoration: BoxDecoration(
                    color: _accent.withValues(alpha: .16),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: _accent.withValues(alpha: .65)),
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    color: _accent,
                    size: 38,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'EAI Analytics',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  t('dashboardSubtitle'),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: scheme.outline, height: 1.4),
                ),
                const SizedBox(height: 32),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _DashboardActionCard(
                        icon: Icons.storefront_outlined,
                        title: t('oldPoint'),
                        subtitle: t('oldPointSubtitle'),
                        onTap: onOldPoint,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _DashboardActionCard(
                        icon: Icons.explore_outlined,
                        title: t('newPoint'),
                        subtitle: t('newPointSubtitle'),
                        onTap: onNewPoint,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
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
    );
  }
}

class _DashboardActionCard extends StatelessWidget {
  const _DashboardActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Theme.of(context).cardTheme.color,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 205),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _accent.withValues(alpha: .55)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: _accent, size: 34),
              const SizedBox(height: 50),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: TextStyle(color: scheme.outline, fontSize: 12),
              ),
              const SizedBox(height: 14),
              const Align(
                alignment: Alignment.centerRight,
                child: Icon(Icons.arrow_forward_rounded, color: _accent),
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
  });

  final VoidCallback onBack;
  final AuditCallback onAudit;
  final String localeCode;

  @override
  State<OldPointSurveyScreen> createState() => _OldPointSurveyScreenState();
}

class _OldPointSurveyScreenState extends State<OldPointSurveyScreen> {
  final _addressController = TextEditingController();
  final _otherBusinessController = TextEditingController();
  final _otherProblemController = TextEditingController();
  final _businesses = const [
    'business_food', 'business_retail', 'business_beauty', 'business_health',
    'business_auto', 'business_guesthouse', 'business_hotel', 'business_education',
  ];
  final _problems = const [
    'problem_traffic', 'problem_competitors', 'problem_ticket',
    'problem_customers', 'problem_visibility',
  ];
  final Set<String> _selectedBusinesses = {};
  final Set<String> _selectedProblems = {};
  bool _otherBusiness = false;
  bool _otherProblem = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _addressController.dispose();
    _otherBusinessController.dispose();
    _otherProblemController.dispose();
    super.dispose();
  }

  Future<void> _audit() async {
    if (_selectedBusinesses.isEmpty || _addressController.text.trim().isEmpty) {
      return;
    }
    setState(() => _isLoading = true);
    final business = [
      ..._selectedBusinesses.map(
        (id) => FlowLocalizations.t(widget.localeCode, id),
      ),
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
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
        _selectedBusinesses.isNotEmpty &&
        _addressController.text.trim().isNotEmpty;
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: widget.onBack,
                    icon: const Icon(Icons.arrow_back),
                  ),
                  const SizedBox(width: 4),
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
                  icon: _businessIcon(id),
                  selected: _selectedBusinesses.contains(id),
                  onTap: () => setState(() {
                    if (!_selectedBusinesses.add(id)) {
                      _selectedBusinesses.remove(id);
                    }
                  }),
                );
              }, childCount: _businesses.length),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 2.25,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: _OtherInputTile(
                label: t('otherBusiness'),
                active: _otherBusiness,
                controller: _otherBusinessController,
                suggestions: [
                  t('business_guesthouse'), t('business_hotel'),
                  t('business_auto'), t('business_logistics'), t('business_service'),
                ],
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
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate((context, index) {
                final id = _problems[index];
                final label = t(id);
                final selected = _selectedProblems.contains(id);
                return _ToggleTile(
                  label: label,
                  icon: Icons.insights_outlined,
                  selected: selected,
                  onTap: () => setState(() {
                    if (selected) {
                      _selectedProblems.remove(id);
                    } else if (_selectedProblems.length < 2) {
                      _selectedProblems.add(id);
                    }
                  }),
                );
              }, childCount: _problems.length),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 2.25,
              ),
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
              child: TextField(
                controller: _addressController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.location_on_outlined),
                  hintText: t('addressHint'),
                  suffixIcon: Icon(Icons.map_outlined),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
              child: FilledButton.icon(
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
                    : const Icon(Icons.auto_awesome),
                label: Text(
                  _isLoading ? t('auditLoading') : t('auditStart'),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: _accent,
                  minimumSize: const Size.fromHeight(54),
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

  IconData _businessIcon(String label) {
    if (label == 'business_food') return Icons.restaurant_outlined;
    if (label == 'business_retail') return Icons.shopping_bag_outlined;
    if (label == 'business_beauty') return Icons.face_retouching_natural;
    if (label == 'business_health') return Icons.medical_services_outlined;
    if (label == 'business_auto') return Icons.directions_car_outlined;
    if (label == 'business_hotel' || label == 'business_guesthouse') {
      return Icons.hotel_outlined;
    }
    return Icons.business_outlined;
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
    final score = analysis?['score']?.toString() ?? '—';
    final traffic = analysis?['pedestrian_traffic'] == null
        ? '—'
        : '${analysis!['pedestrian_traffic']}/100';
    final competitors = analysis?['competitors_500m']?.toString() ?? '—';
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              IconButton(onPressed: onBack, icon: const Icon(Icons.arrow_back)),
              Expanded(
                child: Text(
                  t('reportTitle'),
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.check_circle, color: _success, size: 42),
                  const SizedBox(height: 12),
                  Text(
                    t('auditReady'),
                    style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  Text(address, style: TextStyle(color: scheme.outline)),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      _ReportMetric(
                        label: t('score'),
                        value: score,
                        color: _accent,
                      ),
                      _ReportMetric(
                        label: t('traffic'),
                        value: traffic,
                        color: _success,
                      ),
                      _ReportMetric(
                        label: t('competitors'),
                        value: competitors,
                        color: Colors.orange,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            t('reportDescription'),
            style: TextStyle(color: scheme.outline, height: 1.45),
          ),
          const SizedBox(height: 22),
          FilledButton.icon(
            onPressed: onMap,
            icon: const Icon(Icons.map_outlined),
            label: Text(t('viewMap')),
            style: FilledButton.styleFrom(
              backgroundColor: _accent,
              minimumSize: const Size.fromHeight(54),
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => _showUpgrade(context),
            icon: const Icon(Icons.lock_open_outlined),
            label: Text(t('fullReport')),
          ),
        ],
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
  });
  final VoidCallback onBack;
  final VoidCallback onMap;
  final Future<void> Function(String businessType, String address) onAnalyze;
  final String localeCode;

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

  String _t(String key) => FlowLocalizations.t(widget.localeCode, key);

  @override
  void initState() {
    super.initState();
    _messages = [
      _FlowMessage('assistant', _t('assistantWelcome'), actions: const [
        'startNew', 'ownAddress',
      ]),
    ];
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
        actions: const [
          'business_food', 'business_retail', 'business_beauty',
          'business_health', 'business_auto', 'otherBusiness',
        ],
      );
    } else if (value == 'ownAddress') {
      _mode = 'address';
      _add(
        'assistant',
        _t('writeAddress'),
      );
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
      await widget.onAnalyze(_t(_business!), _address!);
      if (!mounted) return;
      setState(() => _loading = false);
      _add(
        'assistant',
        _t('analysisReady'),
        actions: const ['mapZones'],
      );
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
    if (_mode == 'address' && _business == null) {
      _address = text;
      _add(
        'assistant',
        _t('selectBusiness'),
        actions: const [
          'business_food', 'business_retail', 'business_beauty',
          'business_health', 'business_auto',
        ],
      );
      return;
    }
    if (_business != null && _address == null) {
      _address = text;
      await _finishFlow();
      return;
    }
    setState(() => _loading = true);
    final answer = await _ai.generateResponse(text);
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
                  child: TextField(
                    controller: _inputController,
                    onSubmitted: (_) => _send(),
                    decoration: InputDecoration(
                      hintText: _t('chatHint'),
                    ),
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
    required this.icon,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
    color: selected
        ? _accent.withValues(alpha: .16)
        : Theme.of(context).cardTheme.color,
    borderRadius: BorderRadius.circular(14),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? _accent : Theme.of(context).dividerColor,
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: selected ? _accent : Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle, color: _accent, size: 18),
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
