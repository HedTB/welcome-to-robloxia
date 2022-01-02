local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)

local MoneyController = Knit.CreateController {
    Name = "MoneyController",
}


function MoneyController:KnitStart()

    local function observeMoney(money: number)
        print("Money changed to:", money)
    end

    local MoneyService = Knit.GetService("MoneyService")
    MoneyService:GetMoney():andThen(function(money: number)
        print("Current money:", money)
    end):catch(warn):andThen(function()
        MoneyService.MoneyChanged:Connect(observeMoney)
    end)
end


function MoneyController:KnitInit()
    print("MoneyController Initialized")
end


return MoneyController