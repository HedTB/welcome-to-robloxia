local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local Modules = ReplicatedStorage:WaitForChild("Modules")

local PlotService = require(Modules.PlotService)
local DataService = require(Modules.DataService)
local CustomEnums = require(Modules.CustomEnums)

Remotes.PlotSelection.RequestPlot.OnServerInvoke = function(player, plot, saveName)
	local success, plot = PlotService.OwnPlot(player, plot, saveName)

	if success == nil then
		return CustomEnums.PlotSelection.Invalid
	elseif success == false then
		return CustomEnums.PlotSelection.Unavailable
    else
		player:SetAttribute("LoadedPlot", plot.id)
        return CustomEnums.PlotSelection.Success
	end
end

Players.PlayerRemoving:Connect(function(player)
	PlotService.LeavePlot(player)
end)

Remotes.PlotSelection.LeavePlot.OnServerEvent:Connect(function(player)
	PlotService.LeavePlot(player)
end)

Remotes.PlotSelection.GetPlots.OnServerInvoke = function(player)
	return DataService.GetSavedPlots(player)
end

Remotes.PlotSelection.CreatePlot.OnServerInvoke = function(player, name: string)
	local profile = DataService.GetProfile(player)
	local plots = profile.Data["plots"]
	if not plots then return end
	
	if #plots == 7 then return CustomEnums.PlotSelection.MaxPlots end
	return DataService.CreatePlot(player, name)
end

Remotes.PlotSelection.EditPlot.OnServerInvoke = function(player, plotID: string, data: table)
	local profile = DataService.GetProfile(player)
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