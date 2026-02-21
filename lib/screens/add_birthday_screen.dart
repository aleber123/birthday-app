import 'dart:io';
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
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/contact_service.dart';
import '../services/facebook_analytics_service.dart';
import '../services/premium_service.dart';
import '../l10n/app_localizations.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';
import 'paywall_screen.dart';

class AddBirthdayScreen extends StatefulWidget {
  final Birthday? editBirthday;

  const AddBirthdayScreen({super.key, this.editBirthday});

  @override
  State<AddBirthdayScreen> createState() => _AddBirthdayScreenState();
}

class _AddBirthdayScreenState extends State<AddBirthdayScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime _selectedDate = DateTime(2000, 1, 1);
  bool _dateHasBeenSet = false;
  List<int> _selectedReminders = [0, 1, 7];
  RelationType _selectedRelationType = RelationType.friend;
  String? _imagePath;
  bool _isImporting = false;

  bool get _isEditing => widget.editBirthday != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final b = widget.editBirthday!;
      _nameController.text = b.name;
      _phoneController.text = b.phone ?? '';
      _emailController.text = b.email ?? '';
      _addressController.text = b.address ?? '';
      _notesController.text = b.notes ?? '';
      _selectedDate = b.hasBirthday ? b.date : DateTime(2000, 1, 1);
      _dateHasBeenSet = b.hasBirthday;
      _selectedReminders = List.from(b.reminderDaysBefore);
      _selectedRelationType = b.relationType;
      _imagePath = b.imagePath;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? AppLocalizations.of(context).edit : AppLocalizations.of(context).newBirthday),
        actions: [
          if (!_isEditing)
            TextButton.icon(
              onPressed: _isImporting ? null : _importFromContacts,
              icon: _isImporting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.contacts),
              label: Text(AppLocalizations.of(context).importContacts),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildImagePicker(),
            const SizedBox(height: 16),
            _buildNameField(),
            const SizedBox(height: 16),
            _buildDatePicker(),
            const SizedBox(height: 16),
            _buildRelationTypeSelector(),
            const SizedBox(height: 16),
            _buildPhoneField(),
            const SizedBox(height: 16),
            _buildEmailField(),
            const SizedBox(height: 16),
            _buildAddressField(),
            const SizedBox(height: 16),
            _buildNotesField(),
            const SizedBox(height: 24),
            _buildReminderSection(),
            const SizedBox(height: 32),
            _buildSaveButton(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    final hasImage = !kIsWeb && _imagePath != null && _imagePath!.isNotEmpty && File(_imagePath!).existsSync();

    return Center(
      child: GestureDetector(
        onTap: _showImageSourceSheet,
        child: Stack(
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryColor.withValues(alpha: 0.08),
                border: Border.all(
                  color: AppTheme.primaryColor.withValues(alpha: 0.2),
                  width: 2,
                ),
                image: hasImage
                    ? DecorationImage(
                        image: FileImage(File(_imagePath!)),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: hasImage
                  ? null
                  : Icon(
                      Icons.person_add_alt_1_rounded,
                      size: 36,
                      color: AppTheme.primaryColor,
                    ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withValues(alpha: 0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(Icons.camera_alt_rounded, size: 16, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
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
                AppLocalizations.of(context).choosePhoto,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.camera_alt_rounded, color: AppTheme.primaryColor),
                ),
                title: Text(AppLocalizations.of(context).takePhoto, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(AppLocalizations.of(context).get('use_camera')),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppTheme.accentSky.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.photo_library_rounded, color: AppTheme.accentSky),
                ),
                title: Text(AppLocalizations.of(context).chooseFromGallery, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(AppLocalizations.of(context).get('choose_existing_photo')),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                },
              ),
              if (_imagePath != null) ...[
                ListTile(
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                  ),
                  title: Text(AppLocalizations.of(context).removePhoto, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.red)),
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() => _imagePath = null);
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      if (picked == null) return;

      // Save to app's documents directory for persistence
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = 'avatar_${const Uuid().v4()}${p.extension(picked.path)}';
      final savedFile = await File(picked.path).copy('${appDir.path}/$fileName');

      setState(() => _imagePath = savedFile.path);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kunde inte välja bild: $e')),
        );
      }
    }
  }

  Widget _buildNameField() {
    return TextFormField(
      controller: _nameController,
      textCapitalization: TextCapitalization.words,
      decoration: InputDecoration(
        labelText: AppLocalizations.of(context).name,
        prefixIcon: const Icon(Icons.person_outline),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return AppLocalizations.of(context).name;
        }
        return null;
      },
    );
  }

  Widget _buildDatePicker() {
    final showWarning = _isEditing && !_dateHasBeenSet;
    return InkWell(
      onTap: _pickDate,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: AppLocalizations.of(context).birthdate,
          prefixIcon: Icon(
            Icons.calendar_today_outlined,
            color: showWarning ? Colors.orange.shade400 : null,
          ),
          enabledBorder: showWarning
              ? OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.orange.shade400, width: 1.5),
                )
              : null,
          helperText: showWarning ? 'Födelsedag saknas – lägg till ett datum' : null,
          helperStyle: showWarning ? TextStyle(color: Colors.orange.shade600) : null,
        ),
        child: Text(
          showWarning
              ? 'Välj datum...'
              : DateFormat.yMMMMd(AppLocalizations.of(context).locale.languageCode).format(_selectedDate),
          style: TextStyle(
            fontSize: 16,
            color: showWarning ? Colors.orange.shade400 : null,
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneField() {
    return TextFormField(
      controller: _phoneController,
      keyboardType: TextInputType.phone,
      decoration: InputDecoration(
        labelText: '${AppLocalizations.of(context).phone} (${AppLocalizations.of(context).get('optional')})',
        prefixIcon: const Icon(Icons.phone_outlined),
      ),
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      decoration: InputDecoration(
        labelText: '${AppLocalizations.of(context).email} (${AppLocalizations.of(context).get('optional')})',
        prefixIcon: const Icon(Icons.email_outlined),
      ),
    );
  }

  Widget _buildRelationTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context).get('relation'),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: RelationType.values.map((type) {
            final isSelected = _selectedRelationType == type;
            String label;
            String emoji;
            switch (type) {
              case RelationType.closeFamily:
                label = AppLocalizations.of(context).closeFamily;
                emoji = '\u2764\ufe0f';
                break;
              case RelationType.friend:
                label = AppLocalizations.of(context).friend;
                emoji = '\ud83d\ude0a';
                break;
              case RelationType.colleague:
                label = AppLocalizations.of(context).colleague;
                emoji = '\ud83d\udcbc';
                break;
            }
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: type != RelationType.colleague ? 8 : 0,
                ),
                child: GestureDetector(
                  onTap: () => setState(() => _selectedRelationType = type),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.primaryColor.withValues(alpha: 0.12)
                          : Theme.of(context).cardTheme.color ?? Colors.white.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.primaryColor
                            : Colors.grey.withValues(alpha: 0.2),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(emoji, style: const TextStyle(fontSize: 22)),
                        const SizedBox(height: 4),
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected ? AppTheme.primaryColor : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildAddressField() {
    return TextFormField(
      controller: _addressController,
      keyboardType: TextInputType.streetAddress,
      decoration: InputDecoration(
        labelText: '${AppLocalizations.of(context).get('address')} (${AppLocalizations.of(context).get('optional')})',
        prefixIcon: const Icon(Icons.location_on_outlined),
      ),
    );
  }

  Widget _buildNotesField() {
    return TextFormField(
      controller: _notesController,
      maxLines: 3,
      decoration: InputDecoration(
        labelText: '${AppLocalizations.of(context).notes} (${AppLocalizations.of(context).get('optional')})',
        prefixIcon: const Icon(Icons.note_outlined),
        alignLabelWithHint: true,
      ),
    );
  }

  Widget _buildReminderSection() {
    final premium = context.watch<PremiumService>();
    final freeOptions = AppConstants.freeReminderOptions;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              AppLocalizations.of(context).reminders,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            if (!premium.isPremium) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  AppLocalizations.of(context).requiresPremium,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.primaryColor),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _reminderChip(0, AppLocalizations.of(context).sameDay, freeOptions.contains(0) || premium.isPremium),
            _reminderChip(1, AppLocalizations.of(context).dayBefore, freeOptions.contains(1) || premium.isPremium),
            _reminderChip(3, AppLocalizations.of(context).get('days_before_3'), freeOptions.contains(3) || premium.isPremium),
            _reminderChip(7, AppLocalizations.of(context).weekBefore, freeOptions.contains(7) || premium.isPremium),
            _reminderChip(14, AppLocalizations.of(context).weeksBefore2, freeOptions.contains(14) || premium.isPremium),
            _reminderChip(30, AppLocalizations.of(context).monthBefore, freeOptions.contains(30) || premium.isPremium),
          ],
        ),
      ],
    );
  }

  Widget _reminderChip(int days, String label, bool unlocked) {
    final isSelected = _selectedReminders.contains(days);
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          if (!unlocked) ...[
            const SizedBox(width: 4),
            const Icon(Icons.lock, size: 14, color: Colors.grey),
          ],
        ],
      ),
      selected: isSelected && unlocked,
      onSelected: (selected) {
        if (!unlocked) {
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => const PaywallScreen(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 1),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
                  child: child,
                );
              },
              transitionDuration: const Duration(milliseconds: 400),
            ),
          );
          return;
        }
        setState(() {
          if (selected) {
            _selectedReminders.add(days);
          } else {
            _selectedReminders.remove(days);
          }
        });
      },
      selectedColor: AppTheme.primaryColor.withValues(alpha: 0.15),
      checkmarkColor: AppTheme.primaryColor,
    );
  }

  Widget _buildSaveButton() {
    return FilledButton.icon(
      onPressed: _save,
      icon: Icon(_isEditing ? Icons.check : Icons.add),
      label: Text(_isEditing ? AppLocalizations.of(context).saveChanges : AppLocalizations.of(context).addLink),
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      locale: Locale(AppLocalizations.of(context).locale.languageCode),
      cancelText: AppLocalizations.of(context).cancel,
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dateHasBeenSet = true;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<BirthdayProvider>();

    final birthday = Birthday(
      id: _isEditing ? widget.editBirthday!.id : const Uuid().v4(),
      name: _nameController.text.trim(),
      date: _dateHasBeenSet ? _selectedDate : Birthday.noBirthdaySentinel,
      phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
      email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
      address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      imagePath: _imagePath,
      avatarColor: _isEditing ? widget.editBirthday!.avatarColor : null,
      reminderDaysBefore: _selectedReminders,
      relationType: _selectedRelationType,
      planningItems: _isEditing
          ? widget.editBirthday!.planningItems
          : Birthday.localizedPlanningItems(_selectedRelationType, AppLocalizations.of(context).get),
      relations: _isEditing ? widget.editBirthday!.relations : [],
    );

    if (_isEditing) {
      await provider.updateBirthday(birthday);
    } else {
      await provider.addBirthday(birthday);
      final isFirst = provider.allBirthdays.length == 1;
      if (isFirst) {
        FacebookAnalyticsService.instance.logCompleteRegistration();
      }
    }

    if (mounted) Navigator.pop(context);
  }

  Future<void> _importFromContacts() async {
    setState(() => _isImporting = true);

    try {
      final contactService = ContactService();

      // Request permission via flutter_contacts (shows iOS system dialog)
      final granted = await FlutterContacts.requestPermission();
      if (!granted && mounted) {
        // Completely denied – offer to open Settings
        final goToSettings = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(AppLocalizations.of(context).importContacts),
            content: Text(AppLocalizations.of(context).get('contacts_limited_access')),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(AppLocalizations.of(context).cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(AppLocalizations.of(context).get('open_settings')),
              ),
            ],
          ),
        );
        if (goToSettings == true) {
          await _openAppSettings();
          if (!mounted) return;
          final nowGranted = await FlutterContacts.requestPermission();
          if (!nowGranted) {
            if (mounted) setState(() => _isImporting = false);
            return;
          }
        } else {
          if (mounted) setState(() => _isImporting = false);
          return;
        }
      }

      // Detect limited vs full access
      final permStatus = await Permission.contacts.status;
      final isLimited = permStatus.isLimited;

      // Fetch available contacts
      final allFromContacts = await contactService.getPickableContacts();
      if (!mounted) return;

      debugPrint('Contacts found: ${allFromContacts.length}, limited: $isLimited');

      if (allFromContacts.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).importNone)),
        );
        return;
      }

      // Filter out contacts that already exist (by name)
      final existingNames = context.read<BirthdayProvider>().allBirthdays
          .map((b) => b.name.toLowerCase().trim())
          .toSet();
      final newContacts = allFromContacts
          .where((c) => !existingNames.contains(c.displayName.toLowerCase().trim()))
          .toList();

      debugPrint('New contacts (not already imported): ${newContacts.length}');

      if (newContacts.isEmpty && !isLimited) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).get('all_already_imported')),
          ),
        );
        return;
      }

      // Show contact picker dialog
      if (!mounted) return;
      await _showContactPickerDialog(
        contactService: contactService,
        contacts: newContacts,
        isLimited: isLimited,
        allAlreadyImported: newContacts.isEmpty,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kunde inte importera: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }

  Future<void> _showContactPickerDialog({
    required ContactService contactService,
    required List<PickableContact> contacts,
    required bool isLimited,
    bool allAlreadyImported = false,
  }) async {
    final l10n = AppLocalizations.of(context);
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
                                  l10n.importContacts,
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
                                      ? l10n.get('deselect_all')
                                      : l10n.get('select_all')),
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
                    // Limited access banner
                    if (isLimited)
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.info_outline, color: Colors.orange.shade700, size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    l10n.get('contacts_limited_access'),
                                    style: TextStyle(fontSize: 13, color: Colors.orange.shade900),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () async {
                                      Navigator.pop(ctx);
                                      // Re-request permission to let user pick more contacts
                                      await FlutterContacts.requestPermission();
                                      if (!mounted) return;
                                      // Re-run import to refresh the list
                                      _importFromContacts();
                                    },
                                    icon: const Icon(Icons.person_add_outlined, size: 16),
                                    label: Text(l10n.get('select_more_contacts'), style: const TextStyle(fontSize: 12)),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () async {
                                      Navigator.pop(ctx);
                                      await _openAppSettings();
                                    },
                                    icon: const Icon(Icons.settings_outlined, size: 16),
                                    label: Text(l10n.get('full_access'), style: const TextStyle(fontSize: 12)),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    if (allAlreadyImported && contacts.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          l10n.get('all_already_imported'),
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
                          textAlign: TextAlign.center,
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
                                final hasBirthday = c.birthday != null;
                                return CheckboxListTile(
                                  value: isSelected,
                                  onChanged: hasBirthday
                                      ? (val) {
                                          setSheetState(() {
                                            if (val == true) {
                                              selected.add(originalIndex);
                                            } else {
                                              selected.remove(originalIndex);
                                            }
                                          });
                                        }
                                      : null,
                                  title: Text(
                                    c.displayName,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: hasBirthday ? null : Colors.grey.shade400,
                                    ),
                                  ),
                                  subtitle: hasBirthday
                                      ? Text(DateFormat.yMMMd(l10n.locale.languageCode).format(c.birthday!))
                                      : Row(
                                          children: [
                                            Icon(Icons.warning_amber_rounded, size: 14, color: Colors.orange.shade400),
                                            const SizedBox(width: 4),
                                            Text(
                                              l10n.get('no_birthday_set'),
                                              style: TextStyle(color: Colors.orange.shade400),
                                            ),
                                          ],
                                        ),
                                  secondary: CircleAvatar(
                                    backgroundColor: hasBirthday
                                        ? AppTheme.getAvatarColor(null, c.displayName)
                                        : Colors.grey.shade300,
                                    child: Text(
                                      c.displayName.isNotEmpty ? c.displayName[0].toUpperCase() : '?',
                                      style: TextStyle(
                                        color: hasBirthday ? Colors.white : Colors.grey.shade500,
                                        fontWeight: FontWeight.bold,
                                      ),
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
                              label: Text('${l10n.importContacts} (${selected.length})'),
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
      FacebookAnalyticsService.instance.logImportContacts(count: birthdays.length);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${birthdays.length} kontakter importerade!')),
        );
        Navigator.pop(context);
      }
    }
  }

  Future<void> _openAppSettings() async {
    final uri = Uri.parse('app-settings:');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}
