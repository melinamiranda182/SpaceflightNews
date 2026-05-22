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

### ViewModels con @MainActor
Todos los ViewModels utilizan `@MainActor` para garantizar que las actualizaciones de UI ocurran en el main thread sin código adicional de dispatching.

```swift
@MainActor
final class ArticleListViewModel: ObservableObject {
    @Published internal(set) var state: ArticleListState = .idle
    // Todo el código se ejecuta automáticamente en el Main Thread
}
```

### Separación Domain/Data
Los modelos de dominio (`Article`) están separados de los DTOs (`ArticleDTO`). Esto permite:
- Modificar la API sin afectar la lógica de negocio
- Testear el dominio de manera independiente
- Cumplir con el principio de Dependency Inversion

```swift
// DTO (Data Layer)
struct ArticleDTO: Decodable {
    let id: Int
    let title: String
    let imageUrl: String  // snake_case de la API
}

// Domain Model
struct Article {
    let id: Int
    let title: String
    let imageURL: String   // camelCase del dominio
}
```

### Cancelación de Búsquedas Concurrentes
Al escribir rápidamente, las búsquedas previas se cancelan automáticamente para evitar race conditions y reducir requests innecesarios:

```swift
// En ArticleListViewModel
private var searchTask: Task<Void, Never>?

func performSearch() async {
    searchTask?.cancel()  // Cancela búsqueda anterior
    searchTask = Task {
        // Nueva búsqueda
    }
}
```

### Repository Pattern
La capa de presentación no conoce los detalles de implementación de la red:

```swift
// ViewModel depende solo del protocolo
protocol ArticleRepositoryProtocol {
    func fetchArticles(limit: Int, offset: Int) async throws -> [Article]
    func searchArticles(query: String) async throws -> [Article]
}

// La implementación puede cambiar sin afectar a los ViewModels
class ArticleRepository: ArticleRepositoryProtocol {
    private let networkService: NetworkServiceProtocol
    // Implementación
}
```

### Combine y async/await
- **Combine**: Utilizado para streams reactivos como el texto de búsqueda del usuario
- **async/await**: Utilizado para operaciones asíncronas puntuales como HTTP requests

Cada herramienta se emplea según su propósito específico.

### CachedAsyncImage
Implementación personalizada de carga de imágenes que proporciona:
- Caché en memoria para evitar recargas innecesarias
- Mejor experiencia de usuario durante el scroll
- Control sobre timeouts y manejo de errores

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
