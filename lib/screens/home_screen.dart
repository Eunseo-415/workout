import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/workout_icon.dart';
import '../models/workout_record.dart';
import '../services/storage_service.dart';
import '../widgets/icon_visual.dart';

const _primaryColor = Color(0xFF3B82F6);

final List<TextInputFormatter> _weightInputFormatters = [
  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
];
final List<TextInputFormatter> _repsInputFormatters = [
  FilteringTextInputFormatter.digitsOnly,
];

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final StorageService _storage = StorageService();
  final ImagePicker _imagePicker = ImagePicker();

  List<WorkoutIcon> _icons = [];
  List<WorkoutRecord> _workouts = [];
  String _currentTab = 'type1';
  int _selectedIndex = 0;
  bool _managerOpen = false;
  bool _loading = true;
  bool _dataLoadStarted = false;

  final _nameController = TextEditingController();
  final _weightController = TextEditingController();
  final _repsController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

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
    _weightController.dispose();
    _repsController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final loc = AppLocalizations.of(context);
    final icons = await _storage.loadIcons(defaultWorkoutIcons(loc));
    final workouts = await _storage.loadWorkouts();
    if (!mounted) return;
    setState(() {
      _icons = icons;
      _workouts = workouts;
      _loading = false;
      if (_icons.isNotEmpty) {
        _nameController.text = _icons[0].displayName(loc);
      }
    });
  }

  String get _formattedDate =>
      '${_selectedDate.year.toString().padLeft(4, '0')}-'
      '${_selectedDate.month.toString().padLeft(2, '0')}-'
      '${_selectedDate.day.toString().padLeft(2, '0')}';

  static String _formatDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  List<int> get _filteredIndexes {
    final result = <int>[];
    for (var i = 0; i < _icons.length; i++) {
      if (_icons[i].type == _currentTab) result.add(i);
    }
    return result;
  }

  void _switchTab(String tab) {
    final loc = AppLocalizations.of(context);
    setState(() {
      _currentTab = tab;
      final firstIndex = _icons.indexWhere((icon) => icon.type == tab);
      if (firstIndex != -1) {
        _selectedIndex = firstIndex;
        _nameController.text = _icons[firstIndex].displayName(loc);
      }
    });
  }

  void _selectIcon(int index) {
    final loc = AppLocalizations.of(context);
    setState(() {
      _selectedIndex = index;
      final displayName = _icons[index].displayName(loc);
      if (displayName.isNotEmpty) {
        _nameController.text = displayName;
      }
    });
  }

  Future<void> _persistIcons() => _storage.saveIcons(_icons);

  Future<void> _persistWorkouts() => _storage.saveWorkouts(_workouts);

  void _updateIconName(int index, String newName) {
    setState(() {
      _icons[index].name = newName;
      _icons[index].nameCustomized = true;
      if (index == _selectedIndex) {
        _nameController.text = newName;
      }
    });
    _persistIcons();
  }

  void _updateIconType(int index, String newType) {
    setState(() => _icons[index].type = newType);
    _persistIcons();
  }

  void _moveIconUp(int index) {
    if (index <= 0) return;
    setState(() {
      final temp = _icons[index];
      _icons[index] = _icons[index - 1];
      _icons[index - 1] = temp;
      if (_selectedIndex == index) {
        _selectedIndex = index - 1;
      } else if (_selectedIndex == index - 1) {
        _selectedIndex = index;
      }
    });
    _persistIcons();
  }

  void _moveIconDown(int index) {
    if (index >= _icons.length - 1) return;
    setState(() {
      final temp = _icons[index];
      _icons[index] = _icons[index + 1];
      _icons[index + 1] = temp;
      if (_selectedIndex == index) {
        _selectedIndex = index + 1;
      } else if (_selectedIndex == index + 1) {
        _selectedIndex = index;
      }
    });
    _persistIcons();
  }

  Future<void> _deleteIcon(int index) async {
    final loc = AppLocalizations.of(context);
    if (_icons.length <= 1) {
      _showAlert(loc.alertAtLeastOneIcon);
      return;
    }
    final confirmed = await _confirmDialog(
      title: loc.deleteIconDialogTitle,
      message: loc.deleteIconDialogMessage(_icons[index].displayName(loc)),
    );
    if (!confirmed) return;
    setState(() {
      _icons.removeAt(index);
      if (index < _selectedIndex) {
        _selectedIndex -= 1;
      }
      if (_selectedIndex >= _icons.length) {
        _selectedIndex = _icons.length - 1;
      }
    });
    await _persistIcons();
    _selectIcon(_selectedIndex);
  }

  Future<void> _addCustomImageIcon() async {
    final loc = AppLocalizations.of(context);
    final picked =
        await _imagePicker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();

    final docsDir = await getApplicationDocumentsDirectory();
    final iconsDir = Directory('${docsDir.path}/workout_icons');
    await iconsDir.create(recursive: true);
    final ext = picked.path.contains('.') ? picked.path.split('.').last : 'jpg';
    final file = File('${iconsDir.path}/icon_${DateTime.now().microsecondsSinceEpoch}.$ext');
    await file.writeAsBytes(bytes);

    setState(() {
      _icons.add(WorkoutIcon(imagePath: file.path, name: loc.newIconDefaultName, type: _currentTab));
    });
    await _persistIcons();
    _selectIcon(_icons.length - 1);
  }

  Future<void> _addWorkout() async {
    final loc = AppLocalizations.of(context);
    final name = _nameController.text.trim();
    final weight = _weightController.text.trim();
    final reps = _repsController.text.trim();

    if (name.isEmpty) {
      _showAlert(loc.alertEnterExerciseName);
      return;
    }
    if (weight.isEmpty || reps.isEmpty) {
      _showAlert(loc.alertEnterWeightReps);
      return;
    }
    if (double.tryParse(weight) == null || int.tryParse(reps) == null) {
      _showAlert(loc.alertInvalidWeightReps);
      return;
    }

    final icon = _icons.isEmpty
        ? null
        : (_selectedIndex < _icons.length ? _icons[_selectedIndex] : _icons[0]);

    final record = WorkoutRecord(
      iconCodePoint: icon?.iconCodePoint,
      iconFontFamily: icon?.iconFontFamily,
      iconFontPackage: icon?.iconFontPackage,
      iconImagePath: icon?.imagePath,
      iconImageBase64: icon?.imageBase64,
      iconName: icon?.displayName(loc) ?? '',
      name: name,
      date: _formattedDate,
      weight: weight,
      reps: reps,
    );

    setState(() {
      _workouts.insert(0, record);
      _weightController.clear();
      _repsController.clear();
    });
    await _persistWorkouts();
  }

  Future<void> _deleteWorkout(int index) async {
    final loc = AppLocalizations.of(context);
    final confirmed = await _confirmDialog(
      title: loc.deleteWorkoutDialogTitle,
      message: loc.deleteWorkoutDialogMessage(_workouts[index].name),
    );
    if (!confirmed) return;
    setState(() => _workouts.removeAt(index));
    await _persistWorkouts();
  }

  Future<void> _editWorkout(int index) async {
    final loc = AppLocalizations.of(context);
    final record = _workouts[index];
    final nameCtrl = TextEditingController(text: record.name);
    final weightCtrl = TextEditingController(text: record.weight);
    final repsCtrl = TextEditingController(text: record.reps);
    DateTime date = DateTime.tryParse(record.date) ?? DateTime.now();

    try {
      final saved = await showDialog<bool>(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setDialogState) => AlertDialog(
            title: Text(loc.editWorkoutDialogTitle),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: _inputDecoration(loc.exerciseNameHint),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: date,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setDialogState(() => date = picked);
                      }
                    },
                    child: InputDecorator(
                      decoration: _inputDecoration(),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 16, color: Color(0xFF64748B)),
                          const SizedBox(width: 8),
                          Text(_formatDate(date)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: weightCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: _weightInputFormatters,
                          decoration: _inputDecoration(loc.weightHint),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: repsCtrl,
                          keyboardType: TextInputType.number,
                          inputFormatters: _repsInputFormatters,
                          decoration: _inputDecoration(loc.repsHint),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(loc.cancelButton)),
              TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(loc.saveButton)),
            ],
          ),
        ),
      );

      if (saved != true) return;

      final name = nameCtrl.text.trim();
      final weight = weightCtrl.text.trim();
      final reps = repsCtrl.text.trim();
      if (name.isEmpty ||
          weight.isEmpty ||
          reps.isEmpty ||
          double.tryParse(weight) == null ||
          int.tryParse(reps) == null) {
        _showAlert(loc.alertInvalidEditFields);
        return;
      }

      setState(() {
        record.name = name;
        record.weight = weight;
        record.reps = reps;
        record.date = _formatDate(date);
      });
      await _persistWorkouts();
    } finally {
      nameCtrl.dispose();
      weightCtrl.dispose();
      repsCtrl.dispose();
    }
  }

  Future<bool> _confirmDialog({required String title, required String message}) async {
    final loc = AppLocalizations.of(context);
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(loc.cancelButton)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(loc.deleteButton, style: const TextStyle(color: Color(0xFFEF4444))),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _showAlert(String message) {
    final loc = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(loc.confirmButton)),
        ],
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  InputDecoration _inputDecoration([String hint = '']) => InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.all(12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _primaryColor),
        ),
      );

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF1F5F9),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final loc = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Container(
              margin: const EdgeInsets.all(10),
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 15,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.fitness_center, size: 20, color: Color(0xFF1E293B)),
                        const SizedBox(width: 6),
                        Text(
                          loc.headerTitle,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    Text(
                      loc.iconSectionLabel,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF475569),
                      ),
                    ),
                    const SizedBox(height: 6),
                    _buildTypeTabs(loc),
                    const SizedBox(height: 8),
                    _buildIconGrid(loc),
                    const SizedBox(height: 12),
                    _buildToggleButton(loc),
                    if (_managerOpen) _buildIconManagerPanel(loc),
                    _buildInputGroup(loc),
                    const SizedBox(height: 4),
                    _buildAddButton(loc),
                    const SizedBox(height: 20),
                    Text(
                      loc.workoutListTitle,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF475569),
                      ),
                    ),
                    const Divider(height: 15, color: Color(0xFFE2E8F0)),
                    _buildWorkoutList(loc),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypeTabs(AppLocalizations loc) {
    return Row(
      children: [
        Expanded(child: _tabButton(loc.tabType1, 'type1')),
        const SizedBox(width: 5),
        Expanded(child: _tabButton(loc.tabType2, 'type2')),
      ],
    );
  }

  Widget _tabButton(String label, String tab) {
    final active = _currentTab == tab;
    return GestureDetector(
      onTap: () => _switchTab(tab),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: active ? _primaryColor : const Color(0xFFE2E8F0),
          border: Border.all(color: active ? _primaryColor : const Color(0xFFCBD5E1)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: active ? Colors.white : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }

  Widget _buildIconGrid(AppLocalizations loc) {
    final indexes = _filteredIndexes;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: indexes.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
        mainAxisExtent: 68,
      ),
      itemBuilder: (context, i) {
        final index = indexes[i];
        final icon = _icons[index];
        final selected = _selectedIndex == index;
        return GestureDetector(
          onTap: () => _selectIcon(index),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            decoration: BoxDecoration(
              color: selected ? const Color(0xFFEFF6FF) : Colors.white,
              border: Border.all(
                color: selected ? _primaryColor : const Color(0xFFE2E8F0),
                width: selected ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                IconVisual(
                  iconCodePoint: icon.iconCodePoint,
                  iconFontFamily: icon.iconFontFamily,
                  iconFontPackage: icon.iconFontPackage,
                  imagePath: icon.imagePath,
                  imageBase64: icon.imageBase64,
                  size: 20,
                  color: selected ? _primaryColor : const Color(0xFF475569),
                ),
                const SizedBox(height: 4),
                SizedBox(
                  height: 13,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      icon.displayName(loc),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildToggleButton(AppLocalizations loc) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: () => setState(() => _managerOpen = !_managerOpen),
        style: OutlinedButton.styleFrom(
          backgroundColor: const Color(0xFFF8FAFC),
          side: const BorderSide(color: Color(0xFFCBD5E1)),
          padding: const EdgeInsets.all(12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.settings, size: 16, color: Color(0xFF334155)),
            const SizedBox(width: 6),
            Text(
              _managerOpen ? loc.iconSettingsClose : loc.iconSettingsOpen,
              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF334155)),
            ),
            const SizedBox(width: 6),
            Icon(
              _managerOpen ? Icons.expand_less : Icons.expand_more,
              size: 18,
              color: const Color(0xFF334155),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconManagerPanel(AppLocalizations loc) {
    return Container(
      padding: const EdgeInsets.all(10),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            loc.iconManagePanelTitle,
            style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF334155)),
          ),
          const SizedBox(height: 8),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _icons.length,
            itemBuilder: (context, index) => _iconManageRow(loc, _icons[index], index),
          ),
          const SizedBox(height: 4),
          const Divider(height: 1),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.folder_open, size: 14, color: Color(0xFF334155)),
              const SizedBox(width: 4),
              Text(
                loc.addImageIconLabel,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF334155),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _addCustomImageIcon,
              icon: const Icon(Icons.image_outlined, size: 16),
              label: Text(loc.pickFromGallery),
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconManageRow(AppLocalizations loc, WorkoutIcon icon, int index) {
    return Container(
      key: ValueKey(icon.id),
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            child: Center(
              child: IconVisual(
                iconCodePoint: icon.iconCodePoint,
                iconFontFamily: icon.iconFontFamily,
                iconFontPackage: icon.iconFontPackage,
                imagePath: icon.imagePath,
                imageBase64: icon.imageBase64,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 6),
          DropdownButton<String>(
            value: icon.type,
            underline: const SizedBox.shrink(),
            style: const TextStyle(fontSize: 12, color: Colors.black),
            items: [
              DropdownMenuItem(value: 'type1', child: Text(loc.dropdownType1)),
              DropdownMenuItem(value: 'type2', child: Text(loc.dropdownType2)),
            ],
            onChanged: (value) {
              if (value != null) _updateIconType(index, value);
            },
          ),
          const SizedBox(width: 6),
          Expanded(
            child: TextFormField(
              key: ValueKey('name_${icon.id}'),
              initialValue: icon.displayName(loc),
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                border: const OutlineInputBorder(),
                hintText: loc.iconNameHint,
              ),
              onChanged: (value) => _updateIconName(index, value),
            ),
          ),
          IconButton(
            onPressed: () => _moveIconUp(index),
            icon: const Icon(Icons.arrow_upward, size: 16),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          ),
          IconButton(
            onPressed: () => _moveIconDown(index),
            icon: const Icon(Icons.arrow_downward, size: 16),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          ),
          IconButton(
            onPressed: () => _deleteIcon(index),
            icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFEF4444)),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          ),
        ],
      ),
    );
  }

  Widget _buildInputGroup(AppLocalizations loc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _nameController,
          decoration: _inputDecoration(loc.exerciseNameHint),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _pickDate,
          child: InputDecorator(
            decoration: _inputDecoration(),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: Color(0xFF64748B)),
                const SizedBox(width: 8),
                Text(_formattedDate),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _weightController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: _weightInputFormatters,
                decoration: _inputDecoration(loc.weightHint),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _repsController,
                keyboardType: TextInputType.number,
                inputFormatters: _repsInputFormatters,
                decoration: _inputDecoration(loc.repsHint),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAddButton(AppLocalizations loc) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _addWorkout,
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: Text(
          loc.addWorkoutButton,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildWorkoutList(AppLocalizations loc) {
    if (_workouts.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: Text(loc.emptyWorkoutList, style: const TextStyle(color: Colors.grey)),
        ),
      );
    }
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _workouts.length,
      separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
      itemBuilder: (context, index) {
        final record = _workouts[index];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Row(
            children: [
              SizedBox(
                width: 28,
                child: Center(
                  child: IconVisual(
                    iconCodePoint: record.iconCodePoint,
                    iconFontFamily: record.iconFontFamily,
                    iconFontPackage: record.iconFontPackage,
                    imagePath: record.iconImagePath,
                    imageBase64: record.iconImageBase64,
                    size: 22,
                    color: _primaryColor,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(color: Colors.black, fontSize: 14),
                        children: [
                          TextSpan(
                            text: record.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          TextSpan(
                            text: ' ${loc.workoutSummary(record.weight, record.reps)}',
                            style: const TextStyle(
                              color: Color(0xFF2563EB),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 11, color: Color(0xFF64748B)),
                        const SizedBox(width: 4),
                        Text(
                          '${record.date}'
                          '${record.iconName.isNotEmpty ? ' · ${record.iconName}' : ''}',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton(
                    onPressed: () => _editWorkout(index),
                    style: TextButton.styleFrom(
                      backgroundColor: const Color(0xFFEFF6FF),
                      foregroundColor: _primaryColor,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(loc.editButton, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 6),
                  TextButton(
                    onPressed: () => _deleteWorkout(index),
                    style: TextButton.styleFrom(
                      backgroundColor: const Color(0xFFFEE2E2),
                      foregroundColor: const Color(0xFFEF4444),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(loc.deleteButton, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
