import SwiftUI

// iOS 26 Liquid Glass UI Component
// This provides the signature translucent, blurred glass effect

struct LiquidGlassBackground: ViewModifier {
    var cornerRadius: CGFloat = 20
    var opacity: Double = 0.2
    
    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    // Base blur
                    if #available(iOS 15.0, macOS 12.0, *) {
                        Rectangle()
                            .fill(.ultraThinMaterial)
                    } else {
                        Color.black.opacity(0.3)
                    }
                    
                    // Glass tint
                    Color.white.opacity(opacity)
                    
                    // Edge highlight for 3D glass effect
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(
                            LinearGradient(
                                colors: [.white.opacity(0.5), .clear, .white.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 5)
    }
}

extension View {
    func liquidGlass(cornerRadius: CGFloat = 20, opacity: Double = 0.1) -> some View {
        self.modifier(LiquidGlassBackground(cornerRadius: cornerRadius, opacity: opacity))
    }
}
