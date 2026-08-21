import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/exercise.dart';
import '../models/exercise_icons.dart';
import '../theme/app_theme.dart';
import 'exercise_icon_picker.dart';
import 'field_label.dart';
import 'type_toggle.dart';

class AddCustomExerciseResult {
  final String name;
  final ExerciseType type;
  final String iconKey;
  const AddCustomExerciseResult({
    required this.name,
    required this.type,
    required this.iconKey,
  });
}

/// 커스텀 운동 추가 다이얼로그. 컨트롤러 생명주기를 위젯 자신의
/// State에서 관리해, 다이얼로그가 닫히는 애니메이션 도중 외부에서
/// 컨트롤러를 dispose하는 것을 방지한다.
class AddCustomExerciseDialog extends StatefulWidget {
  const AddCustomExerciseDialog({super.key});

  @override
  State<AddCustomExerciseDialog> createState() =>
      _AddCustomExerciseDialogState();
}

class _AddCustomExerciseDialogState extends State<AddCustomExerciseDialog> {
  final _nameCtrl = TextEditingController();
  ExerciseType _type = ExerciseType.strength;
  String _iconKey = kExerciseIconChoices.first.key;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              loc.addCustomExerciseDialogTitle,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: AppSpacing.s3),
            FieldLabel(loc.iconFieldLabel),
            const SizedBox(height: 5),
            ExerciseIconPicker(
              selectedKey: _iconKey,
              onChanged: (key) => setState(() => _iconKey = key),
            ),
            const SizedBox(height: AppSpacing.s3),
            FieldLabel(loc.customExerciseNameHint),
            const SizedBox(height: 5),
            TextField(
              controller: _nameCtrl,
              autofocus: true,
              decoration: InputDecoration(hintText: loc.exerciseNameHint),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: AppSpacing.s3),
            FieldLabel(loc.typeFieldLabel),
            const SizedBox(height: 5),
            TypeToggle(
              type: _type,
              loc: loc,
              onChanged: (t) => setState(() => _type = t),
            ),
            const SizedBox(height: AppSpacing.s4),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(loc.cancelButton),
                ),
                const SizedBox(width: AppSpacing.s2),
                ElevatedButton(
                  onPressed: _nameCtrl.text.trim().isEmpty
                      ? null
                      : () => Navigator.pop(
                            context,
                            AddCustomExerciseResult(
                              name: _nameCtrl.text.trim(),
                              type: _type,
                              iconKey: _iconKey,
                            ),
                          ),
                  child: Text(loc.addButton),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
