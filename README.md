# BudgetBuddy — Flutter Final Project

A student-level Flutter/Dart allowance and expense tracker with local persistence and a live exchange-rate API.

## Features
- Local register/login, logout and session restoration (classroom demo authentication only)
- Dashboard: allowance total, expense total, remaining balance and recent transactions
- Add, edit and delete allowance records
- Add, edit, delete, search, filter and sort expenses
- Category doughnut chart using `fl_chart`
- Exchange rates retrieved from the Frankfurter public API (`https://api.frankfurter.app`)
- Profile display name and currency preference; budget values are recorded in PHP by default
- Responsive navigation: bottom navigation on mobile, navigation rail on wide screens
- Validation, empty states, feedback messages and delete confirmations

## Run on your computer
Install Flutter and Android Studio/Android SDK first. From this folder run the included PowerShell setup script (Windows):
```powershell
.\setup_flutter_project.ps1
dart format .
flutter analyze
flutter test
flutter run
```
The script generates Flutter platform scaffolding for Android and Windows, adds Android internet permission for the API, and runs `flutter pub get`. If you prefer, run `flutter create . --platforms=android,windows` manually and add `android.permission.INTERNET` to the Android manifest.
To build an APK: `flutter build apk`

After `flutter create .`, ensure `android/app/src/main/AndroidManifest.xml` contains `<uses-permission android:name="android.permission.INTERNET" />` above the `<application>` tag. This is needed for exchange-rate API requests. Flutter-generated platform files depend on the Flutter version installed on your computer; the command above generates compatible platform scaffolding.

## API behavior
The Exchange Rates page requests latest rates from Frankfurter (`https://api.frankfurter.app/latest?from=<base>&to=USD,EUR,JPY,GBP,SGD,PHP`). It has a loading indicator, retry action and offline error state. Budget features continue working without internet.

## Local data and security
User profiles, allowance records, expense records and the session are saved with `shared_preferences`. Records are filtered by user ID and do not sync across devices. Authentication is for classroom demonstration only; do not use a real password. Passwords are stored as a simple demo digest, not production-grade password hashing. The app is not intended for sensitive financial data.

## Instructor requirements covered
- AppBar and screen titles: yes
- Text, colors and consistent visual styling: yes
- Icons/assets: Material icons and a consistent theme; no large external images needed
- StatelessWidget and StatefulWidget: both used
- Custom reusable widgets: summary cards, record rows and empty states
- ListView.builder: used for allowance, expense and rate collections
- API retrieval: Frankfurter exchange-rate API (live HTTP requests)
- Delete functionality: allowance and expense records, with confirmation
- HCI: consistent navigation, readable contrast, validation, clear feedback, empty states and destructive-action confirmation

## Verification results
```
flutter pub get          ✓
dart format .            ✓
flutter analyze          ✓ (no issues)
flutter test             ✓ (60 tests passed)
flutter build apk        ✓ (50.4 MB)
flutter build windows    ✗ (symlink permission issue on Windows/OneDrive)
```

## Known limitations
- Windows desktop build requires Developer Mode enabled on Windows or Administrator privileges to create plugin symlinks. The APK (Android) build completes successfully.
- Currency preference changes display formatting only; stored amounts are not retroactively converted.
- Password storage uses a lightweight FNV-1a digest for classroom demo purposes only.

## Verified API endpoint
The exchange-rate feature uses the Frankfurter API at `https://api.frankfurter.app/latest?from=<base>&to=USD,EUR,JPY,GBP,SGD,PHP` with a 12-second timeout. The original code used the incorrect `.dev` domain which returned 404.