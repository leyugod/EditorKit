// MARK: - EditorKit/Core/Protocols.swift
// 框架核心协议层 —— 定义所有可扩展点

import SwiftUI
import Combine

// ============================================================
// MARK: 1. Document Protocol（文档协议）
// ============================================================

/// 所有文档类型必须遵循的协议
/// 应用层通过实现此协议来定义自己的文档模型
public protocol EKDocument: AnyObject, Observable {
    associatedtype PageType: EKPage

    var id: UUID { get }
    var title: String { get set }
    var pages: [PageType] { get set }
    var isDirty: Bool { get }

    func addPage() -> PageType
    func removePage(id: UUID)
    func movePage(fromOffsets: IndexSet, toOffset: Int)

    // 撤销/重做
    var undoManager: UndoManager? { get set }
}

public extension EKDocument {
    func movePage(fromOffsets: IndexSet, toOffset: Int) {
        pages.move(fromOffsets: fromOffsets, toOffset: toOffset)
    }
}

// ============================================================
// MARK: 2. Page Protocol（页面协议）
// ============================================================

/// 单个页面/幻灯片/画布的协议
public protocol EKPage: Identifiable, Observable {
    associatedtype ElementType: EKElement
    associatedtype BackgroundType: EKBackground

    var id: UUID { get }
    var elements: [ElementType] { get set }
    var background: BackgroundType { get set }
    var size: CGSize { get }

    func addElement(_ element: ElementType)
    func removeElement(id: UUID)
    func updateElement(id: UUID, transform: EKTransform)
}

// ============================================================
// MARK: 3. Element Protocol（元素协议）
// ============================================================

/// 画布上所有可放置元素的协议
public protocol EKElement: Identifiable, Observable {
    var id: UUID { get }
    var transform: EKTransform { get set }
    var isLocked: Bool { get set }
    var isVisible: Bool { get set }
    var zIndex: Int { get set }

    /// 元素类型名（用于 Inspector 路由）
    var typeName: String { get }
}

// ============================================================
// MARK: 4. Background Protocol（背景协议）
// ============================================================

public protocol EKBackground {
    var fill: EKFill { get set }
}

// ============================================================
// MARK: 5. Inspector Content Protocol（检查器内容协议）
// ============================================================

/// 每种元素对应的 Inspector 面板必须遵循此协议
public protocol EKInspectorContent: View {
    associatedtype ElementType: EKElement
    init(element: ElementType)
}

/// 无选中时的 Inspector（文档/页面级别属性）
public protocol EKPageInspectorContent: View {
    associatedtype PageType: EKPage
    init(page: PageType)
}

// ============================================================
// MARK: 6. Toolbar Item Protocol（工具栏项目协议）
// ============================================================

public protocol EKToolbarItem: Identifiable {
    var id: String { get }
    var icon: String { get }         // SF Symbol name
    var label: String { get }
    var group: EKToolbarGroup { get }
    var action: @MainActor () -> Void { get }
}

public enum EKToolbarGroup: String, CaseIterable {
    case navigation     // 左侧：导航相关
    case insert         // 中：插入对象
    case format         // 格式
    case view           // 视图控制
    case share          // 分享/导出
}

// ============================================================
// MARK: 7. Sidebar Item Protocol（侧边栏项目协议）
// ============================================================

public protocol EKSidebarItem: Identifiable {
    associatedtype ThumbnailView: View
    var id: UUID { get }
    var thumbnailView: ThumbnailView { get }
    var label: String { get }
}
