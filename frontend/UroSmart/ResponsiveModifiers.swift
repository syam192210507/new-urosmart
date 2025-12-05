import SwiftUI

// MARK: - Device Detection
enum DeviceType {
    case iPhone_SE
    case iPhone_Standard
    case iPhone_Plus
    case iPhone_Pro_Max
    case iPad
    
    static var current: DeviceType {
        let screenHeight = Swift.max(UIScreen.main.bounds.width, UIScreen.main.bounds.height)
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            return .iPad
        }
        
        // iPhone detection based on screen height
        if screenHeight <= 667 { // iPhone SE, 8
            return .iPhone_SE
        } else if screenHeight <= 736 { // iPhone 8 Plus
            return .iPhone_Plus
        } else if screenHeight <= 844 { // iPhone 12/13/14
            return .iPhone_Standard
        } else if screenHeight <= 896 { // iPhone 11 Pro Max, XS Max
            return .iPhone_Pro_Max
        } else { // iPhone 14 Pro Max (932) and larger
            return .iPhone_Pro_Max
        }
    }
    
    var isSmallDevice: Bool {
        self == .iPhone_SE
    }
    
    var isLargeDevice: Bool {
        self == .iPhone_Pro_Max || self == .iPad
    }
}

// MARK: - Responsive Sizing
struct ResponsiveSize {
    static let shared = ResponsiveSize()
    
    private var screenWidth: CGFloat {
        UIScreen.main.bounds.width
    }
    
    private var screenHeight: CGFloat {
        UIScreen.main.bounds.height
    }
    
    // Base reference: iPhone 14 (390 x 844)
    private let baseWidth: CGFloat = 390
    private let baseHeight: CGFloat = 844
    
    /// Scale factor based on screen width
    var widthScale: CGFloat {
        screenWidth / baseWidth
    }
    
    /// Scale factor based on screen height
    var heightScale: CGFloat {
        screenHeight / baseHeight
    }
    
    /// Scaled value based on width
    func scaledWidth(_ value: CGFloat) -> CGFloat {
        value * widthScale
    }
    
    /// Scaled value based on height
    func scaledHeight(_ value: CGFloat) -> CGFloat {
        value * heightScale
    }
    
    /// Scaled font size that respects accessibility settings
    func scaledFont(_ size: CGFloat, minSize: CGFloat? = nil, maxSize: CGFloat? = nil) -> CGFloat {
        var scaledSize = size * Swift.min(widthScale, heightScale)
        
        if let minVal = minSize {
            scaledSize = Swift.max(scaledSize, minVal)
        }
        if let maxVal = maxSize {
            scaledSize = Swift.min(scaledSize, maxVal)
        }
        
        return scaledSize
    }
    
    /// Horizontal padding that scales with screen width
    var horizontalPadding: CGFloat {
        switch DeviceType.current {
        case .iPhone_SE:
            return 16
        case .iPhone_Standard:
            return 20
        case .iPhone_Plus, .iPhone_Pro_Max:
            return 24
        case .iPad:
            return 40
        }
    }
    
    /// Card corner radius scaled appropriately
    var cardCornerRadius: CGFloat {
        switch DeviceType.current {
        case .iPhone_SE:
            return 16
        case .iPad:
            return 24
        default:
            return 20
        }
    }
}

// MARK: - Responsive View Modifiers

/// Adaptive padding modifier
struct AdaptivePadding: ViewModifier {
    let edges: Edge.Set
    let baseValue: CGFloat
    
    func body(content: Content) -> some View {
        content.padding(edges, ResponsiveSize.shared.scaledWidth(baseValue))
    }
}

/// Responsive font modifier
struct ResponsiveFont: ViewModifier {
    let size: CGFloat
    let weight: Font.Weight
    let minSize: CGFloat?
    let maxSize: CGFloat?
    
    init(size: CGFloat, weight: Font.Weight = .regular, min: CGFloat? = nil, max: CGFloat? = nil) {
        self.size = size
        self.weight = weight
        self.minSize = min
        self.maxSize = max
    }
    
    func body(content: Content) -> some View {
        content.font(.system(size: ResponsiveSize.shared.scaledFont(size, minSize: minSize, maxSize: maxSize), weight: weight))
    }
}

// MARK: - View Extensions
extension View {
    /// Adaptive padding that scales with device size
    func adaptivePadding(_ edges: Edge.Set = .all, _ value: CGFloat = 16) -> some View {
        modifier(AdaptivePadding(edges: edges, baseValue: value))
    }
    
    /// Responsive font that scales with device size
    func responsiveFont(size: CGFloat, weight: Font.Weight = .regular, minSize: CGFloat? = nil, maxSize: CGFloat? = nil) -> some View {
        modifier(ResponsiveFont(size: size, weight: weight, min: minSize, max: maxSize))
    }
    
    /// Frame that scales with device size
    func responsiveFrame(width: CGFloat? = nil, height: CGFloat? = nil) -> some View {
        self.frame(
            width: width.map { ResponsiveSize.shared.scaledWidth($0) },
            height: height.map { ResponsiveSize.shared.scaledHeight($0) }
        )
    }
    
    /// Conditional modifier for different device types
    @ViewBuilder
    func ifDevice(_ type: DeviceType, apply modifier: (Self) -> some View) -> some View {
        if DeviceType.current == type {
            modifier(self)
        } else {
            self
        }
    }
    
    /// Apply different modifiers for small vs large devices
    @ViewBuilder
    func adaptiveLayout(
        small: ((Self) -> AnyView)? = nil,
        large: ((Self) -> AnyView)? = nil
    ) -> some View {
        if DeviceType.current.isSmallDevice, let smallModifier = small {
            smallModifier(self)
        } else if DeviceType.current.isLargeDevice, let largeModifier = large {
            largeModifier(self)
        } else {
            self
        }
    }
}

// MARK: - Responsive Spacing
enum ResponsiveSpacing {
    case xxSmall  // 4
    case xSmall   // 8
    case small    // 12
    case medium   // 16
    case large    // 20
    case xLarge   // 24
    case xxLarge  // 32
    
    var value: CGFloat {
        let base: CGFloat = {
            switch self {
            case .xxSmall: return 4
            case .xSmall: return 8
            case .small: return 12
            case .medium: return 16
            case .large: return 20
            case .xLarge: return 24
            case .xxLarge: return 32
            }
        }()
        
        return ResponsiveSize.shared.scaledWidth(base)
    }
}

// MARK: - Responsive Layout Container
struct AdaptiveStack<Content: View>: View {
    let horizontalThreshold: CGFloat
    let spacing: CGFloat
    let content: () -> Content
    
    init(
        horizontalThreshold: CGFloat = 500,
        spacing: CGFloat = 16,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.horizontalThreshold = horizontalThreshold
        self.spacing = spacing
        self.content = content
    }
    
    var body: some View {
        GeometryReader { geometry in
            if geometry.size.width > horizontalThreshold {
                HStack(spacing: spacing) {
                    content()
                }
            } else {
                VStack(spacing: spacing) {
                    content()
                }
            }
        }
    }
}

// MARK: - Safe Area Aware Container
struct SafeAreaContainer<Content: View>: View {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass
    
    let content: () -> Content
    
    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }
    
    var body: some View {
        GeometryReader { geometry in
            content()
                .frame(maxWidth: maxContentWidth(for: geometry))
                .frame(maxWidth: .infinity)
        }
    }
    
    private func maxContentWidth(for geometry: GeometryProxy) -> CGFloat {
        // On iPad, limit content width for better readability
        if UIDevice.current.userInterfaceIdiom == .pad {
            return min(geometry.size.width - 80, 700)
        }
        return geometry.size.width
    }
}

// MARK: - Preview Helpers
#if DEBUG
struct ResponsivePreview<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        Group {
            content
                .previewDevice("iPhone SE (3rd generation)")
                .previewDisplayName("iPhone SE")
            
            content
                .previewDevice("iPhone 14")
                .previewDisplayName("iPhone 14")
            
            content
                .previewDevice("iPhone 14 Pro Max")
                .previewDisplayName("iPhone 14 Pro Max")
            
            content
                .previewDevice("iPad Pro (11-inch) (4th generation)")
                .previewDisplayName("iPad Pro 11\"")
        }
    }
}
#endif
