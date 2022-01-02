local StarterPlayer = game:GetService("StarterPlayer")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)

Knit.MainModules = ReplicatedStorage.Modules
Knit.ClientModules = StarterPlayer.StarterPlayerScripts.Modules

Knit.AddControllersDeep(script.Parent:WaitForChild("Services"))
Knit.Start():andThen(function()
    print("Knit started.")
end):catch(warn)