local function loadHooks()
	-- 5 minute timeout
	local timeout = 60 * 5

	while GetResourceState('ox_inventory') ~= 'started' and timeout > 0 do
		Wait(1000)
		timeout = timeout - 1
	end

	if timeout <= 0 then
		error('Unable to load hooks, ox inventory was not started !', 0)
	end

	for _, hook in pairs(Hooks) do
		hook()
	end
end

CreateThread(loadHooks)

AddEventHandler('onResourceStart', function (resource)
	if resource ~= "ox_inventory" then return end

	loadHooks()
end)

lib.versionCheck('Maximus7474/mps-ox-invhooks')
