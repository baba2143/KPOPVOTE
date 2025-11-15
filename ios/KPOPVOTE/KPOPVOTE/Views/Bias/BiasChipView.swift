//
//  BiasChipView.swift
//  KPOPVOTE
//
//  K-VOTE COLLECTOR - Bias Chip Component
//

import SwiftUI

struct BiasChipView: View {
    let selectedIdols: [IdolMaster]
    let onRemove: (IdolMaster) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(selectedIdols) { idol in
                    ChipView(idol: idol, onRemove: onRemove)
                }
            }
            .padding(.vertical, 4)
        }
    }
}

// MARK: - Individual Chip
private struct ChipView: View {
    let idol: IdolMaster
    let onRemove: (IdolMaster) -> Void

    var body: some View {
        HStack(spacing: 6) {
            // Idol image
            AsyncImage(url: URL(string: idol.imageUrl ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .overlay(
                        Text(idol.name.prefix(1))
                            .font(.caption2)
                            .foregroundColor(.white)
                    )
            }
            .frame(width: 24, height: 24)
            .clipShape(Circle())

            // Idol name
            Text(idol.name)
                .font(.caption)
                .foregroundColor(.primary)

            // Remove button
            Button {
                onRemove(idol)
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.blue.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Preview
struct BiasChipView_Previews: PreviewProvider {
    static var previews: some View {
        BiasChipView(
            selectedIdols: [
                IdolMaster(id: "1", name: "ハニ", groupName: "NewJeans", imageUrl: nil),
                IdolMaster(id: "2", name: "ミンジ", groupName: "NewJeans", imageUrl: nil),
                IdolMaster(id: "3", name: "ジェニー", groupName: "BLACKPINK", imageUrl: nil)
            ],
            onRemove: { _ in }
        )
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
