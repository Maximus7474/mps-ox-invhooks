Hooks = Hooks or {}

-- Config values

---can the players place identifier locked items in stashes/containers
local ALLOW_STASHES <const> = true

---metadata key for item owner
local OWNER_META_KEY <const> = 'owner_identifier'

---ace permissions required for admin override
local ADMIN_ACE_PERMS <const> = {
	'hooks:admininv',
}

for i = 1, #ADMIN_ACE_PERMS do
	lib.addAce('group.admin', ADMIN_ACE_PERMS[i])
end

-- Business end

local function isItemLocked(item)
    if type(item) ~= 'table' then return false end
    return type(item.metadata) == 'table' and (
	    type(item.metadata[OWNER_META_KEY]) == 'string' or
	    type(item.metadata[OWNER_META_KEY]) == 'number'
    )
end

local function isInventoryPlayer(inventory)
	return type(inventory) == 'number'
end

local function isAdmin(source)
	for i = 1, #ADMIN_ACE_PERMS do
		if IsPlayerAceAllowed(source, ADMIN_ACE_PERMS[i]) then
			return true
		end
	end
	return false
end

---@param payload SwapItemsPayload
local function handleItemSwap(payload)
	lib.print.info('fromSlot', payload.fromSlot, 'fromType', payload.fromType)
	lib.print.info('toSlot', payload.toSlot, 'toType', payload.toType)
	lib.print.info('isItemLocked (fromSlot)', payload.fromSlot and isItemLocked(payload.fromSlot) or 'N/A')

	if not isItemLocked(payload.fromSlot) then return true end
	-- commented during testing
	if isAdmin(payload.source) then return true end

	lib.print.info('same inventory:', payload.fromInventory == payload.toInventory)
	-- allow moving within same inventory
	if payload.fromInventory == payload.toInventory then return true end

	lib.print.info('moving to drop:', payload.toType == 'drop')
	-- deny placing item in a drop (admins can, but only admin & target player can pick up)
	if payload.toType == 'drop' then return false end

	local toInventory = exports.ox_inventory:GetInventory(payload.toInventory)
	local fromInventory = exports.ox_inventory:GetInventory(payload.fromInventory)
	local itemOwner = payload.fromSlot.metadata[OWNER_META_KEY]

	lib.print.info('itemOwner', itemOwner, 'is toInventory a player', not not toInventory.player, 'is fromInventory a player', not not fromInventory.player)
	if toInventory.player and toInventory.player.identifier == itemOwner then
		return true
	end

	if (
		fromInventory.player and
		fromInventory.player.identifier == itemOwner and
		not toInventory.player
	) then
		return true
	end

	return false
end

Hooks.ItemLock = function ()
    RegisterHookAction('swapItems', handleItemSwap)

    lib.print.info('Initialized ItemLock inventory hook')
end
