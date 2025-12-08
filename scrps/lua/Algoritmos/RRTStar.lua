local RRTStar = {}

-- CONFIGURACIÓN
local MAX_ITERATIONS = 4000 
local STEP_SIZE = 6         
local SEARCH_RADIUS = 15    
local GOAL_BIAS = 0.1       
local MAP_LIMIT = 260 

local function Dist(a, b) return (a - b).Magnitude end

-- Función para dibujar rama
local function DrawBranch(p1, p2, folder)
	local dist = (p1 - p2).Magnitude
	local line = Instance.new("Part")
	line.Anchored = true; line.CanCollide = false
	line.Color = Color3.fromRGB(255, 255, 0) -- Amarillo
	line.Material = Enum.Material.Neon
	line.Size = Vector3.new(0.2, 0.2, dist)
	line.CFrame = CFrame.lookAt(p1, p2) * CFrame.new(0, 0, -dist/2)
	line.Position = line.Position + Vector3.new(0, 6, 0) 
	line.Parent = folder
end

local function IsPathFree(startPos, endPos, obstaclesFolder)
	local dir = endPos - startPos
	local dist = dir.Magnitude
	if dist < 0.1 then return true end
	local rayParams = RaycastParams.new()
	rayParams.FilterDescendantsInstances = {obstaclesFolder}
	rayParams.FilterType = Enum.RaycastFilterType.Include
	local origin = startPos + Vector3.new(0, 5, 0) 
	local result = workspace:Raycast(origin, dir.Unit * dist, rayParams)
	return result == nil
end

function RRTStar.Run(startNode, goalNode, _, obstaclesFolder)
	-- CORRECCIÓN: Crear carpeta VIVA en cada ejecución
	local Visuals = workspace:FindFirstChild("RRT_Tree") or Instance.new("Folder", workspace)
	Visuals.Name = "RRT_Tree"
	Visuals:ClearAllChildren()

	local startPos = startNode.Position
	local goalPos = goalNode.Position
	local tree = {}
	table.insert(tree, {pos = startPos, parent = nil, cost = 0})

	local bestGoalIdx = nil
	local bestGoalCost = math.huge

	for i = 1, MAX_ITERATIONS do
		local randPos
		if math.random() < GOAL_BIAS then randPos = goalPos 
		else randPos = Vector3.new(math.random(0, MAP_LIMIT), startPos.Y, math.random(0, MAP_LIMIT)) end

		local nearestIdx = -1
		local minDist = math.huge
		for idx, node in ipairs(tree) do
			local d = Dist(node.pos, randPos)
			if d < minDist then minDist = d; nearestIdx = idx end
		end
		local nearestNode = tree[nearestIdx]

		local diff = randPos - nearestNode.pos
		local dist = diff.Magnitude
		local newPos = randPos
		if dist > STEP_SIZE then newPos = nearestNode.pos + (diff.Unit * STEP_SIZE) end

		if IsPathFree(nearestNode.pos, newPos, obstaclesFolder) then
			-- Pasamos la carpeta correcta
			DrawBranch(nearestNode.pos, newPos, Visuals)

			local newNode = {pos = newPos, parent = nearestIdx, cost = nearestNode.cost + Dist(nearestNode.pos, newPos)}
			table.insert(tree, newNode); local newNodeIdx = #tree

			local dGoal = Dist(newPos, goalPos)
			if dGoal < STEP_SIZE and IsPathFree(newPos, goalPos, obstaclesFolder) then
				if newNode.cost + dGoal < bestGoalCost then
					bestGoalCost = newNode.cost + dGoal; bestGoalIdx = newNodeIdx
				end
			end
		end
		if i % 50 == 0 then wait() end 
	end

	if bestGoalIdx then
		local path = {goalPos}
		local currIdx = bestGoalIdx
		while currIdx do
			local node = tree[currIdx]
			table.insert(path, 1, node.pos)
			currIdx = node.parent
		end
		return path, #tree
	end
	return nil, #tree
end

return RRTStar