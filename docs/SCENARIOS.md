# Scenarios: who the model is for, and what "usable" means

The model measures everything the walk can reach and ships all of it. This file says which
namespaces the scenarios use, so the probe (`docs/PLAN.md` section 4) and the descriptions
(section 5) take them first.

A scenario is a developer with a goal, not a Lua state. Most scenarios span two states, and the
state boundary is usually the hard part of the question.

**The entry roots below are a hypothesis, not a boundary.** They were written from memory of
DCS before this project measured anything. Measurement
takes precedence over them in every case:

- The walk reaches everything it can, from every state's globals and registry. It does not start
  from these roots and it does not stop at them.
- The cites collector produces the measured root set: every top-level name that ED's Lua and
  ED's shipped missions touch, per state, with call counts.
- A root named here may not exist at all. Then it is absent from the index, and this list is
  corrected when the walk has run.

**"Meant to be used" is measured, not declared.** ED marks nothing public. The signals, in
strength order, each a collector's output and never an author's opinion:

1. **ED's own Lua calls it.** The cites collector over `Scripts/`, `MissionEditor/`, `Config/`,
   and over the scripts inside the `mission` table of every `.miz` ED ships. The second half
   matters: the scripting engine a mission author uses is C-implemented and nothing under
   `Scripts/` calls it, but the shipped missions do.
2. **Text ED ships names it.** `API/Sim_ControlAPI.md` in the install, graded `D`.
3. **A scenario's entry roots reach it.** The walk from the roots named below.

Community libraries, wikis and mirrors are not sources, by the maintainer's rule of 2026-11-06.
Every symbol the walk reaches ships. Descriptions go to symbols with the most signals,
most-called first.

**The C-implemented surface.** Most of what scenarios 1, 2, 7, 8 and 9 call is a C function: a
node in the walk with no source span and no Lua body to read. Signal 3 puts it in scope; signals
1 and 2 rank it; its signature comes from the bounded probe (`docs/PLAN.md` section 4), cited
arguments first and one bare call for the error text where nothing cites it, or stays unknown.

---

## The scenarios

### 1. Mission scripting

A script inside a `.miz` that makes the mission dynamic: spawn and despawn, react to events,
drive AI, draw on the F10 map, talk to players.

| | |
|---|---|
| State | `scripting` or `mission`: a hypothesis. The findings place `world`, `Group` and `S_EVENT` in `mission`; the transport's `server` name resolves to `scripting`. The census of both states settles which holds this surface, and the root gate prints the answer |
| Vantage | `sp`. A client never runs it; a server is out of scope |
| Entry roots | `env`, `world`, `coalition`, `trigger`, `timer`, `missionCommands`, `land`, `atmosphere`, `coord`, `radio`, `country`, `AI`, `Object`, `Unit`, `Group`, `StaticObject`, `Airbase`, `Weapon`, `Spot`, `Controller`, `Warehouse`, `VoiceChat`, `net` (the subset visible here) |
| Typical questions | which events fire and what the handler's table holds; how to spawn with a route; how to draw a shape for one coalition; what `Unit.getByName` returns after the unit dies |
| Hazards | the sanitiser: no `io`, `os`, `lfs`, `require` unless `MissionScripting.lua` is edited; every mission script shares one state and one global table |

### 2. Campaign scripting

The same author, over many missions: a `.cmp` with stages and scoring, outcomes reported from
one mission to the next, state that must survive a mission ending.

| | |
|---|---|
| States | `scripting` for the in-mission half; `hook` for `onMissionEnd`, `onSimulationStop` and the result; the `.cmp` and `.miz` file formats |
| Vantage | `sp` |
| Entry roots | scenario 1's, plus `trigger.action.setUserFlag` and the flag space, `mission.result` in the `.miz`, the `.cmp` stage table, `DCS.setUserCallbacks` events on the hook side, `DCS.getMissionResult` |
| Typical questions | how a mission reports its outcome; what a stage transition reads; how to persist a table across missions; what the hook side sees when a mission ends |
| Hazards | persistence is the defining one: the sanitised state cannot write a file, so the honest answer is often a hook-side relay through `net.dostring_in`, or desanitising with a stated cost. Campaign stage files are Lua tables loaded by the `gui` state, not by the mission |

### 3. Client UI

A window, an overlay, a menu, a keybind, a kneeboard page, on the player's own screen.

| | |
|---|---|
| States | `gui` for widgets and the editor's UI, `hook` for `DCS.*` and `net.*` and the callbacks |
| Vantage | `sp` |
| Entry roots | `dxgui`, `DialogLoader`, `Gui`, `GuiWin`, `Skin`, `SkinUtils`, `Static`, `Button`, `EditBox`, `Panel`, `Window`, `MapWindow`, `DCS`, `net`, `lfs`, `Export` (from the hook side), `Input`, `Options` |
| Typical questions | how to make a window with a button and a click handler; how to read the mission clock from a hook; how to find the player's own unit; what `net.get_player_info` returns; how to register a keybind |
| Hazards | a hook runs in the render loop, so a slow callback is a stutter for everyone; `DCS.*` reads that return nothing at the menu; the dxgui toolkit is class-based across incompatible idioms |

### 4. Mission Editor automation

Driving the editor itself, at runtime, from a script or an agent: open a mission, place a unit,
set a route, move the map, save.

| | |
|---|---|
| State | `gui` at the editor phase |
| Vantage | `sp` only |
| Entry roots | `me_*` (`me_mission`, `me_map_window`, `me_route`, `me_vehicle`, `me_aircraft`, `me_ship`, `me_static`, `me_payload`, `me_loadout`, `me_weather`, `me_db`, `me_openfile`, `me_toolbar`, `me_menubar`, `me_action_db`, `me_manager_resource`), `Mission`, `MapWindow`, `panel_*`, `MsgWindow` |
| Typical questions | how to load a `.miz` without the dialog; how to add a group at a coordinate with a route; how to point the map at a coordinate and scale; how to save; which of these need the dialog to be visible |
| Hazards | the `me_*` model is the largest surface in the editor state and the easiest to leave unmeasured; editor and menu are the same phase to the executor, so a script must detect the editor itself (`MapWindow.getVisible()`) |

### 5. Offline mission authoring

Producing or editing a `.miz` with no DCS running: the `mission` table, `options`, `warehouses`,
`mapResource`, the dictionary, and the zip layout.

| | |
|---|---|
| State | `gui`: the code that reads and writes a `.miz` (`me_mission`, `Miz`, `me_openfile`) is the authority on what is legal, and a task's needs spell against it. The format itself has no runtime state |
| Vantage | `sp` |
| Entry roots | the `.miz` `mission` table and every key under it, `warehouses`, `options`, `theatre`, `dictionary`, `mapResource`; the reader and writer code in `gui`; `Scripts/UI/` serialisers (`Serializer`, `value2code`) |
| Typical questions | what keys a unit entry needs; how a route point is spelled; how a trigger with a condition is encoded; which fields the editor recomputes on load; how a loadout references a weapon |
| Hazards | the format has no schema; the editor tolerates missing keys unevenly; a key ED renamed silently breaks old files |

### 6. Reference databases

The facts a mission, a campaign, an authoring tool, or an external program need to look up:
which units exist, their type names and categories, weapons and CLSIDs, loadouts, liveries,
countries and coalitions, airbases and theatres, `wsTypes`.

| | |
|---|---|
| States | `config` and `gui` for the loaded `db`, `country`, `wsTypes`; `Config/`, `CoreMods/`, `Scripts/Database/` on disk as the source |
| Vantage | `sp` |
| Entry roots | `db` (`db.Units`, `db.Weapons`, `db.Countries`, `db.Sensors`), `country`, `wsTypes`, `wsType_*`, `GT_t`, `gun_mount_templates`, `damage_cells`, `NATO`, `terrain`, `Airdromes`; on disk `Config/db/`, `CoreMods/aircraft/*/`, `Scripts/Database/`. Airbase identity per map lives under `Mods/terrains/*/` and is out of scope; the `Airbase` API is in |
| Typical questions | the CLSID for a weapon; the type name for a unit as `Group.spawn` wants it; which country ids belong to which coalition; what `wsType` a category maps to; an airbase's id, name and runways; a livery name |
| Hazards | one fact in three places (the runtime `db`, the `Config/` source, the shipped `.miz` files) that can disagree; `wsTypes` reuses one integer for unrelated things in different branches; strings that look like CLSIDs and are not |

**This scenario ships differently.** The others are functions, and one grep of the index plus one
bounded read of a LuaLS definition answers a question. Reference data is rows, and a consumer's
question is a lookup, so the model ships the shape and the rows:

- **The shape, as LuaLS.** A `---@class` for a unit entry, a weapon entry, a country, with each
  field's seen count and value class from the survey collector. This is what a script iterating
  `db.Units` needs, and it fits the grep-and-read query.
- **The rows, as TSV.** One file per table (`data/units.tsv`, `data/weapons.tsv`,
  `data/countries.tsv`, `data/airbases.tsv`, `data/liveries.tsv`), one row per entry, with the
  columns a lookup asks for: id, display name, type name, category, CLSID, country, coalition,
  `wsType` path. A lookup is still one grep.

The rows come from the runtime `db` dump in the editor state, because the core database source
is encrypted on disk; each row carries the sitting, the build, and the module that declared it
where `db` records one.

### 7. Telemetry export, read side

An external program reading the running sim: own aircraft state, world objects, weapons in the
air, at frame rate.

| | |
|---|---|
| State | `export` |
| Vantage | `sp` |
| Entry roots | `LoGetSelfData`, `LoGetWorldObjects`, `LoGetObjectById`, `LoGetModelTime`, `LoGetMissionStartTime`, `LoGetAircraftDrawArgumentValue`, `LoGetCameraPosition`, `LoGetMCPState`, `LoGetTWSInfo`, `LoGetRadioBeacons`, the `LuaExport*` callbacks, `Export.lua` and its `dofile` chain, `socket` |
| Typical questions | what `LoGetSelfData` holds and which fields are per-aircraft; how often each callback fires; what a world object entry looks like; which reads a server can block |
| Hazards | `Export.lua` is one shared file and every exporter chains it; a blocking socket call stalls the sim; some reads are gated by the server's `allow_*_export` options |
| Note | the `LoGet*` surface is visible from `hook` as well as from `export`; the walk records which state saw each, and this scenario has no measured surface until sitting B walks `export` |

### 8. Cockpit actuation and hardware integration

Reading and clicking cockpit devices from outside: a home cockpit, a stream deck, a script that
types coordinates into a navigation computer.

| | |
|---|---|
| State | `export` |
| Vantage | `sp` |
| Entry roots | `GetDevice`, the device object's `performClickableAction`, `get_argument_value`, `set_argument_value`, `LoSetCommand`, `LoGetAircraftDrawArgumentValue`, `list_indication`, `list_cockpit_params`, `LoSetSharedTexture`; per-aircraft `clickabledata.lua`, `devices.lua`, `command_defs.lua` under `Mods/aircraft/` as the argument and command spaces |
| Typical questions | the device id and command for a switch; the argument number for a gauge; how to read a display's text; whether an action is allowed while the aircraft is not controlled by the player |
| Hazards | the argument and command spaces are per aircraft and under `Mods/`, which is out of the census. The model documents the functions and the file shapes, and the per-aircraft tables are a consumer's own read |

### 9. Multiplayer server administration

A script on a dedicated server: who may connect, slot rules, chat commands, kicks, mission
rotation, reporting.

| | |
|---|---|
| State | `hook` |
| Vantage | `sp`: the `hook` surface is walked at single-player, and its behaviour on a server is not measured |
| Entry roots | `DCS.setUserCallbacks` and the `onPlayer*`, `onSimulation*`, `onMission*`, `onNetConnect`, `onNetDisconnect`, `onGameEvent`, `onChatMessage` events; `net.*` (`get_player_list`, `get_player_info`, `send_chat`, `send_chat_to`, `kick`, `force_player_slot`, `load_mission`, `load_next_mission`, `dostring_in`, `get_slot`, `set_slot`); `DCS.getMissionName`, `DCS.getRealTime`, `DCS.exitProcess`; `serveroptions`, `tabComanders`, `tabRoles` |
| Typical questions | the return value that refuses a connection; the payload of each event; how to read a player's slot and coalition; how to run something in the mission from the server side; what differs on a client |
| Hazards | many `net.*` calls return nil silently on a client; a callback that raises is dropped without a log line; `dostring_in` into the mission is the only way across and it returns a string |
| Note | The `hook` surface is walked at single-player. What differs on a server is not measured and the docs say so |

### 10. Cross-environment plumbing

Any of the above that needs another state: a hook reaching the mission, a mission wanting a file,
an exporter wanting mission data.

| | |
|---|---|
| States | `hook` to `scripting` and `missionscripting` via `net.dostring_in` and `a_do_script`; `gui` to `config`; `export` alongside `hook` on the same frame |
| Vantage | `sp` |
| Entry roots | `net.dostring_in`, `a_do_script`, `a_do_script_file`, `net.lua2json`, `net.json2lua`, `DCS.getMissionName`, the sanitiser's edits in `Scripts/MissionScripting.lua`, `Export.lua`'s load order |
| Typical questions | which state can reach which; what comes back and in what type; what the size limit is; what happens on a client; what the sanitiser removed and how to tell |
| Hazards | the string-only return and its ceiling; a crash in the target state takes the caller with it; the same call returning nil on a client |

---

## Excluded, by name

- Aircraft, terrain and asset mod development: `Mods/`, `Bazar/`, `DemoMods/` are out of the
  census. Scenario 8 reads its per-aircraft tables from there as a consumer, not as a model fact.
- Track files (`.trk`), replay, and the `.acmi` format.
- Localisation `.mo` files. The `_()` msgid obligation is kept; translation is not.
- The sanitiser as a thing to defeat. What it removed is recorded; how to remove it is not
  documented beyond the fact that it costs every `.miz` on that install its safety.

---

## What reads this file

| Consumer | Reads | Produces |
|---|---|---|
| The probe plan | the entry roots per scenario | the order of the probe candidates: scenario namespaces first |
| The describe step | the entry roots and the typical questions | the order in which symbols get a description: most-cited in a scenario namespace first |

Adding a scenario is an edit to this file that names its roots.
