import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/exercise.dart';
import '../models/workout_record.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/exercise_icon.dart';

enum _Tab { log, calendar }

final List<TextInputFormatter> _digitsOnly = [
  FilteringTextInputFormatter.digitsOnly,
];

String _fmtDate(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final StorageService _storage = StorageService();

  bool _loading = true;
  bool _dataLoadStarted = false;

  _Tab _tab = _Tab.log;
  List<WorkoutRecord> _workouts = [];
  List<CustomExercise> _customExercises = [];
  String _selectedExerciseKey = kExercisePresets.first.key;

  final _nameController = TextEditingController();
  DateTime _formDate = DateTime.now();
  final _hoursController = TextEditingController();
  final _minutesController = TextEditingController();

  bool _addingCustom = false;
  final _customDraftController = TextEditingController();
  final _customFocusNode = FocusNode();

  DateTime _calMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
  String? _selectedDay;

  late final String _todayStr = _fmtDate(DateTime.now());

  @override
  void initState() {
    super.initState();
    _customFocusNode.addListener(_onCustomFocusChange);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // AppLocalizations.of(context)는 Localizations InheritedWidget이 준비된
    // 뒤에야 안전하게 조회할 수 있어 initState 대신 여기서 최초 1회만 로드한다.
    if (!_dataLoadStarted) {
      _dataLoadStarted = true;
      _loadData();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _hoursController.dispose();
    _minutesController.dispose();
    _customDraftController.dispose();
    _customFocusNode.removeListener(_onCustomFocusChange);
    _customFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final loc = AppLocalizations.of(context);
    final customExercises = await _storage.loadCustomExercises();
    final workouts = await _storage.loadWorkouts();
    if (!mounted) return;
    setState(() {
      _customExercises = customExercises;
      _workouts = workouts;
      _loading = false;
      _nameController.text = kExercisePresets.first.label(loc);
    });
  }

  List<_ExerciseOption> _allExerciseOptions(AppLocalizations loc) => [
        for (final preset in kExercisePresets)
          _ExerciseOption(key: preset.key, name: preset.label(loc)),
        for (final custom in _customExercises)
          _ExerciseOption(key: custom.key, name: custom.name),
      ];

  void _setTab(_Tab tab) => setState(() => _tab = tab);

  void _selectExercise(String key, String name) {
    setState(() {
      _selectedExerciseKey = key;
      _nameController.text = name;
    });
  }

  void _startAddCustom() {
    setState(() {
      _addingCustom = true;
      _customDraftController.clear();
    });
  }

  void _cancelAddCustom() {
    setState(() => _addingCustom = false);
    _customFocusNode.unfocus();
  }

  Future<void> _confirmCustomExercise() async {
    if (!_addingCustom) return;
    final name = _customDraftController.text.trim();
    if (name.isEmpty) {
      setState(() => _addingCustom = false);
      return;
    }
    final key = 'custom-${DateTime.now().microsecondsSinceEpoch}';
    setState(() {
      _customExercises = [..._customExercises, CustomExercise(key: key, name: name)];
      _selectedExerciseKey = key;
      _nameController.text = name;
      _addingCustom = false;
    });
    await _storage.saveCustomExercises(_customExercises);
  }

  void _onCustomFocusChange() {
    if (!_customFocusNode.hasFocus && _addingCustom) {
      _confirmCustomExercise();
    }
  }

  Future<void> _addWorkout() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    final hours = int.tryParse(_hoursController.text) ?? 0;
    final minutes = int.tryParse(_minutesController.text) ?? 0;
    final record = WorkoutRecord(
      id: 'w${DateTime.now().microsecondsSinceEpoch}',
      exerciseKey: _selectedExerciseKey,
      name: name,
      date: _fmtDate(_formDate),
      durationMinutes: hours * 60 + minutes,
    );
    setState(() {
      _workouts = [record, ..._workouts];
      _hoursController.clear();
      _minutesController.clear();
    });
    await _storage.saveWorkouts(_workouts);
  }

  Future<void> _deleteWorkout(String id) async {
    setState(() => _workouts = _workouts.where((w) => w.id != id).toList());
    await _storage.saveWorkouts(_workouts);
  }

  Future<void> _startEdit(WorkoutRecord record) async {
    final loc = AppLocalizations.of(context);
    final nameCtrl = TextEditingController(text: record.name);
    final hoursCtrl =
        TextEditingController(text: (record.durationMinutes ~/ 60).toString());
    final minutesCtrl =
        TextEditingController(text: (record.durationMinutes % 60).toString());
    DateTime editDate = DateTime.tryParse(record.date) ?? DateTime.now();

    try {
      final saved = await showDialog<bool>(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setDialogState) => Dialog(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.s4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    loc.editWorkoutDialogTitle,
                    style: Theme.of(ctx)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: AppSpacing.s3),
                  _FieldLabel(loc.nameFieldLabel),
                  const SizedBox(height: 5),
                  TextField(controller: nameCtrl),
                  const SizedBox(height: AppSpacing.s3),
                  _FieldLabel(loc.dateFieldLabel),
                  const SizedBox(height: 5),
                  _DateInput(
                    date: editDate,
                    onChanged: (d) => setDialogState(() => editDate = d),
                  ),
                  const SizedBox(height: AppSpacing.s3),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _FieldLabel(loc.hoursFieldLabel),
                            const SizedBox(height: 5),
                            TextField(
                              controller: hoursCtrl,
                              keyboardType: TextInputType.number,
                              inputFormatters: _digitsOnly,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.s3),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _FieldLabel(loc.minutesFieldLabel),
                            const SizedBox(height: 5),
                            TextField(
                              controller: minutesCtrl,
                              keyboardType: TextInputType.number,
                              inputFormatters: _digitsOnly,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.s4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: Text(loc.cancelButton),
                      ),
                      const SizedBox(width: AppSpacing.s2),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: Text(loc.saveButton),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      if (saved != true) return;

      final name = nameCtrl.text.trim();
      final hours = int.tryParse(hoursCtrl.text) ?? 0;
      final minutes = int.tryParse(minutesCtrl.text) ?? 0;
      setState(() {
        record.name = name.isEmpty ? record.name : name;
        record.date = _fmtDate(editDate);
        record.durationMinutes = hours * 60 + minutes;
      });
      await _storage.saveWorkouts(_workouts);
    } finally {
      nameCtrl.dispose();
      hoursCtrl.dispose();
      minutesCtrl.dispose();
    }
  }

  void _prevMonth() =>
      setState(() => _calMonth = DateTime(_calMonth.year, _calMonth.month - 1, 1));
  void _nextMonth() =>
      setState(() => _calMonth = DateTime(_calMonth.year, _calMonth.month + 1, 1));

  void _selectDay(String dateStr) {
    setState(() => _selectedDay = _selectedDay == dateStr ? null : dateStr);
  }

  void _logForSelectedDay() {
    setState(() {
      _tab = _Tab.log;
      final selected = _selectedDay;
      if (selected != null) {
        final d = DateTime.tryParse(selected);
        if (d != null) _formDate = d;
      }
    });
  }

  String _summaryFor(AppLocalizations loc, int totalMinutes) {
    final h = totalMinutes ~/ 60;
    final m = totalMinutes % 60;
    return h > 0 ? loc.durationHoursMinutes(h, m) : loc.durationMinutesOnly(m);
  }

  List<_CalendarDay> _buildCalendarDays() {
    final year = _calMonth.year;
    final month = _calMonth.month;
    final firstOfMonth = DateTime(year, month, 1);
    final startOffset = firstOfMonth.weekday % 7; // Sunday=0, like JS getDay()
    final gridStart = firstOfMonth.subtract(Duration(days: startOffset));

    final byDate = <String, List<WorkoutRecord>>{};
    for (final w in _workouts) {
      (byDate[w.date] ??= []).add(w);
    }

    return List.generate(35, (i) {
      final d = gridStart.add(Duration(days: i));
      final dStr = _fmtDate(d);
      final dayWorkouts = byDate[dStr] ?? const <WorkoutRecord>[];
      final shown = dayWorkouts.take(3).toList();
      return _CalendarDay(
        dateStr: dStr,
        dayNum: d.day,
        inMonth: d.month == month,
        isToday: dStr == _todayStr,
        isSelected: dStr == _selectedDay,
        shownExerciseKeys: shown.map((w) => w.exerciseKey).toList(),
        overflowCount: dayWorkouts.length - shown.length,
      );
    });
  }

  String _monthStatusLabel(AppLocalizations loc) {
    final year = _calMonth.year;
    final month = _calMonth.month;
    final monthWorkouts = _workouts.where((w) {
      final d = DateTime.tryParse(w.date);
      return d != null && d.year == year && d.month == month;
    }).toList();
    if (monthWorkouts.isEmpty) return loc.emptyMonthWorkouts;
    final totalMin =
        monthWorkouts.fold<int>(0, (sum, w) => sum + w.durationMinutes);
    return loc.monthStatusWorkouts(
        monthWorkouts.length, _summaryFor(loc, totalMin));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final loc = AppLocalizations.of(context);

    return Scaffold(
      body: SafeArea(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(loc),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.s4, AppSpacing.s3, AppSpacing.s4, 0),
                  child: _SegmentedTabs(
                    tab: _tab,
                    onChanged: _setTab,
                    logLabel: loc.tabLog,
                    calendarLabel: loc.tabCalendar,
                  ),
                ),
                if (_tab == _Tab.log)
                  _buildLogTab(loc)
                else
                  _buildCalendarTab(loc),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AppLocalizations loc) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.s4, AppSpacing.s4, AppSpacing.s4, 0),
      child: Row(
        children: [
          const Icon(Icons.fitness_center, size: 22, color: AppColors.accent),
          const SizedBox(width: 8),
          Text(
            loc.headerTitle,
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildLogTab(AppLocalizations loc) {
    final options = _allExerciseOptions(loc);
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.s4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionLabel(loc.exerciseSectionLabel),
          const SizedBox(height: AppSpacing.s2),
          SizedBox(
            height: 76,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final option in options)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _ExerciseChip(
                      label: option.name,
                      exerciseKey: option.key,
                      selected: _selectedExerciseKey == option.key,
                      onTap: () => _selectExercise(option.key, option.name),
                    ),
                  ),
                if (_addingCustom)
                  _CustomExerciseInput(
                    controller: _customDraftController,
                    focusNode: _customFocusNode,
                    hint: loc.customExerciseNameHint,
                    onSubmit: _confirmCustomExercise,
                    onEscape: _cancelAddCustom,
                  )
                else
                  _AddCustomChip(
                    label: loc.customExerciseChipLabel,
                    onTap: _startAddCustom,
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.s4),
          _FieldLabel(loc.nameFieldLabel),
          const SizedBox(height: 5),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(hintText: loc.exerciseNameHint),
          ),
          const SizedBox(height: AppSpacing.s3),
          _FieldLabel(loc.dateFieldLabel),
          const SizedBox(height: 5),
          _DateInput(
            date: _formDate,
            onChanged: (d) => setState(() => _formDate = d),
          ),
          const SizedBox(height: AppSpacing.s3),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _FieldLabel(loc.hoursFieldLabel),
                    const SizedBox(height: 5),
                    TextField(
                      controller: _hoursController,
                      keyboardType: TextInputType.number,
                      inputFormatters: _digitsOnly,
                      decoration: const InputDecoration(hintText: '0'),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _FieldLabel(loc.minutesFieldLabel),
                    const SizedBox(height: 5),
                    TextField(
                      controller: _minutesController,
                      keyboardType: TextInputType.number,
                      inputFormatters: _digitsOnly,
                      decoration: const InputDecoration(hintText: '0'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s3),
          ElevatedButton(
            onPressed: _addWorkout,
            child: Text(loc.logWorkoutButton),
          ),
          const SizedBox(height: AppSpacing.s6),
          _SectionLabel(loc.recentSectionLabel),
          if (_workouts.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.s3),
              child: Text(
                loc.emptyRecentWorkouts,
                style: TextStyle(color: AppColors.textMuted55, fontSize: 13),
              ),
            )
          else
            for (final record in _workouts.take(6))
              _RecordTile(
                record: record,
                loc: loc,
                onEdit: () => _startEdit(record),
                onDelete: () => _deleteWorkout(record.id),
              ),
        ],
      ),
    );
  }

  Widget _buildCalendarTab(AppLocalizations loc) {
    final locale = Localizations.localeOf(context).toString();
    final days = _buildCalendarDays();
    final monthLabel = DateFormat.yMMMM(locale).format(_calMonth);
    final selectedDay = _selectedDay;
    final selectedDayWorkouts = selectedDay == null
        ? const <WorkoutRecord>[]
        : _workouts.where((w) => w.date == selectedDay).toList();
    final selectedDate =
        selectedDay == null ? null : DateTime.tryParse(selectedDay);

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.s4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: _prevMonth,
                icon: const Icon(Icons.chevron_left, size: 20),
              ),
              Text(
                monthLabel,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              IconButton(
                onPressed: _nextMonth,
                icon: const Icon(Icons.chevron_right, size: 20),
              ),
            ],
          ),
          Text(
            _monthStatusLabel(loc),
            style: TextStyle(fontSize: 13, color: AppColors.textMuted60),
          ),
          const SizedBox(height: AppSpacing.s3),
          Row(
            children: [
              for (final label in const ['S', 'M', 'T', 'W', 'T', 'F', 'S'])
                Expanded(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 10, color: AppColors.textMuted50),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 2,
            crossAxisSpacing: 2,
            childAspectRatio: 1,
            children: [
              for (final day in days)
                _DayCell(day: day, onTap: () => _selectDay(day.dateStr)),
            ],
          ),
          if (selectedDay != null) ...[
            const SizedBox(height: AppSpacing.s4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  selectedDate != null
                      ? DateFormat.MMMd(locale).format(selectedDate)
                      : '',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted60,
                  ),
                ),
                GestureDetector(
                  onTap: _logForSelectedDay,
                  child: Text(
                    loc.logThisDayLink,
                    style: const TextStyle(fontSize: 12, color: AppColors.accent),
                  ),
                ),
              ],
            ),
            if (selectedDayWorkouts.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.s3),
                child: Text(
                  loc.emptyDayWorkouts,
                  style: TextStyle(color: AppColors.textMuted55, fontSize: 13),
                ),
              )
            else
              for (final record in selectedDayWorkouts)
                _RecordTile(
                  record: record,
                  loc: loc,
                  onEdit: () => _startEdit(record),
                  onDelete: () => _deleteWorkout(record.id),
                ),
          ],
        ],
      ),
    );
  }
}

class _ExerciseOption {
  final String key;
  final String name;
  const _ExerciseOption({required this.key, required this.name});
}

class _CalendarDay {
  final String dateStr;
  final int dayNum;
  final bool inMonth;
  final bool isToday;
  final bool isSelected;
  final List<String> shownExerciseKeys;
  final int overflowCount;

  const _CalendarDay({
    required this.dateStr,
    required this.dayNum,
    required this.inMonth,
    required this.isToday,
    required this.isSelected,
    required this.shownExerciseKeys,
    required this.overflowCount,
  });
}

class _SegmentedTabs extends StatelessWidget {
  final _Tab tab;
  final ValueChanged<_Tab> onChanged;
  final String logLabel;
  final String calendarLabel;

  const _SegmentedTabs({
    required this.tab,
    required this.onChanged,
    required this.logLabel,
    required this.calendarLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.divider),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          Expanded(
            child: _segOption(logLabel, tab == _Tab.log, () => onChanged(_Tab.log)),
          ),
          Container(width: 1, height: 32, color: AppColors.divider),
          Expanded(
            child: _segOption(
              calendarLabel,
              tab == _Tab.calendar,
              () => onChanged(_Tab.calendar),
            ),
          ),
        ],
      ),
    );
  }

  Widget _segOption(String label, bool selected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 7),
        color: selected ? AppColors.accent : Colors.transparent,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: selected ? AppColors.bg : AppColors.text,
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textMuted60,
        ),
      );
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: TextStyle(fontSize: 12, color: AppColors.textMuted65),
      );
}

class _ExerciseChip extends StatelessWidget {
  final String label;
  final String exerciseKey;
  final bool selected;
  final VoidCallback onTap;

  const _ExerciseChip({
    required this.label,
    required this.exerciseKey,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 68,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.accent100 : Colors.transparent,
          border: Border.all(color: selected ? AppColors.accent : Colors.transparent),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ExerciseIcon(
              exerciseKey: exerciseKey,
              size: 22,
              color: selected ? AppColors.accent800 : AppColors.text,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                color: selected ? AppColors.accent800 : AppColors.text,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddCustomChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _AddCustomChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 68,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add_circle_outline, size: 22, color: AppColors.text),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, color: AppColors.text),
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomExerciseInput extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String hint;
  final VoidCallback onSubmit;
  final VoidCallback onEscape;

  const _CustomExerciseInput({
    required this.controller,
    required this.focusNode,
    required this.hint,
    required this.onSubmit,
    required this.onEscape,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 96,
      child: Focus(
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.escape) {
            onEscape();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          autofocus: true,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 11),
          decoration: InputDecoration(
            hintText: hint,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
          ),
          onSubmitted: (_) => onSubmit(),
        ),
      ),
    );
  }
}

class _DateInput extends StatelessWidget {
  final DateTime date;
  final ValueChanged<DateTime> onChanged;
  const _DateInput({required this.date, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (picked != null) onChanged(picked);
      },
      child: InputDecorator(
        decoration: const InputDecoration(),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, size: 14, color: AppColors.text),
            const SizedBox(width: 8),
            Text(_fmtDate(date)),
          ],
        ),
      ),
    );
  }
}

class _RecordTile extends StatelessWidget {
  final WorkoutRecord record;
  final AppLocalizations loc;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _RecordTile({
    required this.record,
    required this.loc,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final h = record.durationMinutes ~/ 60;
    final m = record.durationMinutes % 60;
    final summary =
        h > 0 ? loc.durationHoursMinutes(h, m) : loc.durationMinutesOnly(m);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s3),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration:
                const BoxDecoration(color: AppColors.surface, shape: BoxShape.circle),
            child: ExerciseIcon(
              exerciseKey: record.exerciseKey,
              size: 16,
              color: AppColors.accent700,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    style: DefaultTextStyle.of(context)
                        .style
                        .copyWith(fontSize: 14, color: AppColors.text),
                    children: [
                      TextSpan(
                        text: record.name,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      TextSpan(
                        text: ' $summary',
                        style: const TextStyle(
                          color: AppColors.accent700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  record.date,
                  style: TextStyle(fontSize: 11, color: AppColors.textMuted55),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onEdit,
            tooltip: loc.editButton,
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            icon: const Icon(Icons.edit_outlined, size: 16),
          ),
          IconButton(
            onPressed: onDelete,
            tooltip: loc.deleteButton,
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            icon: const Icon(Icons.delete_outline, size: 16),
          ),
        ],
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  final _CalendarDay day;
  final VoidCallback onTap;
  const _DayCell({required this.day, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final numColor = day.isSelected
        ? AppColors.accent800
        : (day.isToday ? AppColors.accent700 : AppColors.text);
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: day.inMonth ? 1 : 0.32,
        child: Container(
          padding: const EdgeInsets.only(top: 6),
          decoration: BoxDecoration(
            color: day.isSelected ? AppColors.accent100 : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Column(
            children: [
              Text(
                '${day.dayNum}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: day.isToday ? FontWeight.w700 : FontWeight.w400,
                  color: numColor,
                ),
              ),
              const SizedBox(height: 3),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 2,
                children: [
                  for (final key in day.shownExerciseKeys)
                    ExerciseIcon(exerciseKey: key, size: 11, color: AppColors.accent700),
                  if (day.overflowCount > 0)
                    Text(
                      '+${day.overflowCount}',
                      style: const TextStyle(fontSize: 9, color: AppColors.accent700),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
