# Rhythm System

An osu!-style rhythm system for Roblox — timing-based hit targets with graded,
color-coded feedback, BPM-driven charts, and combo scoring.

## Features

- **Hit targets** — a fixed circle with an approach ring that closes onto the beat; the player clicks the moment they meet.
- **Graded judgements** — every input reads at a glance by color: **Sick** (violet), **Good** (green), **Bad** (red), **Miss** (gray), each with its own pop and motion.
- **BPM charts** — note sequences are generated from tempo + duration instead of hand-placing every note.
- **Score & combo** — reactive HUD that tracks the run.
- **Session framing** — the camera moves to the arena on interaction and restores when the run ends.

## Stack

- **Luau** (`--!strict`)
- **Vide** — reactive UI (Solid.js-inspired)
- A lightweight custom framework — auto-loaded services/controllers, typed net, signals, reactive state
- **Rojo** + **Wally** for build and packages

## Structure

```
src/
├── ReplicatedStorage/Shared/
│   ├── Framework/    Loader, Net, Signal, State, Tags
│   └── UI/           Vide components (HitCircle, Theme, …)
├── ServerScriptService/Services/       server services
└── StarterPlayerScripts/Controllers/   client controllers (RhythmController)
```

## Author

Built by **Cosmo (Diogo Boeno)** — Roblox systems & UI/UX.
Open to commissions · _[your contact here]_
