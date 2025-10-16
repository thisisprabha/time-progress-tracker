## Time Progress Tracker — Google Play Publish Checklist

Use this end-to-end checklist to go from test build to production release. Check items off as you complete them.

### 1) AdMob — Switch from Test to Production IDs (no code changes yet)
- [ ] Create/verify AdMob account at `https://admob.google.com`
- [ ] **IMPORTANT**: App must be in Closed/Open Testing (not Internal) to be found by AdMob
- [ ] Promote to Closed Testing in Play Console if needed (wait 2-4 hours)
- [ ] Add an app in AdMob: Android → "Yes, it's listed on Google Play"
- [ ] Search for package: `com.timeprogresstracker.app`
- [ ] Note your AdMob App ID (format: ca-app-pub-XXXXXXXXXXXXXXXX~YYYYYYYYYY)
- [ ] Create Banner ad units you need (Home + Settings): get Unit IDs (format: ca-app-pub-XXXXXXXXXXXXXXXX/ZZZZZZZZZZ)
- [ ] Confirm Google Play services up to date on test device
- [ ] Decide on consent/UMP (GDPR/EEA) if targeting EEA users
- [ ] CONFIRMATION REQUIRED: After you share the App ID and Unit IDs, I will update:
  - [ ] `apps/mobile/android/app/src/main/AndroidManifest.xml` meta-data `com.google.android.gms.ads.APPLICATION_ID`
  - [ ] `apps/mobile/src/app/time-progress.jsx` BannerAd `unitId`s (replace TestIds)

### 2) App Versioning & Metadata
- [ ] Update `apps/mobile/app.json`:
  - [ ] `android.versionCode` → increment (e.g., 2, 3, ...)
  - [ ] `version` or `runtimeVersion` consistent (we use `"1.0.0"` now)
- [ ] Update app name/description if needed

### 3) App Icons & Store Assets
- [ ] App icon (512×512 PNG, <1024 KB, square, no rounded corners) for Play Console
- [ ] Feature graphic (1024×500 JPG/PNG)
- [ ] In-app icons already configured in `app.json` (verify)
- [ ] Screenshots (minimum 2 per device type used):
  - [ ] Phone (1080×1920 or higher, portrait, PNG/JPG)
  - [ ] Optional: 7"/10" tablet screenshots

### 4) Policy, Privacy & Declarations
- [ ] Privacy Policy URL (host on your site or GitHub Pages)
- [ ] Data safety form (Play Console → App content)
- [ ] Ads declaration (Yes → using AdMob)
- [ ] Target audience & content (set age groups, not primarily child-directed unless intended)
- [ ] Content rating questionnaire
- [ ] App category + contact email + website URL

### 5) Android Signing
- [ ] Decide signing: Google Play App Signing (recommended) or local keystore
- [ ] If local keystore:
  - [ ] Create keystore
    ```bash
    cd apps/mobile/android
    keytool -genkey -v -keystore app-release.keystore -alias upload -keyalg RSA -keysize 2048 -validity 10000
    ```
  - [ ] Set `gradle.properties` (create if missing):
    ```properties
    MYAPP_UPLOAD_STORE_FILE=app-release.keystore
    MYAPP_UPLOAD_KEY_ALIAS=upload
    MYAPP_UPLOAD_STORE_PASSWORD=YOUR_STORE_PASSWORD
    MYAPP_UPLOAD_KEY_PASSWORD=YOUR_KEY_PASSWORD
    ```
  - [ ] Configure `apps/mobile/android/app/build.gradle` → `signingConfigs { release { ... } }` and `buildTypes { release { signingConfig signingConfigs.release } }`

### 6) Build Release (AAB preferred)
- [ ] Start Metro in a separate terminal for dev-client flows (optional):
  ```bash
  cd /Users/prabhakaran/Downloads/create-anything/apps/mobile
  npx expo start --dev-client --port 8081
  ```
- [ ] Build Android Release AAB:
  ```bash
  cd /Users/prabhakaran/Downloads/create-anything/apps/mobile/android
  ./gradlew bundleRelease
  ```
- [ ] Output AAB: `apps/mobile/android/app/build/outputs/bundle/release/app-release.aab`
- [ ] (Optional) Build APK for sideload testing:
  ```bash
  ./gradlew assembleRelease
  ```

### 7) Play Console — Create Production Release
- [ ] Create app in `https://play.google.com/console/`
- [ ] Fill all store listing fields (title, short/full description, graphics, screenshots)
- [ ] Upload `app-release.aab`
- [ ] Complete App content sections (Privacy, Data safety, Ads declaration, Target audience, Content rating)
- [ ] Set pricing & distribution countries
- [ ] Add testers if doing a Closed/Open testing track first
- [ ] Submit for review

### 8) Post-Launch
- [ ] Monitor ANRs/Crashes (Play Console → Android Vitals)
- [ ] Check AdMob reporting for fill rate and revenue
- [ ] Plan a staged rollout for updates

---

### Project-Specific Notes
- Build system: Expo prebuild (bare RN under the hood)
- Runtime version fixed: `"runtimeVersion": "1.0.0"`
- Widgets: Implemented for Android (2 sizes) and iOS (WidgetKit)
- Fonts: Kalam (Regular/Bold) in Android widgets via bitmap rendering

### Provide These To Proceed With Live Ads Update (confirmation needed)
- [ ] AdMob App ID (Android)
- [ ] Banner Ad Unit IDs (Home + Settings)

Once you share the IDs, I will update the manifest and code in a single commit and push to your chosen branch.


