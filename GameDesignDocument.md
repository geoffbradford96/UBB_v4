# Unavure Battle Bonanza (UBB) - Game Design Document

## 1. Overview
**Working Title:** Unavure Battle Bonanza (UBB)
**Platforms:** PC, Mobile (iOS/Android)
**Genre:** Card-Based RTS / Lane Battler / Tower Rush (Inspired by Star Wars: Force Arena, Titanfall: Assault, Warcraft Rumble, Clash Royale)

## 2. Core Gameplay Loop
- Players build a deck of 5 unit/spell cards + 1 Hero card from the "Unavure" universe and lore.
- Real-time battles take place on a map with multiple lanes.
- **Resource Economy:** Players generate a resource over time to play cards.
  - *Dominion of Sol specifically uses "Requisition Income."*
  - **Comeback Mechanic:** Requisition Income generation speed goes *up* the fewer towers/structures you have remaining.
- **Card Mechanics (In-Game):**
  - Hand size is limited to **3 Cards**.
  - Whenever a card is played (costing Requisition), a new card is randomly drawn from your constructed deck to replace it.
- **Hero/Leader Unit:** Hybrid control! Players can directly control a main hero character (moving/attacking) while also dragging-and-dropping other units onto the battlefield to march down the lanes.
- Goal: Destroy the opponent's main base or outscore them before time runs out.

## 3. The Universe (Lore)
*To be expanded using the existing lore lexicon and book materials.*
- **Setting:** The Unavure universe.
- **Factions:** [TBD - Need input on factions/races from the book]
- **Key Characters:** [TBD - Heroes and villains from the lore]

## 4. Mechanics
- **Lanes:** X amount of lanes connecting the player bases.
- **Unit Types:** Tanks, Ranged, Melee, Flying, Spells, etc.
- **Progression:** Unlocking new characters/units and upgrading them.

## 5. Menus and Flow
1. **Boot Screen:** Splash screen loading into the main menu.
2. **Main Menu:** Options for Settings, Online Play, and Local Play.
3. **Army Gathering (Deck Builder):** Accessible from Online/Local play. Players assemble their loadout.
   - **Deck Size:** 1 Hero + 5 Units/Spells (6 total slots).

## 6. Factions
1. **Dominion of Sol**
   - **Colors:** Gold and Blue.
   - **Aesthetic:** Highly ornate, "adorned to shit," reflecting a glorified and wealthy capital structure.

## 7. Initial Roster (Dominion of Sol)
1. **Commander (Hero):** Hardened military leader (Male/Female variants).
2. **Cheap Grunt (Melee):** Spawns 3 units at once. Low stats, cheap cost. Runs forward and attacks whatever is in front of them.
3. **Supporting Fire (Ranged):** Single unit with a ballistic gun.
4. **Medic (Support):** Armed with a small pistol. Heals an ally for 50% of their max HP every 10 seconds.
5. **Repair Man (Support/Builder):** Armed with a pistol. Prioritizes repairing friendly structures/towers. If nothing needs fixing, marches forward like a standard unit.
6. **Command Bay (Support/Tactical):** Armed with a small pistol. It generates a small "Deployment Zone" aura around itself, allowing you to spawn new units further up the field.
7. **Call Artillery (Spell):** A targeted circular AoE attack that deals damage with a small explosion animation.
8. **Sniper (Off-lane Ranged):** Hides off the main lane. Forces the enemy hero to manually leave the lane to hunt them down.
9. **Hero Hunter (Laser Grunt):** Ignores standard lane pathing. Specifically hunts down the enemy player/Hero. Less damage, longer range.
10. **Assassin (Counter-Off-lane):** Specifically targets units that are off the main lane (perfect counter for Snipers).

## 8. Arena & Deployment Mechanics
- Large map scaling (100x100 size for testing).
- **Structure:** 2 Defensive Towers positioned along the main lane, leading up to 1 Main Base (glorified capital structure) per side.
- **Deployment Zones:** You cannot spawn units anywhere. Standard Units can ONLY be placed in an area close to friendly Towers, your Main Base, or a friendly Command Bay.
- **Action Cards / Spells:** Cards like "Call Artillery" ignore deployment zones and can be placed anywhere on the map.

## 8. Development Stack
- **Game Engine:** Godot (Perfect for being free, lightweight, and capable of both PC and mobile builds).
- **Art Style:** 3D (Models with animations for characters and environments).
- **Networking:** Multiplayer focused! Planning to support up to 12 players maximum for massive battles on large maps.
