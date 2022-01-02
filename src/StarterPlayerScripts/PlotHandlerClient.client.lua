-- // VARIABLES \\ --

-- SERVICES
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")

-- IMPORTANT
local Modules = ReplicatedStorage:WaitForChild("Modules")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local orbiting = false

-- MODULES
local Knit = require(ReplicatedStorage.Packages.Knit)

local TweenModule = require(Modules.TweenModule)
local UIService = require(Modules.UIService)
local CustomEnums = require(Modules.CustomEnums)

-- GUI
local PlotSelect = player.PlayerGui:WaitForChild("PlotSelectorGUI", 10)

local Frame = PlotSelect:WaitForChild("MainFrame")
local L = Frame:WaitForChild("LeftButton")
local R = Frame:WaitForChild("RightButton")
local Select = Frame:WaitForChild("Select")

local SelectedPlot = Frame:WaitForChild("SelectedPlot")

local Plots = workspace.Plots

-- // FUNCTIONS \\ --

local function camTween(plot)
	camera.CameraType = Enum.CameraType.Scriptable
	local TI = TweenInfo.new(0.5, Enum.EasingStyle.Exponential, Enum.EasingDirection.InOut, 0, false, 0)
	local cf = CFrame.new(plot.Position + Vector3.new(0,120,0), plot.Position)
	local tween = TweenService:Create(camera, TI, {CFrame = cf})
	tween:Play()
	tween.Completed:Wait()
end

local function getCFrameAroundPivot(pivot, angle, offset)
	return pivot * CFrame.Angles(0, math.rad(angle), 0) * offset
end

local function startPlotSelect(plotName)
	TweenService:Create(Lighting.MenuBlur, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {Size = 0}):Play()

	local plotService = Knit.GetService("PlotService")
	local connections = {}
	local plotsTable
	plotService:GetAvailablePlots():andThen(function(...)
		plotsTable = ...
	end):await()
	local index = 1

	Frame.Select.Text = "Select Plot"
	Frame.Position = UDim2.new(0.5, 0, 0.862, 0)
	SelectedPlot.Value = plotsTable[1]

	local function choosePlot()
		camTween(SelectedPlot.Value)
		connections[#connections+1] = R.MouseButton1Click:Connect(function()
			if Plots:FindFirstChild(index-1) then
				index -= 1
			else
				index = #plotsTable
			end
			SelectedPlot.Value = plotsTable[index]
			camTween(plotsTable[index])
		end)
		connections[#connections+1] = L.MouseButton1Click:Connect(function()
			if Plots:FindFirstChild(index+1) then
				index += 1
			else
				index = 1
			end
			SelectedPlot.Value = plotsTable[index]
			camTween(plotsTable[index])
		end)
		connections[#connections+1] = Select.MouseButton1Click:Connect(function()
			local result = plotService:OwnPlot(plotsTable[index], plotName)

			if result == CustomEnums.PlotSelection.Invalid then
				UIService:Error("Invalid plot")
				choosePlot()
			elseif result == CustomEnums.PlotSelection.Unavailable then
				UIService:Error("Plot is owned by someone else")
				choosePlot()
			end

			Select.Text = "Success"
			camera.CameraType = Enum.CameraType.Custom
			SelectedPlot.Value = nil
			-- CutSceneEvents.CancelCutsceneRequestEvent:FireServer(player)

			for _, connection in pairs(connections) do
				if connection then connection:Disconnect() end
			end

			task.wait(0.5)
			Frame:TweenPosition(UDim2.new(0.5, 0,0.862, 500), Enum.EasingDirection.InOut, Enum.EasingStyle.Quart, 0.5)
		end)
	end
	choosePlot()
end

local function orbitPlot(plot)
	local DISTANCE = CFrame.new(0, 120, 125)
	local SPEED = 0.25
	
	local cf = getCFrameAroundPivot(plot.CFrame, 0, DISTANCE)
	local originalCFrame = workspace.CurrentCamera.CFrame
	
	TweenModule:TweenCamera(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.InOut, CFrame.new(cf.Position, plot.Position))

	orbiting = true
	for i = 0, 7 do
		task.wait(0.05)
		if not orbiting then
            TweenModule:TweenCamera(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.InOut, originalCFrame)
            camera.CameraType = Enum.CameraType.Custom
            return
        end
	end
	
	repeat
		camera.CameraType = Enum.CameraType.Custom
		for i = 0, 360, 10 do
			if not orbiting then break end

            camera.CameraType = Enum.CameraType.Scriptable
			local cFrame = getCFrameAroundPivot(plot.CFrame, i, DISTANCE)
            local tween = TweenService:Create(camera, TweenInfo.new(SPEED, Enum.EasingStyle.Linear), {
                CFrame = CFrame.new(cFrame.Position, plot.Position)
            })
            tween:Play()
            tween.Completed:Wait()
		end
	until orbiting == false
	TweenModule:TweenCamera(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.InOut, originalCFrame)
	camera.CameraType = Enum.CameraType.Custom
end

-- // EVENTS \\ --

Remotes.LocalEvents.SelectPlot.Event:Connect(startPlotSelect)
Remotes.LocalEvents.OrbitPlot.Event:Connect(function(instruction, plot)
	if instruction == "stop" then
		orbiting = false
	elseif instruction == "start" then
		orbitPlot(plot)
	end
end)