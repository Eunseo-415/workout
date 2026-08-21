import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/exercise.dart';
import '../models/workout_record.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../utils/date_format.dart';
import '../utils/input_formatters.dart';
import '../widgets/add_custom_exercise_dialog.dart';
import '../widgets/calendar_day_cell.dart';
import '../widgets/date_input.dart';
import '../widgets/edit_workout_dialog.dart';
import '../widgets/exercise_chip.dart';
import '../widgets/field_label.dart';
import '../widgets/record_tile.dart';
import '../widgets/section_label.dart';
import '../widgets/type_toggle.dart';

enum _Tab { log, calendar }

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
  ExerciseType _logExerciseType = ExerciseType.strength;
  List<WorkoutRecord> _workouts = [];
  List<CustomExercise> _customExercises = [];
  String _selectedExerciseKey = kExercisePresets.first.key;

  final _nameController = TextEditingController();
  DateTime _formDate = DateTime.now();
  final _hoursController = TextEditingController();
  final _minutesController = TextEditingController();

  DateTime _calMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
  String? _selectedDay;

  late final String _todayStr = fmtDate(DateTime.now());

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

  List<_ExerciseOption> _optionsForType(AppLocalizations loc, ExerciseType type) => [
        for (final preset in kExercisePresets)
          if (preset.type == type)
            _ExerciseOption(key: preset.key, name: preset.label(loc)),
        for (final custom in _customExercises)
          if (custom.type == type)
            _ExerciseOption(key: custom.key, name: custom.name),
      ];

  void _setTab(_Tab tab) => setState(() => _tab = tab);

  void _selectExercise(String key, String name) {
    setState(() {
      _selectedExerciseKey = key;
      _nameController.text = name;
    });
  }

  void _setLogExerciseType(ExerciseType type) {
    final loc = AppLocalizations.of(context);
    final options = _optionsForType(loc, type);
    setState(() {
      _logExerciseType = type;
      if (options.isNotEmpty) {
        _selectedExerciseKey = options.first.key;
        _nameController.text = options.first.name;
      }
    });
  }

  Future<void> _openAddCustomDialog() async {
    final result = await showDialog<AddCustomExerciseResult>(
      context: context,
      builder: (ctx) => const AddCustomExerciseDialog(),
    );
    if (result == null) return;

    final key = 'custom-${DateTime.now().microsecondsSinceEpoch}';
    setState(() {
      _customExercises = [
        ..._customExercises,
        CustomExercise(
          key: key,
          name: result.name,
          type: result.type,
          iconKey: result.iconKey,
        ),
      ];
      _logExerciseType = result.type;
      _selectedExerciseKey = key;
      _nameController.text = result.name;
    });
    await _storage.saveCustomExercises(_customExercises);
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
      date: fmtDate(_formDate),
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
    final result = await showDialog<EditWorkoutResult>(
      context: context,
      builder: (ctx) => EditWorkoutDialog(record: record),
    );
    if (result == null) return;

    setState(() {
      record.name = result.name.isEmpty ? record.name : result.name;
      record.date = fmtDate(result.date);
      record.durationMinutes = result.durationMinutes;
    });
    await _storage.saveWorkouts(_workouts);
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

  List<CalendarDay> _buildCalendarDays() {
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
      final dStr = fmtDate(d);
      final dayWorkouts = byDate[dStr] ?? const <WorkoutRecord>[];
      final shown = dayWorkouts.take(3).toList();
      return CalendarDay(
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
        bottom: false,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(loc),
                if (_tab == _Tab.log)
                  _buildLogTab(loc)
                else
                  _buildCalendarTab(loc),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        color: AppColors.surface,
        child: BottomNavigationBar(
          currentIndex: _tab.index,
          onTap: (i) => _setTab(_Tab.values[i]),
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppColors.surface,
          selectedItemColor: AppColors.accent,
          unselectedItemColor: AppColors.textMuted55,
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.list_alt),
              label: loc.tabLog,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.calendar_month),
              label: loc.tabCalendar,
            ),
          ],
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
    final options = _optionsForType(loc, _logExerciseType);
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.s4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionLabel(loc.exerciseSectionLabel),
          const SizedBox(height: AppSpacing.s2),
          TypeToggle(
            type: _logExerciseType,
            loc: loc,
            onChanged: _setLogExerciseType,
          ),
          const SizedBox(height: AppSpacing.s2),
          SizedBox(
            height: 84,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final option in options)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ExerciseChip(
                      label: option.name,
                      exerciseKey: option.key,
                      customExercises: _customExercises,
                      selected: _selectedExerciseKey == option.key,
                      onTap: () => _selectExercise(option.key, option.name),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.s3),
          GestureDetector(
            onTap: _openAddCustomDialog,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.add_circle_outline,
                    size: 16, color: AppColors.accent),
                const SizedBox(width: 6),
                Text(
                  loc.addCustomExerciseButton,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.s4),
          FieldLabel(loc.nameFieldLabel),
          const SizedBox(height: 5),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(hintText: loc.exerciseNameHint),
          ),
          const SizedBox(height: AppSpacing.s3),
          FieldLabel(loc.dateFieldLabel),
          const SizedBox(height: 5),
          DateInput(
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
                    FieldLabel(loc.hoursFieldLabel),
                    const SizedBox(height: 5),
                    TextField(
                      controller: _hoursController,
                      keyboardType: TextInputType.number,
                      inputFormatters: digitsOnlyFormatters,
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
                    FieldLabel(loc.minutesFieldLabel),
                    const SizedBox(height: 5),
                    TextField(
                      controller: _minutesController,
                      keyboardType: TextInputType.number,
                      inputFormatters: digitsOnlyFormatters,
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
          SectionLabel(loc.recentSectionLabel),
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
              RecordTile(
                record: record,
                loc: loc,
                customExercises: _customExercises,
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
                DayCell(
                  day: day,
                  customExercises: _customExercises,
                  onTap: () => _selectDay(day.dateStr),
                ),
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
                RecordTile(
                  record: record,
                  loc: loc,
                  customExercises: _customExercises,
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
