# SpaceflightNews - Challenge Técnico iOS

Aplicación iOS que consume la API de Spaceflight News implementando Clean Architecture pragmática con MVVM.

## 🏗️ Arquitectura

### Clean Architecture Simplificada + MVVM

```
┌─────────────────────────────────────────────┐
│          Presentation Layer                 │
│  ┌─────────────┐      ┌─────────────┐      │
│  │   Views     │◄─────┤ ViewModels  │      │
│  └─────────────┘      └──────┬──────┘      │
└─────────────────────────────┼──────────────┘
                               │
┌──────────────────────────────▼──────────────┐
│          Domain Layer                       │
│  ┌─────────────┐      ┌─────────────┐      │
│  │   Models    │      │   Filters   │      │
│  └─────────────┘      └─────────────┘      │
└──────────────────────────┬──────────────────┘
                           │
┌──────────────────────────▼──────────────────┐
│          Data Layer                         │
│  ┌─────────────┐      ┌─────────────┐      │
│  │   DTOs      │      │ Repositories│      │
│  └─────────────┘      └──────┬──────┘      │
└─────────────────────────────┼──────────────┘
                               │
┌──────────────────────────────▼──────────────┐
│          Core Layer                         │
│  ┌─────────────┐      ┌─────────────┐      │
│  │  Networking │      │ImageLoading │      │
│  └─────────────┘      └─────────────┘      │
└─────────────────────────────────────────────┘
```

**Flujo de datos:**
```
User Action → View → ViewModel → Repository → NetworkService → API
                ↑         ↑           ↑              ↑
                └─────────┴───────────┴──────────────┘
                    @Published state updates
```

## 📁 Estructura del Proyecto

```
SpaceflightNews/
├── App/
│   └── SpaceflightNewsApp.swift
│
├── Core/
│   ├── Networking/
│   │   ├── NetworkService.swift         # Cliente HTTP genérico
│   │   └── APIEndpoint.swift            # Endpoints type-safe
│   └── ImageLoading/
│       ├── CachedAsyncImage.swift       # Carga de imágenes con caché
│       └── ImageCache.swift             # NSCache wrapper
│
├── Domain/
│   └── Models/
│       ├── Article.swift                # Modelo de dominio
│       └── ArticleFilters.swift         # Filtros de búsqueda
│
├── Data/
│   ├── Repositories/
│   │   └── ArticleRepository.swift      # Abstracción de datos
│   └── DTOs/
│       └── ArticleDTO.swift             # Data Transfer Objects
│
└── Presentation/
    ├── ArticleList/
    │   ├── ArticleListView.swift
    │   └── ArticleListViewModel.swift
    └── ArticleDetail/
        ├── ArticleDetailView.swift
        └── ArticleDetailViewModel.swift
```

## 🎯 Características Implementadas

### Funcionalidades
- ✅ Listado de artículos con imágenes
- ✅ Búsqueda en tiempo real con debounce (500ms)
- ✅ Cancelación automática de búsquedas concurrentes
- ✅ Pull-to-refresh
- ✅ Detalle de artículo
- ✅ Compartir artículos (ShareLink)
- ✅ Estados: loading, empty, error

### Arquitectura
- ✅ Clean Architecture pragmática
- ✅ MVVM pattern
- ✅ Dependency Injection via protocols
- ✅ Repository Pattern
- ✅ Domain Models separados de DTOs
- ✅ Task cancellation (evita race conditions)

### Tecnologías
- ✅ SwiftUI
- ✅ Swift Concurrency (async/await)
- ✅ Combine (debounce de búsqueda)
- ✅ XCTest (tests unitarios)

### Optimizaciones
- ✅ Caché de imágenes en memoria
- ✅ Debounce en búsqueda (reduce requests)
- ✅ Cancelación de tareas al escribir rápido
- ✅ @MainActor para thread-safety

## 🧪 Testing

Tests unitarios con cobertura completa:

**ArticleListViewModelTests:**
- Estado inicial, carga, empty, error
- Búsqueda con debounce

**NetworkServiceTests:**
- Generación de URLs
- Conversión DTOs → Models
- Manejo de errores

**ArticleRepositoryTests:**
- Integración con NetworkService
- Transformación de datos

```bash
# Ejecutar tests
⌘ + U en Xcode
```

## 🔑 Principios SOLID

- **SRP**: Cada clase tiene una responsabilidad única
- **OCP**: Extensible via protocolos
- **LSP**: Mocks intercambiables con implementaciones reales
- **ISP**: Protocolos específicos y cohesivos
- **DIP**: ViewModels dependen de abstracciones, no de implementaciones

## 🚀 Setup

1. Clonar repositorio
2. Abrir `SpaceflightNews.xcodeproj`
3. ⌘ + R para ejecutar

### Configuración de ATS

La API devuelve algunas imágenes en HTTP. El proyecto incluye configuración de App Transport Security en `Info.plist`:

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSExceptionDomains</key>
    <dict>
        <key>spaceflightnewsapi.net</key>
        <dict>
            <key>NSExceptionAllowsInsecureHTTPLoads</key>
            <true/>
        </dict>
        <key>spaceflightnow.com</key>
        <dict>
            <key>NSExceptionAllowsInsecureHTTPLoads</key>
            <true/>
        </dict>
    </dict>
</dict>
```

## 📱 Compatibilidad

- iOS 16.0+
- Swift 5.9+

## 🔧 Decisiones Técnicas Clave

### 1. ViewModels con @MainActor
Todos los ViewModels usan `@MainActor` para garantizar que las actualizaciones de UI ocurran en el main thread sin código adicional.

```swift
@MainActor
final class ArticleListViewModel: ObservableObject {
    @Published internal(set) var state: ArticleListState = .idle
    // Todo el código corre automáticamente en Main Thread
}
```

### 2. Separación Domain/Data
Los modelos de dominio (`Article`) están separados de los DTOs (`ArticleDTO`). Esto permite:
- Cambiar la API sin afectar la lógica de negocio
- Testear el dominio independientemente
- Cumplir con Dependency Inversion

```swift
// DTO (Data Layer)
struct ArticleDTO: Decodable {
    let id: Int
    let title: String
    let image_url: String  // snake_case de la API
}

// Domain Model
struct Article {
    let id: Int
    let title: String
    let imageURL: String   // camelCase del dominio
}
```

### 3. Cancelación de Búsquedas Concurrentes
Al escribir rápido, las búsquedas previas se cancelan automáticamente:

```swift
// En ArticleListViewModel
private var searchTask: Task<Void, Never>?

func performSearch() async {
    searchTask?.cancel()  // Cancela búsqueda anterior
    searchTask = Task {
        // Nueva búsqueda...
    }
}
```

Esto evita:
- Race conditions (resultados fuera de orden)
- Requests innecesarios
- Desperdicio de ancho de banda

### 4. Repository Pattern
La capa de presentación NO conoce los detalles de red:

```swift
// ViewModel solo conoce el protocolo
protocol ArticleRepositoryProtocol {
    func fetchArticles(limit: Int, offset: Int) async throws -> [Article]
    func searchArticles(query: String) async throws -> [Article]
}

// Implementación real puede cambiar sin afectar ViewModels
class ArticleRepository: ArticleRepositoryProtocol {
    private let networkService: NetworkServiceProtocol
    // ...
}
```

## 🔮 Posibles Mejoras Futuras

### Performance
- [ ] Paginación infinita (actualmente carga 50 artículos)
- [ ] Preload de imágenes para scroll más fluido
- [ ] Persistencia local con SwiftData

### Features
- [ ] Favoritos del usuario
- [ ] Filtros avanzados (por fecha, fuente, eventos)
- [ ] Modo offline con datos cacheados
- [ ] Widget de iOS para artículos recientes

### Testing
- [ ] Tests de UI con Swift Testing
- [ ] Snapshot testing
- [ ] Tests de integración end-to-end

### Accesibilidad
- [ ] VoiceOver labels completos
- [ ] Dynamic Type support mejorado
- [ ] High contrast mode

## 📝 Notas de Implementación

### ¿Por qué ArticleFilters está en Domain?

Los filtros son **conceptos de negocio**, no detalles de implementación. Movidos de `APIEndpoint` (Core) a `ArticleFilters.swift` (Domain) para:
- Separar dominio de infraestructura
- Permitir testing independiente
- Facilitar cambios de API sin afectar lógica de negocio

### ¿Por qué Combine para búsqueda y async/await para networking?

- **Combine**: Ideal para streams reactivos (texto del usuario cambiando)
- **async/await**: Ideal para operaciones asíncronas puntuales (HTTP requests)

Cada herramienta para su propósito específico.

### ¿Por qué CachedAsyncImage custom?

SwiftUI's `AsyncImage` no expone caché. Implementación custom permite:
- Evitar recargas innecesarias
- Mejor UX en scroll
- Control sobre timeouts y errores

---
