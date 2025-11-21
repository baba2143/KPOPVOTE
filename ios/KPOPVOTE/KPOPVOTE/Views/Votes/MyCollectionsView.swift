//
//  MyCollectionsView.swift
//  KPOPVOTE
//
//  K-VOTE COLLECTOR - My Collections View (Phase 2)
//

import SwiftUI

struct MyCollectionsView: View {
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
                        EmptyStateView(
                            icon: "square.stack.3d.up",
                            message: "作成したコレクションがありません",
                            description: "投票タスクをまとめたコレクションを作成しましょう"
                        )
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
            .navigationTitle("マイコレクション")
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
            .sheet(isPresented: $showCollectionDetail) {
                if let collectionId = selectedCollectionId {
                    NavigationView {
                        CollectionDetailView(collectionId: collectionId)
                    }
                }
            }
            .sheet(isPresented: $showCreateCollection) {
                // TODO: Create Collection View (Week 3)
                Text("コレクション作成画面（Week 3で実装）")
            }
            .onAppear {
                Task {
                    await viewModel.loadMyCollections()
                }
            }
        }
    }
}

// MARK: - Preview
#if DEBUG
struct MyCollectionsView_Previews: PreviewProvider {
    static var previews: some View {
        MyCollectionsView()
            .preferredColorScheme(.dark)
    }
}
#endif
