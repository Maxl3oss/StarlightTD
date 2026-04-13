# Project Specification: StarlightTD

## Project Overview
**StarlightTD** is a modern Roblox Tower Defense (TD) game built with a modular, system-oriented architecture. The project aims for high visual quality, smooth performance, and extensible tower mechanics.

---

## Technical Stack
- **Game Engine:** Roblox
- **Language:** Luau
- **Project Management:** Rojo (Visual Studio Code workflow)
- **Networking:** [NetRay](https://github.com/Maxl3oss/NetRay) (v1.1.5 or later) - A high-performance networking library.
- **UI Framework:** Fusion v0.3 (State-management driven UI - Scoped Syntax)
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
- [ ] Upgrade UI (Allowing players to level up towers)
- [ ] Sound Design
- [ ] Progression Systems (Persistent Inventory)
