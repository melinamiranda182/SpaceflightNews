# 📡 Spaceflight News API v4 - Documentación

## 🔗 Base URL
```
https://api.spaceflightnewsapi.net/v4
```

## 📚 Documentación Oficial
https://api.spaceflightnewsapi.net/v4/docs/

---

## 🎯 Endpoints Principales

### 1. **Articles** `/articles/`

#### GET `/v4/articles/`
Lista todos los artículos con paginación y filtros.

**Query Parameters:**
```swift
limit: Int            // Número de resultados (default: 10, max: 100)
offset: Int           // Para paginación (default: 0)
search: String        // Búsqueda en title y summary
has_event: Bool       // Filtra artículos con eventos
has_launch: Bool      // Filtra artículos con lanzamientos
news_site: String     // Filtra por sitio de noticias
published_at_gte: DateTime   // Desde fecha
published_at_lte: DateTime   // Hasta fecha
updated_at_gte: DateTime
updated_at_lte: DateTime
ordering: String      // Ordenamiento (ej: "-published_at")
```

**Ejemplo de Request:**
```
GET /v4/articles/?limit=20&offset=0&ordering=-published_at
```

**Response:**
```json
{
  "count": 1234,
  "next": "https://api.spaceflightnewsapi.net/v4/articles/?limit=10&offset=10",
  "previous": null,
  "results": [
    {
      "id": 123,
      "title": "SpaceX Launches Starship",
      "url": "https://spacenews.com/article",
      "image_url": "https://spacenews.com/image.jpg",
      "news_site": "SpaceNews",
      "summary": "SpaceX successfully launched...",
      "published_at": "2024-01-01T12:00:00Z",
      "updated_at": "2024-01-01T12:00:00Z",
      "featured": false,
      "launches": [
        {
          "launch_id": "abc123",
          "provider": "Launch Library 2"
        }
      ],
      "events": []
    }
  ]
}
```

---

#### GET `/v4/articles/{id}/`
Obtiene un artículo específico por ID.

**Response:**
```json
{
  "id": 123,
  "title": "SpaceX Launches Starship",
  "url": "https://spacenews.com/article",
  "image_url": "https://spacenews.com/image.jpg",
  "news_site": "SpaceNews",
  "summary": "SpaceX successfully launched...",
  "published_at": "2024-01-01T12:00:00Z",
  "updated_at": "2024-01-01T12:00:00Z",
  "featured": false,
  "launches": [],
  "events": []
}
```

---

### 2. **Blogs** `/blogs/`

Similar a articles pero para contenido de blogs.

```
GET /v4/blogs/
GET /v4/blogs/{id}/
```

---

### 3. **Reports** `/reports/`

Similar a articles pero para reportes técnicos.

```
GET /v4/reports/
GET /v4/reports/{id}/
```

---

## 📊 Estructura de Datos

### Article/Blog/Report
```typescript
{
  id: number
  title: string
  url: string
  image_url: string
  news_site: string
  summary: string
  published_at: string (ISO8601)
  updated_at: string (ISO8601)
  featured: boolean
  launches: Launch[]
  events: Event[]
}
```

### Launch
```typescript
{
  launch_id: string
  provider: string  // "Launch Library 2"
}
```

### Event
```typescript
{
  event_id: number
  provider: string  // "Launch Library 2"
}
```

---

## 🎨 Opciones de Ordenamiento

```swift
// Ascendente
published_at
updated_at

// Descendente (prefijo con -)
-published_at   // Más recientes primero ⭐ Recomendado
-updated_at
```

---

## 🔍 Búsqueda

La búsqueda funciona en los campos:
- `title`
- `summary`

**Ejemplo:**
```
GET /v4/articles/?search=SpaceX&limit=20
```

---

## 📱 Filtros Útiles

### Solo artículos con lanzamientos
```
GET /v4/articles/?has_launch=true&limit=20
```

### Solo artículos con eventos
```
GET /v4/articles/?has_event=true&limit=20
```

### Artículos destacados
```
GET /v4/articles/?featured=true&limit=20
```

### Filtrar por sitio de noticias
```
GET /v4/articles/?news_site=SpaceNews&limit=20
```

### Artículos recientes (última semana)
```
GET /v4/articles/?published_at_gte=2024-01-01T00:00:00Z&ordering=-published_at
```

---

## 🚀 Paginación

La API usa **offset-based pagination**.

**Ejemplo de flujo:**
```swift
// Primera página
GET /v4/articles/?limit=20&offset=0

// Segunda página
GET /v4/articles/?limit=20&offset=20

// Tercera página
GET /v4/articles/?limit=20&offset=40
```

**Response include:**
- `count`: Total de resultados
- `next`: URL de la siguiente página (null si es la última)
- `previous`: URL de la página anterior (null si es la primera)

---

## ⚠️ Límites y Consideraciones

1. **Límite máximo:** 100 resultados por request
2. **Rate limiting:** No especificado, usar responsablemente
3. **Fechas:** Formato ISO8601 (UTC)
4. **CORS:** Habilitado para todos los orígenes

---

## 💡 Mejores Prácticas

### 1. Cachear imágenes
```swift
// Usar AsyncImage con cache
AsyncImage(url: URL(string: article.imageURL))
```

### 2. Ordenar por fecha descendente
```swift
var filters = ArticleFilters()
filters.ordering = .publishedDescending
```

### 3. Usar límites razonables
```swift
// Bueno para lista inicial
filters.limit = 20

// Bueno para búsqueda
filters.limit = 50
```

### 4. Implementar paginación infinita
```swift
func loadMore() async {
    filters.offset += filters.limit
    let newArticles = try await repository.fetchArticles(filters: filters)
    articles.append(contentsOf: newArticles)
}
```

---

## 🧪 Endpoints de Prueba

### Obtener artículos recientes
```
https://api.spaceflightnewsapi.net/v4/articles/?limit=10&ordering=-published_at
```

### Buscar artículos de SpaceX
```
https://api.spaceflightnewsapi.net/v4/articles/?search=SpaceX&limit=10
```

### Obtener artículo específico
```
https://api.spaceflightnewsapi.net/v4/articles/1/
```

---

## 📝 Notas Adicionales

- La API es **read-only** (solo GET)
- No requiere autenticación
- Respuestas siempre en JSON
- Timestamps en UTC
- Content-Type: `application/json`

---

## 🔗 Referencias

- Documentación oficial: https://api.spaceflightnewsapi.net/v4/docs/
- GitHub: https://github.com/TheSpaceDevs/spaceflightnewsapi
- Website: https://www.spaceflightnewsapi.net/

---

**Última actualización:** Mayo 2026
