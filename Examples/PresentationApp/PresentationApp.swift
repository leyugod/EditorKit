// MARK: - PresentationApp (Demo: Building a Presentation App with EditorKit)
// This example demonstrates how to build a full slide editor on top of EditorKit.
// To run: add EditorKit as a dependency in your own app target and copy this file.

import SwiftUI
import EditorKit

// ============================================================
// MARK: Step 1：定义应用的文档模型
// ============================================================

// 文本元素
@Observable
final class TextElement: EKElement {
    let id: UUID = UUID()
    var transform: EKTransform
    var isLocked: Bool = false
    var isVisible: Bool = true
    var zIndex: Int = 0
    var typeName: String { "TextElement" }

    // 业务数据
    var text: String
    var fontSize: Double
    var fontWeight: Font.Weight
    var textColor: EKColor
    var alignment: TextAlignment

    init(
        text: String = "双击编辑文本",
        position: CGPoint = CGPoint(x: 400, y: 300)
    ) {
        self.text = text
        self.fontSize = 24
        self.fontWeight = .regular
        self.textColor = .black
        self.alignment = .center
        self.transform = EKTransform(
            position: position,
            size: CGSize(width: 300, height: 80)
        )
    }
}

// 图形元素
@Observable
final class ShapeElement: EKElement {
    let id: UUID = UUID()
    var transform: EKTransform
    var isLocked: Bool = false
    var isVisible: Bool = true
    var zIndex: Int = 0
    var typeName: String { "ShapeElement" }

    var fill: EKFill
    var cornerRadius: Double
    var strokeColor: EKColor
    var strokeWidth: Double

    init(position: CGPoint = CGPoint(x: 300, y: 250)) {
        self.fill = .color(EKColor(red: 0.2, green: 0.5, blue: 0.9))
        self.cornerRadius = 8
        self.strokeColor = .clear
        self.strokeWidth = 0
        self.transform = EKTransform(
            position: position,
            size: CGSize(width: 200, height: 150)
        )
    }
}

// 页面背景
struct SlideBackground: EKBackground {
    var fill: EKFill = .color(.white)
}

// 幻灯片页面
@Observable
final class Slide: EKPage {
    typealias ElementType = AnySlideElement  // 类型擦除
    typealias BackgroundType = SlideBackground

    let id: UUID = UUID()
    var elements: [AnySlideElement] = []
    var background: SlideBackground = SlideBackground()
    var size: CGSize { CGSize(width: 1920, height: 1080) }

    // 因为 EKElement 是协议，使用类型擦除包装
    func addElement(_ element: AnySlideElement) {
        elements.append(element)
    }
    func removeElement(id: UUID) {
        elements.removeAll { $0.id == id }
    }
    func updateElement(id: UUID, transform: EKTransform) {
        elements.first { $0.id == id }?.transform = transform
    }
}

// 类型擦除包装（处理元素多态）
@Observable
final class AnySlideElement: EKElement {
    let id: UUID
    var transform: EKTransform { get { base.transform } set { base.transform = newValue } }
    var isLocked: Bool { get { base.isLocked } set { base.isLocked = newValue } }
    var isVisible: Bool { get { base.isVisible } set { base.isVisible = newValue } }
    var zIndex: Int { get { base.zIndex } set { base.zIndex = newValue } }
    var typeName: String { base.typeName }

    let base: any EKElement

    init(_ base: any EKElement) {
        self.id = base.id
        self.base = base
    }
}

// 演示文档
@MainActor
@Observable
final class PresentationDocument: EKBaseDocument {
    var slides: [Slide] = []

    override init(title: String = "新演示文稿") {
        super.init(title: title)
        // 默认添加一张空白幻灯片
        let slide = Slide()
        let textEl = TextElement(text: "点击添加标题", position: CGPoint(x: 960, y: 400))
        slide.elements.append(AnySlideElement(textEl))
        slides.append(slide)
    }
}

// ============================================================
// MARK: Step 2：注册 Inspector
// ============================================================

extension EKInspectorRegistry {
    @MainActor
    static func registerPresentationInspectors(document: PresentationDocument) {
        shared.register(typeName: "TextElement") { id in
            // 从文档中找到元素
            let allElements = document.slides.flatMap(\.elements)
            if let wrapper = allElements.first(where: { $0.id == id }),
               let textEl = wrapper.base as? TextElement {
                return AnyView(TextElementInspector(element: textEl))
            }
            return AnyView(EmptyView())
        }

        shared.register(typeName: "ShapeElement") { id in
            let allElements = document.slides.flatMap(\.elements)
            if let wrapper = allElements.first(where: { $0.id == id }),
               let shapeEl = wrapper.base as? ShapeElement {
                return AnyView(ShapeElementInspector(element: shapeEl))
            }
            return AnyView(EmptyView())
        }
    }
}

// ============================================================
// MARK: Step 3：实现 Inspector 视图
// ============================================================

struct TextElementInspector: View {
    @Bindable var element: TextElement

    var body: some View {
        VStack(spacing: 0) {
            EKTransformSection(transform: $element.transform)

            EKInspectorSection("文本") {
                EKInspectorRow("内容") {
                    TextField("文本", text: $element.text)
                        .textFieldStyle(.roundedBorder)
                        .font(.caption)
                }
                EKInspectorRow("字号") {
                    HStack {
                        Slider(value: $element.fontSize, in: 8...200)
                        Text("\(Int(element.fontSize))pt")
                            .font(.caption2)
                            .frame(width: 36)
                    }
                }
                EKColorRow("颜色", color: $element.textColor)
            }
        }
    }
}

struct ShapeElementInspector: View {
    @Bindable var element: ShapeElement

    var body: some View {
        VStack(spacing: 0) {
            EKTransformSection(transform: $element.transform)

            EKInspectorSection("填充") {
                // 简化：只展示颜色选择
                if case .color(let c) = element.fill {
                    var color = c
                    EKColorRow("颜色", color: Binding(
                        get: { color },
                        set: { element.fill = .color($0) }
                    ))
                }
                EKInspectorRow("圆角") {
                    Slider(value: $element.cornerRadius, in: 0...100)
                }
            }

            EKInspectorSection("描边") {
                EKColorRow("颜色", color: $element.strokeColor)
                EKInspectorRow("宽度") {
                    Slider(value: $element.strokeWidth, in: 0...20)
                }
            }
        }
    }
}

// 页面属性 Inspector
struct SlidePageInspector: View {
    let slide: Slide?

    var body: some View {
        if let slide {
            VStack(spacing: 0) {
                EKInspectorSection("背景") {
                    EKFillView(fill: slide.background.fill)
                        .frame(height: 60)
                        .cornerRadius(6)
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.gray.opacity(0.3)))
                }

                EKInspectorSection("过渡") {
                    Text("无")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        } else {
            ContentUnavailableView("未选择页面", systemImage: "doc")
        }
    }
}

// ============================================================
// MARK: Step 4：实现画布元素视图
// ============================================================

struct SlideElementView: View {
    let element: AnySlideElement

    var body: some View {
        Group {
            if let textEl = element.base as? TextElement {
                Text(textEl.text)
                    .font(.system(size: textEl.fontSize))
                    .foregroundStyle(textEl.textColor.color)
                    .multilineTextAlignment(textEl.alignment)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .ekElement(id: element.id, typeName: element.typeName, transform: element.$transform)

            } else if let shapeEl = element.base as? ShapeElement {
                RoundedRectangle(cornerRadius: shapeEl.cornerRadius)
                    .ekBackground(shapeEl.fill)
                    .overlay(
                        RoundedRectangle(cornerRadius: shapeEl.cornerRadius)
                            .stroke(shapeEl.strokeColor.color, lineWidth: shapeEl.strokeWidth)
                    )
                    .ekElement(id: element.id, typeName: element.typeName, transform: element.$transform)
            }
        }
    }
}

// ============================================================
// MARK: Step 5：组装完整的 App
// ============================================================

@MainActor
struct PresentationEditorApp: View {
    @State private var store = EditorStore()
    @State private var document = PresentationDocument()
    @State private var bridge: EKDocumentBridge<PresentationDocument>?

    var currentSlide: Slide? {
        guard store.currentPageIndex < document.slides.count else { return nil }
        return document.slides[store.currentPageIndex]
    }

    var body: some View {
        EditorView(store: store) {
            // ── 侧边栏 ──
            EKThumbnailSidebar(
                count: document.slides.count,
                selectedIndex: $store.currentPageIndex,
                onMove: { from, to in document.slides.move(fromOffsets: from, toOffset: to) },
                onAdd: { document.slides.append(Slide()) },
                onDelete: { idx in
                    guard document.slides.count > 1 else { return }
                    document.slides.remove(at: idx)
                }
            ) { index in
                // 缩略图内容（简化版）
                ZStack {
                    EKFillView(fill: document.slides[index].background.fill)
                    Text("幻灯片 \(index + 1)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        } canvas: {
            // ── 画布 ──
            if let slide = currentSlide {
                EKPageCanvasView(pageSize: slide.size) {
                    ForEach(slide.elements) { element in
                        SlideElementView(element: element)
                    }
                }
                .coordinateSpace(.named("canvas"))
            }
        } inspector: {
            // ── Inspector（自动上下文切换）──
            EKContextInspector {
                SlidePageInspector(slide: currentSlide)
            }
        } toolbar: {
            // ── 工具栏 ──
            EKEditorToolbar {
                // 左
                EKUndoRedoButtons()
                EKToolbarDivider()
                EKEditModeSelector()
            } center: {
                // 中：插入按钮
                EKToolbarButton(icon: "text.cursor", label: "插入文本") {
                    insertText()
                }
                EKToolbarButton(icon: "square", label: "插入形状") {
                    insertShape()
                }
                EKToolbarButton(icon: "photo", label: "插入图片") {}
                EKToolbarButton(icon: "chart.bar", label: "插入图表") {}
            } trailing: {
                // 右
                EKZoomControl()
                EKToolbarDivider()
                EKPanelToggles()
                EKToolbarDivider()
                EKPlayButton { startPresentation() }
            }
        }
        .onAppear {
            // 初始化
            store.pageCount = document.slides.count
            bridge = EKDocumentBridge(document: document, store: store)
            EKInspectorRegistry.registerPresentationInspectors(document: document)
        }
    }

    // MARK: - Actions

    private func insertText() {
        guard let slide = currentSlide else { return }
        let el = TextElement(
            text: "双击编辑文本",
            position: CGPoint(x: 960, y: 540)
        )
        slide.elements.append(AnySlideElement(el))
        store.selectElement(id: el.id, type: el.typeName)
    }

    private func insertShape() {
        guard let slide = currentSlide else { return }
        let el = ShapeElement(position: CGPoint(x: 960, y: 540))
        slide.elements.append(AnySlideElement(el))
        store.selectElement(id: el.id, type: el.typeName)
    }

    private func startPresentation() {
        // 进入全屏演示模式
        print("开始演示")
    }
}

// ============================================================
// MARK: @Observable Bindable 扩展（Swift 6）
// ============================================================

extension AnySlideElement {
    var $transform: Binding<EKTransform> {
        Binding(
            get: { self.base.transform },
            set: { self.base.transform = $0 }
        )
    }
}
