-- // VARIABLES \\ --

local Players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local TweenService = game:GetService("TweenService")
local ContentProvider = game:GetService("ContentProvider")
local StarterGui = game:GetService("StarterGui")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local screenGui = ReplicatedFirst:WaitForChild("LoadingGui")
local frame = screenGui.Frame
local textLabel = frame.TextLabel
local bar = frame.Bar
local barBG = bar.BarBG

local assets = {"rbxassetid://8191012322", "rbxassetid://8191636399", "rbxassetid://8392338693", "rbxassetid://8392326036", "rbxassetid://8191578097", "rbxassetid://8389408422", "rbxassetid://8191615568"}

-- // FUNCTIONS \\ --

local function hasProperty(object, propertyName)
	local success, _ = pcall(function() 
		object[propertyName] = object[propertyName]
	end)
	return success
end

local function tweenBarBG(size)
	return TweenService:Create(barBG, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {Size = size})
end

local function fadeTransparency(instance, tweenInfo)
	if instance:IsA("Frame") then
		TweenService:Create(instance, tweenInfo, {BackgroundTransparency = 1}):Play()
	elseif instance:IsA("TextLabel") then
		TweenService:Create(instance, tweenInfo, {TextTransparency = 1, BackgroundTransparency = 1}):Play()
	elseif instance:IsA("UIStroke") then
		TweenService:Create(instance, tweenInfo, {Transparency = 1}):Play()
	end
end

-- // LOADING THE GAME \\ --

screenGui.Parent = playerGui

ReplicatedFirst:RemoveDefaultLoadingScreen()
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false)

task.wait(2)

for _, instance in pairs(playerGui:GetDescendants()) do
	if hasProperty(instance, "Image") then
		if instance.Image == "" or string.match(instance.Image, "rbxasset://textures") then continue
		else
			table.insert(assets, instance.Image)
		end
	end
end

local assetsLoaded = 0
for _, asset in pairs(assets) do
	ContentProvider:PreloadAsync({asset})
	assetsLoaded += 1
    task.spawn(function()
        tweenBarBG(UDim2.new(assetsLoaded/#assets, 0, 1, 0)):Play()
    end)
end

task.wait(1)

local TI = TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
for _, instance in pairs({frame, textLabel, bar, barBG, bar.UIStroke}) do
	fadeTransparency(instance, TI)
end

-- // SETTING UP GUI \\ --

playerGui.MenuGUI.PlotSavesFrame.Size = UDim2.new(0, 0, 0, 0)
playerGui.MenuGUI.PlotSavesFrame.Position = UDim2.new(0.5, 0, 0.511, 0)

-- // CLEAN UP \ --

StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, true)

task.wait(2)
screenGui:Destroy()