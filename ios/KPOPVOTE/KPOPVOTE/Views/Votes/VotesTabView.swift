//
//  VotesTabView.swift
//  KPOPVOTE
//
//  K-VOTE COLLECTOR - Votes Tab Container (Phase 2)
//

import SwiftUI

struct VotesTabView: View {
    @EnvironmentObject var tabCoordinator: TabCoordinator
    @State private var selectedSegment = 0 // 0: Discover, 1: Saved, 2: My Collections

    var body: some View {
        NavigationView {
            ZStack {
                Constants.Colors.backgroundDark
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Segment Control
                    Picker("Votes Tab", selection: $selectedSegment) {
                        Text("Discover").tag(0)
                        Text("保存済み").tag(1)
                        Text("マイコレクション").tag(2)
                    }
                    .pickerStyle(.segmented)
                    .padding()
                    .background(Constants.Colors.backgroundDark)

                    // Content
                    TabView(selection: $selectedSegment) {
                        DiscoverContentView()
                            .environmentObject(tabCoordinator)
                            .tag(0)

                        SavedCollectionsContentView()
                            .environmentObject(tabCoordinator)
                            .tag(1)

                        MyCollectionsContentView()
                            .environmentObject(tabCoordinator)
                            .tag(2)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                }
            }
            .navigationTitle("Votes")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

// MARK: - Discover Content (without NavigationView wrapper)
struct DiscoverContentView: View {
    @EnvironmentObject var tabCoordinator: TabCoordinator
    @StateObject private var viewModel = CollectionViewModel()
    @State private var selectedCollectionId: String?
    @State private var showCollectionDetail = false
    @State private var showCreateCollection = false

    var body: some View {
        ZStack {
            Constants.Colors.backgroundDark
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Search Bar
                SearchBarView(searchQuery: $viewModel.searchQuery)
                    .padding(.horizontal)
                    .padding(.top, 12)

                // Tag Filter Chips
                if !viewModel.searchQuery.isEmpty || !viewModel.selectedTags.isEmpty {
                    TagFilterView(
                        selectedTags: viewModel.selectedTags,
                        onToggleTag: { tag in
                            viewModel.toggleTag(tag)
                        }
                    )
                    .padding(.horizontal)
                    .padding(.top, 8)
                }

                // Sort Options
                SortOptionsView(
                    selectedSort: viewModel.sortOption,
                    onSortChange: { option in
                        viewModel.changeSortOption(option)
                    }
                )
                .padding(.horizontal)
                .padding(.vertical, 8)

                // Content
                if viewModel.isLoading && viewModel.latestCollections.isEmpty {
                    Spacer()
                    ProgressView("読み込み中...")
                        .progressViewStyle(CircularProgressViewStyle(tint: Constants.Colors.accentPink))
                        .foregroundColor(Constants.Colors.textWhite)
                    Spacer()
                } else if let errorMessage = viewModel.errorMessage {
                    Spacer()
                    ErrorView(message: errorMessage) {
                        Task {
                            await viewModel.refresh()
                        }
                    }
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 24) {
                            // Trending Section (only when no search)
                            if viewModel.searchQuery.isEmpty && !viewModel.trendingCollections.isEmpty {
                                TrendingSectionView(
                                    collections: viewModel.trendingCollections,
                                    onSelectCollection: { collection in
                                        selectedCollectionId = collection.id
                                        showCollectionDetail = true
                                    }
                                )
                            }

                            // Collections List
                            CollectionsListSectionView(
                                title: viewModel.searchQuery.isEmpty ? "最新のコレクション" : "検索結果",
                                collections: viewModel.searchQuery.isEmpty ? viewModel.latestCollections : viewModel.searchResults,
                                onSelectCollection: { collection in
                                    selectedCollectionId = collection.id
                                    showCollectionDetail = true
                                },
                                onLoadMore: {
                                    Task {
                                        await viewModel.loadNextPage()
                                    }
                                },
                                hasNextPage: viewModel.hasNextPage
                            )
                        }
                        .padding(.vertical, 16)
                    }
                    .refreshable {
                        await viewModel.refresh()
                    }
                }
            }
        }
        .sheet(isPresented: $showCollectionDetail) {
            if let collectionId = selectedCollectionId {
                NavigationView {
                    CollectionDetailView(collectionId: collectionId)
                        .environmentObject(tabCoordinator)
                }
            }
        }
        .onAppear {
            Task {
                await viewModel.loadTrendingCollections()
                await viewModel.loadLatestCollections()
            }
        }
    }
}

// MARK: - Saved Collections Content (without NavigationView wrapper)
struct SavedCollectionsContentView: View {
    @EnvironmentObject var tabCoordinator: TabCoordinator
    @StateObject private var viewModel = CollectionViewModel()
    @State private var selectedCollectionId: String?
    @State private var showCollectionDetail = false

    var body: some View {
        ZStack {
            Constants.Colors.backgroundDark
                .ignoresSafeArea()

            VStack(spacing: 0) {
                if viewModel.isLoading && viewModel.savedCollections.isEmpty {
                    Spacer()
                    ProgressView("読み込み中...")
                        .progressViewStyle(CircularProgressViewStyle(tint: Constants.Colors.accentPink))
                        .foregroundColor(Constants.Colors.textWhite)
                    Spacer()
                } else if let errorMessage = viewModel.errorMessage {
                    Spacer()
                    ErrorView(message: errorMessage) {
                        Task {
                            await viewModel.loadSavedCollections()
                        }
                    }
                    Spacer()
                } else if viewModel.savedCollections.isEmpty {
                    Spacer()
                    EmptyStateView(
                        icon: "bookmark",
                        message: "保存したコレクションがありません",
                        description: "Discoverで気になるコレクションを保存しましょう"
                    )
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(viewModel.savedCollections) { collection in
                                CollectionCardView(collection: collection)
                                    .onTapGesture {
                                        selectedCollectionId = collection.id
                                        showCollectionDetail = true
                                    }
                                    .onAppear {
                                        if collection.id == viewModel.savedCollections.last?.id && viewModel.hasNextPage {
                                            Task {
                                                await viewModel.loadNextPage()
                                            }
                                        }
                                    }
                            }

                            if viewModel.hasNextPage {
                                HStack {
                                    Spacer()
                                    ProgressView()
                                        .tint(Constants.Colors.accentPink)
                                    Spacer()
                                }
                                .padding()
                            }
                        }
                        .padding()
                    }
                    .refreshable {
                        await viewModel.loadSavedCollections()
                    }
                }
            }
        }
        .sheet(isPresented: $showCollectionDetail) {
            if let collectionId = selectedCollectionId {
                NavigationView {
                    CollectionDetailView(collectionId: collectionId)
                        .environmentObject(tabCoordinator)
                }
            }
        }
        .onAppear {
            Task {
                await viewModel.loadSavedCollections()
            }
        }
    }
}

// MARK: - My Collections Content (without NavigationView wrapper)
struct MyCollectionsContentView: View {
    @EnvironmentObject var tabCoordinator: TabCoordinator
    @StateObject private var viewModel = CollectionViewModel()
    @State private var selectedCollectionId: String?
    @State private var showCollectionDetail = false
    @State private var showCreateCollection = false

    var body: some View {
        ZStack {
            Constants.Colors.backgroundDark
                .ignoresSafeArea()

            VStack(spacing: 0) {
                if viewModel.isLoading && viewModel.myCollections.isEmpty {
                    Spacer()
                    ProgressView("読み込み中...")
                        .progressViewStyle(CircularProgressViewStyle(tint: Constants.Colors.accentPink))
                        .foregroundColor(Constants.Colors.textWhite)
                    Spacer()
                } else if let errorMessage = viewModel.errorMessage {
                    Spacer()
                    ErrorView(message: errorMessage) {
                        Task {
                            await viewModel.loadMyCollections()
                        }
                    }
                    Spacer()
                } else if viewModel.myCollections.isEmpty {
                    Spacer()
                    VStack(spacing: 24) {
                        EmptyStateView(
                            icon: "square.stack.3d.up",
                            message: "作成したコレクションがありません",
                            description: "投票タスクをまとめたコレクションを作成しましょう"
                        )

                        Button(action: {
                            showCreateCollection = true
                        }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("コレクションを作成")
                            }
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(Constants.Colors.accentPink)
                            .cornerRadius(24)
                        }
                    }
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(viewModel.myCollections) { collection in
                                CollectionCardView(collection: collection)
                                    .onTapGesture {
                                        selectedCollectionId = collection.id
                                        showCollectionDetail = true
                                    }
                                    .onAppear {
                                        if collection.id == viewModel.myCollections.last?.id && viewModel.hasNextPage {
                                            Task {
                                                await viewModel.loadNextPage()
                                            }
                                        }
                                    }
                            }

                            if viewModel.hasNextPage {
                                HStack {
                                    Spacer()
                                    ProgressView()
                                        .tint(Constants.Colors.accentPink)
                                    Spacer()
                                }
                                .padding()
                            }
                        }
                        .padding()
                    }
                    .refreshable {
                        await viewModel.loadMyCollections()
                    }
                }
            }
        }
        .sheet(isPresented: $showCollectionDetail) {
            if let collectionId = selectedCollectionId {
                NavigationView {
                    CollectionDetailView(collectionId: collectionId)
                        .environmentObject(tabCoordinator)
                }
            }
        }
        .sheet(isPresented: $showCreateCollection) {
            CreateCollectionView()
        }
        .onAppear {
            Task {
                await viewModel.loadMyCollections()
            }
        }
    }
}

// MARK: - Preview
#if DEBUG
struct VotesTabView_Previews: PreviewProvider {
    static var previews: some View {
        VotesTabView()
            .preferredColorScheme(.dark)
    }
}
#endif
