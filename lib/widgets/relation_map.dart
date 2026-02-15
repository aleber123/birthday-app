import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/birthday.dart';
import '../providers/birthday_provider.dart';
import '../services/database_service.dart';
import '../l10n/app_localizations.dart';
import '../utils/app_theme.dart';

class RelationMapWidget extends StatefulWidget {
  final Birthday birthday;
  final void Function(String birthdayId)? onPersonTap;

  const RelationMapWidget({
    super.key,
    required this.birthday,
    this.onPersonTap,
  });

  @override
  State<RelationMapWidget> createState() => _RelationMapWidgetState();
}

class _RelationMapWidgetState extends State<RelationMapWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnim;
  List<_TreeLinkData> _treeLinks = [];
  String? _ownerName;
  bool _showAllLabels = false;
  static const String _ownerId = 'owner';

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOutBack);
    _animController.forward();
    _loadTreeData();
  }

  @override
  void didUpdateWidget(covariant RelationMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.birthday.id != widget.birthday.id) {
      _loadTreeData();
    }
  }

  final DatabaseService _dbService = DatabaseService();

  Future<void> _loadTreeData() async {
    final linkMaps = await _dbService.getTreeLinks();
    final ownerName = await _dbService.getTreeSetting('owner_name');
    final links = linkMaps.map((e) => _TreeLinkData.fromJson(e)).toList();
    if (mounted) {
      setState(() {
        _treeLinks = links;
        _ownerName = ownerName;
      });
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  // Node dimensions
  static const double _centerSize = 64;
  static const double _nodeCircleSize = 48;
  static const double _nodeWidth = 80;

  /// Create a synthetic Birthday for the owner so they can appear in the map
  Birthday? _makeOwnerBirthday() {
    if (_ownerName == null) return null;
    return Birthday(
      id: _ownerId,
      name: _ownerName!,
      date: DateTime(2000, 1, 1),
    );
  }

  /// Resolve a tree_link id to a Birthday (handles 'owner' specially)
  Birthday? _resolvePerson(String id, List<Birthday> allBirthdays) {
    if (id == _ownerId) return _makeOwnerBirthday();
    return allBirthdays.where((b) => b.id == id).firstOrNull;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BirthdayProvider>(
      builder: (context, provider, _) {
        final allBirthdays = provider.allBirthdays;
        final relations = widget.birthday.relations;
        final bdayId = widget.birthday.id;

        // Build unique set of people in the map (by id)
        final peopleMap = <String, Birthday>{};
        for (final relation in relations) {
          final target = allBirthdays.where((b) => b.id == relation.targetId).firstOrNull;
          if (target != null) peopleMap[target.id] = target;
          if (relation.sourceId != null && relation.sourceId != bdayId) {
            final source = allBirthdays.where((b) => b.id == relation.sourceId).firstOrNull;
            if (source != null) peopleMap[source.id] = source;
          }
        }

        // Build line data from birthday.relations
        final lines = <_RelationLine>[];
        for (final relation in relations) {
          final target = allBirthdays.where((b) => b.id == relation.targetId).firstOrNull;
          if (target == null) continue;
          lines.add(_RelationLine(
            sourceId: relation.sourceId,
            targetId: relation.targetId,
            label: relation.label,
            color: _getRelationColor(target.relationType),
          ));
        }

        // Also include tree_links that involve this person
        for (final tl in _treeLinks) {
          if (tl.parentId == bdayId) {
            // This person is the parent → child is the target
            final child = _resolvePerson(tl.childId, allBirthdays);
            if (child != null && !peopleMap.containsKey(child.id)) {
              peopleMap[child.id] = child;
            }
            if (child != null) {
              final alreadyExists = lines.any((l) => l.targetId == tl.childId);
              if (!alreadyExists) {
                lines.add(_RelationLine(
                  sourceId: null,
                  targetId: tl.childId,
                  label: tl.label,
                  color: _getRelationColor(child.relationType),
                ));
              }
            }
          } else if (tl.childId == bdayId) {
            // This person is the child → parent is the target
            final parent = _resolvePerson(tl.parentId, allBirthdays);
            if (parent != null && !peopleMap.containsKey(parent.id)) {
              peopleMap[parent.id] = parent;
            }
            if (parent != null) {
              final alreadyExists = lines.any((l) => l.targetId == tl.parentId);
              if (!alreadyExists) {
                lines.add(_RelationLine(
                  sourceId: null,
                  targetId: tl.parentId,
                  label: tl.label,
                  color: _getRelationColor(parent.relationType),
                ));
              }
            }
          }
        }

        final uniquePeople = peopleMap.values.toList();

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  icon: const Icon(Icons.person_add_outlined, size: 20),
                  onPressed: () => _showAddRelationDialog(context, provider),
                  tooltip: 'L\u00e4gg till relation',
                ),
              ),
              if (uniquePeople.isEmpty)
                _buildEmptyRelationMap(context, provider)
              else
                _buildRelationMap(context, uniquePeople, lines, provider),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyRelationMap(BuildContext context, BirthdayProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          children: [
            Icon(Icons.group_outlined, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              AppLocalizations.of(context).get('no_relations_yet'),
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => _showAddRelationDialog(context, provider),
              icon: const Icon(Icons.add, size: 18),
              label: Text(AppLocalizations.of(context).connectRelation),
            ),
          ],
        ),
      ),
    );
  }

  /// Canvas size grows with node count so there's always room.
  Size _calculateCanvasSize(int count, double availableWidth) {
    // Minimum spacing between nodes on the circle
    const minArcSpacing = 90.0;
    // Radius needed so nodes are at least minArcSpacing apart
    final neededRadius = count <= 1
        ? 80.0
        : (count * minArcSpacing) / (2 * pi);
    final radius = max(neededRadius, 80.0);
    final side = (radius + _nodeWidth / 2 + 20) * 2;
    // At least as wide as available, and at least 260 tall
    final w = max(side, availableWidth);
    final h = max(side, 260.0);
    return Size(w, h);
  }

  Widget _buildRelationMap(
    BuildContext context,
    List<Birthday> people,
    List<_RelationLine> lines,
    BirthdayProvider provider,
  ) {
    return AnimatedBuilder(
      animation: _scaleAnim,
      builder: (context, child) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final canvasSize = _calculateCanvasSize(
              people.length,
              constraints.maxWidth,
            );
            final canvasW = canvasSize.width;
            final canvasH = canvasSize.height;
            final centerX = canvasW / 2;
            final centerY = canvasH / 2;

            // Radius: fit nodes with spacing
            const minArcSpacing = 90.0;
            final neededRadius = people.length <= 1
                ? 80.0
                : (people.length * minArcSpacing) / (2 * pi);
            final radius = max(neededRadius, 80.0);

            // Build position map
            final positions = <String, Offset>{};
            positions[widget.birthday.id] = Offset(centerX, centerY);
            for (int i = 0; i < people.length; i++) {
              final angle = (2 * pi * i / people.length) - (pi / 2);
              positions[people[i].id] = Offset(
                centerX + radius * cos(angle),
                centerY + radius * sin(angle),
              );
            }

            // Build paint lines
            final paintLines = <_PaintLine>[];
            for (final line in lines) {
              final fromId = line.sourceId ?? widget.birthday.id;
              final from = positions[fromId];
              final to = positions[line.targetId];
              if (from != null && to != null) {
                paintLines.add(_PaintLine(
                  from: from,
                  to: to,
                  color: line.color,
                  label: line.label,
                ));
              }
            }

            // Visible height: capped so it doesn't push everything off screen
            final viewHeight = min(canvasH, 420.0);

            return SizedBox(
              height: viewHeight,
              child: InteractiveViewer(
                constrained: false,
                boundaryMargin: const EdgeInsets.all(40),
                minScale: 0.4,
                maxScale: 2.5,
                child: SizedBox(
                  width: canvasW,
                  height: canvasH,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Connection lines
                      CustomPaint(
                        size: Size(canvasW, canvasH),
                        painter: _RelationLinePainter(
                          lines: paintLines,
                          progress: _scaleAnim.value,
                          centerRadius: _centerSize / 2,
                          nodeRadius: _nodeCircleSize / 2,
                        ),
                      ),
                      // Center person
                      Positioned(
                        left: centerX - _centerSize / 2,
                        top: centerY - _centerSize / 2,
                        child: Transform.scale(
                          scale: _scaleAnim.value,
                          child: _buildCenterAvatar(context),
                        ),
                      ),
                      // Connected people
                      ...people.asMap().entries.map((entry) {
                        final index = entry.key;
                        final person = entry.value;
                        final angle = (2 * pi * index / people.length) - (pi / 2);
                        final nodeX = centerX + radius * cos(angle);
                        final nodeY = centerY + radius * sin(angle);

                        final rel = widget.birthday.relations.where(
                          (r) => r.targetId == person.id || r.sourceId == person.id,
                        ).firstOrNull;
                        final label = rel?.label ?? '';

                        return Positioned(
                          left: nodeX - _nodeWidth / 2,
                          top: nodeY - _nodeCircleSize / 2 - 2,
                          child: Transform.scale(
                            scale: _scaleAnim.value,
                            child: _buildPersonNode(context, person, label, provider),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCenterAvatar(BuildContext context) {
    final color = AppTheme.getAvatarColor(
      widget.birthday.avatarColor,
      widget.birthday.name,
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: _centerSize,
          height: _centerSize,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color, color.withValues(alpha: 0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Text(
              widget.birthday.name.isNotEmpty
                  ? widget.birthday.name[0].toUpperCase()
                  : '?',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPersonNode(
    BuildContext context,
    Birthday person,
    String label,
    BirthdayProvider provider,
  ) {
    final color = AppTheme.getAvatarColor(person.avatarColor, person.name);
    final ringColor = _getRelationColor(person.relationType);

    final isOwner = person.id == _ownerId;
    return GestureDetector(
      onTap: isOwner ? null : () => widget.onPersonTap?.call(person.id),
      onLongPress: isOwner ? null : () => _showNodeOptionsDialog(context, provider, person),
      child: SizedBox(
        width: _nodeWidth,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: _nodeCircleSize,
              height: _nodeCircleSize,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, color.withValues(alpha: 0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                border: Border.all(color: ringColor, width: 2.5),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  person.name.isNotEmpty ? person.name[0].toUpperCase() : '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              person.name.split(' ').first,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            if (label.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: ringColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: ringColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _getRelationColor(RelationType type) {
    switch (type) {
      case RelationType.closeFamily:
        return AppTheme.secondaryColor;
      case RelationType.friend:
        return AppTheme.primaryColor;
      case RelationType.colleague:
        return AppTheme.accentMintStrong;
    }
  }

  // ── Node options (long press) ─────────────────────────────
  void _showNodeOptionsDialog(
    BuildContext context,
    BirthdayProvider provider,
    Birthday person,
  ) {
    // Find all relations involving this person
    final relatedRelations = widget.birthday.relations.where(
      (r) => r.targetId == person.id || r.sourceId == person.id,
    ).toList();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
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
              person.name,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            // List relations
            ...relatedRelations.map((r) {
              final allBirthdays = provider.allBirthdays;
              final sourceName = r.sourceId == null
                  ? widget.birthday.name
                  : allBirthdays.where((b) => b.id == r.sourceId).firstOrNull?.name ?? '?';
              final targetName = allBirthdays.where((b) => b.id == r.targetId).firstOrNull?.name ?? '?';
              return ListTile(
                leading: const Icon(Icons.link, size: 20),
                title: Text('$sourceName \u2192 $targetName'),
                subtitle: Text(r.label),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                  onPressed: () {
                    final updated = widget.birthday.relations
                        .where((rel) => !(rel.targetId == r.targetId &&
                            rel.sourceId == r.sourceId &&
                            rel.label == r.label))
                        .toList();
                    provider.updateBirthday(
                      widget.birthday.copyWith(relations: updated),
                    );
                    Navigator.pop(ctx);
                  },
                ),
              );
            }),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  _showAddRelationDialog(context, provider, preselectedSourceId: person.id);
                },
                icon: const Icon(Icons.add, size: 18),
                label: Text('L\u00e4gg till relation fr\u00e5n ${person.name.split(' ').first}'),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  /// Sync a relation to tree_links in SQLite so it appears in the relation tree
  Future<void> _syncToTreeLinks(String parentId, String childId, String label) async {
    await _dbService.addTreeLink(parentId, childId, label);
  }

  // ── Add relation dialog ───────────────────────────────────
  void _showAddRelationDialog(
    BuildContext context,
    BirthdayProvider provider, {
    String? preselectedSourceId,
  }) {
    final allBirthdays = provider.allBirthdays;
    // Source options: center person + all people already in the map
    final sourceOptions = <Birthday>[widget.birthday];
    for (final r in widget.birthday.relations) {
      final t = allBirthdays.where((b) => b.id == r.targetId).firstOrNull;
      if (t != null && !sourceOptions.any((s) => s.id == t.id)) sourceOptions.add(t);
      if (r.sourceId != null) {
        final s = allBirthdays.where((b) => b.id == r.sourceId).firstOrNull;
        if (s != null && !sourceOptions.any((x) => x.id == s.id)) sourceOptions.add(s);
      }
    }

    String selectedSourceId = preselectedSourceId ?? widget.birthday.id;
    String? selectedTargetId;
    final labelController = TextEditingController();

    final l = AppLocalizations.of(context);
    final relationLabels = [
      l.mamma, l.pappa, l.syster, l.bror, l.partner, l.sambo,
      l.fru, l.man, l.son, l.dotter,
      l.farmor, l.farfar, l.mormor, l.morfar,
      l.farbror, l.morbror, l.faster, l.moster,
      l.svarmor, l.svarfar, l.barnbarn, l.svardotter, l.svarson,
      l.kusin, l.niece, l.nephew,
      l.friend, l.colleague, l.boss, l.neighbor,
      l.brotherInLaw, l.sisterInLaw, l.stepchild, l.ex,
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            // Target options: all birthdays except the selected source
            final targetOptions = allBirthdays
                .where((b) => b.id != selectedSourceId)
                .where((b) => b.id != widget.birthday.id || selectedSourceId != widget.birthday.id)
                .toList();

            return Padding(
              padding: EdgeInsets.only(
                left: 20, right: 20, top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40, height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Text(
                      l.connectRelation,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),

                    // ── Source picker ──
                    Text(
                      l.fromWho,
                      style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 80,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: sourceOptions.length,
                        itemBuilder: (ctx, index) {
                          final b = sourceOptions[index];
                          final isSelected = selectedSourceId == b.id;
                          final color = AppTheme.getAvatarColor(b.avatarColor, b.name);
                          final isCenter = b.id == widget.birthday.id;
                          return GestureDetector(
                            onTap: () => setModalState(() {
                              selectedSourceId = b.id;
                              if (selectedTargetId == b.id) selectedTargetId = null;
                            }),
                            child: Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: Column(
                                children: [
                                  Container(
                                    width: 48, height: 48,
                                    decoration: BoxDecoration(
                                      color: color,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isSelected ? AppTheme.primaryColor : Colors.transparent,
                                        width: 3,
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        b.name.isNotEmpty ? b.name[0].toUpperCase() : '?',
                                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  SizedBox(
                                    width: 56,
                                    child: Text(
                                      isCenter ? '${b.name.split(' ').first} (jag)' : b.name.split(' ').first,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                        color: isSelected ? AppTheme.primaryColor : null,
                                      ),
                                      textAlign: TextAlign.center,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),

                    // ── Target picker ──
                    Text(
                      l.whoToConnect,
                      style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 80,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: targetOptions.length,
                        itemBuilder: (ctx, index) {
                          final b = targetOptions[index];
                          final isSelected = selectedTargetId == b.id;
                          final color = AppTheme.getAvatarColor(b.avatarColor, b.name);
                          return GestureDetector(
                            onTap: () => setModalState(() => selectedTargetId = b.id),
                            child: Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: Column(
                                children: [
                                  Container(
                                    width: 48, height: 48,
                                    decoration: BoxDecoration(
                                      color: color,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isSelected ? AppTheme.primaryColor : Colors.transparent,
                                        width: 3,
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        b.name.isNotEmpty ? b.name[0].toUpperCase() : '?',
                                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  SizedBox(
                                    width: 56,
                                    child: Text(
                                      b.name.split(' ').first,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                        color: isSelected ? AppTheme.primaryColor : null,
                                      ),
                                      textAlign: TextAlign.center,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),

                    // ── Label picker ──
                    Text(
                      l.relations,
                      style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Builder(builder: (_) {
                      final visibleLabels = _showAllLabels ? relationLabels : relationLabels.take(10).toList();
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: visibleLabels.map((label) {
                              final isSelected = labelController.text == label;
                              return GestureDetector(
                                onTap: () => setModalState(() => labelController.text = label),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppTheme.primaryColor.withValues(alpha: 0.12)
                                        : Colors.grey.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: isSelected
                                          ? AppTheme.primaryColor
                                          : Colors.grey.withValues(alpha: 0.2),
                                    ),
                                  ),
                                  child: Text(
                                    label,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                      color: isSelected ? AppTheme.primaryColor : null,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          if (relationLabels.length > 10)
                            TextButton(
                              onPressed: () => setModalState(() => _showAllLabels = !_showAllLabels),
                              child: Text(_showAllLabels ? l.get('show_less') : l.get('show_more')),
                            ),
                        ],
                      );
                    }),
                    const SizedBox(height: 12),
                    TextField(
                      controller: labelController,
                      decoration: InputDecoration(
                        labelText: l.orWriteOwn,
                        hintText: l.egStepfather,
                        prefixIcon: const Icon(Icons.edit_outlined),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: selectedTargetId != null && labelController.text.isNotEmpty
                            ? () async {
                                final sourceId = selectedSourceId == widget.birthday.id
                                    ? null
                                    : selectedSourceId;
                                final newRelation = Relation(
                                  targetId: selectedTargetId!,
                                  label: labelController.text.trim(),
                                  sourceId: sourceId,
                                );
                                final updatedRelations = [
                                  ...widget.birthday.relations,
                                  newRelation,
                                ];
                                provider.updateBirthday(
                                  widget.birthday.copyWith(relations: updatedRelations),
                                );

                                // Also sync to tree_links so it shows in the relation tree
                                final parentId = sourceId ?? widget.birthday.id;
                                final childId = selectedTargetId!;
                                final label = labelController.text.trim();
                                await _syncToTreeLinks(parentId, childId, label);

                                if (ctx.mounted) Navigator.pop(ctx);
                              }
                            : null,
                        child: const Text('L\u00e4gg till'),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ── Data classes ─────────────────────────────────────────────

class _RelationLine {
  final String? sourceId; // null = center person
  final String targetId;
  final String label;
  final Color color;

  _RelationLine({
    required this.sourceId,
    required this.targetId,
    required this.label,
    required this.color,
  });
}

class _PaintLine {
  final Offset from;
  final Offset to;
  final Color color;
  final String label;

  _PaintLine({
    required this.from,
    required this.to,
    required this.color,
    required this.label,
  });
}

// ── Line painter ────────────────────────────────────────────

class _RelationLinePainter extends CustomPainter {
  final List<_PaintLine> lines;
  final double progress;
  final double centerRadius;
  final double nodeRadius;

  _RelationLinePainter({
    required this.lines,
    required this.progress,
    required this.centerRadius,
    required this.nodeRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final line in lines) {
      final dx = line.to.dx - line.from.dx;
      final dy = line.to.dy - line.from.dy;
      final dist = sqrt(dx * dx + dy * dy);
      if (dist < 1) continue;

      final ux = dx / dist;
      final uy = dy / dist;

      // Shorten line to stop at circle edges
      final fromR = centerRadius;
      final toR = nodeRadius;
      final startX = line.from.dx + ux * fromR;
      final startY = line.from.dy + uy * fromR;
      final endX = line.to.dx - ux * toR;
      final endY = line.to.dy - uy * toR;

      // Animate
      final animStartX = line.from.dx + (startX - line.from.dx) * progress;
      final animStartY = line.from.dy + (startY - line.from.dy) * progress;
      final animEndX = line.from.dx + (endX - line.from.dx) * progress;
      final animEndY = line.from.dy + (endY - line.from.dy) * progress;

      final paint = Paint()
        ..color = line.color.withValues(alpha: 0.2)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(
        Offset(animStartX, animStartY),
        Offset(animEndX, animEndY),
        paint,
      );

      // Dot at endpoint
      if (progress > 0.5) {
        final dotPaint = Paint()
          ..color = line.color.withValues(alpha: 0.3 * progress)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(animEndX, animEndY), 2.5, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _RelationLinePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.lines.length != lines.length;
  }
}

// ── Tree link data (mirrors _TreeLink from relation_tree_screen) ─────
class _TreeLinkData {
  final String parentId;
  final String childId;
  final String label;

  _TreeLinkData({required this.parentId, required this.childId, required this.label});

  factory _TreeLinkData.fromJson(Map<String, dynamic> m) => _TreeLinkData(
    parentId: m['parentId'] as String,
    childId: m['childId'] as String,
    label: m['label'] as String,
  );
}
