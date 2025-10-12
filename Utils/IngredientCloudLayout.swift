// Utils/IngredientCloudLayout.swift
// Custom layout that wraps "chip" views across lines. BY online resource - Not by Class note - Zhen Xiao
// https://developer.apple.com/documentation/uikit/uiaccessibilityelement/accessibilitylabel
// https://developer.apple.com/documentation/uikit/supporting-voiceover-in-your-app
// https://developer.apple.com/documentation/swiftui/layout/sizethatfits(proposal:subviews:cache:)?changes=_6
// Accessibillity - Voiceover by make each chip has a specific accessibility label and the container exposes children.
// Uses a small cache to avoid re-measuring subviews more than necessary.

import SwiftUI

/// A lightweight flow layout for horizontally-wrapping chip items.
/// - Parameters:
///   - spacing: horizontal spacing between chips
///   - rowSpacing: vertical spacing between rows
struct IngredientCloudLayout: Layout {
    var spacing: CGFloat = 8
    var rowSpacing: CGFloat = 8

    // MARK: - Cache
    struct Cache { var sizes: [CGSize] = [] }
    func makeCache(subviews: Subviews) -> Cache {
        Cache(sizes: subviews.map { $0.sizeThatFits(.unspecified) })
    }
    func updateCache(_ cache: inout Cache, subviews: Subviews) {
        cache.sizes = subviews.map { $0.sizeThatFits(.unspecified) }
    }

    // MARK: - Layout
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Cache) -> CGSize {
        // Use the proposed width if available; otherwise assume one long row.
        let maxW = proposal.width ?? .infinity
        guard !cache.sizes.isEmpty else { return CGSize(width: maxW.isFinite ? maxW : 0, height: 0) }

        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowH: CGFloat = 0

        for sz in cache.sizes {
            // Wrap if this item would overflow the row width.
            if x > 0, x + sz.width > maxW {
                x = 0
                y += rowH + rowSpacing
                rowH = 0
            }
            rowH = max(rowH, sz.height)
            x += sz.width + (x == 0 ? 0 : spacing)
        }
        y += rowH

        // If maxW is infinite (no width constraint), return content width (x) for better previews.
        let width = maxW.isFinite ? maxW : x
        return CGSize(width: width, height: y)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Cache) {
        let maxW = bounds.width
        guard !cache.sizes.isEmpty else { return }

        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowH: CGFloat = 0

        for (index, subview) in subviews.enumerated() {
            let sz = cache.sizes[index]

            if x > 0, x + sz.width > maxW {
                x = 0
                y += rowH + rowSpacing
                rowH = 0
            }

            let origin = CGPoint(x: bounds.minX + x, y: bounds.minY + y)
            subview.place(
                at: origin,
                proposal: ProposedViewSize(width: sz.width, height: sz.height)
            )

            rowH = max(rowH, sz.height)
            x += sz.width + (x == 0 ? 0 : spacing)
        }
    }
}

/// Convenience view that renders a list of ingredients as chips using `IngredientCloudLayout`.
struct IngredientCloud: View {
    let ingredients: [Ingredient]
    var tint: Color = .accentColor

    var body: some View {
        IngredientCloudLayout(spacing: 8, rowSpacing: 8) {
            ForEach(ingredients) { i in
                Text(i.commonName)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(tint.opacity(0.15))
                    .foregroundStyle(tint)
                    .clipShape(Capsule())
                    .accessibilityLabel("Ingredient: \(i.commonName)")
            }
        }
        .accessibilityElement(children: .contain)
    }
}
