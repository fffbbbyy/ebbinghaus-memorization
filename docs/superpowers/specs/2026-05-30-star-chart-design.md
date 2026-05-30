# Star Chart / Constellation Motivation System — Design Spec

**Date:** 2026-05-30  
**Status:** Draft  
**Branch:** star-chart-system

## 1. Overview

Add a "Star Chart" (星图) game-inspired motivation layer on top of the existing Ebbinghaus schedule. Each completed review = a lit star. Each day's full completion = a constellation. Long streaks = a growing, rotating star chart with escalating visual phases.

**Motto:** "白天伏案读书，夜晚仰望星空" — by day a scholar at the desk, by night a stargazer.

## 2. Design Principles

- **Forgiving, not punishing.** Missed days dim stars but never erase them. Returning after a gap re-lights dim stars with a warm "welcome back" animation. The star chart is a cumulative record, not a streak-or-nothing scoreboard.
- **Visual-first.** The canvas star chart is the centerpiece. Text stats are secondary.
- **Incremental reveal.** Phase upgrades are subtle — a golden pulse at the canvas edge, not a modal interrupt.

## 3. Data Model

All star chart state lives inside the existing `ebbinghaus_schedule_v2` localStorage key under a new `starChart` field:

```js
starChart: {
  // Version for future migrations
  version: 1,

  // Whether the star chart feature has been unlocked (first review ever completed)
  unlocked: true,

  // Map from dateKey ("YYYY-MM-DD") to constellation data
  // Only dates where ALL reviews for that day were completed get an entry.
  // Partial completions do NOT appear here.
  constellations: {
    "2026-05-30": { stars: 5, phaseAtTime: "星芽" }
  },

  // Number of currently-dimmed stars. Increments when a day is missed,
  // decrements when the user returns and re-completes.
  dimStars: 0,

  // Current star chart phase name (one of the 7 phases below).
  // Determined by consecutive completion streak length.
  phase: "星芽",

  // Timestamp of last phase upgrade (for animation gating)
  lastPhaseUpgrade: 1717027200000
}
```

### 3.1 Phase Thresholds

| Phase (阶段) | Consecutive Days | Canvas Visual |
|---|---|---|
| 星芽 (Star Sprout) | 1–2 | 3–8 scattered pale-gold stars, no lines |
| 星溪 (Star Stream) | 3–6 | Short line segments connecting recent stars, silver hints |
| 星湾 (Star Bay) | 7–13 | Recognizable small constellation shapes, silver ribbon |
| 星河 (Star River) | 14–29 | Multiple constellations linked, brighter silver band |
| 星海 (Star Ocean) | 30–59 | Dense star clusters, slow rotation (0.2 deg/s) |
| 星穹 (Star Vault) | 60–99 | Full deep-blue night panorama, golden twinkling |
| 星永恒 (Star Eternity) | 100+ | Full rotation (0.5 deg/s), aurora edge glow |

Consecutive days are computed the same way as the existing streak (`computeStreak`): counting backwards from today (or most recent day with tasks), stopping at the first incomplete day.

## 4. UI Layout

### 4.1 Placement

A new `<section id="starChartCard">` card inserted between the stats bar (`#stats`) and the main table (`#tableWrap`). Default height: ~220px. Collapsed on first load (before unlock).

### 4.2 Card Structure

```
┌─────────────────────────────────────────────────────┐
│  ★ 星图 · [星芽]                     累计 127 颗星  │
│  ┌──────────────────┐ ┌───────────────────────────┐ │
│  │                  │ │  🌟 今日星座              │ │
│  │    Canvas 星图    │ │  已完成 · 5 星           │ │
│  │   300 × 200      │ │                           │ │
│  │                  │ │  最近 7 天:               │ │
│  │  ★ ★  ★          │ │  5/30 ★★★★☆              │ │
│  │   ★   ★          │ │  5/29 ★★★★★              │ │
│  │  ★ ★ ★           │ │  5/28 ★★★★★              │ │
│  │   ★              │ │  ...                      │ │
│  │                  │ │                           │ │
│  └──────────────────┘ └───────────────────────────┘ │
└─────────────────────────────────────────────────────┘
```

### 4.3 Full-Screen Star View

Clicking the canvas opens a full-screen overlay (`#starFullscreen`). The canvas is redrawn at viewport size with a slow rotation animation. A "✕" close button in the top-right corner. Background: deep navy `#0a0d1a` with CSS transition from parchment. Escape key also closes.

## 5. Animations

### 5.1 Constellation Birth (daily completion)

Trigger: last checkbox of the day is checked → `fireStamp()` runs first → then stars appear.

- One star at a time (50ms stagger), scale 0 → 1.2 → 1 with ease-out
- After all stars appear, yellow-white connecting lines draw between them (600ms stroke-dashoffset animation)
- Total duration: ~800ms for 5 stars

### 5.2 Page-Load Star Reveal

When the page loads and `starChart.unlocked === true`:
- Canvas starts at opacity 0, fades to 1 over 1s
- Existing constellations "twinkle in" — each constellation group gets a brief 200ms opacity pulse, staggered by group

### 5.3 Dim Star Re-light (welcome back)

After a gap day, when the user completes today's reviews:
- Dimmed stars (rendered at 30% opacity) pulse back to 100% with a warm golden glow (300ms ease-in-out)
- `starChart.dimStars` count resets to 0

### 5.4 Phase Upgrade Pulse

When `phase` changes:
- Canvas edges emit a subtle golden radial gradient pulse (2s, ease-out, opacity 0.6 → 0)
- A small text label fades in below the phase name: "✦ 星图进阶 ✦" (disappears after 3s)
- Does NOT interrupt existing interactions

### 5.5 Full-Screen Rotation

Continuous rotation driven by `requestAnimationFrame`. Speed:
- 星海: 0.15 deg/s clockwise
- 星穹: 0.3 deg/s
- 星永恒: 0.5 deg/s + aurora edge shimmer
- Earlier phases: static, no rotation

## 6. Star Rendering Algorithm

### 6.1 Star Position Generation

Each date maps to a deterministic position on the canvas using a simple hash:

```js
function starPosition(dateKey, canvasW, canvasH) {
  const seed = hashCode(dateKey); // simple string hash
  const x = (seed % 1000) / 1000 * canvasW;
  const y = ((seed * 7 + 13) % 1000) / 1000 * canvasH;
  return { x, y };
}
```

Stars within the same day (same constellation) are offset from the day's center position by small random deltas derived from the star index.

### 6.2 Star Rendering

Each star: a 4-point cross shape (two thin lines) with a central glow circle. Radius 2–4px based on phase. Color: pale gold `#f0d890` for active, `rgba(240,216,144,0.3)` for dimmed.

### 6.3 Constellation Lines

Lines connect stars within the same day. Stroke: `rgba(240,216,144,0.25)`, 1px. Only drawn for phases ≥ 星溪. In higher phases (≥ 星河), additional lines connect nearby constellations across days.

## 7. Canvas Technical Details

- `<canvas>` element, size 300×200 logical pixels
- `devicePixelRatio` scaling for HiDPI (×2 minimum)
- `requestAnimationFrame` loop only runs when animations are active; stops when idle to save CPU
- Full-screen canvas: separate `<canvas>` sized to `window.innerWidth × window.innerHeight`, rendered only when overlay is open

## 8. Integration Points

| Existing Function | Change |
|---|---|
| `onCheckbox()` | After updating completions, call `updateStarChart()` |
| `computeStreak()` | Also compute star chart phase from streak length |
| `updateStats()` | Call `renderStarChartCard()` |
| `fireStamp()` | After stamp animation, call `animateConstellationBirth()` |
| `init()` | Call `initStarChart()` to load state and render |
| `loadState()` | Include `starChart` in parsed state with defaults |
| `saveState()` | Include `starChart` in saved state |
| `onClear()` | Reset `starChart` to initial state |

## 9. CSS Variables (new)

```css
--star-gold: #f0d890;
--star-dim: rgba(240, 216, 144, 0.3);
--star-line: rgba(240, 216, 144, 0.25);
--night-canvas: #0a0d1a;
--aurora-teal: #2ee8b8;
--aurora-purple: #8844cc;
```

## 10. Accessibility

- Canvas has `aria-label="星图：{phase}阶段，累计{totalStars}颗星"`
- Star chart card respects `prefers-reduced-motion`: all animations replaced with instant transitions
- Full-screen overlay traps focus and supports Escape-to-close
- Phase labels are text elements outside the canvas, readable by screen readers

## 11. Scope & Non-Goals

**In scope:**
- Star chart canvas card below stats bar
- 7 phases with distinct visual treatments
- Constellation birth animation on daily completion
- Dim star mechanism for missed days
- Full-screen star view on click
- Phase upgrade pulse notification
- Page-load star reveal animation

**Out of scope (future ideas):**
- Clickable individual stars showing review details
- Sharing star chart as image
- Custom constellation naming
- Multiple star charts / seasonal resets
- Sound effects specific to star chart (existing stamp sound is sufficient)

## 12. File Changes

Single-file project: all changes go into `index.html`. Sections affected:
- `<style>`: new CSS for star chart card, fullscreen overlay, animations (~150 lines)
- `<script>`: new JS for canvas rendering, animation loop, state management (~300 lines)
- HTML structure: new `#starChartCard` section between `#stats` and `#tableWrap` (~30 lines)
