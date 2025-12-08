local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Busca el evento
local remoteEvent = ReplicatedStorage:WaitForChild("RunAlgorithm")

local frame = script.Parent:WaitForChild("Frame")

-- Mapeo de [Nombre del Botón en Explorer] = "Nombre del Archivo en Algorithms"
local algorithms = {
	BtnAStar = "AStar",
	["RRT*"] = "RRTStar", -- ¡CORREGIDO! Ahora coincide con tu botón "RRT*"
	BtnGreedy = "Greedy",
	BtnRoblox = "RobloxNative",
	BtnReactive = "AntColony" 
}

-- Conectar cada botón
for btnName, algoName in pairs(algorithms) do
	-- Busca el botón por su nombre exacto
	local btn = frame:FindFirstChild(btnName)

	if btn then
		btn.MouseButton1Click:Connect(function()
			print("Solicitando: " .. algoName)
			remoteEvent:FireServer(algoName)
		end)
	else
		warn("Cuidado: No encontré el botón llamado: " .. btnName)
	end
end