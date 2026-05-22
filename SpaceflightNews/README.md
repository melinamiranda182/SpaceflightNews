# SpaceflightNews

Aplicación iOS que consume la API de Spaceflight News implementando Clean Architecture pragmática con MVVM.

## Arquitectura

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

## Estructura del Proyecto

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

## Características Implementadas

### Funcionalidades
- Listado de artículos con imágenes
- Búsqueda en tiempo real con debounce (500ms)
- Cancelación automática de búsquedas concurrentes
- Pull-to-refresh
- Vista de detalle de artículo
- Compartir artículos mediante ShareLink
- Manejo de estados: loading, empty, error

### Arquitectura
- Clean Architecture pragmática sin overengineering
- MVVM pattern
- Dependency Injection mediante protocols
- Repository Pattern
- Separación entre Domain Models y DTOs
- Task cancellation para evitar race conditions

### Tecnologías
- SwiftUI
- Swift Concurrency (async/await)
- Combine (debounce de búsqueda)
- XCTest para unit tests

### Optimizaciones
- Caché de imágenes en memoria con NSCache
- Debounce en búsqueda para reducir requests
- Cancelación de tareas al escribir rápidamente
- @MainActor para garantizar thread-safety en ViewModels

## Testing

### Unit Tests

El proyecto incluye tests unitarios con cobertura de los componentes principales:

**ArticleListViewModelTests:**
- Estado inicial del ViewModel
- Carga de artículos
- Manejo de estados vacíos y errores
- Búsqueda con debounce

**NetworkServiceTests:**
- Generación correcta de URLs
- Conversión de DTOs a modelos de dominio
- Manejo de errores de red

**ArticleRepositoryTests:**
- Integración con NetworkService
- Transformación de datos

Ejecutar tests: Command + U en Xcode

### UI Tests

Los UI Tests están deshabilitados en el scheme por las siguientes razones:
- Son excesivos para un challenge técnico de nivel semi-senior
- Tienden a ser frágiles y propensos a falsos negativos
- Requieren mantenimiento continuo
- Los unit tests ya demuestran la calidad y corrección del código

Para un proyecto de producción, se recomendarían integration tests en lugar de UI tests extensivos.

## Principios SOLID

- **Single Responsibility Principle**: Cada clase tiene una responsabilidad única y bien definida
- **Open/Closed Principle**: El código es extensible mediante protocolos sin modificar implementaciones existentes
- **Liskov Substitution Principle**: Los mocks son intercambiables con las implementaciones reales
- **Interface Segregation Principle**: Los protocolos son específicos y cohesivos
- **Dependency Inversion Principle**: Los ViewModels dependen de abstracciones, no de implementaciones concretas

## Setup

1. Clonar el repositorio
2. Abrir `SpaceflightNews.xcodeproj` en Xcode
3. Ejecutar con Command + R

**Requisitos:**
- Xcode 15.0+
- iOS 16.0+
- Swift 5.9+

### Configuración de App Transport Security

La API de Spaceflight News devuelve algunas imágenes mediante HTTP. El proyecto incluye configuración de App Transport Security en `Info.plist` para permitir la carga de estas imágenes:

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

## Decisiones Técnicas

### 1. ViewModels con @MainActor
Todos los ViewModels utilizan `@MainActor` para garantizar que las actualizaciones de UI ocurran en el main thread sin código adicional de dispatching.

```swift
@MainActor
final class ArticleListViewModel: ObservableObject {
    @Published internal(set) var state: ArticleListState = .idle
    // Todo el código se ejecuta automáticamente en el Main Thread
}
```

**Ventaja**: Elimina la necesidad de `DispatchQueue.main.async` y garantiza thread-safety en tiempo de compilación.

### 2. Separación Domain/Data con DTOs
Los modelos de dominio (`Article`) están separados de los DTOs (`ArticleDTO`). Esto permite:
- Modificar la API sin afectar la lógica de negocio
- Testear el dominio de manera independiente
- Cumplir con el principio de Dependency Inversion

```swift
// DTO (Data Layer) - Mapea la respuesta de la API
struct ArticleDTO: Decodable {
    let imageUrl: String?  // snake_case de la API, opcional
    
    func toDomain() -> Article? {
        Article(imageURL: imageUrl ?? "")
    }
}

// Domain Model - Modelo de negocio
struct Article {
    let imageURL: String   // camelCase, nunca nil
}
```

### 3. State Machine con Enum
El estado de la UI se modela con un enum exhaustivo que el compilador puede validar:

```swift
enum ArticleListState: Equatable {
    case idle
    case loading
    case loaded([Article])
    case empty
    case error(String)
}
```

**Ventaja**: El compilador garantiza que todos los casos estén manejados en la UI.

### 4. Cancelación de Búsquedas Concurrentes
Al escribir rápidamente, las búsquedas previas se cancelan automáticamente para evitar race conditions:

```swift
private var searchTask: Task<Void, Never>?

private func performSearch(query: String) async {
    // Cancelar búsqueda anterior si existe
    searchTask?.cancel()
    
    searchTask = Task {
        guard !Task.isCancelled else { return }
        // Realizar búsqueda
        let articles = try await repository.searchArticles(query: query)
        guard !Task.isCancelled else { return }
        state = .loaded(articles)
    }
}
```

**Beneficios**:
- Evita mostrar resultados desactualizados
- Reduce requests innecesarios a la API
- Previene condiciones de carrera

### 5. Dependency Injection con Protocols
Todas las dependencias se inyectan mediante protocolos, facilitando testing y flexibilidad:

```swift
protocol ArticleRepositoryProtocol {
    func fetchArticles(limit: Int, offset: Int) async throws -> [Article]
}

@MainActor
final class ArticleListViewModel: ObservableObject {
    private let repository: ArticleRepositoryProtocol
    
    init(repository: ArticleRepositoryProtocol = ArticleRepository()) {
        self.repository = repository
    }
}
```

**Ventaja**: Permite crear mocks para testing sin modificar el ViewModel.

### 6. Combine + async/await
- **Combine**: Para streams reactivos (debounce en búsqueda)
- **async/await**: Para operaciones asíncronas puntuales (HTTP requests)

```swift
// Combine para debounce
$searchQuery
    .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
    .sink { query in
        Task { await self.performSearch(query: query) }
    }
```

### 7. Caché de Imágenes con NSCache
Implementación personalizada que proporciona:
- Gestión automática de memoria bajo presión
- Límites configurables (100 MB, 200 imágenes)
- Limpieza automática en memory warnings

```swift
final class ImageCache {
    private let cache: NSCache<NSString, UIImage>
    
    init() {
        cache.totalCostLimit = 100 * 1024 * 1024  // 100 MB
        cache.countLimit = 200
    }
}
```

## Anti-patterns Evitados

Este proyecto evita conscientemente los siguientes anti-patterns comunes:

### 1. Lógica de negocio en Views
```swift
// Incorrecto
struct ArticleListView: View {
    var body: some View {
        List(articles.filter { $0.featured }) { article in
            // Filtrado en la View
        }
    }
}

// Correcto - Lógica en ViewModel
@MainActor
final class ArticleListViewModel: ObservableObject {
    func loadFeaturedArticles() async {
        // Filtrado en lógica de negocio
    }
}
```

### 2. Repository ejecutándose en MainActor
```swift
// Incorrecto - Bloquea el main thread
@MainActor
final class ArticleRepository {
    func fetchArticles() async throws -> [Article] {
        // Operaciones de red bloqueando UI
    }
}

// Correcto - Repository en background
final class ArticleRepository {
    func fetchArticles() async throws -> [Article] {
        // Network calls en background thread
    }
}
```

### 3. Domain Models acoplados a la API
```swift
// Incorrecto
struct Article: Codable {
    let image_url: String  // Acoplado a nombres de API
}

// Correcto - Separación con DTOs
struct ArticleDTO: Decodable {
    let image_url: String
    
    func toDomain() -> Article {
        Article(imageURL: image_url)
    }
}
```

### 4. Múltiples fuentes de verdad
```swift
// Incorrecto
@Published var articles: [Article] = []
@Published var isLoading: Bool = false
@Published var error: String? = nil

// Correcto - Estado único
@Published var state: ArticleListState = .idle
```

## Mejoras Futuras

### Performance
- Paginación infinita (actualmente carga 50 artículos)
- Precarga de imágenes para mejorar el scroll
- Persistencia local con SwiftData

### Funcionalidades
- Sistema de favoritos
- Filtros avanzados por fecha, fuente y eventos
- Modo offline con datos en caché
- Widget de iOS para artículos recientes

### Testing
- Tests de integración end-to-end
- Snapshot testing
- Tests adicionales de UI

### Accesibilidad
- Labels completos para VoiceOver
- Soporte mejorado para Dynamic Type
- Modo de alto contraste

## Notas de Implementación

### Ubicación de ArticleFilters en Domain

Los filtros están en la capa de dominio porque representan conceptos de negocio, no detalles de implementación. Esta separación permite:
- Independencia del dominio respecto a la infraestructura
- Testing independiente de la lógica de filtrado
- Facilitar cambios en la API sin afectar la lógica de negocio
