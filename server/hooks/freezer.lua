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

Hooks.Freezer = function ()
	exports.ox_inventory:registerHook('swapItems',
	---@param payload SwapItemsPayload
	---@return boolean
	function (payload)
		-- boolean values
		local toFreezer = SatisfiesPatterns(payload.toInventory, freezerPatterns)
		local fromFreezer = SatisfiesPatterns(payload.fromInventory, freezerPatterns)

		-- indicates that the items stayed in the originating inventory
		if toFreezer == fromFreezer then
			return true
		end

		local item = payload.fromSlot
        local itemData = hasDegrade(item.name)
        if not itemData then return true end

        local currentTime = os.time()
        local inventory = payload.toInventory
        local slotId = type(payload.toSlot) == "number" and payload.toSlot or payload.toSlot.slot
        local newMeta = item.metadata

        if toFreezer then
            local secondsLeft = item.metadata.durability - currentTime
            local totalSeconds = (item.metadata.degrade or itemData.degrade) * 60
            local lifePercent = math.max(0, secondsLeft / totalSeconds)

            newMeta.durability = lifePercent * 100
            newMeta.degrade = nil
            newMeta.isFrozen = true
        else
            local lifePercent = item.metadata.durability / 100
            local originalMaxSeconds = itemData.degrade * 60

            newMeta.durability = math.floor(currentTime + (originalMaxSeconds * lifePercent))
            newMeta.degrade = itemData.degrade
            newMeta.isFrozen = nil
        end

        Citizen.SetTimeout(100, function()
            exports.ox_inventory:SetMetadata(inventory, slotId, newMeta)
        end)

		return true
	end, {
		inventoryFilter = freezerPatterns,
	})

	lib.print.info('Initialized Freezer inventory hook')
end
