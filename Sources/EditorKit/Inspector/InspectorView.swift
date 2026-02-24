// MARK: - EditorKit/Inspector/InspectorView.swift
// Inspector 系统 —— 上下文感知属性面板 + 注册表模式

import SwiftUI

// ============================================================
// MARK: EKInspectorRegistry —— Inspector 注册表
// ============================================================
// 通过注册表将元素 typeName 映射到对应的 Inspector 视图
// 应用层在启动时注册，运行时动态路由

@MainActor
public final class EKInspectorRegistry {

    public static let shared = EKInspectorRegistry()
    private init() {}

    // typeName → AnyView 工厂函数
    // 工厂接收选中元素 ID，返回对应 Inspector 视图
    private var factories: [String: @MainActor (UUID) -> AnyView] = [:]

    /// 注册元素 Inspector
    /// - Parameters:
    ///   - typeName: 元素类型名（与 EKElement.typeName 一致）
    ///   - factory: 接收元素 ID，返回 AnyView
    public func register(
        typeName: String,
        factory: @escaping @MainActor (UUID) -> AnyView
    ) {
        factories[typeName] = factory
    }

    /// 根据 typeName + id 构建 Inspector 视图
    public func inspector(for typeName: String, id: UUID) -> AnyView? {
        factories[typeName]?(id)
    }
}

// ============================================================
// MARK: EKContextInspector —— 自动切换的上下文 Inspector
// ============================================================

/// 放在应用层 Inspector 区域，自动根据 selection 状态切换内容
public struct EKContextInspector<PageInspector: View>: View {
    @Environment(\.editorStore) private var store
    let registry: EKInspectorRegistry
    let pageInspector: () -> PageInspector

    public init(
        registry: EKInspectorRegistry = .shared,
        @ViewBuilder pageInspector: @escaping () -> PageInspector
    ) {
        self.registry = registry
        self.pageInspector = pageInspector
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Inspector 顶部标题栏
            EKInspectorHeader()

            Divider()

            // 内容区（根据 selection 路由）
            Group {
                switch store?.selection ?? .none {
                case .none:
                    // 显示页面级 Inspector
                    pageInspector()
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .opacity
                        ))

                case .element(let id, let typeName):
                    // 查询注册表，显示对应元素 Inspector
                    if let view = registry.inspector(for: typeName, id: id) {
                        view
                            .id(id) // 强制刷新
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .opacity
                            ))
                    } else {
                        EKUnknownElementInspector(typeName: typeName)
                    }

                case .multiElement(let ids):
                    EKMultiSelectionInspector(ids: ids)
                }
            }
            .animation(.easeInOut(duration: 0.2), value: store?.selection)
        }
    }
}

// ============================================================
// MARK: EKInspectorHeader
// ============================================================

struct EKInspectorHeader: View {
    @Environment(\.editorStore) private var store

    private var title: String {
        switch store?.selection ?? .none {
        case .none: return EKStrings.inspectorPageTitle
        case .element(_, let type): return type
        case .multiElement(let ids): return "\(ids.count) \(EKStrings.inspectorSelected)"
        }
    }

    var body: some View {
        HStack {
            Text(title)
                .font(.headline)
                .fontWeight(.medium)

            Spacer()

            // 关闭 Inspector
            Button {
                store?.toggleInspector()
            } label: {
                Image(systemName: "xmark")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .animation(.none, value: title)
    }
}

// ============================================================
// MARK: EKMultiSelectionInspector
// ============================================================

struct EKMultiSelectionInspector: View {
    let ids: [UUID]
    @Environment(\.editorStore) private var store

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "square.on.square")
                .font(.largeTitle)
                .foregroundStyle(.secondary)

            Text("\(ids.count) \(EKStrings.inspectorSelected)")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Divider()

            // 多选通用操作
            EKMultiSelectionActions()
        }
        .padding()
    }
}

struct EKMultiSelectionActions: View {
    var body: some View {
        VStack(spacing: 8) {
            EKInspectorButton(title: EKStrings.actionGroup, icon: "square.3.layers.3d") {}
            EKInspectorButton(title: EKStrings.actionAlign, icon: "align.horizontal.center") {}
            EKInspectorButton(title: EKStrings.actionDistribute, icon: "distribute.horizontal") {}
        }
    }
}

// ============================================================
// MARK: EKUnknownElementInspector
// ============================================================

struct EKUnknownElementInspector: View {
    let typeName: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "questionmark.square.dashed")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text(EKStrings.inspectorUnregistered)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(String(format: EKStrings.inspectorUnregisteredType, typeName))
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding()
    }
}

// ============================================================
// MARK: Inspector 通用组件库（供应用层 Inspector 使用）
// ============================================================

/// Inspector Section 容器
public struct EKInspectorSection<Content: View>: View {
    let title: String
    let content: () -> Content
    @State private var isExpanded: Bool = true

    public init(_ title: String, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.content = content
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Section 标题（可折叠）
            Button {
                withAnimation(.easeInOut(duration: 0.15)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
            }
            .buttonStyle(.plain)

            if isExpanded {
                VStack(spacing: 12) {
                    content()
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 14)
            }

            Divider()
        }
    }
}

/// Inspector 行（标签 + 控件）
public struct EKInspectorRow<Control: View>: View {
    let label: String
    let control: () -> Control

    public init(_ label: String, @ViewBuilder control: @escaping () -> Control) {
        self.label = label
        self.control = control
    }

    public var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 60, alignment: .leading)

            control()
        }
    }
}

/// Inspector 按钮
public struct EKInspectorButton: View {
    let title: String
    let icon: String
    let action: () -> Void

    public init(title: String, icon: String, action: @escaping () -> Void) {
        self.title = title; self.icon = icon; self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(.caption)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
        }
        .buttonStyle(.bordered)
        .controlSize(.small)
    }
}

/// 颜色选择器行
public struct EKColorRow: View {
    let label: String
    @Binding var color: EKColor

    public init(_ label: String, color: Binding<EKColor>) {
        self.label = label
        self._color = color
    }

    @State private var swiftColor: Color = .white

    public var body: some View {
        EKInspectorRow(label) {
            ColorPicker("", selection: $swiftColor)
                .onChange(of: swiftColor) { _, newColor in
                    color = EKColor(swiftUIColor: newColor)
                }
                .onAppear {
                    swiftColor = color.color
                }
        }
    }
}

/// 透明度滑块行
public struct EKOpacityRow: View {
    @Binding var opacity: Double

    public init(opacity: Binding<Double>) {
        self._opacity = opacity
    }

    public var body: some View {
        EKInspectorRow(EKStrings.fieldOpacity) {
            HStack(spacing: 8) {
                Slider(value: $opacity, in: 0...1)
                Text("\(Int(opacity * 100))%")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .frame(width: 30, alignment: .trailing)
            }
        }
    }
}

/// 位置/尺寸输入行
public struct EKTransformSection: View {
    @Binding var transform: EKTransform

    public init(transform: Binding<EKTransform>) {
        self._transform = transform
    }

    public var body: some View {
        EKInspectorSection(EKStrings.sectionArrange) {
            HStack(spacing: 8) {
                EKNumberField("X", value: $transform.position.x)
                EKNumberField("Y", value: $transform.position.y)
            }
            HStack(spacing: 8) {
                EKNumberField(EKStrings.fieldWidth, value: $transform.size.width)
                EKNumberField(EKStrings.fieldHeight, value: $transform.size.height)
            }
            EKNumberField(EKStrings.fieldRotation, value: $transform.rotation, suffix: "°")
            EKOpacityRow(opacity: $transform.opacity)
        }
    }
}

/// 数字输入框
public struct EKNumberField: View {
    let label: String
    @Binding var value: Double
    var suffix: String = ""

    public init(_ label: String, value: Binding<Double>, suffix: String = "") {
        self.label = label; self._value = value; self.suffix = suffix
    }

    /// Convenience initializer accepting `Binding<CGFloat>`.
    public init(_ label: String, value: Binding<CGFloat>, suffix: String = "") {
        self.label = label
        self._value = Binding(
            get: { Double(value.wrappedValue) },
            set: { value.wrappedValue = CGFloat($0) }
        )
        self.suffix = suffix
    }

    public var body: some View {
        HStack(spacing: 4) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .frame(width: 20, alignment: .leading)

            TextField("", value: $value, format: .number)
                .textFieldStyle(.roundedBorder)
                .font(.caption)
                .multilineTextAlignment(.trailing)

            if !suffix.isEmpty {
                Text(suffix)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
