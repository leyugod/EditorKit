// EditorKit — A SwiftUI Editor Framework
// Swift 6 + SwiftUI + MVVM
// Platforms: macOS 15+ / iOS 18+

/// EditorKit provides a composable, protocol-oriented editor framework
/// for building document-based applications with a three-pane layout,
/// canvas system, inspector registry, toolbar, and sidebar.
///
/// ## Quick Start
///
/// 1. Define your element model conforming to ``EKElement``
/// 2. Define your page model conforming to ``EKPage``
/// 3. Optionally subclass ``EKBaseDocument`` for undo/redo support
/// 4. Register inspectors via ``EKInspectorRegistry``
/// 5. Assemble your UI with ``EditorView``
///
/// See the Examples directory for a complete Presentation app demo.

@_exported import SwiftUI

// MARK: - Version

public enum EditorKit {
    public static let version = "1.0.0"
}
