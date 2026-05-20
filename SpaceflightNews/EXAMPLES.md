# 📚 Ejemplos de Uso - Spaceflight News App

## 🎯 Casos de Uso Comunes

### 1. **Cargar Artículos Recientes**

```swift
// En tu ViewModel
func loadRecentArticles() async {
    state = .loading
    
    var filters = ArticleFilters()
    filters.limit = 20
    filters.ordering = .publishedDescending
    
    do {
        let articles = try await repository.fetchArticles(filters: filters)
        handleLoadedArticles(articles)
    } catch {
        state = .error(error.localizedDescription)
    }
}
```

---

### 2. **Filtrar Artículos con Lanzamientos**

```swift
func loadArticlesWithLaunches() async {
    state = .loading
    
    var filters = ArticleFilters()
    filters.limit = 30
    filters.hasLaunch = true
    filters.ordering = .publishedDescending
    
    do {
        let articles = try await repository.fetchArticles(filters: filters)
        handleLoadedArticles(articles)
    } catch {
        state = .error(error.localizedDescription)
    }
}
```

---

### 3. **Buscar por Sitio de Noticias**

```swift
func loadArticlesFrom(newsSite: String) async {
    state = .loading
    
    var filters = ArticleFilters()
    filters.limit = 20
    filters.newsSite = newsSite  // "SpaceNews", "NASA", etc.
    filters.ordering = .publishedDescending
    
    do {
        let articles = try await repository.fetchArticles(filters: filters)
        handleLoadedArticles(articles)
    } catch {
        state = .error(error.localizedDescription)
    }
}
```

---

### 4. **Paginación Infinita**

```swift
@MainActor
final class ArticleListViewModel: ObservableObject {
    @Published private(set) var state: ArticleListState = .idle
    @Published var articles: [Article] = []
    @Published var isLoadingMore = false
    
    private var currentOffset = 0
    private let pageSize = 20
    private var canLoadMore = true
    
    func loadArticles() async {
        guard !isLoadingMore else { return }
        state = .loading
        currentOffset = 0
        
        do {
            var filters = ArticleFilters()
            filters.limit = pageSize
            filters.offset = 0
            filters.ordering = .publishedDescending
            
            let newArticles = try await repository.fetchArticles(filters: filters)
            articles = newArticles
            currentOffset = pageSize
            canLoadMore = newArticles.count == pageSize
            state = .loaded(articles)
        } catch {
            state = .error(error.localizedDescription)
        }
    }
    
    func loadMoreArticles() async {
        guard canLoadMore, !isLoadingMore else { return }
        isLoadingMore = true
        
        do {
            var filters = ArticleFilters()
            filters.limit = pageSize
            filters.offset = currentOffset
            filters.ordering = .publishedDescending
            
            let newArticles = try await repository.fetchArticles(filters: filters)
            articles.append(contentsOf: newArticles)
            currentOffset += pageSize
            canLoadMore = newArticles.count == pageSize
            state = .loaded(articles)
        } catch {
            // No cambiar el estado, mantener artículos existentes
            print("Error loading more: \(error)")
        }
        
        isLoadingMore = false
    }
}
```

**En la View:**

```swift
List(articles) { article in
    NavigationLink(value: article) {
        ArticleRowView(article: article)
    }
    .task {
        // Cargar más cuando llega al último item
        if article.id == articles.last?.id {
            await viewModel.loadMoreArticles()
        }
    }
}
```

---

### 5. **Filtros con Picker en la UI**

```swift
struct ArticleListView: View {
    @StateObject private var viewModel = ArticleListViewModel()
    @State private var selectedFilter: FilterOption = .all
    
    enum FilterOption: String, CaseIterable {
        case all = "Todos"
        case launches = "Con Lanzamientos"
        case events = "Con Eventos"
        case featured = "Destacados"
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                filterPicker
                contentView
            }
            .navigationTitle("Space News")
            .task {
                if case .idle = viewModel.state {
                    await viewModel.loadArticles()
                }
            }
            .onChange(of: selectedFilter) { _, newValue in
                Task {
                    await viewModel.loadArticles(filter: newValue)
                }
            }
        }
    }
    
    private var filterPicker: some View {
        Picker("Filtro", selection: $selectedFilter) {
            ForEach(FilterOption.allCases, id: \.self) { option in
                Text(option.rawValue).tag(option)
            }
        }
        .pickerStyle(.segmented)
        .padding()
    }
}

// En el ViewModel:
extension ArticleListViewModel {
    func loadArticles(filter: ArticleListView.FilterOption) async {
        state = .loading
        
        var filters = ArticleFilters()
        filters.limit = 50
        filters.ordering = .publishedDescending
        
        switch filter {
        case .all:
            break
        case .launches:
            filters.hasLaunch = true
        case .events:
            filters.hasEvent = true
        case .featured:
            // Nota: La API no tiene un filtro 'featured' directo en v4
            // Tendrías que filtrar del lado del cliente
            break
        }
        
        do {
            let articles = try await repository.fetchArticles(filters: filters)
            handleLoadedArticles(articles)
        } catch {
            state = .error(error.localizedDescription)
        }
    }
}
```

---

### 6. **Mostrar Badge para Artículos con Lanzamientos**

```swift
struct ArticleRowView: View {
    let article: Article
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Imagen...
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(article.title)
                        .font(.headline)
                        .lineLimit(2)
                    
                    if article.hasLaunches {
                        Image(systemName: "rocket.fill")
                            .foregroundStyle(.orange)
                            .font(.caption)
                    }
                    
                    if article.hasEvents {
                        Image(systemName: "calendar")
                            .foregroundStyle(.blue)
                            .font(.caption)
                    }
                    
                    if article.featured {
                        Image(systemName: "star.fill")
                            .foregroundStyle(.yellow)
                            .font(.caption)
                    }
                }
                
                // Resto del contenido...
            }
        }
    }
}
```

---

### 7. **Búsqueda Avanzada con Debounce**

```swift
@MainActor
final class ArticleListViewModel: ObservableObject {
    @Published var searchQuery: String = ""
    @Published private(set) var state: ArticleListState = .idle
    
    private var searchTask: Task<Void, Never>?
    
    private func setupSearchDebounce() {
        $searchQuery
            .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] query in
                self?.searchTask?.cancel()
                self?.searchTask = Task {
                    await self?.performSearch(query: query)
                }
            }
            .store(in: &cancellables)
    }
    
    private func performSearch(query: String) async {
        // Cancelar si la tarea fue cancelada
        guard !Task.isCancelled else { return }
        
        if query.isEmpty {
            await loadArticles()
            return
        }
        
        state = .loading
        
        do {
            let articles = try await repository.searchArticles(query: query, limit: 50)
            guard !Task.isCancelled else { return }
            handleLoadedArticles(articles)
        } catch {
            guard !Task.isCancelled else { return }
            state = .error(error.localizedDescription)
        }
    }
}
```

---

### 8. **Ordenamiento Personalizado**

```swift
struct ArticleListView: View {
    @StateObject private var viewModel = ArticleListViewModel()
    @State private var sortOrder: ArticleOrdering = .publishedDescending
    
    var body: some View {
        NavigationStack {
            contentView
                .navigationTitle("Space News")
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Menu {
                            Button {
                                sortOrder = .publishedDescending
                                Task { await viewModel.loadArticles(ordering: sortOrder) }
                            } label: {
                                Label("Más recientes", systemImage: "calendar.badge.clock")
                            }
                            
                            Button {
                                sortOrder = .publishedAscending
                                Task { await viewModel.loadArticles(ordering: sortOrder) }
                            } label: {
                                Label("Más antiguos", systemImage: "calendar")
                            }
                            
                            Button {
                                sortOrder = .updatedDescending
                                Task { await viewModel.loadArticles(ordering: sortOrder) }
                            } label: {
                                Label("Actualizados recientemente", systemImage: "arrow.clockwise")
                            }
                        } label: {
                            Label("Ordenar", systemImage: "arrow.up.arrow.down")
                        }
                    }
                }
        }
    }
}

// En el ViewModel:
extension ArticleListViewModel {
    func loadArticles(ordering: ArticleOrdering) async {
        state = .loading
        
        var filters = ArticleFilters()
        filters.limit = 50
        filters.ordering = ordering
        
        do {
            let articles = try await repository.fetchArticles(filters: filters)
            handleLoadedArticles(articles)
        } catch {
            state = .error(error.localizedDescription)
        }
    }
}
```

---

### 9. **Pull to Refresh**

```swift
struct ArticleListView: View {
    @StateObject private var viewModel = ArticleListViewModel()
    
    var body: some View {
        NavigationStack {
            contentView
                .refreshable {
                    await viewModel.refresh()
                }
        }
    }
}

// En el ViewModel:
extension ArticleListViewModel {
    func refresh() async {
        await loadArticles()
    }
}
```

---

### 10. **Lista de Sitios de Noticias**

```swift
struct NewsSourcesView: View {
    @StateObject private var viewModel = NewsSourcesViewModel()
    
    var body: some View {
        List(viewModel.sources, id: \.self) { source in
            NavigationLink(destination: ArticleListView(newsSite: source)) {
                HStack {
                    Image(systemName: "newspaper")
                    Text(source)
                    Spacer()
                    Text("\(viewModel.counts[source] ?? 0)")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Fuentes")
        .task {
            await viewModel.loadSources()
        }
    }
}
```

---

## 💡 Tips y Trucos

### 1. **Cachear Resultados**

```swift
actor ArticleCache {
    private var cache: [String: [Article]] = [:]
    private let maxAge: TimeInterval = 300 // 5 minutos
    private var timestamps: [String: Date] = [:]
    
    func get(for key: String) -> [Article]? {
        guard let timestamp = timestamps[key],
              Date().timeIntervalSince(timestamp) < maxAge else {
            return nil
        }
        return cache[key]
    }
    
    func set(_ articles: [Article], for key: String) {
        cache[key] = articles
        timestamps[key] = Date()
    }
}
```

### 2. **Manejo de Errores Específicos**

```swift
func loadArticles() async {
    state = .loading
    
    do {
        let articles = try await repository.fetchArticles(limit: 50, offset: 0)
        handleLoadedArticles(articles)
    } catch let error as NetworkError {
        switch error {
        case .invalidURL:
            state = .error("URL inválida")
        case .httpError(let statusCode):
            if statusCode == 404 {
                state = .error("No se encontraron artículos")
            } else {
                state = .error("Error del servidor (\(statusCode))")
            }
        case .decodingError:
            state = .error("Error al procesar los datos")
        case .noData:
            state = .empty
        case .unknown(let underlyingError):
            state = .error("Error: \(underlyingError.localizedDescription)")
        default:
            state = .error(error.localizedDescription)
        }
    } catch {
        state = .error(error.localizedDescription)
    }
}
```

### 3. **Búsqueda con Sugerencias**

```swift
@MainActor
final class SearchViewModel: ObservableObject {
    @Published var searchQuery: String = ""
    @Published var suggestions: [String] = []
    
    private let popularSearches = ["SpaceX", "NASA", "Mars", "ISS", "Starship"]
    
    func updateSuggestions() {
        if searchQuery.isEmpty {
            suggestions = popularSearches
        } else {
            suggestions = popularSearches.filter {
                $0.localizedCaseInsensitiveContains(searchQuery)
            }
        }
    }
}
```

---

## 🎨 UI/UX Enhancements

### Shimmer Loading Effect

```swift
struct ShimmerView: View {
    @State private var isAnimating = false
    
    var body: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(
                LinearGradient(
                    colors: [.gray.opacity(0.3), .gray.opacity(0.1), .gray.opacity(0.3)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(height: 100)
            .offset(x: isAnimating ? 200 : -200)
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    isAnimating = true
                }
            }
    }
}
```

---

**¿Necesitas más ejemplos?** Consulta la documentación de la API en `API_DOCUMENTATION.md`
