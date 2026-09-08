# Ox Inventory Hooks

  ![](https://img.shields.io/github/downloads/Maximus7474/mps-ox-invhooks/total?logo=github)

A collection of server-side hooks that modify item behavior during inventory transfers within `ox_inventory`.

> [!IMPORTANT]
> This script will work best with `v2.47.2` of ox_inventory, as it provides a more reliable method in acting on the item's metadata.
> No changes will need to be made to this script, it'll detect if using the appropriate version and act accordingly.

## How to remove a hook

The system is designed to be entirely modular. To remove a hook, simply delete its corresponding file from the `server/hooks/` directory. The server will instantly stop integrating it upon the next resource restart.

## Hooks:

<details>
<summary>Fridge Hook: extend an items lifespan</summary><br/>

The fridge hook extends the lifespan of degradable items while they are stored in specific containers.

### How it works

When an item is moved into a "fridge," the script calculates the remaining life and extends the expiration timestamp. To ensure the UI displays the correct percentage, it also scales the `degrade` metadata. When removed, the process is reversed, returning the item to its original degradation rate.

### Configuration

* **Stash Names:** Any stash name containing the keyword `"fridge"`.
* Tweak `fridgePattern` in [`fridge.lua`](./server/hooks/fridge.lua).


* **Durability Multiplier:** Controlled by `durabilityIncrease` (Default: `2`).
* Doubles the remaining time before the item rots.

</details>

<details>
<summary>Freezer Hook: freeze an items degradation</summary><br/>

The Freezer Hook effectively "pauses" the degradation process entirely.

### How it works

Because `ox_inventory` uses active timestamps for durability, the freezer hook converts the dynamic timestamp into a static percentage value (0–100) and removes the `degrade` metadata. This stops the "countdown."

* **Entering Freezer:** Timestamp -> Static Percentage (e.g., 65%).
* **Exiting Freezer:** Static Percentage -> New Expiry Timestamp based on the current time.

### Configuration

* **Stash Names:** Any stash name containing the keyword `"freezer"`.
* Tweak `freezerPattern` in [`freezer.lua`](./server/hooks/fridge.lua).

</details>

<details>
<summary>Admin Inventory Hook: limitless item spawning</summary><br/>

The Admin Inventory Hook creates a dynamic, secure "sandbox" stash containing every item registered on the server for administrators to pull items from easily.

### How it works

When an administrator runs the management command, the script dynamically scans the server's shared item list, ignores minor items (like identification), and populates a temporary stash with standard stacks of every available item. 

To prevent admins from accidentally making the stash messy or destroying items, the hook explicitly blocks moving items *into* or *swapping* items within this specific inventory. It acts strictly as a "take-only" generation point.

### Configuration

* **Permissions:** Restricted by default to Ace group `group.admin` using the `hooks:admininv` Ace permission node.
* **Commands:** Registered to `/adminitems`, can be used with a search parameter to refine the displayed list of items.

### Limitations
* `identification` item can not be added, as it will attempt to obtain player data from a stash inventory which will not work

</details>

<details>
<summary>Glovebox access restriction</summary><br/>

A hook that prevents players in back seats to open the glovebox, **do note** that this will stop them from opening the inventory in it's entirety meaning they won't even be able view their inventory and move/use items, they'll only have access to their hotbar.

If you want to simply hide the glovebox inventory, you would need to edit the source code of ox_inventory to allow hiding that second inventory.

### How it works

When opening the inventory in a vehicle with a glovebox, the `openInventory` hook will fire the registered callback. This will check if the player is seated in any of the valid seats (by default indices `-1` and `0` - driver & front passenger) and only if the player is found will it allow the glovebox to be accessed.

### Configuration

* **Seat Overrides:** At the top of the file, you can add in overrides for specific models to define what seats can access the glovebox.

### Limitations
* Players can not access their inventory if they can't access the glovebox.

</details>
<details>
<summary>Item Lock Hook: bind items to specific players</summary><br/>

The Item Lock hook prevents players from trading, giving away, or dropping items that are permanently bound to their character's identifier.

### How it works

Because `ox_inventory` handles item movement globally, this hook intercepts `swapItems` actions and checks the item's metadata for an owner identifier. If an item is locked, it strictly limits where the item can be moved.

* **Player -> Drop:** Blocked. Prevents dropping locked items on the ground to give to others.
* **Player -> Player:** Blocked. Prevents trading, giving, or stealing locked items.
* **Player -> Stash:** Allowed (configurable). Allows the owner to store their locked items in non-player inventories (trunks, stashes).
* **Admin Override:** Staff with the configured ace permissions bypass all movement restrictions.

### Configuration

* **Metadata Key:** Set `OWNER_META_KEY` to dictate which metadata field defines ownership (default: `'owner_identifier'`).
* **Stash Storage:** Toggle the `ALLOW_STASHES` boolean to control whether players can place locked items into non-player containers.
* **Admin Permissions:** Adjust `ADMIN_ACE_PERMS` to define which server ace groups can bypass the item locks (default: `'hooks:admininv'`).

</details>

---

## Technical Implementation Notes

### Metadata Handling

* **Fridge:** Modifies `durability` (timestamp) and `degrade` (scale).
* **Freezer:** Converts `durability` to a float (0.0-100.0), sets `degrade` to `nil` and adds a `isFrozen` boolean flag.
