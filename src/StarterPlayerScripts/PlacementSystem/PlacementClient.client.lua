-- // SERVICES \\ --

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local ContextActionService = game:GetService("ContextActionService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")

-- // IMPORTANT VARIABLES \\ --

local Modules, Remotes = ReplicatedStorage:WaitForChild("Modules"), ReplicatedStorage:WaitForChild("Remotes")
local PlacementSystem = require(Modules.PlacementService)
local UIService = require(Modules.UIService)
local TweenModule = require(Modules.TweenModule)

local player = Players.LocalPlayer
local mouse = player:GetMouse()
local camera = workspace.CurrentCamera
local playerGui = player.PlayerGui

-- // VARIABLES \\ --

local mainFrame = playerGui:WaitForChild("BuildingSystemGUI").MainFrame

local gridSize = 2
local cameraSpeed = 0.75

local keyADown = false
local keyDDown = false
local keyWDown = false
local keySDown = false

local placing = false
local open = false
local highlight = false
local highlightedItems = {}

local itemsFolder = ReplicatedStorage.Items
local itemsTable = itemsFolder:GetChildren()

local originalCFrame

-- // SETTING UP \\ --

mainFrame.Position = UDim2.new(0.197, 0, 1.5, 0)

-- // FUNCTIONS \\ --

local function placeItems(items, plane)
	if (placing) then
		return
	end
	
	for _, item in pairs(items) do
		item.Parent = workspace
		local clonedItem = item:Clone()
		clonedItem.Parent = itemsFolder
	end
	
	placing = true
	
	plane:enable(items, #items > 1):Connect(function(itemCFrames)
		placing = false
		for i = #items, 1, -1 do
			local success = Remotes.BuildingSystem.PlaceObject:InvokeServer(items[i].Name, itemCFrames[i])
			if success == "notEnoughMoney" then
				UIService:Error("You don't have enough money")
			elseif success == "notWithinCanvas" then
				UIService:Error("Not within your plot canvas")
			elseif success then
				plane:disable()
				for _, item in pairs(items) do
					item:Destroy()
				end
				table.remove(items, i)
			end
		end
	end)
end

local function isInArray(array, value)
	for i = 1, #array do
		if (array[i] == value) then
			return i
		end
	end
end

local function findItem(itemName)
	for _, item in pairs(itemsFolder:GetDescendants()) do
		if item.Name == itemName then
			return item
		end
	end
	return nil
end

local function placeObject(plot, objectName)
	local plane = PlacementSystem.new(plot, plot.PlacedItems, gridSize)
	local item = findItem(objectName)

	if item then
		placeItems({item}, plane)
		return true
	else
		return false
	end
end

-- // KEYBINDS \\ --

--[[
ContextActionService:BindActionAtPriority("select", function(_, userInputState)
	if (placing or userInputState ~= Enum.UserInputState.End) then
		return
	end

	if (highlight) then
		local hit = mouse.Target

		if (hit and hit.Parent.Parent == workspace.items) then
			local position = isInArray(highlightedItems, hit.Parent)

			if (position) then
				table.remove(highlightedItems, position)
			else
				table.insert(highlightedItems, hit.Parent)
			end
		end

	else
		highlightedItems = {}
	end
end, false, 8, Enum.UserInputType.MouseButton1)
]]--

ContextActionService:BindAction("ctrl", function(_, inputState, input)
	if (inputState == Enum.UserInputState.Begin) then
		highlight = true
	elseif (inputState == Enum.UserInputState.Begin) then
		highlight = false
	end
end, false, Enum.KeyCode.LeftControl)


--[[
ContextActionService:BindAction("enable", function(_, inputState, input)
	if (inputState == Enum.UserInputState.End) then
		if (placing) then
			return
		end
		
		if (#highlightedItems > 0) then
			placeItems(highlightedItems)
		else
			placeItems({itemsFolder.Frigde:Clone()})
		end
	end
end, false, Enum.KeyCode.Q)
--]]

-- // MOVING CAMERA \\ --

UISTable = {}
function startCameraMovement(plot, setSpeed)

	local x = 0
	local y = 0
	local minCorner = plot.MinCorner.Position
	local maxCorner = plot.MaxCorner.Position
	local angle = Instance.new("CFrameValue")
	angle.Value = CFrame.Angles(math.rad(-90), 0, math.rad(-90))
	local position = plot.CameraStart.Position

	local nVec = {
		[Enum.KeyCode.A] = Vector3.new(-1, 0, 0),
		[Enum.KeyCode.D] = Vector3.new(1, 0, 0),
		[Enum.KeyCode.S] = Vector3.new(0, 0, 1),
		[Enum.KeyCode.W] = Vector3.new(0, 0, -1),
		[Enum.KeyCode.Q] = Vector3.new(0, -1, 0),
		[Enum.KeyCode.E] = Vector3.new(0, 1, 0)
	}

	local Vec = {}

	local defaultSpeed = setSpeed
	local speed = defaultSpeed

	function UISTable.InputBegan(input)
		if not open then return end
		if nVec[input.KeyCode] then
			Vec[input.KeyCode] = nVec[input.KeyCode]
		elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
			UserInputService.MouseBehavior = Enum.MouseBehavior.LockCurrentPosition
		elseif input.KeyCode == Enum.KeyCode.LeftShift then
			speed = defaultSpeed / 10
		elseif input.KeyCode == Enum.KeyCode.LeftControl then
			speed = defaultSpeed * 2
		end
	end

	function UISTable.InputChanged(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
			x = (x - math.rad(input.Delta.X))%(2*math.pi)
			y = math.clamp(y - math.rad(input.Delta.Y), math.rad(-89), math.rad(89))
			TweenService:Create(
				angle,
				TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{Value = CFrame.Angles(0, x, 0) * CFrame.Angles(y, 0, 0)}
			):Play()
		elseif input.UserInputType == Enum.UserInputType.MouseWheel then
			position -= angle.Value * Vector3.new(0, 0, 5*input.Position.Z)
		end
	end

	function UISTable.InputEnded(input)
		if nVec[input.KeyCode] then
			Vec[input.KeyCode] = nil
		elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
			UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		elseif input.KeyCode == Enum.KeyCode.LeftShift then
			speed = defaultSpeed
		elseif input.KeyCode == Enum.KeyCode.LeftControl then
			speed = defaultSpeed
		end
	end

	for i, v in pairs(UISTable) do
		UserInputService[i]:Connect(v)
	end

	local function DefaultCam(dt)
		local move = Vector3.new()
		for _, v in pairs(Vec) do
			move += v
		end
		TweenService:Create(camera, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {CFrame = angle.Value + Vector3.new(
			math.clamp(position.X, minCorner.X, maxCorner.X),
			math.clamp(position.Y, minCorner.Y, maxCorner.Y),
			math.clamp(position.Z, minCorner.Z, maxCorner.Z)
		)}):Play()
		--camera.CFrame = angle.Value + position
		position += angle.Value * (move * speed)
	end

	RunService:BindToRenderStep("DefaultCam", Enum.RenderPriority.Camera.Value, DefaultCam)

end

-- // EVENTS \\ --

Remotes.LocalEvents.BuildSystem.Event:Connect(function(instruction, value, plot)

	local character = player.Character or player.CharacterAdded:Wait()
	local head = character.Head

	if instruction == "open" then
		StarterGui:SetCore("ResetButtonCallback", false)

		for _, v in pairs(character:GetChildren()) do
			if v:IsA("BasePart") then
				v.Anchored = true
			end
		end

		mainFrame:TweenPosition(UDim2.new(0.197, 0, 1.01, 0), Enum.EasingDirection.InOut, Enum.EasingStyle.Quart, 0.5)
		open = true

		camera.CameraType = Enum.CameraType.Scriptable
		originalCFrame = camera.CFrame
		TweenModule:TweenCamera(0.5, Enum.EasingStyle.Exponential, Enum.EasingDirection.InOut, CFrame.new(Vector3.new(head.Position.X, plot.CameraStart.Position.Y, head.Position.Z), head.Position))
		startCameraMovement(plot, cameraSpeed)

	elseif instruction == "close" then
		StarterGui:SetCore("ResetButtonCallback", true)

		for _, v in pairs(character:GetChildren()) do
			if v:IsA("BasePart") then
				v.Anchored = false
			end
		end

		mainFrame:TweenPosition(UDim2.new(0.197, 0, 1.5, 0), Enum.EasingDirection.InOut, Enum.EasingStyle.Quart, 0.5)
		
		TweenModule:TweenCamera(0.5, Enum.EasingStyle.Exponential, Enum.EasingDirection.InOut, originalCFrame)
		camera.CameraType = Enum.CameraType.Custom

		open = false
		RunService:UnbindFromRenderStep("DefaultCam")

		task.wait(0.5)
		mainFrame.CategoryButtons:TweenPosition(UDim2.new(0.484, 0, 0.573), Enum.EasingDirection.InOut, Enum.EasingStyle.Quart, 0.5)
		mainFrame.ItemsContent:TweenPosition(UDim2.new(0.484, 0, -0.573), Enum.EasingDirection.InOut, Enum.EasingStyle.Quart, 0.5)
		TweenService:Create(mainFrame.BackButton, TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.InOut), {
			TextTransparency = 1
		}):Play()
		mainFrame.BackButton:TweenPosition(UDim2.new(0.137, 0, 0.136, 0), Enum.EasingDirection.InOut, Enum.EasingStyle.Quart, 0.5)

		mainFrame.TitleLabel.Text = "Decoration"

		for _, button in pairs(mainFrame.ItemsContent:GetChildren()) do
			if button:IsA("ImageButton") then
				button.Visible = false
				button.Active = false
				button.Parent = mainFrame.Parent.Items
			end
		end
		for _, button in pairs(mainFrame.CategoryButtons:GetChildren()) do
			if button:IsA("ImageButton") then
				button.ImageTransparency = 0
				button.TitleLabel.TextTransparency = 0
			end
		end

	elseif instruction == "placeObject" then
		local success = placeObject(plot, value)
		if success == false then
			warn(value.. " is not a valid object.")
		end
	end
end)