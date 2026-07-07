# 🌌 The Galaxy's Logistics & Operations Insight

**BI Analyst Challenge — Alianza Rebelde**
Un tablero estratégico para que el Consejo Jedi tome decisiones de flota y talento basadas en datos.

---

## 📖 Contexto

La Alianza Rebelde interceptó una base de datos crítica sobre recursos, naves y personal a través de la galaxia. Este proyecto transforma esos datos crudos (SWAPI) en un tablero de inteligencia que responde 4 preguntas estratégicas para el Consejo Jedi.

---

## 🔗 Entregables

| Entregable | Link |
|---|---|
| 📊 Dashboard público | **[https://super-cucurucho-bcef04.netlify.app/]** |
| 🎞️ Presentación (5 slides) | [`Consejo_Jedi_Logistica_Galactica.pptx`](./Consejo_Jedi_Logistica_Galactica.pptx) |
| 🗄️ Script de BigQuery | [`bigquery_setup.sql`](./bigquery_setup.sql) |
| 📁 Datos limpios | [`people.csv`](./people.csv) · [`planets.csv`](./planets.csv) · [`starships.csv`](./starships.csv) |

---

## 🏗️ Arquitectura

```
SWAPI (fixtures originales)
        │
        ▼
  Ingesta y limpieza (Python)
        │
        ▼
   BigQuery — capa raw
        │
        ▼
BigQuery — capa staging (tipos, joins, normalización de texto)
        │
        ▼
   4 vistas de negocio
        │
        ▼
  Dashboard público (Looker Studio / prototipo HTML)
```

> La arquitectura ingiere los datasets de People, Starships y Planets de SWAPI como tablas raw en BigQuery, sobre las cuales se aplica una capa de transformación SQL que castea tipos numéricos, resuelve relaciones (homeworld, especie, pilotos) y normaliza campos de texto para evitar duplicados por mayúsculas/espacios. Sobre esa capa limpia se construyen vistas de negocio —una por pregunta estratégica— que alimentan directamente el dashboard público.

---

## ❓ Preguntas de negocio respondidas

### 1. Eficiencia de Flota
¿Cuáles son las 3 naves más eficientes para evacuar población, medido en costo por pasajero?
→ **Trade Federation Cruiser**, **Sentinel-class Landing Craft**, **Solar Sailer**.

### 2. Análisis de Talento
¿Existe correlación entre planeta de origen y éxito como piloto?
→ Correlación débil: la variable que realmente predice presencia de pilotos es cuántas personas de ese planeta están documentadas, no el origen en sí. Es un problema de cobertura de datos, no de talento real.

### 3. Inversión Estratégica
¿En qué clúster de naves (Starship Class) invertir?
→ **Starfighter**: más unidades ya operativas, más pilotos con experiencia real y el menor costo medio entre las clases relevantes.

### 4. Anomalía Detectada
13 naves de la clase real *"starfighter"* estaban repartidas en dos etiquetas de texto distintas (`"Starfighter"` vs `"starfighter"`) por un problema de mayúsculas en el dataset original — subestimando esa clase en un 44% si no se normaliza.

---

## 🛠️ Stack técnico

- **Fuente de datos:** SWAPI (fixtures originales de `phalt/swapi`)
- **Transformación:** Python (pandas) + SQL (BigQuery)
- **Cloud:** Google Cloud Platform · BigQuery
- **Visualización:** Looker Studio (prototipo de referencia en HTML/Chart.js)
- **Presentación:** PowerPoint (PptxGenJS)

---

## 📂 Estructura del repositorio

```
├── README.md
├── people.csv
├── planets.csv
├── starships.csv
├── bigquery_setup.sql
├── dashboard_prototipo.html   (o index.html si usas GitHub Pages)
└── Consejo_Jedi_Logistica_Galactica.pptx
```

---

*Preparado por: Flavio Lavīn, Inteligencia de la Alianza Rebelde* 🛰️

