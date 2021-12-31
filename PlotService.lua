local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Plots = workspace:WaitForChild("Plots")

local PlotService = {}

function PlotService.InitializePlots()
	for _, plot in pairs(Plots:GetChildren()) do
		plot:SetAttribute("Occupant", "None")
	end
end

function PlotService.GetPlot(plr)
	for _, plot in pairs(Plots:GetChildren()) do
		if plot:GetAttribute("Occupant") == plr.Name then
			return plot
		end
	end
	return nil
end

function PlotService.LeavePlot(plr)
	local plot = PlotService.GetPlot(plr)
	if plot then
		plot:SetAttribute("Occupant", "None")
	end
end

function PlotService.OwnPlot(plr, plot, saveName)
	local DataService = require(ReplicatedStorage:WaitForChild("Modules").DataService)
	local char = plr.Character or plr.CharacterAdded:Wait()
	
	if not plot then return nil end
	if not plot:IsA("BasePart") then return nil end
	if plot:GetAttribute("Occupant") ~= "None" then return false end
	
	local loadedPlot = DataService.LoadPlot(plr, plot, saveName)
	plot:SetAttribute("Occupant", plr.Name)

	local cf = plot.PlotSpawn.CFrame
	char.HumanoidRootPart.CFrame = CFrame.new(cf.Position + Vector3.new(0, 5, 0))

	return true, loadedPlot
end

function PlotService.GetAvailablePlots()
	local availablePlots = {}

	for i, plot in pairs(Plots:GetChildren()) do
		if plot:GetAttribute("Occupant") == "None" then
			table.insert(availablePlots, plot)
		end
	end

	return availablePlots
end


function PlotService.EditPlot(player, plotName: string, instruction: string, value)
	local DataService = require(ReplicatedStorage:WaitForChild("Modules").DataService)
	local profile = DataService.GetProfile(player)
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
			["id"] = tostring(plotID),
			["lastUsed"] = nil,
        }
	end

	if instruction == "name" then
		plotData = profile.Data["plots"][plotData.plotID]
        profile.Data["plots"][plotData.id] = {
            ["items"] = plotData.items,
			["name"] = tostring(value),
			["id"] = plotData.id,
			["lastUsed"] = plotData.lastUsed,
        }
		plotData = nil
	else
		return false
	end

	return true
end

return PlotService