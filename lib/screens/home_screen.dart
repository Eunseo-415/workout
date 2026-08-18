import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/workout_icon.dart';
import '../models/workout_record.dart';
import '../services/storage_service.dart';
import '../widgets/icon_visual.dart';

const _primaryColor = Color(0xFF3B82F6);

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

  final _nameController = TextEditingController();
  final _weightController = TextEditingController();
  final _repsController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _weightController.dispose();
    _repsController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final icons = await _storage.loadIcons();
    final workouts = await _storage.loadWorkouts();
    setState(() {
      _icons = icons;
      _workouts = workouts;
      _loading = false;
      if (_icons.isNotEmpty) {
        _nameController.text = _icons[0].name;
      }
    });
  }

  String get _formattedDate =>
      '${_selectedDate.year.toString().padLeft(4, '0')}-'
      '${_selectedDate.month.toString().padLeft(2, '0')}-'
      '${_selectedDate.day.toString().padLeft(2, '0')}';

  List<int> get _filteredIndexes {
    final result = <int>[];
    for (var i = 0; i < _icons.length; i++) {
      if (_icons[i].type == _currentTab) result.add(i);
    }
    return result;
  }

  void _switchTab(String tab) {
    setState(() {
      _currentTab = tab;
      final firstIndex = _icons.indexWhere((icon) => icon.type == tab);
      if (firstIndex != -1) {
        _selectedIndex = firstIndex;
        _nameController.text = _icons[firstIndex].name;
      }
    });
  }

  void _selectIcon(int index) {
    setState(() {
      _selectedIndex = index;
      if (_icons[index].name.isNotEmpty) {
        _nameController.text = _icons[index].name;
      }
    });
  }

  Future<void> _persistIcons() => _storage.saveIcons(_icons);

  Future<void> _persistWorkouts() => _storage.saveWorkouts(_workouts);

  void _updateIconName(int index, String newName) {
    setState(() {
      _icons[index].name = newName;
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
    if (_icons.length <= 1) {
      _showAlert('최소 1개의 아이콘은 남아있어야 합니다!');
      return;
    }
    setState(() {
      _icons.removeAt(index);
      if (_selectedIndex >= _icons.length) {
        _selectedIndex = _icons.length - 1;
      }
    });
    await _persistIcons();
    _selectIcon(_selectedIndex);
  }

  Future<void> _addCustomImageIcon() async {
    final picked =
        await _imagePicker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    final base64Str = base64Encode(bytes);
    setState(() {
      _icons.add(WorkoutIcon(imageBase64: base64Str, name: '새운동', type: _currentTab));
    });
    await _persistIcons();
    _selectIcon(_icons.length - 1);
  }

  Future<void> _addWorkout() async {
    final name = _nameController.text.trim();
    final weight = _weightController.text.trim();
    final reps = _repsController.text.trim();

    if (name.isEmpty) {
      _showAlert('운동 종목 이름을 입력해주세요!');
      return;
    }
    if (weight.isEmpty || reps.isEmpty) {
      _showAlert('중량과 횟수를 모두 입력해주세요!');
      return;
    }

    final icon = _icons.isEmpty
        ? null
        : (_selectedIndex < _icons.length ? _icons[_selectedIndex] : _icons[0]);

    final record = WorkoutRecord(
      iconEmoji: icon?.emoji,
      iconImageBase64: icon?.imageBase64,
      iconName: icon?.name ?? '',
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
    setState(() => _workouts.removeAt(index));
    await _persistWorkouts();
  }

  void _showAlert(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('확인')),
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
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 15,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      '🏋️ 운동 기록장',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 15),
                    const Text(
                      '운동 아이콘 선택 (Type별 분류)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF475569),
                      ),
                    ),
                    const SizedBox(height: 6),
                    _buildTypeTabs(),
                    const SizedBox(height: 8),
                    _buildIconGrid(),
                    const SizedBox(height: 12),
                    _buildToggleButton(),
                    if (_managerOpen) _buildIconManagerPanel(),
                    _buildInputGroup(),
                    const SizedBox(height: 4),
                    _buildAddButton(),
                    const SizedBox(height: 20),
                    const Text(
                      '운동 기록 리스트',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF475569),
                      ),
                    ),
                    const Divider(height: 15, color: Color(0xFFE2E8F0)),
                    _buildWorkoutList(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypeTabs() {
    return Row(
      children: [
        Expanded(child: _tabButton('Type 1 (근력/기본)', 'type1')),
        const SizedBox(width: 5),
        Expanded(child: _tabButton('Type 2 (유산소/기타)', 'type2')),
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

  Widget _buildIconGrid() {
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
                IconVisual(emoji: icon.emoji, imageBase64: icon.imageBase64, size: 20),
                const SizedBox(height: 4),
                SizedBox(
                  height: 13,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      icon.name,
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

  Widget _buildToggleButton() {
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
        child: Text(
          _managerOpen ? '⚙️ 아이콘 설정 닫기 🔼' : '⚙️ 아이콘 설정 (타입/이름/순서) 🔽',
          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF334155)),
        ),
      ),
    );
  }

  Widget _buildIconManagerPanel() {
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
          const Text(
            '아이콘 타입 및 이름 수정',
            style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF334155)),
          ),
          const SizedBox(height: 8),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _icons.length,
            itemBuilder: (context, index) => _iconManageRow(_icons[index], index),
          ),
          const SizedBox(height: 4),
          const Divider(height: 1),
          const SizedBox(height: 8),
          const Text(
            '📁 새 아이콘 추가 (이미지)',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF334155),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _addCustomImageIcon,
              icon: const Icon(Icons.image_outlined, size: 16),
              label: const Text('갤러리에서 선택'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconManageRow(WorkoutIcon icon, int index) {
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
              child: IconVisual(emoji: icon.emoji, imageBase64: icon.imageBase64, size: 18),
            ),
          ),
          const SizedBox(width: 6),
          DropdownButton<String>(
            value: icon.type,
            underline: const SizedBox.shrink(),
            style: const TextStyle(fontSize: 12, color: Colors.black),
            items: const [
              DropdownMenuItem(value: 'type1', child: Text('Type1')),
              DropdownMenuItem(value: 'type2', child: Text('Type2')),
            ],
            onChanged: (value) {
              if (value != null) _updateIconType(index, value);
            },
          ),
          const SizedBox(width: 6),
          Expanded(
            child: TextFormField(
              key: ValueKey('name_${icon.id}'),
              initialValue: icon.name,
              style: const TextStyle(fontSize: 13),
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                border: OutlineInputBorder(),
                hintText: '이름',
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

  Widget _buildInputGroup() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _nameController,
          decoration: _inputDecoration('운동 종목 이름 (예: 스쿼트)'),
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
                decoration: _inputDecoration('중량 (kg)'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _repsController,
                keyboardType: TextInputType.number,
                decoration: _inputDecoration('횟수 (회)'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAddButton() {
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
        child: const Text(
          '기록 추가하기',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildWorkoutList() {
    if (_workouts.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: Text('기록된 운동이 없습니다.', style: TextStyle(color: Colors.grey)),
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
                    emoji: record.iconEmoji,
                    imageBase64: record.iconImageBase64,
                    size: 22,
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
                            text: ' (${record.weight}kg / ${record.reps}회)',
                            style: const TextStyle(
                              color: Color(0xFF2563EB),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '📅 ${record.date}'
                      '${record.iconName.isNotEmpty ? ' · ${record.iconName}' : ''}',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => _deleteWorkout(index),
                style: TextButton.styleFrom(
                  backgroundColor: const Color(0xFFFEE2E2),
                  foregroundColor: const Color(0xFFEF4444),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('삭제', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
    );
  }
}
