// MARK: - EditorKit/Core/ValueTypes.swift
// 框架核心值类型

import SwiftUI

// ============================================================
// MARK: EKTransform —— 元素变换信息
// ============================================================

public struct EKTransform: Sendable, Equatable, Hashable, Codable {
    public var position: CGPoint
    public var size: CGSize
    public var rotation: Double   // 角度，单位 degrees
    public var opacity: Double    // 0.0 ~ 1.0

    public init(
        position: CGPoint = .zero,
        size: CGSize = CGSize(width: 200, height: 100),
        rotation: Double = 0,
        opacity: Double = 1
    ) {
        self.position = position
        self.size = size
        self.rotation = rotation
        self.opacity = opacity
    }

    public static let `default` = EKTransform()
}

// ============================================================
// MARK: EKFill —— 填充类型
// ============================================================

public enum EKFill: Sendable, Equatable, Hashable, Codable {
    case none
    case color(EKColor)
    case gradient(EKGradient)
    case image(String)  // asset name or URL string
}

public struct EKColor: Sendable, Equatable, Hashable, Codable {
    public var red: Double
    public var green: Double
    public var blue: Double
    public var alpha: Double

    public init(red: Double, green: Double, blue: Double, alpha: Double = 1) {
        self.red = red; self.green = green
        self.blue = blue; self.alpha = alpha
    }

    public var color: Color {
        Color(red: red, green: green, blue: blue, opacity: alpha)
    }

    /// Initialize from a SwiftUI `Color` (cross-platform).
    /// Uses `Color.resolve(in:)` available on macOS 14+ / iOS 17+.
    @MainActor
    public init(swiftUIColor: Color) {
        let resolved = swiftUIColor.resolve(in: EnvironmentValues())
        self.init(
            red: Double(resolved.red),
            green: Double(resolved.green),
            blue: Double(resolved.blue),
            alpha: Double(resolved.opacity)
        )
    }

    public static let white = EKColor(red: 1, green: 1, blue: 1)
    public static let black = EKColor(red: 0, green: 0, blue: 0)
    public static let clear = EKColor(red: 0, green: 0, blue: 0, alpha: 0)
}

public struct EKGradient: Sendable, Equatable, Hashable, Codable {
    public var stops: [GradientStop]
    public var startPoint: EKUnitPoint
    public var endPoint: EKUnitPoint

    public struct GradientStop: Sendable, Equatable, Hashable, Codable {
        public var color: EKColor
        public var location: Double

        public init(color: EKColor, location: Double) {
            self.color = color; self.location = location
        }
    }

    public init(stops: [GradientStop], startPoint: EKUnitPoint = .top, endPoint: EKUnitPoint = .bottom) {
        self.stops = stops
        self.startPoint = startPoint
        self.endPoint = endPoint
    }
}

// ============================================================
// MARK: EKSelectionContext —— 选中上下文（驱动 Inspector 切换）
// ============================================================

public enum EKSelectionContext: Equatable, Sendable {
    case none
    case element(id: UUID, type: String)
    case multiElement([UUID])
}

// ============================================================
// MARK: EKEditorConfig —— 编辑器全局配置
// ============================================================

/// Global configuration for the EditorKit editor.
///
/// Pass a customized instance to ``EditorStore/init(config:)`` to
/// control layout dimensions, canvas behavior, and feature flags.
public struct EKEditorConfig: Sendable {

    // MARK: Layout

    /// Minimum width of the sidebar panel.
    public var sidebarMinWidth: CGFloat = 160
    /// Maximum width of the sidebar panel.
    public var sidebarMaxWidth: CGFloat = 260
    /// Fixed width of the inspector panel.
    public var inspectorWidth: CGFloat = 280
    /// Height of the toolbar area.
    public var toolbarHeight: CGFloat = 52

    // MARK: Canvas

    /// Background color of the canvas area surrounding the page.
    public var canvasBackgroundColor: Color = Color(white: 0.92)
    /// Padding around the page inside the canvas scroll view.
    public var canvasPadding: CGFloat = 40
    /// Default zoom level (1.0 = 100%).
    public var defaultZoom: CGFloat = 1.0
    /// Minimum allowed zoom level.
    public var minZoom: CGFloat = 0.1
    /// Maximum allowed zoom level.
    public var maxZoom: CGFloat = 4.0

    // MARK: Feature Flags

    /// Show page numbers in sidebar thumbnails.
    public var showPageNumbers: Bool = true
    /// Enable ruler overlays (when implemented).
    public var enableRulers: Bool = true
    /// Show a grid overlay on the canvas.
    public var enableGrid: Bool = false
    /// Spacing between grid lines in points.
    public var gridSpacing: CGFloat = 20

    public init() {}
}

// ============================================================
// MARK: EKUnitPoint — Codable wrapper for UnitPoint
// ============================================================

/// A `Codable` / `Sendable` wrapper around `UnitPoint` to avoid
/// retroactive conformance on the framework type.
public struct EKUnitPoint: Sendable, Equatable, Hashable, Codable {
    public var x: Double
    public var y: Double

    public init(x: Double = 0.5, y: Double = 0.5) {
        self.x = x; self.y = y
    }

    public init(_ unitPoint: UnitPoint) {
        self.x = unitPoint.x; self.y = unitPoint.y
    }

    public var unitPoint: UnitPoint { UnitPoint(x: x, y: y) }

    public static let top = EKUnitPoint(.top)
    public static let bottom = EKUnitPoint(.bottom)
    public static let leading = EKUnitPoint(.leading)
    public static let trailing = EKUnitPoint(.trailing)
    public static let center = EKUnitPoint(.center)
    public static let topLeading = EKUnitPoint(.topLeading)
    public static let topTrailing = EKUnitPoint(.topTrailing)
    public static let bottomLeading = EKUnitPoint(.bottomLeading)
    public static let bottomTrailing = EKUnitPoint(.bottomTrailing)
}
