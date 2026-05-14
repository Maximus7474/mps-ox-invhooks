---check if a value is concerned by a pattern group
---@param value any
---@param patterns table<string>
---@return boolean
function SatisfiesPatterns(value, patterns)
	if type(value) ~= "string" then return false end

    for i = 1, #patterns do
        local pattern = patterns[i]

        if string.find(value:lower(), pattern:lower(), 1, true) then
            return true
        end
    end

    return false
end

local hookSideEffectListenersRecordSeeLongNamesAreFun = {}

---basic wrapper used for this resource, pitches into DRY coding practices
---@param hookname 'swapItems' | 'openInventory' | 'openShop' | 'createItem' | 'buyItem' | 'craftItem' | 'usingItem'
---@param hookcb function | nil
---@param posthookcb function | nil
---@param patterns table<string>
function RegisterHookAction(hookname, hookcb, posthookcb, patterns)
	local hookid = exports.ox_inventory:registerHook(hookname, hookcb, { inventoryFilter = patterns })

	if not posthookcb then return end

	local listner = AddEventHandler(hookid, function (success, payload)
		if not success then return end

		posthookcb(payload)
	end)

	hookSideEffectListenersRecordSeeLongNamesAreFun[#hookSideEffectListenersRecordSeeLongNamesAreFun+1] = listner
end

AddEventHandler('onResourceStop', function (resource)
	if resource ~= 'ox_inventory' then return end

	for i = 1, #hookSideEffectListenersRecordSeeLongNamesAreFun, 1 do
		local listener = hookSideEffectListenersRecordSeeLongNamesAreFun[i]
		RemoveEventHandler(listener)
	end
end)

---checks if ox inventory is the minimum required version (v2.47.0) to function properly
---@return boolean
function IsInventoryMinimumVersion()
    local version = GetResourceMetadata('ox_inventory', 'version', 0)
    if not version then return false end

    local major, minor, patch = version:match("^(%d+)%.(%d+)%.(%d+)$")
    major, minor, patch = tonumber(major), tonumber(minor), tonumber(patch)

    if not major or not minor or not patch then return false end

    if major > 2 then return true end
    if major < 2 then return false end

    return minor > 46
end

if not IsInventoryMinimumVersion() then
    lib.print.warn('Invalid ox_inventory version!')
    lib.print.warn('Update to v2.47.0+ ASAP to avoid conflicts.')
end
