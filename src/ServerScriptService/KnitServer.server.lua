local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)

local MoneyService = Knit.CreateService {
    Name = "MoneyService",
    Client = {},
    _MoneyPerPlayer = {},
    _StartingMoney = 10,
}

function MoneyService:GetMoney(player: Player): number
    local money = self._MoneyPerPlayer[player] or self._StartingMoney
    return money
end

function MoneyService:AddMoney(player: Player, amount: number)
    local newMoney = self:GetMoney(player) + amount
    self._MoneyPerPlayer[player] = newMoney
end

function MoneyService:KnitStart()
   print("MoneyService Started")
end

function MoneyService:KnitInit()
    print("MoneyService Initialized")
    Players.PlayerRemoving:Connect(function(player: Player)
        self._MoneyPerPlayer[player] = nil
    end)
    Players.PlayerAdded:Connect(function(player: Player)
        task.wait(0.5)
        print(MoneyService:GetMoney(player))
    end)
end

Knit.MainModules = ReplicatedStorage.Modules
Knit.ServerModules = ServerStorage.Modules

Knit.AddServices(ServerScriptService.Services)
Knit.Start():andThen(function()
    print("Knit started.")
end):catch(warn)