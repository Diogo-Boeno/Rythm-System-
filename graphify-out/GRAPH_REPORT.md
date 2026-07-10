# Graph Report - .  (2026-07-10)

## Corpus Check
- Corpus is ~6,879 words - fits in a single context window. You may not need a graph.

## Summary
- 168 nodes · 159 edges · 35 communities (19 shown, 16 thin omitted)
- Extraction: 75% EXTRACTED · 24% INFERRED · 1% AMBIGUOUS · INFERRED: 38 edges (avg confidence: 0.88)
- Token cost: 0 input · 109,413 output

## Community Hubs (Navigation)
- Project Structure & Workflow Docs
- Code Style & Naming Conventions
- UI Component Catalog
- Core Framework (Net/Signal/State)
- Vide UI Patterns vs Roact
- State Persistence Mechanisms
- State Module API
- AAA Indie Design System
- Signal Module API
- Loader & Bootstrap Entry Points
- Net Module API
- AutoScale & Window Components
- ModelViewport & Theme
- Project Identity (Rhythm_System)
- UI Labs Stories
- Aftman Tooling
- Author: Cosmo
- Rojo Build Tool
- Wally Package Manager
- Antigravity IDE
- Selene Linter
- StyLua Formatter
- Double Quotes Rule
- Indentation Rule
- Player Join Pattern
- Strict Mode Rule
- Roblox Studio Plugin

## God Nodes (most connected - your core abstractions)
1. `Basic Component Structure Pattern` - 13 edges
2. `Framework Custom (Shared/Framework/)` - 6 edges
3. `Estrutura de Pastas (Section)` - 6 edges
4. `AAA Indie UI Style` - 6 edges
5. `Workflows (Section)` - 6 edges
6. `getRemote()` - 5 edges
7. `getSignal()` - 5 edges
8. `Convencoes Principais (Section)` - 5 edges
9. `Anti-Patterns List` - 5 edges
10. `Vide (Referenced)` - 5 edges

## Surprising Connections (you probably didn't know these)
- `Anti-Patterns List` --references--> `Rule: Never Use RemoteEvent Directly`  [INFERRED]
  docs/CONVENTIONS.md → CLAUDE.md
- `Vide (Referenced)` --references--> `Vide`  [INFERRED]
  docs/ui/COMPONENTS.md → CLAUDE.md
- `Shared/Framework/ Folder` --references--> `Framework Custom (Shared/Framework/)`  [INFERRED]
  README.md → CLAUDE.md
- `Attributes for Simple Replication Pattern` --references--> `player:SetAttribute Mechanism`  [INFERRED]
  docs/CONVENTIONS.md → CLAUDE.md
- `Rule: Comments Explain Why, in English` --conceptually_related_to--> `Rule: Comments in Brazilian Portuguese`  [AMBIGUOUS]
  CLAUDE.md → docs/CONVENTIONS.md

## Import Cycles
- None detected.

## Hyperedges (group relationships)
- **Aftman-Managed Toolchain** — claude_aftman, claude_rojo, claude_wally, claude_selene, claude_stylua [EXTRACTED 1.00]
- **Three State Management Mechanisms** — claude_playerdataservice, claude_setattribute, claude_vide_source [EXTRACTED 1.00]
- **AAA Indie Design Philosophy** — claude_aaa_indie_style, claude_corner_brackets, claude_dot_pattern, claude_amber_accent, claude_restricted_palette [EXTRACTED 1.00]

## Communities (35 total, 16 thin omitted)

### Community 0 - "Project Structure & Workflow Docs"
Cohesion: 0.12
Nodes (20): Services/AxeService.luau (Example), Bootstrap.client.luau, Bootstrap.server.luau, UI/Common/Button.luau (Example), Controllers/ Folder, docs/ARCHITECTURE.md (Reference), docs/workflow/DEBUGGING.md (Reference), docs/workflow/NEW_SERVICE.md (Reference) (+12 more)

### Community 1 - "Code Style & Naming Conventions"
Cohesion: 0.14
Nodes (15): Rule: Comments Explain Why, in English, Convencoes Principais (Section), Rule: Module-Level State, Not OOP, Naming: camelCase for API Helper Methods, Naming: PascalCase for Modules/Services/Controllers, Naming: UPPER_SNAKE for Module Constants, Anti-Patterns List, camelCase for API Helper Methods (+7 more)

### Community 2 - "UI Component Catalog"
Cohesion: 0.14
Nodes (14): Optional Types with ? Pattern, Basic Component Structure Pattern, CornerBrackets Component (TODO), DialogUI Component, HealthBar Component, Inventory Component, MainMenu Component, Merchant Component (+6 more)

### Community 3 - "Core Framework (Net/Signal/State)"
Cohesion: 0.18
Nodes (11): docs/framework/ (Reference), docs/framework/STATE.md (Reference), Framework Custom (Shared/Framework/), Net (Framework), Rule: Never Use RemoteEvent Directly, Signal (Framework), State (Framework), Attributes for Simple Replication Pattern (+3 more)

### Community 4 - "Vide UI Patterns vs Roact"
Cohesion: 0.20
Nodes (10): Rule: Never Use Roact, Roact, Vide, Anti-Patterns List, Cleanup Pattern for Vide Effects, create ClassName {...} Call Syntax, Events Directly in Props Convention, indexes() Dynamic List Pattern (+2 more)

### Community 5 - "State Persistence Mechanisms"
Cohesion: 0.22
Nodes (9): PlayerDataService, Rule: Never Manipulate profile.Data Directly, ProfileService (Madwork), player:SetAttribute Mechanism, Estado: 3 Mecanismos (Table), Vide.source() Mechanism, Guard Clauses Pattern, PlayerDataService (Referenced) (+1 more)

### Community 6 - "State Module API"
Cohesion: 0.33
Nodes (6): Signal.new(), getSignal(), State.Observe(), State.OnChange(), State.Set(), State.Update()

### Community 7 - "AAA Indie Design System"
Cohesion: 0.29
Nodes (7): AAA Indie UI Style, Amber Accent Color, Corner Brackets (Signature Element), Dot Pattern, Rule: Never Use Saturated Roblox Green in CTAs, Restricted Black/White/Gray Palette, DESIGN_SYSTEM.md (Empty Placeholder)

### Community 10 - "Net Module API"
Cohesion: 0.60
Nodes (5): getRemote(), Net.FireAllClients(), Net.FireClient(), Net.FireServer(), Net.On()

### Community 11 - "AutoScale & Window Components"
Cohesion: 0.47
Nodes (4): AutoScale.factor(), compute(), bracket(), Window()

### Community 14 - "UI Labs Stories"
Cohesion: 0.67
Nodes (3): UI Labs, UI Labs Story Pattern, UI Labs (Referenced)

## Ambiguous Edges - Review These
- `Rule: Comments Explain Why, in English` → `Rule: Comments in Brazilian Portuguese`  [AMBIGUOUS]
  CLAUDE.md · relation: conceptually_related_to
- `UI/Common/Button.luau (Example)` → `Button Component (TODO)`  [AMBIGUOUS]
  CLAUDE.md · relation: conceptually_related_to

## Knowledge Gaps
- **54 isolated node(s):** `Cosmo (Diogo Boeno Pereira)`, `Antigravity IDE`, `Rojo`, `Wally`, `UI Labs` (+49 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **16 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **What is the exact relationship between `Rule: Comments Explain Why, in English` and `Rule: Comments in Brazilian Portuguese`?**
  _Edge tagged AMBIGUOUS (relation: conceptually_related_to) - confidence is low._
- **What is the exact relationship between `UI/Common/Button.luau (Example)` and `Button Component (TODO)`?**
  _Edge tagged AMBIGUOUS (relation: conceptually_related_to) - confidence is low._
- **Why does `Framework Custom (Shared/Framework/)` connect `Core Framework (Net/Signal/State)` to `Project Structure & Workflow Docs`?**
  _High betweenness centrality (0.128) - this node is a cross-community bridge._
- **Why does `Loader (Framework)` connect `Project Structure & Workflow Docs` to `Core Framework (Net/Signal/State)`?**
  _High betweenness centrality (0.112) - this node is a cross-community bridge._
- **Are the 10 inferred relationships involving `Basic Component Structure Pattern` (e.g. with `Button Component (TODO)` and `CornerBrackets Component (TODO)`) actually correct?**
  _`Basic Component Structure Pattern` has 10 INFERRED edges - model-reasoned connections that need verification._
- **What connects `Cosmo (Diogo Boeno Pereira)`, `Antigravity IDE`, `Rojo` to the rest of the system?**
  _58 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Project Structure & Workflow Docs` be split into smaller, more focused modules?**
  _Cohesion score 0.11578947368421053 - nodes in this community are weakly interconnected._