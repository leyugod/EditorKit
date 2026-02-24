// MARK: - EditorKit/Toolbar/ToolbarView.swift
// 工具栏系统 —— 灵活分组、可扩展工具栏

import SwiftUI

// ============================================================
// MARK: EKEditorToolbar —— 主工具栏布局
// ============================================================

/// 三段布局：左（导航） | 中（插入/格式） | 右（视图/分享）
public struct EKEditorToolbar<
    Leading: View,
    Center: View,
    Trailing: View
>: View {
    let leading: () -> Leading
    let center: () -> Center
    let trailing: () -> Trailing

    public init(
        @ViewBuilder leading: @escaping () -> Leading,
        @ViewBuilder center: @escaping () -> Center,
        @ViewBuilder trailing: @escaping () -> Trailing
    ) {
        self.leading = leading
        self.center = center
        self.trailing = trailing
    }

    public var body: some View {
        HStack(spacing: 0) {
            // 左：导航区（固定左对齐）
            HStack(spacing: 4) {
                leading()
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // 中：主操作区（居中）
            HStack(spacing: 4) {
                center()
            }
            .frame(maxWidth: .infinity, alignment: .center)

            // 右：视图控制区（固定右对齐）
            HStack(spacing: 4) {
                trailing()
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.horizontal, 8)
    }
}

// ============================================================
// MARK: 工具栏内置控件
// ============================================================

/// 工具栏图标按钮
public struct EKToolbarButton: View {
    let icon: String
    let label: String
    let isActive: Bool
    let action: () -> Void

    public init(
        icon: String,
        label: String,
        isActive: Bool = false,
        action: @escaping () -> Void
    ) {
        self.icon = icon; self.label = label
        self.isActive = isActive; self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .regular))
                .frame(width: 32, height: 32)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(isActive ? Color.accentColor.opacity(0.15) : Color.clear)
                )
                .foregroundStyle(isActive ? Color.accentColor : Color.primary)
        }
        .buttonStyle(.plain)
        .help(label)
    }
}

/// 工具栏分隔符
public struct EKToolbarDivider: View {
    public init() {}

    public var body: some View {
        Divider()
            .frame(height: 20)
            .padding(.horizontal, 4)
    }
}

/// 工具栏编辑模式选择器
public struct EKEditModeSelector: View {
    @Environment(\.editorStore) private var store

    public init() {}

    public var body: some View {
        HStack(spacing: 2) {
            ForEach(EKEditMode.allCases, id: \.self) { mode in
                EKToolbarButton(
                    icon: mode.icon,
                    label: mode.rawValue,
                    isActive: store?.editMode == mode
                ) {
                    store?.editMode = mode
                }
            }
        }
        .padding(2)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.primary.opacity(0.06))
        )
    }
}

/// 工具栏缩放控件
public struct EKZoomControl: View {
    @Environment(\.editorStore) private var store

    public init() {}

    public var body: some View {
        HStack(spacing: 4) {
            Button {
                store?.zoomOut()
            } label: {
                Image(systemName: "minus.magnifyingglass")
            }
            .buttonStyle(.plain)
            .help(EKStrings.toolbarZoomOut)

            Menu {
                Button("25%")  { store?.setZoom(0.25) }
                Button("50%")  { store?.setZoom(0.5) }
                Button("75%")  { store?.setZoom(0.75) }
                Button("100%") { store?.setZoom(1.0) }
                Button("150%") { store?.setZoom(1.5) }
                Button("200%") { store?.setZoom(2.0) }
                Divider()
                Button(EKStrings.toolbarZoomToFit) { store?.zoomToFit() }
            } label: {
                Text("\(Int((store?.zoomScale ?? 1) * 100))%")
                    .font(.caption)
                    .frame(width: 42)
            }
            #if os(macOS)
            .menuStyle(.borderlessButton)
            #endif
            .fixedSize()

            Button {
                store?.zoomIn()
            } label: {
                Image(systemName: "plus.magnifyingglass")
            }
            .buttonStyle(.plain)
            .help(EKStrings.toolbarZoomIn)
        }
    }
}

/// 撤销/重做按钮组
public struct EKUndoRedoButtons: View {
    @Environment(\.editorStore) private var store

    public init() {}

    public var body: some View {
        HStack(spacing: 4) {
            EKToolbarButton(icon: "arrow.uturn.backward", label: EKStrings.toolbarUndo) {
                store?.requestUndo()
            }
            .disabled(!(store?.canUndo ?? false))

            EKToolbarButton(icon: "arrow.uturn.forward", label: EKStrings.toolbarRedo) {
                store?.requestRedo()
            }
            .disabled(!(store?.canRedo ?? false))
        }
    }
}

/// 侧边栏/Inspector 切换按钮
public struct EKPanelToggles: View {
    @Environment(\.editorStore) private var store

    public init() {}

    public var body: some View {
        HStack(spacing: 4) {
            EKToolbarButton(
                icon: "sidebar.left",
                label: EKStrings.toolbarToggleSidebar,
                isActive: store?.isSidebarVisible == true
            ) {
                store?.toggleSidebar()
            }

            EKToolbarButton(
                icon: "sidebar.right",
                label: EKStrings.toolbarToggleInspector,
                isActive: store?.isInspectorVisible == true
            ) {
                store?.toggleInspector()
            }
        }
    }
}

/// 播放/演示按钮
public struct EKPlayButton: View {
    let action: () -> Void

    public init(action: @escaping () -> Void) {
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: "play.fill")
                    .font(.system(size: 12))
                Text(EKStrings.toolbarPlay)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color.accentColor)
            .foregroundStyle(.white)
            .cornerRadius(6)
        }
        .buttonStyle(.plain)
        .help(EKStrings.toolbarStartPresentation)
    }
}
