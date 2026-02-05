# Revamping TODO (iOS) - Time Progress Tracker

This is the working checklist to improve the app using competitor-proven premium features + your unique ideas, while **keeping the existing visual style** (Sabdevi + tally look) and focusing on **widgets-first**.

## Product Decisions (Locked)

- Premium model: **One-time lifetime unlock**
- Monetization principle: sell value (widgets + unlimited + reminders), not “remove ads”

## Free vs Premium (Suggested Defaults)

- Free:
  - Up to **3 custom events**
  - Basic widgets only (current layouts)
  - **1 reminder** per event (optional)
- Premium (one-time unlock):
  - **Unlimited** events
  - Premium widget styles/layouts (including dot-matrix glow style option)
  - Multiple reminders per event + repeat rules
  - Themes + custom backgrounds
  - iCloud backup/sync (or at least reliable backup/restore)
  - Calendar import
  - Export (CSV/PDF)
  - Streak tracking
  - Leave optimizer (moat feature)

---

## Phase 0 - Foundations (1 week)

- [x] Create branch `codex/revamping` (start coding work here)
- [ ] Add a single “Upgrade” entry point in `SettingsView`
- [ ] Add “Premium status” banner/row (shows unlocked vs locked)
- [ ] Create `AppGroupStore` wrapper (single place to read/write app + widget data)
- [ ] Add storage versioning + migration strategy for saved JSON (forward compatible)
- [ ] Add deep link routing:
  - [ ] `myapp://home`
  - [ ] `myapp://event/<id>`
- [ ] Ensure widget taps open the app reliably (basic deep link works end-to-end)

Definition of done:
- [ ] No UI redesign; app behaves the same, but has shared store + deep link foundation.

---

## Phase 1 - Widgets First (2-4 weeks)

### 1A) Coverage
- [ ] Ensure Home Screen widget supports: `.systemSmall`, `.systemMedium`, `.systemLarge`
- [ ] Ensure Lock Screen widget supports: `.accessoryCircular`, `.accessoryRectangular`, `.accessoryInline`
- [ ] Expand Custom Events widget families:
  - [ ] `.systemSmall`
  - [ ] `.systemMedium`
  - [ ] `.systemLarge`
  - [ ] `.accessoryCircular`
  - [ ] `.accessoryRectangular`
  - [ ] `.accessoryInline`

### 1B) Widget Layout Options (Keep Existing Style)
- [ ] Add 1–2 more “Classic” layouts (same current style)
- [ ] Add “Single big” mode + “2–3 rows” mode per widget size
- [ ] Add widget “primary item” rules:
  - [ ] Auto (most urgent)
  - [ ] User-selected pinned item (later via configuration)

### 1C) Widget Customization (Minimal UI)
- [ ] Add global widget style setting in Settings:
  - [x] Classic (current)
  - [x] Minimal (text-forward, high readability)
  - [ ] Dot Matrix Glow (deferred / not needed now)
- [x] Persist style selection via App Group and reload widget timelines on change

### 1D) Live Updating + Tap Behavior
- [ ] Use system-updating text where possible (`.relative` / `.timer`) to avoid frequent timeline reloads
- [ ] Update timeline cadence:
  - [ ] daily for “days left”
  - [ ] 15–60 min for “today hours left” (battery-safe)
- [ ] Tap behavior:
  - [ ] tap widget opens Home (`myapp://home`)
  - [ ] tap row opens event (`myapp://event/<id>`) where supported

### 1E) StandBy Readiness (iOS 17+)
- [ ] Check contrast/spacing in StandBy context
- [ ] Verify large widget feels clean on OLED (no low-contrast text)

Definition of done:
- [ ] Widgets are “product-quality” and useful without opening the app.

---

## Phase 2 - Unlimited Events + Stronger Event Model (2-4 weeks)

### 2A) Event Model Upgrade (Backward Compatible)
- [x] Add `category` (work/personal/family/custom)
- [x] Add `mode` (countdown vs count-up “days since”)
- [x] Add optional `timeOfDay` (for accurate “exact time” countdowns later)
- [x] Add `recurrence`:
  - [x] none
  - [x] yearly
  - [x] monthly
  - [x] weekly
- [x] Stop auto-deleting past events (needed for count-up + history)

### 2B) Events Management (Fits Current UX)
- [x] Add “Events” section (inside Settings) to manage all events
- [x] Add category filtering + sorting (soonest first)
- [x] Add pinned events for widgets (store pinned IDs in App Group)

### 2C) Premium Gating
- [ ] Enforce free limit at create time (max 3 events)
- [ ] Premium unlock removes limits + unlocks extra widget styles

Definition of done:
- [ ] Users can track many event types cleanly without confusing the core time-progress features.

---

## Phase 3 - Reminders + Smart Notifications (2-3 weeks)

- [x] Notifications permission onboarding (simple + respectful)
- [ ] Per-event reminders:
- [x] multiple reminders per event (premium)
- [x] reminder offsets (7d, 1d, 1h, at time)
- [x] Repeat rules:
  - [x] weekly/monthly/yearly next occurrences
- [x] Rich notifications:
  - [x] show “X days/hours left” in notification body
- [ ] Safety/quality:
  - [x] reschedule notifications when event date edits happen
  - [ ] reschedule after app reinstall/restore

Definition of done:
- [ ] Users reliably get the reminders they set, without duplicates or missing alerts.

---

## Phase 4 - Themes + Backup + Import/Export (Month 2-3)

### 4A) Themes (Keep Current Style)
- [x] Add theme presets (token changes only: background/accent)
- [x] Add premium theme packs (starter set)
- [x] Add custom background photo (premium)

### 4B) iCloud Backup/Sync
- [x] V1: manual backup/restore (fast + safe)
- [ ] V2: auto sync (later, if needed)

### 4C) Calendar Import (EventKit)
- [ ] Import birthdays (contacts/calendar)
- [x] Import selected calendar events as countdowns

### 4D) Export
- [x] Export events to CSV
- [ ] Export streaks to CSV (when streaks ship)
- [x] Share sheet support

Definition of done:
- [ ] Switching devices doesn’t lose data; setup is faster via import.

---

## Phase 5 - Streaks + Leave Optimizer (Month 3+)

### 5A) Streak Tracking
- [x] Habit-type events with daily check-in
- [x] Streak stats (current, longest, success rate)
- [x] Milestones (7/30/90)
- [x] Widget support: streak count + next milestone

### 5B) Leave Optimizer (Moat Feature)
- [ ] Holiday dataset (start with 1 region)
- [ ] Long weekend finder
- [ ] Leave block suggestions (maximize consecutive off-days)
- [ ] Leave balance tracker
- [ ] Widget: “next long weekend” + “best leave suggestion”

Definition of done:
- [ ] App becomes more than a countdown tracker; it becomes a planning tool.

---

## QA / Release Checklist (Each Phase)

- [ ] Widget performance check (scrolling, rendering, timeline updates)
- [ ] Accessibility labels for widgets and important UI
- [ ] Dark mode contrast pass
- [ ] Deep link tests (home + event)
- [ ] Upgrade/restore purchase test (StoreKit 2 lifetime)
