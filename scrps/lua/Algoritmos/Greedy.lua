local Greedy = {}

local function Heuristic(a, b)
	return math.abs(a.Position.X - b.Position.X) + math.abs(a.Position.Z - b.Position.Z)
end

function Greedy.Run(startNode, goalNode, allNodes, obstaclesFolder)
	local openSet = {startNode}
	local cameFrom = {}
	local visited = {[startNode] = true} -- Importante marcar visitado al inicio

	local nodesExpanded = 0

	while #openSet > 0 do
		-- Seleccionar el más cercano a la meta (sin importar costo acumulado)
		local current = nil
		local minH = math.huge
		local currentIndex = -1

		for i, node in ipairs(openSet) do
			local h = Heuristic(node, goalNode)
			if h < minH then
				minH = h
				current = node
				currentIndex = i
			end
		end

		if current == goalNode then
			local path = {}
			local curr = goalNode
			while curr do
				table.insert(path, 1, curr.Position)
				curr = cameFrom[curr]
			end
			return path, nodesExpanded
		end

		table.remove(openSet, currentIndex)
		nodesExpanded = nodesExpanded + 1

		for _, neighbor in pairs(current.Neighbors) do
			if not visited[neighbor] then
				visited[neighbor] = true
				cameFrom[neighbor] = current
				table.insert(openSet, neighbor)
			end
		end
	end
	return nil, nodesExpanded
end

return Greedy