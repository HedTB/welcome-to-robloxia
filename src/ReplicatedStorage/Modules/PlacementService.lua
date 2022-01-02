local INTERPOLATION = true
local INTERPOLATION_DAMP = .21
local ROTATION_SPEED = .2

local COLLISION_COLOR3 = BrickColor.Red().Color
local COLLISION_TRANSPARENCY = .5

local NORMAL_COLOR3 = BrickColor.new().Color
local NORMAL_TRANSPARENCY = .8

local LOAD_COLOR3 = Color3.fromRGB(226, 155, 64)
local LOAD_TRANSPARENCY = .6

local GRID_TEXTURE = "rbxassetid://8149359285"
local GRID_COLOR = Color3.fromRGB(0, 0, 0)
local GRID_TRANSPARENCY = 0.5

local OVERRIDE_CONTROLS = false
local INPUT_PRIORITY = 9
local TOUCH_RANGE = 30

local PLACEMENT_COOLDOWN = .45


local module = {}

local player = game.Players.LocalPlayer
local mouse = player:GetMouse()
local runService = game:GetService("RunService")
local touch = game:GetService("UserInputService").TouchEnabled

local currentPlane
local currentBase

local renderConnection = nil

local cx, cy, cz, cr = 0, 0, 0, 0
local currentObjects = {}
local currentEvent
local currentTexture
local currentPosition = Vector3.new(0, 0, 0)
local ax, az

local currentExtentsX
local currentExtentsZ
local currentYAxis
local currentXAxis
local currentZAxis
local currentAxis

local ox, oy, oz -- do
local dxx, dxy, dxz
local dzx, dzy, dzz

local min = math.min
local max = math.max
local abs = math.abs

local springVelocity = Vector3.new(0, 0, 0)
local springPosition = Vector3.new(0, 0, 0)
local tweenGoalRotation = 0 -- springs arent worth effort for rotation
local tweenStartRotation = 0
local tweenCurrentRotation = 0
local tweenAlpha = 1

local lastRenderCycle = tick()
local lastPlacement = tick()

local function round(n, to)
	return n % to ~= 0 and (n % to) > to/2 and (n + to - (n % to)) or (n - (n % to))	
end

local function project(px, py, pz)
	px, py, pz = px - ox, py - oy, pz - oz

	return px * dxx + py * dxy + pz * dxz, px * dzx + py * dzy + pz * dzz
end

local function translate(px, pz, r)
	if (r == 0) then
		return px, pz
	elseif (r == 1) then
		return -pz, px
	elseif (r == 2) then
		return -px, -pz
	elseif (r == 3) then
		return pz, -px
	end

	--  or for all angles
	--	r = r * math.pi/2
	--	return math.cos(r) * px - math.sin(r) * pz,  math.sin(r) * px + math.cos(r) * pz	
end

local function angleLerp(a, b, d) -- to avoid angle jump
	local x1, y1 = math.cos(a), math.sin(a)
	local x2, y2 = math.cos(b), math.sin(b)

	return math.atan2(y1 + (y2 - y1) * d, x1 + (x2 - x1) * d)
end

local function hasProperty(object, propertyName)
	local success, _ = pcall(function() 
		object[propertyName] = object[propertyName]
	end)
	return success
end

local function calculateExtents(part, cf)
	local cf = cf or part.CFrame

	local edgeA = cf * CFrame.new(-part.Size.X/2, 0, 0)
	local edgeB = cf * CFrame.new(part.Size.X/2, 0, 0)
	local edgeC = cf * CFrame.new(0, 0, part.Size.Z/2)
	local edgeD = cf * CFrame.new(0, 0, -part.Size.Z/2)

	local edgeAx, edgeAz = project(edgeA.X, edgeA.Y, edgeA.Z)
	local edgeBx, edgeBz = project(edgeB.X, edgeB.Y, edgeB.Z)
	local edgeCx, edgeCz = project(edgeC.X, edgeC.Y, edgeC.Z)
	local edgeDx, edgeDz = project(edgeD.X, edgeD.Y, edgeD.Z)

	local extentsX = max(edgeAx, edgeBx, edgeCx, edgeDx) - min(edgeAx, edgeBx, edgeCx, edgeDx)
	local extentsZ = max(edgeAz, edgeBz, edgeCz, edgeDz) - min(edgeAz, edgeBz, edgeCz, edgeDz)

	return round(extentsX, currentPlane.grid), round(extentsZ, currentPlane.grid)
end

local states = {
	neutral = 1;
	collision = 2;
	loading = 3;
}

module.states = states

local function setState(object, state, downward)
	if (object.state and (object.state == state or (object.state > state and not downward))) then
		return
	end

	object.state = state

	if (state == 1) then
		if (NORMAL_COLOR3) then
			object.model.PrimaryPart.Color = NORMAL_COLOR3
		end
		if (NORMAL_TRANSPARENCY) then
			object.model.PrimaryPart.Transparency = NORMAL_TRANSPARENCY
		end
	elseif (state == 2) then
		if (COLLISION_COLOR3) then
			object.model.PrimaryPart.Color = COLLISION_COLOR3
		end
		if (COLLISION_TRANSPARENCY) then
			object.model.PrimaryPart.Transparency = COLLISION_TRANSPARENCY
		end
	elseif (state == 3) then
		if (LOAD_COLOR3) then
			object.model.PrimaryPart.Color = LOAD_COLOR3
		end
		if (LOAD_TRANSPARENCY) then
			object.model.PrimaryPart.Transparency = LOAD_TRANSPARENCY
		end
	end

	currentPlane.stateEvent:Fire(object.model, state)
end

--[[
	status
	model
	px, pz, r
	sx, sz
--]]

local function floatEqual(a, b)
	return (math.abs(a - b) < .01)
end

local function floatGreater(a, b)
	return (a - b) > .01
end

local function floatLesser(a, b)
	return (b - a) > .01
end

local function obstacleCollision()
	local px, pz = cx, cz

	local collision = false

	for _, model in pairs(currentPlane.obstacles:GetChildren()) do
		if (model.PrimaryPart) then

			local extentsX1, extentsZ1 = calculateExtents(model.PrimaryPart)
			local x1, z1 = project(model.PrimaryPart.Position.X, model.PrimaryPart.Position.Y, model.PrimaryPart.Position.Z)

			for i = 1, #currentObjects do
				local object = currentObjects[i]

				if (not object.collision) then
					local r = (object.r + cr) % 4

					local x0, z0 = translate(object.px, -object.pz, cr)
					x0 = x0 + px
					z0 = z0 + pz

					local extentsX0, extentsZ0

					if (r == 1 or r == 3) then
						extentsX0, extentsZ0 = object.sz, object.sx
					else
						extentsX0, extentsZ0 = object.sx, object.sz
					end		

					if (floatLesser(x0 - extentsX0/2, x1 + extentsX1/2) and floatGreater(x0 + extentsX0/2, x1 - extentsX1/2) and floatLesser(z0 - extentsZ0/2, z1 + extentsZ1/2) and floatGreater(z0 + extentsZ0/2, z1 - extentsZ1/2)) then
						collision = true
						object.collision = true
						setState(object, states.collision)
					end
				end
			end
		end
	end

	for i = 1, #currentObjects do
		local object = currentObjects[i]

		if (not object.collision and object.state == states.collision) then
			setState(object, states.neutral, true)
		else
			object.collision = nil
		end
	end

	return not collision
end

local function inputCapture() -- converts user inputs to 3d position, built in mobile compatibility
	local position

	if (touch) then
		local camera = workspace.CurrentCamera
		local range = TOUCH_RANGE * (camera.Focus.p - camera.CFrame.p).magnitude/5	

		position = camera.Focus.p + camera.CFrame.lookVector * (camera.CoordinateFrame.lookVector.Y/2 + .5) * range
	else
		local hit, p = workspace:FindPartOnRayWithWhitelist(Ray.new(mouse.UnitRay.Origin, mouse.UnitRay.Direction * 999), {currentPlane.base})

		if (hit) then
			position = p
		end
	end

	return position, cr
end

local resting = false

local function calc(position, rotation, force)
	if (not currentPlane or currentPlane.loading) then
		return
	end

	force = force == true

	local ux, uz

	if (position) then
		ux, uz = project(position.X, position.Y, position.Z)
	else
		ux, uz = ax or 0, az or 0
	end

	local nr = rotation or cr

	local nx = round(ux, currentPlane.grid)
	local nz = round(uz, currentPlane.grid)

	local extentsX, extentsZ = translate(currentExtentsX, currentExtentsZ, nr)
	extentsX = abs(extentsX)
	extentsZ = abs(extentsZ)

	if (floatEqual(extentsX/2 % currentPlane.grid, 0)) then
		nx = nx + currentPlane.grid/2
	end

	if (floatEqual(extentsZ/2 % currentPlane.grid, 0)) then
		nz = nz + currentPlane.grid/2
	end

	nx = nx + currentPlane.offsetX
	nz = nz + currentPlane.offsetZ

	local borderX = currentPlane.size.X/2
	local borderZ = currentPlane.size.Z/2

	ax = ux
	az = uz

	if (nx + extentsX/2 > borderX) then
		nx = nx - (nx + extentsX/2 - borderX)
	elseif (nx - extentsX/2 < -borderX) then
		nx = nx - (nx - extentsX/2 + borderX)
	end

	if (nz + extentsZ/2 > borderZ) then
		nz = nz - (nz + extentsZ/2 - borderZ)
	elseif (nz - extentsZ/2 < -borderZ) then
		nz = nz - (nz - extentsZ/2 + borderZ)
	end

	if (force or nx ~= cx or nz ~= cz or cr ~= nr) then
		cx, cz, cr = nx, nz, nr
		resting = false
		currentPosition = (Vector3.new(ox, oy, oz) + currentXAxis * nx + currentZAxis * nz)
		obstacleCollision()
	end
end

local function render()
	if (resting) then
		return
	end

	if (INTERPOLATION) then
		local delta = 1/60

		springVelocity = (springVelocity + (currentPosition - springPosition)) * INTERPOLATION_DAMP * 60 * delta
		springPosition = springPosition + springVelocity

		local extentsX, extentsZ = translate(currentExtentsX, currentExtentsZ, cr)

		local vx, vz = 9 * springVelocity:Dot(currentXAxis)/abs(extentsX), 9 * springVelocity:Dot(currentZAxis)/abs(extentsZ)
		local r

		if (not floatEqual(tweenGoalRotation, cr * math.pi/2)) then
			tweenStartRotation = tweenCurrentRotation
			tweenGoalRotation = cr * math.pi/2
			tweenAlpha = 0
		end

		if (tweenAlpha < 1) then
			tweenAlpha = min(1, tweenAlpha + delta/ROTATION_SPEED)
			tweenCurrentRotation = angleLerp(tweenStartRotation, tweenGoalRotation, 1 - (1 - tweenAlpha)^2)
			r = tweenCurrentRotation
		else
			r = cr * math.pi/2
		end


		local effectAngle = CFrame.Angles(math.sqrt(math.abs(vz/100)) * math.sign(vz), 0, math.sqrt(math.abs(vx/100)) * math.sign(vx))

		local rotationCFrame = currentAxis * effectAngle * CFrame.Angles(0, r, 0)
		local centerCFrame = rotationCFrame + springPosition

		for i = 1, #currentObjects do
			local object = currentObjects[i]

			local x, z = object.px, object.pz

			object.model:SetPrimaryPartCFrame(centerCFrame * CFrame.Angles(0, object.r * math.pi/2, 0) + rotationCFrame * Vector3.new(x, object.sy/2, z))
		end

		if (springVelocity.magnitude < .01 and tweenAlpha >= 1) then
			resting = true
		end
	else
		local rotationCFrame = currentAxis * CFrame.Angles(0, cr * math.pi/2, 0)

		for i = 1, #currentObjects do
			local object = currentObjects[i]
			local x, z = object.px, object.pz

			object.model:SetPrimaryPartCFrame(rotationCFrame * CFrame.Angles(0, object.r * math.pi/2, 0) + rotationCFrame * Vector3.new(x, object.sy/2, z) + currentPosition)
		end

		resting = true
	end
end

local function run(display)
	local position, rotation = inputCapture()

	if (position or rotation) then
		calc(position, rotation)
		if (display) then
			render()
		end
	end
end

local function place()
	if (currentPlane and (obstacleCollision()) and (tick() - lastPlacement) >= PLACEMENT_COOLDOWN and not currentPlane.loading) then
		lastPlacement = tick()

		local modelCFrames = {}

		for i = 1, #currentObjects do
			local object = currentObjects[i]
			modelCFrames[i] = currentAxis * CFrame.Angles(0, (object.r + cr) * math.pi/2, 0) +  (currentAxis * CFrame.Angles(0, cr * math.pi/2, 0)) * Vector3.new(object.px, object.sy/2, object.pz) + currentPosition
		end

		currentEvent:Fire(modelCFrames)
	end
end

local function rotate()
	calc(nil, (cr + 1) % 4)
	render()
end

local function inputRotate(_, userInputState, inputObject)
	if (currentPlane and userInputState == Enum.UserInputState.End) then
		rotate()
	end
end

local function inputPlace(_, userInputState, inputObject)
	if (currentPlane and userInputState == Enum.UserInputState.End) then
		place()
	end
end

local function bindInputs()
	if (not OVERRIDE_CONTROLS) then
		if not touch then
			game:GetService("ContextActionService"):BindActionAtPriority("PlacementModule_Rotate", inputRotate, false, INPUT_PRIORITY, Enum.KeyCode.R)
			game:GetService("ContextActionService"):BindActionAtPriority("PlacementModule_Place", inputPlace, false, INPUT_PRIORITY, Enum.UserInputType.MouseButton1)
		else
			game:GetService("ContextActionService"):BindActionAtPriority("PlacementModule_Rotate", inputRotate, false, INPUT_PRIORITY, Enum.KeyCode.R)
			game:GetService("ContextActionService"):BindActionAtPriority("PlacementModule_Place", inputPlace, false, INPUT_PRIORITY, Enum.UserInputType.Touch)
		end
	end
end

local function unbindInputs()
	if (not OVERRIDE_CONTROLS) then
		game:GetService("ContextActionService"):UnbindAction("PlacementModule_Rotate")
		game:GetService("ContextActionService"):UnbindAction("PlacementModule_Place")
	end
end

local function enablePlacement(plane, models, prealigned)
	if (plane == currentPlane) then
		return
	elseif (currentPlane) then
		currentPlane:disable()
	end

	if (type(models) ~= "table") then
		models = {models}
	end

	lastRenderCycle = tick()

	currentPlane = plane
	currentBase = plane.base

	local planePosition = currentBase.CFrame * Vector3.new(0, currentBase.Size.Y/2, 0)	

	resting = false
	ox, oy, oz = planePosition.X, planePosition.Y, planePosition.Z
	currentXAxis = currentBase.CFrame.rightVector
	currentYAxis = currentBase.CFrame.upVector
	currentZAxis = currentBase.CFrame.lookVector
	currentAxis = CFrame.new(0, 0, 0, currentXAxis.X, currentYAxis.X, -currentZAxis.X, currentXAxis.Y, currentYAxis.Y, -currentZAxis.Y, currentXAxis.Z, currentYAxis.Z, -currentZAxis.Z)
	currentObjects = {}
	dxx, dxy, dxz = currentXAxis.X, currentXAxis.Y, currentXAxis.Z
	dzx, dzy, dzz = currentZAxis.X, currentZAxis.Y, currentZAxis.Z
	cx, cy, cz, cr = 0, 0, 0, 0

	springVelocity = Vector3.new(0, 0, 0)
	springPosition = Vector3.new(0, 0, 0)

	tweenAlpha = 0
	tweenCurrentRotation = 0
	tweenGoalRotation = 0
	tweenStartRotation = 0

	local position, _ = inputCapture()

	if (not position) then
		position = planePosition
	end

	springPosition = position

	do
		local extentsXMin, extentsXMax = 10e10, -10e10
		local extentsZMin, extentsZMax = 10e10, -10e10

		for i = 1, #models do
			local model = models[i]
			local object = {}
			object.model = model

			local lookVector = object.model.PrimaryPart.CFrame.lookVector
			local theta
			local px, pz

			if (prealigned) then
				local position = object.model.PrimaryPart.CFrame * Vector3.new(0, -object.model.PrimaryPart.Size.Y/2 , 0) + Vector3.new(0, 0.001, 0)
				px, pz = project(position.X, position.Y, position.Z)

				theta = math.acos(math.clamp(lookVector:Dot(currentZAxis), -1, 1))
				local cross = lookVector:Cross(currentZAxis)

				if (cross:Dot(currentYAxis) > 0) then
					theta = -theta
				end

			else
				px, pz = object.model.PrimaryPart.Position.X, object.model.PrimaryPart.Position.Z
				theta = math.atan2(lookVector.X, lookVector.Z)		
			end

			local x, z = model.PrimaryPart.Size.X, model.PrimaryPart.Size.Z

			object.r = round((theta % (2 * math.pi))/(math.pi/2), 1)

			if (object.r == 1 or object.r == 3) then
				x, z = z, x
			end

			local x1, x2 = px + x/2, px - x/2
			local z1, z2 = pz + z/2, pz - z/2	

			if (x2 < extentsXMin) then
				extentsXMin = x2
			end
			if (x1 > extentsXMax) then
				extentsXMax = x1
			end

			if (z2 < extentsZMin) then
				extentsZMin = z2
			end
			if (z1 > extentsZMax) then
				extentsZMax = z1
			end

			for _, instance in pairs(model:GetDescendants()) do
				if hasProperty(instance, "CanCollide") and hasProperty(instance, "Transparency") and hasProperty(instance, "Anchored") then
					instance.Transparency = .5
					instance.Anchored = true
					instance.CanCollide = false
				end
			end

			setState(object, plane.loading and states.loading or states.neutral)

			currentObjects[i] = object
		end

		currentExtentsX, currentExtentsZ = round(extentsXMax - extentsXMin, currentPlane.grid), round(extentsZMax - extentsZMin, currentPlane.grid)

		for i = 1, #currentObjects do
			local object = currentObjects[i]
			local px, pz

			if (prealigned) then
				local position = object.model.PrimaryPart.CFrame * Vector3.new(0, -object.model.PrimaryPart.Size.Y/2, 0)		
				px, pz = project(position.X, position.Y, position.Z)
			else
				px, pz = object.model.PrimaryPart.Position.X, object.model.PrimaryPart.Position.Z
			end

			object.px = px - (extentsXMin + extentsXMax)/2
			object.pz = (pz - (extentsZMin + extentsZMax)/2) * (prealigned and -1 or 1)

			object.sx, object.sy, object.sz = object.model.PrimaryPart.Size.X, object.model.PrimaryPart.Size.Y, object.model.PrimaryPart.Size.Z
		end
	end

	renderConnection = runService.RenderStepped:connect(run)
	module.currentPlane = currentPlane
	currentEvent = Instance.new("BindableEvent")

	if (GRID_TEXTURE) then
		currentTexture = Instance.new("Texture", currentPlane.base)
		currentTexture.Texture = GRID_TEXTURE
		currentTexture.Color3 = GRID_COLOR
		currentTexture.Transparency = GRID_TRANSPARENCY
		currentTexture.Face = Enum.NormalId.Top
		currentTexture.StudsPerTileU = currentPlane.grid
		currentTexture.StudsPerTileV = currentPlane.grid
	end

	bindInputs()

	run(true)

	return currentEvent.Event
end

local function disablePlacement(plane)
	if (currentPlane) then
		renderConnection:Disconnect()
		renderConnection = nil
		currentPlane = nil
		module.currentPlane = nil
		currentEvent:Destroy()
		currentEvent = nil

		if (currentTexture) then
			currentTexture:Destroy()
			currentTexture = nil
		end

		for i = 1, #currentObjects do
			local object = currentObjects[i]
			object.model = nil
			currentObjects[i] = nil
		end

		unbindInputs()
	end
end

local function setLoading(plane, isLoading)
	if (plane.loading == isLoading) then
		return
	end

	plane.loading = isLoading

	if (plane == currentPlane) then
		if (isLoading) then
			for i = 1, #currentObjects do
				setState(currentObjects[i], states.loading)
			end
		else
			for i = 1, #currentObjects do
				setState(currentObjects[i], states.neutral, true)
			end

			obstacleCollision()
		end
	end
end

module.new = function(base, obstacles, grid)
	local plane = {}
	plane.base = base
	plane.obstacles = obstacles
	plane.position = base.Position
	plane.size = base.Size

	if (math.floor(.5 + plane.size.X/grid) % 2 == 0) then
		plane.offsetX = -grid/2
	else
		plane.offsetX = 0
	end

	if (math.floor(.5 + plane.size.Z/grid) % 2 == 0) then
		plane.offsetZ = -grid/2
	else
		plane.offsetZ = 0
	end


	plane.stateEvent = Instance.new("BindableEvent")
	plane.stateChanged = plane.stateEvent.Event

	plane.grid = grid
	plane.enable = enablePlacement
	plane.disable = disablePlacement
	plane.rotate = rotate
	plane.place = place
	plane.setLoading = setLoading

	return plane
end

module.setLoading = setLoading
module.currentPlane = false

return module