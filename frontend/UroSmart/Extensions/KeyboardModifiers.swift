import SwiftUI

/// Extension to fix Auto Layout constraint conflicts caused by iOS keyboard input accessory view
extension View {
    /// Disables the keyboard accessory view (autocomplete/suggestions bar) to prevent constraint conflicts
    /// This fixes the "assistantHeight" SystemInputAssistantView.height == 45 constraint warning
    func disableKeyboardAccessory() -> some View {
        // Disable autocorrection which also suppresses the keyboard accessory view
        // This prevents the 45pt height constraint conflict
        self.autocorrectionDisabled(true)
    }
}
