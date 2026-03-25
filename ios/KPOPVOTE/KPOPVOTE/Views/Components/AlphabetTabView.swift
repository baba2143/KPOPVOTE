//
//  AlphabetTabView.swift
//  KPOPVOTE
//
//  Common alphabet filter tab component
//

import SwiftUI

struct AlphabetTabView: View {
    let char: String
    let count: Int
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 2) {
                Text(char)
                    .font(.system(size: 14, weight: isSelected ? .bold : .regular))
                    .foregroundColor(isSelected ? .white : (count > 0 ? .blue : .gray))

                if count > 0 && !isSelected {
                    Text("\(count)")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
            }
            .frame(minWidth: 36, minHeight: 36)
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.blue : Color(UIColor.systemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.clear : (count > 0 ? Color.blue.opacity(0.3) : Color.gray.opacity(0.3)), lineWidth: 1)
            )
        }
        .disabled(count == 0 && char != "ALL")
        .opacity(count == 0 && char != "ALL" ? 0.5 : 1.0)
    }
}

// MARK: - Preview

#Preview {
    HStack {
        AlphabetTabView(char: "ALL", count: 100, isSelected: true, onTap: {})
        AlphabetTabView(char: "A", count: 5, isSelected: false, onTap: {})
        AlphabetTabView(char: "B", count: 0, isSelected: false, onTap: {})
    }
    .padding()
    .background(Color.black)
}
