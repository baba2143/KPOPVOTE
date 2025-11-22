//
//  CreateMenuView.swift
//  KPOPVOTE
//
//  K-VOTE COLLECTOR - Custom Glassmorphism Create Menu
//

import SwiftUI

struct CreateMenuView: View {
    @Environment(\.dismiss) var dismiss
    let onTaskCreate: () -> Void
    let onCollectionCreate: () -> Void
    let onPostCreate: () -> Void

    var body: some View {
        ZStack {
            // Background overlay
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture {
                    dismiss()
                }

            VStack(spacing: 0) {
                Spacer()

                // Glassmorphism container
                VStack(spacing: 20) {
                    // Header
                    Text("新規作成")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.top, 24)

                    // Menu options
                    VStack(spacing: 12) {
                        CreateMenuButton(
                            icon: "square.and.pencil",
                            title: "投票タスクを登録",
                            gradientColors: [
                                Constants.Colors.accentPink,
                                Constants.Colors.gradientPurple
                            ]
                        ) {
                            dismiss()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                onTaskCreate()
                            }
                        }

                        CreateMenuButton(
                            icon: "square.stack.3d.up",
                            title: "コレクションを作成",
                            gradientColors: [
                                Constants.Colors.gradientPurple,
                                Constants.Colors.accentBlue
                            ]
                        ) {
                            dismiss()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                onCollectionCreate()
                            }
                        }

                        CreateMenuButton(
                            icon: "bubble.left.and.bubble.right",
                            title: "コミュニティ投稿",
                            gradientColors: [
                                Constants.Colors.accentBlue,
                                Constants.Colors.accentPink
                            ]
                        ) {
                            dismiss()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                onPostCreate()
                            }
                        }
                    }
                    .padding(.horizontal, 20)

                    // Cancel button
                    Button(action: {
                        dismiss()
                    }) {
                        Text("キャンセル")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white.opacity(0.7))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                    }
                    .padding(.top, 8)
                    .padding(.bottom, 24)
                }
                .background(
                    // Glassmorphism effect
                    ZStack {
                        // Blur background
                        Color(hex: "1a2744")
                            .opacity(0.8)

                        // Gradient border overlay
                        RoundedRectangle(cornerRadius: 24)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [
                                        Constants.Colors.accentPink.opacity(0.5),
                                        Constants.Colors.accentBlue.opacity(0.5)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    }
                )
                .cornerRadius(24)
                .padding(.horizontal, 16)
                .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
            }
        }
        .background(.ultraThinMaterial)
    }
}

// MARK: - Create Menu Button Component
struct CreateMenuButton: View {
    let icon: String
    let title: String
    let gradientColors: [Color]
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Icon with gradient background
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: gradientColors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 48, height: 48)

                    Image(systemName: icon)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(.white)
                }

                // Title
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)

                Spacer()

                // Arrow indicator
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.5))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(
                        LinearGradient(
                            colors: gradientColors.map { $0.opacity(0.3) },
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
        }
    }
}

// MARK: - Preview
#Preview {
    CreateMenuView(
        onTaskCreate: {},
        onCollectionCreate: {},
        onPostCreate: {}
    )
}
