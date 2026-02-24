// MARK: - EditorKit/Layout/SidebarView.swift
// 侧边栏系统 —— 页面缩略图列表，支持拖拽排序

import SwiftUI

// ============================================================
// MARK: EKThumbnailSidebar —— 通用缩略图侧边栏
// ============================================================

/// 应用层使用示例：
/// ```swift
/// EKThumbnailSidebar(
///     count: document.slides.count,
///     selectedIndex: $store.currentPageIndex,
///     onMove: { from, to in document.slides.move(fromOffsets: from, toOffset: to) },
///     onAdd: { document.addSlide() },
///     onDelete: { document.removeSlide(at: $0) }
/// ) { index in
///     SlidePreviewImage(slide: document.slides[index])
/// }
/// ```
public struct EKThumbnailSidebar<Thumbnail: View>: View {
    @Environment(\.editorStore) private var store

    let count: Int
    @Binding var selectedIndex: Int
    let onMove: (IndexSet, Int) -> Void
    let onAdd: () -> Void
    let onDelete: (Int) -> Void
    let thumbnail: (Int) -> Thumbnail

    @State private var isDraggingOver: Int? = nil

    public init(
        count: Int,
        selectedIndex: Binding<Int>,
        onMove: @escaping (IndexSet, Int) -> Void,
        onAdd: @escaping () -> Void,
        onDelete: @escaping (Int) -> Void,
        @ViewBuilder thumbnail: @escaping (Int) -> Thumbnail
    ) {
        self.count = count
        self._selectedIndex = selectedIndex
        self.onMove = onMove
        self.onAdd = onAdd
        self.onDelete = onDelete
        self.thumbnail = thumbnail
    }

    public var body: some View {
        VStack(spacing: 0) {
            // 头部
            EKSidebarHeader()

            Divider()

            // 缩略图列表
            List(selection: $selectedIndex) {
                ForEach(0..<count, id: \.self) { index in
                    EKThumbnailCell(
                        index: index,
                        isSelected: selectedIndex == index,
                        thumbnail: { thumbnail(index) }
                    )
                    .tag(index)
                    .listRowInsets(EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .contextMenu {
                        EKThumbnailContextMenu(
                            index: index,
                            onDuplicate: { onAdd() },
                            onDelete: { onDelete(index) }
                        )
                    }
                }
                .onMove { from, to in onMove(from, to) }
            }
            .listStyle(.plain)

            Divider()

            // 底部添加按钮
            EKSidebarFooter(onAdd: onAdd)
        }
    }
}

// ============================================================
// MARK: EKSidebarHeader
// ============================================================

struct EKSidebarHeader: View {
    @Environment(\.editorStore) private var store

    var body: some View {
        HStack {
            Text(EKStrings.sidebarTitle)
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()

            Text(EKStrings.sidebarPageCount(store?.pageCount ?? 0))
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}

// ============================================================
// MARK: EKThumbnailCell
// ============================================================

struct EKThumbnailCell<Thumbnail: View>: View {
    let index: Int
    let isSelected: Bool
    let thumbnail: () -> Thumbnail

    var body: some View {
        VStack(spacing: 4) {
            // 缩略图
            thumbnail()
                .aspectRatio(16/9, contentMode: .fit)
                .background(Color.white)
                .cornerRadius(4)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(
                            isSelected ? Color.accentColor : Color.gray.opacity(0.3),
                            lineWidth: isSelected ? 2 : 1
                        )
                )
                .shadow(
                    color: .black.opacity(isSelected ? 0.12 : 0.06),
                    radius: isSelected ? 4 : 2
                )

            // 页码
            Text("\(index + 1)")
                .font(.caption2)
                .foregroundStyle(isSelected ? Color.accentColor : .secondary)
        }
        .padding(.vertical, 2)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isSelected ? Color.accentColor.opacity(0.08) : Color.clear)
        )
        .animation(.easeInOut(duration: 0.1), value: isSelected)
    }
}

// ============================================================
// MARK: EKThumbnailContextMenu
// ============================================================

struct EKThumbnailContextMenu: View {
    let index: Int
    let onDuplicate: () -> Void
    let onDelete: () -> Void

    var body: some View {
        Button(EKStrings.sidebarNewPageAfter, action: onDuplicate)
        Button(EKStrings.sidebarDuplicatePage, action: onDuplicate)
        Divider()
        Button(EKStrings.sidebarDeletePage, role: .destructive, action: onDelete)
    }
}

// ============================================================
// MARK: EKSidebarFooter
// ============================================================

struct EKSidebarFooter: View {
    let onAdd: () -> Void

    var body: some View {
        Button(action: onAdd) {
            Label(EKStrings.sidebarAddPage, systemImage: "plus")
                .font(.caption)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
        .foregroundStyle(.secondary)
    }
}
