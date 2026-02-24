// MARK: - EditorKit/Document/BaseDocument.swift
// 文档基础层 —— 可观察文档 + Undo/Redo 支持

import SwiftUI

// ============================================================
// MARK: EKBaseDocument —— 可直接继承的基础文档类
// ============================================================

/// 应用层可直接继承此类，获得：
/// - Observable 支持
/// - UndoManager 集成
/// - 脏标记管理
/// - 序列化钩子
@MainActor
@Observable
open class EKBaseDocument {

    // ── 基本信息 ──
    public var id: UUID = UUID()
    public var title: String = EKStrings.untitled {
        didSet { markDirty() }
    }

    // ── 状态 ──
    public private(set) var isDirty: Bool = false
    public var undoManager: UndoManager? = UndoManager()

    // ── 初始化 ──
    public init(title: String = EKStrings.untitled) {
        self.title = title
    }

    // MARK: - Dirty 标记

    public func markDirty() {
        isDirty = true
    }

    public func markClean() {
        isDirty = false
    }

    // MARK: - Undo/Redo 工具方法

    /// 执行可撤销操作
    /// - Parameters:
    ///   - name: 操作名称（显示在撤销菜单中）
    ///   - action: 正向操作（立即执行）
    ///   - undoAction: 撤销操作
    public func performUndoable(
        name: String,
        action: @escaping @MainActor () -> Void,
        undoAction: @escaping @MainActor () -> Void
    ) {
        action()
        markDirty()

        undoManager?.beginUndoGrouping()
        undoManager?.registerUndo(withTarget: self) { [weak self] _ in
            Task { @MainActor in
                undoAction()
                self?.markDirty()
            }
        }
        undoManager?.setActionName(name)
        undoManager?.endUndoGrouping()
    }

    // MARK: - Serialization Hooks (override in subclass)

    /// Encode document data for persistence. Override in subclass.
    /// Default implementation returns empty Data.
    open func encode() throws -> Data { Data() }

    /// Decode document data from persistence. Override in subclass.
    /// Default implementation is a no-op.
    open func decode(from data: Data) throws {}
}

// ============================================================
// MARK: EKDocumentBridge —— 连接文档与 EditorStore
// ============================================================

/// 将具体文档绑定到 EditorStore
@MainActor
public final class EKDocumentBridge<Doc: EKBaseDocument> {
    let document: Doc
    let store: EditorStore

    public init(document: Doc, store: EditorStore) {
        self.document = document
        self.store = store
        setupBridge()
    }

    private func setupBridge() {
        // 文档标题同步
        store.documentTitle = document.title

        // Undo/Redo 回调
        store.onUndoRequested = { [weak self] in
            self?.document.undoManager?.undo()
            self?.syncUndoState()
        }
        store.onRedoRequested = { [weak self] in
            self?.document.undoManager?.redo()
            self?.syncUndoState()
        }

        syncUndoState()
    }

    private func syncUndoState() {
        store.canUndo = document.undoManager?.canUndo ?? false
        store.canRedo = document.undoManager?.canRedo ?? false
    }
}
