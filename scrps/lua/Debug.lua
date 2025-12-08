wait(5)
print("=== DIAGNÓSTICO DEL SISTEMA ===")
local algos = game.ServerScriptService:WaitForChild("Algorithms")
print("Carpeta Algorithms encontrada: " .. tostring(algos))
print("Archivos dentro:")
for _, child in pairs(algos:GetChildren()) do
	print(" - " .. child.Name .. " (" .. child.ClassName .. ")")
end

local rrt = require(algos:WaitForChild("RRTStar"))
print("Módulo RRTStar cargado correctamente: " .. tostring(rrt))
if rrt.Run then
	print("Función Run existe en RRTStar.")
else
	warn("CRÍTICO: RRTStar no tiene función Run.")
end
print("=== FIN DIAGNÓSTICO ===")