import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/birthday.dart';
import '../providers/birthday_provider.dart';
import '../services/contact_service.dart';
import '../screens/add_birthday_screen.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/database_service.dart';
import '../l10n/app_localizations.dart';
import '../utils/app_theme.dart';
import 'birthday_detail_screen.dart';

// ── Tree link model ──────────────────────────────────────
class _TreeLink {
  final String parentId;
  final String childId;
  final String label;

  _TreeLink({required this.parentId, required this.childId, required this.label});

  Map<String, dynamic> toJson() => {'parentId': parentId, 'childId': childId, 'label': label};

  factory _TreeLink.fromJson(Map<String, dynamic> m) => _TreeLink(
    parentId: m['parentId'] as String,
    childId: m['childId'] as String,
    label: m['label'] as String,
  );

  static const partnerLabels = {'Partner', 'Sambo', 'Fru', 'Man', 'Maka', 'Make', 'Hustru'};
  bool get isPartner => partnerLabels.contains(label);
}

// ── Child ownership enum ─────────────────────────────────
enum _ChildOwner { left, shared, right }

// ── Layout node for custom tree ──────────────────────────
class _LayoutNode {
  final String id;
  final String? partnerId;
  final String? partnerLabel;
  final List<_LayoutNode> children;
  /// Which parent each child belongs to (parallel list with children)
  final List<_ChildOwner> childOwnership;
  double x = 0;
  double y = 0;
  double subtreeWidth = 0;

  _LayoutNode({
    required this.id,
    this.partnerId,
    this.partnerLabel,
    List<_LayoutNode>? children,
    List<_ChildOwner>? childOwnership,
  })  : children = children ?? [],
        childOwnership = childOwnership ?? [];

  static const double nodeW = 120.0;
  static const double pairW = 260.0;
  static const double nodeH = 110.0;
  static const double hGap = 24.0;
  static const double vGap = 60.0;

  double get width => partnerId != null ? pairW : nodeW;
}

class RelationTreeScreen extends StatefulWidget {
  const RelationTreeScreen({super.key});

  @override
  State<RelationTreeScreen> createState() => RelationTreeScreenState();
}

class RelationTreeScreenState extends State<RelationTreeScreen> {
  String? _ownerName;
  DateTime? _ownerBirthday;
  String? _ownerImage;
  bool _profileLoaded = false;
  List<_TreeLink> _links = [];
  final _nameController = TextEditingController();
  final TransformationController _transformController = TransformationController();
  final _searchController = TextEditingController();
  bool _isSearching = false;
  String _searchQuery = '';
  bool _isLocked = true;
  bool _showAllLabelsEdit = false;
  bool _showAllLabelsAdd = false;
  // Manual position offsets for drag-and-drop
  final Map<String, Offset> _dragOffsets = {};
  final List<MapEntry<String, Offset?>> _dragUndoStack = [];

  static const String _ownerId = 'owner';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  final DatabaseService _dbService = DatabaseService();

  Future<void> _loadData() async {
    // Migrate old SharedPreferences data to SQLite (runs once)
    await _dbService.migrateTreeDataFromPrefs();

    final name = await _dbService.getTreeSetting('owner_name');
    final bdayStr = await _dbService.getTreeSetting('owner_birthday');
    final imgPath = await _dbService.getTreeSetting('owner_image');

    final linkMaps = await _dbService.getTreeLinks();
    final links = linkMaps.map((e) => _TreeLink.fromJson(e)).toList();

    // Load lock state
    final lockedStr = await _dbService.getTreeSetting('tree_locked');
    final locked = lockedStr == null ? true : lockedStr == 'true';

    // Load drag offsets
    final dragJson = await _dbService.getTreeSetting('tree_drag_offsets');
    Map<String, Offset> savedDrags = {};
    if (dragJson != null) {
      final map = jsonDecode(dragJson) as Map<String, dynamic>;
      savedDrags = map.map((k, v) {
        final list = v as List;
        return MapEntry(k, Offset(list[0].toDouble(), list[1].toDouble()));
      });
    }
    setState(() {
      _ownerName = name;
      _ownerBirthday = bdayStr != null ? DateTime.tryParse(bdayStr) : null;
      _ownerImage = imgPath;
      _links = links;
      _isLocked = locked;
      _dragOffsets.addAll(savedDrags);
      _profileLoaded = true;
    });
  }

  Future<void> _saveLinks() async {
    await _dbService.saveTreeLinks(_links.map((l) => l.toJson()).toList());
  }

  Future<void> _saveLockState() async {
    await _dbService.setTreeSetting('tree_locked', _isLocked.toString());
  }

  Future<void> _saveDragOffsets() async {
    final map = _dragOffsets.map((k, v) => MapEntry(k, [v.dx, v.dy]));
    await _dbService.setTreeSetting('tree_drag_offsets', jsonEncode(map));
  }

  Future<void> _saveProfile(String name, DateTime birthday, {String? imagePath}) async {
    await _dbService.setTreeSetting('owner_name', name);
    await _dbService.setTreeSetting('owner_birthday', birthday.toIso8601String());
    if (imagePath != null) {
      await _dbService.setTreeSetting('owner_image', imagePath);
    }
    setState(() {
      _ownerName = name;
      _ownerBirthday = birthday;
      if (imagePath != null) _ownerImage = imagePath;
    });
  }

  Future<String?> _pickOwnerImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      if (picked == null) return null;
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = 'owner_avatar_${const Uuid().v4()}${p.extension(picked.path)}';
      final savedFile = await File(picked.path).copy('${appDir.path}/$fileName');
      return savedFile.path;
    } catch (e) {
      return null;
    }
  }

  int get _ownerAge {
    if (_ownerBirthday == null) return 0;
    final now = DateTime.now();
    int age = now.year - _ownerBirthday!.year;
    if (now.month < _ownerBirthday!.month ||
        (now.month == _ownerBirthday!.month && now.day < _ownerBirthday!.day)) {
      age--;
    }
    return age;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _transformController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // ── Public API for HomeScreen FAB ──────────────────────
  void showAddLinkDialog({String? preselectedParentId}) {
    final provider = context.read<BirthdayProvider>();
    
    // If no birthdays exist, show choice dialog
    if (provider.allBirthdays.isEmpty) {
      _showAddChoiceDialog(provider);
    } else {
      _showAddLinkDialogInner(provider, preselectedParentId: preselectedParentId);
    }
  }

  // ── Add choice dialog (manual vs import) ──────────────────
  void _showAddChoiceDialog(BirthdayProvider provider) {
    final l = AppLocalizations.of(context);
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Lägg till födelsedagar',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              
              // Manual option
              ListTile(
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.person_add, color: AppTheme.primaryColor),
                ),
                title: Text('Lägg till manuellt', style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text('Fyll i formuläret för att lägga till en ny födelsedag'),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AddBirthdayScreen()),
                  );
                },
              ),
              
              const SizedBox(height: 8),
              
              // Import option
              ListTile(
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppTheme.accentSky.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.contacts, color: AppTheme.accentSky),
                ),
                title: Text('Importera från kontakter', style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text('Importera födelsedagar från din telefonkontakter'),
                onTap: () {
                  Navigator.pop(ctx);
                  _importFromContacts();
                },
              ),
              
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  // ── Import from contacts ────────────────────────────────
  Future<void> _importFromContacts() async {
    final contactService = ContactService();

    // Request permission via flutter_contacts (shows iOS system dialog)
    final granted = await FlutterContacts.requestPermission();
    if (!granted && mounted) {
      // Completely denied – offer to open Settings
      final goToSettings = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('Importera kontakter'),
          content: Text('Appen behöver tillgång till dina kontakter för att importera födelsedagar.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Avbryt'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('Öppna inställningar'),
            ),
          ],
        ),
      );
      if (goToSettings == true) {
        await openAppSettings();
        if (!mounted) return;
        final nowGranted = await FlutterContacts.requestPermission();
        if (!nowGranted) return;
      } else {
        return;
      }
    }

    // Fetch available contacts
    final allFromContacts = await contactService.getPickableContacts();
    if (!mounted) return;

    if (allFromContacts.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Inga kontakter hittades')),
        );
      }
      return;
    }

    // Filter out contacts that already exist (by name)
    final existingNames = context.read<BirthdayProvider>().allBirthdays
        .map((b) => b.name.toLowerCase().trim())
        .toSet();
    final newContacts = allFromContacts
        .where((c) => !existingNames.contains(c.displayName.toLowerCase().trim()))
        .toList();

    if (newContacts.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Alla kontakter är redan importerade')),
        );
      }
      return;
    }

    // Show contact picker dialog
    await _showContactPickerDialog(
      contactService: contactService,
      contacts: newContacts,
    );
  }

  // ── Contact picker dialog (reused from AddBirthdayScreen) ──
  Future<void> _showContactPickerDialog({
    required ContactService contactService,
    required List<PickableContact> contacts,
  }) async {
    final selected = <int>{};
    
    // Search state
    String searchQuery = '';
    List<PickableContact> filteredContacts = List.from(contacts);
    
    // Filter contacts based on search query
    void filterContacts(String query) {
      searchQuery = query.toLowerCase().trim();
      if (searchQuery.isEmpty) {
        filteredContacts = List.from(contacts);
      } else {
        filteredContacts = contacts.where((contact) => 
          contact.displayName.toLowerCase().contains(searchQuery)
        ).toList();
      }
    }

    final result = await showModalBottomSheet<List<PickableContact>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.85,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              expand: false,
              builder: (ctx, scrollController) {
                return Column(
                  children: [
                    // Handle bar
                    Container(
                      margin: const EdgeInsets.only(top: 12, bottom: 8),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    // Title and search
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Column(
                        children: [
                          // Title row
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Importera kontakter',
                                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                ),
                              ),
                              if (contacts.isNotEmpty)
                                TextButton(
                                  onPressed: () {
                                    setSheetState(() {
                                      if (selected.length == filteredContacts.length) {
                                        selected.clear();
                                      } else {
                                        selected.clear();
                                        for (int i = 0; i < filteredContacts.length; i++) {
                                          // Find the original index of this filtered contact
                                          final originalIndex = contacts.indexOf(filteredContacts[i]);
                                          if (originalIndex != -1) {
                                            selected.add(originalIndex);
                                          }
                                        }
                                      }
                                    });
                                  },
                                  child: Text(selected.length == filteredContacts.length
                                      ? 'Avmarkera alla'
                                      : 'Markera alla'),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Search field
                          if (contacts.isNotEmpty)
                            TextField(
                              onChanged: (value) {
                                setSheetState(() {
                                  filterContacts(value);
                                  // Clear selections when search changes
                                  selected.clear();
                                });
                              },
                              decoration: InputDecoration(
                                hintText: 'Sök kontakter...',
                                prefixIcon: const Icon(Icons.search),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                            ),
                        ],
                      ),
                    ),
                    // Contact list
                    Expanded(
                      child: filteredContacts.isEmpty
                          ? contacts.isEmpty
                              ? const SizedBox.shrink()
                              : Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Text(
                                    searchQuery.isEmpty 
                                        ? 'Inga kontakter att importera'
                                        : 'Inga kontakter matchar "$searchQuery"',
                                    style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
                                    textAlign: TextAlign.center,
                                  ),
                                )
                          : ListView.builder(
                              controller: scrollController,
                              itemCount: filteredContacts.length,
                              itemBuilder: (ctx, i) {
                                final c = filteredContacts[i];
                                final originalIndex = contacts.indexOf(c);
                                final isSelected = selected.contains(originalIndex);
                                return CheckboxListTile(
                                  value: isSelected,
                                  onChanged: (val) {
                                    setSheetState(() {
                                      if (val == true) {
                                        selected.add(originalIndex);
                                      } else {
                                        selected.remove(originalIndex);
                                      }
                                    });
                                  },
                                  title: Text(c.displayName, style: const TextStyle(fontWeight: FontWeight.w600)),
                                  subtitle: c.birthday != null
                                      ? Text(DateFormat.yMMMd('sv').format(c.birthday!))
                                      : Text('Ingen födelsedag satt', style: TextStyle(color: Colors.grey.shade400)),
                                  secondary: CircleAvatar(
                                    backgroundColor: AppTheme.getAvatarColor(null, c.displayName),
                                    child: Text(
                                      c.displayName.isNotEmpty ? c.displayName[0].toUpperCase() : '?',
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                    // Import button
                    if (contacts.isNotEmpty)
                      SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: selected.isEmpty
                                  ? null
                                  : () {
                                      final chosen = selected.map((i) => contacts[i]).toList();
                                      Navigator.pop(ctx, chosen);
                                    },
                              icon: const Icon(Icons.download_rounded),
                              label: Text('Importera kontakter (${selected.length})'),
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            );
          },
        );
      },
    );

    if (result != null && result.isNotEmpty && mounted) {
      final birthdays = <Birthday>[];
      for (final c in result) {
        birthdays.add(await contactService.contactToBirthday(c));
      }
      await context.read<BirthdayProvider>().importBirthdays(birthdays);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${birthdays.length} kontakter importerade!')),
        );
      }
    }
  }

  bool get hasProfile => _ownerName != null;

  @override
  Widget build(BuildContext context) {
    return Consumer<BirthdayProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          appBar: AppBar(
            title: _isSearching
                ? TextField(
                    controller: _searchController,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(context).searchPerson,
                      border: InputBorder.none,
                      hintStyle: const TextStyle(fontWeight: FontWeight.w400),
                    ),
                    style: const TextStyle(fontSize: 16),
                    onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
                  )
                : Text(AppLocalizations.of(context).relationMap),
            centerTitle: !_isSearching,
            actions: [
              if (_ownerName != null && _links.isNotEmpty)
                IconButton(
                  icon: Icon(_isLocked ? Icons.lock_rounded : Icons.lock_open_rounded, size: 20,
                    color: _isLocked ? AppTheme.primaryColor : null),
                  onPressed: () {
                    setState(() => _isLocked = !_isLocked);
                    _saveLockState();
                    final l = AppLocalizations.of(context);
                    ScaffoldMessenger.of(context).clearSnackBars();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            Icon(_isLocked ? Icons.lock_rounded : Icons.lock_open_rounded,
                              color: Colors.white, size: 18),
                            const SizedBox(width: 8),
                            Text(_isLocked ? l.lockMap : l.unlockMap),
                          ],
                        ),
                        duration: const Duration(seconds: 1),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    );
                  },
                  tooltip: _isLocked ? AppLocalizations.of(context).unlockMap : AppLocalizations.of(context).lockMap,
                ),
              if (_dragUndoStack.isNotEmpty && !_isLocked)
                IconButton(
                  icon: const Icon(Icons.undo_rounded, size: 22),
                  onPressed: () {
                    final last = _dragUndoStack.removeLast();
                    setState(() {
                      if (last.value == null) {
                        _dragOffsets.remove(last.key);
                      } else {
                        _dragOffsets[last.key] = last.value!;
                      }
                    });
                    _saveDragOffsets();
                  },
                  tooltip: 'Undo',
                ),
              if (_dragOffsets.isNotEmpty && !_isLocked)
                IconButton(
                  icon: const Icon(Icons.restart_alt_rounded, size: 22),
                  onPressed: () {
                    final l = AppLocalizations.of(context);
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: Text(l.resetLayout),
                        content: Text(l.get('reset_layout_confirm')),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: Text(l.cancel),
                          ),
                          FilledButton(
                            onPressed: () {
                              setState(() {
                                _dragOffsets.clear();
                                _dragUndoStack.clear();
                              });
                              _saveDragOffsets();
                              Navigator.pop(ctx);
                            },
                            child: Text(l.resetLayout),
                          ),
                        ],
                      ),
                    );
                  },
                  tooltip: AppLocalizations.of(context).resetLayout,
                ),
              if (_ownerName != null && _links.isNotEmpty)
                IconButton(
                  icon: Icon(_isSearching ? Icons.close : Icons.search, size: 22),
                  onPressed: () {
                    setState(() {
                      _isSearching = !_isSearching;
                      if (!_isSearching) {
                        _searchController.clear();
                        _searchQuery = '';
                      }
                    });
                  },
                  tooltip: _isSearching ? AppLocalizations.of(context).closeSearch : AppLocalizations.of(context).search,
                ),
              if (_ownerName != null)
                IconButton(
                  icon: const Icon(Icons.person_outline, size: 22),
                  onPressed: _showEditProfileDialog,
                  tooltip: AppLocalizations.of(context).myProfile,
                ),
            ],
          ),
          body: !_profileLoaded
              ? const Center(child: CircularProgressIndicator())
              : _ownerName == null
                  ? _buildSetup()
                  : _buildTree(provider),
        );
      },
    );
  }

  // ── Build tree layout ──────────────────────────────────
  _LayoutNode _buildLayoutTree(Map<String, Birthday> bdayMap) {
    final partnerLinks = _links.where((l) => l.isPartner).toList();
    final regularLinks = _links.where((l) => !l.isPartner).toList();

    // Build partner map: personId -> (partnerId, label)
    final partnerMap = <String, (String, String)>{};
    final partnerIds = <String>{};
    for (final pl in partnerLinks) {
      partnerMap[pl.parentId] = (pl.childId, pl.label);
      partnerIds.add(pl.childId);
    }

    // Build children map from regular links (exclude partner-only nodes from children)
    final childrenMap = <String, List<String>>{};
    for (final link in regularLinks) {
      if (partnerIds.contains(link.childId)) continue;
      childrenMap.putIfAbsent(link.parentId, () => []).add(link.childId);
    }

    // Recursive tree builder
    final visited = <String>{};
    _LayoutNode buildNode(String id) {
      visited.add(id);
      final partner = partnerMap[id];

      final personChildIds = (childrenMap[id] ?? []).toSet();
      final partnerChildIds = partner != null ? (childrenMap[partner.$1] ?? []).toSet() : <String>{};

      // Categorize: shared = linked to both, left = person only, right = partner only
      final sharedIds = personChildIds.intersection(partnerChildIds);
      final leftOnly = personChildIds.difference(sharedIds);
      final rightOnly = partnerChildIds.difference(sharedIds);

      // Build ordered list: left children, shared children, right children
      final orderedIds = <String>[];
      final ownership = <_ChildOwner>[];

      for (final cid in leftOnly) {
        orderedIds.add(cid);
        ownership.add(_ChildOwner.left);
      }
      for (final cid in sharedIds) {
        orderedIds.add(cid);
        ownership.add(_ChildOwner.shared);
      }
      for (final cid in rightOnly) {
        orderedIds.add(cid);
        ownership.add(_ChildOwner.right);
      }

      final children = <_LayoutNode>[];
      final childOwnership = <_ChildOwner>[];
      for (int i = 0; i < orderedIds.length; i++) {
        final cid = orderedIds[i];
        if (visited.contains(cid)) continue;
        children.add(buildNode(cid));
        childOwnership.add(ownership[i]);
      }

      return _LayoutNode(
        id: id,
        partnerId: partner?.$1,
        partnerLabel: partner?.$2,
        children: children,
        childOwnership: childOwnership,
      );
    }

    return buildNode(_ownerId);
  }

  void _layoutTree(_LayoutNode node, double startX, double startY) {
    _computeSubtreeWidth(node);
    _assignPositions(node, startX, startY);
  }

  void _computeSubtreeWidth(_LayoutNode node) {
    if (node.children.isEmpty) {
      node.subtreeWidth = node.width;
      return;
    }
    for (final child in node.children) {
      _computeSubtreeWidth(child);
    }
    final childrenTotalWidth = node.children.fold<double>(
      0, (sum, c) => sum + c.subtreeWidth,
    ) + (node.children.length - 1) * _LayoutNode.hGap;

    node.subtreeWidth = math.max(node.width, childrenTotalWidth);
  }

  void _assignPositions(_LayoutNode node, double centerX, double y) {
    node.x = centerX;
    node.y = y;

    if (node.children.isEmpty) return;

    final childrenTotalWidth = node.children.fold<double>(
      0, (sum, c) => sum + c.subtreeWidth,
    ) + (node.children.length - 1) * _LayoutNode.hGap;

    double childX = centerX - childrenTotalWidth / 2;
    final childY = y + _LayoutNode.nodeH + _LayoutNode.vGap;

    for (final child in node.children) {
      final childCenterX = childX + child.subtreeWidth / 2;
      _assignPositions(child, childCenterX, childY);
      childX += child.subtreeWidth + _LayoutNode.hGap;
    }
  }

  // Collect all nodes flat
  List<_LayoutNode> _flattenTree(_LayoutNode root) {
    final result = <_LayoutNode>[root];
    for (final child in root.children) {
      result.addAll(_flattenTree(child));
    }
    return result;
  }

  // Collect parent-child edges for line drawing
  List<(Offset, Offset, _ChildOwner, RelationType?)> _collectEdges(
    _LayoutNode root,
    Map<String, Offset> dragOffsets,
    Map<String, Birthday> bdayMap,
  ) {
    final edges = <(Offset, Offset, _ChildOwner, RelationType?)>[];
    final rootDrag = dragOffsets[root.id] ?? Offset.zero;

    for (int i = 0; i < root.children.length; i++) {
      final child = root.children[i];
      final childDrag = dragOffsets[child.id] ?? Offset.zero;
      final owner = i < root.childOwnership.length ? root.childOwnership[i] : _ChildOwner.shared;
      final childRelType = bdayMap[child.id]?.relationType;

      // Determine parent anchor point based on ownership
      double parentAnchorX;
      if (root.partnerId != null) {
        const halfPair = _LayoutNode.pairW / 2;
        const quarterPair = halfPair / 2;
        switch (owner) {
          case _ChildOwner.left:
            parentAnchorX = root.x - quarterPair;
          case _ChildOwner.shared:
            parentAnchorX = root.x;
          case _ChildOwner.right:
            parentAnchorX = root.x + quarterPair;
        }
      } else {
        parentAnchorX = root.x;
      }

      final parentBottom = Offset(parentAnchorX + rootDrag.dx, root.y + _LayoutNode.nodeH + rootDrag.dy);
      final childTop = Offset(child.x + childDrag.dx, child.y + childDrag.dy);
      edges.add((parentBottom, childTop, owner, childRelType));
      edges.addAll(_collectEdges(child, dragOffsets, bdayMap));
    }
    return edges;
  }

  Widget _buildTree(BirthdayProvider provider) {
    final allBirthdays = provider.allBirthdays;
    final bdayMap = {for (final b in allBirthdays) b.id: b};

    // Clean orphaned links referencing deleted persons
    final validIds = bdayMap.keys.toSet()..add(_ownerId);
    final before = _links.length;
    _links.removeWhere((l) => !validIds.contains(l.parentId) || !validIds.contains(l.childId));
    if (_links.length != before) _saveLinks();

    if (_links.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildOwnerNodeWidget(null, null),
              const SizedBox(height: 32),
              Icon(Icons.arrow_downward_rounded, size: 40, color: Colors.grey.shade300),
              const SizedBox(height: 16),
              Text(
                'Tryck \ud83d\udd17 f\u00f6r att koppla\npersoner till dig',
                style: TextStyle(fontSize: 16, color: Colors.grey.shade500, height: 1.4),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // Build and layout tree
    final root = _buildLayoutTree(bdayMap);
    _layoutTree(root, 0, 0);

    // Flatten and find bounds (including drag offsets)
    final allNodes = _flattenTree(root);
    double minX = double.infinity, maxX = double.negativeInfinity;
    double minY = double.infinity, maxY = double.negativeInfinity;
    for (final n in allNodes) {
      final drag = _dragOffsets[n.id] ?? Offset.zero;
      final halfW = n.width / 2;
      final nx = n.x + drag.dx;
      final ny = n.y + drag.dy;
      if (nx - halfW < minX) minX = nx - halfW;
      if (nx + halfW > maxX) maxX = nx + halfW;
      if (ny < minY) minY = ny;
      if (ny + _LayoutNode.nodeH > maxY) maxY = ny + _LayoutNode.nodeH;
    }

    const padding = 300.0;
    final totalW = (maxX - minX) + padding * 2;
    final totalH = (maxY - minY) + padding * 2;
    final offsetX = -minX + padding;
    final offsetY = -minY + padding;

    final edges = _collectEdges(root, _dragOffsets, bdayMap);

    final screenW = MediaQuery.of(context).size.width;
    final screenH = MediaQuery.of(context).size.height;
    final canvasW = math.max(totalW, screenW * 2);
    final canvasH = math.max(totalH, screenH * 2);

    // Center view on root node on first build
    if (_transformController.value == Matrix4.identity()) {
      final rootDrag = _dragOffsets[root.id] ?? Offset.zero;
      final rootScreenX = root.x + offsetX + rootDrag.dx;
      final rootScreenY = root.y + offsetY + rootDrag.dy;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          final m = Matrix4.identity();
          m.storage[12] = -(rootScreenX - screenW / 2);
          m.storage[13] = -(rootScreenY - screenH / 3);
          _transformController.value = m;
        }
      });
    }

    return InteractiveViewer(
      transformationController: _transformController,
      constrained: false,
      boundaryMargin: EdgeInsets.all(math.max(canvasW, canvasH)),
      minScale: 0.05,
      maxScale: 3.0,
      child: SizedBox(
        width: canvasW,
        height: canvasH,
        child: Stack(
          children: [
            // Draw connection lines
            CustomPaint(
              size: Size(canvasW, canvasH),
              painter: _TreeLinePainter(
                edges: edges,
                offset: Offset(offsetX, offsetY),
              ),
            ),
            // Place node widgets
            ...allNodes.map((node) {
              final dragOff = _dragOffsets[node.id] ?? Offset.zero;
              final left = node.x - node.width / 2 + offsetX + dragOff.dx;
              final top = node.y + offsetY + dragOff.dy;

              // Search matching
              bool matches = true;
              if (_searchQuery.isNotEmpty) {
                final nodeName = node.id == _ownerId
                    ? (_ownerName ?? AppLocalizations.of(context).me)
                    : bdayMap[node.id]?.name ?? '';
                final partnerName = node.partnerId != null ? (bdayMap[node.partnerId]?.name ?? '') : '';
                matches = nodeName.toLowerCase().contains(_searchQuery) ||
                    partnerName.toLowerCase().contains(_searchQuery);
              }

              return Positioned(
                left: left,
                top: top,
                width: node.width,
                child: Center(child: GestureDetector(
                  onPanStart: _isLocked ? null : (_) {
                    // Save current position for undo before dragging
                    final prev = _dragOffsets[node.id];
                    _dragUndoStack.add(MapEntry(node.id, prev));
                  },
                  onPanUpdate: _isLocked ? null : (details) {
                    final scale = _transformController.value.getMaxScaleOnAxis();
                    final currentOff = _dragOffsets[node.id] ?? Offset.zero;
                    final newOff = currentOff + details.delta / scale;
                    // Clamp so nodes can't be dragged too far away
                    const maxDrag = 800.0;
                    final clamped = Offset(
                      newOff.dx.clamp(-maxDrag, maxDrag),
                      newOff.dy.clamp(-maxDrag, maxDrag),
                    );
                    setState(() {
                      _dragOffsets[node.id] = clamped;
                    });
                  },
                  onPanEnd: _isLocked ? null : (_) {
                    _saveDragOffsets();
                  },
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: _searchQuery.isEmpty || matches ? 1.0 : 0.25,
                    child: _buildNodeWidget(node, bdayMap, provider),
                  ),
                )),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildNodeWidget(_LayoutNode node, Map<String, Birthday> bdayMap, BirthdayProvider provider) {
    if (node.id == _ownerId) {
      final partnerBday = node.partnerId != null ? bdayMap[node.partnerId] : null;
      return _buildOwnerNodeWidget(
        node.partnerId != null ? (partnerBday, node.partnerLabel) : null,
        provider,
      );
    }

    final bday = bdayMap[node.id];
    if (bday == null) return const SizedBox.shrink();

    final label = _getLabelForId(node.id);

    if (node.partnerId != null) {
      final partnerBday = bdayMap[node.partnerId!];
      // Use priority-aware label for partner too (e.g. show "Pappa" instead of "Man")
      final partnerLabel = _getLabelForId(node.partnerId!);
      final resolvedPartnerLabel = partnerLabel.isNotEmpty ? partnerLabel : (node.partnerLabel ?? '');
      return _buildPersonPairWidget(
        bday, partnerBday, resolvedPartnerLabel, label, provider,
      );
    }

    return _buildPersonNodeWidget(bday, label, provider);
  }

  // ── Owner node (with optional partner side by side) ────
  Widget _buildOwnerNodeWidget((Birthday?, String?)? partnerInfo, BirthdayProvider? provider) {
    final name = _ownerName ?? AppLocalizations.of(context).me;
    final hasBday = _ownerBirthday != null;

    final ownerCard = GestureDetector(
      onTap: _showEditProfileDialog,
      child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Builder(builder: (_) {
              final hasOwnerImage = !kIsWeb &&
                  _ownerImage != null &&
                  _ownerImage!.isNotEmpty &&
                  File(_ownerImage!).existsSync();
              return Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: hasOwnerImage ? null : AppTheme.auroraGradient,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                  image: hasOwnerImage
                      ? DecorationImage(
                          image: FileImage(File(_ownerImage!)),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: hasOwnerImage
                    ? null
                    : Center(
                        child: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : 'J',
                          style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                      ),
              );
            }),
            const SizedBox(height: 6),
            Text(
              name.split(' ').first,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            if (hasBday)
              Text(
                '$_ownerAge \u00e5r',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
            const SizedBox(height: 3),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('JAG', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 1)),
            ),
          ],
        ),
    );

    if (partnerInfo == null || partnerInfo.$1 == null) {
      return Center(child: ownerCard);
    }

    final partner = partnerInfo.$1!;
    final partnerLabel = partnerInfo.$2 ?? 'Partner';
    final partnerColor = AppTheme.getAvatarColor(partner.avatarColor, partner.name);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE91E63).withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ownerCard,
          Padding(
            padding: const EdgeInsets.only(left: 6, right: 6, top: 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('\u2764\ufe0f', style: TextStyle(fontSize: 18)),
                const SizedBox(height: 2),
                Text(
                  partnerLabel,
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade600, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => BirthdayDetailScreen(birthdayId: partner.id),
            )),
            onLongPress: provider != null ? () => _showNodeOptions(partner, provider) : null,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Builder(builder: (_) {
                    final hasPartnerImage = !kIsWeb &&
                        partner.imagePath != null &&
                        partner.imagePath!.isNotEmpty &&
                        File(partner.imagePath!).existsSync();
                    return Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: hasPartnerImage ? null : partnerColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: partnerColor.withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                        image: hasPartnerImage
                            ? DecorationImage(
                                image: FileImage(File(partner.imagePath!)),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: hasPartnerImage
                          ? null
                          : Center(
                              child: Text(
                                partner.name.isNotEmpty ? partner.name[0].toUpperCase() : '?',
                                style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                              ),
                            ),
                    );
                  }),
                const SizedBox(height: 6),
                Text(
                  partner.name.split(' ').first,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
                Text(
                  '${partner.age} \u00e5r',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Person pair widget (person + partner side by side) ──
  Widget _buildPersonPairWidget(Birthday person, Birthday? partner, String partnerLabel, String personLabel, BirthdayProvider provider) {
    final color = AppTheme.getAvatarColor(person.avatarColor, person.name);
    final relColor = _getRelColor(person.relationType);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: relColor.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => BirthdayDetailScreen(birthdayId: person.id),
            )),
            onLongPress: () => _showNodeOptions(person, provider),
            child: _buildMiniPersonAvatar(person.name, '${person.age} \u00e5r', color, imagePath: person.imagePath, label: personLabel, labelColor: relColor),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: const Text('\u2764\ufe0f', style: TextStyle(fontSize: 14)),
          ),
          if (partner != null)
            GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => BirthdayDetailScreen(birthdayId: partner.id),
              )),
              onLongPress: () => _showNodeOptions(partner, provider),
              child: _buildMiniPersonAvatar(
                partner.name,
                '${partner.age} \u00e5r',
                AppTheme.getAvatarColor(partner.avatarColor, partner.name),
                imagePath: partner.imagePath,
                label: partnerLabel,
                labelColor: Colors.grey.shade500,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMiniPersonAvatar(String name, String subtitle, Color color, {String? imagePath, String? label, Color? labelColor}) {
    final imgPath = imagePath;
    final hasImage = !kIsWeb &&
        imgPath != null &&
        imgPath.isNotEmpty &&
        File(imgPath).existsSync();
    return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (label != null && label.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(bottom: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: (labelColor ?? Colors.grey.shade600).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: labelColor ?? Colors.grey.shade600)),
            ),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: hasImage ? null : color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(color: color.withValues(alpha: 0.25), blurRadius: 6, offset: const Offset(0, 2)),
              ],
              image: hasImage
                  ? DecorationImage(
                      image: FileImage(File(imgPath)),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: hasImage
                ? null
                : Center(
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
          ),
          const SizedBox(height: 4),
          Text(
            name.split(' ').first,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          Text(subtitle, style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
        ],
    );
  }

  // ── Single person node widget ──────────────────────────
  Widget _buildPersonNodeWidget(Birthday person, String label, BirthdayProvider provider) {
    final color = AppTheme.getAvatarColor(person.avatarColor, person.name);
    final relColor = _getRelColor(person.relationType);
    final daysUntil = person.daysUntilBirthday;
    final isToday = person.isBirthdayToday;
    final isSoon = daysUntil <= 7 && daysUntil > 0;

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(
        builder: (_) => BirthdayDetailScreen(birthdayId: person.id),
      )),
      onLongPress: () => _showNodeOptions(person, provider),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: relColor.withValues(alpha: 0.25), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (label.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: relColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  label,
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: relColor),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            Stack(
              clipBehavior: Clip.none,
              children: [
                Builder(builder: (_) {
                  final hasImage = !kIsWeb &&
                      person.imagePath != null &&
                      person.imagePath!.isNotEmpty &&
                      File(person.imagePath!).existsSync();
                  return Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: hasImage ? null : color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isToday ? const Color(0xFFFBBF24) : relColor.withValues(alpha: 0.4),
                        width: isToday ? 3 : 2,
                      ),
                      boxShadow: [
                        BoxShadow(color: color.withValues(alpha: 0.2), blurRadius: 6, offset: const Offset(0, 2)),
                      ],
                      image: hasImage
                          ? DecorationImage(
                              image: FileImage(File(person.imagePath!)),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: hasImage
                        ? null
                        : Center(
                            child: Text(
                              person.name.isNotEmpty ? person.name[0].toUpperCase() : '?',
                              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                          ),
                  );
                }),
                if (isToday || isSoon)
                  Positioned(
                    right: -4, top: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: isToday ? const Color(0xFFFBBF24) : AppTheme.secondaryColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: Text(
                        isToday ? '\ud83c\udf82' : '${daysUntil}d',
                        style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              person.name.split(' ').first,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isToday ? const Color(0xFFF97316) : null,
              ),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            Text(
              '${person.age} \u00e5r',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }

  // Labels that should always take priority over partner/spouse labels
  static const _priorityLabels = {
    'Mamma', 'Pappa', 'Mor', 'Far', 'Mormor', 'Morfar', 'Farmor', 'Farfar',
    'Syster', 'Bror', 'Son', 'Dotter', 'Barnbarn',
    'Faster', 'Moster', 'Farbror', 'Morbror',
    'Svärmor', 'Svärfar', 'Svärdotter', 'Svärson',
    'Kusin', 'Niece', 'Nephew', 'Halvbror', 'Halvsyster',
    'Styvmamma', 'Styvpappa', 'Styvbror', 'Styvsyster', 'Styvbarn',
    // English variants
    'Mom', 'Dad', 'Mother', 'Father', 'Grandmother', 'Grandfather',
    'Sister', 'Brother',
  };

  String _getLabelForId(String id) {
    // Collect ALL non-partner links where this person is the child
    final childLinks = _links.where((l) => l.childId == id && !l.isPartner).toList();
    // Also collect partner links where this person is the child (i.e. the partner side)
    final allLinks = _links.where((l) => l.childId == id || l.parentId == id).toList();

    // Build full label list: child-links first, then any other links
    final allLabels = [
      ...childLinks.map((l) => l.label),
      ...allLinks.where((l) => !childLinks.contains(l)).map((l) => l.label),
    ];

    if (allLabels.isEmpty) return '';

    // Prefer priority (family) labels over partner/spouse labels
    final priority = allLabels.where((label) => _priorityLabels.contains(label)).toList();
    if (priority.isNotEmpty) return priority.first;

    return allLabels.first;
  }

  Color _getRelColor(RelationType type) {
    switch (type) {
      case RelationType.closeFamily: return AppTheme.secondaryColor;
      case RelationType.friend: return AppTheme.primaryColor;
      case RelationType.colleague: return AppTheme.accentMintStrong;
    }
  }

  // ── Node long-press options ────────────────────────────
  void _showNodeOptions(Birthday person, BirthdayProvider provider) {
    final personLinks = _links.where((l) => l.childId == person.id || l.parentId == person.id).toList();

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
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            Text(person.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  _showAddLinkDialogInner(provider, preselectedParentId: person.id);
                },
                icon: const Icon(Icons.add, size: 18),
                label: Text('${AppLocalizations.of(context).connectRelation} ${person.name.split(' ').first}'),
              ),
            ),
            if (personLinks.isNotEmpty) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(AppLocalizations.of(context).relations, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey.shade600)),
              ),
            ],
            const SizedBox(height: 4),
            ...personLinks.map((link) {
              final fromName = link.parentId == _ownerId
                  ? (_ownerName ?? AppLocalizations.of(context).me)
                  : provider.allBirthdays.where((b) => b.id == link.parentId).firstOrNull?.name ?? '?';
              final toName = link.childId == _ownerId
                  ? (_ownerName ?? AppLocalizations.of(context).me)
                  : provider.allBirthdays.where((b) => b.id == link.childId).firstOrNull?.name ?? '?';
              return ListTile(
                dense: true,
                leading: Icon(link.isPartner ? Icons.favorite : Icons.link, size: 18, color: link.isPartner ? const Color(0xFFE91E63) : null),
                title: Text('$fromName \u2192 $toName'),
                subtitle: Text(link.label),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit_outlined, color: Colors.grey.shade600, size: 18),
                      tooltip: AppLocalizations.of(context).editLabel,
                      onPressed: () {
                        Navigator.pop(ctx);
                        _showEditLinkDialog(link, provider);
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                      tooltip: AppLocalizations.of(context).deleteLink,
                      onPressed: () {
                        setState(() {
                          _links.removeWhere((l) =>
                              l.parentId == link.parentId &&
                              l.childId == link.childId &&
                              l.label == link.label);
                        });
                        _saveLinks();
                        Navigator.pop(ctx);
                      },
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ── Edit link dialog ──────────────────────────────────
  void _showEditLinkDialog(_TreeLink link, BirthdayProvider provider) {
    final labelController = TextEditingController(text: link.label);
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

    final fromName = link.parentId == _ownerId
        ? (_ownerName ?? l.me)
        : provider.allBirthdays.where((b) => b.id == link.parentId).firstOrNull?.name ?? '?';
    final toName = link.childId == _ownerId
        ? (_ownerName ?? l.me)
        : provider.allBirthdays.where((b) => b.id == link.childId).firstOrNull?.name ?? '?';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 16),
              Center(child: Text(l.editLabel, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
              const SizedBox(height: 8),
              Center(child: Text('$fromName \u2192 $toName', style: TextStyle(fontSize: 14, color: Colors.grey.shade600))),
              const SizedBox(height: 20),
              Text(l.relations, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
              const SizedBox(height: 10),
              Builder(builder: (_) {
                final visibleLabels = _showAllLabelsEdit ? relationLabels : relationLabels.take(10).toList();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8, runSpacing: 8,
                      children: visibleLabels.map((label) {
                        final selected = labelController.text == label;
                        return GestureDetector(
                          onTap: () => setModalState(() => labelController.text = label),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: selected ? AppTheme.primaryColor.withValues(alpha: 0.12) : Colors.grey.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: selected ? AppTheme.primaryColor : Colors.grey.withValues(alpha: 0.2)),
                            ),
                            child: Text(label, style: TextStyle(fontSize: 13, fontWeight: selected ? FontWeight.w700 : FontWeight.w500, color: selected ? AppTheme.primaryColor : null)),
                          ),
                        );
                      }).toList(),
                    ),
                    if (relationLabels.length > 10)
                      TextButton(
                        onPressed: () => setModalState(() => _showAllLabelsEdit = !_showAllLabelsEdit),
                        child: Text(_showAllLabelsEdit ? l.get('show_less') : l.get('show_more')),
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
                  isDense: true,
                ),
                onChanged: (_) => setModalState(() {}),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: labelController.text.trim().isNotEmpty
                      ? () {
                          setState(() {
                            final idx = _links.indexWhere((l) =>
                                l.parentId == link.parentId &&
                                l.childId == link.childId &&
                                l.label == link.label);
                            if (idx >= 0) {
                              _links[idx] = _TreeLink(
                                parentId: link.parentId,
                                childId: link.childId,
                                label: labelController.text.trim(),
                              );
                            }
                          });
                          _saveLinks();
                          Navigator.pop(ctx);
                        }
                      : null,
                  child: Text(l.save),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  // ── Add link dialog ────────────────────────────────────
  void _showAddLinkDialogInner(BirthdayProvider provider, {String? preselectedParentId}) {
    final allBirthdays = provider.allBirthdays;
    if (allBirthdays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).addBirthdaysFirst)),
      );
      return;
    }

    final parentsInTree = <String>{_ownerId};
    for (final link in _links) {
      parentsInTree.add(link.parentId);
      parentsInTree.add(link.childId);
    }

    String selectedParentId = preselectedParentId ?? _ownerId;
    // Multi-select: childId -> label
    final selectedChildren = <String, String>{};
    final labelController = TextEditingController();
    final targetSearchController = TextEditingController();
    String? activeChildId; // which child we're currently setting label for

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
            final parentOptions = <_ParentOption>[
              _ParentOption(id: _ownerId, name: _ownerName ?? l.me, isOwner: true, imagePath: _ownerImage),
            ];
            for (final id in parentsInTree) {
              if (id == _ownerId) continue;
              final b = allBirthdays.where((b) => b.id == id).firstOrNull;
              if (b != null) parentOptions.add(_ParentOption(id: b.id, name: b.name, imagePath: b.imagePath));
            }

            final existingChildIds = _links
                .where((lnk) => lnk.parentId == selectedParentId)
                .map((lnk) => lnk.childId)
                .toSet();
            // Include owner as a possible target (when parent is not owner)
            final targetOptions = <_ParentOption>[];
            if (selectedParentId != _ownerId && !existingChildIds.contains(_ownerId)) {
              targetOptions.add(_ParentOption(id: _ownerId, name: _ownerName ?? l.me, isOwner: true, imagePath: _ownerImage));
            }
            for (final b in allBirthdays) {
              if (b.id != selectedParentId && !existingChildIds.contains(b.id)) {
                targetOptions.add(_ParentOption(id: b.id, name: b.name, imagePath: b.imagePath));
              }
            }

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
                    Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
                    const SizedBox(height: 16),
                    Text(l.connectRelation, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),

                    Text(l.fromWho, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 80,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: parentOptions.length,
                        itemBuilder: (_, i) {
                          final p = parentOptions[i];
                          final selected = selectedParentId == p.id;
                          return GestureDetector(
                            onTap: () => setModalState(() {
                              selectedParentId = p.id;
                              selectedChildren.remove(p.id);
                              activeChildId = null;
                              labelController.clear();
                            }),
                            child: Container(
                              width: 70,
                              margin: const EdgeInsets.only(right: 10),
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: selected ? AppTheme.primaryColor.withValues(alpha: 0.08) : null,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: selected ? AppTheme.primaryColor : Colors.grey.withValues(alpha: 0.15),
                                  width: selected ? 2 : 1,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Builder(builder: (_) {
                                    final hasImg = !kIsWeb && p.imagePath != null && p.imagePath!.isNotEmpty && File(p.imagePath!).existsSync();
                                    return CircleAvatar(
                                      radius: 18,
                                      backgroundColor: p.isOwner ? AppTheme.primaryColor : AppTheme.getAvatarColor(null, p.name),
                                      backgroundImage: hasImg ? FileImage(File(p.imagePath!)) : null,
                                      child: hasImg ? null : Text(
                                        p.name.isNotEmpty ? p.name[0].toUpperCase() : '?',
                                        style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                                      ),
                                    );
                                  }),
                                  const SizedBox(height: 4),
                                  Text(
                                    p.isOwner ? l.me : p.name.split(' ').first,
                                    style: TextStyle(fontSize: 10, fontWeight: selected ? FontWeight.w700 : FontWeight.w500),
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(child: Text(l.whoToConnect, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey.shade700))),
                        TextButton.icon(
                          onPressed: () => _showContactPicker(ctx, provider, setModalState, (id) {
                            selectedChildren[id] = '';
                            activeChildId = id;
                          }),
                          icon: const Icon(Icons.contacts_outlined, size: 18),
                          label: Text(l.fromContacts, style: const TextStyle(fontSize: 12)),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (targetOptions.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(l.allAlreadyConnected, style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                      )
                    else ...[
                      // Search field
                      TextField(
                        controller: targetSearchController,
                        onChanged: (_) => setModalState(() {}),
                        decoration: InputDecoration(
                          hintText: 'Sök person...',
                          prefixIcon: const Icon(Icons.search, size: 20),
                          isDense: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Builder(builder: (_) {
                        // Compute which first names are duplicated (for disambiguation)
                        final firstNames = targetOptions.map((t) => t.name.split(' ').first.toLowerCase()).toList();
                        final duplicateFirstNames = <String>{};
                        for (int i = 0; i < firstNames.length; i++) {
                          for (int j = i + 1; j < firstNames.length; j++) {
                            if (firstNames[i] == firstNames[j]) {
                              duplicateFirstNames.add(firstNames[i]);
                            }
                          }
                        }

                        // Filter by search
                        final query = targetSearchController.text.toLowerCase().trim();
                        final filtered = query.isEmpty
                            ? targetOptions
                            : targetOptions.where((t) => t.name.toLowerCase().contains(query)).toList();

                        if (filtered.isEmpty) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text('Ingen person matchar "$query"', style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                          );
                        }

                        return Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: filtered.map((t) {
                            final isSelected = selectedChildren.containsKey(t.id);
                            final isActive = activeChildId == t.id;
                            final avatarColor = t.isOwner ? AppTheme.primaryColor : AppTheme.getAvatarColor(null, t.name);
                            final firstName = t.isOwner ? l.me : t.name.split(' ').first;
                            // Add last name initial if first name is duplicated
                            final parts = t.name.split(' ');
                            final displayName = (!t.isOwner && duplicateFirstNames.contains(firstName.toLowerCase()) && parts.length > 1)
                                ? '$firstName ${parts.last[0].toUpperCase()}.'
                                : firstName;

                            return GestureDetector(
                              onTap: () => setModalState(() {
                                if (isSelected) {
                                  selectedChildren.remove(t.id);
                                  if (activeChildId == t.id) {
                                    activeChildId = selectedChildren.isNotEmpty ? selectedChildren.keys.last : null;
                                    labelController.text = activeChildId != null ? (selectedChildren[activeChildId] ?? '') : '';
                                  }
                                } else {
                                  selectedChildren[t.id] = '';
                                  activeChildId = t.id;
                                  labelController.text = '';
                                }
                              }),
                              child: Container(
                                width: 70,
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: isActive
                                      ? AppTheme.primaryColor.withValues(alpha: 0.12)
                                      : isSelected
                                          ? AppTheme.secondaryColor.withValues(alpha: 0.08)
                                          : null,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isActive
                                        ? AppTheme.primaryColor
                                        : isSelected
                                            ? AppTheme.secondaryColor
                                            : Colors.grey.withValues(alpha: 0.15),
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Stack(
                                      children: [
                                        Builder(builder: (_) {
                                          final hasImg = !kIsWeb && t.imagePath != null && t.imagePath!.isNotEmpty && File(t.imagePath!).existsSync();
                                          return CircleAvatar(
                                            radius: 18,
                                            backgroundColor: avatarColor,
                                            backgroundImage: hasImg ? FileImage(File(t.imagePath!)) : null,
                                            child: hasImg ? null : Text(
                                              t.name.isNotEmpty ? t.name[0].toUpperCase() : '?',
                                              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                                            ),
                                          );
                                        }),
                                        if (isSelected)
                                          Positioned(
                                            right: 0, bottom: 0,
                                            child: Container(
                                              width: 14, height: 14,
                                              decoration: BoxDecoration(
                                                color: selectedChildren[t.id]!.isNotEmpty ? Colors.green : Colors.orange,
                                                shape: BoxShape.circle,
                                                border: Border.all(color: Colors.white, width: 1.5),
                                              ),
                                              child: Icon(
                                                selectedChildren[t.id]!.isNotEmpty ? Icons.check : Icons.edit,
                                                size: 8, color: Colors.white,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      displayName,
                                      style: TextStyle(fontSize: 10, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500),
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        );
                      }),
                    ],

                    // Show selected children chips
                    if (selectedChildren.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 6, runSpacing: 6,
                        children: selectedChildren.entries.map((e) {
                          final name = targetOptions.where((t) => t.id == e.key).firstOrNull?.name ?? '?';
                          final isActive = activeChildId == e.key;
                          return GestureDetector(
                            onTap: () => setModalState(() {
                              activeChildId = e.key;
                              labelController.text = e.value;
                            }),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: isActive ? AppTheme.primaryColor.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: isActive ? AppTheme.primaryColor : Colors.grey.withValues(alpha: 0.2)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '${name.split(' ').first}${e.value.isNotEmpty ? ' \u2022 ${e.value}' : ''}',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isActive ? AppTheme.primaryColor : null),
                                  ),
                                  const SizedBox(width: 4),
                                  GestureDetector(
                                    onTap: () => setModalState(() {
                                      selectedChildren.remove(e.key);
                                      if (activeChildId == e.key) {
                                        activeChildId = selectedChildren.isNotEmpty ? selectedChildren.keys.last : null;
                                        labelController.text = activeChildId != null ? (selectedChildren[activeChildId] ?? '') : '';
                                      }
                                    }),
                                    child: Icon(Icons.close, size: 14, color: Colors.grey.shade500),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                    const SizedBox(height: 16),

                    if (activeChildId != null) ...[
                      Text(
                        l.get('relation_for').replaceAll('{name}', targetOptions.where((t) => t.id == activeChildId).firstOrNull?.name.split(' ').first ?? '?'),
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
                      ),
                      const SizedBox(height: 10),
                      Builder(builder: (_) {
                        final visibleLabels = _showAllLabelsAdd ? relationLabels : relationLabels.take(10).toList();
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: 8, runSpacing: 8,
                              children: visibleLabels.map((label) {
                                final selected = labelController.text == label;
                                return GestureDetector(
                                  onTap: () => setModalState(() {
                                    labelController.text = label;
                                    if (activeChildId != null) {
                                      selectedChildren[activeChildId!] = label;
                                    }
                                  }),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: selected ? AppTheme.primaryColor.withValues(alpha: 0.12) : Colors.grey.withValues(alpha: 0.06),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: selected ? AppTheme.primaryColor : Colors.grey.withValues(alpha: 0.2)),
                                    ),
                                    child: Text(label, style: TextStyle(fontSize: 13, fontWeight: selected ? FontWeight.w700 : FontWeight.w500, color: selected ? AppTheme.primaryColor : null)),
                                  ),
                                );
                              }).toList(),
                            ),
                            if (relationLabels.length > 10)
                              TextButton(
                                onPressed: () => setModalState(() => _showAllLabelsAdd = !_showAllLabelsAdd),
                                child: Text(_showAllLabelsAdd ? l.get('show_less') : l.get('show_more')),
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
                          isDense: true,
                        ),
                        onChanged: (v) => setModalState(() {
                          if (activeChildId != null) {
                            selectedChildren[activeChildId!] = v.trim();
                          }
                        }),
                      ),
                    ],
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: selectedChildren.isNotEmpty && selectedChildren.values.every((v) => v.isNotEmpty)
                            ? () {
                                setState(() {
                                  for (final entry in selectedChildren.entries) {
                                    _links.add(_TreeLink(
                                      parentId: selectedParentId,
                                      childId: entry.key,
                                      label: entry.value,
                                    ));
                                  }
                                });
                                _saveLinks();
                                Navigator.pop(ctx);
                              }
                            : null,
                        child: Text(selectedChildren.length > 1
                            ? l.get('add_links').replaceAll('{count}', '${selectedChildren.length}')
                            : l.addLink),
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

  // ── Contact picker ─────────────────────────────────────
  Future<void> _showContactPicker(
    BuildContext sheetCtx,
    BirthdayProvider provider,
    void Function(void Function()) setModalState,
    void Function(String id) onSelected,
  ) async {
    final contactService = ContactService();
    final contacts = await contactService.getPickableContacts();

    if (!mounted) return;

    if (contacts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).importNone)),
      );
      return;
    }

    final searchController = TextEditingController();
    final messenger = ScaffoldMessenger.of(context);

    if (!sheetCtx.mounted) return;
    await showModalBottomSheet(
      context: sheetCtx,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (pickerCtx) {
        return StatefulBuilder(
          builder: (pickerCtx, setPickerState) {
            final query = searchController.text.toLowerCase();
            final filtered = query.isEmpty
                ? contacts
                : contacts.where((c) => c.displayName.toLowerCase().contains(query)).toList();

            return DraggableScrollableSheet(
              initialChildSize: 0.7,
              minChildSize: 0.4,
              maxChildSize: 0.9,
              expand: false,
              builder: (_, scrollController) => Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Column(
                      children: [
                        Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
                        const SizedBox(height: 12),
                        Text(AppLocalizations.of(context).fromContacts, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        TextField(
                          controller: searchController,
                          decoration: InputDecoration(
                            hintText: AppLocalizations.of(context).searchName,
                            prefixIcon: const Icon(Icons.search),
                            isDense: true,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onChanged: (_) => setPickerState(() {}),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                  Expanded(
                    child: filtered.isEmpty
                        ? Center(child: Text(AppLocalizations.of(context).get('no_contacts_match'), style: TextStyle(color: Colors.grey.shade500)))
                        : ListView.builder(
                            controller: scrollController,
                            itemCount: filtered.length,
                            itemBuilder: (_, i) {
                              final c = filtered[i];
                              final hasBirthday = c.birthday != null;
                              final subtitle = <String>[];
                              if (hasBirthday) subtitle.add(DateFormat('d MMM yyyy', 'sv').format(c.birthday!));
                              if (c.phone != null) subtitle.add(c.phone!);
                              if (c.email != null) subtitle.add(c.email!);

                              final hasPhoto = c.photoBytes != null && c.photoBytes!.isNotEmpty;
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: AppTheme.getAvatarColor(null, c.displayName),
                                  backgroundImage: hasPhoto ? MemoryImage(c.photoBytes!) : null,
                                  child: hasPhoto ? null : Text(
                                    c.displayName.isNotEmpty ? c.displayName[0].toUpperCase() : '?',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                title: Text(c.displayName, style: const TextStyle(fontWeight: FontWeight.w600)),
                                subtitle: subtitle.isNotEmpty
                                    ? Text(subtitle.join(' \u2022 '), style: TextStyle(fontSize: 12, color: Colors.grey.shade600), maxLines: 1, overflow: TextOverflow.ellipsis)
                                    : null,
                                trailing: hasBirthday
                                    ? Icon(Icons.cake, size: 18, color: AppTheme.primaryColor.withValues(alpha: 0.6))
                                    : null,
                                onTap: () async {
                                  // Check if this contact already exists as a birthday
                                  final existing = provider.allBirthdays.where(
                                    (b) => b.name.toLowerCase() == c.displayName.toLowerCase(),
                                  ).firstOrNull;

                                  final String selectedId;
                                  if (existing != null) {
                                    selectedId = existing.id;
                                  } else {
                                    final birthday = await contactService.contactToBirthday(c);
                                    await provider.addBirthday(birthday);
                                    selectedId = birthday.id;
                                  }
                                  if (!pickerCtx.mounted) return;
                                  Navigator.pop(pickerCtx);
                                  setModalState(() {
                                    onSelected(selectedId);
                                  });
                                  final l = AppLocalizations.of(context);
                                  messenger.showSnackBar(
                                    SnackBar(content: Text(existing != null
                                        ? '${c.displayName} ${l.get('already_exists_linked')}'
                                        : '${c.displayName} ${l.get('added')}')),
                                  );
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ── Setup screen ───────────────────────────────────────
  Widget _buildSetup() {
    DateTime selectedDate = DateTime(2000, 1, 1);
    final setupNameController = TextEditingController();
    String? setupImagePath;

    return StatefulBuilder(
      builder: (context, setSetupState) => Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () {
                  _showImageSourceSheet((path) {
                    setSetupState(() => setupImagePath = path);
                  });
                },
                child: Stack(
                  children: [
                    Builder(builder: (_) {
                      final hasImg = setupImagePath != null && File(setupImagePath!).existsSync();
                      return Container(
                        width: 100, height: 100,
                        decoration: BoxDecoration(
                          gradient: hasImg ? null : AppTheme.auroraGradient,
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: AppTheme.primaryColor.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8))],
                          image: hasImg
                              ? DecorationImage(image: FileImage(File(setupImagePath!)), fit: BoxFit.cover)
                              : null,
                        ),
                        child: hasImg ? null : const Icon(Icons.person, size: 48, color: Colors.white),
                      );
                    }),
                    Positioned(
                      bottom: 0, right: 0,
                      child: Container(
                        width: 32, height: 32,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(AppLocalizations.of(context).setupProfile, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text(AppLocalizations.of(context).startBuilding, style: TextStyle(fontSize: 15, color: Colors.grey.shade500), textAlign: TextAlign.center),
              const SizedBox(height: 32),
              TextField(
                controller: setupNameController,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(labelText: AppLocalizations.of(context).yourName, prefixIcon: const Icon(Icons.person_outline)),
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(context: context, initialDate: selectedDate, firstDate: DateTime(1900), lastDate: DateTime.now(), locale: Locale(AppLocalizations.of(context).locale.languageCode));
                  if (picked != null) setSetupState(() => selectedDate = picked);
                },
                borderRadius: BorderRadius.circular(12),
                child: InputDecorator(
                  decoration: InputDecoration(labelText: AppLocalizations.of(context).birthdate, prefixIcon: const Icon(Icons.cake_outlined)),
                  child: Text(DateFormat.yMMMMd(AppLocalizations.of(context).locale.languageCode).format(selectedDate), style: const TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    final name = setupNameController.text.trim();
                    if (name.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).yourName)));
                      return;
                    }
                    _saveProfile(name, selectedDate, imagePath: setupImagePath);
                  },
                  icon: const Icon(Icons.check),
                  label: Text(AppLocalizations.of(context).startBuilding),
                  style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Image source picker ────────────────────────────────
  void _showImageSourceSheet(void Function(String path) onPicked) {
    final l = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: Text(l.takePhoto),
              onTap: () async {
                Navigator.pop(ctx);
                final path = await _pickOwnerImage(ImageSource.camera);
                if (path != null) onPicked(path);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(l.chooseFromGallery),
              onTap: () async {
                Navigator.pop(ctx);
                final path = await _pickOwnerImage(ImageSource.gallery);
                if (path != null) onPicked(path);
              },
            ),
          ],
        ),
      ),
    );
  }

  // ── Edit profile dialog ────────────────────────────────
  void _showEditProfileDialog() {
    _nameController.text = _ownerName ?? '';
    DateTime selectedDate = _ownerBirthday ?? DateTime(2000, 1, 1);
    String? editImagePath = _ownerImage;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 16),
              Text(AppLocalizations.of(context).myProfile, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () {
                  _showImageSourceSheet((path) {
                    setSheetState(() => editImagePath = path);
                  });
                },
                child: Stack(
                  children: [
                    Builder(builder: (_) {
                      final hasImg = !kIsWeb &&
                          editImagePath != null &&
                          editImagePath!.isNotEmpty &&
                          File(editImagePath!).existsSync();
                      return Container(
                        width: 80, height: 80,
                        decoration: BoxDecoration(
                          gradient: hasImg ? null : AppTheme.auroraGradient,
                          shape: BoxShape.circle,
                          image: hasImg
                              ? DecorationImage(image: FileImage(File(editImagePath!)), fit: BoxFit.cover)
                              : null,
                        ),
                        child: hasImg
                            ? null
                            : Center(
                                child: Text(
                                  (_ownerName ?? '').isNotEmpty ? _ownerName![0].toUpperCase() : '?',
                                  style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                                ),
                              ),
                      );
                    }),
                    Positioned(
                      bottom: 0, right: 0,
                      child: Container(
                        width: 28, height: 28,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.camera_alt, size: 14, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextField(controller: _nameController, textCapitalization: TextCapitalization.words, decoration: InputDecoration(labelText: AppLocalizations.of(context).name, prefixIcon: const Icon(Icons.person_outline))),
              const SizedBox(height: 12),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(context: context, initialDate: selectedDate, firstDate: DateTime(1900), lastDate: DateTime.now(), locale: Locale(AppLocalizations.of(context).locale.languageCode));
                  if (picked != null) setSheetState(() => selectedDate = picked);
                },
                borderRadius: BorderRadius.circular(12),
                child: InputDecorator(
                  decoration: InputDecoration(labelText: AppLocalizations.of(context).birthdate, prefixIcon: const Icon(Icons.cake_outlined)),
                  child: Text(DateFormat.yMMMMd(AppLocalizations.of(context).locale.languageCode).format(selectedDate), style: const TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    final name = _nameController.text.trim();
                    if (name.isNotEmpty) _saveProfile(name, selectedDate, imagePath: editImagePath);
                    Navigator.pop(ctx);
                  },
                  child: Text(AppLocalizations.of(context).save),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Custom painter for tree connection lines ─────────────
class _TreeLinePainter extends CustomPainter {
  final List<(Offset, Offset, _ChildOwner, RelationType?)> edges;
  final Offset offset;

  _TreeLinePainter({required this.edges, required this.offset});

  // Colors per relation type
  static const _familyColor  = Color(0xFFEC4899); // pink  – close family
  static const _friendColor  = Color(0xFF6366F1); // indigo – friend
  static const _colleagueColor = Color(0xFF34D399); // mint – colleague
  static const _defaultColor = Color(0xFFCBD5E1); // grey  – unknown
  // Partner-side tints (slightly lighter)
  static const _familyRight  = Color(0xFFF9A8D4);
  static const _friendRight  = Color(0xFFA5B4FC);
  static const _colleagueRight = Color(0xFF6EE7B7);

  @override
  void paint(Canvas canvas, Size size) {
    for (final (from, to, owner, relType) in edges) {
      final Color lineColor;
      // Base color on relation type, tinted lighter for partner-side children
      final Color baseColor = switch (relType) {
        RelationType.closeFamily => owner == _ChildOwner.right ? _familyRight : _familyColor,
        RelationType.friend      => owner == _ChildOwner.right ? _friendRight : _friendColor,
        RelationType.colleague   => owner == _ChildOwner.right ? _colleagueRight : _colleagueColor,
        null                     => _defaultColor,
      };
      lineColor = baseColor;

      final paint = Paint()
        ..color = lineColor
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      final start = from + offset;
      final end = to + offset;
      final midY = (start.dy + end.dy) / 2;

      final path = Path()
        ..moveTo(start.dx, start.dy)
        ..lineTo(start.dx, midY)
        ..lineTo(end.dx, midY)
        ..lineTo(end.dx, end.dy);

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _TreeLinePainter oldDelegate) => true;
}

// ── Helper class ─────────────────────────────────────────
class _ParentOption {
  final String id;
  final String name;
  final bool isOwner;
  final String? imagePath;
  _ParentOption({required this.id, required this.name, this.isOwner = false, this.imagePath});
}
