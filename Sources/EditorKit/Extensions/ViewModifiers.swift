// MARK: - EditorKit/Extensions/ViewModifiers.swift
// 便捷 ViewModifier 和扩展

import SwiftUI

// ============================================================
// MARK: EKElementModifier —— 便捷元素包装修饰符
// ============================================================

public extension View {
    /// 将视图包装为可交互的 EditorKit 元素
    func ekElement(
        id: UUID,
        typeName: String,
        transform: Binding<EKTransform>,
        isLocked: Bool = false
    ) -> some View {
        EKElementView(
            id: id,
            typeName: typeName,
            transform: transform,
            isLocked: isLocked
        ) {
            self
        }
    }
}

// ============================================================
// MARK: EKFill View Extension
// ============================================================

public extension View {
    /// 应用 EKFill 作为背景
    func ekBackground(_ fill: EKFill) -> some View {
        self.background(EKFillView(fill: fill))
    }
}

// ============================================================
// MARK: EKInspectorSection 快捷构建
// ============================================================

public extension View {
    /// 快速包装为 Inspector Section
    func ekInspectorSection(_ title: String) -> some View {
        EKInspectorSection(title) { self }
    }
}

// ============================================================
// MARK: EditorStore Environment Convenience
// ============================================================

public extension View {
    /// 将 EditorStore 注入环境
    func ekEditorEnvironment(_ store: EditorStore) -> some View {
        self.environment(\.editorStore, store)
    }
}

// ============================================================
// MARK: CGPoint / CGSize Operators
// ============================================================

public extension CGPoint {
    static func + (lhs: CGPoint, rhs: CGSize) -> CGPoint {
        CGPoint(x: lhs.x + rhs.width, y: lhs.y + rhs.height)
    }

    static func - (lhs: CGPoint, rhs: CGPoint) -> CGSize {
        CGSize(width: lhs.x - rhs.x, height: lhs.y - rhs.y)
    }
}

// ============================================================
// MARK: EKSnappingHelper —— 对齐辅助（磁吸）
// ============================================================

public struct EKSnappingHelper {
    public let threshold: CGFloat

    public init(threshold: CGFloat = 5) {
        self.threshold = threshold
    }

    /// 检查是否应该磁吸到参考点
    public func snap(_ value: CGFloat, to reference: CGFloat) -> (snapped: CGFloat, didSnap: Bool) {
        let diff = abs(value - reference)
        if diff < threshold {
            return (reference, true)
        }
        return (value, false)
    }

    /// 将位置磁吸到多个参考点
    public func snap(_ point: CGPoint, toX references: [CGFloat], toY yReferences: [CGFloat]) -> CGPoint {
        var result = point
        for refX in references {
            let (snapped, didSnap) = snap(point.x, to: refX)
            if didSnap { result.x = snapped; break }
        }
        for refY in yReferences {
            let (snapped, didSnap) = snap(point.y, to: refY)
            if didSnap { result.y = snapped; break }
        }
        return result
    }
}

// ============================================================
// MARK: EKAlignmentHelper —— 元素对齐计算
// ============================================================

public enum EKAlignment {
    case left, centerH, right
    case top, centerV, bottom
}

public struct EKAlignmentHelper {
    public static func align(
        transforms: [EKTransform],
        alignment: EKAlignment,
        in canvasSize: CGSize
    ) -> [EKTransform] {
        guard !transforms.isEmpty else { return transforms }

        return transforms.map { t in
            var updated = t
            switch alignment {
            case .left:    updated.position.x = t.size.width / 2
            case .right:   updated.position.x = canvasSize.width - t.size.width / 2
            case .centerH: updated.position.x = canvasSize.width / 2
            case .top:     updated.position.y = t.size.height / 2
            case .bottom:  updated.position.y = canvasSize.height - t.size.height / 2
            case .centerV: updated.position.y = canvasSize.height / 2
            }
            return updated
        }
    }
}
