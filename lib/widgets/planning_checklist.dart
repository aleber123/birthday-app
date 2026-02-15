import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/birthday.dart';
import '../providers/birthday_provider.dart';
import '../services/premium_service.dart';
import '../l10n/app_localizations.dart';
import '../utils/app_theme.dart';
import '../screens/paywall_screen.dart';

class PlanningChecklist extends StatelessWidget {
  final Birthday birthday;

  const PlanningChecklist({super.key, required this.birthday});

  @override
  Widget build(BuildContext context) {
    final premium = PremiumService();
    final items = birthday.planningItems;
    final completedCount = items.where((i) => i.isCompleted).length;
    final progress = items.isEmpty ? 0.0 : completedCount / items.length;

    Color levelColor;
    String levelLabel;
    IconData levelIcon;

    switch (birthday.relationType) {
      case RelationType.closeFamily:
        levelColor = AppTheme.secondaryColor;
        levelLabel = AppLocalizations.of(context).get('detailed_planning');
        levelIcon = Icons.star_rounded;
        break;
      case RelationType.friend:
        levelColor = AppTheme.primaryColor;
        levelLabel = AppLocalizations.of(context).get('medium_planning');
        levelIcon = Icons.favorite_rounded;
        break;
      case RelationType.colleague:
        levelColor = AppTheme.accentMintStrong;
        levelLabel = AppLocalizations.of(context).get('simple_planning');
        levelIcon = Icons.check_circle_rounded;
        break;
    }

    // Premium gate: show locked teaser for free users
    if (!premium.canUsePlanning) {
      return _buildLockedView(context, levelColor, levelIcon, levelLabel, items.length);
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: levelColor.withValues(alpha: 0.1),
                valueColor: AlwaysStoppedAnimation(levelColor),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$completedCount / ${items.length}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            ...items.map((item) => _PlanningItemTile(
              item: item,
              birthday: birthday,
              color: levelColor,
            )),
            const SizedBox(height: 8),
            _AddItemButton(birthday: birthday, color: levelColor),
          ],
        ),
    );
  }

  Widget _buildLockedView(
    BuildContext context,
    Color levelColor,
    IconData levelIcon,
    String levelLabel,
    int itemCount,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            // Blurred preview of items
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Stack(
                children: [
                  Opacity(
                    opacity: 0.4,
                    child: Column(
                      children: List.generate(
                        itemCount.clamp(0, 3),
                        (i) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          child: Row(
                            children: [
                              Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: Colors.grey.shade300, width: 2),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                height: 12,
                                width: 100.0 + i * 30,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            // Upgrade CTA
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PaywallScreen()),
                  );
                },
                icon: const Icon(Icons.star_rounded, size: 18),
                label: Text(AppLocalizations.of(context).get('unlock_planning')),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFD4A017),
                  side: const BorderSide(color: Color(0xFFD4A017)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Center(
              child: Text(
                AppLocalizations.of(context).get('plan_edit_check'),
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
    );
  }
}

class _PlanningItemTile extends StatelessWidget {
  final PlanningItem item;
  final Birthday birthday;
  final Color color;

  const _PlanningItemTile({
    required this.item,
    required this.birthday,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.red),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(AppLocalizations.of(context).get('delete_task')),
            content: Text('${AppLocalizations.of(context).get('delete_confirm')} "${item.title}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(AppLocalizations.of(context).cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                child: Text(AppLocalizations.of(context).delete),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) => _deleteItem(context),
      child: InkWell(
        onTap: () => _toggleItem(context),
        onLongPress: () => _editItem(context),
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: item.isCompleted ? color : Colors.transparent,
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(
                    color: item.isCompleted ? color : Colors.grey.shade400,
                    width: 2,
                  ),
                ),
                child: item.isCompleted
                    ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item.title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    decoration: item.isCompleted ? TextDecoration.lineThrough : null,
                    color: item.isCompleted ? Colors.grey.shade400 : null,
                  ),
                ),
              ),
              Icon(Icons.more_horiz_rounded, size: 18, color: Colors.grey.shade300),
            ],
          ),
        ),
      ),
    );
  }

  void _toggleItem(BuildContext context) {
    final provider = context.read<BirthdayProvider>();
    final updatedItems = birthday.planningItems.map((p) {
      if (p.id == item.id) {
        return p.copyWith(isCompleted: !p.isCompleted);
      }
      return p;
    }).toList();
    provider.updateBirthday(birthday.copyWith(planningItems: updatedItems));
  }

  void _deleteItem(BuildContext context) {
    final provider = context.read<BirthdayProvider>();
    final updatedItems = birthday.planningItems.where((p) => p.id != item.id).toList();
    provider.updateBirthday(birthday.copyWith(planningItems: updatedItems));
  }

  void _editItem(BuildContext context) {
    final controller = TextEditingController(text: item.title);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(AppLocalizations.of(context).get('edit_task')),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            hintText: AppLocalizations.of(context).get('task_name'),
            filled: true,
            fillColor: Colors.grey.shade100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(context).cancel),
          ),
          FilledButton(
            onPressed: () {
              final newTitle = controller.text.trim();
              if (newTitle.isNotEmpty) {
                final provider = ctx.read<BirthdayProvider>();
                final updatedItems = birthday.planningItems.map((p) {
                  if (p.id == item.id) {
                    return PlanningItem(id: p.id, title: newTitle, isCompleted: p.isCompleted);
                  }
                  return p;
                }).toList();
                provider.updateBirthday(birthday.copyWith(planningItems: updatedItems));
              }
              Navigator.pop(ctx);
            },
            child: Text(AppLocalizations.of(context).save),
          ),
        ],
      ),
    );
  }
}

class _AddItemButton extends StatelessWidget {
  final Birthday birthday;
  final Color color;

  const _AddItemButton({required this.birthday, required this.color});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _addItem(context),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: color.withValues(alpha: 0.2), width: 1.5),
          borderRadius: BorderRadius.circular(10),
          color: color.withValues(alpha: 0.04),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_rounded, size: 20, color: color),
            const SizedBox(width: 6),
            Text(
              AppLocalizations.of(context).get('add_task'),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addItem(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(AppLocalizations.of(context).get('new_task')),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            hintText: AppLocalizations.of(context).get('task_name'),
            filled: true,
            fillColor: Colors.grey.shade100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
          onSubmitted: (value) {
            _saveNewItem(ctx, controller);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(context).cancel),
          ),
          FilledButton(
            onPressed: () => _saveNewItem(ctx, controller),
            child: Text(AppLocalizations.of(context).addLink),
          ),
        ],
      ),
    );
  }

  void _saveNewItem(BuildContext context, TextEditingController controller) {
    final title = controller.text.trim();
    if (title.isEmpty) return;

    final provider = context.read<BirthdayProvider>();
    final newItem = PlanningItem(
      id: 'p_${const Uuid().v4().substring(0, 8)}',
      title: title,
    );
    final updatedItems = [...birthday.planningItems, newItem];
    provider.updateBirthday(birthday.copyWith(planningItems: updatedItems));
    Navigator.pop(context);
  }
}
