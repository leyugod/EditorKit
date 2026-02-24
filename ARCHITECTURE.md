# EditorKit — 架构设计文档

> Swift 6 + SwiftUI + MVVM 通用编辑器框架
> 版本：1.0 | 平台：macOS 15+ / iOS 18+

---

## 目录

1. [框架概览](#1-框架概览)
2. [目录结构](#2-目录结构)
3. [核心架构分层](#3-核心架构分层)
4. [关键设计模式](#4-关键设计模式)
5. [数据流图](#5-数据流图)
6. [扩展指南](#6-扩展指南)
7. [开发新应用的 Checklist](#7-开发新应用的-checklist)

---

## 1. 框架概览

```
┌─────────────────────────────────────────────────────────────────┐
│                        Your App Layer                           │
│   (文档模型 / 元素视图 / Inspector / 工具栏按钮 / 业务逻辑)         │
├─────────────────────────────────────────────────────────────────┤
│                         EditorKit                               │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────────┐   │
│  │  Layout  │  │  Canvas  │  │Inspector │  │   Toolbar    │   │
│  │三栏布局框架│  │画布/选中  │  │注册表路由 │  │ 分组工具栏   │   │
│  └──────────┘  └──────────┘  └──────────┘  └──────────────┘   │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │            Core（协议 / 值类型 / EditorStore）             │   │
│  └──────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

### 设计原则

| 原则 | 实现方式 |
|------|---------|
| **协议优先** | 所有扩展点通过 Protocol 定义，零侵入 |
| **类型擦除** | AnyView + 泛型边界，处理元素多态 |
| **单向数据流** | Store → View，Action → Store |
| **Swift 6 并发安全** | `@MainActor` 隔离，`Sendable` 值类型 |
| **零魔法** | 无反射，无 runtime hook，纯 SwiftUI |

---

## 2. 目录结构

```
EditorKit/
├── Package.swift
└── Sources/
    └── EditorKit/
        ├── EditorKit.swift              # 模块入口
        ├── Core/
        │   ├── Protocols.swift          # 所有核心协议
        │   ├── ValueTypes.swift         # 值类型（Transform/Fill/Color）
        │   └── EditorViewModel.swift    # EditorStore + SelectionManager
        ├── Layout/
        │   ├── EditorView.swift         # 三栏主布局
        │   └── SidebarView.swift        # 缩略图侧边栏
        ├── Canvas/
        │   └── CanvasView.swift         # 画布 + 元素容器 + 选中句柄
        ├── Inspector/
        │   └── InspectorView.swift      # Inspector 注册表 + 通用组件
        ├── Toolbar/
        │   └── ToolbarView.swift        # 工具栏组件库
        ├── Document/
        │   └── BaseDocument.swift       # 基础文档 + Bridge
        └── Extensions/
            └── ViewModifiers.swift      # 便捷修饰符 + 工具类
```

---

## 3. 核心架构分层

### Layer 1 —— Core（核心层）

**EditorStore**（中央状态仓库）是整个编辑器的核心，通过 SwiftUI `Environment` 传递：

```swift
@MainActor @Observable
final class EditorStore {
    var selection: EKSelectionContext    // 选中状态 → 驱动 Inspector
    var zoomScale: CGFloat               // 缩放 → 驱动 Canvas
    var editMode: EKEditMode             // 操作模式 → 驱动工具栏高亮
    var isSidebarVisible: Bool           // 面板可见性
    var isInspectorVisible: Bool
    // ...
}
```

**EKSelectionContext** 是整个系统的枢纽：

```
EKSelectionContext
    ├── .none              → Inspector 显示页面属性
    ├── .element(id, type) → Inspector 通过 Registry 查找并显示对应面板
    └── .multiElement([id])→ Inspector 显示多选通用操作
```

### Layer 2 —— Protocol（协议层）

```
EKDocument ──→ EKPage ──→ EKElement
    │              │           │
  文档级          页面级       元素级
（标题/页面列表）（背景/元素列表）（位置/锁定/可见性）
```

应用层通过实现这些协议接入框架，**框架本身不关心具体类型**。

### Layer 3 —— UI（视图层）

视图层完全由 `EditorStore` 驱动，分为四个独立区域：

```
EditorView（主布局）
├── EKToolbarContainer     → 渲染应用提供的 Toolbar 内容
├── EKSidebarContainer     → 渲染应用提供的 Sidebar 内容
├── EKCanvasContainer      → 渲染应用提供的 Canvas 内容
└── EKInspectorContainer   → 渲染 EKContextInspector（自动路由）
```

---

## 4. 关键设计模式

### 4.1 Inspector 注册表模式

**问题**：Inspector 面板需要根据选中的元素类型动态切换，但框架不知道应用的元素类型。

**解决**：注册表（Registry）+ 类型名路由

```swift
// 应用启动时注册
EKInspectorRegistry.shared.register(typeName: "TextElement") { id in
    AnyView(TextElementInspector(elementID: id))
}

// 框架运行时路由（无需知道具体类型）
let view = registry.inspector(for: selection.typeName, id: selection.id)
```

### 4.2 泛型三栏布局

**问题**：主布局需要接收应用自定义的 Sidebar / Canvas / Inspector，同时保持框架内部逻辑。

**解决**：关联类型 + ViewBuilder 泛型约束

```swift
public struct EditorView<Sidebar: View, Canvas: View, Inspector: View, Toolbar: View>: View {
    // 框架提供布局骨架，内容由应用注入
}
```

### 4.3 EKElementView 通用容器

**问题**：每种元素都需要选中高亮、拖拽移动、缩放句柄，但内容不同。

**解决**：容器 + 内容分离

```swift
// 框架提供交互能力
EKElementView(id: el.id, typeName: "TextElement", transform: $el.transform) {
    // 应用提供渲染内容
    Text(el.text)
}
```

### 4.4 文档桥接（Bridge）

**问题**：`EKBaseDocument` 的 UndoManager 需要与 `EditorStore` 的状态同步。

**解决**：Bridge 对象封装双向绑定

```swift
let bridge = EKDocumentBridge(document: myDocument, store: store)
// Bridge 自动处理 undo/redo 回调和状态同步
```

---

## 5. 数据流图

```
User Action（用户操作）
        │
        ▼
  EditorStore.action()      ← @MainActor，线程安全
        │
        ├── 修改 selection ──→ EKContextInspector 重新渲染
        │
        ├── 修改 zoomScale ──→ EKPageCanvasView 重新缩放
        │
        ├── 修改 editMode ──→ EKEditModeSelector 高亮更新
        │
        └── 触发 onUndo ──→ UndoManager → 文档数据回滚 → 视图刷新
```

---

## 6. 扩展指南

### 开发新应用只需 5 步：

#### Step 1：定义元素模型

```swift
@Observable
final class MyElement: EKElement {
    let id = UUID()
    var transform = EKTransform()
    var isLocked = false
    var isVisible = true
    var zIndex = 0
    var typeName: String { "MyElement" }

    // 你的业务字段
    var content: String = ""
}
```

#### Step 2：定义文档模型

```swift
@Observable
final class MyDocument: EKBaseDocument {
    var pages: [MyPage] = [MyPage()]
}
```

#### Step 3：注册 Inspector

```swift
EKInspectorRegistry.shared.register(typeName: "MyElement") { id in
    AnyView(MyElementInspector(id: id))
}
```

#### Step 4：实现元素渲染视图

```swift
struct MyElementView: View {
    let element: MyElement
    var body: some View {
        Text(element.content)
            .ekElement(id: element.id, typeName: element.typeName,
                       transform: element.$transform)
    }
}
```

#### Step 5：组装 EditorView

```swift
EditorView(store: store) {
    EKThumbnailSidebar(...) { index in MyThumbnail(page: pages[index]) }
} canvas: {
    EKPageCanvasView(pageSize: .init(width: 1920, height: 1080)) {
        ForEach(currentPage.elements) { MyElementView(element: $0) }
    }
} inspector: {
    EKContextInspector { MyPageInspector() }
} toolbar: {
    EKEditorToolbar { /* 左 */ } center: { /* 中 */ } trailing: { /* 右 */ }
}
```

---

## 7. 开发新应用的 Checklist

- [ ] 定义 `XxxElement: EKElement`（业务元素）
- [ ] 定义 `XxxPage: EKPage`（页面模型）
- [ ] 定义 `XxxDocument: EKBaseDocument`（文档模型）
- [ ] 为每种元素实现 `XxxElementInspector: View`
- [ ] 在 App 启动时调用 `EKInspectorRegistry.shared.register`
- [ ] 实现 `XxxElementView`（调用 `.ekElement` 修饰符）
- [ ] 实现缩略图视图（用于侧边栏）
- [ ] 实现页面级 Inspector（无选中时显示）
- [ ] 创建 `EditorStore`，传入 `EKEditorConfig`
- [ ] 用 `EKDocumentBridge` 连接文档与 Store
- [ ] 组装 `EditorView`

---

## 附录：Swift 6 并发安全说明

| 类型 | 隔离方式 | 原因 |
|------|---------|------|
| `EditorStore` | `@MainActor` | 直接驱动 UI |
| `EKBaseDocument` | `@MainActor` | 包含 UndoManager |
| `EKInspectorRegistry` | `@MainActor` | 注册表修改须在主线程 |
| `EKTransform` | `Sendable` struct | 跨线程传递安全 |
| `EKColor/EKFill` | `Sendable` enum/struct | 值语义 |
| 视图层 | SwiftUI 自动 `@MainActor` | 框架保证 |
