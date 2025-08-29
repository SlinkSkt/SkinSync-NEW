// Utils/IngredientCloudLayout.swift
import SwiftUI

/// Custom Layout (not from lectorial) that wraps chips across lines.
struct IngredientCloudLayout: Layout {
    var spacing: CGFloat = 8
    var rowSpacing: CGFloat = 8
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxW = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, rowH: CGFloat = 0
        for s in subviews {
            let sz = s.sizeThatFits(.unspecified)
            if x > 0, x + sz.width > maxW { x = 0; y += rowH + rowSpacing; rowH = 0 }
            rowH = max(rowH, sz.height)
            x += sz.width + (x == 0 ? 0 : spacing)
        }
        y += rowH
        return CGSize(width: maxW.isFinite ? maxW : x, height: y)
    }
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let maxW = bounds.width
        var x: CGFloat = 0, y: CGFloat = 0, rowH: CGFloat = 0
        for s in subviews {
            let sz = s.sizeThatFits(.unspecified)
            if x > 0, x + sz.width > maxW { x = 0; y += rowH + rowSpacing; rowH = 0 }
            s.place(at: CGPoint(x: bounds.minX + x, y: bounds.minY + y),
                    proposal: ProposedViewSize(width: sz.width, height: sz.height))
            rowH = max(rowH, sz.height)
            x += sz.width + (x == 0 ? 0 : spacing)
        }
    }
}

struct IngredientCloud: View {
    let ingredients: [Ingredient]
    var tint: Color = .accentColor
    var body: some View {
        IngredientCloudLayout(spacing: 8, rowSpacing: 8) {
            ForEach(ingredients) { i in
                Text(i.commonName)
                    .font(.caption)
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(tint.opacity(0.15))
                    .foregroundStyle(tint)
                    .clipShape(Capsule())
            }
        }
        .accessibilityElement(children: .contain)
    }
}
