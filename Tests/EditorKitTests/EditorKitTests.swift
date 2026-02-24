import Testing
@testable import EditorKit

@Suite("EditorKit Core Tests")
struct EditorKitTests {

    @Test func versionExists() {
        #expect(!EditorKit.version.isEmpty)
    }

    @Test func transformDefaults() {
        let t = EKTransform()
        #expect(t.position == .zero)
        #expect(t.size.width == 200)
        #expect(t.size.height == 100)
        #expect(t.rotation == 0)
        #expect(t.opacity == 1)
    }

    @Test func transformEquality() {
        let a = EKTransform(position: CGPoint(x: 10, y: 20), size: CGSize(width: 100, height: 50))
        let b = EKTransform(position: CGPoint(x: 10, y: 20), size: CGSize(width: 100, height: 50))
        #expect(a == b)
    }

    @Test func colorConversion() {
        let c = EKColor(red: 0.5, green: 0.3, blue: 0.8, alpha: 0.9)
        let _ = c.color // Verify Color conversion doesn't crash
        #expect(c.red == 0.5)
        #expect(c.alpha == 0.9)
    }

    @Test func fillCases() {
        let none = EKFill.none
        let solid = EKFill.color(.black)
        #expect(none != solid)
        #expect(EKFill.color(.white) == EKFill.color(.white))
    }

    @Test func selectionContextSendable() {
        let ctx: EKSelectionContext = .element(id: UUID(), type: "Test")
        let copy = ctx
        #expect(ctx == copy)
    }

    @Test func editorConfigDefaults() {
        let config = EKEditorConfig()
        #expect(config.minZoom == 0.1)
        #expect(config.maxZoom == 4.0)
        #expect(config.defaultZoom == 1.0)
        #expect(config.sidebarMinWidth == 160)
    }

    @MainActor
    @Test func editorStoreZoom() {
        let store = EditorStore()
        store.setZoom(2.0)
        #expect(store.zoomScale == 2.0)

        store.setZoom(10.0)
        #expect(store.zoomScale == store.config.maxZoom)

        store.setZoom(0.01)
        #expect(store.zoomScale == store.config.minZoom)
    }

    @MainActor
    @Test func editorStoreSelection() {
        let store = EditorStore()
        let id = UUID()
        store.selectElement(id: id, type: "Test")
        #expect(store.selection == .element(id: id, type: "Test"))

        store.clearSelection()
        #expect(store.selection == .none)
    }

    @MainActor
    @Test func selectionManagerBasics() {
        let mgr = SelectionManager()
        let id1 = UUID()
        let id2 = UUID()

        mgr.select(id1)
        #expect(mgr.isSelected(id1))
        #expect(mgr.isSingleSelection)

        mgr.select(id2, additive: true)
        #expect(mgr.selectedIDs.count == 2)
        #expect(!mgr.isSingleSelection)

        mgr.deselect(id1)
        #expect(mgr.singleSelectedID == id2)

        mgr.clearAll()
        #expect(mgr.selectedIDs.isEmpty)
    }
}
