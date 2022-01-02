-- // VARAIBLES \\ --

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Plots = workspace:WaitForChild("Plots")
local Knit = require(ReplicatedStorage.Packages.Knit)

-- // FUNCTIONS \\ --

local function getPlotWorth(plotData: table)
	local worth = 0
	for _, item in pairs(plotData.items) do
		worth += item.Price
	end
	return worth
end

-- // SERVICE \\ --

local PlotService = Knit.CreateService {
	Name = "PlotService",
	Client = {},
	_Plots = {},
}

function PlotService:GetOwnedPlot(player)
	for _, plot in pairs(Plots:GetChildren()) do
		if plot:GetAttribute("Occupant") == player.Name then
			return plot
		end
	end
	return nil
end

function PlotService:LeavePlot(player)
	local plot = PlotService:GetOwnedPlot(player)
	if plot then
		plot:SetAttribute("Occupant", "None")
	end
end

function PlotService.Client:OwnPlot(player: Player, plot: Part, saveName: string)
	return self.Server:OwnPlot(player, plot, saveName)
end

function PlotService:OwnPlot(player, plot, saveName)
	local DataService = require(ReplicatedStorage:WaitForChild("Modules").DataService)
	local char = player.Character or player.CharacterAdded:Wait()
	
	if not plot then return nil end
	if not plot:IsA("BasePart") then return nil end
	if plot:GetAttribute("Occupant") ~= "None" then return false end
	
	local loadedPlot = DataService.LoadPlot(player, plot, saveName)
	plot:SetAttribute("Occupant", player.Name)

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


function PlotService:EditPlot(player, plotID: string, instruction: string, value)
	local DataService = require(ReplicatedStorage:WaitForChild("Modules").DataService)
	
	return DataService:EditPlot(player, plotID, instruction, value)
end


function PlotService:KnitStart()
	print("PlotService Started")
end

function PlotService:KnitInit()
	for _, plot in pairs(Plots:GetChildren()) do
		plot:SetAttribute("Occupant", "None")
	end
	Players.PlayerRemoving:Connect(function(player)
		self:LeavePlot(player)
	end)
end

return PlotService