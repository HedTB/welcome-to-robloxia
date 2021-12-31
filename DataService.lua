local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local DataStoreService = game:GetService("DataStoreService")

local ProfileService = require(script.Parent:WaitForChild("ProfileService"))

local PlotID = HttpService:GenerateGUID(false)
local ProfileStore = ProfileService.GetProfileStore(
	"Player",
	{
		["money"] = 10000,
		["roMoney"] = 0,
        ["plots"] = {
			[PlotID] = {
				["items"] = {},
				["name"] = "My Beautiful Home",
				["lastUsed"] = nil,
				["worth"] = 0,
				["id"] = PlotID,
			}
		}
	}
)

local Profiles = {}

Players.PlayerAdded:Connect(function(player)
	local profile = ProfileStore:LoadProfileAsync(
		"UserData_" .. player.UserId,
		"ForceLoad"
	)

	if profile then
		profile:ListenToRelease(function()
			Profiles[player] = nil
			player:Kick()
		end)

		if player:IsDescendantOf(Players) then
			Profiles[player] = profile
			task.wait(0.5)
			ReplicatedStorage:WaitForChild("Remotes").LocalEvents.MoneyChange:FireClient(player, profile.Data.money, profile.Data.roMoney)
		else
			profile:Release()
		end
	else
		player:Kick("Your data failed to load, please rejoin.\n\nIf this happens repeatedly, please contact a developer.")
	end
end)

Players.PlayerRemoving:Connect(function(player)
	local profile = Profiles[player]
	if profile then
		profile:Release()
	end
end)

local function len(t)
	local n = 0
	
	for _ in pairs(t) do
		n = n + 1
	end
	return n
end

local function findItem(itemName)
	for _, item in pairs(ReplicatedStorage:WaitForChild("Items"):GetDescendants()) do
		if item.Name == itemName then
			return item
		end
	end
	return nil
end

local DataService = {}

function DataService.GetProfile(player)
	local profile = Profiles[player]
	if profile then
		return profile
	end
end

function DataService.GetPlot(player, plotName: string)
	local profile = Profiles[player]
	local plots = profile.Data["plots"]
	if not plots then
		profile.Data["plots"] = {}
		return nil
	end

	for _, plot in pairs(plots) do
		if plot.name == plotName then
			return plot
		end
	end
	return nil
end

function DataService.LoadPlot(player, selectedPlot: BasePart, plotName: string)
	local profile = Profiles[player]
	local plots = profile.Data["plots"]
	if not plots then
		profile.Data["plots"] = {}
	end
	
	local plotData = DataService.GetPlot(player, plotName)
    if not plotData then
		local plotID = HttpService:GenerateGUID(false)
        profile.Data["plots"][plotID] = {
            ["items"] = {},
			["name"] = tostring(plotName),
			["lastUsed"] = nil,
			["id"] = plotID,
        }
		plotData = profile.Data["plots"][plotName]
	end

	if not plotData["items"] then
		plotData["items"] = {}
	end

    for _, item in pairs(plotData["items"]) do
        local clonedItem
        if findItem(item.Name) then
            clonedItem = findItem(item.Name):Clone()
		else
			continue
        end

		clonedItem:PivotTo(selectedPlot.CFrame * CFrame.new(unpack(item.CFrame)))
		clonedItem:SetAttribute("ID", tostring(item.ID))
        clonedItem.Parent = selectedPlot.PlacedItems
    end

	plotData["lastUsed"] = os.date("%d/%m/%y %H:%M")
	return plotData
end

function DataService.CreatePlot(player, name: string)
	local profile = Profiles[player]
	if not profile.Data["plots"] then
		profile.Data["plots"] = {}
	end

	local plotID = HttpService:GenerateGUID(false)
	profile.Data["plots"][plotID] = {
		["items"] = {},
		["name"] = tostring(name),
		["lastUsed"] = nil,
		["id"] = plotID,
	}

	return profile.Data["plots"][plotID]
end

function DataService.SaveItem(player, item: Model, selectedPlot: BasePart, plotID: string)
	local profile = Profiles[player]
	if not profile.Data["plots"] then
		profile.Data["plots"] = {}
	end
    local plotData = profile.Data["plots"][plotID]
    if not plotData then
		local plotID = HttpService:GenerateGUID(false)
        profile.Data["plots"][plotID] = {
            ["items"] = {},
			["name"] = "My Beautiful Home",
			["lastUsed"] = nil,
			["id"] = plotID,
        }
    end

	local itemID = HttpService:GenerateGUID(false)
	plotData.items[itemID] = {
        ["CFrame"] = {(selectedPlot.CFrame:Inverse() * item:GetPivot()):GetComponents()},
        ["Name"] = item.Name,
		["ID"] = itemID,
    }
	local itemData = plotData.items[itemID]

	return itemData
end

function DataService.GetSavedPlots(player)
	local profile = Profiles[player]
	if not profile.Data["plots"] then
		profile.Data["plots"] = {}
	end
	if len(profile.Data["plots"]) > 7 then
		profile.Data["plots"] = {}
	end

	return profile.Data["plots"]
end

return DataService