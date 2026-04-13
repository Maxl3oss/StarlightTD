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

### 2. Wave & Enemy System (`WaveSystem.luau`)
- **Waves:** Config-driven spawning (`WaveConfig`).
- **Pathfinding:** Waypoint-based movement through `Workspace.Base.Waypoints`.
- **Base Logic:** Health management and game over/victory transitions.
- **Currency:** Manages "Coins" (game-session currency) and interfaces with `ProfileStoreSystem` for "Cash" (persistent currency).

### 3. Tower System (`TowerSystem.luau`)
- **Placement:** Handles `PlaceTower` network events, deducting coins and spawning models.
- **Combat Logic:** 
    - **Targeting:** 2D distance calculation to find the closest "Mob".
    - **Standard Logic:** Single target and AoE (Area of Effect) damage.
    - **Modular Logic:** Individual towers can have a `Logic` ModuleScript inside their model to override/extend attack behaviors.
- **VFX Synchronization:** Broadcasts `TowerShoot` events to all clients for visual rendering.

### 4. Client Systems
- **VFX System:** Listens for `TowerShoot` and other events to render polished effects (beams, projectiles, explosions).
- **Placement System:** Handles the client-side UI for dragging/snapping towers to the grid before confirming placement.
- **UI Systems:** `WaveClientSystem`, `TowerUISystem`, and `HealthBarSystem` handle the game HUD using Fusion.

---

## Key Data Structures

### Tower Configuration (`TowerConfig.luau`)
```lua
{
    Name = string,
    Cost = number,
    Damage = number,
    Range = number,
    FireRate = number,
    AttackType = "Single" | "AoE",
    -- Optional modular fields
    BlastRadius = number,
    AoECenter = "Tower" | "Target",
}
```

### Enemy Configuration (`EnemyConfig.luau`)
```lua
{
    Health = number,
    WalkSpeed = number,
    Damage = number, -- Damage to base
    Reward = number, -- Coins granted on kill
}
```

---

## Operational Workflow for AI
1. **Always use NetRay for networking:** Follow the `getOrRegisterEvent` pattern in `Network.luau`.
2. **Respect Modular Logic:** Before adding global tower behaviors, check if they should be in `TowerSystem.luau` or a specific tower's `Logic.luau`.
3. **2D Combat:** Use `Vector2` (X, Z) for distance checks to avoid verticality issues in targeting.
4. **VFX on Client:** Ensure all gameplay-affecting damage happens on the Server, while visual "wow" factors (beams, particles) are handled in `VfxSystem.luau`.

---

## Project Status
- [x] Foundation (Framework/Network)
- [x] Core Gameplay (Waves/Placement/Basic Combat)
- [x] UI (Fusion implementation)
- [ ] Polish (Sound, advanced VFX, specialized Tower Logic)
- [ ] Map Variety
- [ ] Progression Systems (Upgrades, Persistent Inventory)
