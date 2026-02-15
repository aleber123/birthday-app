import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../models/birthday.dart';

class ContactService {
  static const _uuid = Uuid();

  static final List<String> _avatarColors = [
    '0xFFE91E63', '0xFF9C27B0', '0xFF673AB7', '0xFF3F51B5',
    '0xFF2196F3', '0xFF03A9F4', '0xFF00BCD4', '0xFF009688',
    '0xFF4CAF50', '0xFF8BC34A', '0xFFFF9800', '0xFFFF5722',
  ];

  Future<bool> requestPermission() async {
    return await FlutterContacts.requestPermission();
  }

  /// Returns true if contacts permission is granted.
  /// Uses flutter_contacts directly to avoid conflicts with permission_handler.
  Future<bool> hasFullAccess() async {
    return await FlutterContacts.requestPermission();
  }

  Future<List<Birthday>> importFromContacts() async {
    final hasPermission = await requestPermission();
    if (!hasPermission) return [];

    final contacts = await FlutterContacts.getContacts(
      withProperties: true,
      withPhoto: true,
    );

    final appDir = await getApplicationDocumentsDirectory();
    final List<Birthday> birthdays = [];

    for (final contact in contacts) {
      if (contact.displayName.isEmpty) continue;

      // Extract birthday if available
      DateTime? birthdayDate;
      for (final event in contact.events) {
        if (event.label == EventLabel.birthday && event.year != null) {
          birthdayDate = DateTime(event.year!, event.month, event.day);
          break;
        }
      }

      // Save contact photo if available
      String? imagePath;
      if (contact.photo != null && contact.photo!.isNotEmpty) {
        final fileName = 'avatar_${_uuid.v4()}.jpg';
        final file = File('${appDir.path}/$fileName');
        await file.writeAsBytes(contact.photo!);
        imagePath = file.path;
      }

      // Extract address
      String? address;
      if (contact.addresses.isNotEmpty) {
        final a = contact.addresses.first;
        final parts = [a.street, a.city, a.postalCode, a.country]
            .where((s) => s.isNotEmpty)
            .toList();
        if (parts.isNotEmpty) address = parts.join(', ');
      }

      final colorIndex = contact.displayName.hashCode.abs() % _avatarColors.length;
      birthdays.add(Birthday(
        id: _uuid.v4(),
        name: contact.displayName,
        date: birthdayDate ?? DateTime(2000, 1, 1),
        phone: contact.phones.isNotEmpty ? contact.phones.first.number : null,
        email: contact.emails.isNotEmpty ? contact.emails.first.address : null,
        address: address,
        imagePath: imagePath,
        avatarColor: _avatarColors[colorIndex],
      ));
    }

    return birthdays;
  }

  /// Returns a list of all contacts as lightweight objects for a picker UI.
  Future<List<PickableContact>> getPickableContacts() async {
    final hasPermission = await requestPermission();
    if (!hasPermission) return [];

    final contacts = await FlutterContacts.getContacts(
      withProperties: true,
      withPhoto: true,
      sorted: true,
    );

    return contacts.map((c) {
      DateTime? birthday;
      for (final event in c.events) {
        if (event.label == EventLabel.birthday && event.year != null) {
          birthday = DateTime(event.year!, event.month, event.day);
          break;
        }
      }

      String? address;
      if (c.addresses.isNotEmpty) {
        final a = c.addresses.first;
        final parts = [a.street, a.city, a.postalCode, a.country]
            .where((s) => s.isNotEmpty)
            .toList();
        if (parts.isNotEmpty) address = parts.join(', ');
      }

      return PickableContact(
        displayName: c.displayName,
        phone: c.phones.isNotEmpty ? c.phones.first.number : null,
        email: c.emails.isNotEmpty ? c.emails.first.address : null,
        address: address,
        birthday: birthday,
        photoBytes: c.photo,
      );
    }).where((c) => c.displayName.isNotEmpty).toList();
  }

  Future<Birthday> contactToBirthday(PickableContact contact) async {
    final colorIndex = contact.displayName.hashCode.abs() % _avatarColors.length;

    // Save contact photo if available
    String? imagePath;
    if (contact.photoBytes != null && contact.photoBytes!.isNotEmpty) {
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = 'avatar_${_uuid.v4()}.jpg';
      final file = File('${appDir.path}/$fileName');
      await file.writeAsBytes(contact.photoBytes!);
      imagePath = file.path;
    }

    return Birthday(
      id: _uuid.v4(),
      name: contact.displayName,
      date: contact.birthday ?? DateTime(2000, 1, 1),
      phone: contact.phone,
      email: contact.email,
      address: contact.address,
      imagePath: imagePath,
      avatarColor: _avatarColors[colorIndex],
    );
  }

}

class PickableContact {
  final String displayName;
  final String? phone;
  final String? email;
  final String? address;
  final DateTime? birthday;
  final Uint8List? photoBytes;

  PickableContact({
    required this.displayName,
    this.phone,
    this.email,
    this.address,
    this.birthday,
    this.photoBytes,
  });
}
