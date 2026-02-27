# Game Design Document

## Overview

### Core Gameplay Loop

- **Home Base/Hub World:** Acts as a lobby to start missions, etc. Sell items and buy upgrades
- **Journey to Station/Base:** Simple navigation through space to enter either space fights or dungeon crawls.
- **Space "Dogfighting" (Optional):** Fight AI or human enemies. Either get loot or defend your loot on the way back. Some loot is only attainable this way, but progression is doable with station/base only gameplay. Return to space navigation afterward.
- **Space Station/Planetoid Base (Optional):** Lethal-company like dungeon crawl with hazards and enemies. Some loot is only attainable this way, but progression is doable with doable with space fight only gameplay. Return to space navigation afterward.

### Lore (Tentative)

Total honesty this is basically just made up on the spot so its all subject to change

In 1983, Soviet scientists cracked cold fusion, preventing the fall of the Soviet Union. In 2004, they cracked exotic matter and it works exactly the way that we thought it would and the FTL it enables on paper definitely works and there are no "but FTL ***always*** breaks causality" problems. Sometime between 2100 and 2300, life is discovered in a nearby star system so there's a bunch of manned missions to establish bases and space stations in that star system. Shortly thereafter something bad happens and they're now all abandoned. Fifty-ish years later, a variety of companies send people on missions to recover space junk from these stations/bases, Lethal Company-style. They're not *supposed* to have their contractors kill each other for loot, but they do anyway because it makes money and no one's gonna stop them (justification for pvp mechanics).

### Reference Media

#### Aesthetic

- **Alien and Alien: Romulus:** being a sci-fi series that started in the 1980s, the retrofuturistic look with 80s-style tech is pretty interesting and relatively unique
- **Jean "Moebius" Giraud:** I like the aesthetic he's most known for. Maybe we could implement a shader that approximates it to give the game a unique, more eye-catching aesthetic

#### Space Gameplay

- **Sea of Thieves:** The core gameplay loop of PvPvE and starting at a "home base," venturing through a "wilderness" with hazards posed by other players and AI to a "dungeon" that contains loot
- **Elite: Dangerous:** Space "dogfighting" reference gameplay
- **Jump Space: Space** "dogfighting" reference gameplay

#### Dungeon Gameplay

- **Lethal Company:** Tone and gameplay on space stations

## Minimum Viable Product

### Space Dogfighting Gameplay

- One ship variant to fly
    - Ship has maximum amount of weight it can hold
- **Controls:**
    - W/S = forward/back
    - Q/E = roll left/right
    - Mouse = look
- **Movement upgrades (three to start):**
    - Moar speed
    - Moar accel (better handling)
    - Lateral movement with A/S
- **Shields/Health upgrades (three to start):**
    - tbh idk what it would be other than reduced damage taken/more health
- **Weapon upgrades (three to start):**
    - Fire rate
    - Damage
    - Homing?
- Enemy Ships (one variant to start; aim for three)

### Dungeon Gameplay

- Character controller is typical FPS controller
    - Characters have maximum inventory slots and weight
    - Maybe some items result in "hands full" like Lethal Company
- **"Character" Upgrades (three? to start):**
    - Thing that upgrades inventory capacity
    - ATV
    - Jetpack
    - Various Weapons
- **Consumable Items:**
    - "Werewolf NRG" drink gives temporary speed
- **Procedural Dungeon**
    - [This old project of mine](https://github.com/blackHat-Magic/pygame-demo) has a dungeon generation algorithm tht can be adapted to work for this
    - Military/Private Security Themed Variant:
        - Possible Hazards: Landmines, Sentient Turrets (like from Portal)
        - Possible Enemies: Security drones
    - Research Facility Themed Variant:
        - Possible Hazards: Radiation, Various biohazards
        - Possible Enemies: Mutants
    - Warehouse Themed Variant:
        - Possible Hazards: Sentient Turrets (like from Portal), Falling boxes/debris
        - Possible Enemies: Security drones
    - Mine/Resource Extraction Themed Variant:
        - Possible Hazards: Falling debris, Unused explosive charges, Pit
        - Possible Enemies: Xorn, Pit, Mimic
- **Items to be Collected:**
    - Seemingly random junk
        - Sold back to company and used to buy upgrades/items
    - usable items
    - consumables
    - ship upgrades
    - Some items only attainable through dungeon exploration
    - Some items only attainable through space combat
    - 

## Miscellaneous Features

These are mostly things that serve almost no purpose but my brain won't let me not think about adding them

- Various useless items
    - Laser pointer (sells for very little)
    - Bing bong (from PEAK)
    - Paint (allows you to paint fellow players)
    - Plushie that explodes the fourth time it is picked up.
    - Blowgun that shoots tranq darts (only usable on other players)
- Terminal with GNU core utils and proper bash support
    - here me out: LFS distro in a VM built into the game that can run freedoom
    - used to dose out lore
- Physics based whiteboard and markers on ship/in home base
- Playable board games on ship/in home base
