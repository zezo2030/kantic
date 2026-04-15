# Apple Pay setup checklist (Moyasar + Flutter)

This document covers the iOS-side prerequisites required to enable Apple Pay in `kantic`.

## 1) Apple Developer configuration

1. Create an Apple Merchant ID (example: `merchant.com.kantic.app`).
2. Enable Apple Pay for the app identifier used by this project.
3. Ensure the provisioning profile includes Apple Pay capability.

## 2) Xcode project configuration

1. Open `ios/Runner.xcworkspace` in Xcode.
2. Select `Runner` target.
3. Go to **Signing & Capabilities**.
4. Add capability: **Apple Pay**.
5. Select the same Merchant ID from Apple Developer.
6. Rebuild the project after capability update.

## 3) App-level configuration values

These values are consumed from `ApiConstants`:

- `moyasarApplePayMerchantId`
- `moyasarApplePayLabel`

Recommended runtime override using `--dart-define`:

- `MOYASAR_APPLE_PAY_MERCHANT_ID`
- `MOYASAR_APPLE_PAY_LABEL`

## 4) Testing notes

1. Use a real iOS device (Apple Pay is limited in simulator scenarios).
2. Test success, cancel, and failure paths.
3. Validate backend payment confirmation still receives `moyasarPaymentId`.
