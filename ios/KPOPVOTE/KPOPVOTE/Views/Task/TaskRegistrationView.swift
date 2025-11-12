//
//  TaskRegistrationView.swift
//  KPOPVOTE
//
//  K-VOTE COLLECTOR - Task Registration Form
//

import SwiftUI

struct TaskRegistrationView: View {
    @StateObject private var viewModel = TaskRegistrationViewModel()
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: Constants.Spacing.large) {
                    // Title Input
                    VStack(alignment: .leading, spacing: Constants.Spacing.small) {
                        Text("タスクタイトル")
                            .font(.system(size: Constants.Typography.bodySize, weight: .semibold))
                            .foregroundColor(Constants.Colors.textWhite)

                        TextField("例: MAMA 2024 投票", text: $viewModel.title)
                            .font(.system(size: Constants.Typography.bodySize))
                            .padding()
                            .background(Constants.Colors.backgroundDark)
                            .foregroundColor(Constants.Colors.textWhite)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Constants.Colors.accentPink.opacity(0.3), lineWidth: 1)
                            )

                        if let error = viewModel.titleError {
                            Text(error)
                                .font(.system(size: Constants.Typography.captionSize))
                                .foregroundColor(.red)
                        }
                    }

                    // URL Input
                    VStack(alignment: .leading, spacing: Constants.Spacing.small) {
                        Text("投票URL")
                            .font(.system(size: Constants.Typography.bodySize, weight: .semibold))
                            .foregroundColor(Constants.Colors.textWhite)

                        TextField("https://vote.example.com", text: $viewModel.url)
                            .font(.system(size: Constants.Typography.bodySize))
                            .padding()
                            .background(Constants.Colors.backgroundDark)
                            .foregroundColor(Constants.Colors.textWhite)
                            .cornerRadius(12)
                            .autocapitalization(.none)
                            .keyboardType(.URL)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Constants.Colors.accentBlue.opacity(0.3), lineWidth: 1)
                            )

                        if let error = viewModel.urlError {
                            Text(error)
                                .font(.system(size: Constants.Typography.captionSize))
                                .foregroundColor(.red)
                        }
                    }

                    // Deadline Picker
                    VStack(alignment: .leading, spacing: Constants.Spacing.small) {
                        Text("投票期限")
                            .font(.system(size: Constants.Typography.bodySize, weight: .semibold))
                            .foregroundColor(Constants.Colors.textWhite)

                        DatePicker(
                            "",
                            selection: $viewModel.deadline,
                            in: Date()...,
                            displayedComponents: [.date, .hourAndMinute]
                        )
                        .datePickerStyle(.compact)
                        .labelsHidden()
                        .tint(Constants.Colors.accentPink)
                        .padding()
                        .background(Constants.Colors.backgroundDark)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Constants.Colors.gradientPurple.opacity(0.3), lineWidth: 1)
                        )

                        if let error = viewModel.deadlineError {
                            Text(error)
                                .font(.system(size: Constants.Typography.captionSize))
                                .foregroundColor(.red)
                        }
                    }

                    // Bias IDs Input (Optional, MVP version)
                    VStack(alignment: .leading, spacing: Constants.Spacing.small) {
                        Text("対象メンバー（任意）")
                            .font(.system(size: Constants.Typography.bodySize, weight: .semibold))
                            .foregroundColor(Constants.Colors.textWhite)

                        TextField("例: blackpink, twice, bts（カンマ区切り）", text: $viewModel.biasIdsText)
                            .font(.system(size: Constants.Typography.bodySize))
                            .padding()
                            .background(Constants.Colors.backgroundDark)
                            .foregroundColor(Constants.Colors.textWhite)
                            .cornerRadius(12)
                            .autocapitalization(.none)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Constants.Colors.textGray.opacity(0.3), lineWidth: 1)
                            )

                        Text("複数のメンバーを指定する場合はカンマで区切ってください")
                            .font(.system(size: 12))
                            .foregroundColor(Constants.Colors.textGray)
                    }

                    Spacer(minLength: 20)

                    // Register Button
                    Button(action: {
                        Task {
                            await viewModel.registerTask()
                        }
                    }) {
                        HStack {
                            if viewModel.isLoading {
                                ProgressView()
                                    .tint(.white)
                                    .padding(.trailing, 8)
                            }

                            Text(viewModel.isLoading ? "登録中..." : "タスクを登録")
                                .font(.system(size: Constants.Typography.bodySize, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            viewModel.isFormValid ?
                            LinearGradient(
                                colors: [Constants.Colors.accentPink, Constants.Colors.gradientPink],
                                startPoint: .leading,
                                endPoint: .trailing
                            ) :
                            LinearGradient(
                                colors: [Constants.Colors.textGray, Constants.Colors.textGray],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(16)
                        .shadow(
                            color: viewModel.isFormValid ? Constants.Colors.accentPink.opacity(0.4) : .clear,
                            radius: 12,
                            x: 0,
                            y: 4
                        )
                    }
                    .disabled(!viewModel.isFormValid || viewModel.isLoading)
                }
                .padding()
            }
            .background(Constants.Colors.cardDark)
            .navigationTitle("VOTE登録")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("VOTE登録")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(Constants.Colors.textWhite)
                }

                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(Constants.Colors.textGray)
                    }
                }
            }
            .toolbarBackground(Constants.Colors.cardDark, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .alert("エラー", isPresented: $viewModel.showError) {
                Button("OK") {
                    viewModel.showError = false
                }
            } message: {
                Text(viewModel.errorMessage ?? "エラーが発生しました")
            }
            .alert("登録完了", isPresented: $viewModel.showSuccess) {
                Button("OK") {
                    viewModel.showSuccess = false
                    dismiss()
                }
            } message: {
                Text("タスクが正常に登録されました")
            }
        }
    }
}

// MARK: - Preview
#Preview {
    TaskRegistrationView()
}
