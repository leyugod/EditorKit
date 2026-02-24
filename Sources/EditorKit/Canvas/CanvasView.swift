// MARK: - EditorKit/Canvas/CanvasView.swift
// 画布系统 —— 缩放、平移、元素渲染、选中句柄

import SwiftUI

// ============================================================
// MARK: EKPageCanvasView —— 单页画布（泛型，支持任意元素类型）
// ============================================================

/// 应用层使用：
/// ```swift
/// EKPageCanvasView(pageSize: CGSize(width: 1920, height: 1080)) {
///     ForEach(page.elements) { element in
///         MyElementView(element: element)
///     }
/// }
/// ```
public struct EKPageCanvasView<Content: View>: View {
    @Environment(\.editorStore) private var store

    let pageSize: CGSize
    let content: () -> Content

    public init(pageSize: CGSize, @ViewBuilder content: @escaping () -> Content) {
        self.pageSize = pageSize
        self.content = content
    }

    public var body: some View {
        GeometryReader { geo in
            let fittingScale = min(
                geo.size.width / pageSize.width,
                geo.size.height / pageSize.height
            ) * 0.9

            ScrollView([.horizontal, .vertical], showsIndicators: true) {
                ZStack {
                    // 页面白纸
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white)
                        .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 2)
                        .frame(width: pageSize.width, height: pageSize.height)

                    // 元素内容层
                    ZStack {
                        content()
                    }
                    .frame(width: pageSize.width, height: pageSize.height)
                    .clipped()
                }
                .scaleEffect(fittingScale * (store?.zoomScale ?? 1.0))
                .frame(
                    width: pageSize.width * fittingScale * (store?.zoomScale ?? 1.0),
                    height: pageSize.height * fittingScale * (store?.zoomScale ?? 1.0)
                )
                .padding(store?.config.canvasPadding ?? 40)
            }
        }
    }
}

// ============================================================
// MARK: EKElementView —— 可交互元素容器
// ============================================================

/// 包装任意元素视图，提供：选中高亮、拖拽移动、缩放句柄
public struct EKElementView<Content: View>: View {
    @Environment(\.editorStore) private var store

    let id: UUID
    let typeName: String
    @Binding var transform: EKTransform
    let isLocked: Bool
    let content: () -> Content

    @State private var isDragging = false
    @State private var dragStart: CGPoint = .zero

    public init(
        id: UUID,
        typeName: String,
        transform: Binding<EKTransform>,
        isLocked: Bool = false,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.id = id
        self.typeName = typeName
        self._transform = transform
        self.isLocked = isLocked
        self.content = content
    }

    private var isSelected: Bool {
        guard let store else { return false }
        switch store.selection {
        case .element(let eid, _): return eid == id
        case .multiElement(let ids): return ids.contains(id)
        case .none: return false
        }
    }

    public var body: some View {
        content()
            .frame(width: transform.size.width, height: transform.size.height)
            .opacity(transform.opacity)
            .rotationEffect(.degrees(transform.rotation))
            // 选中边框
            .overlay {
                if isSelected {
                    RoundedRectangle(cornerRadius: 2)
                        .stroke(Color.accentColor, lineWidth: 1.5)
                        .padding(-1)
                }
            }
            // 选中句柄（仅单选且非锁定）
            .overlay {
                if isSelected && !isLocked {
                    EKSelectionHandles(transform: $transform)
                }
            }
            // 位置
            .position(transform.position)
            // 点击选中
            .onTapGesture {
                store?.selectElement(id: id, type: typeName)
            }
            // 拖拽移动
            .gesture(
                isLocked ? nil : DragGesture(coordinateSpace: .named("canvas"))
                    .onChanged { value in
                        if !isDragging {
                            isDragging = true
                            dragStart = transform.position
                        }
                        transform.position = CGPoint(
                            x: dragStart.x + value.translation.width,
                            y: dragStart.y + value.translation.height
                        )
                        store?.selectElement(id: id, type: typeName)
                    }
                    .onEnded { _ in
                        isDragging = false
                    }
            )
    }
}

// ============================================================
// MARK: EKSelectionHandles —— 8方向缩放句柄
// ============================================================

public struct EKSelectionHandles: View {
    @Binding var transform: EKTransform

    private let handleSize: CGFloat = 8

    enum Handle: CaseIterable, Hashable {
        case topLeft, top, topRight
        case left, right
        case bottomLeft, bottom, bottomRight
    }

    public var body: some View {
        ZStack {
            ForEach(Handle.allCases, id: \.self) { handle in
                EKHandleDot(size: handleSize)
                    .position(position(for: handle))
                    .gesture(dragGesture(for: handle))
            }
        }
    }

    private func position(for handle: Handle) -> CGPoint {
        let w = transform.size.width
        let h = transform.size.height
        switch handle {
        case .topLeft:     return CGPoint(x: 0,   y: 0)
        case .top:         return CGPoint(x: w/2, y: 0)
        case .topRight:    return CGPoint(x: w,   y: 0)
        case .left:        return CGPoint(x: 0,   y: h/2)
        case .right:       return CGPoint(x: w,   y: h/2)
        case .bottomLeft:  return CGPoint(x: 0,   y: h)
        case .bottom:      return CGPoint(x: w/2, y: h)
        case .bottomRight: return CGPoint(x: w,   y: h)
        }
    }

    private func dragGesture(for handle: Handle) -> some Gesture {
        DragGesture()
            .onChanged { value in
                let dx = value.translation.width
                let dy = value.translation.height
                var newSize = transform.size
                var newPos = transform.position

                switch handle {
                case .bottomRight:
                    newSize.width = max(40, transform.size.width + dx)
                    newSize.height = max(40, transform.size.height + dy)
                case .bottomLeft:
                    newSize.width = max(40, transform.size.width - dx)
                    newSize.height = max(40, transform.size.height + dy)
                    newPos.x = transform.position.x + dx / 2
                case .topRight:
                    newSize.width = max(40, transform.size.width + dx)
                    newSize.height = max(40, transform.size.height - dy)
                    newPos.y = transform.position.y + dy / 2
                case .topLeft:
                    newSize.width = max(40, transform.size.width - dx)
                    newSize.height = max(40, transform.size.height - dy)
                    newPos.x = transform.position.x + dx / 2
                    newPos.y = transform.position.y + dy / 2
                case .right:
                    newSize.width = max(40, transform.size.width + dx)
                case .left:
                    newSize.width = max(40, transform.size.width - dx)
                    newPos.x = transform.position.x + dx / 2
                case .bottom:
                    newSize.height = max(40, transform.size.height + dy)
                case .top:
                    newSize.height = max(40, transform.size.height - dy)
                    newPos.y = transform.position.y + dy / 2
                }
                transform.size = newSize
                transform.position = newPos
            }
    }
}

struct EKHandleDot: View {
    let size: CGFloat
    var body: some View {
        Circle()
            .fill(Color.white)
            .frame(width: size, height: size)
            .overlay(Circle().stroke(Color.accentColor, lineWidth: 1.5))
            .shadow(radius: 1)
    }
}

// ============================================================
// MARK: EKFillView —— 通用填充渲染
// ============================================================

public struct EKFillView: View {
    let fill: EKFill

    public init(fill: EKFill) { self.fill = fill }

    public var body: some View {
        switch fill {
        case .none:
            Color.clear
        case .color(let c):
            c.color
        case .gradient(let g):
            LinearGradient(
                stops: g.stops.map { .init(color: $0.color.color, location: $0.location) },
                startPoint: g.startPoint.unitPoint,
                endPoint: g.endPoint.unitPoint
            )
        case .image(let name):
            Image(name)
                .resizable()
                .scaledToFill()
        }
    }
}

