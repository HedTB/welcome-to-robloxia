local UIService = {}

local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local playerGui = player.PlayerGui

function UIService:Error(errorMessage: string)
	local errorTextLabel = playerGui:WaitForChild("Samples").Error:Clone()
	local errorAnimator = require(errorTextLabel.Animator)
	
	errorTextLabel.Text = errorMessage
	errorTextLabel.Parent = playerGui.MainGUI
	
	errorAnimator.AppearTween:Play()
	errorAnimator.AppearTween.Completed:Wait()
	
	errorTextLabel:Destroy()
end

return UIService