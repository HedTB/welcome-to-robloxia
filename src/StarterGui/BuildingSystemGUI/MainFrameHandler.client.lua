-- // SERVICES \\ --

local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- // MODULES \\ --

local Modules = ReplicatedStorage:WaitForChild("Modules")
local PlotService = require(Modules.PlotService)
local UIService = require(Modules.UIService)

-- // VARIABLES \ --

local player = Players.LocalPlayer
local playerGui = player.PlayerGui

local Items = ReplicatedStorage:WaitForChild("Items")
local Categories = {"Appliances", "Electronics", "Furniture", "Kitchen", "Plumbing", "Lighting"}

-- GUI

local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local Samples = playerGui:WaitForChild("Samples")
local GUI = playerGui:WaitForChild("BuildingSystemGUI")
local MainFrame = script.Parent
local TitleLabel = MainFrame.TitleLabel
local BackButton = MainFrame.BackButton

local SideButtons = MainFrame.SideButtons
local CategoryButtons = MainFrame.CategoryButtons
local ItemsContent = MainFrame.ItemsContent
local ItemsFolder = GUI.Items

-- // FUNCTIONS \\ --

function getCFrameAroundPivot(pivot, angle, offset)
	if angle > 0 then
		return pivot * CFrame.Angles(0, math.rad(angle), 0) * offset
	else
		return pivot * offset
	end
end

function tiltButton(button: ImageButton, degrees: number, size: UDim2)
    local tween = TweenService:Create(button, TweenInfo.new(0.3, Enum.EasingStyle.Circular, Enum.EasingDirection.InOut), {
        Rotation = degrees, Size = size
    })
    tween:Play()
end

function fadeButtons(frame: Frame, transparency: number, direction: Enum.EasingDirection, time: number)
    for _, button in pairs(frame:GetChildren()) do
        if button:IsA("ImageButton") then
            TweenService:Create(button, TweenInfo.new(time, Enum.EasingStyle.Exponential, direction), {
                ImageTransparency = transparency
            }):Play()
            TweenService:Create(button.TitleLabel, TweenInfo.new(time, Enum.EasingStyle.Exponential, direction), {
                TextTransparency = transparency
            }):Play()
        end
    end
end

function loadCategory(category)
    local categoryFolder = Items:FindFirstChild(category)
    if not categoryFolder then return end

    TitleLabel.Text = category

    ItemsContent:TweenPosition(UDim2.new(0.484, 0, 0.573), Enum.EasingDirection.InOut, Enum.EasingStyle.Quart, 0.5)
    CategoryButtons:TweenPosition(UDim2.new(0.484, 0, 1.573), Enum.EasingDirection.InOut, Enum.EasingStyle.Quart, 0.5)
    fadeButtons(CategoryButtons, 1, Enum.EasingDirection.InOut, 0.3)
    TweenService:Create(BackButton, TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.InOut), {
        TextTransparency = 0
    }):Play()

    local tableOfContent = {}

    for _, item in pairs(categoryFolder:GetChildren()) do
        local button = ItemsFolder:FindFirstChild(item.Name.."Viewport")
        if not button then
            button = Samples.ViewportSample:Clone()
        end

        local viewport = button.Viewport
        local clonedItem = item:Clone()
        local viewportCamera = Instance.new("Camera")

        local cf = getCFrameAroundPivot(item.PrimaryPart.CFrame, 260, CFrame.new(0.5, 2, item.Settings.ViewportDistance.Value))

        viewport.CurrentCamera = viewportCamera
        viewport.CurrentCamera.CFrame = CFrame.new(cf.Position, item.PrimaryPart.Position)

        button.Name = item.Name.."Viewport"
        button.Visible = false
        button.BackgroundTransparency = 1
        button.ImageTransparency = 1

        clonedItem.Parent = viewport
        viewportCamera.Parent = viewport
        button.Parent = MainFrame.ItemsContent
        
		button.MouseButton1Click:Connect(function()
			local plot = PlotService.GetPlot(player)
			if plot ~= nil then
				Remotes.LocalEvents.BuildSystem:Fire("placeObject", item.Name, plot)
			else
				UIService:Error("You don't own a plot")
			end
		end)

        table.insert(tableOfContent, button)
    end

    task.wait(0.3)

    for _, button in pairs(tableOfContent) do
        local tween = TweenService:Create(button, TweenInfo.new(0.3, Enum.EasingStyle.Circular, Enum.EasingDirection.InOut), {
            ImageTransparency = 0, Active = true
        })

        button.Visible = true
        task.wait(0.07)
        tween:Play()
        task.wait(0.03)
    end
end

function unloadCategory()
    
    fadeButtons(CategoryButtons, 0, Enum.EasingDirection.In, 0.5)
    CategoryButtons:TweenPosition(UDim2.new(0.484, 0, 0.573), Enum.EasingDirection.InOut, Enum.EasingStyle.Quart, 0.5)
    ItemsContent:TweenPosition(UDim2.new(0.484, 0, -0.573), Enum.EasingDirection.InOut, Enum.EasingStyle.Quart, 0.5)
    TweenService:Create(BackButton, TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.InOut), {
        TextTransparency = 1
    }):Play()
    BackButton:TweenPosition(UDim2.new(0.137, 0, 0.136, 0), Enum.EasingDirection.InOut, Enum.EasingStyle.Quart, 0.5)

    TitleLabel.Text = "Decoration"

    for _, button in pairs(ItemsContent:GetChildren()) do
        if button:IsA("ImageButton") then
            button.Visible = false
            button.Active = false
            button.Parent = ItemsFolder
        end
    end
end

-- // EVENTS \\ --

for _, button in pairs(SideButtons:GetChildren()) do
    button.MouseEnter:Connect(function()
        tiltButton(button, 10, UDim2.new(0.9, 0, 0.5, 0))
    end)
    button.MouseLeave:Connect(function()
        tiltButton(button, 0, UDim2.new(0.8, 0, 0.4, 0))
    end)
end

BackButton.MouseButton1Click:Connect(function()
    unloadCategory()
end)

-- // SET UP \\ --

for _, category in pairs(Categories) do
    local button = Samples.CategoryButtonSample:Clone()

    button.TitleLabel.Text = category
    button.Name = category.."Button"
    button.Parent = CategoryButtons

    button.MouseButton1Click:Connect(function()
        loadCategory(category)
    end)
end

for _, item in pairs(Items:GetDescendants()) do
    if item:IsA("Model") and item.Name ~= "Template" then
        local button = Samples.ViewportSample:Clone()
    
        button.Name = item.Name.."Viewport"
        button.Visible = false
        button.Parent = ItemsFolder
    end
end