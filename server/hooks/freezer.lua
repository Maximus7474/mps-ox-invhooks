Hooks = Hooks or {}

-- Config values

-- the string identifier to determine a stash is a freezer
local freezerPatterns = {
	"freezer"
}

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

---helper func to get updated metadata for freezer logic
---@param item any
---@param toFreezer boolean is item moved to a freezer
---@return nil | table newMeta nil if not applicable by hook logic
local function getUpdatedFreezerMetadata(item, toFreezer)
    local itemData = hasDegrade(item.name)
    if not itemData or not item.metadata.durability then return nil end

    local currentTime = os.time()
    local newMeta = table.clone(item.metadata)

    if toFreezer then
        -- vonvert timestamp to percentage
        local secondsLeft = item.metadata.durability - currentTime
        local totalSeconds = (item.metadata.degrade or itemData.degrade) * 60
        local lifePercent = math.max(0, secondsLeft / totalSeconds)

        newMeta.durability = lifePercent * 100
        newMeta.degrade = nil
        newMeta.isFrozen = true
    else
        -- convert percentage back to timestamp
        local lifePercent = (item.metadata.durability or 0) / 100
        local originalMaxSeconds = itemData.degrade * 60

        newMeta.durability = math.floor(currentTime + (originalMaxSeconds * lifePercent))
        newMeta.degrade = itemData.degrade
        newMeta.isFrozen = nil
    end

    return newMeta
end

---main logic for handling freezer item meta updating
---@param payload SwapItemsPayload
---@return nil | string | number | table inventoryId
---@return nil | number slotId
---@return nil | table newMeta
local function handleFreezerLogic(payload)
    -- boolean values
    local toFreezer = SatisfiesPatterns(payload.toInventory, freezerPatterns)
    local fromFreezer = SatisfiesPatterns(payload.fromInventory, freezerPatterns)

    -- indicates that the items stayed in the originating inventory
    if toFreezer == fromFreezer then return nil, nil, nil end

    local newMeta = getUpdatedFreezerMetadata(payload.fromSlot, toFreezer)
    if not newMeta then return nil, nil, nil end

    local slotId = type(payload.toSlot) == "number" and payload.toSlot or payload.toSlot.slot --[[ @as number ]]
    return payload.toInventory, slotId, newMeta
end

---in the case of an outdated ox_inventory
---@param payload SwapItemsPayload
---@return boolean
local function unidealFreezerHookCb(payload)
    local inv, slot, meta = handleFreezerLogic(payload)
    if not inv or not slot or not meta then return true end

    Citizen.SetTimeout(100, function()
        exports.ox_inventory:SetMetadata(inv, slot, meta)
    end)

    return true
end

---in the case of an good version of ox_inventory
---@param success boolean
---@param payload SwapItemsPayload
local function idealFreezerHookCb(success, payload)
    if not success then return end

    local inv, slot, meta = handleFreezerLogic(payload)
    if not inv or not slot or not meta then return end

    exports.ox_inventory:SetMetadata(inv, slot, meta)
end

Hooks.Freezer = function ()
    local useIdeal = IsInventoryMinimumVersion()
    local before, after

    if useIdeal then
        after = idealFreezerHookCb
    else
        before = unidealFreezerHookCb
    end

    RegisterHookAction('swapItems', before, after, freezerPatterns)
    lib.print.info('Initialized Freezer inventory hook')
end

-- formatted durability 76.75
