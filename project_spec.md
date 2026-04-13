# Project Specification: StarlightTD

## Project Overview
**StarlightTD** is a modern Roblox Tower Defense (TD) game built with a modular, system-oriented architecture. The project aims for high visual quality, smooth performance, and extensible tower mechanics.

---

## Technical Stack
- **Game Engine:** Roblox
- **Language:** Luau
- **Project Management:** [Argon](https://github.com/argon-rbx/argon) (Visual Studio Code workflow)
- **Data Store:** [ProfileStore](https://github.com/MadStudioRoblox/ProfileStore) (Updated 25 Mar 2026) - A high-performance data store library.
- **Networking:** [NetRay](https://github.com/AstaWasTaken/NetRay) (v1.1.5) - A high-performance networking library.
- **UI Framework:** [Fusion](https://github.com/dphfox/Fusion) v0.3 (State-management driven UI - Scoped Syntax)
- **Architecture:** System-based framework with modular tower logic.

---

## Core Systems & Architecture

### 1. Framework & Loading
- **Framework:** Custom system-based loader (`src/ReplicatedStorage/Framework`).
- **Initialization:** `Server.luau` and `Client.luau` handle the lifecycle of systems.
- **Systems:** Independent modules that handle specific game domains (e.g., `TowerSystem`, `WaveSystem`).
- **Security:** `AssetSystem` strips server-side logic from tower models before they are replicated to the client for placement previews.

### 2. Wave & Enemy System (`WaveSystem.luau`)
- **Waves:** Config-driven spawning (`WaveConfig`).
- **Pathfinding:** Waypoint-based movement through `Workspace.Base.Waypoints`.
- **Base Logic:** Health management and game over/victory transitions.
- **Currency:** Manages "Coins" (game-session currency).

### 3. Tower System (`TowerSystem.luau`)
- **Placement:** 
    - **Validation:** Towers can ONLY be placed on `Workspace.Base.Land`.
    - **Collision:** Towers are assigned to the `Towers` collision group.
    - **Anti-Stacking:** Overlap checks (using `GetPartBoundsInBox`) prevent towers from being placed on top of each other.
    - **Limits:** 
        - Max global tower limit (Default: 25).
        - Max per-type tower limit (e.g., Potato: 6, Archer: 4, Mage: 2).
    - **Visuals:** Ghost models use a dynamic color system (Red when invalid/overlapping/limit reached).
- **Combat Logic:** 
    - **Levels:** Towers support 5 levels of progression. Stats are fetched from `tower.Config.Levels[tower.Level]`.
    - **Targeting:** 2D distance calculation to find the closest "Mob".
    - **Centralized Logic:** Combat logic is kept secure in `ServerScriptService/TowerLogic`.
- **VFX Synchronization:** Broadcasts `TowerShoot` events to all clients for visual rendering.

### 4. Client Systems
- **VFX System:** Listens for `TowerShoot` events to render polished effects.
- **Placement System:** Handles client-side validation logic and real-time color feedback.
- **UI Systems:** `TowerUISystem`, `WaveClientSystem`, `NotificationUISystem`, and `HealthBarSystem` handle the game HUD using Fusion.
- **Notification System:** Displays real-time alerts (e.g., "Not enough coins", "Max towers reached").

---

## Key Data Structures

### Tower Configuration (`TowerConfig.luau`)
```lua
{
    Name = string,
    Cost = number,
    Levels = {
        [1] = { Damage = number, Range = number, FireRate = number, UpgradeCost = number },
        -- ... up to level 5
    },
    AttackType = "Single" | "AoE",
    -- Optional fields
    BlastRadius = number,
    AoECenter = "Tower" | "Target",
}
```

---

## Operational Workflow & Security
1. **Server Source of Truth:** All damage, spending, and limits happen on the Server.
2. **Internal Logic:** Keep tower combat scripts in `ServerScriptService/TowerLogic` to ensure they never enter the Workspace.
3. **Validation Parity:** Both Client and Server must validate placement and gameplay rules.
4. **Collision Groups:** Maintain proper collision group layers (`Mobs`, `Towers`, `Players`).
5. **UI Development:** Always create a `.story.luau` file (UI Labs style) in `src/ServerScriptService/Stories` for every new UI component to enable isolated testing.

---

## 🛠 Development Rules & Standards (MANDATORY)

### 1. UI Framework (Fusion v0.3)
- **Scoped Syntax:** All components and stories MUST use the `scope` object. Constructor functions like `New`, `Value`, `Computed`, and `Observer` must be called through `scope` (e.g., `scope:New`).
- **Reactivity:** UI elements must be reactive. Use `scope:Computed` to handle derived states and `scope:Value/Observer` to listen for attribute changes on game objects (like `Level`).
- **Type Safety:** All component functions MUST have a strictly defined `props` type. Do not use generic types like `any` or leave them undefined.

### 2. Visual Standards
- **Tower Selection:** Always use the `Highlight` instance (Aura/Outline style) when a tower is selected. Avoid using `SelectionBox` (wireframe) for primary selection visuals.
- **World UI:** All placed towers must feature a `BillboardGui` (via `WorldTowerInfo`) displaying the tower name and current level. Placement systems must include foolproof mounting logic (e.g., `ChildAdded` listeners) to ensure visuals are attached even during network latency.
- **Placement Preview:** While in placement mode, a summary of the tower's Base Stats (Damage, Range, Speed) must be displayed on the left side of the screen (via `TowerDraftInfo`).
- **Micro-Animations:** UI components (like Notifications) should include smooth transitions (Fade, Slide) using task-based loops or Fusion's spring/tween systems when available.

### 3. Workflow & Organization
- **Tower Identification:** All towers MUST be tracked using a unique UUID (assigned via `HttpService:GenerateGUID`) stored as a `TowerId` attribute. NEVER use instance references for critical network requests like upgrades or sales.
- **World UI:** All placed towers must feature a `BillboardGui` (via `WorldTowerInfo`). This UI MUST have a `MaxDistance` of 60 studs to ensure optimal performance and clarity.
- **Sell Policy:** Tower sales MUST refund exactly 70% of the total investment (Original Cost + all Upgrade Costs). Refund calculations must be performed on the server for security.
- **Stories Location:** All UI preview stories MUST reside in `src/ServerScriptService/Stories/`.
- **Spec Maintenance:** The `project_spec.md` MUST be updated every time a new feature, network event, or architectural change is implemented. This document is the single source of truth.
- **Shared Utilities:** Frequently used functions (e.g., `getDistance2D`, `formatNumber`, `setCollisionGroup`) MUST be placed in `src/ReplicatedStorage/Utils/Helper.luau`. Developers MUST check this helper before rewriting utility logic.
- **Network Optimization:** Economy updates (like adding coins) MUST be throttled using `task.defer` to batch multiple changes into a single network packet per frame. NEVER fire network events inside tight loops (e.g., AoE damage loops).
- **UI Performance:** All major Fusion UI systems MUST implement "Pre-warming" during initialization to prevent hitching. Always use the modern Fusion 0.3 API: use `peek()` or `use()` instead of the deprecated `get()`.
- **VFX Standards:** Frequent visual effects (like health bar pops) MUST use optimized tweens (e.g., `Reverses = true`) instead of chain-connecting multiple tweens to minimize event listener overhead.
- **Logic Security:** Gameplay-critical combat logic (Damage, Range, FireRate) MUST be stored in `src/ServerScriptService/TowerLogic/` and handled exclusively on the server.
- **Asset Replication:** Server logic should be stripped from models in `ReplicatedStorage` to prevent client-side script inspection.

### 4. Networking
- **NetRay API:** Use colon syntax for event/request methods (e.g., `Network.Event:OnEvent()`, `Network.Event:FireServer()`).
- **Authorization:** Server must validate all client requests (Placement, Upgrades, Spending) against current player state and configs.

---

## Project Status
- [x] Foundation (Framework/Network)
- [x] Placement Validation (On Land only)
- [x] Anti-Stacking System (Overlap prevention)
- [x] Tower Collision Groups
- [x] Tower Level Progression (Levels 1-5)
- [x] Max Tower Limit (Enforced on Server)
- [x] Security (Logic Stripping & Centralized TowerLogic)
- [x] Notification UI System
- [x] Core Gameplay (Waves/Placement/Combat)
- [x] Upgrade & Sell UI (Allowing players to manage towers)
- [x] Unique Tower Identification (UUID-based networking)
- [ ] Sound Design
- [ ] Progression Systems (Persistent Inventory)
