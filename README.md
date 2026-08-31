# Notchmark

Every notch pays down the price.

Notchmark is for people who buy an $80 gadget, use it twice, and want the exact ugly number — and the quiet satisfaction of a $6 tool finally outranking it. Home is the rail: each owned Article is a shrinking balance bar. Tap Notch to carve one share off the purchase price. When the balance hits zero the row stamps an immutable Breakeven Mark and flips to Profit. The Board can only rank Marked Articles; a still-Amortizing row is structurally absent from that query.

No account, no ads, no Game tab. The rail is the calculator.

## Architecture

Notch ADT fold — Amortizing | Breakeven | Profit; the ledger is a fold over an Article's notches.

Phase is never a stored enum picked by hand. `AmortizationLedger.reduce(over:)` folds the append-only `NotchEntry` array from a starting balance equal to the purchase price. Each notch subtracts one fixed `perNotchShare`. The instant a subtraction reaches or passes zero the fold emits `.breakeven(BreakevenMark)` and the caller persists that Mark. From then on the fold short-circuits to `.profit(mark:)` so editing the share later cannot rewrite a Mark that already exists. Rail and Board read phase only through this fold.

This fits a cost-per-use desk: the legal move is carve-one-share, not edit-a-row. A tab plus a list of purchases would be a journal clone.

## Notch-to-breakeven ledger

This is why someone would pick the app. Every Article is born Amortizing. The only way the balance moves is notch by notch — never a percentage, never a date-based decay. The Mark is one-way. Board's ranking query selects only Articles that carry a Mark, so a cheap tool cannot jump the fence early. The Forecast strip estimates notches-to-Mark from that Article's own rolling interval so you can see how close the $6 tool is to outranking the $80 gadget. Relative A+–F library grades sit on the rail itself: `cpu = (price − disposal) / max(uses, 1)`, compared against five or more peers aged at least seven days.

## Design

Actuary's desk: ruled foolscap, brass paper-clip, carbon-copy violet, ink-stamp red. Palette lives in `Assets.xcassets` and is reached only through `LedgerPalette`: background `#F6F1E3`, surface `#ECE3CB`, ink `#241C12`, accent `#A32E2A`, muted `#8B7A55`. Type is American Typewriter behind `Font.ledger(_:)` — five steps (heading, articleTitle, stampNumeral, body, footnote). Hard edges. Spacing unit 8 pt. Tap targets 44 pt. The notch rail never leaves; Board and Settings arrive as sheets.

## Art

Style: steel engraving of a Victorian actuary's desk (ledger page, brass paper-clip, carbon flimsy, red ink stamp).

Base prompt reused for every asset:

```
Monochrome steel-engraving illustration in the style of a nineteenth-century actuary's desk plate: fine cross-hatched linework on ruled foolscap ledger paper, a glinting brass paper-clip pinning a corner, a violet carbon-copy flimsy peeking from beneath, and one red ink-stamp mark for accent. Restrained, printmaking-era detail and tonal range — no photographic textures, no soft gradients, no modern flat-icon shapes.
```

| Image set | Prompt |
| --- | --- |
| `ntm_AppIcon` | Steel-engraving emblem, centred and filling the canvas edge to edge: a single ledger-page corner pierced by a brass paper-clip, one small red ink-stamp notch-mark beside it. Monochrome engraved linework on cream. No text, no lettering, no rounded corners, no drop shadow, no alpha channel. |
| `ntm_Splash` | Vertical steel-engraving composition of a Victorian actuary's desk seen from above: ruled foolscap pages, a brass paper-clip, a violet carbon flimsy at the edges, framing a calm uncluttered centre band where the Notchmark wordmark will sit. |
| `ntm_Onboarding1` | Steel-engraving illustration of a single owned object — a hand tool sitting beside a price tag on ruled ledger paper — the two things this app tracks: what you bought and what it cost. |
| `ntm_Onboarding2` | Steel-engraving illustration of a hand pressing a carve into a ledger balance bar, one tooth cutting inward, mid-gesture — the app's one verb, notching a use. |
| `ntm_Onboarding3` | Steel-engraving illustration of a ledger page stamped with a red ink Mark at its foot, carbon-copy violet showing through beneath — the moment an Article crosses into Profit. |
| `ntm_EmptyHome` | Steel-engraving of a blank ruled foolscap ledger page, an empty brass paper-clip resting at the top corner, waiting for its first entry — calm, not sad. |
| `ntm_EmptyList` | Steel-engraving of an empty ledger column with faint ruled lines and no entries yet, a brass paper-clip at rest beside it. |
| `ntm_CardBackdrop` | Low-contrast steel-engraving backdrop of faint ruled foolscap lines and a soft carbon-violet wash, quiet enough to sit behind readable card text. |
| `ntm_ControlFace` | Steel-engraving close-up of a single brass paper-clip face, the app's one physical control motif, rendered as a dial-like emblem. |
| `ntm_TwistHero` | Steel-engraving hero art for the Notch-to-breakeven ledger: a balance bar carved down to its last tooth, a red ink-stamp Mark landing at that instant, carbon-violet flimsy beneath. |
| `ntm_SuccessMark` | Small steel-engraving red ink-stamp mark, freshly pressed, confirming a committed notch or a written Mark. |
| `ntm_HeaderDecor` | Wide steel-engraving ornamental band of ruled ledger lines, a thin brass rule, and a faint carbon-violet edge, for a screen header. |
| `ntm_MarkStamp` | Steel-engraving icon of a round red ink stamp mid-press over a ledger line, used wherever the UI needs to represent a written Breakeven Mark distinctly from an ordinary notch. |

## How this is not a repeat

cost_per_use is unused in the 41-app history. The closest neighbor, subscription_load (Kentledge), amortizes a recurring monthly charge by cutting it; this amortizes a one-time purchase by counting uses, with opposite arithmetic. Home is the notch rail, not a today-number-vs-capacity ratio. Distinct from Occupath (token-block occupation), Washfolio (year wash), and Nisihold (brittle-lead gate). No Game tab.

## Build

```bash
cd Notchmark
xcodegen generate
xcodebuild -scheme Notchmark -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO build
```

Bundle identifier: `com.travelhel.per`. Contact: https://travelhel-per.pro/contact-us

Review screenshots: launch with `-ReviewScreen today|log|goals` after onboarding. Simulator seed uses `ntm.demo.v1` and never runs on a device. The driver captures PNG with `simctl`, not `ImageRenderer`.
