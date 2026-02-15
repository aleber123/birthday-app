# App Store & TestFlight – Lanseringsguide

## 1. GitHub Pages (krävs innan App Store-submission)

### Skapa repo och publicera
```bash
# 1. Skapa nytt repo på GitHub: birthday-app
# Gå till https://github.com/new → namn: birthday-app → Public → Create

# 2. Pusha docs-mappen
cd /Users/sogr/CascadeProjects/birthday_app
git init
git add docs/
git commit -m "Add App Store required pages: privacy, terms, support"
git remote add origin https://github.com/aleber123/birthday-app.git
git branch -M main
git push -u origin main

# 3. Aktivera GitHub Pages
# Gå till: https://github.com/aleber123/birthday-app/settings/pages
# Source: Deploy from a branch
# Branch: main → /docs → Save
```

### Verifiera att sidorna fungerar (vänta ~2 min efter aktivering)
- https://aleber123.github.io/birthday-app/index.html
- https://aleber123.github.io/birthday-app/privacy.html
- https://aleber123.github.io/birthday-app/terms.html
- https://aleber123.github.io/birthday-app/support.html

---

## 2. App Store Connect – Skapa app

### Förutsättningar
- Apple Developer-konto ($99/år): https://developer.apple.com/programs/enroll/
- Xcode installerat med giltigt signing certificate

### Steg
1. Gå till https://appstoreconnect.apple.com
2. **My Apps** → **+** → **New App**
3. Fyll i:
   - **Platform:** iOS
   - **Name:** Födelsedagar
   - **Primary Language:** Swedish
   - **Bundle ID:** com.alexanderbergqvist.birthdayreminder
   - **SKU:** birthdayreminder001

---

## 3. App Store-metadata

### App Information
| Fält | Värde |
|------|-------|
| **Name** | Födelsedagar |
| **Subtitle** | Glöm aldrig en födelsedag |
| **Category** | Lifestyle |
| **Secondary Category** | Utilities |
| **Content Rights** | Does not contain third-party content |
| **Age Rating** | 4+ |

### Privacy Policy URL
```
https://aleber123.github.io/birthday-app/privacy.html
```

### Support URL
```
https://aleber123.github.io/birthday-app/support.html
```

### Marketing URL (valfritt)
```
https://aleber123.github.io/birthday-app/index.html
```

### Beskrivning (Swedish)
```
Glöm aldrig en födelsedag igen! 🎂

Födelsedagar hjälper dig hålla koll på alla viktiga datum med smarta påminnelser, presenttips och en unik relationskarta.

✨ FUNKTIONER:
🔔 Smarta påminnelser – Välj när du vill bli påmind
🎁 Presenttips – Anpassade efter ålder och relation
🗺️ Relationskarta – Visualisera kopplingar mellan personer
💸 Swish & Vipps – Skicka pengar enkelt
📱 SMS-gratulationer – Skicka hälsning med ett tryck
📅 Kalendervy – Se alla födelsedagar i månadsöversikt
📇 Kontaktimport – Importera från telefonboken

🌍 Stöd för svenska, norska, danska, finska, isländska och engelska.

Ladda ner gratis och börja fira! 🎉
```

### Keywords (max 100 tecken)
```
födelsedag,påminnelse,present,kalender,grattis,birthday,reminder,swish
```

### Promotional Text (kan ändras utan ny version)
```
🎂 Ny version! Relationskarta, Vipps-stöd och förbättrade presenttips.
```

---

## 4. Screenshots (KRÄVS)

Du behöver screenshots för:
- **iPhone 6.7"** (iPhone 15 Pro Max) – 1290 × 2796 px – **minst 3 st**
- **iPhone 6.5"** (iPhone 14 Plus) – 1284 × 2778 px
- **iPad 12.9"** (om du stödjer iPad) – 2048 × 2732 px

### Tips
- Visa: Hemskärm med födelsedagar, detaljvy, relationskarta, presenttips, kalender
- Använd Simulator i Xcode: `Cmd+S` för screenshot

---

## 5. Bygga för release

### Steg 1: Uppdatera version
I `pubspec.yaml` är version redan `1.0.0+2`. Öka build-nummer vid varje upload:
```yaml
version: 1.0.0+3
```

### Steg 2: Bygga IPA
```bash
cd /Users/sogr/CascadeProjects/birthday_app

# Rensa gammal build
flutter clean

# Hämta dependencies
flutter pub get

# Bygga för iOS release
flutter build ipa --release
```

### Steg 3: Ladda upp till App Store Connect
```bash
# Alternativ 1: Via Xcode
open build/ios/archive/Runner.xcarchive
# → Distribute App → App Store Connect → Upload

# Alternativ 2: Via kommandorad
xcrun altool --upload-app -f build/ios/ipa/birthday_reminder.ipa -t ios -u DITT_APPLE_ID -p APP_SPECIFIC_PASSWORD
```

---

## 6. TestFlight

### Intern testning (direkt efter upload)
1. Gå till App Store Connect → din app → TestFlight
2. Vänta på att builden bearbetas (~10-30 min)
3. Under **Internal Testing** → lägg till dig själv som testare
4. Öppna TestFlight-appen på din iPhone → installera

### Extern testning (kräver Apple-granskning)
1. Skapa en **External Testing Group**
2. Lägg till testares e-postadresser
3. Fyll i **Beta App Description** och **What to Test**
4. Skicka in → Apple granskar (vanligtvis 24-48h)

---

## 7. App Review – Vanliga avvisningsorsaker

| Problem | Lösning |
|---------|---------|
| Privacy policy saknas | ✅ Redan fixat (GitHub Pages) |
| Support URL saknas | ✅ Redan fixat |
| Metadata saknas | Fyll i allt ovan |
| Screenshots saknas | Ta minst 3 screenshots |
| Crash vid start | Testa på riktig enhet först |
| In-app purchases inte konfigurerade | Konfigurera i App Store Connect |
| Ads utan consent (GDPR) | AdMob hanterar detta via UMP SDK |

---

## 8. Checklista före submission

- [ ] GitHub Pages publicerade och fungerar
- [ ] Privacy Policy URL fungerar
- [ ] Support URL fungerar
- [ ] App-ikon (1024x1024) uppladdad
- [ ] Screenshots för alla enheter
- [ ] Beskrivning, keywords, subtitle ifyllda
- [ ] Åldersklassificering ifylld (4+)
- [ ] In-app purchases konfigurerade (om Premium)
- [ ] Testat på riktig iPhone via TestFlight
- [ ] Inga crashes eller stora buggar
- [ ] Version och build-nummer uppdaterade
