import 'package:flutter/widgets.dart';

import 'cozy_date_chip.dart';

/// Horizontal scroller of [CozyDateChip]s. Formats month labels locally
/// (no intl dependency); pass [dates] and react to [onSelected].
class CozyDateScroller extends StatelessWidget {
  final List<DateTime> dates;
  final DateTime? selectedDate;
  final ValueChanged<DateTime>? onSelected;
  final EdgeInsetsGeometry padding;

  const CozyDateScroller({
    super.key,
    required this.dates,
    this.selectedDate,
    this.onSelected,
    this.padding = EdgeInsets.zero,
  });

  static const List<String> _months = [
    'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', //
    'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC',
  ];

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: padding,
        itemCount: dates.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final date = dates[index];
          final bool selected =
              selectedDate != null && _sameDay(date, selectedDate!);
          return CozyDateChip(
            topLabel: _months[date.month - 1],
            bottomLabel: '${date.day}',
            selected: selected,
            onTap: onSelected == null ? null : () => onSelected!(date),
          );
        },
      ),
    );
  }
}
