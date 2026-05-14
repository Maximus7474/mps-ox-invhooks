# Ox Inventory Hooks

  ![](https://img.shields.io/github/downloads/Maximus7474/mps-ox-invhooks/total?logo=github)

A collection of server-side hooks that modify item behavior during inventory transfers within `ox_inventory`.

> [!IMPORTANT]
> This script will work best with `v2.47.0` of ox_inventory (when released), as it provides a more reliable method in acting on the item's metadata.
> No changes will need to be made to this script, it'll detect if using the appropriate version and act accordingly.

## Hooks:

<details>
<summary>Fridge Hook: extend an items lifespan</summary>

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
<summary>Freezer Hook: freeze an items degradation</summary>

The Freezer Hook effectively "pauses" the degradation process entirely.

### How it works

Because `ox_inventory` uses active timestamps for durability, the freezer hook converts the dynamic timestamp into a static percentage value (0–100) and removes the `degrade` metadata. This stops the "countdown."

* **Entering Freezer:** Timestamp $\rightarrow$ Static Percentage (e.g., 65%).
* **Exiting Freezer:** Static Percentage $\rightarrow$ New Expiry Timestamp based on the current time.

### Configuration

* **Stash Names:** Any stash name containing the keyword `"freezer"`.
* Tweak `freezerPattern` in [`freezer.lua`](./server/hooks/fridge.lua).

</details>

---

## Technical Implementation Notes

### Metadata Handling

* **Fridge:** Modifies `durability` (timestamp) and `degrade` (scale).
* **Freezer:** Converts `durability` to a float (0.0-100.0), sets `degrade` to `nil` and adds a `isFrozen` boolean flag.
