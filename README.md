# 🌟 StarlightTD

StarlightTD is a high-quality, modern Tower Defense game built on Roblox using a highly modular system-based architecture. It features polished VFX, a robust leveling system, and secure server-authoritative logic.

## 🚀 Technical Highlights

- **Framework:** Custom system-based loader with clear domain separation.
- **Project Management:** Powered by [Argon](https://github.com/argon-rbx/argon) for a seamless VS Code to Roblox workflow.
- **Networking:** Utilizes [NetRay v1.1.5](https://github.com/AstaWasTaken/NetRay) for high-performance, typed client-server communication.
- **UI Framework:** Built with [Fusion v0.3](https://github.com/dphfox/Fusion), leveraging modern scoped state management.
- **Data Management:** Integrated with [ProfileStore](https://github.com/MadStudioRoblox/ProfileStore) for secure persistent player data.
- **Security:** Logic-stripped asset replication and centralized `ServerScriptService/TowerLogic` to prevent client-side exploits.

## 🏰 Core Features

### 1. Robust Tower System
- **Level Progression:** 5-tier upgrade system for every tower with dynamic stat scaling (Damage, Range, FireRate).
- **Smart Placement:** Validate surfaces, prevent tower stacking (Anti-stacking), and provide real-time visual feedback (Ghost coloring).
- **Modular Combat:** Centralized attack logic in `TowerLogic` allowing for specialized behaviors (AoE, Single Target, Custom Logic).
- **Deployment Limits:** Both global and per-tower instance limits enforced server-side.

### 2. Wave & Enemy Combat
- **Config-Driven Waves:** Easy to expand wave configurations.
- **Smooth Navigation:** Waypoint-based pathfinding for mobs.
- **Polished VFX:** Real-time synchronized attack effects (Lasers, Meteors, Arrows, Pulses).

### 3. Modern HUD & UI
- **Fusion-Powered:** High-performance UI components with reactive state.
- **Notification System:** Real-time feedback for gameplay events (e.g., "Not enough coins", "Limit reached").
- **UI Stories:** Isolated component testing via [UI Labs](https://github.com/re-vue/ui-labs) story files in `ServerScriptService/Stories`.

## 🛠 Project Structure

- `src/ReplicatedStorage/Components`: Reusable Fusion UI components.
- `src/ReplicatedStorage/Systems`: Shared logic and client-side systems (VFX, Placement).
- `src/ServerScriptService/Systems`: Server-authoritative logic (Tower management, Waves).
- `src/ServerScriptService/TowerLogic`: Secure combat scripts for individual tower behaviors.
- `src/ServerScriptService/Stories`: UI Labs stories for component previewing.

## 📜 Project Specification
For detailed technical documentation and development guidelines, refer to [project_spec.md](./project_spec.md).

---
*Built with ❤️ for the Roblox community.*
