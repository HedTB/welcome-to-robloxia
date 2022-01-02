-- // SERVICES

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

-- // VARIABLES \\ --

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local Modules = ReplicatedStorage:WaitForChild("Modules")

local CustomEnums = require(Modules.CustomEnums)
local Knit = require(ReplicatedStorage.Packages.Knit)

local GUI = script.Parent
local Buttons = GUI.ButtonsFrame
local PlotSavesFrame = GUI.PlotSavesFrame
local DarkenFrame = GUI.DarkenFrame
local SavesFrame = PlotSavesFrame.SavesFrame
local EditPlotFrame = GUI.EditPlotFrame
local Logo = GUI.MainFrame.Logo

local SaveSample = PlotSavesFrame.SaveSample

local player = Players.LocalPlayer
local mouse = player:GetMouse()

local EditingPlot = nil
local EditingHover = false

-- // FUNCTIONS \\ --

local function len(t)
    local n = 0
    
    for _ in pairs(t) do
        n = n + 1
    end
    return n
end

local function loadPlots()
    local dataService = Knit.GetService("DataService")

    dataService:GetSavedPlots():andThen(function(plotsTable: table)
        local usedIDs = {}

        for _, frame in pairs(SavesFrame:GetChildren()) do
            if frame:IsA("ImageLabel") then frame:Destroy() end
        end
        if len(plotsTable) == 0 then
            local plot = Remotes.PlotSelection.CreatePlot:InvokeServer("My Beautiful Home")
            loadPlots()
        end
        
        for _, plot in pairs(plotsTable) do
            if usedIDs[plot.id] then continue end

            local clone = SaveSample:Clone()
            local plotWorth = plot.plotWorth
            if plotWorth then
                plotWorth = "Worth " .. plotWorth .. "$"
            end

            clone.LastUsed.Text = plot.lastUsed or "Never Used"
            clone.SaveName.Text = plot.name or "Untitled"
            clone.PlotWorth.Text = plotWorth or "N/A"
            clone.Visible = true
            clone.Parent = SavesFrame

            table.insert(usedIDs, plot.id)

            clone.LoadButton.MouseButton1Click:Connect(function()
                Remotes.LocalEvents.SelectPlot:Fire(plot.name)
                PlotSavesFrame:TweenPosition(UDim2.new(0.5, 0, 1.511, 0), Enum.EasingDirection.InOut, Enum.EasingStyle.Quart, 0.5)
            end)
            clone.EditButton.MouseButton1Click:Connect(function()
                TweenService:Create(DarkenFrame, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {BackgroundTransparency = 0.6}):Play()
                EditPlotFrame.Visible = true
                EditPlotFrame.NameBox.Text = plot.name

                EditingPlot = plotsTable[plot.id]
            end)
            
            clone.LoadButton.MouseEnter:Connect(function()
                TweenService:Create(clone.LoadButton, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.InOut), {ImageColor3 = Color3.fromRGB(200, 200, 200)}):Play()
            end)
            clone.LoadButton.MouseLeave:Connect(function()
                TweenService:Create(clone.LoadButton, TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {ImageColor3 = Color3.fromRGB(255, 255, 255)}):Play()
            end)

            clone.EditButton.MouseEnter:Connect(function()
                TweenService:Create(clone.EditButton, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.InOut), {ImageColor3 = Color3.fromRGB(200, 200, 200)}):Play()
            end)
            clone.EditButton.MouseLeave:Connect(function()
                TweenService:Create(clone.EditButton, TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {ImageColor3 = Color3.fromRGB(255, 255, 255)}):Play()
            end)
        end
    end)
end

local function playGame()
    loadPlots()
    PlotSavesFrame.Size = UDim2.new(0.614, 0, 0.74, 0)
    PlotSavesFrame.Position = UDim2.new(0.5, 0, 1.511, 0)
    PlotSavesFrame:TweenPosition(UDim2.new(0.5, 0, 0.511, 0), Enum.EasingDirection.InOut, Enum.EasingStyle.Quart, 0.5)
    PlotSavesFrame.Size = UDim2.new(0.614, 0, 0.74, 0)

    task.wait(0.35)
    Buttons.Visible = false
    Logo.Visible = false
end

local function savePlotData(closeType)
    local dataService = Knit.GetService("DataService")

    local name = EditPlotFrame.NameBox.Text
    local tween = TweenService:Create(DarkenFrame, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {BackgroundTransparency = 1})

    if string.len(name) > 20 or string.len(name) < 3 and closeType == "button" then
        if name == EditingPlot.name then return end
        EditPlotFrame.NameBox.Text = "Please input a name between 3 and 20 characters."
        task.wait(2)
        EditPlotFrame.NameBox.Text = name
    elseif name ~= EditingPlot.name then
        dataService:EditPlot(EditingPlot.id, {name=name}):andThen(function(success: number, data: table)
            if success == CustomEnums.PlotSelection.Success then
                loadPlots()
                EditingPlot = nil
            end
            tween:Play()
            EditPlotFrame.Visible = false
        end):catch(warn)
    elseif name == EditingPlot.name then
        tween:Play()
        EditPlotFrame.Visible = false
    end
end

-- // SETUP \\ --

for _, button in pairs(Buttons:GetChildren()) do
    if button:IsA("ImageLabel") then
        button.Button.MouseEnter:Connect(function()
            TweenService:Create(button, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.InOut), {ImageColor3 = Color3.fromRGB(200, 200, 200)}):Play()
        end)
        button.Button.MouseLeave:Connect(function()
            TweenService:Create(button, TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {ImageColor3 = Color3.fromRGB(255, 255, 255)}):Play()
        end)

        button.Button.MouseButton1Click:Connect(function()
            if button.Button.Text == "Play" then
                playGame()
            elseif button.Button.Text == "Shop" then
            end
        end)
    end
end

-- // EVENTS \\ --

EditPlotFrame.SaveButton.Button.MouseButton1Click:Connect(function()
    savePlotData("button")
end)

EditPlotFrame.SaveButton.Button.MouseEnter:Connect(function()
    TweenService:Create(EditPlotFrame.SaveButton, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.InOut), {ImageColor3 = Color3.fromRGB(200, 200, 200)}):Play()
end)
EditPlotFrame.SaveButton.Button.MouseLeave:Connect(function()
    TweenService:Create(EditPlotFrame.SaveButton, TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {ImageColor3 = Color3.fromRGB(255, 255, 255)}):Play()
end)

EditPlotFrame.NameBox.MouseEnter:Connect(function()
    TweenService:Create(EditPlotFrame.TextBoxBackground, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.InOut), {ImageColor3 = Color3.fromRGB(200, 200, 200)}):Play()
    TweenService:Create(EditPlotFrame.NameBox, TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {TextColor3 = Color3.fromRGB(225, 225, 225)}):Play()
end)
EditPlotFrame.NameBox.MouseLeave:Connect(function()
    TweenService:Create(EditPlotFrame.TextBoxBackground, TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {ImageColor3 = Color3.fromRGB(255, 255, 255)}):Play()
    TweenService:Create(EditPlotFrame.NameBox, TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {TextColor3 = Color3.fromRGB(255, 255, 255)}):Play()
end)

EditPlotFrame.MouseEnter:Connect(function()
    EditingHover = true
end)
EditPlotFrame.MouseLeave:Connect(function()
    EditingHover = false
end)

mouse.Button1Down:Connect(function()
    if EditingHover then return end
    if not EditPlotFrame.Visible then return end
    savePlotData("outside")
end)
UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
    if gameProcessedEvent then return end
    if EditingHover then return end
    if not EditPlotFrame.Visible then return end
    if input.UserInputType == Enum.UserInputType.Touch then
        savePlotData("outside")
    end
end)