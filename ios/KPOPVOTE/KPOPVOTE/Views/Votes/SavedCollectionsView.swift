//
//  SavedCollectionsView.swift
//  KPOPVOTE
//
//  K-VOTE COLLECTOR - Saved Collections View (Phase 2)
//

import SwiftUI

struct SavedCollectionsView: View {
    @StateObject private var viewModel = CollectionViewModel()
    @State private var selectedCollectionId: String?
    @State private var showCollectionDetail = false

    var body: some View {
        NavigationView {
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
            .navigationTitle("保存済み")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showCollectionDetail) {
                if let collectionId = selectedCollectionId {
                    NavigationView {
                        CollectionDetailView(collectionId: collectionId)
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
}

struct EmptyStateView: View {
    let icon: String
    let message: String
    let description: String

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(Constants.Colors.textGray)

            Text(message)
                .foregroundColor(Constants.Colors.textWhite)
                .font(.system(size: 18, weight: .semibold))

            Text(description)
                .foregroundColor(Constants.Colors.textGray)
                .font(.system(size: 14))
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

// MARK: - Preview
#if DEBUG
struct SavedCollectionsView_Previews: PreviewProvider {
    static var previews: some View {
        SavedCollectionsView()
            .preferredColorScheme(.dark)
    }
}
#endif
