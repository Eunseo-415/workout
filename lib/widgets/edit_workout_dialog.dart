import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/workout_record.dart';
import '../theme/app_theme.dart';
import '../utils/input_formatters.dart';
import 'date_input.dart';
import 'field_label.dart';

class EditWorkoutResult {
  final String name;
  final DateTime date;
  final int durationMinutes;
  const EditWorkoutResult({
    required this.name,
    required this.date,
    required this.durationMinutes,
  });
}

/// 운동 기록 수정 다이얼로그. 컨트롤러 생명주기를 위젯 자신의 State에서
/// 관리해, 다이얼로그가 닫히는 애니메이션 도중 외부에서 컨트롤러를
/// dispose하는 것을 방지한다.
class EditWorkoutDialog extends StatefulWidget {
  final WorkoutRecord record;
  const EditWorkoutDialog({super.key, required this.record});

  @override
  State<EditWorkoutDialog> createState() => _EditWorkoutDialogState();
}

class _EditWorkoutDialogState extends State<EditWorkoutDialog> {
  late final _nameCtrl = TextEditingController(text: widget.record.name);
  late final _hoursCtrl = TextEditingController(
      text: (widget.record.durationMinutes ~/ 60).toString());
  late final _minutesCtrl = TextEditingController(
      text: (widget.record.durationMinutes % 60).toString());
  late DateTime _date =
      DateTime.tryParse(widget.record.date) ?? DateTime.now();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _hoursCtrl.dispose();
    _minutesCtrl.dispose();
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
              loc.editWorkoutDialogTitle,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: AppSpacing.s3),
            FieldLabel(loc.nameFieldLabel),
            const SizedBox(height: 5),
            TextField(controller: _nameCtrl),
            const SizedBox(height: AppSpacing.s3),
            FieldLabel(loc.dateFieldLabel),
            const SizedBox(height: 5),
            DateInput(
              date: _date,
              onChanged: (d) => setState(() => _date = d),
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
                        controller: _hoursCtrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: digitsOnlyFormatters,
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
                        controller: _minutesCtrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: digitsOnlyFormatters,
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
                  onPressed: () => Navigator.pop(context),
                  child: Text(loc.cancelButton),
                ),
                const SizedBox(width: AppSpacing.s2),
                ElevatedButton(
                  onPressed: () => Navigator.pop(
                    context,
                    EditWorkoutResult(
                      name: _nameCtrl.text.trim(),
                      date: _date,
                      durationMinutes: (int.tryParse(_hoursCtrl.text) ?? 0) *
                              60 +
                          (int.tryParse(_minutesCtrl.text) ?? 0),
                    ),
                  ),
                  child: Text(loc.saveButton),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
