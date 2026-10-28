--!strict
-- RIFTBOUND PvE Navigation 2.0
-- Server-only, throttled pathfinding for hostile R15 NPCs.
-- A clear line uses inexpensive MoveTo; only obstructed travel computes a path.
-- No client may submit destinations or waypoints.
local PathfindingService = game:GetService("PathfindingService")
local Workspace = game:GetService("Workspace")

local Navigation = {}
local records = setmetatable({}, {__mode = "k"})

local DEFAULTS = {
	RepathInterval = 1.8,
	RepathGoalMovement = 12,
	WaypointReachDistance = 4,
	ArriveDistance = 3.5,
	AgentRadius = 2.5,
	AgentHeight = 5,
}

local function stateFor(character)
	local state = records[character]
	if not state then
		state = {
			serial = 0,
			pending = false,
			route = nil,
			waypointIndex = 1,
			nextRepath = 0,
			routeGoal = nil,
			mode = "",
			failures = 0,
		}
		records[character] = state
	end
	return state
end

local function invalidate(state)
	state.serial += 1
	state.pending = false
	state.route = nil
	state.waypointIndex = 1
	state.routeGoal = nil
end

local function canSeeGoal(character, root, destination, targetCharacter)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	if targetCharacter then
		params.FilterDescendantsInstances = {character, targetCharacter}
	else
		params.FilterDescendantsInstances = {character}
	end
	params.IgnoreWater = true
	local from = root.Position + Vector3.new(0, 1.2, 0)
	-- Keep line-of-sight close to waist height. Avoid mistaking the floor
	-- for a wall when the agent and its goal stand on different road pads.
	local to = Vector3.new(destination.X, from.Y, destination.Z)
	local ray = to - from
	if ray.Magnitude < 0.01 then return true end
	local hit = Workspace:Raycast(from, ray, params)
	return hit == nil or hit.Instance.CanCollide == false
end

-- Cancels any stale route without waiting for an in-flight ComputeAsync.
-- The serial + model identity also invalidate any late path result.
function Navigation.Stop(character, humanoid, root)
	local state = records[character]
	if state then
		invalidate(state)
		state.mode = ""
		state.nextRepath = 0
	end
	if humanoid and root and humanoid.Parent and root.Parent then
		humanoid:MoveTo(root.Position)
	end
end

function Navigation.Clear(character)
	local state = records[character]
	if state then invalidate(state) end
	records[character] = nil
end

function Navigation.GoTo(character, humanoid, root, destination, options)
	if not character or not character.Parent or not humanoid or humanoid.Health <= 0
		or not root or not root.Parent or typeof(destination) ~= "Vector3" then
		return "Invalid"
	end
	options = options or {}
	local mode = options.Mode or "Pursue"
	local state = stateFor(character)
	local now = os.clock()
	if state.mode ~= mode then
		invalidate(state)
		state.mode = mode
		state.nextRepath = 0
	end

	local arrive = options.ArriveDistance or DEFAULTS.ArriveDistance
	if (root.Position - destination).Magnitude <= arrive then
		if state.route or state.pending then invalidate(state) end
		humanoid:MoveTo(root.Position)
		return "Arrived"
	end

	-- Walking a straight unobstructed segment is smoother and costs no
	-- PathfindingService computation, especially on the open roads.
	if canSeeGoal(character, root, destination, options.TargetCharacter) then
		if state.route or state.pending then invalidate(state) end
		humanoid:MoveTo(destination)
		return "Direct"
	end

	local requested = state.routeGoal
	local goalShift = requested and (requested - destination).Magnitude or 0
	if goalShift > DEFAULTS.RepathGoalMovement then
		invalidate(state)
		state.nextRepath = math.min(state.nextRepath, now)
	end

	-- Never compute on the NPC think thread. Roblox ComputeAsync yields and
	-- must not freeze combat decisions or make knockback/parry unresponsive.
	if not state.pending and now >= state.nextRepath
		and (not state.route or now - (state.routeAt or 0) >= DEFAULTS.RepathInterval) then
		state.pending = true
		state.nextRepath = now + DEFAULTS.RepathInterval
		state.routeGoal = destination
		state.serial += 1
		local token = state.serial
		local start = root.Position
		local target = destination

		task.spawn(function()
			local ok, waypoints = pcall(function()
				local path = PathfindingService:CreatePath({
					AgentRadius = DEFAULTS.AgentRadius,
					AgentHeight = DEFAULTS.AgentHeight,
					AgentCanJump = true,
					WaypointSpacing = 5,
				})
				path:ComputeAsync(start, target)
				if path.Status ~= Enum.PathStatus.Success then return nil end
				return path:GetWaypoints()
			end)
			if records[character] ~= state or token ~= state.serial then return end
			state.pending = false
			if not character.Parent or humanoid.Health <= 0 then return end
			if ok and waypoints and #waypoints > 0 then
				state.route = waypoints
				state.waypointIndex = #waypoints > 1 and 2 or 1
				state.routeAt = os.clock()
				state.failures = 0
			else
				-- Retry only after the throttle window. Do not spin on
				-- impossible paths around large physical obstacles.
				state.route = nil
				state.failures += 1
				state.nextRepath = os.clock() + math.min(6,
					DEFAULTS.RepathInterval * math.min(3, state.failures))
			end
		end)
	end

	if state.route then
		local route = state.route
		local index = state.waypointIndex
		local waypoint = route[index]
		-- Consume waypoints already reached while the async query ran.
		while waypoint and (root.Position - waypoint.Position).Magnitude <=
			DEFAULTS.WaypointReachDistance do
			index += 1
			waypoint = route[index]
		end
		state.waypointIndex = index
		if waypoint then
			if waypoint.Action == Enum.PathWaypointAction.Jump then
				humanoid.Jump = true
			end
			humanoid:MoveTo(waypoint.Position)
			return "Path"
		end
		-- Route completed but the target moved since it was calculated.
		state.route = nil
	end

	-- Best-effort fallback while the route computes or when Roblox rejects
	-- a particular route. Agent leash is always enforced by CombatNPCs.
	humanoid:MoveTo(destination)
	return "Fallback"
end

return Navigation
