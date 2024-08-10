local config = lib.require('config')
local stevo_lib = exports['stevo_lib']:import()
lib.locale()


local ComputerZone = lib.points.new({
	coords = config.computer.coords,
	distance = config.computer.viewdistance,
	computer = false,
})

function ComputerZone:onEnter()
    self.computer = CreateObject(config.computer.model, config.computer.coords, true)
    FreezeEntityPosition(self.computer, true)
end
 
function ComputerZone:onExit()
    DeleteEntity(self.computer)
end

local InteractZone = lib.points.new({
	coords = config.computer.coords,
	distance = 2,
})

function InteractZone:onEnter()
	lib.showTextUI('[E] - View Computer')
end
 
function InteractZone:onExit()
    lib.hideTextUI()
end

function InteractZone:nearby()
    if IsControlJustReleased(0, 38) then
		local crateCooldown, hasUsb = lib.callback.await('stevo_cayocrates:data', false)

		SetNuiFocus(true, true)
		SendNUIMessage({
			action = "openLaptop",
			hasUsb = hasUsb,
			crateCooldown = crateCooldown,
		})
    end
end

local function closeLaptop()
    SetNuiFocus(false, false)
end

RegisterNUICallback('closeLaptop', closeLaptop)

local function crateDrop()
	TriggerServerEvent('stevo_cayocrates:createdrop')
	SendNUIMessage({
		action = "closeLaptop",
	})
	closeLaptop()
end

RegisterNUICallback('crateDrop', crateDrop)

local CURRENT_DROP = false
local CRATE_POINT = false
local RADIUS_BLIP

function openingCrate()
	if lib.progressBar({
		duration = config.crates.opening_time,
		label = config.locales.opening_crate,
		useWhileDead = false,
		canCancel = true,
		disable = {
			car = true,
			move = true
		},
		anim = {
			dict = 'anim@gangops@facility@servers@bodysearch@',
			clip = 'player_search'
		},
	}) then 
		lib.notify({
			title = 'Opened Crate',
			type = 'success'
		})
		TriggerServerEvent('stevo_cayocrates:networksync', 'crateopen')
	else 
		lib.notify({
			title = 'Cancelled opening',
			type = 'error'
		})
		TriggerServerEvent('stevo_cayocrates:networksync', 'cancelopen')
	end
end


RegisterNetEvent('stevo_cayocrates:createdrop', function(DROP)
	CURRENT_DROP = DROP


	CRATE_POINT = lib.points.new({
		coords = vec3(CURRENT_DROP.coords.x, CURRENT_DROP.coords.y, CURRENT_DROP.coords.z),
		distance = 50,
		crate = false,
	})
	
	function CRATE_POINT:onEnter()
		lib.requestModel(config.crates.model)
		self.crate = CreateObject(config.crates.model, CURRENT_DROP.coords.x, CURRENT_DROP.coords.y, CURRENT_DROP.coords.z, true)
		CRATE_OBJECT = self.crate
		FreezeEntityPosition(self.crate, true)

		local coords = CURRENT_DROP.coords
		
		local offsets = {
			[1] = vec3(coords.x+5, coords.y, coords.z),
			[2] = vec3(coords.x-5, coords.y, coords.z),
			[3] = vec3(coords.x, coords.y-5, coords.z),
			[4] = vec3(coords.x, coords.y+5, coords.z),


		}

		lib.requestWeaponAsset(GetHashKey("weapon_flare"))
	
		for i = 1, 4 do		
			ShootSingleBulletBetweenCoords(vec3(coords.x, coords.y, coords.z + 10), offsets[i], 0, false, GetHashKey("weapon_flare"), 0, true, true, -1.0)
		end
	end
	 
	function CRATE_POINT:onExit()
		DeleteEntity(self.crate)
	end

	function CRATE_POINT:nearby()
		if self.currentDistance < 3 and not CURRENT_DROP.owned and CRATE_POINT ~= false then
			local onScreen, _x, _y = World3dToScreen2d(CURRENT_DROP.coords.x, CURRENT_DROP.coords.y, CURRENT_DROP.coords.z+1)

			if onScreen then
				SetTextScale(0.4, 0.4)
				SetTextFont(4)
				SetTextProportional(1)
				SetTextColour(255, 255, 255, 255)
				SetTextOutline()
				SetTextEntry("STRING")
				SetTextCentre(true)
				AddTextComponentString(config.locales.open_crate)
				DrawText(_x, _y)
			end
		end

		if self.currentDistance < 3 and IsControlJustReleased(0, 38) and not CURRENT_DROP.owned then
			if stevo_lib.IsDead() then return end
			CreateThread(function()
				TriggerServerEvent('stevo_cayocrates:networksync', 'open')
				openingCrate()
			end)
		end
	end
end)

RegisterNetEvent('stevo_cayocrates:networksync', function(action, DROP)

	if action == 'crateopen' then

		local coords = CURRENT_DROP.coords

		local dist = #(GetEntityCoords(cache.ped - coords))

		RemoveBlip(RADIUS_BLIP)

		if dist <= 100 then 
			CRATE_POINT:remove()
			CRATE_POINT = false
		else 
			CRATE_POINT:onExit()
			CRATE_POINT:remove()
			CRATE_POINT = false
		end

		if dist <= 100 then 
			local coords = CURRENT_DROP.coords
			
			lib.notify({
				title = 'Get Away from the crate!',
				duration = 5000,
				type = 'error'
			})
			if config.explosion then 
				Wait(8000)
				local dist = #(GetEntityCoords(cache.ped - coords))
				if dist <= 100 then 
					AddExplosion(coords, 9, 0.9, 1, 0, 1065353216, 0)
					Wait(1000)
				end
			end
		end
	end

	CURRENT_DROP = DROP

end)

RegisterNetEvent('stevo_cayocrates:createblip', function(coords)
	RADIUS_BLIP = AddBlipForRadius(coords, 100.0)
	SetBlipColour(RADIUS_BLIP, 1)
	SetBlipAlpha(RADIUS_BLIP, 128)
end)


RegisterCommand('crate', function()
	TriggerServerEvent('stevo_cayocrates:createdrop')
end)
