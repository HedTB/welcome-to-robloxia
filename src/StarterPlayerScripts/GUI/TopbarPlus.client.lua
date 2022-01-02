-- // SERIVCES \\ --

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")

-- // IMPORTANT VARIABLES \\ --

local Modules = ReplicatedStorage:WaitForChild("Modules")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local player = Players.LocalPlayer

-- // MODULEs \\ --

local Knit = require(ReplicatedStorage.Packages.Knit)
local TopbarPlus = require(Modules.Icon)
local UIService = require(Modules.UIService)
local InteractionService = require(Modules.InteractionService)

-- // CREATE TOPBAR PLUS \\ --

local Clock = TopbarPlus.new()

local HomeButton = TopbarPlus.new()
local BuildModeButton = TopbarPlus.new()
local EditHomeButton = TopbarPlus.new()
local ViewPlotButton = TopbarPlus.new()

-- // SET UP \\ --

Clock:setMid()
Clock:setSize(55, 32)
Clock:lock()
InteractionService:CreateInteraction({
	["1"] = {
		["Text"] = "Test",
		["Function"] = function()
			print("test")
			task.spawn(function()
				task.wait(1)
				InteractionService:OpenInteraction("Test")
			end)
		end
	},
	["2"] = {
		["Text"] = "Test2",
		["Function"] = function()
			print("test2")
			task.spawn(function()
				task.wait(1)
				InteractionService:OpenInteraction("Test")
			end)
		end
	},
	["3"] = {
		["Text"] = "Test3",
		["Function"] = function()
			print("test3")
			task.spawn(function()
				task.wait(1)
				InteractionService:OpenInteraction("Test")
			end)
		end
	}
}, workspace.Part, "Test", UDim2.new(0.7, 0, 0.7, 0), 70)

HomeButton:setImage("rbxassetid://8062280634")
HomeButton:setLeft()
HomeButton:setName("home")

BuildModeButton:setImage("rbxassetid://8062382215")
BuildModeButton:setName("buildmode")
BuildModeButton:setTip("Build Mode")

EditHomeButton:setImage("rbxassetid://8062377683")
EditHomeButton:setName("editHome")
EditHomeButton:setTip("Edit Home")

ViewPlotButton:setImage("rbxassetid://8062378990")
ViewPlotButton:setName("viewPlot")
ViewPlotButton:setTip("View Plot")

HomeButton:setDropdown({BuildModeButton, EditHomeButton, ViewPlotButton})

-- // HANDLE TOPBAR PLUS \\ --

task.spawn(function()
	while true do
		local currentTime = string.sub(Lighting.TimeOfDay, 0, 5)
		Clock:setLabel(currentTime)
		task.wait(0.5)
	end
end)

ViewPlotButton:bindEvent("selected", function()
	local PlotService = Knit.GetService("PlotService")
	local plot = PlotService:GetOwnedPlot(player)
	if plot ~= nil then
		Remotes.LocalEvents.OrbitPlot:Fire("start", plot)
	else
		UIService:Error("You don't own a plot")
		task.wait(0.35)
		ViewPlotButton:deselect()
	end
end)
ViewPlotButton:bindEvent("deselected", function()
	ViewPlotButton:lock()
	local PlotService = Knit.GetService("PlotService")
	local plot = PlotService:GetOwnedPlot(player)
	if plot ~= nil then
		Remotes.LocalEvents.OrbitPlot:Fire("stop", plot)
	end
	task.wait(1)
	ViewPlotButton:unlock()
end)

BuildModeButton:bindEvent("selected", function()
	local PlotService = Knit.GetService("PlotService")
	local plot = PlotService:GetOwnedPlot(player)
	if plot ~= nil then
		Remotes.LocalEvents.BuildSystem:Fire("open", nil, plot)
	else
		UIService:Error("You don't own a plot")
		task.wait(0.35)
		BuildModeButton:deselect()
	end
end)
BuildModeButton:bindEvent("deselected", function()
	local PlotService = Knit.GetService("PlotService")
	local plot = PlotService:GetOwnedPlot(player)
	BuildModeButton:lock()
	if plot ~= nil then
		Remotes.LocalEvents.BuildSystem:Fire("close", nil, plot)
	end
	task.wait(1)
	BuildModeButton:unlock()
end)