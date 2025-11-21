//
//  CollectionViewModel.swift
//  KPOPVOTE
//
//  K-VOTE COLLECTOR - Collection ViewModel (Phase 2)
//

import Foundation
import Combine

@MainActor
class CollectionViewModel: ObservableObject {
    // MARK: - Published Properties

    // Discover Tab
    @Published var trendingCollections: [VoteCollection] = []
    @Published var latestCollections: [VoteCollection] = []
    @Published var searchResults: [VoteCollection] = []

    // My Collections
    @Published var savedCollections: [VoteCollection] = []
    @Published var myCollections: [VoteCollection] = []

    // Detail View
    @Published var currentCollection: VoteCollection?
    @Published var isSaved: Bool = false
    @Published var isLiked: Bool = false
    @Published var isOwner: Bool = false

    // Pagination
    @Published var currentPage: Int = 1
    @Published var hasNextPage: Bool = false
    @Published var totalPages: Int = 1

    // UI State
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var searchQuery: String = ""
    @Published var selectedTags: [String] = []
    @Published var sortOption: SortOption = .latest

    // MARK: - Private Properties
    private let collectionService = CollectionService.shared
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Sorting Options
    enum SortOption: String, CaseIterable {
        case latest = "latest"
        case popular = "popular"
        case trending = "trending"
        case relevance = "relevance"

        var displayText: String {
            switch self {
            case .latest:
                return "最新順"
            case .popular:
                return "人気順"
            case .trending:
                return "トレンド"
            case .relevance:
                return "関連度順"
            }
        }
    }

    // MARK: - Initialization
    init() {
        setupSearchDebounce()
    }

    // MARK: - Setup

    /// Setup search query debouncing
    private func setupSearchDebounce() {
        $searchQuery
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] query in
                if !query.isEmpty {
                    Task {
                        await self?.performSearch(query: query)
                    }
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Fetch Methods

    /// Load trending collections for Discover tab
    func loadTrendingCollections(period: String = "7d", limit: Int = 10) async {
        isLoading = true
        errorMessage = nil

        do {
            trendingCollections = try await collectionService.getTrendingCollections(period: period, limit: limit)
            print("✅ [CollectionViewModel] Loaded \(trendingCollections.count) trending collections")
        } catch {
            errorMessage = NetworkErrorHandler.getUserMessage(for: error)
            print("❌ [CollectionViewModel] Failed to load trending: \(error.localizedDescription)")
        }

        isLoading = false
    }

    /// Load latest collections for Discover tab
    func loadLatestCollections(page: Int = 1, limit: Int = 20) async {
        isLoading = true
        errorMessage = nil

        do {
            let response = try await collectionService.getCollections(
                page: page,
                limit: limit,
                sortBy: sortOption.rawValue,
                tags: selectedTags.isEmpty ? nil : selectedTags
            )

            if page == 1 {
                latestCollections = response.data.collections
            } else {
                latestCollections.append(contentsOf: response.data.collections)
            }

            currentPage = response.data.pagination.currentPage
            totalPages = response.data.pagination.totalPages
            hasNextPage = response.data.pagination.hasNext

            print("✅ [CollectionViewModel] Loaded \(response.data.collections.count) collections (page \(page))")
        } catch {
            errorMessage = NetworkErrorHandler.getUserMessage(for: error)
            print("❌ [CollectionViewModel] Failed to load latest: \(error.localizedDescription)")
        }

        isLoading = false
    }

    /// Load next page of collections
    func loadNextPage() async {
        guard hasNextPage && !isLoading else { return }
        await loadLatestCollections(page: currentPage + 1)
    }

    /// Perform search with query
    func performSearch(query: String, page: Int = 1) async {
        guard !query.isEmpty else {
            searchResults = []
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            let response = try await collectionService.searchCollections(
                query: query,
                page: page,
                limit: 20,
                sortBy: sortOption.rawValue,
                tags: selectedTags.isEmpty ? nil : selectedTags
            )

            if page == 1 {
                searchResults = response.data.collections
            } else {
                searchResults.append(contentsOf: response.data.collections)
            }

            currentPage = response.data.pagination.currentPage
            totalPages = response.data.pagination.totalPages
            hasNextPage = response.data.pagination.hasNext

            print("✅ [CollectionViewModel] Found \(response.data.collections.count) collections for '\(query)'")
        } catch {
            errorMessage = NetworkErrorHandler.getUserMessage(for: error)
            print("❌ [CollectionViewModel] Search failed: \(error.localizedDescription)")
        }

        isLoading = false
    }

    /// Load saved collections
    func loadSavedCollections(page: Int = 1) async {
        isLoading = true
        errorMessage = nil

        do {
            let response = try await collectionService.getSavedCollections(page: page, limit: 20)

            if page == 1 {
                savedCollections = response.data.collections
            } else {
                savedCollections.append(contentsOf: response.data.collections)
            }

            currentPage = response.data.pagination.currentPage
            totalPages = response.data.pagination.totalPages
            hasNextPage = response.data.pagination.hasNext

            print("✅ [CollectionViewModel] Loaded \(response.data.collections.count) saved collections")
        } catch {
            errorMessage = NetworkErrorHandler.getUserMessage(for: error)
            print("❌ [CollectionViewModel] Failed to load saved: \(error.localizedDescription)")
        }

        isLoading = false
    }

    /// Load user's created collections
    func loadMyCollections(page: Int = 1) async {
        isLoading = true
        errorMessage = nil

        do {
            let response = try await collectionService.getMyCollections(page: page, limit: 20)

            if page == 1 {
                myCollections = response.data.collections
            } else {
                myCollections.append(contentsOf: response.data.collections)
            }

            currentPage = response.data.pagination.currentPage
            totalPages = response.data.pagination.totalPages
            hasNextPage = response.data.pagination.hasNext

            print("✅ [CollectionViewModel] Loaded \(response.data.collections.count) created collections")
        } catch {
            errorMessage = NetworkErrorHandler.getUserMessage(for: error)
            print("❌ [CollectionViewModel] Failed to load my collections: \(error.localizedDescription)")
        }

        isLoading = false
    }

    /// Load collection detail
    func loadCollectionDetail(collectionId: String) async {
        isLoading = true
        errorMessage = nil

        do {
            let response = try await collectionService.getCollectionDetail(collectionId: collectionId)

            currentCollection = response.data.collection
            isSaved = response.data.isSaved
            isLiked = response.data.isLiked
            isOwner = response.data.isOwner

            print("✅ [CollectionViewModel] Loaded collection detail: \(response.data.collection.title)")
        } catch {
            errorMessage = NetworkErrorHandler.getUserMessage(for: error)
            print("❌ [CollectionViewModel] Failed to load detail: \(error.localizedDescription)")
        }

        isLoading = false
    }

    // MARK: - Action Methods

    /// Toggle save/unsave collection
    func toggleSaveCollection(collectionId: String) async -> Bool {
        do {
            let response = try await collectionService.toggleSaveCollection(collectionId: collectionId)
            isSaved = response.data.saved

            // Update saveCount in current collection
            if var collection = currentCollection {
                collection.saveCount = response.data.saveCount
                currentCollection = collection
            }

            print("✅ [CollectionViewModel] Save toggled: \(isSaved)")
            return true
        } catch {
            errorMessage = NetworkErrorHandler.getUserMessage(for: error)
            print("❌ [CollectionViewModel] Save toggle failed: \(error.localizedDescription)")
            return false
        }
    }

    /// Add collection tasks to user's task list
    func addCollectionToTasks(collectionId: String) async -> AddToTasksData? {
        do {
            let response = try await collectionService.addCollectionToTasks(collectionId: collectionId)

            print("✅ [CollectionViewModel] Added \(response.data.addedCount) tasks")
            return response.data
        } catch {
            errorMessage = NetworkErrorHandler.getUserMessage(for: error)
            print("❌ [CollectionViewModel] Add to tasks failed: \(error.localizedDescription)")
            return nil
        }
    }

    // MARK: - Filter Methods

    /// Apply tag filter
    func toggleTag(_ tag: String) {
        if selectedTags.contains(tag) {
            selectedTags.removeAll { $0 == tag }
        } else {
            selectedTags.append(tag)
        }

        // Reload with new filter
        Task {
            if searchQuery.isEmpty {
                await loadLatestCollections(page: 1)
            } else {
                await performSearch(query: searchQuery, page: 1)
            }
        }
    }

    /// Clear all filters
    func clearFilters() {
        selectedTags.removeAll()
        searchQuery = ""
        sortOption = .latest

        Task {
            await loadLatestCollections(page: 1)
        }
    }

    /// Change sort option
    func changeSortOption(_ option: SortOption) {
        sortOption = option

        Task {
            if searchQuery.isEmpty {
                await loadLatestCollections(page: 1)
            } else {
                await performSearch(query: searchQuery, page: 1)
            }
        }
    }

    // MARK: - Helper Methods

    /// Clear error message
    func clearError() {
        errorMessage = nil
    }

    /// Refresh all data
    func refresh() async {
        await loadTrendingCollections()
        await loadLatestCollections(page: 1)
    }
}
