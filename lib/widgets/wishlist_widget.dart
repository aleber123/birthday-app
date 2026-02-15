import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';
import '../models/birthday.dart';
import '../providers/birthday_provider.dart';
import '../services/premium_service.dart';
import '../l10n/app_localizations.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';

class WishlistWidget extends StatefulWidget {
  final Birthday birthday;

  const WishlistWidget({super.key, required this.birthday});

  @override
  State<WishlistWidget> createState() => _WishlistWidgetState();
}

class _WishlistWidgetState extends State<WishlistWidget> {
  final _textController = TextEditingController();
  final _priceController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _addItem() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    final price = double.tryParse(_priceController.text.trim().replaceAll(',', '.'));

    final newItem = WishlistItem(
      id: const Uuid().v4().substring(0, 8),
      title: text,
      price: price,
    );

    final updated = widget.birthday.copyWith(
      wishlistItems: [...widget.birthday.wishlistItems, newItem],
    );
    context.read<BirthdayProvider>().updateBirthday(updated);
    _textController.clear();
    _priceController.clear();
  }

  void _toggleItem(WishlistItem item) {
    final items = widget.birthday.wishlistItems.map((w) {
      if (w.id == item.id) return w.copyWith(isPurchased: !w.isPurchased);
      return w;
    }).toList();

    final updated = widget.birthday.copyWith(wishlistItems: items);
    context.read<BirthdayProvider>().updateBirthday(updated);
  }

  void _removeItem(WishlistItem item) {
    final items = widget.birthday.wishlistItems
        .where((w) => w.id != item.id)
        .toList();

    final updated = widget.birthday.copyWith(wishlistItems: items);
    context.read<BirthdayProvider>().updateBirthday(updated);
  }

  void _setSplit(WishlistItem item, int count) {
    final items = widget.birthday.wishlistItems.map((w) {
      if (w.id == item.id) return w.copyWith(splitBetween: count);
      return w;
    }).toList();

    final updated = widget.birthday.copyWith(wishlistItems: items);
    context.read<BirthdayProvider>().updateBirthday(updated);
  }

  void _showSplitDialog(WishlistItem item) {
    int selected = item.splitBetween;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context).shareGift,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  item.title,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: selected > 1
                          ? () => setSheetState(() => selected--)
                          : null,
                      icon: const Icon(Icons.remove_circle_outline),
                      iconSize: 32,
                      color: AppTheme.primaryColor,
                    ),
                    const SizedBox(width: 16),
                    Column(
                      children: [
                        Text(
                          '$selected',
                          style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w800),
                        ),
                        Text(
                          selected == 1 ? AppLocalizations.of(context).person : AppLocalizations.of(context).persons,
                          style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      onPressed: () => setSheetState(() => selected++),
                      icon: const Icon(Icons.add_circle_outline),
                      iconSize: 32,
                      color: AppTheme.primaryColor,
                    ),
                  ],
                ),
                if (item.price != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${(item.price! / selected).toStringAsFixed(0)} kr ${AppLocalizations.of(context).perPerson}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          _setSplit(item, selected);
                          Navigator.pop(ctx);
                        },
                        child: Text(AppLocalizations.of(context).save),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () {
                          _setSplit(item, selected);
                          Navigator.pop(ctx);
                          _shareSplitInvite(item, selected);
                        },
                        icon: const Icon(Icons.send, size: 18),
                        label: Text(AppLocalizations.of(context).invite),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF34C759),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _shareSplitInvite(WishlistItem item, int people) {
    final name = widget.birthday.name.split(' ').first;
    final perPerson = item.price != null ? (item.price! / people).toStringAsFixed(0) : '?';
    final total = item.price?.toStringAsFixed(0) ?? '?';

    final buffer = StringBuffer();
    buffer.writeln('\ud83c\udf81 Hej! Vi g\u00e5r ihop om en present till $name!');
    buffer.writeln();
    buffer.writeln('\ud83d\udce6 ${item.title}');
    buffer.writeln('\ud83d\udcb0 Totalt: $total kr');
    buffer.writeln('\ud83d\udc65 $people personer delar = $perPerson kr/person');
    buffer.writeln();
    buffer.writeln('Jag anv\u00e4nder F\u00f6delsedagar-appen f\u00f6r att h\u00e5lla koll p\u00e5 presenter och f\u00f6delsedagar \u2013 supersmidigt!');
    buffer.writeln();
    buffer.writeln('\ud83d\udcf2 Ladda ner gratis: ${AppConstants.appStoreUrl}');

    // ignore: deprecated_member_use
    Share.share(buffer.toString());
  }

  void _shareWishlist() {
    final items = widget.birthday.wishlistItems;
    if (items.isEmpty) return;

    final name = widget.birthday.name;
    final buffer = StringBuffer();
    buffer.writeln('\ud83c\udf81 \u00d6nskelista f\u00f6r $name');
    buffer.writeln();
    for (final item in items) {
      final check = item.isPurchased ? '\u2705' : '\u2b1c';
      final priceStr = item.price != null ? ' (${item.price!.toStringAsFixed(0)} kr)' : '';
      final splitStr = item.price != null && item.splitBetween > 1
          ? ' \u00f7 ${item.splitBetween} = ${item.pricePerPerson!.toStringAsFixed(0)} kr/pers'
          : '';
      buffer.writeln('$check ${item.title}$priceStr$splitStr');
    }

    // Budget summary
    final withPrice = items.where((w) => w.price != null);
    if (withPrice.isNotEmpty) {
      final total = withPrice.fold<double>(0, (s, w) => s + w.price!);
      buffer.writeln();
      buffer.writeln('\ud83d\udcb0 Totalt: ${total.toStringAsFixed(0)} kr');
    }

    buffer.writeln();
    buffer.writeln('Skickad fr\u00e5n F\u00f6delsedagar \u2013 appen som hj\u00e4lper dig att aldrig gl\u00f6mma en f\u00f6delsedag!');
    buffer.writeln('\ud83d\udcf2 Ladda ner gratis: ${AppConstants.appStoreUrl}');

    // ignore: deprecated_member_use
    Share.share(buffer.toString());
  }

  Widget _buildBudgetBar(List<WishlistItem> items) {
    final itemsWithPrice = items.where((w) => w.price != null);
    if (itemsWithPrice.isEmpty) return const SizedBox.shrink();

    final total = itemsWithPrice.fold<double>(0, (sum, w) => sum + w.price!);
    final spent = itemsWithPrice
        .where((w) => w.isPurchased)
        .fold<double>(0, (sum, w) => sum + w.price!);
    final progress = total > 0 ? (spent / total).clamp(0.0, 1.0) : 0.0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context).get('budget'),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
              ),
              Text(
                '${spent.toStringAsFixed(0)} / ${total.toStringAsFixed(0)} kr',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey.shade200,
              valueColor: const AlwaysStoppedAnimation(AppTheme.accentMintStrong),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final premium = context.watch<PremiumService>();
    final items = widget.birthday.wishlistItems;

    if (!premium.canUseWishlist) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            if (items.isNotEmpty)
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: _shareWishlist,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.share, size: 14, color: AppTheme.primaryColor),
                        const SizedBox(width: 4),
                        Text(
                          AppLocalizations.of(context).get('share'),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            if (items.isNotEmpty) _buildBudgetBar(items),
            if (items.isNotEmpty) const SizedBox(height: 10),
            if (items.isEmpty)
              Text(
                AppLocalizations.of(context).get('no_wishes_yet'),
                style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
              ),
            ...items.map((item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => _toggleItem(item),
                    child: Icon(
                      item.isPurchased
                          ? Icons.check_circle
                          : Icons.circle_outlined,
                      color: item.isPurchased
                          ? AppTheme.accentMintStrong
                          : Colors.grey.shade400,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: TextStyle(
                            fontSize: 15,
                            decoration: item.isPurchased
                                ? TextDecoration.lineThrough
                                : null,
                            color: item.isPurchased
                                ? Colors.grey.shade400
                                : null,
                          ),
                        ),
                        if (item.price != null)
                          Row(
                            children: [
                              Text(
                                '${item.price!.toStringAsFixed(0)} kr',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: item.isPurchased
                                      ? Colors.grey.shade400
                                      : AppTheme.primaryColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (item.splitBetween > 1) ...[
                                Text(
                                  ' \u00f7 ${item.splitBetween} = ${item.pricePerPerson!.toStringAsFixed(0)} kr/pers',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ],
                          ),
                      ],
                    ),
                  ),
                  if (item.price != null)
                    GestureDetector(
                      onTap: () => _showSplitDialog(item),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Icon(
                          Icons.group,
                          size: 18,
                          color: item.splitBetween > 1
                              ? AppTheme.primaryColor
                              : Colors.grey.shade400,
                        ),
                      ),
                    ),
                  GestureDetector(
                    onTap: () => _removeItem(item),
                    child: Icon(
                      Icons.close,
                      size: 18,
                      color: Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
            )),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: InputDecoration(
                      hintText: 'L\u00e4gg till \u00f6nskem\u00e5l...',
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (_) => _addItem(),
                  ),
                ),
                const SizedBox(width: 6),
                SizedBox(
                  width: 70,
                  child: TextField(
                    controller: _priceController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      hintText: 'kr',
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (_) => _addItem(),
                  ),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: _addItem,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.add, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ],
        ),
    );
  }
}
