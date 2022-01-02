local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)

local MoneyService = Knit.CreateService {
    Name = "MoneyService",
    Client = {
        MoneyChanged = Knit.CreateSignal(),
    },
    _MoneyPerPlayer = {},
    _StartingMoney = 10,
}

function MoneyService.Client:GetMoney(player: Player): number
    return self.Server:GetMoney(player)
end

function MoneyService:GetMoney(player: Player): number
    local money = self._MoneyPerPlayer[player] or self._StartingMoney
    return money
end

function MoneyService:AddMoney(player: Player, amount: number)
    local currentMoney = self:GetMoney(player)
    if amount > 0 then
        local newMoney = currentMoney + amount
        self._MoneyPerPlayer[player] = newMoney
        self.Client.MoneyChanged:Fire(player, newMoney)
    end
end

function MoneyService:KnitStart()
   print("MoneyService Started")
end

function MoneyService:KnitInit()
    print("MoneyService Initialized")
    Players.PlayerRemoving:Connect(function(player: Player)
        self._MoneyPerPlayer[player] = nil
    end)
end

return MoneyService