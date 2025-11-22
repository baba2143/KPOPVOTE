//
//  DiscoverView.swift
//  KPOPVOTE
//
//  K-VOTE COLLECTOR - Votes Tab Discover View (Phase 2)
//

import SwiftUI

struct DiscoverView: View {
    @StateObject private var viewModel = CollectionViewModel()
    @State private var selectedCollectionId: String?
    @State private var showCollectionDetail = false
    @State private var showCreateCollection = false

    var body: some View {
        NavigationView {
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
            .navigationTitle("Discover")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showCreateCollection = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(Constants.Colors.accentPink)
                            .font(.system(size: 24))
                    }
                }
            }
            .sheet(isPresented: $showCreateCollection) {
                // TODO: Create Collection View (Week 3)
                Text("コレクション作成画面（Week 3で実装）")
            }
            .sheet(isPresented: $showCollectionDetail) {
                if let collectionId = selectedCollectionId {
                    NavigationView {
                        CollectionDetailView(collectionId: collectionId)
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
}

// MARK: - Search Bar View
struct SearchBarView: View {
    @Binding var searchQuery: String

    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(Constants.Colors.textGray)

            TextField("コレクションを検索", text: $searchQuery)
                .autocapitalization(.none)

            if !searchQuery.isEmpty {
                Button(action: {
                    searchQuery = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(Constants.Colors.textGray)
                }
            }
        }
        .padding(12)
        .background(Constants.Colors.cardDark)
        .cornerRadius(12)
    }
}

// MARK: - Tag Filter View
struct TagFilterView: View {
    let selectedTags: [String]
    let onToggleTag: (String) -> Void

    // Popular tags
    let popularTags = ["BTS", "BLACKPINK", "TWICE", "MAMA2024", "授賞式", "カムバ"]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(popularTags, id: \.self) { tag in
                    TagChip(
                        tag: tag,
                        isSelected: selectedTags.contains(tag),
                        onTap: {
                            onToggleTag(tag)
                        }
                    )
                }
            }
        }
    }
}

struct TagChip: View {
    let tag: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Text(tag)
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(isSelected ? .white : Constants.Colors.textGray)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(isSelected ? Constants.Colors.accentPink : Constants.Colors.cardDark)
            .cornerRadius(20)
            .onTapGesture {
                onTap()
            }
    }
}

// MARK: - Sort Options View
struct SortOptionsView: View {
    let selectedSort: CollectionViewModel.SortOption
    let onSortChange: (CollectionViewModel.SortOption) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(CollectionViewModel.SortOption.allCases, id: \.self) { option in
                    SortChip(
                        option: option,
                        isSelected: selectedSort == option,
                        onTap: {
                            onSortChange(option)
                        }
                    )
                }
            }
        }
    }
}

struct SortChip: View {
    let option: CollectionViewModel.SortOption
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        HStack(spacing: 4) {
            if isSelected {
                Image(systemName: "checkmark")
                    .font(.system(size: 12, weight: .bold))
            }

            Text(option.displayText)
                .font(.system(size: 14, weight: .medium))
        }
        .foregroundColor(isSelected ? .white : Constants.Colors.textGray)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(isSelected ? Constants.Colors.accentBlue : Constants.Colors.cardDark)
        .cornerRadius(20)
        .onTapGesture {
            onTap()
        }
    }
}

// MARK: - Trending Section View
struct TrendingSectionView: View {
    let collections: [VoteCollection]
    let onSelectCollection: (VoteCollection) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "flame.fill")
                    .foregroundColor(Constants.Colors.accentPink)
                    .font(.system(size: 16))

                Text("トレンド")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Constants.Colors.textWhite)

                Spacer()
            }
            .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(collections) { collection in
                        TrendingCollectionCard(collection: collection)
                            .onTapGesture {
                                onSelectCollection(collection)
                            }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

struct TrendingCollectionCard: View {
    let collection: VoteCollection

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Cover Image
            if let coverUrl = collection.coverImage {
                AsyncImage(url: URL(string: coverUrl)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Color.gray.opacity(0.3)
                }
                .frame(width: 200, height: 120)
                .clipped()
                .cornerRadius(12)
            } else {
                Rectangle()
                    .fill(Constants.Colors.cardDark)
                    .frame(width: 200, height: 120)
                    .cornerRadius(12)
                    .overlay(
                        Image(systemName: "photo")
                            .foregroundColor(Constants.Colors.textGray)
                            .font(.system(size: 32))
                    )
            }

            // Title
            Text(collection.title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Constants.Colors.textWhite)
                .lineLimit(2)

            // Stats
            HStack(spacing: 12) {
                HStack(spacing: 4) {
                    Image(systemName: "bookmark.fill")
                        .font(.system(size: 12))
                    Text("\(collection.saveCount)")
                        .font(.system(size: 12))
                }

                HStack(spacing: 4) {
                    Image(systemName: "square.stack.3d.up.fill")
                        .font(.system(size: 12))
                    Text("\(collection.taskCount)")
                        .font(.system(size: 12))
                }
            }
            .foregroundColor(Constants.Colors.textGray)
        }
        .frame(width: 200)
    }
}

// MARK: - Collections List Section View
struct CollectionsListSectionView: View {
    let title: String
    let collections: [VoteCollection]
    let onSelectCollection: (VoteCollection) -> Void
    let onLoadMore: () -> Void
    let hasNextPage: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(Constants.Colors.textWhite)
                .padding(.horizontal)

            if collections.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "tray")
                        .font(.system(size: 48))
                        .foregroundColor(Constants.Colors.textGray)

                    Text("コレクションが見つかりませんでした")
                        .foregroundColor(Constants.Colors.textGray)
                        .font(.system(size: 16))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                LazyVStack(spacing: 16) {
                    ForEach(collections) { collection in
                        CollectionCardView(collection: collection)
                            .onTapGesture {
                                onSelectCollection(collection)
                            }
                            .onAppear {
                                // Load more when reaching last item
                                if collection.id == collections.last?.id && hasNextPage {
                                    onLoadMore()
                                }
                            }
                    }
                }
                .padding(.horizontal)

                // Loading indicator for pagination
                if hasNextPage {
                    HStack {
                        Spacer()
                        ProgressView()
                            .tint(Constants.Colors.accentPink)
                        Spacer()
                    }
                    .padding()
                }
            }
        }
    }
}

// MARK: - Collection Card View
struct CollectionCardView: View {
    let collection: VoteCollection

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with creator info
            HStack(spacing: 8) {
                // Creator avatar
                if let avatarUrl = collection.creatorAvatarUrl {
                    AsyncImage(url: URL(string: avatarUrl)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                    }
                    .frame(width: 32, height: 32)
                    .clipShape(Circle())
                } else {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .frame(width: 32, height: 32)
                        .foregroundColor(Constants.Colors.textGray)
                }

                Text(collection.creatorName)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Constants.Colors.textGray)

                Spacer()

                // Visibility icon
                Image(systemName: collection.visibility.icon)
                    .font(.system(size: 12))
                    .foregroundColor(Constants.Colors.textGray)
            }

            // Title
            Text(collection.title)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Constants.Colors.textWhite)
                .lineLimit(2)

            // Description
            Text(collection.description)
                .font(.system(size: 14))
                .foregroundColor(Constants.Colors.textGray)
                .lineLimit(3)

            // Tags
            if !collection.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(collection.tags.prefix(5), id: \.self) { tag in
                            Text("#\(tag)")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(Constants.Colors.accentBlue)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Constants.Colors.accentBlue.opacity(0.15))
                                .cornerRadius(8)
                        }
                    }
                }
            }

            // Stats
            HStack(spacing: 16) {
                HStack(spacing: 4) {
                    Image(systemName: "bookmark.fill")
                        .font(.system(size: 14))
                    Text("\(collection.saveCount)")
                        .font(.system(size: 14))
                }

                HStack(spacing: 4) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 14))
                    Text("\(collection.likeCount)")
                        .font(.system(size: 14))
                }

                HStack(spacing: 4) {
                    Image(systemName: "square.stack.3d.up.fill")
                        .font(.system(size: 14))
                    Text("\(collection.taskCount)個のタスク")
                        .font(.system(size: 14))
                }

                Spacer()
            }
            .foregroundColor(Constants.Colors.textGray)
        }
        .padding(16)
        .background(Constants.Colors.cardDark)
        .cornerRadius(16)
    }
}

// MARK: - Error View
struct ErrorView: View {
    let message: String
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(Constants.Colors.textGray)

            Text(message)
                .foregroundColor(Constants.Colors.textGray)
                .font(.system(size: 16))
                .multilineTextAlignment(.center)

            Button(action: onRetry) {
                Text("再試行")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Constants.Colors.accentPink)
                    .cornerRadius(24)
            }
        }
        .padding()
    }
}

// MARK: - Preview
#if DEBUG
struct DiscoverView_Previews: PreviewProvider {
    static var previews: some View {
        DiscoverView()
            .preferredColorScheme(.dark)
    }
}
#endif
