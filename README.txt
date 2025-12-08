Análisis Comparativo de Algoritmos de Planificación de Rutas en Entornos de Costo Ponderado (Roblox)

Autor: Camilo Andres Arenillas Pineda  
Institución: Universidad Nacional de Colombia  
Materia: Inteligencia Artificial 

* Descripción del Proyecto
	Este repositorio contiene la implementación, experimentación y análisis de cinco 	paradigmas de búsqueda de rutas (Pathfinding) en un entorno de simulación 3D 	utilizando Roblox Studio.

	El objetivo fue evaluar el rendimiento en un mapa de cuadrícula 41x41 con costos 	de terreno heterogéneos (Carretera, Bosque, Pantano), comparando métricas 	de eficiencia, calidad y seguridad.

* Algoritmos Implementados
	1.  A* (A-Star): Búsqueda heurística óptima (f = g + h).
	2.  Greedy: Búsqueda rápida pero subóptima (f = h).
	3.  Ant Colony Optimization (ACO): Metaheurística basada en feromonas.
	4.  RRT* (Rapidly-exploring Random Tree Star): Muestreo probabilístico 	asintótico.
	5.  Roblox Native: Solución basada en NavMesh del motor.

* Estructura del Repositorio
	scr: Contiene los scripts en Lua (para Roblox) 
	data: Archivos CSV con los datos crudos de las 5 iteraciones experimentales.
	docs: Incluye el Paper en formato IEEE, imágenes de las gráficas resultantes, 	imágenes de los algoritmos, imagen del mapa principal, imágenes de la 	configuración de mapas usados para cada iteración, diagrama de flujo acerca del 	funcionamiento. 

* Resultados Destacados
	El estudio concluyó que A* es el algoritmo más robusto para este dominio, 	logrando un equilibrio perfecto entre costo y tiempo.

	| Algoritmo | Ranking IDG (0-100) | Observación |

	|A*     | 98 | Estándar de Oro. Óptimo y seguro.          |
	|Nativo | 85 | Rápido pero rígido (caja negra).           |
	|RRT*   | 70 | Bueno pero computacionalmente costoso.     |
	|Greedy | 60 | Rápido pero inseguro (alta tasa de error). |
	|ACO    | 55 | Ineficiente para cuadrículas simples.      |

* Tecnologías
	Motor: Roblox Studio (Luau).
	Análisis de Datos: Python (Pandas, Seaborn, Matplotlib).
	Documentación: LaTeX (IEEEtran).

---
Proyecto desarrollado para fines académicos.