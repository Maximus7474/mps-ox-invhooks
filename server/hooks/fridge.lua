Hooks = Hooks or {}

-- Config values

-- the string identifier to determine a stash is a fridge
local fridgePatterns = {
	"fridge"
}
-- 2 means that the time left until it degrades is twice as long
local durabilityIncrease = 2

-- Business end

local cache = {} --[[ @as table<string, { degrade: number } | false> ]]

---@param itemname string
---@return { degrade: number } | boolean
local function hasDegrade(itemname)
	if cache[itemname] then return cache[itemname] end

	local item = exports.ox_inventory:Items(itemname)
	if not item then return false end

	cache[itemname] = type(item.degrade) == 'number' and { degrade = item.degrade } or false

	return cache[itemname]
end

---helper func to get updated metadata
---@param item OxItem
---@param toFridge boolean is item moved to a fridge
---@return nil | table newMeta nil if not applicable by hook logic
local function getUpdatedMetadata(item, toFridge)
    local degradeable = hasDegrade(item.name)
    if not degradeable or not item.metadata.durability or item.metadata.durability == 0 then
        return nil
    end

    local currentTime = os.time()
    local secondsLeft = item.metadata.durability - currentTime
    if secondsLeft <= 0 then return nil end

    local newMeta = table.clone(item.metadata)

    if toFridge then
        newMeta.degrade = degradeable.degrade * durabilityIncrease
        newMeta.durability = math.floor(currentTime + (secondsLeft * durabilityIncrease))
    else
        newMeta.degrade = degradeable.degrade
        newMeta.durability = math.floor(currentTime + (secondsLeft / durabilityIncrease))
    end

    return newMeta
end

---main logic for handling item meta updating
---@param payload SwapItemsPayload
---@return nil | string | number | table inventoryId
---@return nil | number slotId
---@return nil | table newMeta
local function handleFridgeLogic(payload)
    local toFridge = SatisfiesPatterns(payload.toInventory, fridgePatterns)
    local fromFridge = SatisfiesPatterns(payload.fromInventory, fridgePatterns)

    if toFridge == fromFridge then return nil, nil, nil end

    local newMeta = getUpdatedMetadata(payload.fromSlot, toFridge)
    if not newMeta then return nil, nil, nil end

    local slotId = type(payload.toSlot) == "number" and payload.toSlot or payload.toSlot.slot --[[ @as number ]]
    return payload.toInventory, slotId, newMeta
end

---@param payload SwapItemsPayload
local function unidealHookCb(payload)
    local inv, slot, meta = handleFridgeLogic(payload)
    if not inv or not slot or not meta then return true end

    Citizen.SetTimeout(100, function()
        exports.ox_inventory:SetMetadata(inv, slot, meta)
    end)

    return true
end

---@param success boolean
---@param payload SwapItemsPayload
local function idealHookCb(success, payload)
    if not success then return end

    local inv, slot, meta = handleFridgeLogic(payload)
    if not inv or not slot or not meta then return true end

    exports.ox_inventory:SetMetadata(inv, slot, meta)
end

Hooks.Fridge = function ()
    local useIdeal = IsInventoryMinimumVersion()
    local before, after

    if useIdeal then
        after = idealHookCb
    else
        before = unidealHookCb
    end

    RegisterHookAction('swapItems', before, after, fridgePatterns)

	lib.print.info('Initialized Fridge inventory hook')
end
