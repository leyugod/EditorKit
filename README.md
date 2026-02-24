# EditorKit

A composable, protocol-oriented SwiftUI editor framework for building document-based applications.

**Swift 6 | SwiftUI | MVVM | macOS 15+ | iOS 18+**

一个可组合的、面向协议的 SwiftUI 编辑器框架，用于构建基于文档的应用程序。

---

## Features / 功能特性

- **Three-pane layout** — Sidebar, Canvas, Inspector with configurable dimensions
- **Canvas system** — Zoom, pan, element rendering with selection handles
- **Inspector registry** — Dynamic inspector routing by element type name
- **Toolbar components** — Ready-to-use zoom controls, undo/redo, mode selector
- **Document management** — Base document class with UndoManager integration
- **Localization** — Built-in English & Simplified Chinese; extensible via `.lproj`
- **Swift 6 concurrency** — `@MainActor` isolation, `Sendable` value types
- **Zero magic** — No reflection, no runtime hooks, pure SwiftUI

---

## Installation / 安装

### Swift Package Manager

Add EditorKit to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/leyugod/EditorKit.git", from: "1.0.0")
]
```

Or in Xcode: **File > Add Package Dependencies...** and paste the repository URL.

---

## Architecture / 架构

```
┌─────────────────────────────────────────────────────────┐
│                     Your App Layer                       │
│  (Document model / Element views / Inspector / Toolbar)  │
├─────────────────────────────────────────────────────────┤
│                       EditorKit                          │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐  │
│  │  Layout   │ │  Canvas  │ │Inspector │ │ Toolbar  │  │
│  │ 3-pane   │ │ zoom/pan │ │ registry │ │ grouped  │  │
│  └──────────┘ └──────────┘ └──────────┘ └──────────┘  │
│  ┌──────────────────────────────────────────────────┐  │
│  │     Core (Protocols / Value Types / EditorStore)  │  │
│  └──────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
```

### Directory Structure / 目录结构

```
Sources/EditorKit/
├── EditorKit.swift           # Module entry
├── Localization/
│   └── EKStrings.swift       # NSLocalizedString wrapper
├── Core/
│   ├── Protocols.swift       # EKDocument, EKPage, EKElement, ...
│   ├── ValueTypes.swift      # EKTransform, EKFill, EKColor, ...
│   └── EditorViewModel.swift # EditorStore + SelectionManager
├── Layout/
│   ├── EditorView.swift      # Three-pane main layout
│   └── SidebarView.swift     # Thumbnail sidebar
├── Canvas/
│   └── CanvasView.swift      # Canvas + element container + handles
├── Inspector/
│   └── InspectorView.swift   # Inspector registry + UI components
├── Toolbar/
│   └── ToolbarView.swift     # Toolbar components
├── Document/
│   └── BaseDocument.swift    # Base document + Bridge
└── Extensions/
    └── ViewModifiers.swift   # Convenience modifiers
```

---

## Quick Start / 快速开始

### 1. Define your element / 定义元素模型

```swift
@Observable
final class TextElement: EKElement {
    let id = UUID()
    var transform = EKTransform()
    var isLocked = false
    var isVisible = true
    var zIndex = 0
    var typeName: String { "TextElement" }

    var text: String = "Hello"
}
```

### 2. Define your page / 定义页面模型

```swift
@Observable
final class MyPage: EKPage {
    let id = UUID()
    var elements: [TextElement] = []
    var background = MyBackground()
    var size: CGSize { CGSize(width: 1920, height: 1080) }

    func addElement(_ element: TextElement) { elements.append(element) }
    func removeElement(id: UUID) { elements.removeAll { $0.id == id } }
    func updateElement(id: UUID, transform: EKTransform) {
        elements.first { $0.id == id }?.transform = transform
    }
}
```

### 3. Register inspector / 注册 Inspector

```swift
EKInspectorRegistry.shared.register(typeName: "TextElement") { id in
    AnyView(TextElementInspector(elementID: id))
}
```

### 4. Render elements / 渲染元素

```swift
struct TextElementView: View {
    @Bindable var element: TextElement
    var body: some View {
        Text(element.text)
            .ekElement(id: element.id, typeName: element.typeName,
                       transform: $element.transform)
    }
}
```

### 5. Assemble the editor / 组装编辑器

```swift
EditorView(store: store) {
    EKThumbnailSidebar(count: pages.count, selectedIndex: $store.currentPageIndex,
                       onMove: { ... }, onAdd: { ... }, onDelete: { ... }) { index in
        MyThumbnail(page: pages[index])
    }
} canvas: {
    EKPageCanvasView(pageSize: CGSize(width: 1920, height: 1080)) {
        ForEach(currentPage.elements) { TextElementView(element: $0) }
    }
} inspector: {
    EKContextInspector { MyPageInspector() }
} toolbar: {
    EKEditorToolbar {
        EKUndoRedoButtons()
    } center: {
        EKEditModeSelector()
    } trailing: {
        EKZoomControl()
        EKPanelToggles()
    }
}
```

See [`Examples/PresentationApp/`](Examples/PresentationApp/) for a complete demo.

For a comprehensive step-by-step guide, read the **[Tutorial](docs/TUTORIAL.md)**.

完整示例请查看 [`Examples/PresentationApp/`](Examples/PresentationApp/) 目录。

详细的分步教程请阅读 **[使用教程](docs/TUTORIAL.md)**。

---

## Key Types / 核心类型

| Type | Description |
|------|-------------|
| `EKElement` | Protocol for canvas elements (position, size, rotation, lock, visibility) |
| `EKPage` | Protocol for pages/slides (elements list, background, size) |
| `EKDocument` | Protocol for documents (pages, title, undo manager) |
| `EditorStore` | Observable central state store for the editor |
| `EKBaseDocument` | Base class with UndoManager and dirty tracking |
| `EKDocumentBridge` | Connects a document to EditorStore |
| `EditorView` | Main three-pane layout view |
| `EKPageCanvasView` | Zoomable canvas for a single page |
| `EKElementView` | Interactive element container (selection, drag, resize) |
| `EKContextInspector` | Auto-routing inspector based on selection |
| `EKInspectorRegistry` | Registry mapping element types to inspector views |
| `EKEditorConfig` | Global configuration (layout, canvas, features) |

---

## Localization / 本地化

EditorKit ships with English (default) and Simplified Chinese. To add your own language:

1. Create `YourApp/Resources/<lang>.lproj/Localizable.strings`
2. Override keys prefixed with `ek.` (e.g., `ek.sidebar.title`, `ek.toolbar.undo`)

All localization keys are listed in `Sources/EditorKit/Localization/EKStrings.swift`.

---

## Requirements / 系统要求

- Swift 6.0+
- macOS 15+ / iOS 18+
- Xcode 16+

---

## License / 许可证

MIT License. See [LICENSE](LICENSE) for details.
