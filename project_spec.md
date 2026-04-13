# Project Specification: StarlightTD

## Project Overview
**StarlightTD** is a modern Roblox Tower Defense (TD) game built with a modular, system-oriented architecture. The project aims for high visual quality, smooth performance, and extensible tower mechanics.

---

## Technical Stack
- **Game Engine:** Roblox
- **Language:** Luau
- **Project Management:** Rojo (Visual Studio Code workflow)
- **Networking:** [NetRay](https://github.com/Maxl3oss/NetRay) (v1.1.5 or later) - A high-performance networking library.
- **UI Framework:** Fusion (State-management driven UI)
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
- **Currency:** Manages "Coins" (game-session currency) and interfaces with `ProfileStoreSystem` for "Cash" (persistent currency).

### 3. Tower System (`TowerSystem.luau`)
- **Placement:** 
    - **Validation:** Towers can ONLY be placed on `Workspace.Base.Land`.
    - **Visuals:** Ghost models use a dynamic color system (Red when invalid, original/white when valid).
- **Combat Logic:** 
    - **Levels:** Towers support 5 levels of progression. Stats are fetched from `tower.Config.Levels[tower.Level]`.
    - **Targeting:** 2D distance calculation to find the closest "Mob".
    - **Modular Logic:** Individual towers can have a `Logic` ModuleScript inside their model to override/extend attack behaviors.
- **VFX Synchronization:** Broadcasts `TowerShoot` events to all clients for visual rendering.

### 4. Client Systems
- **VFX System:** Listens for `TowerShoot` events to render polished effects.
- **Placement System:** Handles client-side validation logic and real-time color feedback for the placement ghost.
- **UI Systems:** `WaveClientSystem`, `TowerUISystem`, and `HealthBarSystem` handle the game HUD using Fusion.

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
1. **Server Source of Truth:** All damage and spending must happen on the Server.
2. **Asset Sanitization:** Never replicate server-side scripts (Logic) to `ReplicatedStorage`.
3. **Validation Parity:** Both Client and Server must validate placement to ensure a smooth UX and block exploits.
4. **2D Combat:** Use `Vector2` (X, Z) for distance checks to avoid verticality issues in targeting.

---

## Project Status
- [x] Foundation (Framework/Network)
- [x] Placement Validation (On Land only)
- [x] Tower Level Progression (Levels 1-5)
- [x] Security (Logic Stripping)
- [x] Core Gameplay (Waves/Placement/Combat)
- [ ] Upgrade UI (Allowing players to level up towers)
- [ ] Sound Design
- [ ] Progression Systems (Persistent Inventory)
