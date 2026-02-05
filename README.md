## Análisis Comparativo de Algoritmos de Planificación de Rutas en Entornos de Navegación con Costos Ponderados: Un Estudio de Caso en Roblox

Autores: Camilo Andres Arenillas Pineda, Juan Pablo Hoyos Sanchez

Institución: Universidad Nacional de Colombia

## Descripción del Proyecto

Este repositorio contiene la implementación, experimentación y análisis de cinco paradigmas de búsqueda de rutas (Pathfinding) en un entorno de simulación 3D 	utilizando Roblox Studio.

El objetivo fue evaluar el rendimiento en un mapa de cuadrícula 41x41 con costos de terreno heterogéneos (Carretera, Bosque, Pantano), comparando métricas 	de eficiencia, calidad y seguridad.

## Algoritmos Implementados

1.  A* (A-Star): Búsqueda heurística óptima (f = g + h).

2.  Greedy: Búsqueda rápida pero subóptima (f = h).

3.  Ant Colony Optimization (ACO): Metaheurística basada en feromonas.

4.  RRT\* (Rapidly-exploring Random Tree Star): Muestreo probabilístico asintótico.

5.  Roblox Native: Solución basada en NavMesh del motor.

## Estructura del Repositorio

scr: Contiene los scripts en Lua (para Roblox)

data: Archivos CSV con los datos crudos de las 5 iteraciones experimentales.

## Tecnologías

Motor: Roblox Studio (Luau).

Análisis de Datos: Python (Pandas, Seaborn, Matplotlib).

Documentación: LaTeX (IEEEtran).

---

Proyecto desarrollado para fines académicos.
