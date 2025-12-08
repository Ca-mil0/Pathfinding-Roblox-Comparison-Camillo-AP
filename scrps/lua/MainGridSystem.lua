-- CONFIGURACIÓN DEL SISTEMA
-- ALERTA: Usamos os.time() para que CADA VEZ que des Play, el mapa sea distinto.
math.randomseed(os.time()) 

local GRID_SIZE_X = 41 
local GRID_SIZE_Z = 41 
local NODE_SPACING = 6 

-- SERVICIOS
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunAlgorithmEvent = ReplicatedStorage:WaitForChild("RunAlgorithm")
local Debris = game:GetService("Debris")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")

local AlgorithmsFolder = game.ServerScriptService:WaitForChild("Algorithms")
local Algos = {
	AStar = require(AlgorithmsFolder.AStar),
	RRTStar = require(AlgorithmsFolder.RRTStar),
	Greedy = require(AlgorithmsFolder.Greedy),
	RobloxNative = require(AlgorithmsFolder.RobloxNative),
	AntColony = require(AlgorithmsFolder.AntColony)
}

-- CONFIGURACIÓN DE ILUMINACIÓN
Lighting.TimeOfDay = "12:00" 
Lighting.Brightness = 2
Lighting.Ambient = Color3.new(0.6, 0.6, 0.6)
Lighting.OutdoorAmbient = Color3.new(0.6, 0.6, 0.6)

-- LIMPIEZA DE ENTORNO
local objectsToDelete = {
	"Grid", "Obstacles", "PathVisuals", "Start", "Goal", "Agent", "CastleBase", "SkyBox",
	"PheromoneVisuals", "RRT_Tree", "Native_Visuals"
}
for _, name in ipairs(objectsToDelete) do
	if workspace:FindFirstChild(name) then workspace[name]:Destroy() end
end

-- CARPETAS DE ORGANIZACIÓN
local GridFolder = Instance.new("Folder", workspace); GridFolder.Name = "Grid"
local ObstaclesFolder = Instance.new("Folder", workspace); ObstaclesFolder.Name = "Obstacles"
local VisualsFolder = Instance.new("Folder", workspace); VisualsFolder.Name = "PathVisuals"

local AllNodesList = {} 
local Nodes = {}        

-- DEFINICIÓN DE COSTOS DE TERRENO
local TERRAIN_TYPES = {
	ROAD =   {Cost = 1,  Color = Color3.fromRGB(180, 180, 180), Mat = Enum.Material.Cobblestone}, 
	GRASS =  {Cost = 5,  Color = Color3.fromRGB(70, 140, 50),   Mat = Enum.Material.Grass},       
	SWAMP =  {Cost = 20, Color = Color3.fromRGB(50, 90, 140),   Mat = Enum.Material.Water}        
}

local MAT_WALL = Enum.Material.Limestone 
local COL_WALL = Color3.fromRGB(80, 80, 85)

-- FUNCIONES DE GENERACIÓN
local function CrearAntorcha(pos, parent)
	local stick = Instance.new("Part")
	stick.Size = Vector3.new(0.6, 2.5, 0.6)
	stick.Position = pos
	stick.Color = Color3.fromRGB(100, 50, 0)
	stick.Material = Enum.Material.Wood
	stick.Anchored = true; stick.CanCollide = false; stick.Parent = parent

	local firePart = Instance.new("Part")
	firePart.Size = Vector3.new(0.5, 0.5, 0.5)
	firePart.Position = pos + Vector3.new(0, 1.2, 0)
	firePart.Transparency = 1; firePart.Anchored = true; firePart.CanCollide = false; firePart.Parent = parent

	local fire = Instance.new("Fire", firePart)
	fire.Color = Color3.new(1, 0.6, 0.2); fire.SecondaryColor = Color3.new(1, 0, 0)
	fire.Size = 4; fire.Heat = 10
end

local function CrearTorre(pos)
	local tower = Instance.new("Part")
	tower.Shape = Enum.PartType.Cylinder
	tower.Size = Vector3.new(40, 25, 25) 
	tower.Position = pos + Vector3.new(0, 15, 0)
	tower.Orientation = Vector3.new(0,0,90)
	tower.Material = MAT_WALL; tower.Color = COL_WALL; tower.Anchored = true; tower.Parent = ObstaclesFolder

	local roof = Instance.new("Part")
	roof.Shape = Enum.PartType.Ball
	roof.Size = Vector3.new(26, 15, 26) 
	roof.Position = tower.Position + Vector3.new(0, 20, 0)
	roof.Material = Enum.Material.Slate; roof.Color = Color3.fromRGB(40, 40, 50); roof.Anchored = true; roof.Parent = ObstaclesFolder
end

-- INICIALIZACIÓN DE LA GRILLA
local base = Instance.new("Part")
base.Name = "CastleBase"
base.Size = Vector3.new(GRID_SIZE_X * NODE_SPACING + 30, 2, GRID_SIZE_Z * NODE_SPACING + 30)
base.Position = Vector3.new((GRID_SIZE_X * NODE_SPACING)/2, -5, (GRID_SIZE_Z * NODE_SPACING)/2) 
base.Color = Color3.fromRGB(50,50,50); base.Anchored = true; base.Parent = workspace

for x = 1, GRID_SIZE_X do
	Nodes[x] = {}
	for z = 1, GRID_SIZE_Z do
		local pos = Vector3.new(x * NODE_SPACING, 0, z * NODE_SPACING)
		Nodes[x][z] = {
			X = x, Z = z, Position = pos, Neighbors = {},
			IsObstacle = true, Type = "Wall", Cost = 1, Terrain = TERRAIN_TYPES.ROAD
		}
	end
end

-- GENERACIÓN PROCEDIMENTAL (Laberinto Nuevo cada vez)
local function CarveMaze(startX, startZ)
	local stack = {}
	local visited = {}
	local current = {x = startX, z = startZ}
	table.insert(stack, current)
	visited[startX..","..startZ] = true

	local function MakePath(x, z)
		if Nodes[x] and Nodes[x][z] then
			Nodes[x][z].IsObstacle = false
			Nodes[x][z].Type = "Path"
			table.insert(AllNodesList, Nodes[x][z])
		end
	end
	MakePath(startX, startZ) 

	while #stack > 0 do
		local cx, cz = current.x, current.z
		local neighbors = {}
		local directions = {{0,2}, {0,-2}, {2,0}, {-2,0}}
		for _, dir in pairs(directions) do
			local nx, nz = cx + dir[1], cz + dir[2]
			if nx > 1 and nx < GRID_SIZE_X and nz > 1 and nz < GRID_SIZE_Z then
				if not visited[nx..","..nz] then table.insert(neighbors, {x = nx, z = nz, dx = dir[1]/2, dz = dir[2]/2}) end
			end
		end
		if #neighbors > 0 then
			local nextNode = neighbors[math.random(1, #neighbors)]
			local wallX, wallZ = cx + nextNode.dx, cz + nextNode.dz
			MakePath(wallX, wallZ); MakePath(nextNode.x, nextNode.z)
			visited[nextNode.x..","..nextNode.z] = true
			table.insert(stack, nextNode); current = nextNode
		else current = table.remove(stack) end
	end
end
CarveMaze(2, 2)

-- AUMENTO DE COMPLEJIDAD Y BIOMAS (Aleatorio)
for i = 1, 350 do
	local rx, rz = math.random(2, GRID_SIZE_X-1), math.random(2, GRID_SIZE_Z-1)
	if Nodes[rx][rz].IsObstacle then
		Nodes[rx][rz].IsObstacle = false
		table.insert(AllNodesList, Nodes[rx][rz])
	end
end

for x = 1, GRID_SIZE_X do
	for z = 1, GRID_SIZE_Z do
		if not Nodes[x][z].IsObstacle then
			local chance = math.random()
			if chance < 0.12 then 
				Nodes[x][z].Terrain = TERRAIN_TYPES.SWAMP
				Nodes[x][z].Cost = TERRAIN_TYPES.SWAMP.Cost
			elseif chance < 0.40 then 
				Nodes[x][z].Terrain = TERRAIN_TYPES.GRASS
				Nodes[x][z].Cost = TERRAIN_TYPES.GRASS.Cost
			else
				Nodes[x][z].Terrain = TERRAIN_TYPES.ROAD
				Nodes[x][z].Cost = TERRAIN_TYPES.ROAD.Cost
			end
		end
	end
end

-- VISUALIZACIÓN
local function CrearTextoPeso(pos, costo)
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.new(0, 40, 0, 40)
	bb.StudsOffset = Vector3.new(0, 2, 0)
	bb.AlwaysOnTop = true
	bb.MaxDistance = 150 

	local txt = Instance.new("TextLabel", bb)
	txt.Size = UDim2.new(1,0,1,0)
	txt.BackgroundTransparency = 1
	txt.Text = tostring(costo)
	txt.Font = Enum.Font.GothamBold
	txt.TextStrokeTransparency = 0

	if costo >= 20 then txt.TextColor3 = Color3.new(1, 0, 0); txt.TextSize = 22 
	elseif costo >= 5 then txt.TextColor3 = Color3.new(0, 1, 0); txt.TextSize = 18 
	else txt.TextColor3 = Color3.new(1, 1, 1); txt.TextSize = 14; txt.TextTransparency = 0.5 end 

	return bb
end

for x = 1, GRID_SIZE_X do
	for z = 1, GRID_SIZE_Z do
		local n = Nodes[x][z]
		if n.IsObstacle then
			local wall = Instance.new("Part")
			local h = math.random(10, 14)
			wall.Size = Vector3.new(NODE_SPACING, h, NODE_SPACING)
			wall.Position = n.Position + Vector3.new(0, h/2, 0)
			wall.Anchored = true; wall.Material = MAT_WALL; wall.Color = COL_WALL
			wall.Parent = ObstaclesFolder

			if math.random() < 0.05 then
				CrearAntorcha(wall.Position + Vector3.new(0, 1, NODE_SPACING/2 + 0.5), ObstaclesFolder)
			end
		else
			local floor = Instance.new("Part")
			floor.Size = Vector3.new(NODE_SPACING, 1, NODE_SPACING)
			floor.Position = n.Position + Vector3.new(0, 0, 0)
			floor.Anchored = true; floor.CanCollide = true
			floor.Color = n.Terrain.Color; floor.Material = n.Terrain.Mat
			floor.Parent = GridFolder

			local label = CrearTextoPeso(n.Position, n.Cost)
			label.Parent = floor
		end
	end
end

local mapW = GRID_SIZE_X * NODE_SPACING
local mapH = GRID_SIZE_Z * NODE_SPACING
CrearTorre(Vector3.new(0, 0, 0))
CrearTorre(Vector3.new(mapW, 0, 0))
CrearTorre(Vector3.new(0, 0, mapH))
CrearTorre(Vector3.new(mapW, 0, mapH))

local neighborsOffset = { {1,0}, {-1,0}, {0,1}, {0,-1} }
for x = 1, GRID_SIZE_X do
	for z = 1, GRID_SIZE_Z do
		if not Nodes[x][z].IsObstacle then
			for _, dir in pairs(neighborsOffset) do
				local nx, nz = x + dir[1], z + dir[2]
				if nx > 0 and nx <= GRID_SIZE_X and nz > 0 and nz <= GRID_SIZE_Z then
					if not Nodes[nx][nz].IsObstacle then
						table.insert(Nodes[x][z].Neighbors, Nodes[nx][nz])
					end
				end
			end
		end
	end
end

-- === SELECCIÓN DE PUNTOS RANDOM CADA VEZ QUE DAS PLAY ===
-- Como math.randomseed cambia con os.time(), estos puntos serán distintos en cada sesión.
local startNode, goalNode

local function GetRandomValidNode()
	local attempts = 0
	local node = nil
	repeat
		local rx = math.random(2, GRID_SIZE_X - 1)
		local rz = math.random(2, GRID_SIZE_Z - 1)
		node = Nodes[rx][rz]
		attempts = attempts + 1
	until (not node.IsObstacle) or attempts > 200
	-- Fallback si no encuentra nada rápido
	if not node or node.IsObstacle then 
		return AllNodesList[math.random(1, #AllNodesList)] 
	end
	return node
end

startNode = GetRandomValidNode()
goalNode = GetRandomValidNode()

-- Aseguramos que la meta esté lejos del inicio (mínimo 100 studs)
-- para obligar al algoritmo a trabajar duro
while (startNode.Position - goalNode.Position).Magnitude < 100 do
	goalNode = GetRandomValidNode()
end

print("?? NUEVA SESIÓN GENERADA")
print("   Inicio en: (" .. startNode.X .. ", " .. startNode.Z .. ")")
print("   Meta en: (" .. goalNode.X .. ", " .. goalNode.Z .. ")")

local sPart = Instance.new("Part", workspace); sPart.Name = "Start"; sPart.Anchored = true; sPart.CanCollide = false
sPart.Size = Vector3.new(5,25,5); sPart.Position = startNode.Position + Vector3.new(0,12,0); sPart.Color = Color3.new(0,1,0); sPart.Material = Enum.Material.Neon
local gPart = Instance.new("Part", workspace); gPart.Name = "Goal"; gPart.Anchored = true; gPart.CanCollide = false
gPart.Size = Vector3.new(5,25,5); gPart.Position = goalNode.Position + Vector3.new(0,12,0); gPart.Color = Color3.new(1,0,0); gPart.Material = Enum.Material.Neon

-- SKYBOX Y SPAWN
local mapCenterX = (GRID_SIZE_X * NODE_SPACING) / 2
local mapCenterZ = (GRID_SIZE_Z * NODE_SPACING) / 2
local skyHeight = 90
local boxSize = 70

local SkyBoxModel = Instance.new("Model", workspace); SkyBoxModel.Name = "SkyBox"

local function CreateGlassPart(size, pos)
	local p = Instance.new("Part")
	p.Size = size; p.Position = pos; p.Anchored = true
	p.Material = Enum.Material.Glass; p.Color = Color3.new(0.8, 0.9, 1); p.Transparency = 0.5
	p.Parent = SkyBoxModel
end

CreateGlassPart(Vector3.new(boxSize, 1, boxSize), Vector3.new(mapCenterX, skyHeight, mapCenterZ))
CreateGlassPart(Vector3.new(boxSize, 10, 1), Vector3.new(mapCenterX, skyHeight+5, mapCenterZ - boxSize/2))
CreateGlassPart(Vector3.new(boxSize, 10, 1), Vector3.new(mapCenterX, skyHeight+5, mapCenterZ + boxSize/2))
CreateGlassPart(Vector3.new(1, 10, boxSize), Vector3.new(mapCenterX - boxSize/2, skyHeight+5, mapCenterZ))
CreateGlassPart(Vector3.new(1, 10, boxSize), Vector3.new(mapCenterX + boxSize/2, skyHeight+5, mapCenterZ))

local spawnLocation = Instance.new("SpawnLocation")
spawnLocation.Neutral = true 
spawnLocation.Size = Vector3.new(10, 1, 10)
spawnLocation.Position = Vector3.new(mapCenterX, skyHeight + 2, mapCenterZ)
spawnLocation.Anchored = true
spawnLocation.Transparency = 1
spawnLocation.Parent = SkyBoxModel

local function TeleportPlayer(player)
	if player.Character then
		player.Character:MoveTo(spawnLocation.Position + Vector3.new(0,3,0))
	end
	player.CharacterAdded:Connect(function(char)
		wait(0.5)
		char:MoveTo(spawnLocation.Position + Vector3.new(0,3,0))
	end)
end

for _, player in pairs(Players:GetPlayers()) do TeleportPlayer(player) end
Players.PlayerAdded:Connect(TeleportPlayer)

-- SIMULACIÓN VISUAL
function SimulateAgent(path, color)
	if workspace:FindFirstChild("Agent") then workspace.Agent:Destroy() end
	local agent = Instance.new("Part"); agent.Name = "Agent"; agent.Shape = Enum.PartType.Ball; agent.Size = Vector3.new(5,5,5); agent.Color = color; agent.Material = Enum.Material.Neon; agent.Anchored = true; agent.CanCollide = false; agent.Position = path[1] + Vector3.new(0,5,0); agent.Parent = workspace

	spawn(function()
		for i = 1, #path - 1 do
			if not agent or not agent.Parent then return end
			local p1 = path[i]; local p2 = path[i+1]; local dist = (p2 - p1).Magnitude
			local line = Instance.new("Part"); line.Anchored = true; line.CanCollide = false; line.Material = Enum.Material.Neon; line.Color = color; line.Size = Vector3.new(1, 1, dist); line.CFrame = CFrame.lookAt(p1, p2) * CFrame.new(0, 0, -dist/2); line.Position = line.Position + Vector3.new(0, 5, 0); line.Parent = VisualsFolder
			for alpha = 0, 1, 0.15 do
				agent.Position = p1:Lerp(p2, alpha) + Vector3.new(0,5,0)
				wait(0.01)
			end
		end
	end)
end

-- MANEJADOR DEL EVENTO (EJECUCIÓN)
RunAlgorithmEvent.OnServerEvent:Connect(function(player, algoName)
	if workspace:FindFirstChild("PheromoneVisuals") then workspace.PheromoneVisuals:Destroy() end
	if workspace:FindFirstChild("RRT_Tree") then workspace.RRT_Tree:Destroy() end
	if workspace:FindFirstChild("Native_Visuals") then workspace.Native_Visuals:Destroy() end
	if workspace:FindFirstChild("Agent") then workspace.Agent:Destroy() end
	if not workspace:FindFirstChild("PathVisuals") then 
		VisualsFolder = Instance.new("Folder", workspace); VisualsFolder.Name = "PathVisuals" 
	else
		VisualsFolder:ClearAllChildren()
	end

	local selectedAlgo = Algos[algoName]
	if not selectedAlgo then return end

	print("--- Ejecutando: " .. algoName .. " ---")
	local tStart = os.clock()
	local path, nodesExpanded = nil, 0

	local success, err = pcall(function()
		if algoName == "RobloxNative" then 
			path, nodesExpanded = selectedAlgo.Run(startNode, goalNode)
		else 
			path, nodesExpanded = selectedAlgo.Run(startNode, goalNode, AllNodesList, ObstaclesFolder) 
		end
	end)

	local tEnd = os.clock()

	if success and path and #path > 0 then
		local duration = (tEnd - tStart) * 1000
		local totalWeightedCost = 0
		local waterCount = 0 
		local grassCount = 0 

		if algoName == "RobloxNative" or algoName == "RRTStar" then
			totalWeightedCost = (startNode.Position - goalNode.Position).Magnitude
			waterCount = -1 
			grassCount = -1
		else
			for _, pos in ipairs(path) do
				local xIdx = math.floor(pos.X / NODE_SPACING + 0.5)
				local zIdx = math.floor(pos.Z / NODE_SPACING + 0.5)
				if Nodes[xIdx] and Nodes[xIdx][zIdx] then
					local node = Nodes[xIdx][zIdx]
					totalWeightedCost = totalWeightedCost + node.Cost

					if node.Cost == 20 then waterCount = waterCount + 1 end
					if node.Cost == 5 then grassCount = grassCount + 1 end
				end
			end
		end

		print(string.format("REPORTE FINAL [%s]", algoName))
		print(string.format("   Tiempo: %.4f ms", duration))
		print(string.format("   Nodos Expandidos: %s", tostring(nodesExpanded)))
		print(string.format("   Longitud (Pasos): %d", #path))
		print(string.format("   Costo Ponderado: %d", totalWeightedCost))

		if waterCount >= 0 then
			print(string.format("   Pasos en Agua: %d", waterCount))
			print(string.format("   Pasos en Bosque: %d", grassCount))
		else
			print("   (Conteo de terreno no disponible para algoritmos continuos)")
		end

		local color = Color3.fromHSV(math.random(), 1, 1)
		SimulateAgent(path, color)
	else
		warn("Error o ruta no encontrada: " .. tostring(err))
	end
end)