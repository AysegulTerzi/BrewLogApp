# brew_log

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,

## Building for iOS (via GitHub Actions)

Since this project is developed on Linux, we use **GitHub Actions** to build the iOS application (`.ipa`).

### How to Build
1.  Push your code to the `main` or `master` branch.
2.  Go to the **Actions** tab in your GitHub repository.
3.  Select the **Build iOS App** workflow.
4.  You can manually trigger it or it will run on push.

### Artifacts
Once the build is complete, you can download the `ios-build` artifact from the workflow run summary.

### Signing Setup (Required for physical devices)
To install the app on a real iPhone, you must set up the following **Secrets** in your GitHub Repository settings (`Settings` -> `Secrets and variables` -> `Actions`):

| Secret Name | Description |
|---|---|
| `P12_BASE64` | Your Apple Distribution Certificate (`.p12`) converted to Base64. |
| `P12_PASSWORD` | The password for your `.p12` file. |
| `BUILD_PROVISION_PROFILE_BASE64` | Your Provisioning Profile (`.mobileprovision`) converted to Base64. |
| `KEYCHAIN_PASSWORD` | A temporary password for the build keychain (can be any string). |

**To generate Base64 strings:**
```bash
base64 -i my_certificate.p12 | pbcopy  # macOS
base64 -w 0 my_certificate.p12          # Linux
```
