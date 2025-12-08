local PathfindingService = game:GetService("PathfindingService")
local RobloxNative = {}

function RobloxNative.Run(startNode, goalNode)
	-- CORRECCIÓN: Carpeta local para esta ejecución
	local Visuals = workspace:FindFirstChild("Native_Visuals") or Instance.new("Folder", workspace)
	Visuals.Name = "Native_Visuals"
	Visuals:ClearAllChildren()

	local startPos = startNode.Position
	local goalPos = goalNode.Position

	local agentParams = {
		AgentRadius = 1.0,    
		AgentHeight = 5.0,
		AgentCanJump = false, 
		WaypointSpacing = 4.0,
		Costs = { Water = 20, Grass = 5 }
	}

	local path = PathfindingService:CreatePath(agentParams)

	local success, errorMessage = pcall(function()
		path:ComputeAsync(startPos, goalPos)
	end)

	if success and path.Status == Enum.PathStatus.Success then
		local waypoints = path:GetWaypoints()
		local pathPoints = {}

		for _, wp in pairs(waypoints) do
			table.insert(pathPoints, wp.Position)

			-- Visualización de Puntos
			local marker = Instance.new("Part")
			marker.Shape = Enum.PartType.Ball
			marker.Size = Vector3.new(2,2,2)
			marker.Color = Color3.fromRGB(0, 150, 255) 
			marker.Material = Enum.Material.Neon
			marker.Position = wp.Position + Vector3.new(0, 4, 0)
			marker.Anchored = true
			marker.CanCollide = false
			marker.Parent = Visuals
		end
		return pathPoints, "N/A"
	else
		warn("RobloxNative Falló: " .. tostring(path.Status))
		return nil, 0
	end
end

return RobloxNative