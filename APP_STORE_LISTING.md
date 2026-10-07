# App Store listing — copy-paste sheet

Everything App Store Connect asks for, in the order it asks. Fill it in at
https://appstoreconnect.apple.com/apps/6817792157 → the iOS app → version 1.0.

## App Information

| Field | Value |
|---|---|
| Name | Viswachakra Claims |
| Subtitle | Aarogyasri claim tracker for VCOH |
| Primary category | Medical |
| Secondary category | Business |
| Content rights | Does not contain, show, or access third-party content |
| Age rating | 4+ (answer **No** to every questionnaire item; "Unrestricted Web Access" = No) |
| Privacy Policy URL | https://viswachakra.vercel.app/privacy.html |

## Pricing and Availability

Free. Availability: India only is fine (the app is useless elsewhere).
Pre-orders: off.

## Version 1.0 → App Store page

**Promotional text** (170 chars, can change without a new build)

> Know what happened to every Aarogyasri claim after you filed it — queries, approvals, short-payments and payments — on your phone.

**Description**

> Viswachakra Claims is the claims desk of Viswa Chakra Orthopaedic Hospital, Machilipatnam, in your pocket. It follows every Dr. YSR Aarogyasri / NTR Vaidya Seva case from admission to payment and tells you the moment something needs your attention.
>
> ALERTS
> • Queries raised by the Trust, with the 7-day reply deadline counting down
> • Claims approved for less than you raised, with the exact shortfall
> • Treated patients whose claim has not been filed yet
> • Payments received, matched against what was approved
>
> CASES
> • Every case with its current status, patient, procedure and amounts
> • Search by patient name, case number or claim number
> • The full workflow history for each claim — who did what, and when
>
> SUMMARY
> • Paid, pending and short-paid totals for the month and the year
> • How long the Trust is taking to pay, and how that is trending
>
> Data is read from the hospital's own portal account and refreshed every hour. Sign-in is restricted to hospital staff; doctors see amounts, scribes see the work queue without them.
>
> This app is for the staff of Viswa Chakra Orthopaedic Hospital. It is not affiliated with the Dr. NTR Vaidya Seva Trust or the Government of Andhra Pradesh.

**Keywords** (100 chars max, comma-separated, no spaces after commas)

> aarogyasri,vaidya seva,claims,hospital,ntr,ysr,orthopaedic,machilipatnam,insurance,tracker

**Support URL**: https://viswachakra.vercel.app
**Marketing URL**: leave blank
**Copyright**: 2026 VVIS Technologies (OPC) Private Limited

**What's New in This Version**

> First release.

## Screenshots

Upload the 6.7"/6.9" set only; Apple scales it for the other sizes.
Files are in `store/screenshots/` (1290 × 2796 px, PNG):

1. `01-alerts.png` — Alerts tab: blocked claims and short-payments
2. `02-cases.png` — Cases tab: list with status chips
3. `03-case-detail.png` — a case with its workflow history
4. `04-summary.png` — Summary tab: paid / pending / short-paid

## App Privacy (the questionnaire)

**Does the app collect data?** Yes.

| Data type | Collected? | Linked to user | Used for tracking | Purpose |
|---|---|---|---|---|
| Contact Info → Email Address | Yes | Yes | No | App Functionality (sign-in) |
| Contact Info → Name | Yes | Yes | No | App Functionality (patient records shown to staff) |
| Contact Info → Phone Number | Yes | Yes | No | App Functionality (patient records shown to staff) |
| Health & Fitness → Health | Yes | Yes | No | App Functionality (procedure and claim records) |
| Identifiers → User ID | Yes | Yes | No | App Functionality |

Everything else (location, purchases, usage data, diagnostics, browsing, contacts, photos): **not collected**.
"Data used to track you": **none**.

## App Review Information

**Sign-in required**: Yes
- User name: `appreview@vvistech.com`
- Password: see `D:\viswachakra\_reviewer-account.txt` (not committed)

**Contact**: your first name, last name, phone (+91…) and email — Apple calls or emails this person if the review has a question.

**Notes** (paste as-is)

> This is an internal tool for the staff of one hospital in India; accounts are issued by the hospital, there is no public sign-up. The reviewer account has the "scribe" role, which hides rupee amounts by design — doctors see them, scribes do not. The data shown is the hospital's real government-insurance claim ledger, refreshed hourly from the state portal. Notifications are generated locally from that data; there is no push server.

**Attachment**: none needed.

## Version release

Choose **Manually release this version** — so that after approval you decide when it goes live.

## Before pressing "Add for Review"

- [ ] Build selected (the latest Codemagic upload — check the build number)
- [ ] Four screenshots uploaded
- [ ] Privacy policy URL responds (open it in a browser)
- [ ] App Privacy questionnaire published
- [ ] Reviewer account signs in on a real phone or TestFlight
- [ ] Export compliance: the app uses only standard HTTPS → answer **No** to "Does your app use encryption?" is wrong; answer **Yes**, then **Yes, it only uses exempt encryption (standard HTTPS)**. Or add `ITSAppUsesNonExemptEncryption = NO` to Info.plist to skip the question on every build.
