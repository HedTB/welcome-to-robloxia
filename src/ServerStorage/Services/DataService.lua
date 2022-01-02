-- // SERVICES \\  --

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local HttpService = game:GetService("HttpService")

local ProfileService = require(ServerStorage:WaitForChild("Modules").ProfileService)
local CustomEnums = require(ReplicatedStorage:WaitForChild("Modules").CustomEnums)

-- // VARIABLES \\ --

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
				["plotWorth"] = 0,
			}
		}
	}
)

local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)

-- // FUNCTIONS \\ --

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

local function getPlotWorth(plotData: table)
	local worth = 0
	for _, item in pairs(plotData.items) do
		worth += item.Price
	end
	return worth
end

-- // SERVICE \\ --

local DataService = Knit.CreateService {
	Name = "DataService",
	Client = {},
	_Profiles = {},
}

function DataService:GetProfile(player)
	local profile = self._Profiles[player]
	if profile then
		return profile
	else
		player:Kick("Your data failed to load, please rejoin.\n\nIf this happens repeatedly, please contact a developer.")
	end
end

function DataService:GetPlot(player, plotName: string)
	local profile = self._Profiles[player]
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

function DataService:LoadPlot(player, selectedPlot: BasePart, plotName: string)
	local profile = self._Profiles[player]
	local plots = profile.Data["plots"]
	if not plots then
		profile.Data["plots"] = {}
	end
	
	local plotData = DataService:GetPlot(player, plotName)
    if not plotData then
		local plotID = HttpService:GenerateGUID(false)
        profile.Data["plots"][plotID] = {
            ["items"] = {},
			["name"] = tostring(plotName),
			["lastUsed"] = nil,
			["id"] = plotID,
			["plotWorth"] = 0,
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
			if not item.Price then
				item.Price = clonedItem.Settings.Price.Value
			end
		else
			continue
        end

		clonedItem:PivotTo(selectedPlot.CFrame * CFrame.new(unpack(item.CFrame)))
		clonedItem:SetAttribute("ID", tostring(item.ID))
        clonedItem.Parent = selectedPlot.PlacedItems
    end

	plotData.plotWorth = getPlotWorth(plotData)
	plotData.lastUsed = os.date("%d/%m/%y %H:%M")
	return plotData
end

function DataService.Client:LoadPlot(player, selectedPlot: BasePart, plotName: string)
	return self.Server:LoadPlot(player, selectedPlot, plotName)
end

function DataService:CreatePlot(player, name: string)
	local profile = self._Profiles[player]
	local plots = profile.Data["plots"]
	if not plots then return end
	
	if #plots == 7 then return CustomEnums.PlotSelection.MaxPlots end

	if not plots then
		profile.Data["plots"] = {}
	end

	local plotID = HttpService:GenerateGUID(false)
	plots[plotID] = {
		["items"] = {},
		["name"] = tostring(name),
		["lastUsed"] = nil,
		["id"] = plotID,
		["plotWorth"] = 0,
	}

	return profile.Data["plots"][plotID]
end

function DataService.Client:CreatePlot(player, name: string)
	return self.Server:CreatePlot(player, name)
end

function DataService:SaveItem(player, item: Model, selectedPlot: BasePart, plotID: string)
	local profile = self._Profiles[player]
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
			["plotWorth"] = 0,
        }
    end

	local itemID = HttpService:GenerateGUID(false)
	plotData.items[itemID] = {
        ["CFrame"] = {(selectedPlot.CFrame:Inverse() * item:GetPivot()):GetComponents()},
        ["Name"] = item.Name,
		["ID"] = itemID,
		["Price"] = item.Settings.Price.Value,
    }
	plotData.plotWorth = getPlotWorth(plotData)
	local itemData = plotData.items[itemID]

	return itemData
end

function DataService:EditPlot(player, plotID: string, data: table)
	local profile = DataService:GetProfile(player)
	local plots = profile.Data["plots"]
	if not plots then
		profile.Data["plots"] = {}
		return
	end

	if data["name"] == "" then data["name"] = "Untitled"
	elseif string.len(data["name"]) > 20 or string.len(data["name"]) < 3 then
		return
	end
	profile.Data["plots"][plotID].name = data["name"]

	return CustomEnums.PlotSelection.Success, profile.Data["plots"][plotID]
end

function DataService.Client:EditPlot(player, plotID: string, data: table)
	return self.Server:EditPlot(player, plotID, data)
end

function DataService:GetSavedPlots(player)
	local profile = self._Profiles[player]
	if not profile.Data["plots"] then
		profile.Data["plots"] = {}
	end
	if len(profile.Data["plots"]) > 7 then
		profile.Data["plots"] = {}
	end

	for _, plot in pairs(profile.Data["plots"]) do
		plot.plotWorth = getPlotWorth(plot)
	end

	local plots = profile.Data["plots"]
	return plots
end

function DataService.Client:GetSavedPlots(player)
	return self.Server:GetSavedPlots(player)
end


function DataService:KnitStart()
	print("DataService Started")
end

function DataService:KnitInit()
	Players.PlayerAdded:Connect(function(player)
		local profile = ProfileStore:LoadProfileAsync(
			"UserData_" .. player.UserId,
			"ForceLoad"
		)
		if not profile then
			player:Kick("Your data failed to load, please rejoin.\n\nIf this happens repeatedly, please contact a developer.")
		end
		profile:ListenToRelease(function()
			self._Profiles[player] = nil
			player:Kick()
		end)
	
		if player:IsDescendantOf(Players) then
			self._Profiles[player] = profile
		else
			profile:Release()
		end
	end)
	
	Players.PlayerRemoving:Connect(function(player)
		local profile = self._Profiles[player]
		if profile then
			profile:Release()
		end
	end)

	print("DataService Initialized")
end

return DataService