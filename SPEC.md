# Notchmark — Build Specification

> Portfolio app 57, batch pending. This document is the complete brief for
> building this application. Read all of it before writing any code. Anything
> not specified here is your decision, but must stay consistent with section 3.

**One-line positioning:** Every notch pays down the price.

| Field | Value |
| --- | --- |
| Product name | Notchmark |
| Bundle identifier | `com.travelhel.per` |
| Domain | https://travelhel-per.pro |
| Contact URL | https://travelhel-per.pro/contact-us |
| Deployment target | iOS 17.0 |
| Swift version | 6.2, strict concurrency `complete` |
| Devices | iPhone and iPad, portrait |
| Interface style | Light |
| Asset prefix | `ntm_` |
| User-Agent | `Notchmark/1.0 (iOS; +https://travelhel-per.pro)` |

---

## 1. Non-negotiable constraints

1. **No CocoaPods.** Dependencies come from Swift Package Manager, a local
   in-repo package, a vendored source folder, or nothing at all — per section 3.
2. **No shared code with other portfolio apps.** Business rules are re-implemented
   here under this app's own type names.
3. **All code, identifiers, comments, UI copy and the README are in English.**
4. **No launch gate, no WebView shell, no remote configuration, no analytics.**
5. **No CI files.** No `bitrise.yml`, no `Scripts/`, no `metadata/` folder.
6. **Assets are AI-generated.** No stock photography. SF Symbols may support
   small affordances but must never be the primary iconography.
7. **The app must build clean** with
   `xcodegen generate && xcodebuild -scheme Notchmark -destination 'generic/platform=iOS' build`.
8. **Nothing may echo another app in this batch** in naming, layout or visuals.
9. **This is not a calorie meal-slot tracker** unless family is `food_tracker`.
   Do not invent food logging to fill the brief.

---

## 2. Product core

The product is offline-first. No account, no sign-in, no ads, no in-app purchase,
no analytics SDK, no remote config. All user data stays on the device.

A notch pays down the price.

### 2.1 User flow

1. Add an Article: name, purchase price, and either a manual per-notch share or a target use-count that auto-divides the price into shares; optionally scan a receipt's printed price to prefill it.
2. Rail shows every Article as an accordion row: a shrinking balance bar and its phase word, Amortizing or Profit.
3. Tap Notch on a row to log a use — the balance bar carves down by one share and the notch appends to that row's inline history; no push, no separate Detail screen.
4. The instant a balance reaches zero the row writes its Mark (notch index and date), flips to Profit, and animates onto the Board.
5. Open Board, a sheet, to see only Marked Articles ranked by profit-per-notch — an Amortizing Article never appears there no matter how cheap its notches already look.
6. Board also shows a Forecast strip for still-Amortizing Articles: notches remaining at their current pace, so the user sees how close each one is to its Mark.
7. Settings: currency, default share method (manual vs. price divided by target uses), export an Article's notch history as CSV.

### 2.2 Essential behaviour

- Article model: purchase price, per-notch share (manual or auto = price / target uses), running balance.
- One-tap Notch action per row that decrements the balance and appends a timestamped, immutable notch entry.
- Deterministic Amortizing→Profit transition: writes an immutable Mark (notch index, date) the instant the balance crosses zero, never recomputed even if the share is edited afterward.
- Board ranking restricted to Marked Articles only, sorted by profit-per-notch, enforced at the query level so an Amortizing Article cannot structurally appear.
- Forecast strip computing notches-to-Mark from a rolling average of an Article's notch intervals.
- Optional price-tag or receipt text scan to prefill purchase price on Article creation.
- Local CSV export of an Article's full notch history via the share sheet.
- No accounts, no network sync — every Article is its own JSON document on device.

---

## 3. Uniqueness assignment for Notchmark

| Axis | Assigned value |
| --- | --- |
| Architecture | **Notch ADT fold (Amortizing | Breakeven | Profit; the ledger is a fold over an Article's notches)** |
| UI approach | **SwiftUI hosting a UIView notch-rail (CAShapeLayer teeth carve inward per notch; UITapGestureRecognizer commits the carve)** |
| Naming convention | **Actuarial / amortization lexicon** |
| File organization | **By notch role (Article, Notch, Rail, Mark, Board)** |
| Dependency strategy | **None (zero external dependencies)** |
| Design direction | **Actuary's desk (ruled foolscap, brass paper-clip, carbon-copy violet, ink-stamp red)** |
| Typography | **American Typewriter** |
| Navigation pattern | **Rail-locked chrome (the notch rail never leaves; Board and Settings arrive as sheets)** |
| AI art style | **Steel engraving of a Victorian actuary's desk (ledger page, brass paper-clip, carbon flimsy, red ink stamp)** |
| Functional twist | **Notch-to-breakeven ledger (an Amortizing Article cannot rank until it writes a Mark)** |
| Persistence | **JSON documents (one file per aggregate)** |
| Screen composition | see 3.6 |

### 3.0 Product concept

This is the product the contracts below are assigned to. Do not substitute another.

**Family** — cost_per_use

**Core** — A notch pays down the price.

**Audience** — People who buy an $80 gadget, use it twice, and want the exact ugly number — and the quiet satisfaction of a $6 tool finally outranking it.

**User flow**

1. Add an Article: name, purchase price, and either a manual per-notch share or a target use-count that auto-divides the price into shares; optionally scan a receipt's printed price to prefill it.
2. Rail shows every Article as an accordion row: a shrinking balance bar and its phase word, Amortizing or Profit.
3. Tap Notch on a row to log a use — the balance bar carves down by one share and the notch appends to that row's inline history; no push, no separate Detail screen.
4. The instant a balance reaches zero the row writes its Mark (notch index and date), flips to Profit, and animates onto the Board.
5. Open Board, a sheet, to see only Marked Articles ranked by profit-per-notch — an Amortizing Article never appears there no matter how cheap its notches already look.
6. Board also shows a Forecast strip for still-Amortizing Articles: notches remaining at their current pace, so the user sees how close each one is to its Mark.
7. Settings: currency, default share method (manual vs. price divided by target uses), export an Article's notch history as CSV.

**Essential features**

- Article model: purchase price, per-notch share (manual or auto = price / target uses), running balance.
- One-tap Notch action per row that decrements the balance and appends a timestamped, immutable notch entry.
- Deterministic Amortizing→Profit transition: writes an immutable Mark (notch index, date) the instant the balance crosses zero, never recomputed even if the share is edited afterward.
- Board ranking restricted to Marked Articles only, sorted by profit-per-notch, enforced at the query level so an Amortizing Article cannot structurally appear.
- Forecast strip computing notches-to-Mark from a rolling average of an Article's notch intervals.
- Optional price-tag or receipt text scan to prefill purchase price on Article creation.
- Local CSV export of an Article's full notch history via the share sheet.
- No accounts, no network sync — every Article is its own JSON document on device.

**Twist** — Notch-to-breakeven ledger. Every Article starts Amortizing

**Why this is not a repeat** — cost_per_use is unused anywhere in the 41-app history; the closest neighbor, subscription_load (Kentledge), amortizes a recurring monthly charge by cutting it, while this amortizes a one-time purchase by counting uses, with opposite arithmetic (a balance falling per notch, not a monthlyEquivalent being freed) and no beam-of-this-month view. It is not the forbidden metric_capacity shape: there is no today-number-vs-capacity ratio, no calendar, no charts hero — the mechanic is a one-way Amortizing→Profit state transition gated by an immutable Mark that structurally excludes unpaid Articles from the ranking, the same class of hard invariant as Nisihold's brittle-lead gate or Kentledge's seat-the-credit rule, but applied to a new domain (owned durable goods) with a new home verb (notch) and a new architecture (Notch ADT fold). All eight unique-catalog axes — architecture, ui, naming, organization, design, navigation, art, twist — are freshly invented strings, checked against the full occupied list since those catalogs are exhausted.

### 3.0a Craft from the shipped portfolio

Full craft is in KNOWLEDGE.md. Follow it. Do not copy type names or layouts.
- Home: Library with relative A+–F grades.
- Invariant: cpu = (price−disposal)/max(uses,1). Efficiency vs ≥5 peers. Percentile → A+…F. Else insufficientData. Age ≥ 7 days.
- Never: Grades are relative to this library.

### 3.1 Architecture contract

Every `Article` aggregate owns an ordered array of `NotchEntry` values and, once written, an optional `BreakevenMark`. Phase is never a stored enum picked by hand — it is produced by folding `AmortizationLedger.reduce(over:)` across the notch array from a starting `NotchPhase.amortizing(balance: purchasePrice)`. Each `NotchEntry` subtracts one `perNotchShare` from the running balance inside the fold; the instant a subtraction takes the balance to or below zero the fold emits `.breakeven(BreakevenMark(index:, date:))`, and the caller persists that `Mark` back onto the `Article`. From that point forward the fold short-circuits: any notch at or after the stored `Mark.index` folds straight to `.profit(mark:)` without touching balance arithmetic again, so editing `perNotchShare` later can change where a future fold would cross zero but can never rewrite a `Mark` that already exists. `Rail` and `Board` both read phase only through this fold — no view compares balances or dates on its own.

Put a short comment block at the top of each principal type stating the role it
plays in this architecture. The README must justify the pattern for this product.

### 3.2 UI contract

Each Rail row is a `NotchRailRepresentable` (`UIViewRepresentable`) wrapping `NotchRailView`, a `UIView` subclass that draws the balance bar and its teeth with `CAShapeLayer`: one tooth path per remaining share, redrawn by mutating the layer's path inside a `CATransaction` rather than replacing the view. A `UITapGestureRecognizer` on the carve button commits a notch and calls back into SwiftUI through a closure, never through target-action into a view controller, so the accordion row's expand/collapse state stays in SwiftUI `@State`. `RailView` lays these representables out in a plain `List`; the tooth-carving cut is driven by Core Animation while the inline notch-history expansion is a SwiftUI height change. `BoardView` and `SettingsView` are pure SwiftUI with no representables.

### 3.3 Naming contract

Convention: Actuarial / amortization lexicon.

Examples to follow: `Article`, `NotchEntry`, `BreakevenMark`, `AmortizationLedger`

### 3.4 Dependency contract

Zero external dependencies: no Swift Package Manager entries, no CocoaPods, no vendored sources. Persistence is hand-written `Codable` JSON via `FileManager`, scanning uses the system `VisionKit` framework, and every drawn shape (balance bar, notch teeth, forecast strip) is `CAShapeLayer`/`Path`, never a charting library. `project.yml` carries no `packages:` key at all.

### 3.5 Navigation contract

There is no tab bar. `RailView` is the single always-on root; its toolbar carries exactly two glyphs — a ledger icon presenting `BoardView` and a gear presenting `SettingsView`, both as `.sheet`. A '+' in the same toolbar presents `AddArticleSheet`. None of the three ever push onto a `NavigationStack` — Rail has no stack to push onto — and none is reachable from inside another sheet, so Rail is always exactly one tap away. Dismissal is the sheet's own swipe-down or a Close button; there is no Detail screen to push into from a row, since notch history expands inline in place.

### 3.6 Screen composition contract

Rail is the single root: an accordion list of Articles, each row a shrinking balance bar. Tapping a row expands it inline to its notch history — no push, no separate Detail. Notch is one tap on the row's carve button. Board and Settings arrive as sheets. Physical screens: Rail, Board, Settings, AddArticleSheet.

Rail (root, always visible): an accordion `List` of Article rows filling the screen edge to edge; each row is a `NotchRailView` balance bar plus its phase word (Amortizing/Profit), a Notch carve button, and, when expanded, an inline strip of that Article's notch history — no separate Detail screen exists. Board (sheet): a ranked list of only Marked Articles sorted by profit-per-notch, each row showing the Mark's date and index, with a Forecast strip above the list showing still-Amortizing Articles and their rolling-average notches-remaining. Settings (sheet): currency picker, default share method (manual vs. price-divided-by-target-uses) segmented control, and a per-Article CSV export row list backed by the share sheet. AddArticleSheet (sheet, from Rail's '+'): name, purchase price, share method toggle with its manual-share or target-uses field, and an optional 'Scan a price tag' capture button.

Section 5 lists the logical functions that must exist. This section decides how
they are grouped into actual screens. Where the two disagree, this section wins.

---

## 4. Target file organization

Scheme: **By notch role (Article, Notch, Rail, Mark, Board)**

```
Notchmark/
  App/
    NotchmarkApp.swift
  Article/
    Article.swift
    ShareMethod.swift
    ArticleStore.swift
  Notch/
    NotchEntry.swift
  Mark/
    BreakevenMark.swift
    AmortizationLedger.swift
  Rail/
    RailView.swift
    NotchRailView.swift
    NotchRailRepresentable.swift
    RailRowView.swift
    AddArticleSheet.swift
    PriceScannerView.swift
  Board/
    BoardView.swift
    ForecastStrip.swift
    ProfitPerNotchRanking.swift
  Settings/
    SettingsView.swift
    CSVExporter.swift
  Support/
    CurrencyFormatting.swift
    DayKey.swift
  Assets.xcassets/
```

Adapt the leaf files to the architecture, but the top-level shape is fixed. Do
not create a `Utils/` or `Helpers/` dumping ground.

---

## 5. Screens

Build the screens named in section 3.6. The labels below are logical;
actual type names follow this app's naming convention.

### 5.1 Onboarding
Three to four pages. Explains the product, writes initial settings, sets a
completion flag. Skip still writes sensible defaults. Re-runnable from Settings.

### 5.2 Library
A first-class screen for **Library**. Must render empty, populated and error states.

### 5.3 Ledger
A first-class screen for **Ledger**. Must render empty, populated and error states.

### 5.4 Insights
A first-class screen for **Insights**. Must render empty, populated and error states.

### 5.5 Settings
A first-class screen for **Settings**. Must render empty, populated and error states.

### 5.6 Settings
Holds: re-run onboarding, reset all data (confirmed), and the contact link to
the domain contact-us URL.

### 5.7 Twist screen
See section 12. The twist needs at least one screen of its own plus a surface on the home screen.

---

## 6. Domain model

Minimum entities, named per this app's convention:

- **OwnedItem** — named per this app's convention.
- **UseLog** — named per this app's convention.
- Plus whatever the twist in section 12 requires.


---

## 7. Design system

Direction: **Actuary's desk (ruled foolscap, brass paper-clip, carbon-copy violet, ink-stamp red)**

### 7.1 Palette

| Token | Hex | Use |
| --- | --- | --- |
| `background` | `#F6F1E3` | Screen background |
| `surface` | `#ECE3CB` | Cards, rows, sheets |
| `ink` | `#241C12` | Primary text and icons |
| `accent` | `#A32E2A` | Primary action, key figure, progress fill |
| `muted` | `#8B7A55` | Secondary text, dividers, disabled |

Define these as named colours in `Assets.xcassets` and reach them through one
typed accessor. Never hard-code a hex string anywhere else.

### 7.2 Typography

Family: **American Typewriter**

American Typewriter across a five-step scale reached through one `Font.ledger(_:)` accessor: `.heading` (28pt semibold, screen titles and the Notchmark wordmark), `.articleTitle` (20pt regular, row names), `.stampNumeral` (17pt regular, tabular-figure balances and prices — American Typewriter's fixed-pitch strike reads like a typed ledger line), `.body` (15pt regular, labels and settings rows), `.footnote` (12pt regular, notch timestamps and history entries). No other font is referenced anywhere in the app.

Define a type scale of at most six steps behind one accessor and use only those
steps. Text stays legible at the largest Dynamic Type size.

### 7.3 Layout

- One base spacing unit (4 or 8 pt); only multiples of it.
- One corner radius value applied consistently, or deliberately none if the
  design direction calls for hard edges.
- Every interactive element is at least 44x44 pt.

---

## 8. UI and UX quality bar

Every item here is a defect if it is missing. Do not treat this as advice.

**Layout**

- Respect safe areas on every screen. Nothing sits under the notch, the Dynamic
  Island or the home indicator.
- The app is portrait-only on iPhone. Lock it in the Info settings and do not
  write rotation-dependent layout.
- No layout shift when asynchronous data arrives. Reserve the final size up
  front, or use a redacted placeholder of the same dimensions.
- Long product names must truncate gracefully, never push a number off screen.
  Numbers win; names truncate.
- Minimum tap target 44x44 pt for every interactive element, including small
  icon buttons and list accessories.
- Pick one base spacing unit and use only multiples of it. No arbitrary values.

**Keyboard**

- The grams field uses `.decimalPad`, and the decimal separator matches the
  user's locale.
- Content scrolls out from under the keyboard. The focused field is always
  visible.
- Tapping outside the field, or scrolling, dismisses the keyboard.
- Validate on the fly: reject negative and non-numeric input rather than
  crashing the parser later.

**Loading and state**

- Every asynchronous operation has a visible loading state.
- Guard against the spinner flash: if the work finishes in under 150 ms, do not
  show a spinner at all.
- Every list has a designed empty state containing a primary action, not just a
  sentence of text.
- Every error state offers a retry, and states plainly what failed.
- Disable the primary button while its action is in flight so it cannot be
  double-tapped into a double push or a duplicate entry.

**Typography and accessibility**

- All text scales with Dynamic Type. Verify at the largest accessibility size:
  nothing may clip or overlap.
- Every icon-only control has an `accessibilityLabel`. Decorative images are
  marked as decorative so VoiceOver skips them.
- Colour is never the only signal. Pair it with a label, a shape or an icon.
- Honour Reduce Motion: replace movement-heavy transitions with a fade.
- Meet contrast requirements against the palette in section 7. Check the muted
  colour against the background specifically; that is where these palettes fail.

**Formatting**

- Format every number with `NumberFormatter`, never string interpolation. Group
  separators and decimal separators must follow the locale.
- Energy is shown as a whole number of kcal. Macros are shown with at most one
  decimal place.
- Round only at the point of display. Stored values keep full precision.
- Day boundaries use `Calendar.current.startOfDay(for:)` in the user's current
  time zone. Handle the day changing while the app is open, and handle the
  short and long days that daylight saving produces.
- Unknown macro values render as a dash or the word "unknown", never as 0.

**Motion and feedback**

- One haptic on a successful commit (a food logged, a target saved). No haptic
  on navigation.
- Animations are short (0.2 to 0.35 s) and use a single shared easing curve.
- Nothing animates on first appearance of a screen except an intentional entry
  transition.

**Navigation**

- Back always works and never loses entered data without asking.
- A destructive action (delete a log row, reset all data) is confirmed.
- Modal sheets can always be dismissed; there is no dead end.
- Deep state is restorable: relaunching returns the user to a sane screen.


---

## 9. Concurrency

The target builds with Swift 6.2 and `SWIFT_STRICT_CONCURRENCY = complete`. It
must compile with **zero concurrency warnings**. Warnings here become crashes
later, so they are not negotiable.

- All UI types are `@MainActor`. Annotate the type, not individual methods.
- Any value crossing an actor boundary is `Sendable`. Prefer immutable structs
  of primitives.
- Do not use `@unchecked Sendable`. If it is genuinely unavoidable, it needs a
  comment explaining what guarantees the safety.
- No mutable global state. No `static var` that is written after launch.
- Networking and storage APIs are `async` and honour cancellation. When the
  search query changes, cancel the in-flight task; do not let a stale response
  overwrite fresh results.
- Use structured concurrency. Avoid `Task.detached` unless there is a stated
  reason. Never fire a `Task` that outlives the view without owning it.
- Never use `DispatchQueue.main.asyncAfter` to paper over an ordering problem.
  Fix the ordering.
- `Timer` and notification observers are invalidated in `deinit` or on
  disappear.


---

## 10. Persistence engineering

Chosen technology: **JSON documents (one file per aggregate)**

One JSON file per `Article` aggregate, written by `ArticleStore` to `Application Support/Articles/<uuid>.json` through `FileManager`, atomically (write to a temp file, then rename). Each document is the whole aggregate: purchase price, share method, per-notch share, the append-only `notches` array, and the optional `mark`. Notching only ever appends to `notches` and re-serializes the same file; it never rewrites an existing entry or the `mark` once present. `Settings.json` is a second, singular document for currency and default share method. There is no database, no Core Data stack, and no external persistence library.

This app persists to **files on disk**. The following are mandatory.

- Write atomically. Either `Data.write(to:options: .atomic)` or write to a
  temporary file and `FileManager.replaceItemAt`. A non-atomic write that is
  interrupted leaves a truncated file and the app will not launch.
- Create the containing directory with
  `withIntermediateDirectories: true` before the first write.
- Every document carries a `schemaVersion` field from version 1, and the decoder
  switches on it.
- Decoding failure must be recoverable: keep the previous good file as a
  `.backup`, fall back to it, and if that also fails start from empty state and
  tell the user. Never crash on a corrupt file.
- All file IO happens off the main thread. The main thread never blocks on disk.
- Debounce writes during rapid edits, but force a flush when `scenePhase`
  becomes `.inactive` or `.background`, and after any destructive action.
- Exclude caches from backup with `URLResourceValues.isExcludedFromBackup` where
  appropriate; user data belongs in Application Support and should be backed up.
- Keep an explicit in-memory source of truth and treat the file as a projection
  of it, so a failed write never leaves the UI showing data that does not exist.


Regardless of technology:

- One seam between domain logic and storage; the UI never touches storage types.
- Writes survive a force-quit. Do not rely on `applicationWillTerminate`.
- Provide `resetAllData()`, used by tests and reachable from Settings.

---

## 11. Networking

- One client type owns both Open Food Facts endpoints.
- Set `User-Agent` on every request. Open Food Facts throttles clients that do
  not identify themselves.
- 15 second timeout. One retry on a transient transport failure, then a typed
  error. Do not retry a 404.
- Cancel the in-flight search when the query changes. Debounce input by roughly
  300 ms.
- Decode into DTO types that mirror the JSON exactly, then map to domain types.
  Never decode straight into your domain model.
- Open Food Facts data is user-contributed and frequently incomplete. Every
  numeric field is optional. A product with no energy value is a normal case
  that the UI must present, not an error.
- Some numeric fields arrive as strings. The decoder must accept both a number
  and a numeric string for every nutriment.
- `status` of `0` in the product response means not found. Map it to a distinct
  error case so the UI can offer manual entry.
- Never crash on malformed JSON. A decoding failure is a handled error.
- Cache every resolved product locally on success, so the app degrades to a
  working offline catalogue.


Set `User-Agent: Notchmark/1.0 (iOS; +https://travelhel-per.pro)` on every request. Never reuse another app's string.
No required remote catalog. Network only if this product actually needs it.

---

## 11b. App Store readiness

The app must be submittable without further work.

- `PrivacyInfo.xcprivacy` in the target, declaring the UserDefaults access API
  reason `CA92.1` and the file timestamp reason `C617.1`, with
  `NSPrivacyTracking` false and no collected data types.
- `INFOPLIST_KEY_ITSAppUsesNonExemptEncryption = NO` in the pbxproj so TestFlight
  does not sit on Missing Compliance.
- `NSCameraUsageDescription` written specifically for this app. Generic strings
  get rejected.
- `LSApplicationCategoryType` of `public.app-category.healthcare-fitness`.
- Portrait only, iPhone and iPad (`TARGETED_DEVICE_FAMILY = "1,2"`).
- No account, no sign-in, no delete-account flow, no in-app purchase, no ads, no
  user-generated content, and therefore no report or block UI.
- App Tracking Transparency is never invoked.
- The camera is the only sensitive permission requested.
- The app must not present itself as medical advice. It is a personal food log.
- Nutrition data is credited to Open Food Facts, a public database.


Ignore the food-log and Open Food Facts lines above when they conflict with this
family. Category for this app is `public.app-category.lifestyle`. Camera permission only if the
product actually captures.

Project settings that follow from the above:

```yaml
INFOPLIST_KEY_UIUserInterfaceStyle: Light
INFOPLIST_KEY_UISupportedInterfaceOrientations: UIInterfaceOrientationPortrait
INFOPLIST_KEY_NSCameraUsageDescription: Notchmark uses the camera only to read a receipt or price tag's printed number and prefill an Article's purchase price.
INFOPLIST_KEY_ITSAppUsesNonExemptEncryption: NO
INFOPLIST_KEY_LSApplicationCategoryType: public.app-category.lifestyle
TARGETED_DEVICE_FAMILY: "1,2"
SWIFT_STRICT_CONCURRENCY: complete
```

---

## 12. Functional twist: Notch-to-breakeven ledger (an Amortizing Article cannot rank until it writes a Mark)

Every Article is born Amortizing: its purchase price is its balance, and the only way that balance moves is `NotchEntry` by `NotchEntry`, each one subtracting a fixed per-notch share — never a percentage, never a date-based decay. The instant a notch carries the balance to or past zero the Article writes a `BreakevenMark` holding the exact notch index and date, and that write is one-way: editing `perNotchShare` afterward can change how future Articles amortize but cannot touch a `Mark` that already exists. Every notch logged after the `Mark` moves the Article into Profit, and `Board`'s query is written so it can only ever select Articles carrying a `Mark` — a still-Amortizing Article is not filtered out of the ranking by a check, it is structurally absent from the query that produces it. The Forecast strip mirrors this for the Amortizing side: it estimates notches-to-Mark from a rolling average of that Article's own notch intervals, so the user sees how close the $6 tool is to outranking the $80 gadget without ever letting it jump the fence early.

This is the app's marketed differentiator. It must be:

- visible on the home screen, not buried in settings;
- backed by real persisted data, not a cosmetic flourish;
- covered by at least one unit test;
- described in the README as the reason a user would pick this app.

---

## 13. AI-generated assets

Art style: **Steel engraving of a Victorian actuary's desk (ledger page, brass paper-clip, carbon flimsy, red ink stamp)**

Base prompt, reused and extended for every asset:

```
Monochrome steel-engraving illustration in the style of a nineteenth-century actuary's desk plate: fine cross-hatched linework on ruled foolscap ledger paper, a glinting brass paper-clip pinning a corner, a violet carbon-copy flimsy peeking from beneath, and one red ink-stamp mark for accent. Restrained, printmaking-era detail and tonal range — no photographic textures, no soft gradients, no modern flat-icon shapes.
```

All 13 images below are required. Generate each one, export
as PNG, and add it to `Assets.xcassets` as its own image set named exactly as
given. Every name carries the `ntm_` prefix.

### 13.1 App icon rules (strict)

The icon is rejected by App Store Connect if any of these are wrong:

- Exactly **1024 x 1024 px**.
- **No alpha channel.**
- sRGB colour profile, 8 bits per channel, PNG.
- **No text and no words** in the artwork.
- **No rounded corners and no built-in mask.**
- The subject stays inside the middle 80%.

### 13.2 Full asset list

| # | Image set | Size (px) | Alpha | Purpose |
| --- | --- | --- | --- | --- |
| 1 | `ntm_AppIcon` | 1024x1024 | **NO** | App Store icon. NO alpha channel, NO transparency, NO text, NO rounded corners, NO drop shadow outside the canvas. |
| 2 | `ntm_Splash` | 1290x2796 | allowed | Launch background. The middle third must stay quiet so the wordmark reads on top. |
| 3 | `ntm_Onboarding1` | 1024x1536 | allowed | Onboarding page 1 illustration: what the app is for. |
| 4 | `ntm_Onboarding2` | 1024x1536 | allowed | Onboarding page 2 illustration: the main verb. |
| 5 | `ntm_Onboarding3` | 1024x1536 | allowed | Onboarding page 3 illustration: why they stay. |
| 6 | `ntm_EmptyHome` | 1024x1024 | allowed | Empty state: the home screen has nothing yet. Calm and inviting, never sad. |
| 7 | `ntm_EmptyList` | 1024x1024 | allowed | Empty state: a secondary list has no rows. |
| 8 | `ntm_CardBackdrop` | 1200x800 | allowed | Backdrop art for a primary card. Low contrast so text stays readable. |
| 9 | `ntm_ControlFace` | 512x512 | allowed | Custom control artwork used for the primary interactive element. |
| 10 | `ntm_TwistHero` | 1024x1024 | allowed | Hero art for the 'Notch-to-breakeven ledger (an Amortizing Article cannot rank until it writes a Mark)' feature screen. |
| 11 | `ntm_SuccessMark` | 512x512 | allowed | Shown briefly when the primary action succeeds. |
| 12 | `ntm_HeaderDecor` | 1200x600 | allowed | Decorative header accent on the main screen. |
| 13 | `ntm_MarkStamp` | 1024x1024 | allowed | Steel-engraving icon of a round red ink stamp mid-press over a ledger line, used wherever the UI needs to represent a written Breakeven Mark distinctly from an ordinary notch. |

### Prompt per asset

**`ntm_AppIcon`** — 1024x1024

```
Steel-engraving emblem, centred and filling the canvas edge to edge: a single ledger-page corner pierced by a brass paper-clip, one small red ink-stamp notch-mark beside it. Monochrome engraved linework on cream. No text, no lettering, no rounded corners, no drop shadow, no alpha channel.
```

**`ntm_Splash`** — 1290x2796

```
Vertical steel-engraving composition of a Victorian actuary's desk seen from above: ruled foolscap pages, a brass paper-clip, a violet carbon flimsy at the edges, framing a calm uncluttered centre band where the Notchmark wordmark will sit.
```

**`ntm_Onboarding1`** — 1024x1536

```
Steel-engraving illustration of a single owned object — a hand tool sitting beside a price tag on ruled ledger paper — the two things this app tracks: what you bought and what it cost.
```

**`ntm_Onboarding2`** — 1024x1536

```
Steel-engraving illustration of a hand pressing a carve into a ledger balance bar, one tooth cutting inward, mid-gesture — the app's one verb, notching a use.
```

**`ntm_Onboarding3`** — 1024x1536

```
Steel-engraving illustration of a ledger page stamped with a red ink Mark at its foot, carbon-copy violet showing through beneath — the moment an Article crosses into Profit.
```

**`ntm_EmptyHome`** — 1024x1024

```
Steel-engraving of a blank ruled foolscap ledger page, an empty brass paper-clip resting at the top corner, waiting for its first entry — calm, not sad.
```

**`ntm_EmptyList`** — 1024x1024

```
Steel-engraving of an empty ledger column with faint ruled lines and no entries yet, a brass paper-clip at rest beside it.
```

**`ntm_CardBackdrop`** — 1200x800

```
Low-contrast steel-engraving backdrop of faint ruled foolscap lines and a soft carbon-violet wash, quiet enough to sit behind readable card text.
```

**`ntm_ControlFace`** — 512x512

```
Steel-engraving close-up of a single brass paper-clip face, the app's one physical control motif, rendered as a dial-like emblem.
```

**`ntm_TwistHero`** — 1024x1024

```
Steel-engraving hero art for the Notch-to-breakeven ledger: a balance bar carved down to its last tooth, a red ink-stamp Mark landing at that instant, carbon-violet flimsy beneath.
```

**`ntm_SuccessMark`** — 512x512

```
Small steel-engraving red ink-stamp mark, freshly pressed, confirming a committed notch or a written Mark.
```

**`ntm_HeaderDecor`** — 1200x600

```
Wide steel-engraving ornamental band of ruled ledger lines, a thin brass rule, and a faint carbon-violet edge, for a screen header.
```

**`ntm_MarkStamp`** — 1024x1024

```
Steel-engraving icon of a round red ink stamp mid-press over a ledger line, used wherever the UI needs to represent a written Breakeven Mark distinctly from an ordinary notch.
```


### 13.3 Asset rules

- Assets must be semantically different from each other.
- Record the exact prompt used for every asset in the README.
- SF Symbols are permitted only for close, chevron, share and similar system
  affordances.

Scanner frames, reticles, background textures, and anything else that needs a guaranteed transparent region or a guaranteed seamless join are drawn in SwiftUI via `Path` or `Shape`. The image generator is not used for these elements: it guarantees neither an alpha channel nor a seamless tile.

---

## 14. Demo data

Seed a small local demo dataset for this family's entities so Simulator
screenshots are not empty. The same seed must mark onboarding complete and
fill the primary surface — otherwise `-ReviewScreen` never fires. Never seed
on a physical device. Guard with `#if targetEnvironment(simulator)` and
`ntm.demo.v1`.

---

## 16. Anti-patterns

The following will fail review:

- `try!`, `as!`, or force-unwrapping anything derived from the network, the
  database or a file.
- `fatalError` anywhere reachable at runtime. It is acceptable only for a
  programmer error in an initialiser that cannot fail in practice, and needs a
  comment.
- Swallowing an error with an empty `catch`.
- `print` used as production logging.
- A hard-coded hex colour outside the single colour accessor.
- A hard-coded font name outside the single typography accessor.
- An SF Symbol used as primary iconography.
- Storing a value that can be computed (day totals, remaining budget, macro
  percentages).
- Blocking the main thread on disk or network work.
- `UIScreen.main` for sizing. Use the geometry the layout system gives you.
- Index positions used as list identity. Identity is a stable identifier.
- A view that reaches into the persistence layer directly, bypassing the
  architecture's designated seam.
- Business logic inside a `View` body or a `UIViewController` method, when the
  assigned architecture places it elsewhere.
- Copying a source file from another app in this batch.


---

## 17. Tests

Add a unit test target `NotchmarkTests` covering at minimum:

1. The core domain invariant of this family (the thing that would be wrong if
   the calculator, decay, crate, or log lied).
2. Empty, populated and invalid input paths for the primary verb.
3. The section 12 twist logic.
4. One architecture-specific test proving the pattern holds.
5. A persistence round-trip: write, relaunch-equivalent reload, verify.
6. Parse `ProcessInfo.processInfo.arguments` once after onboarding. 
   `-ReviewScreen today|log|goals` switches the running app's live navigation.
   Cover that parser with a unit test. Do not host a `View` in the test.

---

## 18. README.md

Write `README.md` at the app folder root covering:

1. What the app does and who it is for.
2. The architecture used and **why** it suits this product.
3. The unique feature added and how it works.
4. The AI art style and the exact prompt used for every asset.
5. How this app differs from others in the batch.
6. Build instructions.

---

## 19. Definition of done

**Build**
- [ ] `xcodegen generate` succeeds.
- [ ] `xcodebuild -scheme Notchmark -destination 'generic/platform=iOS' build` succeeds.
- [ ] Zero new compiler warnings.
- [ ] Strict concurrency `complete` compiles clean.
- [ ] Test target passes.

**Function**
- [ ] Onboarding to first successful primary action works on a clean install.
- [ ] Every screen in section 3.6 exists and handles empty / filled / error.
- [ ] Reset and contact link live in Settings.
- [ ] Force-quitting immediately after a write loses nothing.

**Uniqueness**
- [ ] Architecture matches **Notch ADT fold (Amortizing | Breakeven | Profit; the ledger is a fold over an Article's notches)** with no leakage across layers.
- [ ] UI approach matches **SwiftUI hosting a UIView notch-rail (CAShapeLayer teeth carve inward per notch; UITapGestureRecognizer commits the carve)**.
- [ ] Navigation matches **Rail-locked chrome (the notch rail never leaves; Board and Settings arrive as sheets)**.
- [ ] Screen composition follows section 3.6.
- [ ] Typography uses **American Typewriter** and nothing else.
- [ ] Palette matches section 7.1 exactly.

**Quality**
- [ ] Section 8 UI/UX bar satisfied end to end.
- [ ] Contact link present.
- [ ] `PrivacyInfo.xcprivacy` present and correct.
- [ ] README complete.

---

## 20. Build commands

```bash
cd Notchmark
xcodegen generate
xcodebuild -scheme Notchmark -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO build
xcrun simctl list devices available
xcodebuild -scheme Notchmark -destination 'platform=iOS Simulator,id=<UDID>' test
```

Signing is off only on that command line. Do not put CODE_SIGNING_ALLOWED, CODE_SIGNING_REQUIRED, CODE_SIGN_IDENTITY or DEVELOPMENT_TEAM in project.yml — CI signs the archive. Leave CODE_SIGN_STYLE: Automatic as the scaffold set it. The exact simulator does not matter — use any available UDID from the list.
