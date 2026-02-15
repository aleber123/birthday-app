import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../models/birthday.dart';
import '../providers/birthday_provider.dart';
import '../l10n/app_localizations.dart';
import '../utils/app_theme.dart';
import '../widgets/birthday_avatar.dart';
import 'birthday_detail_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    return Consumer<BirthdayProvider>(
      builder: (context, provider, _) {
        final selectedBirthdays = _selectedDay != null
            ? _getBirthdaysForDay(_selectedDay!, provider.allBirthdays)
            : <Birthday>[];

        return CustomScrollView(
          slivers: [
            SliverAppBar(
              floating: true,
              title: Text(AppLocalizations.of(context).calendar),
            ),
            SliverToBoxAdapter(
              child: Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TableCalendar(
                  firstDay: DateTime(DateTime.now().year - 1, 1, 1),
                  lastDay: DateTime(DateTime.now().year + 1, 12, 31),
                  focusedDay: _focusedDay,
                  calendarFormat: _calendarFormat,
                  locale: AppLocalizations.of(context).locale.languageCode,
                  startingDayOfWeek: StartingDayOfWeek.monday,
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                  },
                  onFormatChanged: (format) {
                    setState(() => _calendarFormat = format);
                  },
                  onPageChanged: (focusedDay) {
                    _focusedDay = focusedDay;
                  },
                  eventLoader: (day) {
                    return _getBirthdaysForDay(day, provider.allBirthdays);
                  },
                  calendarStyle: CalendarStyle(
                    todayDecoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                    ),
                    selectedDecoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      shape: BoxShape.circle,
                    ),
                    markerDecoration: BoxDecoration(
                      color: AppTheme.secondaryColor,
                      shape: BoxShape.circle,
                    ),
                    markerSize: 6,
                    markersMaxCount: 3,
                  ),
                  headerStyle: const HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                    titleTextStyle: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            if (selectedBirthdays.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    _selectedDay != null
                        ? '${AppLocalizations.of(context).birthdaysOn} ${DateFormat.MMMd(AppLocalizations.of(context).locale.languageCode).format(_selectedDay!)}'
                        : '',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final birthday = selectedBirthdays[index];
                    return _buildBirthdayTile(context, birthday);
                  },
                  childCount: selectedBirthdays.length,
                ),
              ),
            ] else if (_selectedDay != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Text(
                      AppLocalizations.of(context).get('no_birthdays_this_day'),
                      style: const TextStyle(color: Colors.grey, fontSize: 15),
                    ),
                  ),
                ),
              ),
            _buildMonthOverview(provider),
            const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
          ],
        );
      },
    );
  }

  Widget _buildBirthdayTile(BuildContext context, Birthday birthday) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: BirthdayAvatar(birthday: birthday, size: 44),
        title: Text(birthday.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(AppLocalizations.of(context).get('milestone_generic').replaceAll('{age}', '${birthday.turningAge}')),
        trailing: Text(
          birthday.zodiacEmoji,
          style: const TextStyle(fontSize: 24),
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BirthdayDetailScreen(birthdayId: birthday.id),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMonthOverview(BirthdayProvider provider) {
    final byMonth = provider.birthdaysByMonth;
    if (byMonth.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());
    final l = AppLocalizations.of(context);

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l.get('month_overview'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(12, (index) {
                final month = index + 1;
                final birthdays = byMonth[month] ?? [];
                final count = birthdays.length;
                final isCurrentMonth = DateTime.now().month == month;
                return GestureDetector(
                  onTap: count > 0 ? () => _showMonthBirthdays(month, birthdays) : null,
                  child: Container(
                    width: (MediaQuery.of(context).size.width - 56) / 4,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isCurrentMonth
                          ? AppTheme.primaryColor.withValues(alpha: 0.1)
                          : Theme.of(context).cardTheme.color,
                      borderRadius: BorderRadius.circular(12),
                      border: isCurrentMonth
                          ? Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3))
                          : null,
                    ),
                    child: Column(
                      children: [
                        Text(
                          _localizedShortMonth(month),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isCurrentMonth ? FontWeight.bold : FontWeight.normal,
                            color: isCurrentMonth ? AppTheme.primaryColor : Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$count',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: count > 0 ? null : Colors.grey.shade400,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  void _showMonthBirthdays(int month, List<Birthday> birthdays) {
    final l = AppLocalizations.of(context);
    final monthName = DateFormat.MMMM(l.locale.languageCode).format(DateTime(2024, month));
    final sorted = List<Birthday>.from(birthdays)..sort((a, b) => a.date.day.compareTo(b.date.day));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.3,
          maxChildSize: 0.85,
          expand: false,
          builder: (ctx, scrollController) {
            return Column(
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Text(
                        monthName[0].toUpperCase() + monthName.substring(1),
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${sorted.length}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: sorted.length,
                    itemBuilder: (ctx, index) {
                      final birthday = sorted[index];
                      final dayStr = DateFormat.MMMd(l.locale.languageCode).format(
                        DateTime(2024, month, birthday.date.day),
                      );
                      return ListTile(
                        leading: BirthdayAvatar(birthday: birthday, size: 44),
                        title: Text(birthday.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text('$dayStr  •  ${l.get('turning_age_on_weekday').replaceAll('{age}', '${birthday.turningAge}').replaceAll('{weekday}', l.get(birthday.weekdayKey))}'),
                        trailing: Text(birthday.zodiacEmoji, style: const TextStyle(fontSize: 22)),
                        onTap: () {
                          Navigator.pop(ctx);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => BirthdayDetailScreen(birthdayId: birthday.id),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  List<Birthday> _getBirthdaysForDay(DateTime day, List<Birthday> allBirthdays) {
    return allBirthdays
        .where((b) => b.date.month == day.month && b.date.day == day.day)
        .toList();
  }

  String _localizedShortMonth(int month) {
    final lang = AppLocalizations.of(context).locale.languageCode;
    final name = DateFormat.MMM(lang).format(DateTime(2024, month));
    return name[0].toUpperCase() + name.substring(1);
  }
}
