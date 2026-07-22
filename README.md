# Bookery

A premium Flutter book tracker project.

## Security & Credentials Setup

To keep private API keys and credentials out of the public Git history, all configuration credentials (like the Hardcover API token and Firebase settings) are loaded dynamically at compile-time from environment variables.

To run the project locally, follow these configuration steps:

### 1. Hardcover and Firebase Credentials
1. Copy the `secrets.json.example` template at the root of the project to a new file named `secrets.json`:
   ```bash
   cp secrets.json.example secrets.json
   ```
2. Open `secrets.json` and fill in your Hardcover API token and your Firebase credentials.
3. *Note:* `secrets.json` is already added to `.gitignore` so it will never be committed to your repository.

### 2. Android Configuration
1. Copy the `android/app/google-services.json.example` template to `android/app/google-services.json`:
   ```bash
   cp android/app/google-services.json.example android/app/google-services.json
   ```
2. Open `android/app/google-services.json` and fill in your Firebase configuration parameters (especially `mobilesdk_app_id`, `project_id`, and `api_key`).
3. *Note:* This file is also gitignored and won't be pushed.

---

## Running the Project

To run or build the app locally, pass the `secrets.json` file to the compiler using the `--dart-define-from-file` parameter:

### Command Line
```bash
flutter run --dart-define-from-file=secrets.json
```

To build a release APK:
```bash
flutter build apk --dart-define-from-file=secrets.json
```

### VS Code Configuration
If you develop using VS Code, add the flag to your `launch.json` run configuration:
```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Bookery",
      "request": "launch",
      "type": "dart",
      "program": "lib/main.dart",
      "args": [
        "--dart-define-from-file=secrets.json"
      ]
    }
  ]
}
```

### Android Studio Configuration
In Android Studio / IntelliJ:
1. Open the run configuration menu (top-right next to the green run button).
2. Edit configurations.
3. In the **Additional run args** field, add:
   `--dart-define-from-file=secrets.json`
4. Apply and save.

