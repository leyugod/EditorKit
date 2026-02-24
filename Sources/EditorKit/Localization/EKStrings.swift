import Foundation

/// Centralized localization strings for EditorKit.
///
/// All UI-facing text is routed through `NSLocalizedString` with
/// the `EditorKit` bundle, so host apps can provide `.lproj` overrides.
public enum EKStrings {

    private static let bundle = Bundle.module

    // MARK: - General

    public static var untitled: String {
        NSLocalizedString("ek.untitled", bundle: bundle, value: "Untitled", comment: "Default document title")
    }

    // MARK: - Inspector

    public static var inspectorPageTitle: String {
        NSLocalizedString("ek.inspector.page_title", bundle: bundle, value: "Page", comment: "Inspector header when no element is selected")
    }

    public static var inspectorSelected: String {
        NSLocalizedString("ek.inspector.selected", bundle: bundle, value: "selected", comment: "Suffix for multi-selection count, e.g. '3 selected'")
    }

    public static var inspectorUnregistered: String {
        NSLocalizedString("ek.inspector.unregistered", bundle: bundle, value: "No Inspector Registered", comment: "Shown when element type has no registered inspector")
    }

    public static var inspectorUnregisteredType: String {
        NSLocalizedString("ek.inspector.unregistered_type", bundle: bundle, value: "Type: %@", comment: "Shows the unregistered element type name")
    }

    // MARK: - Inspector Actions (Multi-Selection)

    public static var actionGroup: String {
        NSLocalizedString("ek.action.group", bundle: bundle, value: "Group", comment: "Group elements action")
    }

    public static var actionAlign: String {
        NSLocalizedString("ek.action.align", bundle: bundle, value: "Align", comment: "Align elements action")
    }

    public static var actionDistribute: String {
        NSLocalizedString("ek.action.distribute", bundle: bundle, value: "Distribute", comment: "Distribute elements action")
    }

    // MARK: - Inspector Sections & Fields

    public static var sectionArrange: String {
        NSLocalizedString("ek.section.arrange", bundle: bundle, value: "Arrange", comment: "Transform/arrange inspector section title")
    }

    public static var fieldWidth: String {
        NSLocalizedString("ek.field.width", bundle: bundle, value: "W", comment: "Width field label")
    }

    public static var fieldHeight: String {
        NSLocalizedString("ek.field.height", bundle: bundle, value: "H", comment: "Height field label")
    }

    public static var fieldRotation: String {
        NSLocalizedString("ek.field.rotation", bundle: bundle, value: "Rotation", comment: "Rotation field label")
    }

    public static var fieldOpacity: String {
        NSLocalizedString("ek.field.opacity", bundle: bundle, value: "Opacity", comment: "Opacity slider label")
    }

    // MARK: - Sidebar

    public static var sidebarTitle: String {
        NSLocalizedString("ek.sidebar.title", bundle: bundle, value: "Pages", comment: "Sidebar header title")
    }

    public static func sidebarPageCount(_ count: Int) -> String {
        String.localizedStringWithFormat(
            NSLocalizedString("ek.sidebar.page_count", bundle: bundle, value: "%d pages", comment: "Sidebar page count"),
            count
        )
    }

    public static var sidebarAddPage: String {
        NSLocalizedString("ek.sidebar.add_page", bundle: bundle, value: "Add Page", comment: "Add page button")
    }

    public static var sidebarNewPageAfter: String {
        NSLocalizedString("ek.sidebar.new_page_after", bundle: bundle, value: "New Page After", comment: "Context menu: insert page after")
    }

    public static var sidebarDuplicatePage: String {
        NSLocalizedString("ek.sidebar.duplicate_page", bundle: bundle, value: "Duplicate Page", comment: "Context menu: duplicate page")
    }

    public static var sidebarDeletePage: String {
        NSLocalizedString("ek.sidebar.delete_page", bundle: bundle, value: "Delete Page", comment: "Context menu: delete page")
    }

    // MARK: - Toolbar

    public static var toolbarUndo: String {
        NSLocalizedString("ek.toolbar.undo", bundle: bundle, value: "Undo", comment: "Undo button tooltip")
    }

    public static var toolbarRedo: String {
        NSLocalizedString("ek.toolbar.redo", bundle: bundle, value: "Redo", comment: "Redo button tooltip")
    }

    public static var toolbarZoomIn: String {
        NSLocalizedString("ek.toolbar.zoom_in", bundle: bundle, value: "Zoom In", comment: "Zoom in button tooltip")
    }

    public static var toolbarZoomOut: String {
        NSLocalizedString("ek.toolbar.zoom_out", bundle: bundle, value: "Zoom Out", comment: "Zoom out button tooltip")
    }

    public static var toolbarZoomToFit: String {
        NSLocalizedString("ek.toolbar.zoom_to_fit", bundle: bundle, value: "Zoom to Fit", comment: "Zoom to fit menu item")
    }

    public static var toolbarToggleSidebar: String {
        NSLocalizedString("ek.toolbar.toggle_sidebar", bundle: bundle, value: "Toggle Sidebar", comment: "Sidebar toggle tooltip")
    }

    public static var toolbarToggleInspector: String {
        NSLocalizedString("ek.toolbar.toggle_inspector", bundle: bundle, value: "Toggle Inspector", comment: "Inspector toggle tooltip")
    }

    public static var toolbarPlay: String {
        NSLocalizedString("ek.toolbar.play", bundle: bundle, value: "Play", comment: "Play/present button label")
    }

    public static var toolbarStartPresentation: String {
        NSLocalizedString("ek.toolbar.start_presentation", bundle: bundle, value: "Start Presentation", comment: "Play button tooltip")
    }
}
