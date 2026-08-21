import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/date_format.dart';

class DateInput extends StatelessWidget {
  final DateTime date;
  final ValueChanged<DateTime> onChanged;
  const DateInput({super.key, required this.date, required this.onChanged});

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
            Text(fmtDate(date)),
          ],
        ),
      ),
    );
  }
}
