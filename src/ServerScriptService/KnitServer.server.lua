local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)

Knit.MainModules = ReplicatedStorage.Modules
Knit.ServerModules = ServerStorage.Modules

Knit.AddServices(ServerStorage.Services)
Knit.Start():andThen(function()
    print("Knit started.")
end):catch(warn)