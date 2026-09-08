Hooks = Hooks or {}

local itemList = lib.require('@ox_inventory.modules.items.shared')

local adminAcePerms = {
	'hooks:admininv',
}

for i = 1, #adminAcePerms do
	lib.addAce('group.admin', adminAcePerms[i])
end

local openInventories = {}

local function canUseAdminInv(src)
	for j = 1, #adminAcePerms do
		if IsPlayerAceAllowed(src, adminAcePerms[j]) then
			return true
		end
	end

	return false
end

---@param search? string | false
local function createAdminInvStash(search)
	local itemCount = 0
	local maxWeight = 0
	local items = {}

	search = search and string.lower(search) or false

	for item, data in pairs(itemList) do
		if item == 'identification' then goto continue end

		local addToInv = false

		if search then
			local startIdx, _ = string.find(string.lower(item), search, 1, true)
			addToInv = not not startIdx
		else
			addToInv = true
		end

		if addToInv then
			local count = 50

			if data.stack == false then
				count = 1
			end

			items[#items+1] = { item, count }
			maxWeight += data.weight * count
			itemCount += 1
		end

	    ::continue::
	end

	local id = exports.ox_inventory:CreateTemporaryStash({
		label = 'Admin Item Inventory',
		slots = itemCount,
		maxWeight = maxWeight,
		items = items,
	})

	return id
end

---@param payload SwapItemsPayload
---@return boolean
local function idealHandlePreSwap(payload)
	if not lib.table.contains(openInventories, payload.fromInventory) then return true end

	if not canUseAdminInv(payload.source) then
		lib.print.warn(('Player %d tried to use admin inventory when not ace allowed !'):format(payload.source))
		return false
	end

	if payload.action == 'swap' then
		lib.notify(payload.source, {
			title = 'Action Denied',
			description = 'You can not swap items with this inventory',
			type = 'warning'
		})
	end

	return false
end

---@param success boolean
---@param payload SwapItemsPayload
local function idealHandlePostSwap(success, payload)
	-- shouldn't succeed
	if success then return end
	-- no swapping
	if payload.action == 'swap' then return end

	-- check that from inv is an admin inv
	if not lib.table.contains(openInventories, payload.fromInventory) then return end

	if not canUseAdminInv(payload.source) then return end

	-- this should only trigger when the target inventory is the players
	if payload.toInventory ~= payload.source then return end

	local src = payload.source
	local count = payload.count
	local item = payload.fromSlot
	local slot = ((type(payload.toSlot) == "number" and payload.toSlot or payload.toSlot.slot) --[[@as number]])

	local addSuccess = exports.ox_inventory:AddItem(src, item.name, count, nil, slot)

	if not addSuccess then
		lib.notify(payload.source, {
			title = 'Action Failed',
			description = 'Something went wrong',
			type = 'error'
		})
	end
end

---@param payload SwapItemsPayload
---@return boolean
local function unidealHandleSwap(payload)
	if not lib.table.contains(openInventories, payload.fromInventory) then return true end
	if not canUseAdminInv(payload.source) then
		lib.print.warn(('Player %d tried to use admin inventory when not ace allowed !'):format(payload.source))
		return false
	end

	if payload.action == 'swap' then
		lib.notify(payload.source, {
			title = 'Action Denied',
			description = 'You can not swap items with this inventory',
			type = 'warning'
		})
		return false
	end

	local src = payload.source
	local count = payload.count
	local item = payload.fromSlot
	local slot = ((type(payload.toSlot) == "number" and payload.toSlot or payload.toSlot.slot) --[[@as number]])

	Citizen.SetTimeout(100, function()
        local addSuccess = exports.ox_inventory:AddItem(src, item.name, count, nil, slot)

		if not addSuccess then
			lib.notify(payload.source, {
				title = 'Action Failed',
				description = 'Something went wrong',
				type = 'error'
			})
		end
    end)

	return false
end

Hooks.AdminInvOpen = function ()

	---@param payload OpenInventoryPayload
	RegisterHookAction('openInventory', function (payload)
		if not lib.table.contains(openInventories, payload.inventoryId) then return true end

		if not canUseAdminInv(payload.source) then
			lib.print.warn(('Player %d tried to open admin inventory when not ace allowed !'):format(payload.source))
			return false
		end

		return true
	end)

	lib.print.info('Initialized Admin inventory openInventory hook')
end

Hooks.AdminInvSwap = function ()
    local useIdeal = IsInventoryMinimumVersion()
    local before, after

    if useIdeal then
		before = idealHandlePreSwap
        after = idealHandlePostSwap
    else
        before = unidealHandleSwap
    end

    RegisterHookAction('swapItems', before, after)

	lib.print.info('Initialized Admin inventory swapItems hook')
end

lib.addCommand('adminitems', {
	help = 'Open inventory with all items',
	restricted = 'group.admin',
	params = {{
		name = "search",
		help = "Item name to search for, will narrow the displayed items",
		optional = true
	}}
}, function (source, args)
	local invId = createAdminInvStash(args.search)
	table.insert(openInventories, invId)
	exports.ox_inventory:forceOpenInventory(source, 'stash', invId)
end)

---@param _ number
---@param inventoryId string
AddEventHandler('ox_inventory:closedInventory', function (_, inventoryId)
	local isAdminInv, idx = lib.table.contains(openInventories, inventoryId)
	if isAdminInv then
		exports.ox_inventory:RemoveInventory(inventoryId)
		table.remove(openInventories, idx)
	end
end)
