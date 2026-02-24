// MARK: - EditorKit/Core/EditorViewModel.swift
// 编辑器核心 ViewModel —— 全局状态管理中枢

import SwiftUI
import Combine

// ============================================================
// MARK: EditorEnvironment —— 通过环境传递核心 ViewModel
// ============================================================

public struct EditorEnvironmentKey: EnvironmentKey {
    public static let defaultValue: EditorStore? = nil
}

public extension EnvironmentValues {
    var editorStore: EditorStore? {
        get { self[EditorEnvironmentKey.self] }
        set { self[EditorEnvironmentKey.self] = newValue }
    }
}

// ============================================================
// MARK: EditorStore —— 核心状态仓库（与文档类型无关）
// ============================================================

@MainActor
@Observable
public final class EditorStore {

    // ------ 文档元数据 ------
    public var documentTitle: String = EKStrings.untitled
    public var isDirty: Bool = false

    // ------ 页面管理 ------
    public var pageCount: Int = 0
    public var currentPageIndex: Int = 0 {
        didSet { onPageChanged?(currentPageIndex) }
    }

    // ------ 选中状态 ------
    public var selection: EKSelectionContext = .none {
        didSet { onSelectionChanged?(selection) }
    }

    /// Fine-grained selection tracking (hover, additive selection).
    public let selectionManager = SelectionManager()

    // ------ 画布状态 ------
    public var zoomScale: CGFloat = 1.0
    public var canvasOffset: CGSize = .zero
    public var isCanvasFocused: Bool = false

    // ------ 面板可见性 ------
    public var isSidebarVisible: Bool = true
    public var isInspectorVisible: Bool = true
    public var isRulerVisible: Bool = false

    // ------ 编辑模式 ------
    public var editMode: EKEditMode = .select

    // ------ 配置 ------
    public var config: EKEditorConfig = .init()

    // ------ 回调（用于连接具体文档层）------
    public var onPageChanged: ((Int) -> Void)?
    public var onSelectionChanged: ((EKSelectionContext) -> Void)?
    public var onUndoRequested: (() -> Void)?
    public var onRedoRequested: (() -> Void)?

    // ------ Undo/Redo 状态 ------
    public var canUndo: Bool = false
    public var canRedo: Bool = false

    public init(config: EKEditorConfig = .init()) {
        self.config = config
    }

    // MARK: - Actions

    public func selectElement(id: UUID, type: String) {
        withAnimation(.easeInOut(duration: 0.15)) {
            selection = .element(id: id, type: type)
        }
    }

    public func clearSelection() {
        withAnimation(.easeInOut(duration: 0.15)) {
            selection = .none
        }
    }

    public func addToSelection(id: UUID) {
        switch selection {
        case .none:
            break
        case .element(let existingId, _):
            selection = .multiElement([existingId, id])
        case .multiElement(var ids):
            if !ids.contains(id) { ids.append(id) }
            selection = .multiElement(ids)
        }
    }

    public func setZoom(_ scale: CGFloat) {
        zoomScale = min(max(scale, config.minZoom), config.maxZoom)
    }

    public func zoomIn() { setZoom(zoomScale * 1.25) }
    public func zoomOut() { setZoom(zoomScale / 1.25) }
    public func zoomToFit() { setZoom(config.defaultZoom) }

    public func toggleSidebar() {
        withAnimation(.easeInOut(duration: 0.2)) {
            isSidebarVisible.toggle()
        }
    }

    public func toggleInspector() {
        withAnimation(.easeInOut(duration: 0.2)) {
            isInspectorVisible.toggle()
        }
    }

    public func requestUndo() { onUndoRequested?() }
    public func requestRedo() { onRedoRequested?() }
}

// ============================================================
// MARK: EKEditMode —— 编辑器当前操作模式
// ============================================================

public enum EKEditMode: String, CaseIterable, Sendable {
    case select     // 选择/移动
    case text       // 文本插入
    case shape      // 形状绘制
    case pen        // 手绘
    case hand       // 平移画布

    public var icon: String {
        switch self {
        case .select: "arrow.up.left.and.arrow.down.right"
        case .text:   "character.cursor.ibeam"
        case .shape:  "square.on.circle"
        case .pen:    "pencil"
        case .hand:   "hand.raised"
        }
    }
}

// ============================================================
// MARK: SelectionManager —— 元素选中框架层管理
// ============================================================

@MainActor
@Observable
public final class SelectionManager {
    public var selectedIDs: Set<UUID> = []
    public var hoveredID: UUID? = nil

    public func select(_ id: UUID, additive: Bool = false) {
        if additive {
            selectedIDs.insert(id)
        } else {
            selectedIDs = [id]
        }
    }

    public func deselect(_ id: UUID) {
        selectedIDs.remove(id)
    }

    public func clearAll() {
        selectedIDs.removeAll()
        hoveredID = nil
    }

    public func isSelected(_ id: UUID) -> Bool {
        selectedIDs.contains(id)
    }

    public var isSingleSelection: Bool {
        selectedIDs.count == 1
    }

    public var singleSelectedID: UUID? {
        selectedIDs.count == 1 ? selectedIDs.first : nil
    }
}
