local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local Modules = ReplicatedStorage:WaitForChild("Modules")

local PlotService = require(ServerStorage.Services.PlotService)
local DataService = require(ServerStorage.Services.DataService)
local CustomEnums = require(Modules.CustomEnums)

local Items = ReplicatedStorage:WaitForChild("Items")

local function findItem(itemName)
	for _, item in pairs(Items:GetDescendants()) do
		if item.Name == itemName then
			return item
		end
	end
	return nil
end

local function isInsidePart(position, part)
	local vector3 = part.CFrame:PointToObjectSpace(position)
	return (math.abs(vector3.X) <= part.Size.X / 2)
		and (math.abs(vector3.Y) <= part.Size.Y / 2)
		and (math.abs(vector3.Z) <= part.Size.Z / 2)
end

Remotes.BuildingSystem.PlaceObject.OnServerInvoke = function(player, object, location)

	local item = findItem(object)
    local plot = PlotService.GetPlot(player)
	local data = DataService.GetProfile(player)
	local clonedItem

	if item and plot ~= nil then
		if data.Data.money < item.Settings.Price.Value then return CustomEnums.BuildSystem.InsufficientMoney end
		if not isInsidePart(location.Position, plot.PlotCanvas) then return CustomEnums.BuildSystem.OutsideCanvas end

		clonedItem = item:Clone()
		clonedItem:SetPrimaryPartCFrame(location)
		clonedItem.PrimaryPart.Position += Vector3.new(0, 0.001, 0)
		clonedItem.PrimaryPart.CanCollide = true
		clonedItem.PrimaryPart.Transparency = 0

		data.Data.money -= item.Settings.Price.Value
		Remotes.LocalEvents.MoneyChange:FireClient(player, data.Data.money, data.Data.roMoney)
		clonedItem.Parent = plot.PlacedItems

		local plotID = player:GetAttribute("LoadedPlot")
		local itemData = DataService.SaveItem(player, clonedItem, plot, plotID)
		clonedItem:SetAttribute("ID", itemData.ID)

		return CustomEnums.BuildSystem.Success
	end
	return CustomEnums.BuildSystem.Error

end