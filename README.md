# QuickNote

Open → Write → Save → Done. Offline-first Flutter notes app (Android).

## Set up

```bash
flutter create --org com.yourname --project-name quicknote --platforms android .   # inside this folder; keeps lib/ and pubspec.yaml
flutter pub get
```

Then apply the Android edits in `android_overrides/`:
- `AndroidManifest.notes.md` — label, `allowBackup=false`, `<queries>` for Instagram, minSdk 23
- `MainActivity.kt` — copy over the generated one and fix the `package` line (enables screenshot/recents protection while private notes are open; the app works without it)

```bash
flutter run                      # debug
flutter build appbundle --release   # Play Store bundle (set up signing first)
```

## Architecture

```
lib/
  core/       theme, routes, config (version, Instagram URL, privacy-policy URL), AppScope
  models/     Note
  data/       NoteDatabase (sqflite), NoteRepository, SettingsStore (theme, default color, draft)
  security/   PrivacyService (PIN, key derivation, AES-GCM), ScreenSecurity (FLAG_SECURE channel)
  screens/    Home, Saved, Settings, Editor, PIN setup, Privacy info, note actions, PIN prompt
  widgets/    NoteCard, NoteGrid (masonry), PinPad, color picker, empty state, round buttons
```

## Private notes — how they work

- Key = PBKDF2-HMAC-SHA256(PIN, salt ‖ device secret), 60k iterations, run in an isolate.
  The device secret is random and kept in Android Keystore-backed secure storage.
- Title and body of a private note are encrypted together with AES-256-GCM; only ciphertext touches SQLite.
- The PIN is never stored. It's "correct" only if it decrypts a small verifier blob.
- Wrong guesses: 5 free tries, then escalating lockouts (30 s doubling up to 1 h), persisted across restarts.
- Locks automatically when the app goes to background. Locked cards show no text; locked notes are excluded from search.
- Change PIN requires the old PIN and re-encrypts every private note.
- Forgot PIN → notes are unrecoverable by design; "Reset private notes" deletes them and the PIN.
- Honest limits (also stated in-app): 4 digits = 10,000 combinations; throttling slows guessing but doesn't make a weak PIN strong.

## Before you publish

1. Put your hosted privacy policy URL in `lib/core/config.dart` (`kPrivacyPolicyUrl`). `PRIVACY_POLICY.md` is a template.
2. Play Console → Data safety: no data collected or shared; no permissions requested in release.
3. Create an upload keystore, keep it and `key.properties` out of git.
4. Run the checklist on a real device with a **release** build:
   startup · add/edit/persist across restart · search · pin/unpin · Saved tab · delete + Undo ·
   private: setup, confirm PIN, unlock, wrong PIN, lock on background, no text in locked cards or search ·
   change PIN (old notes still open) · reset · Instagram button · light/dark · landscape/large phone.
