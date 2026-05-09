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

Hooks.Fridge = function ()
	exports.ox_inventory:registerHook('swapItems',
	---@param payload SwapItemsPayload
	---@return boolean
	function (payload)
		-- boolean values
		local toFridge = SatisfiesPatterns(payload.toInventory, fridgePatterns)
		local fromFridge = SatisfiesPatterns(payload.fromInventory, fridgePatterns)

		-- indicates that the items stayed in the originating inventory
		if toFridge == fromFridge then
			return true
		end

		local item = payload.fromSlot
		local degradeable = hasDegrade(item.name)

		if not degradeable or item.metadata.durability == 0 then return true end

		local currentTime = os.time()
		local secondsLeft = item.metadata.durability - currentTime
		if secondsLeft <= 0 then return true end


		local inventory = payload.toInventory
		local slotId = type(payload.toSlot) == "number" and payload.toSlot or payload.toSlot.slot --[[ @as number ]]

		local newDegrade = toFridge and (
			degradeable.degrade * durabilityIncrease
		) or (
			degradeable.degrade
		)

		local newDurability = math.floor(currentTime + (
			toFridge and (
				secondsLeft * durabilityIncrease
			) or (
				secondsLeft / durabilityIncrease
			)
		))

		Citizen.SetTimeout(100, function ()
			local newMeta = item.metadata

			newMeta.degrade = newDegrade
			newMeta.durability = newDurability

			exports.ox_inventory:SetMetadata(
				inventory, slotId, newMeta
			)
		end)

		return true
	end, {
		inventoryFilter = fridgePatterns,
	})

	lib.print.info('Initialized Fridge inventory hook')
end
