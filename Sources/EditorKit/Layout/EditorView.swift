// MARK: - EditorKit/Layout/EditorView.swift
// 编辑器主布局视图 —— 三栏结构 + 工具栏

import SwiftUI

// ============================================================
// MARK: EditorView —— 框架入口视图（泛型化，适配任意文档）
// ============================================================

/// 使用示例：
/// ```swift
/// EditorView(
///     store: myStore,
///     sidebar: { MySidebarView() },
///     canvas: { MyCanvasView() },
///     inspector: { MyInspectorView() },
///     toolbar: { MyToolbarItems() }
/// )
/// ```
public struct EditorView<
    Sidebar: View,
    Canvas: View,
    Inspector: View,
    Toolbar: View
>: View {

    @State private var store: EditorStore
    private let sidebar: () -> Sidebar
    private let canvas: () -> Canvas
    private let inspector: () -> Inspector
    private let toolbar: () -> Toolbar

    public init(
        store: EditorStore,
        @ViewBuilder sidebar: @escaping () -> Sidebar,
        @ViewBuilder canvas: @escaping () -> Canvas,
        @ViewBuilder inspector: @escaping () -> Inspector,
        @ViewBuilder toolbar: @escaping () -> Toolbar
    ) {
        self._store = State(initialValue: store)
        self.sidebar = sidebar
        self.canvas = canvas
        self.inspector = inspector
        self.toolbar = toolbar
    }

    public var body: some View {
        VStack(spacing: 0) {
            // ── 工具栏 ──
            EKToolbarContainer(content: toolbar)
                .frame(height: store.config.toolbarHeight)

            Divider()

            // ── 三栏主体 ──
            HStack(spacing: 0) {

                // 左：侧边栏
                if store.isSidebarVisible {
                    EKSidebarContainer(content: sidebar)
                        .frame(
                            minWidth: store.config.sidebarMinWidth,
                            maxWidth: store.config.sidebarMaxWidth
                        )
                        .transition(.move(edge: .leading).combined(with: .opacity))

                    Divider()
                }

                // 中：画布（弹性填充）
                EKCanvasContainer(content: canvas)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                // 右：检查器
                if store.isInspectorVisible {
                    Divider()

                    EKInspectorContainer(content: inspector)
                        .frame(width: store.config.inspectorWidth)
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                }
            }
        }
        .environment(\.editorStore, store)
        // 键盘快捷键
        .onKeyPress(.escape) {
            store.clearSelection()
            return .handled
        }
        #if os(macOS)
        .frame(minWidth: 900, minHeight: 600)
        #endif
    }
}

// ============================================================
// MARK: EKToolbarContainer
// ============================================================

struct EKToolbarContainer<Content: View>: View {
    let content: () -> Content

    var body: some View {
        HStack(spacing: 0) {
            content()
        }
        .padding(.horizontal, 12)
        #if os(macOS)
        .background(.bar)
        #else
        .background(.regularMaterial)
        #endif
    }
}

// ============================================================
// MARK: EKSidebarContainer
// ============================================================

struct EKSidebarContainer<Content: View>: View {
    let content: () -> Content

    var body: some View {
        content()
        #if os(macOS)
            .background(Color(NSColor.controlBackgroundColor))
        #else
            .background(Color(UIColor.secondarySystemBackground))
        #endif
    }
}

// ============================================================
// MARK: EKCanvasContainer
// ============================================================

struct EKCanvasContainer<Content: View>: View {
    @Environment(\.editorStore) private var store

    let content: () -> Content

    var body: some View {
        ZStack {
            // 画布背景色
            (store?.config.canvasBackgroundColor ?? Color(white: 0.92))
                .ignoresSafeArea()

            // 网格（可选）
            if store?.config.enableGrid == true {
                EKGridOverlay(spacing: store?.config.gridSpacing ?? 20)
                    .opacity(0.3)
            }

            // 内容
            content()
        }
        .clipped()
        // 点击画布空白区域取消选中
        .onTapGesture {
            store?.clearSelection()
        }
    }
}

// ============================================================
// MARK: EKInspectorContainer
// ============================================================

struct EKInspectorContainer<Content: View>: View {
    let content: () -> Content

    var body: some View {
        ScrollView {
            content()
                .padding(.vertical, 8)
        }
        #if os(macOS)
        .background(Color(NSColor.controlBackgroundColor))
        #else
        .background(Color(UIColor.secondarySystemBackground))
        #endif
    }
}

// ============================================================
// MARK: EKGridOverlay —— 网格叠加层
// ============================================================

struct EKGridOverlay: View {
    let spacing: CGFloat

    var body: some View {
        Canvas { context, size in
            var path = Path()
            // 垂直线
            var x: CGFloat = 0
            while x < size.width {
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: size.height))
                x += spacing
            }
            // 水平线
            var y: CGFloat = 0
            while y < size.height {
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
                y += spacing
            }
            context.stroke(path, with: .color(.gray.opacity(0.5)), lineWidth: 0.5)
        }
        .allowsHitTesting(false)
    }
}
