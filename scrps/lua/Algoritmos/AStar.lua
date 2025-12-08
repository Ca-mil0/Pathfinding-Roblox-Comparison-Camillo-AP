local AStar = {}

-- Función Heurística (Distancia Manhattan)
local function Heuristic(a, b)
	return math.abs(a.Position.X - b.Position.X) + math.abs(a.Position.Z - b.Position.Z)
end

function AStar.Run(startNode, goalNode, allNodes, obstaclesFolder)
	local openSet = {startNode}
	local cameFrom = {}

	local gScore = {} -- Costo real desde el inicio
	local fScore = {} -- gScore + Heurística

	-- Inicialización de puntuaciones
	for _, node in pairs(allNodes) do
		gScore[node] = math.huge
		fScore[node] = math.huge
	end

	gScore[startNode] = 0
	fScore[startNode] = Heuristic(startNode, goalNode)

	local nodesExpanded = 0

	while #openSet > 0 do
		-- Selección del nodo con menor fScore
		local current = nil
		local minF = math.huge
		local currentIndex = -1

		for i, node in ipairs(openSet) do
			if fScore[node] < minF then
				minF = fScore[node]
				current = node
				currentIndex = i
			end
		end

		-- Verificación de objetivo alcanzado
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

		-- Exploración de vecinos
		for _, neighbor in pairs(current.Neighbors) do
			local tentative_gScore = gScore[current] + neighbor.Cost

			if tentative_gScore < gScore[neighbor] then
				cameFrom[neighbor] = current
				gScore[neighbor] = tentative_gScore
				fScore[neighbor] = gScore[neighbor] + Heuristic(neighbor, goalNode)

				local inOpen = false
				for _, n in ipairs(openSet) do if n == neighbor then inOpen = true break end end
				if not inOpen then table.insert(openSet, neighbor) end
			end
		end
	end
	return nil, nodesExpanded
end

return AStar