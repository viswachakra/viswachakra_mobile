# Shipping the iOS app to the App Store (from Windows, via Codemagic)

You don't own a Mac, so we build on **Codemagic's cloud Macs**. This app is already
iOS-ready (Flutter is cross-platform; the icon and display name are set). What's left is
account setup on Apple's side + connecting Codemagic. None of it needs a Mac.

**App identity (already set in this repo):**
- Bundle ID: `com.vvistech.viswachakraMobile`
- Display name: `Viswachakra Claims`

---

## Step 1 — Enroll in the Apple Developer Program  (~$99/year, ~1–2 days to approve)
1. Go to https://developer.apple.com/programs/enroll/
2. Enroll as **VVIS Tech** (organization — needs a D-U-N-S number, free to request) or as an individual.
3. Wait for Apple's approval email. You can't create apps until this is active.

## Step 2 — Register the App ID + create the app record
1. https://developer.apple.com/account → **Certificates, IDs & Profiles → Identifiers → +**
   → App IDs → App → Bundle ID (explicit): `com.vvistech.viswachakraMobile`.
2. https://appstoreconnect.apple.com → **My Apps → + → New App**
   - Platform: iOS · Name: **Viswachakra Claims** · Bundle ID: the one above · SKU: `viswachakra-mobile`.
3. Open the new app → note its **numeric Apple ID** (the number in the URL / App Information).
   Put that number into `codemagic.yaml` → `APP_STORE_APP_ID`.

## Step 3 — Create an App Store Connect API key (lets Codemagic sign + upload)
1. App Store Connect → **Users and Access → Integrations → App Store Connect API → +**
2. Access role: **App Manager**. Generate → download the **`.p8` file** (one-time download!).
3. Note the **Key ID** and the **Issuer ID** (shown on that page).

## Step 4 — Set up Codemagic
1. Sign up at https://codemagic.io with your GitHub, and add this repo
   (**viswachakra/viswachakra_mobile**).
2. **Teams → Integrations → App Store Connect → Connect** → upload the `.p8`, Key ID, Issuer ID.
   Name the integration **`codemagic`** (must match `integrations: app_store_connect:` in `codemagic.yaml`).
3. Codemagic will detect `codemagic.yaml` automatically. It handles signing certificates and
   provisioning profiles for you via that API key (no manual certs).

## Step 5 — Build
- Push to `main` (or click **Start new build** in Codemagic on the `ios-appstore` workflow).
- Codemagic builds the signed `.ipa` on a cloud Mac and uploads it to **TestFlight**.
- Install **TestFlight** on an iPhone, accept the invite, and test the app.

## Step 6 — Submit for review
- When happy: in App Store Connect fill the **store listing** (screenshots, description,
  privacy policy URL, category), attach the TestFlight build, and **Submit for Review**.
- Or set `submit_to_app_store: true` in `codemagic.yaml` to have Codemagic submit automatically.

---

### What you'll need to provide / do (summary)
| Item | Where | Notes |
|---|---|---|
| Apple Developer account | developer.apple.com | $99/yr, ~1–2 day approval |
| App record + Apple ID | App Store Connect | put the numeric ID in `codemagic.yaml` |
| ASC API key (.p8 + Key ID + Issuer ID) | App Store Connect → Integrations | upload to Codemagic |
| Codemagic account | codemagic.io | free tier, then paid Mac build minutes |
| Store listing + screenshots | App Store Connect | needed to submit for review |

### Notes / follow-ups
- **iOS background notifications** are not wired yet (they need `BGTaskScheduler` in `Info.plist`
  + `AppDelegate.swift`, plus a real device to test). Foreground/on-open notifications work on
  iOS today. This is a separate task once the app is on TestFlight.
- **Privacy:** the app reads claim data (incl. patient info) behind login — you'll need a
  **privacy policy URL** for App Store review, and to fill Apple's "App Privacy" data-collection form.
