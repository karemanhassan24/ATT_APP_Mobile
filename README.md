# نظام الحضور — Mobile (Capacitor)

Android wrapper for the attendance HTML app, built with [Capacitor](https://capacitorjs.com/).

## Local setup

```powershell
cd C:\Users\kareman.hassan\Desktop\ATT_APP_Mobile
npm install
npx cap sync android
npx cap open android
```

In Android Studio: **Build → Build Bundle(s) / APK(s) → Build APK(s)**.

## Codemagic (cloud APK build)

1. Push this folder to GitHub or GitLab.
2. Sign up at [codemagic.io/apps](https://codemagic.io/apps) and connect the repo.
3. Create a release keystore:
   ```powershell
   keytool -genkey -v -keystore attendance-release.keystore -alias attendance -keyalg RSA -keysize 2048 -validity 10000
   ```
4. In Codemagic → **Team settings → Code signing identities → Android**, upload the keystore and name it **`attendance_keystore`** (must match `codemagic.yaml`).
5. Update the email in `codemagic.yaml` under `publishing.email.recipients`.
6. Start workflow **android-release** and download the APK from Artifacts.

## App details

| Setting   | Value                    |
|-----------|--------------------------|
| App ID    | `com.alfath.attendance`  |
| Web entry | `www/index.html`         |

Permissions: Internet, fine/coarse location (GPS).
