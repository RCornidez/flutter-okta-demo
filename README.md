# Flutter + Okta Auth Demo

A Flutter app demonstrating user registration and login with [Okta](https://okta.com) using the OAuth 2.0 Authorization Code flow with PKCE. No Okta SDK is used — the flow is implemented from scratch with standard HTTP calls so every step is visible and understandable.

---

## Okta Setup

I signed up for trial access this will generate a unique domain. You can use this and update your application name throughout the app. Or you can just set the callbacks to be: login redirect `com.okta.trial-8077266:/callback` and logout redirect `com.okta.trial-8077266:/`. This should work without having to refactor folders/names.

You will need to generate:
    1. An application (OIDC, Native)
    2. An API token (Security > API > Tokens > "Create Token")

You will need to configure:
    1. A resource server access policy: in the Admin Console go to Security > API > Authorization Servers, edit the `default` server, open Access Policies, and add a rule that grants simple permissions.
    2. A single factor login policy and assign it to the app. (for simplicity to not require users to use authenticator app)

Note the domain, client id, and API token for env setup.

---

## Env Setup

The app reads credentials from a `.env` file at runtime. Copy the example and fill in your values:

```bash
cp demo/.env.example demo/.env
```

```env
# Matches your Okta Admin Dashboard URL
OKTA_DOMAIN=trial-xxxxxxx.okta.com     # Your Okta org domain (no https://)
OKTA_CLIENT_ID=YOUR_CLIENT_ID          # From the Okta app integration
# Dashboard > Applications > Listed within app
OKTA_REDIRECT_URI=com.okta.trial-xxxxxxx:/callback  # Must match the custom URI scheme registered in the Okta app
# Security > API > Tokens > 'Create Token'
OKTA_API_TOKEN=YOUR_OKTA_API_TOKEN     # An Okta API token used only for user registration
```

**Why a `.env` file?**
Hard-coding credentials in Dart source would expose them in version control. `flutter_dotenv` loads the file at startup and makes values available via `dotenv.env['KEY']`. The file is listed as a Flutter asset in `pubspec.yaml` so it gets bundled into the app binary.

> **Note:** The `OKTA_API_TOKEN` grants broad admin access to your Okta org. In a production app, registration should go through your own backend server, not directly from the mobile client.

---

## How to Run (Emulator)

> [!IMPORTANT]
> If you encounter a white login screen you may need to clear your cache and reset the emulator state:
> ```
> flutter clean && flutter pub get
> adb shell pm clear com.okta.trial_8077266
> ```

**Prerequisites**

- Flutter SDK installed and on your `PATH`
- Android Studio with an Android emulator configured (API 23+)
- `demo/.env` populated (see above)

**Steps**

```bash
# 1. Install Dart dependencies
cd demo
flutter pub get

# 2. Start an Android emulator (or connect a physical device)
flutter emulators --launch <emulator_id>
# List available emulators with: flutter emulators

# 3. Run the app
flutter run -d <device_name>
```

The app will compile and install on the emulator. You should see the Welcome splash screen with Login and Sign Up buttons.

---

## Auth Configuration

This section explains how registration and login work end-to-end. For a step-by-step visual walkthrough see:

- [LOGINFLOW.md](LOGINFLOW.md) — OAuth 2.0 PKCE login from splash screen to home screen
- [REGISTERFLOW.md](REGISTERFLOW.md) — account creation via the Okta Users API

---

### File Map

```
demo/lib/
├── main.dart                  # Entry point: loads .env, wires up BLoC, starts on SplashScreen
├── env/
│   ├── environment_state.dart # Plain data class holding the four Okta config values
│   └── environment_cubit.dart # Reads .env and emits EnvironmentState
├── auth/
│   └── auth_client.dart       # All Okta API calls: login redirect, callback handling, signup
└── screens/
    ├── splash_screen.dart     # Landing screen; handles deep link callbacks via MethodChannel
    ├── signup_screen.dart     # Registration form → AuthClient.signup()
    └── home_screen.dart       # Post-login screen (shows tokens are present)

demo/android/app/src/main/
├── AndroidManifest.xml        # Registers the com.okta.trial-8077266:/ intent-filter so Android
│                              # routes the OAuth callback URI back to the app
└── kotlin/com/okta/trial_8077266/
    └── MainActivity.kt        # Bridges the deep link into Flutter: captures the callback URI from
                               # the launching Intent (cold start) or onNewIntent (app already running)
                               # and delivers it to SplashScreen via the MethodChannel
```
