# ClearCue — 0.1.0 alpha

<img src="Media/Icon.png" width="128" height="128" alt="ClearCue icon">

A Retail WoW addon with a readable next-spell cue, interrupt cue and four per-specialization defensive reminders. Customize fonts, keybind labels and visibility to fit your UI.

## Start

Place the addon files in `World of Warcraft/_retail_/Interface/AddOns/ClearCue` (with `ClearCue.toc` directly inside that folder). Restart WoW if the addon does not appear in the AddOns list, then enable ClearCue. `/cc` opens settings. `/cc edit` previews all six positions and enables dragging; repeat to exit. `/cc refresh` rescans fonts and keybindings. `/cc bindings` prints binding diagnostics outside combat. The assistant and interrupt are large square tiles above a single row of four smaller defensive tiles.

EllesmereUI's configured Action Bars font (including module overrides) is used by default when available. Choose another Ellesmere font source in settings if desired. Otherwise ClearCue uses the game font. LibSharedMedia fonts are available when another addon supplies that library; ClearCue does not bundle it. Global and separate keybind, cooldown, charge and label fonts/sizes are configurable. Colored keybinds sit in the top-right corner; cooldown text is centered and charges sit bottom-right. Numbers and labels default off. Inactive reminders default to fully transparent and all live frames are click-through.

## Settings and DataBroker

`/cc` opens a dark settings panel with Display, Typography and Defensives tabs. Changes save immediately; Enter or leaving a numeric field commits its value. The header's Preview & position button toggles edit mode and stays synchronized with `/cc edit`.

When LibDataBroker is available (for example from BugSack), ClearCue registers a launcher. In Ellesmere Data Bars, add a Broker Plugin block and choose ClearCue. Left-click opens settings; right-click toggles positioning/preview. The text and tooltip show edit state. No separate minimap icon is added. The launcher is optional and does not require an additional library installation in your current setup.

## Reminder behavior

Main display visibility is shared by the full row: hostile living target, combat, or always. Hide while mounted is optional. Inactive opacity controls failed reminder conditions and unavailable cooldowns, not the whole-row visibility. Edit mode overrides visibility for preview.

Four rules per specialization: spell ID, unit (player/pet/mouseover), health or a numeric power type, below/above threshold, and optional explicit keybind. A few known class spells seed the first visit; review them rather than treating these as expert recommendations. Set ID to 0 to disable. Thresholds are percentages, strictly below/above, with a very narrow interpolation boundary. Empty positions remain fixed so reminders do not jump around.

Interrupt detection uses a known class interrupt and the target's cast/channel interruptibility, plus cooldown readiness. It does not assess whether interrupting that particular spell is strategically desirable. Optional red icon tint indicates out of range when Blizzard supplies an accessible range result; unknown or restricted results keep the normal color. Pet interrupt availability needs in-game validation.

Cooldown and health/resource values flow into Blizzard duration/curve display APIs without converting protected combat values into Lua decisions. Unknown API behavior must still be tested in combat, instances and PvP. The addon never casts a spell and does not bypass protected actions.

## Alpha limitations

- Built for Retail interface 120100. Defensives, interrupts and keybindings have been tested in-game on a Frost Mage using EllesmereUI; other classes and setups still need validation.
- Keybind lookup supports Blizzard and Ellesmere action buttons, including resolved spell macros. Other action-bar addons and complex macros may need defensive key overrides.
- No resource-pooling recommendation, movement substitution, aura bar, enemy counter, proc glow or empowered-stage override in this version.
- Configured theme font changes are detected automatically within one second.
- Font settings do not automatically import Ellesmere's sizes or outline preference.
- One account-wide visual profile; rules separated by specialization.

## Manual acceptance checklist

1. Open `/cc edit`; verify six preview slots, corner keybinds, selected font, optional text and dragging. Exit edit and verify click-through.
2. Clear target: row disappears in target mode. Select hostile living target: recommendation appears.
3. Test an interruptible cast, an uninterruptible cast, interrupt cooldown and a channel. Check BugSack for errors.
4. Set a health threshold high and cross it using ordinary gameplay. Verify the rule fades/hides and returns, including during combat. Repeat with resource, pet and mouseover rules.
5. Test charged defensives with one charge still available and with no charges.
6. Verify bindings after page/spec changes and reload. Check macro and modifier labels.
7. Change fonts, timers and charge options; inspect live cooldown text as well as preview. Reload to verify persistence.

## Development

From the addon directory, run `luac -p Core.lua Options.lua Broker.lua tests/smoke.lua` and `lua tests/smoke.lua` with Lua 5.1. The smoke tests mock WoW APIs; they supplement the in-game checklist above.

API reference: [Blizzard-generated documentation](https://github.com/Gethe/wow-ui-source/tree/live/Interface/AddOns/Blizzard_APIDocumentationGenerated).

## License

No license selected yet. All rights reserved.

