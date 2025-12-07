//
//  TutorialView.swift
//  OSHI Pick
//
//  OSHI Pick - Tutorial/Onboarding View
//  新フロー: 機能説明 → 推し選択 → アカウント登録促進
//

import SwiftUI

// MARK: - Tutorial Step
enum TutorialStep: Int, CaseIterable {
    case intro = 0
    case biasSelection = 1
    case accountPromotion = 2
}

struct TutorialView: View {
    @EnvironmentObject var authService: AuthService
    @State private var currentStep: TutorialStep = .intro
    @State private var introPage = 0
    @State private var showLogin = false
    @StateObject private var biasViewModel = BiasViewModel()

    var body: some View {
        ZStack {
            Constants.Colors.backgroundDark
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Skip Button (top right) - 全ステップで表示
                HStack {
                    Spacer()
                    Button("スキップ") {
                        completeOnboardingAsGuest()
                    }
                    .font(.system(size: Constants.Typography.bodySize))
                    .foregroundColor(Constants.Colors.textGray)
                    .padding()
                }

                // Step Content
                switch currentStep {
                case .intro:
                    TutorialIntroView(
                        currentPage: $introPage,
                        onNext: {
                            withAnimation {
                                currentStep = .biasSelection
                            }
                        }
                    )

                case .biasSelection:
                    TutorialBiasSelectionView(
                        viewModel: biasViewModel,
                        onNext: {
                            // 選択データをローカル保存（メンバーIDとグループID）
                            let selectedMemberIds = Array(biasViewModel.selectedIdols)
                            let selectedGroupIds = Array(biasViewModel.selectedGroups)
                            AppStorageManager.shared.pendingBiasIds = selectedMemberIds
                            AppStorageManager.shared.pendingGroupIds = selectedGroupIds
                            withAnimation {
                                currentStep = .accountPromotion
                            }
                        },
                        onSkip: {
                            withAnimation {
                                currentStep = .accountPromotion
                            }
                        }
                    )

                case .accountPromotion:
                    TutorialAccountPromotionView(
                        selectedMemberCount: biasViewModel.selectedIdols.count,
                        selectedGroupCount: biasViewModel.selectedGroups.count,
                        selectedIdols: biasViewModel.selectedIdolObjects,
                        selectedGroups: biasViewModel.selectedGroupObjects,
                        onRegister: {
                            showLogin = true
                        },
                        onSkip: {
                            completeOnboardingAsGuest()
                        }
                    )
                }
            }
        }
        .fullScreenCover(isPresented: $showLogin) {
            NavigationView {
                LoginView(authService: authService)
            }
        }
        .task {
            // 推し選択用のアイドルリストを事前ロード
            await biasViewModel.loadIdols()
        }
    }

    private func completeOnboardingAsGuest() {
        AppStorageManager.shared.hasCompletedOnboarding = true
        authService.loginAsGuest()
    }
}

// MARK: - Tutorial Intro View (機能説明)
struct TutorialIntroView: View {
    @Binding var currentPage: Int
    let onNext: () -> Void

    private let pages: [TutorialPage] = [
        TutorialPage(
            icon: "arrow.triangle.branch",
            title: "複数のKPOPアプリの投票を一元管理",
            description: "OSHI Pickはあなたの応援する推しの投票をタスク管理できます。これで推しへの投票を忘れたり、見逃したりすることがなくなります！",
            color: Constants.Colors.accentPink
        ),
        TutorialPage(
            icon: "hands.sparkles",
            title: "みんなで推しアイドルを応援",
            description: "現在参加中の投票を共有することで、友達がどの投票に力を入れているかが分かります",
            color: Constants.Colors.accentBlue
        ),
        TutorialPage(
            icon: "bubble.left.and.bubble.right",
            title: "同じ推しアイドルの友達とつながる",
            description: "コミュニティで推しに関する情報を投稿したり、グッズ交換のやり取りもできます",
            color: Constants.Colors.gradientPurple
        ),
        TutorialPage(
            icon: "calendar.badge.plus",
            title: "みんなで作る推しカレンダー",
            description: "推しアイドルのカムバ、TV出演情報、ライブスケジュールなどユーザー同士で登録し、共有できるカレンダーを作れます",
            color: Constants.Colors.accentPink
        )
    ]

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $currentPage) {
                ForEach(0..<pages.count, id: \.self) { index in
                    TutorialPageView(page: pages[index])
                        .tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
            .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))

            // Next Button
            Button(action: {
                if currentPage < pages.count - 1 {
                    withAnimation {
                        currentPage += 1
                    }
                } else {
                    onNext()
                }
            }) {
                HStack {
                    Text(currentPage < pages.count - 1 ? "次へ" : "推しを選択")
                        .font(.system(size: Constants.Typography.bodySize, weight: .bold))
                    Image(systemName: "arrow.right")
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [Constants.Colors.accentBlue, Constants.Colors.gradientPurple],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(16)
            }
            .padding(.horizontal)
            .padding(.bottom, 40)
        }
    }
}

// MARK: - Tutorial Bias Selection View (推し選択)
struct TutorialBiasSelectionView: View {
    @ObservedObject var viewModel: BiasViewModel
    let onNext: () -> Void
    let onSkip: () -> Void

    /// 選択中の総数（グループ + メンバー）
    private var totalSelectedCount: Int {
        viewModel.selectedGroups.count + viewModel.selectedIdols.count
    }

    /// 選択中のテキスト
    private var selectedText: String {
        let groupCount = viewModel.selectedGroups.count
        let memberCount = viewModel.selectedIdols.count

        if groupCount > 0 && memberCount > 0 {
            return "\(groupCount)グループ・\(memberCount)人"
        } else if groupCount > 0 {
            return "\(groupCount)グループ"
        } else if memberCount > 0 {
            return "\(memberCount)人"
        }
        return ""
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 8) {
                Text("推しを選択")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(Constants.Colors.textWhite)

                Text("あなたの好きなアイドルを選んでください")
                    .font(.system(size: 14))
                    .foregroundColor(Constants.Colors.textGray)
            }
            .padding(.vertical, 16)

            if viewModel.isLoading {
                Spacer()
                VStack(spacing: 16) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: Constants.Colors.accentPink))
                    Text("アイドル一覧を読み込んでいます...")
                        .font(.caption)
                        .foregroundColor(Constants.Colors.textGray)
                }
                Spacer()
            } else {
                // Mode Picker (グループ/メンバー)
                Picker("選択モード", selection: $viewModel.selectionMode) {
                    ForEach(BiasSelectionMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.bottom, 8)

                // Selected count
                if totalSelectedCount > 0 {
                    HStack {
                        Text("選択中: \(selectedText)")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Constants.Colors.accentPink)
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Constants.Colors.cardDark)
                }

                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(Constants.Colors.textGray)

                    TextField(
                        viewModel.selectionMode == .group ? "グループ名で検索" : "アイドル名・グループ名で検索",
                        text: $viewModel.searchText
                    )
                        .textFieldStyle(.plain)
                        .foregroundColor(Constants.Colors.textWhite)
                        .autocorrectionDisabled()

                    if !viewModel.searchText.isEmpty {
                        Button(action: { viewModel.searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(Constants.Colors.textGray)
                        }
                    }
                }
                .padding(10)
                .background(Constants.Colors.cardDark)
                .cornerRadius(10)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)

                // Alphabet filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(viewModel.ALPHABET, id: \.self) { char in
                            AlphabetTabButton(
                                char: char,
                                count: viewModel.selectionMode == .group
                                    ? (char == "ALL" ? viewModel.allGroups.count : (viewModel.groupAlphabetCounts[char] ?? 0))
                                    : (char == "ALL" ? viewModel.allIdols.count : (viewModel.alphabetCounts[char] ?? 0)),
                                isSelected: viewModel.selectedChar == char,
                                onTap: {
                                    viewModel.selectedChar = char
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                }
                .background(Constants.Colors.backgroundDark.opacity(0.5))

                // Content based on mode
                if viewModel.selectionMode == .group {
                    // Group list
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(viewModel.filteredGroupsByAlphabet) { group in
                                GroupSelectionRow(
                                    group: group,
                                    isSelected: viewModel.isGroupSelected(group),
                                    onTap: {
                                        viewModel.toggleGroup(group)
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 16)
                    }
                } else {
                    // Idol list
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(viewModel.groupNames, id: \.self) { groupName in
                                VStack(alignment: .leading, spacing: 12) {
                                    // Group header
                                    HStack {
                                        Text(groupName)
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundColor(Constants.Colors.textWhite)

                                        Spacer()

                                        Text("\(viewModel.groupedIdols[groupName]?.count ?? 0)人")
                                            .font(.system(size: 14))
                                            .foregroundColor(Constants.Colors.textGray)
                                    }
                                    .padding(.horizontal, 16)

                                    // Idols in group
                                    VStack(spacing: 8) {
                                        ForEach(viewModel.groupedIdols[groupName] ?? []) { idol in
                                            IdolSelectionRow(
                                                idol: idol,
                                                isSelected: viewModel.isSelected(idol),
                                                onTap: {
                                                    viewModel.toggleIdol(idol)
                                                }
                                            )
                                        }
                                    }
                                    .padding(.horizontal, 16)
                                }
                            }
                        }
                        .padding(.vertical, 16)
                    }
                }
            }

            // Bottom Buttons
            VStack(spacing: 12) {
                Button(action: onNext) {
                    HStack {
                        Text(totalSelectedCount > 0 ? "次へ (\(selectedText)選択中)" : "次へ")
                            .font(.system(size: Constants.Typography.bodySize, weight: .bold))
                        Image(systemName: "arrow.right")
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [Constants.Colors.accentPink, Constants.Colors.gradientPink],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(16)
                }

                Button(action: onSkip) {
                    Text("後で選ぶ")
                        .font(.system(size: Constants.Typography.bodySize, weight: .medium))
                        .foregroundColor(Constants.Colors.textGray)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
    }
}

// MARK: - Group Selection Row (オンボーディング用)
struct GroupSelectionRow: View {
    let group: GroupMaster
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Checkbox
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? Constants.Colors.accentPink : Constants.Colors.textGray)

                // Group info
                Text(group.name)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Constants.Colors.textWhite)

                Spacer()
            }
            .padding(12)
            .background(isSelected ? Constants.Colors.accentPink.opacity(0.1) : Constants.Colors.cardDark)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Constants.Colors.accentPink : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Tutorial Account Promotion View (アカウント登録促進)
struct TutorialAccountPromotionView: View {
    let selectedMemberCount: Int
    let selectedGroupCount: Int
    let selectedIdols: [IdolMaster]
    let selectedGroups: [GroupMaster]
    let onRegister: () -> Void
    let onSkip: () -> Void

    /// 選択中の総数
    private var totalCount: Int {
        selectedMemberCount + selectedGroupCount
    }

    /// 選択中のテキスト
    private var selectedText: String {
        if selectedGroupCount > 0 && selectedMemberCount > 0 {
            return "\(selectedGroupCount)グループ・\(selectedMemberCount)人"
        } else if selectedGroupCount > 0 {
            return "\(selectedGroupCount)グループ"
        } else if selectedMemberCount > 0 {
            return "\(selectedMemberCount)人"
        }
        return ""
    }

    /// 表示用の名前リスト
    private var displayNames: String {
        var names: [String] = []

        // グループ名を追加
        names.append(contentsOf: selectedGroups.prefix(2).map { $0.name })

        // メンバー名を追加（残り枠）
        let remaining = 3 - names.count
        if remaining > 0 {
            names.append(contentsOf: selectedIdols.prefix(remaining).map { $0.name })
        }

        let total = selectedGroupCount + selectedMemberCount
        let suffix = total > 3 ? " 他" : ""
        return names.joined(separator: ", ") + suffix
    }

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Icon
            ZStack {
                Circle()
                    .fill(Constants.Colors.accentPink.opacity(0.2))
                    .frame(width: 140, height: 140)

                Circle()
                    .fill(Constants.Colors.accentPink.opacity(0.3))
                    .frame(width: 120, height: 120)

                Circle()
                    .fill(Constants.Colors.accentPink)
                    .frame(width: 100, height: 100)

                Image(systemName: totalCount > 0 ? "heart.fill" : "person.crop.circle")
                    .font(.system(size: 50))
                    .foregroundColor(.white)
            }

            // Title & Description
            VStack(spacing: 12) {
                if totalCount > 0 {
                    Text("\(selectedText)の推しを選択しました！")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(Constants.Colors.textWhite)

                    // 選択した推しの名前を表示（最大3件）
                    if !displayNames.isEmpty {
                        Text(displayNames)
                            .font(.system(size: 14))
                            .foregroundColor(Constants.Colors.accentPink)
                    }

                    Text("アカウント登録で推しを保存して\n投票に参加しましょう！")
                        .font(.system(size: 16))
                        .foregroundColor(Constants.Colors.textGray)
                        .multilineTextAlignment(.center)
                        .padding(.top, 8)
                } else {
                    Text("さあ、始めましょう！")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(Constants.Colors.textWhite)

                    Text("アカウント登録で推し設定や投票に\n参加できるようになります")
                        .font(.system(size: 16))
                        .foregroundColor(Constants.Colors.textGray)
                        .multilineTextAlignment(.center)
                }
            }

            Spacer()

            // Buttons
            VStack(spacing: 12) {
                Button(action: onRegister) {
                    HStack {
                        Image(systemName: "person.fill")
                        Text("アカウントを登録する")
                            .font(.system(size: Constants.Typography.bodySize, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [Constants.Colors.accentPink, Constants.Colors.gradientPink],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(16)
                    .shadow(color: Constants.Colors.accentPink.opacity(0.4), radius: 12, x: 0, y: 4)
                }

                Button(action: onSkip) {
                    Text("ゲストとして始める")
                        .font(.system(size: Constants.Typography.bodySize, weight: .semibold))
                        .foregroundColor(Constants.Colors.textGray)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(16)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 40)
        }
    }
}

// MARK: - Tutorial Page Model
struct TutorialPage {
    let icon: String
    let title: String
    let description: String
    let color: Color
}

// MARK: - Tutorial Page View
struct TutorialPageView: View {
    let page: TutorialPage

    var body: some View {
        VStack(spacing: Constants.Spacing.extraLarge) {
            Spacer()

            // Icon
            ZStack {
                Circle()
                    .fill(page.color.opacity(0.2))
                    .frame(width: 160, height: 160)

                Circle()
                    .fill(page.color.opacity(0.3))
                    .frame(width: 140, height: 140)

                Circle()
                    .fill(page.color)
                    .frame(width: 120, height: 120)

                Image(systemName: page.icon)
                    .font(.system(size: 60))
                    .foregroundColor(.white)
            }

            // Title
            Text(page.title)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(Constants.Colors.textWhite)
                .multilineTextAlignment(.center)

            // Description
            Text(page.description)
                .font(.system(size: Constants.Typography.bodySize))
                .foregroundColor(Constants.Colors.textGray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Spacer()
        }
    }
}

// MARK: - Preview
#Preview {
    TutorialView()
        .environmentObject(AuthService())
}
