local DebrisMaker = {}

local TweenService = game:GetService("TweenService")
local DebrisService = game:GetService("Debris")

local partCacheMod = require(script.PartCache)

-- Ensure the Debris folder exists
local cacheFolder
if not workspace:FindFirstChild("Debris") then
	cacheFolder = Instance.new("Folder")
	cacheFolder.Name = "Debris"
	cacheFolder.Parent = workspace
else
	cacheFolder = workspace.Debris
end

local partCache = partCacheMod.new(Instance.new("Part"), 1000, cacheFolder)
local smallDebrisCache = partCacheMod.new(Instance.new("Part"), 5000, cacheFolder)

local function CFrameToOrientation(cf)
	local rx, ry, rz = cf:ToOrientation()
	return Vector3.new(math.deg(rx), math.deg(ry), math.deg(rz))
end

local function SpawnSmallDebris(explosionPos, material, debrisCache, despawnTime, colour, size)
	local random = Random.new()
	local smallDebrisCount = 1

	for _ = 1, smallDebrisCount do
		local debris = debrisCache:GetPart()
		debris.Size = (size * random:NextNumber(0.95, 1.15)) * 0.5  -- Small size
		-- Offset debris position slightly to prevent immediate overlap
		debris.Position = explosionPos + Vector3.new(
			random:NextNumber(-2, 2),
			random:NextNumber(1, 3),  -- Increased Y offset to spawn above ground
			random:NextNumber(-2, 2)
		)
		debris.Anchored = false
        debris.Transparency = 0
		debris.CanTouch = false
		debris.CanCollide = false  -- Enable collision
		debris.Material = material or Enum.Material.Concrete
		debris.Color = colour

		debris.Parent = cacheFolder

		-- Assign to "Debris" collision group
		debris.CollisionGroup = "Debris"

		-- Apply a random velocity
		local velocitySpread = 32
		local upwardForce = 22
		local velocity = Vector3.new(
			random:NextNumber(-velocitySpread, velocitySpread),
			upwardForce,
			random:NextNumber(-velocitySpread, velocitySpread)
		)
		local bodyVelocity = Instance.new("BodyVelocity")
		bodyVelocity.Velocity = velocity
		bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
		bodyVelocity.P = 5000
		bodyVelocity.Parent = debris
		task.delay(0.6, function()
			debris.CanCollide = true
		end)

		-- Optional: Add rotation for more realism
		local angularVelocity = Instance.new("BodyAngularVelocity")
		angularVelocity.AngularVelocity = Vector3.new(
			random:NextNumber(-100, 100),
			random:NextNumber(-100, 100),
			random:NextNumber(-100, 100)
		)
		angularVelocity.MaxTorque = Vector3.new(500000, 500000, 500000)
		angularVelocity.Parent = debris

		-- Cleanup BodyVelocity and BodyAngularVelocity after 0.25 seconds
		DebrisService:AddItem(bodyVelocity, 0.25)
		DebrisService:AddItem(angularVelocity, 0.25)

		-- Tween the debris to disappear smoothly after despawnTime
		task.spawn(function()
			task.wait(despawnTime)
			TweenService:Create(
				debris,
				TweenInfo.new(0.75, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut),
				{ Size = Vector3.new(0.1, 0.1, 0.1), Transparency = 1 }
			):Play()
			-- Return the part to cache after tween
			task.wait(0.75)
			debrisCache:ReturnPart(debris)
		end)
	end
end

function DebrisMaker:Ground(Pos, Normal, Distance, Size, filter, MaxRocks, Ice, despawnTime, bigExplosion)
	local random = Random.new()

	-- Default parameter handling
	filter = filter or {cacheFolder}
	Size = Size or Vector3.new(2, 2, 2)
	MaxRocks = MaxRocks or 10
	Ice = Ice or false
	despawnTime = despawnTime or 4

	local angle = 30
	local otherAngle = 360 / MaxRocks
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = filter

	local cf = CFrame.new(Pos, Pos + Normal)

	-- Inner Rocks Loop (existing functionality)
	local function InnerRocksLoop()
		for _ = 1, MaxRocks do
			local newCF = cf * CFrame.fromEulerAnglesXYZ(0, 0, math.rad(angle)) * CFrame.new(0, Distance / 2 + Distance / 10, -10)
			local ray = workspace:Raycast(newCF.Position, newCF.LookVector * -20, params)

			angle += otherAngle
			if ray then
				local part = partCache:GetPart()
				local hoof = partCache:GetPart()

				part.Position = ray.Position
				part.Orientation = CFrameToOrientation(newCF)
				part.Size = Vector3.new(Size.X * 1.3, Size.Y * 1.3, Size.Z * 0.7) * random:NextNumber(1, 1.5)
				part.CFrame *= CFrame.new(0, 0, part.Size.Z)

				local GoalCF = part.CFrame * CFrame.new(0, 0, -part.Size.Z * 0.35) * CFrame.fromEulerAnglesXYZ(random:NextNumber(-1, -0.35), random:NextNumber(-0.15, 0.15), random:NextNumber(-0.15, 0.15))

				hoof.Size = Vector3.new(part.Size.X * 1.01, part.Size.Y * 1.01, part.Size.Z * 0.25)
				hoof.CFrame = part.CFrame * CFrame.new(0, 0, -part.Size.Z / 2 - hoof.Size.Z / 2.1)

				TweenService:Create(part, TweenInfo.new(0.15), {CFrame = GoalCF}):Play()
				TweenService:Create(hoof, TweenInfo.new(0.15), {CFrame = GoalCF * CFrame.new(0, 0, -part.Size.Z / 2 - hoof.Size.Z / 2.1)}):Play()

				part.Parent = cacheFolder
				hoof.Parent = cacheFolder

				part.BrickColor = BrickColor.new("Dark grey")
				part.Anchored = true
				part.CanTouch = false
				part.CanCollide = false

				hoof.Color = ray.Instance.Color
				hoof.Anchored = true
				hoof.CanTouch = false
				hoof.CanCollide = false

				-- Assign to "Rocks" collision group
				part.CollisionGroup = "Rocks"
				hoof.CollisionGroup = "Rocks"

				-- Material handling
				if ray.Material == Enum.Material.Concrete or ray.Material == Enum.Material.Air or ray.Material == Enum.Material.Wood or ray.Material == Enum.Material.Neon or ray.Material == Enum.Material.WoodPlanks then
					part.Material = ray.Instance.Material
					hoof.Material = ray.Instance.Material
				elseif ray.Material == Enum.Material.Grass then
					part.Material = Enum.Material.Mud
					hoof.Material = Enum.Material.Grass
					part.Color = Color3.fromRGB(76, 55, 32)
					hoof.Color = Color3.fromRGB(21, 144, 87)
				else
					part.Material = Enum.Material.Concrete
					hoof.Material = ray.Instance.Material
				end

				if Ice then
					part.BrickColor = BrickColor.new("Pastel light blue")
					hoof.BrickColor = BrickColor.new("Lily white")
					part.Material = Enum.Material.Ice
					hoof.Material = Enum.Material.Sand
				end

				-- Spawn small debris at this rock's position
				SpawnSmallDebris(ray.Position, ray.Instance.Material, smallDebrisCache, despawnTime, ray.Instance.Color, Size)

				-- Despawn logic for large rocks
				task.delay(despawnTime, function()
					TweenService:Create(part, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {Size = Vector3.new(0.01, 0.01, 0.01)}):Play()
					TweenService:Create(hoof, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {Size = Vector3.new(0.01, 0.01, 0.01), CFrame = part.CFrame * CFrame.new(0, part.Size.Y / 2 - part.Size.Y / 2.1, 0)}):Play()

					task.delay(0.6, function()
						partCache:ReturnPart(part)
						partCache:ReturnPart(hoof)
					end)
				end)
			end
		end
	end

	local function OuterRocksLoop()
		for _ = 1, MaxRocks do
			local newCF = cf * CFrame.fromEulerAnglesXYZ(0, 0, math.rad(angle)) * CFrame.new(0, Distance / 2 + Distance / 2.7, -Size.Y * 2)
			local ray = workspace:Raycast(newCF.Position, newCF.LookVector * -20, params)
			angle += otherAngle
			if ray then
				local part = partCache:GetPart()
				local hoof = partCache:GetPart()

				part.Position = ray.Position
				part.Orientation = CFrameToOrientation(newCF)
				part.Size = Vector3.new(Size.X * 1.3, Size.Y * 1.3, Size.Z / 1.4) * random:NextNumber(1, 1.5)
				part.CFrame *= CFrame.new(0, 0, part.Size.Z)

				local GoalCF = part.CFrame * CFrame.new(0, 0, -part.Size.Z / 2) * CFrame.fromEulerAnglesXYZ(random:NextNumber(0.25, 0.5), random:NextNumber(-0.25, 0.25), random:NextNumber(-0.25, 0.25))
				hoof.Size = Vector3.new(part.Size.X * 1.01, part.Size.Y * 1.01, part.Size.Z * 0.25)
				hoof.CFrame = part.CFrame * CFrame.new(0, 0, -part.Size.Z / 2 - hoof.Size.Z / 2.1)
				hoof.Anchored = false

				TweenService:Create(part, TweenInfo.new(0.15), {CFrame = GoalCF}):Play()
				TweenService:Create(hoof, TweenInfo.new(0.15), {CFrame = GoalCF * CFrame.new(0, 0, -part.Size.Z / 2 - hoof.Size.Z / 2.1)}):Play()

				part.Parent = cacheFolder
				hoof.Parent = cacheFolder

				part.BrickColor = BrickColor.new("Dark grey")
				part.Anchored = true
				part.CanTouch = false
				part.CanCollide = false

				hoof.Color = ray.Instance.Color
				hoof.Anchored = true
				hoof.CanTouch = false
				hoof.CanCollide = false

				-- Assign to "Rocks" collision group
				part.CollisionGroup = "Rocks"
				hoof.CollisionGroup = "Rocks"

				-- Material handling
				if ray.Material == Enum.Material.Concrete or ray.Material == Enum.Material.Air or ray.Material == Enum.Material.Wood or ray.Material == Enum.Material.Neon or ray.Material == Enum.Material.WoodPlanks then
					part.Material = ray.Instance.Material
					hoof.Material = ray.Instance.Material
				elseif ray.Material == Enum.Material.Grass then
					part.Material = Enum.Material.Mud
					hoof.Material = Enum.Material.Grass
					part.Color = Color3.fromRGB(76, 55, 32)
					hoof.Color = Color3.fromRGB(21, 144, 87)
				else
					part.Material = Enum.Material.Concrete
					hoof.Material = ray.Instance.Material
				end

				if Ice then
					part.BrickColor = BrickColor.new("Pastel light blue")
					hoof.BrickColor = BrickColor.new("Lily white")
					part.Material = Enum.Material.Ice
					hoof.Material = Enum.Material.Sand
				end

				-- Spawn small debris at this rock's position
                if bigExplosion then
				    SpawnSmallDebris(ray.Position, ray.Instance.Material, smallDebrisCache, despawnTime, ray.Instance.Color)
                end

				-- Despawn logic for large rocks
				task.delay(despawnTime, function()
					TweenService:Create(part, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {Size = Vector3.new(0.01, 0.01, 0.01)}):Play()
					TweenService:Create(hoof, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {Size = Vector3.new(0.01, 0.01, 0.01), CFrame = part.CFrame * CFrame.new(0, part.Size.Y / 2 - part.Size.Y / 2.1, 0)}):Play()

					task.delay(0.6, function()
						partCache:ReturnPart(part)
						partCache:ReturnPart(hoof)
					end)
				end)
			end
		end
	end

	-- Execute both loops
	InnerRocksLoop()
	OuterRocksLoop()

end

return DebrisMaker