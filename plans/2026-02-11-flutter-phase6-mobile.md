# Phase 6: Mobile

## Goal

Extend the Flutter web app to iOS and Android. The codebase is already cross-platform by design — this phase focuses on platform-specific adjustments, testing, and app store preparation.

## Prerequisites

- Phases 1–5 complete and deployed
- Flutter web app is stable and feature-complete
- Apple Developer account (iOS)
- Google Play Developer account (Android)

## Step 1: Enable Mobile Platforms

```bash
cd frontend
flutter create . --platforms ios,android
```

This adds `ios/` and `android/` directories to the existing project without touching `lib/`.

## Step 2: Platform-Specific Adjustments

**Secure storage:**
`flutter_secure_storage` automatically uses:
- iOS: Keychain
- Android: EncryptedSharedPreferences

No code changes — the package handles this. Verify tokens persist across app restarts on both platforms.

**Image picker:**
`image_picker` works on all platforms but the UX differs:
- Web: file picker dialog (already working)
- Mobile: camera + gallery options
- Add camera option to photo upload UI when running on mobile
- Request camera/photo library permissions in `Info.plist` (iOS) and `AndroidManifest.xml` (Android)

**Navigation patterns:**
- Web: GoRouter handles browser back/forward, URL bar
- Mobile: GoRouter still works, but consider adding swipe-back gestures (iOS default)
- Bottom navigation bar on mobile instead of top nav (common mobile pattern)
- Detect platform with `kIsWeb` or `Platform.isIOS` / `Platform.isAndroid`

**Deep linking:**
- Configure `AndroidManifest.xml` and Apple Associated Domains for deep links
- Links like `vedgy.com/listing/{id}` open the mobile app if installed

## Step 3: API Base URL

Mobile apps can't use relative URLs like the web production build:
- Web (prod): `/api/` (same origin)
- Mobile: `https://your-domain.com/api/` (absolute URL)

Use environment config to set the base URL per platform/build.

## Step 4: Platform Testing

**iOS:**
- Test on iPhone simulator (various sizes: SE, 15, 15 Pro Max)
- Test on iPad simulator
- Verify Keychain token storage
- Test camera + gallery photo upload
- Test deep links
- Test background/foreground app lifecycle (token refresh on resume)

**Android:**
- Test on Android emulator (various screen sizes and API levels)
- Verify EncryptedSharedPreferences
- Test camera + gallery photo upload
- Test deep links
- Test back button behavior (should follow GoRouter stack)

## Step 5: Mobile-Specific UI Polish

**Responsive adjustments that matter more on mobile:**
- Touch targets: minimum 48x48dp for all tappable elements
- Form inputs: appropriate keyboard types (email keyboard for email fields, number keyboard for price)
- Pull-to-refresh on browse and dashboard screens
- Photo gallery: swipe gestures for photo navigation (instead of arrow buttons)
- Listing cards: slightly larger tap targets, reduced information density

**Status bar and safe areas:**
- Use `SafeArea` widget to handle notches and home indicators
- Status bar color matches app theme

## Step 6: App Store Preparation

**iOS (App Store):**
- App icon (1024x1024) and splash screen
- `Info.plist`: camera usage description, photo library usage description
- Bundle identifier, version number, build number
- App Store Connect: app listing, screenshots, description, privacy policy URL
- TestFlight for beta testing

**Android (Google Play):**
- App icon (adaptive icon: foreground + background)
- Splash screen
- `build.gradle`: application ID, version code, version name
- Signing key for release builds
- Google Play Console: store listing, screenshots, description, privacy policy URL
- Internal testing track for beta

**Shared:**
- Privacy policy URL (point to `/privacy` on the web app)
- App description and screenshots for each platform
- Review guidelines compliance (no payment in-app if not using platform payment systems)

## Step 7: CI/CD for Mobile

Add to build pipeline:
- `flutter build apk --release` — Android release build
- `flutter build ipa --release` — iOS release build (requires macOS)
- Consider Codemagic or GitHub Actions for automated mobile builds
- Web build continues to deploy via Railway as before

## Out of Scope (Future Considerations)

These are not part of this phase but worth noting for later:
- **Push notifications** — notify listers when listings are approved/rejected, notify users of new listings matching saved searches
- **Offline support** — cache browse results for offline viewing
- **Biometric auth** — fingerprint/face login using stored refresh token
- **App-specific features** — location-based listing suggestions, map view

## Acceptance Criteria

- App runs on iOS simulator and Android emulator
- Auth flow works (signup, login, token refresh, logout)
- Photo upload works from camera and gallery
- Navigation feels native on each platform (swipe back on iOS, back button on Android)
- All screens display correctly on various phone and tablet sizes
- Deep links open correct screens
- App resumes correctly after backgrounding (tokens refresh)
- Release builds generate successfully for both platforms
- TestFlight / internal testing builds distributed for beta testing
