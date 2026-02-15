# Födelsedagar 🎂

En snygg och integritetsfokuserad födelsedags-påminnelseapp byggd med Flutter.

## Funktioner

- **Lägg till födelsedagar** manuellt eller importera från kontakter
- **Automatiska påminnelser** – samma dag, 1 dag, 1 vecka innan (och fler med Premium)
- **Kalendervy** med månadsöversikt
- **Countdown** – se hur många dagar kvar till varje födelsedag
- **Stjärntecken & ålder** beräknas automatiskt
- **Mörkt läge** – följer systemets inställning
- **Sök & sortera** – efter namn, ålder, kommande eller senast tillagda
- **100% lokalt** – all data sparas på enheten, ingen molnsynk

## Teknikstack

| Komponent | Teknologi |
|-----------|-----------|
| Framework | Flutter 3.38+ (Dart) |
| Databas | SQLite via sqflite |
| State | Provider |
| Notiser | flutter_local_notifications |
| Kontakter | flutter_contacts |
| Kalender | table_calendar |

## Kom igång

### Förutsättningar
- Flutter SDK 3.10+
- Xcode (för iOS)
- Android Studio (för Android)
- CocoaPods (`brew install cocoapods`)

### Installation

```bash
# Klona projektet
cd birthday_app

# Installera dependencies
flutter pub get

# Kör på iOS-simulator
flutter run -d ios

# Kör på Android-emulator
flutter run -d android
```

### Tester

```bash
flutter test
flutter analyze
```

## Projektstruktur

```
lib/
├── main.dart                  # App-startpunkt
├── models/
│   └── birthday.dart          # Datamodell
├── providers/
│   └── birthday_provider.dart # State management
├── screens/
│   ├── home_screen.dart       # Huvudlista
│   ├── add_birthday_screen.dart # Lägg till / redigera
│   ├── birthday_detail_screen.dart # Detaljvy
│   ├── calendar_screen.dart   # Kalendervy
│   └── settings_screen.dart   # Inställningar
├── services/
│   ├── database_service.dart  # SQLite-databas
│   ├── notification_service.dart # Lokala notiser
│   └── contact_service.dart   # Kontaktimport
├── utils/
│   ├── app_theme.dart         # Ljust/mörkt tema
│   └── constants.dart         # Konstanter
└── widgets/
    ├── birthday_avatar.dart   # Initialer-avatar
    ├── birthday_card.dart     # Listkort
    └── today_banner.dart      # "Idag"-banner

```

## Monetisering (Freemium)

**Gratis:**
- Max 30 födelsedagar
- 3 påminnelsetider (samma dag, 1 dag, 1 vecka)

**Premium (29–79 kr/mån eller 199 kr/år):**
- Obegränsat antal födelsedagar
- 6 påminnelsetider
- Export till CSV/PDF
- Extra teman
- Familje-delning

## Nästa steg

- [ ] Hemskärms-widget (iOS WidgetKit + Android Glance)
- [ ] iCloud/Google backup
- [ ] Digitala gratulationskort
- [ ] Affiliate-gåvolänkar
- [ ] In-app köp (RevenueCat)
- [ ] Lockscreen-widget (iOS 16+)
- [ ] Familje-delning via QR/länk

## Licens

Privat projekt – alla rättigheter förbehållna.
