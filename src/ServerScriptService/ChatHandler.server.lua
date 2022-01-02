-- // SERVICES \\ --

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- // MODULES \\ --

local Modules = ReplicatedStorage:WaitForChild("Modules")
local ChatPlus = require(Modules.ChatPlus)

-- // CHAT SETUP \\ --

local AdminChannel = ChatPlus:createChannel("Admins")
AdminChannel:setWelcomeMessage("This channel is restricted to admins/developers.")

-- // ASSIGN CHANNELS \\ --

ChatPlus:onPlayer(function(player)
    if player:GetRankInGroup(12674654) >= 253 then
        AdminChannel:assignUser(player)
    end
end)