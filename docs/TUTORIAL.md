# EditorKit 使用教程 / Usage Tutorial

> 本教程将引导你从零开始，使用 EditorKit 构建一个完整的可视化编辑器应用。
>
> This tutorial walks you through building a visual editor from scratch with EditorKit.

---

## 目录 / Table of Contents

1. [概念总览 / Concepts Overview](#1-概念总览--concepts-overview)
2. [安装与项目配置 / Installation](#2-安装与项目配置--installation)
3. [Step 1：定义数据模型 / Define Data Models](#3-step-1定义数据模型--define-data-models)
4. [Step 2：创建元素渲染视图 / Create Element Views](#4-step-2创建元素渲染视图--create-element-views)
5. [Step 3：构建 Inspector 面板 / Build Inspector Panels](#5-step-3构建-inspector-面板--build-inspector-panels)
6. [Step 4：组装编辑器 / Assemble the Editor](#6-step-4组装编辑器--assemble-the-editor)
7. [Step 5：连接文档与 Undo/Redo / Wire Up Document & Undo](#7-step-5连接文档与-undoredo--wire-up-document--undo)
8. [深入：EditorStore 状态管理 / Deep Dive: EditorStore](#8-深入editorstore-状态管理--deep-dive-editorstore)
9. [深入：Inspector 注册表 / Deep Dive: Inspector Registry](#9-深入inspector-注册表--deep-dive-inspector-registry)
10. [深入：画布与交互 / Deep Dive: Canvas & Interactions](#10-深入画布与交互--deep-dive-canvas--interactions)
11. [深入：工具栏组件 / Deep Dive: Toolbar Components](#11-深入工具栏组件--deep-dive-toolbar-components)
12. [深入：侧边栏 / Deep Dive: Sidebar](#12-深入侧边栏--deep-dive-sidebar)
13. [自定义配置 / Customizing Configuration](#13-自定义配置--customizing-configuration)
14. [工具类 API / Utility APIs](#14-工具类-api--utility-apis)
15. [本地化 / Localization](#15-本地化--localization)
16. [完整示例：白板应用 / Full Example: Whiteboard App](#16-完整示例白板应用--full-example-whiteboard-app)
17. [最佳实践 / Best Practices](#17-最佳实践--best-practices)
18. [常见问题 / FAQ](#18-常见问题--faq)

---

## 1. 概念总览 / Concepts Overview

EditorKit 是一个 **面向协议** 的编辑器框架。你的应用只需要实现几个协议、注册 Inspector，然后将部件组装在一起。

```
┌────────────────────────────────────────────────────┐
│                    你的应用层                        │
│  ┌──────────┐  ┌──────────┐  ┌──────────────────┐ │
│  │ 数据模型  │  │ 元素视图  │  │ Inspector 面板   │ │
│  └──────────┘  └──────────┘  └──────────────────┘ │
├────────────────────────────────────────────────────┤
│                   EditorKit                         │
│  EditorView → Sidebar + Canvas + Inspector + Toolbar│
│  EditorStore → 全局状态（选中/缩放/模式/面板）        │
│  Protocols  → EKElement / EKPage / EKDocument       │
└────────────────────────────────────────────────────┘
```

### 核心协议 / Core Protocols

| 协议 | 职责 | 你需要实现的 |
|------|------|-------------|
| `EKElement` | 画布上的单个元素 | `id`, `transform`, `isLocked`, `isVisible`, `zIndex`, `typeName` + 你的业务字段 |
| `EKPage` | 一个页面/画布 | `id`, `elements`, `background`, `size`, `addElement`, `removeElement`, `updateElement` |
| `EKDocument` | 整个文档 | `id`, `title`, `pages`, `isDirty`, `addPage`, `removePage`, `undoManager` |
| `EKBackground` | 页面背景 | `fill: EKFill` |

### 核心类 / Core Classes

| 类 | 职责 |
|------|------|
| `EditorStore` | 全局状态仓库：选中、缩放、编辑模式、面板可见性 |
| `EKBaseDocument` | 可继承的文档基类（含 UndoManager） |
| `EKDocumentBridge` | 连接文档与 EditorStore |
| `EKInspectorRegistry` | Inspector 注册表（typeName → View 工厂） |

### 数据流 / Data Flow

```
用户操作 → EditorStore.action()
              │
              ├─ selection 变化  → EKContextInspector 自动切换面板
              ├─ zoomScale 变化  → EKPageCanvasView 重新缩放
              ├─ editMode 变化   → EKEditModeSelector 高亮更新
              └─ onUndoRequested → UndoManager → 数据回滚 → 视图刷新
```

---

## 2. 安装与项目配置 / Installation

### 方式 A：Xcode 图形界面

1. 打开你的 Xcode 项目
2. 菜单 **File → Add Package Dependencies...**
3. 输入 `https://github.com/leyugod/EditorKit.git`
4. 选择版本规则（推荐 **Up to Next Major Version**，从 `1.0.0` 开始）
5. 点击 **Add Package**

### 方式 B：Package.swift

```swift
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MyEditorApp",
    platforms: [.macOS(.v15), .iOS(.v18)],
    dependencies: [
        .package(url: "https://github.com/leyugod/EditorKit.git", from: "1.0.0")
    ],
    targets: [
        .executableTarget(
            name: "MyEditorApp",
            dependencies: ["EditorKit"]
        )
    ]
)
```

### 导入

在你的 Swift 文件中：

```swift
import EditorKit
// EditorKit 已自动导出 SwiftUI，无需重复 import SwiftUI
```

---

## 3. Step 1：定义数据模型 / Define Data Models

### 3.1 定义元素 / Define Elements

每种可以放到画布上的对象都是一个 `EKElement`。

```swift
import EditorKit

// ── 文本元素 ──
@Observable
final class TextElement: EKElement {
    let id = UUID()
    var transform: EKTransform
    var isLocked = false
    var isVisible = true
    var zIndex = 0

    // typeName 用于 Inspector 路由，必须唯一
    var typeName: String { "TextElement" }

    // ── 你的业务字段 ──
    var text: String
    var fontSize: Double
    var textColor: EKColor

    init(text: String = "Hello", position: CGPoint = .zero) {
        self.text = text
        self.fontSize = 24
        self.textColor = .black
        self.transform = EKTransform(
            position: position,
            size: CGSize(width: 300, height: 80)
        )
    }
}
```

**关键点：**

- `@Observable` 是必须的——SwiftUI 通过它跟踪属性变化
- `typeName` 返回一个 **字符串**，作为 Inspector 路由的 key
- `transform` 包含位置、大小、旋转、透明度

#### EKTransform 详解

```swift
public struct EKTransform {
    public var position: CGPoint   // 元素中心点坐标
    public var size: CGSize        // 宽高
    public var rotation: Double    // 旋转角度（单位：度）
    public var opacity: Double     // 透明度 0.0 ~ 1.0
}

// 默认值
let t = EKTransform()
// position = (0, 0), size = (200, 100), rotation = 0, opacity = 1
```

### 3.2 定义背景 / Define Background

```swift
struct MyBackground: EKBackground {
    var fill: EKFill = .color(.white)
}
```

`EKFill` 支持四种填充：

```swift
// 无填充
.none

// 纯色
.color(EKColor(red: 0.2, green: 0.5, blue: 0.9))
.color(.white)
.color(.black)

// 渐变
.gradient(EKGradient(
    stops: [
        .init(color: EKColor(red: 1, green: 0, blue: 0), location: 0),
        .init(color: EKColor(red: 0, green: 0, blue: 1), location: 1),
    ],
    startPoint: .top,
    endPoint: .bottom
))

// 图片
.image("background-photo")  // Asset 名称或 URL 字符串
```

### 3.3 定义页面 / Define Page

```swift
@Observable
final class CanvasPage: EKPage {
    typealias ElementType = TextElement     // 如果只有一种元素
    typealias BackgroundType = MyBackground

    let id = UUID()
    var elements: [TextElement] = []
    var background = MyBackground()
    var size: CGSize { CGSize(width: 1920, height: 1080) }

    func addElement(_ element: TextElement) {
        elements.append(element)
    }

    func removeElement(id: UUID) {
        elements.removeAll { $0.id == id }
    }

    func updateElement(id: UUID, transform: EKTransform) {
        elements.first { $0.id == id }?.transform = transform
    }
}
```

### 3.4 处理多种元素类型（类型擦除）/ Handling Multiple Element Types

如果你的页面需要放置多种不同类型的元素（文本、图片、形状...），你需要一个类型擦除包装器：

```swift
@Observable
final class AnyCanvasElement: EKElement {
    let id: UUID
    var transform: EKTransform {
        get { base.transform }
        set { base.transform = newValue }
    }
    var isLocked: Bool {
        get { base.isLocked }
        set { base.isLocked = newValue }
    }
    var isVisible: Bool {
        get { base.isVisible }
        set { base.isVisible = newValue }
    }
    var zIndex: Int {
        get { base.zIndex }
        set { base.zIndex = newValue }
    }
    var typeName: String { base.typeName }

    let base: any EKElement

    init(_ base: any EKElement) {
        self.id = base.id
        self.base = base
    }

    // 方便获取 Binding<EKTransform>
    var transformBinding: Binding<EKTransform> {
        Binding(
            get: { self.base.transform },
            set: { self.base.transform = $0 }
        )
    }
}
```

然后 Page 使用擦除类型：

```swift
@Observable
final class CanvasPage: EKPage {
    typealias ElementType = AnyCanvasElement
    // ...
    var elements: [AnyCanvasElement] = []
}
```

### 3.5 定义文档 / Define Document

继承 `EKBaseDocument` 可获得 UndoManager、脏标记等：

```swift
@MainActor
@Observable
final class MyDocument: EKBaseDocument {
    var pages: [CanvasPage] = []

    override init(title: String = "My Document") {
        super.init(title: title)
        pages.append(CanvasPage())
    }
}
```

---

## 4. Step 2：创建元素渲染视图 / Create Element Views

每种元素需要一个视图来在画布上渲染。使用 `.ekElement()` 修饰符赋予它选中、拖拽、缩放能力。

### 单一元素类型

```swift
struct TextElementView: View {
    @Bindable var element: TextElement

    var body: some View {
        Text(element.text)
            .font(.system(size: element.fontSize))
            .foregroundStyle(element.textColor.color)
            // .ekElement 修饰符提供：选中高亮 + 拖拽移动 + 缩放句柄
            .ekElement(
                id: element.id,
                typeName: element.typeName,
                transform: $element.transform,
                isLocked: element.isLocked    // 锁定后不可拖拽/缩放
            )
    }
}
```

### 多种元素类型（配合类型擦除）

```swift
struct CanvasElementView: View {
    let element: AnyCanvasElement

    var body: some View {
        Group {
            switch element.typeName {
            case "TextElement":
                if let textEl = element.base as? TextElement {
                    Text(textEl.text)
                        .font(.system(size: textEl.fontSize))
                        .foregroundStyle(textEl.textColor.color)
                }

            case "ImageElement":
                if let imgEl = element.base as? ImageElement {
                    Image(imgEl.imageName)
                        .resizable()
                        .scaledToFill()
                }

            case "ShapeElement":
                if let shapeEl = element.base as? ShapeElement {
                    RoundedRectangle(cornerRadius: shapeEl.cornerRadius)
                        .ekBackground(shapeEl.fill)   // 便捷修饰符
                }

            default:
                Rectangle().fill(.gray.opacity(0.3))
            }
        }
        .ekElement(
            id: element.id,
            typeName: element.typeName,
            transform: element.transformBinding
        )
    }
}
```

### .ekElement 修饰符自动提供的功能

| 功能 | 说明 |
|------|------|
| 选中高亮 | 点击元素时显示蓝色边框 |
| 拖拽移动 | 长按拖拽改变 `transform.position` |
| 8 方向缩放句柄 | 选中后出现 8 个白色圆点，拖动调整 `transform.size` |
| 旋转/透明度 | 自动应用 `transform.rotation` 和 `transform.opacity` |
| 锁定保护 | `isLocked = true` 时禁止拖拽和缩放 |

---

## 5. Step 3：构建 Inspector 面板 / Build Inspector Panels

Inspector 是右侧的属性面板。EditorKit 提供了丰富的内置 UI 组件。

### 5.1 元素级 Inspector

```swift
struct TextElementInspector: View {
    @Bindable var element: TextElement

    var body: some View {
        VStack(spacing: 0) {
            // ── 变换属性（位置/大小/旋转/透明度）──
            // 这是一个完整的预制组件
            EKTransformSection(transform: $element.transform)

            // ── 自定义区域：文本属性 ──
            EKInspectorSection("Text") {
                EKInspectorRow("Content") {
                    TextField("", text: $element.text)
                        .textFieldStyle(.roundedBorder)
                        .font(.caption)
                }

                EKInspectorRow("Size") {
                    HStack {
                        Slider(value: $element.fontSize, in: 8...200)
                        Text("\(Int(element.fontSize))pt")
                            .font(.caption2)
                            .frame(width: 36)
                    }
                }

                EKColorRow("Color", color: $element.textColor)
            }

            // ── 透明度快捷行 ──
            EKOpacityRow(opacity: $element.transform.opacity)
        }
    }
}
```

### 5.2 内置 Inspector 组件一览

| 组件 | 用途 | 示例 |
|------|------|------|
| `EKInspectorSection("标题") { ... }` | 可折叠的分组容器 | 包裹多个属性行 |
| `EKInspectorRow("标签") { ... }` | 标签 + 控件的单行布局 | 左侧标签，右侧任意 View |
| `EKInspectorButton(title:icon:action:)` | Inspector 内的按钮 | 操作按钮 |
| `EKTransformSection(transform:)` | 完整的 X/Y/宽/高/旋转/透明度编辑 | 放在 Inspector 顶部 |
| `EKNumberField("标签", value:, suffix:)` | 数字输入框 | 精确数值输入 |
| `EKColorRow("标签", color:)` | 颜色选择器行 | 选择 `EKColor` |
| `EKOpacityRow(opacity:)` | 透明度滑块 | 0%~100% 滑块 |

### 5.3 页面级 Inspector

当没有选中任何元素时，显示页面属性：

```swift
struct PageInspector: View {
    let page: CanvasPage?

    var body: some View {
        if let page {
            VStack(spacing: 0) {
                EKInspectorSection("Background") {
                    EKFillView(fill: page.background.fill)
                        .frame(height: 60)
                        .cornerRadius(6)
                }
                EKInspectorSection("Info") {
                    EKInspectorRow("Size") {
                        Text("\(Int(page.size.width)) x \(Int(page.size.height))")
                            .font(.caption)
                    }
                    EKInspectorRow("Elements") {
                        Text("\(page.elements.count)")
                            .font(.caption)
                    }
                }
            }
        } else {
            ContentUnavailableView("No Page", systemImage: "doc")
        }
    }
}
```

### 5.4 注册 Inspector / Register Inspectors

在应用启动时告诉框架：哪种 `typeName` 对应哪个 Inspector 视图。

```swift
@MainActor
func registerInspectors(document: MyDocument) {
    let registry = EKInspectorRegistry.shared

    // 文本元素 Inspector
    registry.register(typeName: "TextElement") { elementID in
        // 从文档中根据 ID 找到元素
        let allElements = document.pages.flatMap(\.elements)
        if let wrapper = allElements.first(where: { $0.id == elementID }),
           let textEl = wrapper.base as? TextElement {
            return AnyView(TextElementInspector(element: textEl))
        }
        return AnyView(EmptyView())
    }

    // 图形元素 Inspector
    registry.register(typeName: "ShapeElement") { elementID in
        let allElements = document.pages.flatMap(\.elements)
        if let wrapper = allElements.first(where: { $0.id == elementID }),
           let shapeEl = wrapper.base as? ShapeElement {
            return AnyView(ShapeElementInspector(element: shapeEl))
        }
        return AnyView(EmptyView())
    }
}
```

---

## 6. Step 4：组装编辑器 / Assemble the Editor

`EditorView` 是框架的入口视图，接受四个 `@ViewBuilder` 闭包：

```swift
EditorView(store: EditorStore) {
    /* sidebar  — 左侧边栏 */
} canvas: {
    /* canvas   — 中间画布 */
} inspector: {
    /* inspector — 右侧属性面板 */
} toolbar: {
    /* toolbar  — 顶部工具栏 */
}
```

### 完整组装示例

```swift
@MainActor
struct MyEditorView: View {
    @State private var store = EditorStore()
    @State private var document = MyDocument()
    @State private var bridge: EKDocumentBridge<MyDocument>?

    var currentPage: CanvasPage? {
        guard store.currentPageIndex < document.pages.count else { return nil }
        return document.pages[store.currentPageIndex]
    }

    var body: some View {
        EditorView(store: store) {

            // ━━━━━━━━━━━━━━━━━━━━━━━━
            // 侧边栏：页面缩略图列表
            // ━━━━━━━━━━━━━━━━━━━━━━━━
            EKThumbnailSidebar(
                count: document.pages.count,
                selectedIndex: $store.currentPageIndex,
                onMove: { from, to in
                    document.pages.move(fromOffsets: from, toOffset: to)
                },
                onAdd: {
                    document.pages.append(CanvasPage())
                    store.pageCount = document.pages.count
                },
                onDelete: { index in
                    guard document.pages.count > 1 else { return }
                    document.pages.remove(at: index)
                    store.pageCount = document.pages.count
                }
            ) { index in
                // 每个缩略图的内容
                ZStack {
                    EKFillView(fill: document.pages[index].background.fill)
                    Text("Page \(index + 1)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

        } canvas: {

            // ━━━━━━━━━━━━━━━━━━━━━━━━
            // 画布：当前页面内容
            // ━━━━━━━━━━━━━━━━━━━━━━━━
            if let page = currentPage {
                EKPageCanvasView(pageSize: page.size) {
                    ForEach(page.elements) { element in
                        CanvasElementView(element: element)
                    }
                }
                .coordinateSpace(.named("canvas"))
            }

        } inspector: {

            // ━━━━━━━━━━━━━━━━━━━━━━━━
            // Inspector：自动根据选中状态切换
            // ━━━━━━━━━━━━━━━━━━━━━━━━
            EKContextInspector {
                PageInspector(page: currentPage)
            }

        } toolbar: {

            // ━━━━━━━━━━━━━━━━━━━━━━━━
            // 工具栏：三段式布局
            // ━━━━━━━━━━━━━━━━━━━━━━━━
            EKEditorToolbar {
                // 左区：撤销/重做 + 编辑模式
                EKUndoRedoButtons()
                EKToolbarDivider()
                EKEditModeSelector()
            } center: {
                // 中区：插入按钮
                EKToolbarButton(icon: "text.cursor", label: "Text") {
                    insertTextElement()
                }
                EKToolbarButton(icon: "square", label: "Shape") {
                    insertShapeElement()
                }
            } trailing: {
                // 右区：缩放 + 面板切换
                EKZoomControl()
                EKToolbarDivider()
                EKPanelToggles()
            }
        }
        .onAppear {
            store.pageCount = document.pages.count
            bridge = EKDocumentBridge(document: document, store: store)
            registerInspectors(document: document)
        }
    }

    // MARK: - 操作方法

    private func insertTextElement() {
        guard let page = currentPage else { return }
        let el = TextElement(text: "New Text", position: CGPoint(x: 960, y: 540))
        page.elements.append(AnyCanvasElement(el))
        store.selectElement(id: el.id, type: el.typeName)
    }

    private func insertShapeElement() {
        guard let page = currentPage else { return }
        let el = ShapeElement(position: CGPoint(x: 960, y: 540))
        page.elements.append(AnyCanvasElement(el))
        store.selectElement(id: el.id, type: el.typeName)
    }
}
```

---

## 7. Step 5：连接文档与 Undo/Redo / Wire Up Document & Undo

### EKDocumentBridge

`EKDocumentBridge` 自动将文档的 UndoManager 与 EditorStore 的撤销/重做按钮连接起来：

```swift
// 创建时自动 setup
let bridge = EKDocumentBridge(document: myDocument, store: store)

// 之后工具栏的 EKUndoRedoButtons 自动生效
```

### 可撤销操作

使用 `EKBaseDocument.performUndoable()` 注册可撤销的操作：

```swift
func moveElement(_ element: TextElement, to newPosition: CGPoint) {
    let oldPosition = element.transform.position

    document.performUndoable(
        name: "Move Element",
        action: {
            element.transform.position = newPosition
        },
        undoAction: {
            element.transform.position = oldPosition
        }
    )
}

func deleteElement(id: UUID, from page: CanvasPage) {
    guard let index = page.elements.firstIndex(where: { $0.id == id }) else { return }
    let removed = page.elements[index]

    document.performUndoable(
        name: "Delete Element",
        action: {
            page.elements.remove(at: index)
        },
        undoAction: {
            page.elements.insert(removed, at: index)
        }
    )
}
```

---

## 8. 深入：EditorStore 状态管理 / Deep Dive: EditorStore

`EditorStore` 是整个编辑器的 **中央状态仓库**，通过 SwiftUI Environment 自动传递给所有子视图。

### 常用属性

```swift
let store = EditorStore()

// 文档信息
store.documentTitle          // 文档标题
store.isDirty                // 是否有未保存修改

// 页面管理
store.pageCount              // 页面总数
store.currentPageIndex       // 当前页面索引

// 选中状态
store.selection              // .none / .element(id, type) / .multiElement([ids])
store.selectionManager       // 细粒度选中管理器

// 画布
store.zoomScale              // 当前缩放倍率
store.canvasOffset           // 画布偏移
store.editMode               // .select / .text / .shape / .pen / .hand

// 面板可见性
store.isSidebarVisible       // 侧边栏是否显示
store.isInspectorVisible     // Inspector 是否显示
```

### 常用操作

```swift
// 选中元素
store.selectElement(id: someID, type: "TextElement")

// 取消选中
store.clearSelection()

// 追加多选
store.addToSelection(id: anotherID)

// 缩放
store.zoomIn()               // +25%
store.zoomOut()              // -25%
store.setZoom(1.5)           // 设置为 150%
store.zoomToFit()            // 重置为默认缩放

// 面板切换
store.toggleSidebar()
store.toggleInspector()

// 撤销/重做
store.requestUndo()
store.requestRedo()
```

### 回调钩子

```swift
// 当页面切换时触发
store.onPageChanged = { newIndex in
    print("Switched to page \(newIndex)")
}

// 当选中状态变化时触发
store.onSelectionChanged = { context in
    switch context {
    case .none:
        print("Nothing selected")
    case .element(let id, let type):
        print("Selected \(type) with id \(id)")
    case .multiElement(let ids):
        print("Multi-selected \(ids.count) elements")
    }
}
```

### 自定义配置初始化

```swift
var config = EKEditorConfig()
config.sidebarMinWidth = 200
config.inspectorWidth = 320
config.canvasBackgroundColor = Color(white: 0.95)
config.enableGrid = true
config.gridSpacing = 16
config.minZoom = 0.25
config.maxZoom = 5.0

let store = EditorStore(config: config)
```

---

## 9. 深入：Inspector 注册表 / Deep Dive: Inspector Registry

### 工作原理

```
用户点击元素 → store.selection = .element(id, type: "TextElement")
                    ↓
EKContextInspector 检测到 selection 变化
                    ↓
EKInspectorRegistry.shared.inspector(for: "TextElement", id: someID)
                    ↓
返回注册时提供的 AnyView → 渲染到 Inspector 区域
```

### 注册 API

```swift
// 基础注册
EKInspectorRegistry.shared.register(typeName: "TextElement") { elementID -> AnyView in
    // 根据 elementID 构建 Inspector 视图
    return AnyView(MyInspector(elementID: elementID))
}
```

### EKContextInspector

放在 `EditorView` 的 inspector 区域，它会：
- **无选中时** → 显示你提供的 `pageInspector` 闭包
- **选中元素时** → 自动查询 Registry 显示对应面板
- **多选时** → 显示内置的多选操作面板（编组/对齐/分布）
- **未注册的类型** → 显示 "No Inspector Registered" 提示

```swift
EKContextInspector {
    // 这里放页面级 Inspector
    PageInspector(page: currentPage)
}
```

---

## 10. 深入：画布与交互 / Deep Dive: Canvas & Interactions

### EKPageCanvasView

可缩放的单页画布容器：

```swift
EKPageCanvasView(pageSize: CGSize(width: 1920, height: 1080)) {
    // 你的元素视图
    ForEach(page.elements) { element in
        MyElementView(element: element)
    }
}
```

它自动提供：
- 白色"纸张"背景 + 阴影
- 根据容器大小自动适配缩放
- 响应 `store.zoomScale` 变化
- 水平/垂直滚动
- 点击空白区域自动取消选中

### EKElementView

交互式元素容器（通常通过 `.ekElement()` 修饰符使用）：

```swift
// 方式 1：修饰符（推荐）
Text("Hello")
    .ekElement(id: el.id, typeName: "TextElement",
               transform: $el.transform, isLocked: false)

// 方式 2：显式容器
EKElementView(id: el.id, typeName: "TextElement",
              transform: $el.transform, isLocked: false) {
    Text("Hello")
}
```

### EKFillView

通用填充渲染视图：

```swift
// 可以单独使用
EKFillView(fill: .color(.white))
EKFillView(fill: .gradient(myGradient))

// 或作为背景修饰符
myView.ekBackground(.color(EKColor(red: 0.9, green: 0.9, blue: 1)))
```

---

## 11. 深入：工具栏组件 / Deep Dive: Toolbar Components

### EKEditorToolbar

三段式工具栏布局：

```swift
EKEditorToolbar {
    // leading：左对齐区域
} center: {
    // center：居中区域
} trailing: {
    // trailing：右对齐区域
}
```

### 内置工具栏组件

| 组件 | 功能 |
|------|------|
| `EKToolbarButton(icon:label:isActive:action:)` | 图标按钮（支持高亮状态） |
| `EKToolbarDivider()` | 垂直分隔线 |
| `EKEditModeSelector()` | 编辑模式切换器（选择/文本/形状/画笔/平移） |
| `EKZoomControl()` | 缩放控件（缩小/百分比菜单/放大） |
| `EKUndoRedoButtons()` | 撤销/重做按钮组 |
| `EKPanelToggles()` | 侧边栏/Inspector 显示切换 |
| `EKPlayButton(action:)` | 播放/演示按钮 |

### 自定义工具栏按钮

```swift
EKToolbarButton(
    icon: "photo",                     // SF Symbol 名称
    label: "Insert Image",             // tooltip 文本
    isActive: false                    // 是否高亮
) {
    // 点击操作
    showImagePicker = true
}
```

---

## 12. 深入：侧边栏 / Deep Dive: Sidebar

### EKThumbnailSidebar

```swift
EKThumbnailSidebar(
    count: pages.count,                           // 页面数量
    selectedIndex: $store.currentPageIndex,        // 双向绑定当前页
    onMove: { from, to in ... },                  // 拖拽排序回调
    onAdd: { ... },                               // 添加页面回调
    onDelete: { index in ... }                     // 删除页面回调
) { index -> some View in
    // 每个缩略图的渲染内容
    MyThumbnailView(page: pages[index])
}
```

自动提供的功能：
- 缩略图列表，16:9 比例
- 选中高亮
- 页码显示
- 拖拽排序
- 右键菜单（新建/复制/删除）
- 底部 "Add Page" 按钮
- 顶部标题栏显示页数

---

## 13. 自定义配置 / Customizing Configuration

`EKEditorConfig` 控制编辑器的方方面面：

```swift
var config = EKEditorConfig()

// ── 布局 ──
config.sidebarMinWidth = 160         // 侧边栏最小宽度
config.sidebarMaxWidth = 260         // 侧边栏最大宽度
config.inspectorWidth = 280          // Inspector 固定宽度
config.toolbarHeight = 52            // 工具栏高度

// ── 画布 ──
config.canvasBackgroundColor = Color(white: 0.92)
config.canvasPadding = 40            // 画布内边距
config.defaultZoom = 1.0             // 默认缩放
config.minZoom = 0.1                 // 最小缩放
config.maxZoom = 4.0                 // 最大缩放

// ── 功能开关 ──
config.showPageNumbers = true        // 侧边栏显示页码
config.enableRulers = true           // 启用标尺
config.enableGrid = false            // 启用网格
config.gridSpacing = 20              // 网格间距

let store = EditorStore(config: config)
```

---

## 14. 工具类 API / Utility APIs

### EKSnappingHelper（磁吸对齐）

```swift
let snapper = EKSnappingHelper(threshold: 5)

// 检查单个值是否应该磁吸
let (snapped, didSnap) = snapper.snap(102.3, to: 100.0)
// snapped = 100.0, didSnap = true （差值 < 5）

// 将点磁吸到多个参考线
let point = CGPoint(x: 102, y: 198)
let result = snapper.snap(point,
    toX: [0, 100, 200, 300],    // X 方向参考线
    toY: [0, 100, 200, 300]     // Y 方向参考线
)
// result = (100, 200) — 自动吸附到最近的参考线
```

### EKAlignmentHelper（元素对齐）

```swift
let transforms = selectedElements.map(\.transform)

// 所有选中元素左对齐
let aligned = EKAlignmentHelper.align(
    transforms: transforms,
    alignment: .left,          // .left / .centerH / .right / .top / .centerV / .bottom
    in: canvasSize
)

// 将结果应用回元素
for (element, newTransform) in zip(selectedElements, aligned) {
    element.transform = newTransform
}
```

### CGPoint / CGSize 运算符

```swift
let point = CGPoint(x: 100, y: 200)
let offset = CGSize(width: 10, height: -5)

let moved = point + offset        // CGPoint(110, 195)

let a = CGPoint(x: 300, y: 400)
let b = CGPoint(x: 100, y: 100)
let diff = a - b                  // CGSize(200, 300)
```

---

## 15. 本地化 / Localization

EditorKit 内置英文（默认）和简体中文。

### 查看所有 Key

所有本地化 Key 定义在 `Sources/EditorKit/Localization/EKStrings.swift`。常用 Key：

| Key | English | 简体中文 |
|-----|---------|---------|
| `ek.untitled` | Untitled | 未命名 |
| `ek.inspector.page_title` | Page | 页面 |
| `ek.sidebar.title` | Pages | 页面 |
| `ek.sidebar.add_page` | Add Page | 添加页面 |
| `ek.toolbar.undo` | Undo | 撤销 |
| `ek.toolbar.redo` | Redo | 重做 |
| `ek.toolbar.zoom_in` | Zoom In | 放大 |
| `ek.toolbar.zoom_out` | Zoom Out | 缩小 |
| `ek.section.arrange` | Arrange | 排列 |
| `ek.field.opacity` | Opacity | 不透明度 |

### 添加新语言

1. 在你的 App 中创建 `Resources/<lang>.lproj/Localizable.strings`
2. 覆写以 `ek.` 开头的 Key：

```
/* Japanese */
"ek.untitled" = "無題";
"ek.sidebar.title" = "ページ";
"ek.toolbar.undo" = "元に戻す";
```

---

## 16. 完整示例：白板应用 / Full Example: Whiteboard App

一个最小化的白板（Whiteboard）应用，支持在画布上放置便利贴：

```swift
import EditorKit

// ── 1. 便利贴元素 ──

@Observable
final class StickyNote: EKElement {
    let id = UUID()
    var transform: EKTransform
    var isLocked = false
    var isVisible = true
    var zIndex = 0
    var typeName: String { "StickyNote" }

    var text: String
    var noteColor: EKColor

    init(text: String = "", position: CGPoint = .zero,
         color: EKColor = EKColor(red: 1, green: 0.95, blue: 0.6)) {
        self.text = text
        self.noteColor = color
        self.transform = EKTransform(
            position: position,
            size: CGSize(width: 200, height: 200)
        )
    }
}

// ── 2. 背景 & 页面 ──

struct WhiteboardBackground: EKBackground {
    var fill: EKFill = .color(EKColor(red: 0.97, green: 0.97, blue: 0.97))
}

@Observable
final class Whiteboard: EKPage {
    typealias ElementType = StickyNote
    typealias BackgroundType = WhiteboardBackground

    let id = UUID()
    var elements: [StickyNote] = []
    var background = WhiteboardBackground()
    var size: CGSize { CGSize(width: 3000, height: 2000) }

    func addElement(_ element: StickyNote) { elements.append(element) }
    func removeElement(id: UUID) { elements.removeAll { $0.id == id } }
    func updateElement(id: UUID, transform: EKTransform) {
        elements.first { $0.id == id }?.transform = transform
    }
}

// ── 3. 文档 ──

@MainActor @Observable
final class WhiteboardDocument: EKBaseDocument {
    var boards: [Whiteboard] = [Whiteboard()]
}

// ── 4. 便利贴渲染 ──

struct StickyNoteView: View {
    @Bindable var note: StickyNote

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(note.text.isEmpty ? "Tap to edit..." : note.text)
                .font(.body)
                .foregroundStyle(note.text.isEmpty ? .secondary : .primary)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .padding(12)
        .background(note.noteColor.color)
        .cornerRadius(4)
        .shadow(color: .black.opacity(0.1), radius: 3, y: 2)
        .ekElement(id: note.id, typeName: note.typeName,
                   transform: $note.transform)
    }
}

// ── 5. Inspector ──

struct StickyNoteInspector: View {
    @Bindable var note: StickyNote

    var body: some View {
        VStack(spacing: 0) {
            EKTransformSection(transform: $note.transform)
            EKInspectorSection("Content") {
                TextEditor(text: $note.text)
                    .frame(height: 100)
                    .font(.caption)
                    .cornerRadius(4)
            }
            EKInspectorSection("Style") {
                EKColorRow("Color", color: $note.noteColor)
            }
        }
    }
}

// ── 6. 组装 ──

@MainActor
struct WhiteboardApp: View {
    @State private var store = EditorStore(config: {
        var c = EKEditorConfig()
        c.canvasBackgroundColor = Color(white: 0.96)
        c.defaultZoom = 0.5
        c.enableGrid = true
        c.gridSpacing = 40
        return c
    }())
    @State private var doc = WhiteboardDocument()
    @State private var bridge: EKDocumentBridge<WhiteboardDocument>?

    var board: Whiteboard { doc.boards[store.currentPageIndex] }

    var body: some View {
        EditorView(store: store) {
            EKThumbnailSidebar(
                count: doc.boards.count,
                selectedIndex: $store.currentPageIndex,
                onMove: { doc.boards.move(fromOffsets: $0, toOffset: $1) },
                onAdd: { doc.boards.append(Whiteboard()) },
                onDelete: { i in
                    guard doc.boards.count > 1 else { return }
                    doc.boards.remove(at: i)
                }
            ) { i in
                Text("Board \(i + 1)").font(.caption2)
            }
        } canvas: {
            EKPageCanvasView(pageSize: board.size) {
                ForEach(board.elements) { note in
                    StickyNoteView(note: note)
                }
            }
        } inspector: {
            EKContextInspector {
                Text("Select a sticky note to edit.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding()
            }
        } toolbar: {
            EKEditorToolbar {
                EKUndoRedoButtons()
            } center: {
                EKToolbarButton(icon: "note.text", label: "Add Note") {
                    let note = StickyNote(
                        text: "",
                        position: CGPoint(x: 1500, y: 1000)
                    )
                    board.addElement(note)
                    store.selectElement(id: note.id, type: note.typeName)
                }
            } trailing: {
                EKZoomControl()
                EKPanelToggles()
            }
        }
        .onAppear {
            store.pageCount = doc.boards.count
            bridge = EKDocumentBridge(document: doc, store: store)

            EKInspectorRegistry.shared.register(typeName: "StickyNote") { id in
                if let note = board.elements.first(where: { $0.id == id }) {
                    return AnyView(StickyNoteInspector(note: note))
                }
                return AnyView(EmptyView())
            }
        }
    }
}
```

---

## 17. 最佳实践 / Best Practices

### 数据模型

- 所有 Element 类使用 `@Observable`，确保 SwiftUI 能跟踪变化
- `typeName` 使用类名字符串，保持唯一且一致
- 将 `EKTransform` 作为标准变换存储，不要在元素上单独存 position/size
- 多类型元素使用类型擦除包装器（参考 `AnySlideElement`）

### Inspector

- 在 App 启动时（`.onAppear`）注册所有 Inspector
- Inspector 视图使用 `@Bindable` 接收元素，实现实时双向绑定
- 善用内置组件 `EKTransformSection` / `EKInspectorSection` / `EKColorRow`
- 每个 `EKInspectorSection` 对应一个属性分组

### 性能

- `EKPageCanvasView` 内使用 `ForEach` 时确保元素有稳定的 `id`
- 不可见元素（`isVisible = false`）应在渲染时过滤掉
- 大量元素场景下考虑只渲染视口内的元素

### Undo/Redo

- 所有修改操作通过 `document.performUndoable()` 包装
- 确保 `undoAction` 闭包能完整还原状态
- 用 `EKDocumentBridge` 自动同步 UndoManager 与 EditorStore

### Swift 6 并发

- `EditorStore` 和 `EKBaseDocument` 已标记 `@MainActor`，直接在主线程使用
- `EKTransform`、`EKColor`、`EKFill` 等值类型都是 `Sendable`，可安全跨线程传递
- 自定义 Element 类如果需要跨线程传递，确保遵循 `Sendable`

---

## 18. 常见问题 / FAQ

### Q: 点击元素但 Inspector 没有变化？

**A:** 检查是否已注册该 `typeName` 对应的 Inspector：

```swift
EKInspectorRegistry.shared.register(typeName: "YourTypeName") { id in ... }
```

`typeName` 必须与 Element 的 `typeName` 属性返回值完全一致。

### Q: 元素无法拖拽？

**A:** 检查以下几点：
1. `isLocked` 是否为 `true`
2. 是否使用了 `.ekElement()` 修饰符或 `EKElementView`
3. Canvas 是否添加了 `.coordinateSpace(.named("canvas"))`

### Q: 如何获取当前选中的元素？

```swift
switch store.selection {
case .element(let id, let type):
    let element = page.elements.first { $0.id == id }
case .multiElement(let ids):
    let elements = page.elements.filter { ids.contains($0.id) }
case .none:
    break
}
```

### Q: 如何自定义画布背景色？

```swift
var config = EKEditorConfig()
config.canvasBackgroundColor = Color(red: 0.15, green: 0.15, blue: 0.18) // 深色
let store = EditorStore(config: config)
```

### Q: 如何禁用侧边栏/Inspector？

```swift
// 初始化时隐藏
store.isSidebarVisible = false
store.isInspectorVisible = false

// 或者不在工具栏放 EKPanelToggles，用户就无法切换
```

### Q: 如何添加键盘快捷键？

`EditorView` 已内置 `Esc` 键取消选中。你可以在外层添加更多：

```swift
EditorView(store: store) { ... }
    .onKeyPress(.delete) {
        deleteSelectedElement()
        return .handled
    }
    .onKeyPress("z", modifiers: .command) {
        store.requestUndo()
        return .handled
    }
```

### Q: 如何同时在 macOS 和 iOS 上运行？

EditorKit 已处理所有平台差异（`#if os(macOS)` / `#else`）。你的代码无需额外适配，`EditorView` 在两个平台上都能正确渲染。macOS 上会自动设置最小窗口尺寸 900x600。

---

> 更多信息请查看 [ARCHITECTURE.md](../ARCHITECTURE.md) 了解框架内部设计，或查看 [Examples/PresentationApp/](../Examples/PresentationApp/) 获取完整的幻灯片应用示例。
