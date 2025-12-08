local AntColony = {}

-- === CONFIGURACIÓN ===
local NUM_ANTS = 30       
local NUM_WAVES = 15      
local EVAPORATION = 0.1   
local ALPHA = 1           
local BETA = 4            

local function Dist(a, b)
	return (a.Position - b.Position).Magnitude
end

-- Función para dibujar el mapa de calor de feromonas
local function DrawPheromones(pheromones, folder)
	folder:ClearAllChildren()
	for node, level in pairs(pheromones) do
		if level > 0.6 then
			local p = Instance.new("Part")
			p.Size = Vector3.new(4, 0.5, 4)
			p.Position = node.Position + Vector3.new(0, 1, 0)
			p.Anchored = true
			p.CanCollide = false
			p.Material = Enum.Material.Neon
			p.Color = Color3.fromRGB(150, 0, 255) 

			local transparency = 1 - (level / 5) 
			if transparency < 0.1 then transparency = 0.1 end
			if transparency > 0.9 then transparency = 0.9 end
			p.Transparency = transparency

			p.Parent = folder
		end
	end
end

function AntColony.Run(startNode, goalNode, allNodes, _)
	-- CORRECCIÓN: Crear/Buscar carpeta AQUÍ dentro, no afuera
	local PheromoneFolder = workspace:FindFirstChild("PheromoneVisuals") or Instance.new("Folder", workspace)
	PheromoneFolder.Name = "PheromoneVisuals"
	PheromoneFolder:ClearAllChildren()

	-- 1. Inicializar Feromonas
	local pheromones = {}
	for _, node in pairs(allNodes) do
		pheromones[node] = 0.5 
	end

	local bestPath = nil
	local bestPathLen = math.huge
	local nodesExpanded = 0 

	-- Ciclo de Oleadas
	for wave = 1, NUM_WAVES do
		local wavePaths = {} 

		-- Lanzar Hormigas
		for ant = 1, NUM_ANTS do
			local current = startNode
			local path = {current}
			local visited = {[current] = true}
			local success = false

			for step = 1, 900 do
				nodesExpanded = nodesExpanded + 1
				if current == goalNode then success = true; break end

				local neighbors = current.Neighbors
				local probabilities = {}
				local totalProb = 0

				for _, neighbor in pairs(neighbors) do
					if not visited[neighbor] then
						local pheromone = pheromones[neighbor] or 0.5
						local h = 1 / (Dist(neighbor, goalNode) + 0.1)
						local prob = (pheromone ^ ALPHA) * (h ^ BETA)
						table.insert(probabilities, {node = neighbor, p = prob})
						totalProb = totalProb + prob
					end
				end

				if totalProb == 0 then break end

				local r = math.random() * totalProb
				local sum = 0
				local nextNode = nil
				for _, entry in ipairs(probabilities) do
					sum = sum + entry.p
					if sum >= r then nextNode = entry.node; break end
				end
				if not nextNode and #probabilities > 0 then nextNode = probabilities[1].node end

				if nextNode then
					current = nextNode
					visited[current] = true
					table.insert(path, current)
				else break end
			end

			if success then
				table.insert(wavePaths, path)
				if #path < bestPathLen then bestPath = path; bestPathLen = #path end
			end
		end

		-- Evaporación y Refuerzo
		for node, val in pairs(pheromones) do pheromones[node] = val * (1 - EVAPORATION) end
		for _, path in ipairs(wavePaths) do
			local contribution = 80 / #path 
			for _, node in ipairs(path) do
				pheromones[node] = (pheromones[node] or 0.5) + contribution
			end
		end

		-- VISUALIZAR USANDO LA CARPETA ACTUALIZADA
		DrawPheromones(pheromones, PheromoneFolder)
		wait(0.1) 
	end

	if bestPath then
		local posPath = {}
		for _, n in ipairs(bestPath) do table.insert(posPath, n.Position) end
		return posPath, nodesExpanded
	end
	return nil, nodesExpanded
end

return AntColony