local InteractionService = {}
local interTable = {}

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

function InteractionService:CreateInteraction(tableOfInteractions: table, interactionSourcePart: BasePart, name, frameSize: UDim2, buttonsRadius: number)
	local playerGui = Players.LocalPlayer.PlayerGui
	
	local interactionSample = playerGui:WaitForChild("Samples").InteractionSample
	local gui = playerGui:FindFirstChild("InteractionGui") or Instance.new("ScreenGui")
	gui.Name = "InteractionGui"
    gui.Parent = playerGui
	local frame = gui:FindFirstChild(name) or Instance.new("Frame")
	frame.Name = name
    frame.Parent = gui

	local function placeInCircle(center: UDim2, radius: number, frames: {Frame})
		local len = #frames
		for i = 1, len do
			local percent = i/len
			local radians = percent * (math.pi*2)
			local currentFrame = frames[i]
			currentFrame.Position = UDim2.new(center.X.Scale, math.cos(radians) * radius, center.Y.Scale, math.sin(radians) * radius)
			currentFrame.Parent = frame
			currentFrame.Visible = true
		end
	end

	local function closeInteraction()
		local tween = TweenService:Create(frame, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.InOut), {
			Size = UDim2.new(0, 0, 0, 0)
		})
		tween:Play()
		tween.Completed:Wait()
		frame.Visible = false
		if interTable[name] then
			interTable[name].Open = false
		end
	end


	frame.Visible = false
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.Size = UDim2.new(0, 0, 0, 0)
	frame.Position = UDim2.new(0.5, 0, 0.5, 0)
	frame.BackgroundTransparency = 1

	local frames = {}
	local connections = {}
	local isHovering = false
	for _, interaction in pairs(tableOfInteractions) do
		local clonedInteraction = interactionSample:Clone()

		clonedInteraction.Button.Text = interaction.Text
		local connection = clonedInteraction.Button.MouseButton1Click:Connect(function()
			task.spawn(interaction.Function)
			closeInteraction()
		end)

		clonedInteraction.MouseEnter:Connect(function() isHovering = true end)
		clonedInteraction.MouseLeave:Connect(function() isHovering = false end)

		table.insert(connections, connection)
		table.insert(frames, clonedInteraction)
	end

	placeInCircle(UDim2.new(0.5, 0, 0.5, 0), buttonsRadius, frames)

	interTable[name] = {
		["Name"] = name,
		["Frames"] = frames,
		["MainFrame"] = frame,
		["Open"] = false,
		["Size"] = frameSize,
		["Connections"] = connections
	}

	local connection
	connection = RunService.Heartbeat:Connect(function()
		if interTable[name] and not interTable[name].Open then return end

		local WSP = workspace.CurrentCamera:WorldToScreenPoint(interactionSourcePart.Position)
		frame.Position = UDim2.new(0, WSP.X, 0, WSP.Y)

		if not interTable[name] then
			task.spawn(closeInteraction)
			connection:Disconnect()
			frame:Destroy()
		end
	end)

	UserInputService.InputBegan:Connect(function(input)
		if interTable[name] and interTable[name].Open and not isHovering and input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			closeInteraction()
		end
	end)
end

function InteractionService:OpenInteraction(interactionName: string)
	local interaction = interTable[interactionName]
	if interaction then
		interaction.MainFrame.Visible = true
		interaction.Open = true
		local tween = TweenService:Create(interaction.MainFrame, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.InOut), {
			Size = interaction.Size
		})
		tween:Play()
		tween.Completed:Wait()
	else
		warn('"'..interactionName..'" is not a valid interaction.')
	end
end

function InteractionService:CloseInteraction(interactionName: string)
	local interaction = interTable[interactionName]
	if interaction then
		local tween = TweenService:Create(interaction.MainFrame, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.InOut), {
			Size = UDim2.new(0, 0, 0, 0)
		})
		tween:Play()
		tween.Completed:Wait()
		interaction.MainFrame.Visible = false
		interaction.Open = false
	else
		warn('"'..interactionName..'" is not a valid interaction.')
	end
end

function InteractionService:DeleteInteraction(interactionName: string)
	local interaction = interTable[interactionName]
	if interaction then
		interTable[interactionName] = nil
		for _, connection in pairs(interaction.Connections) do
			connection:Disconnect()
		end
	else
		warn('"'..interactionName..'" is not a valid interaction.')
	end
end

return InteractionService