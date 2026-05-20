# SpaceflightNews - Challenge Técnico iOS

Aplicación iOS moderna desarrollada con SwiftUI que consume la API de Spaceflight News, implementando Clean Architecture y mejores prácticas de desarrollo móvil.

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
│  │   Models    │      │  Use Cases  │      │
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
│  │  Networking │      │ Extensions  │      │
│  └─────────────┘      └─────────────┘      │
└─────────────────────────────────────────────┘
```

## 📁 Estructura del Proyecto

```
SpaceflightNews/
├── App/
│   └── SpaceflightNewsApp.swift
│
├── Core/
│   ├── Networking/
│   │   ├── NetworkService.swift      # Servicio genérico de red
│   │   └── APIEndpoint.swift         # Definición type-safe de endpoints
│   └── Extensions/
│
├── Domain/
│   ├── Models/
│   │   └── Article.swift             # Modelo de dominio puro
│   └── UseCases/
│
├── Data/
│   ├── Repositories/
│   │   └── ArticleRepository.swift   # Abstracción de origen de datos
│   └── DTOs/
│       └── ArticleDTO.swift          # Data Transfer Objects
│
└── Presentation/
    ├── ArticleList/
    │   ├── ArticleListView.swift
    │   └── ArticleListViewModel.swift
    ├── ArticleDetail/
    │   ├── ArticleDetailView.swift
    │   └── ArticleDetailViewModel.swift
    └── Components/
```

## 🎯 Características Implementadas

### ✅ Funcionalidades
- [x] Listado de artículos con imágenes
- [x] Búsqueda en tiempo real con debounce (500ms)
- [x] Navegación a detalle de artículo
- [x] Compartir artículos
- [x] Abrir artículo completo en Safari
- [x] Estados de loading, empty y error
- [x] Persistencia de estado en rotación (automática por @StateObject)

### ✅ Arquitectura
- [x] Clean Architecture simplificada
- [x] MVVM pattern
- [x] Separación de responsabilidades (SRP)
- [x] Dependency Injection
- [x] Protocol-oriented programming
- [x] Repository pattern

### ✅ Tecnologías
- [x] SwiftUI
- [x] Swift Concurrency (async/await)
- [x] Combine (para debounce de búsqueda)
- [x] XCTest (tests unitarios)

### ✅ Mejores Prácticas
- [x] Type-safe networking
- [x] Manejo robusto de errores
- [x] Código testeable con mocks
- [x] SwiftUI previews para todos los estados
- [x] @MainActor para thread safety
- [x] Memory management correcto (weak self)
- [x] Naming conventions consistentes
- [x] Tests unitarios con XCTest

## 🧪 Testing

El proyecto incluye tests unitarios usando XCTest con cobertura completa:

- **ArticleListViewModelTests**: Tests del ViewModel principal
  - Verifica estado inicial
  - Carga exitosa de artículos
  - Manejo de estados vacíos
  - Manejo de errores
  - Búsqueda con filtros

- **NetworkServiceTests**: Tests de endpoints y conversión de DTOs
  - Generación correcta de URLs
  - Métodos HTTP correctos
  - Headers apropiados
  - Conversión de DTOs a modelos de dominio
  - Manejo de fechas inválidas
  - Decodificación JSON

- **ArticleRepositoryTests**: Tests de la capa de repositorio
  - Integración con NetworkService
  - Búsqueda con queries válidas y vacías
  - Transformación de DTOs a modelos de dominio

### Ejecutar tests
```bash
⌘ + U en Xcode
```

### Cobertura de Tests
Los tests cubren:
- ✅ Lógica de negocio (ViewModels)
- ✅ Capa de datos (Repository)
- ✅ Capa de red (NetworkService, Endpoints)
- ✅ Transformación de datos (DTOs → Domain Models)
- ✅ Manejo de errores
- ✅ Estados de UI

## 🔑 Principios SOLID Aplicados

### Single Responsibility Principle (SRP)
- Cada clase tiene una única responsabilidad
- ViewModels manejan lógica de presentación
- Repository maneja acceso a datos
- NetworkService maneja comunicación HTTP

### Open/Closed Principle (OCP)
- Uso de protocolos para extensibilidad
- NetworkServiceProtocol permite diferentes implementaciones
- ArticleRepositoryProtocol facilita testing y cambios

### Liskov Substitution Principle (LSP)
- Mocks implementan los mismos protocolos
- Permite sustituir implementaciones sin romper el código

### Interface Segregation Principle (ISP)
- Protocolos específicos y cohesivos
- No se fuerza a implementar métodos innecesarios

### Dependency Inversion Principle (DIP)
- Dependencias inyectadas via protocolos
- ViewModels dependen de abstracciones, no de implementaciones concretas

## 🚀 Cómo Usar

1. Abrir `SpaceflightNews.xcodeproj` en Xcode
2. Seleccionar simulador o dispositivo
3. ⌘ + R para ejecutar
4. La app cargará automáticamente los artículos más recientes

## 🔄 Flujo de Datos

```
User Action → View → ViewModel → Repository → NetworkService → API
                ↑        ↑            ↑              ↑
                └────────┴────────────┴──────────────┘
              @Published state updates propagate back
```

## 🎨 UI/UX

- **Diseño nativo de iOS** usando componentes del sistema
- **Vistas de estado personalizadas** para empty y error (compatible iOS 16+)
- **AsyncImage** para carga eficiente de imágenes
- **NavigationStack** para navegación moderna
- **Searchable** para búsqueda integrada
- **ShareLink** para compartir nativamente

## 📱 Compatibilidad

- iOS 16.0+
- iPadOS 16.0+
- Swift 5.9+

## 🔮 Mejoras Futuras

- [ ] Paginación infinita
- [ ] Cache de imágenes avanzado
- [ ] Favoritos persistentes con SwiftData
- [ ] Modo oscuro personalizado
- [ ] Widgets para iOS
- [ ] Tests de UI con Swift Testing
- [ ] Accessibility labels completos
- [ ] Animaciones personalizadas

---

**Desarrollado con ❤️ siguiendo las mejores prácticas de iOS**
