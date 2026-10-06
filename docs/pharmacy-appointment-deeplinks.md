# Pharmacy appointment booking deep links

Pharmacy-specific QR codes (shown in BSS) should open the appointment booking of
that pharmacy in the app (CAPO-9193). This page covers how pharmacy links work
today, how to mark a link for appointment booking, and how core_app reads it.

## How pharmacy links work today

The QR codes link to `https://ihreapotheken.de/apothekewahlen?apothekeId=<id>`.

- **App installed:** the link opens core_app, and `PharmacyPreselectionLink`
  reads the pharmacy with `url.split('apothekeId=').last`. Any parameter added
  after `apothekeId` breaks it, so `apothekeId` must stay last.
- **App not installed:** the page sends the IP address and pharmacy to the
  backend for the IP fallback, then redirects phones to an Adjust link built
  from `apothekeId` alone. Other parameters on the page URL are dropped:

  ```
  https://app.eu.adjust.com/1ibn9ah2?campaign=apothekewahlen&adgroup=<id>&redirect=<pharmacy page>
  ```

- **After install:** `AdjustTrackingService.setAttributionInfo` reads the
  pharmacy from the attribution's `adgroup`, falls back to `deferred_deeplink`
  (IP matching), and shows the pharmacy switch bottom sheet. It runs once per
  install.

## Marking a link for appointment booking

Until the website forwards a marker, use the Adjust link directly and put the
marker in the label:

```
https://bq95.eu.adj.st/?adj_t=1ibn9ah2&adj_campaign=apothekewahlen&adj_adgroup=<id>&adj_label=terminbuchung
```

| Part | Purpose |
| --- | --- |
| `adj_t=1ibn9ah2` | The core_app pharmacy preselection link. |
| `adj_campaign=apothekewahlen` | Keeps the existing campaign reporting. |
| `adj_adgroup=<id>` | The pharmacy, read by the existing preselection. |
| `adj_label=terminbuchung` | The appointment booking marker. |
| `adj_redirect=<URL-encoded page>` | Optional: where users without the app go instead of the store. |

**Verified on 6 October 2026** (Pixel 7a, core_app staging, fresh install after
opening the link): attribution returned `campaign=apothekewahlen`,
`adgroup=2163`, `clickLabel=terminbuchung`.

**Custom parameters did not arrive.** Adjust doesn't store them, so they are
never in attribution. The only other place they could appear is the deferred
deep link, and the deferred deep link callback didn't fire for this link,
probably because the link has no deep link target. Use the label (or
`creative`) for the marker.

## Reading it in core_app

```dart
final attribution = await Adjust.getAttribution();
final pharmacyId = int.tryParse(attribution.adgroup ?? '');
final opensBooking = attribution.clickLabel == 'terminbuchung';
```

`setAttributionInfo` already reads `adgroup`. Routing to the appointment
booking after the preselection, when `opensBooking` is true, is the remaining
core_app change. Two more cases from the ticket are not covered yet:
`AppointmentBookingLink` ignores booking links without `at` and `stid`, and a
pharmacy without appointment booking should end on the start page.

## When the app is already installed

The `bq95.eu.adj.st` link only opens core_app once the domain is set up:

- **iOS:** the domain's association file lists `QB8H6S7PA4.ihre.apotheken`
  (production only), but core_app's `Runner.entitlements` doesn't include
  `applinks:bq95.eu.adj.st`.
- **Android:** the domain's `assetlinks.json` returns 404 because no signing
  certificate fingerprints are set in Adjust, and core_app has no intent
  filter for the domain.

Once it opens the app, read the link with `AdjustLinkData`:

```dart
final adjustLink = AdjustLinkData.parse(link);
if (adjustLink?.linkToken != null) {
  Adjust.processDeeplink(AdjustDeeplink(link)); // reports the click to Adjust
  final pharmacyId = int.tryParse(adjustLink!.adgroup ?? '');
  final opensBooking = adjustLink.label == 'terminbuchung';
}
```

`DeepLinkNotifier` drops initial links containing `apothekewahlen`, so handle
Adjust links before that check.

## Testing

Follow [How to test Pharmacy Preselection with Adjust & DeeplinkSDK](https://sbentwicklung.atlassian.net/wiki/spaces/IA/pages/4795203585/How+to+test+Pharmacy+Preselection+with+Adjust+DeeplinkSDK).
Before every run, forget the device in Adjust's Testing Console and uninstall
the app. Then open the link, install, and grant analytics consent. Without a
link click before the install, attribution comes back as organic.

## Trying AdjustLinkData in the example app

The example app handles `adjustexample://` links and shows what each one parses
to: its path, parameters, label and adgroup.

```sh
# iOS simulator
xcrun simctl openurl booted "adjustexample://?adj_adgroup=2163&adj_label=terminbuchung"

# Android emulator
adb shell am start -a android.intent.action.VIEW -d "'adjustexample://?adj_adgroup=2163&adj_label=terminbuchung'"
```
