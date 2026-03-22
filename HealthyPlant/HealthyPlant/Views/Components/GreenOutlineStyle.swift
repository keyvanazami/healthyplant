import SwiftUI

// MARK: - Green Outline ViewModifier

struct GreenOutlineModifier: ViewModifier {
    var cornerRadius: CGFloat = 12

    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(Theme.accent, lineWidth: Theme.outlineWidth)
            )
    }
}

extension View {
    func greenOutline(cornerRadius: CGFloat = 12) -> some View {
        modifier(GreenOutlineModifier(cornerRadius: cornerRadius))
    }
}

// MARK: - Green Outline Button Style

struct GreenOutlineButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .foregroundColor(Theme.accent)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(Theme.accent, lineWidth: Theme.outlineWidth)
            )
            .opacity(configuration.isPressed ? 0.6 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Green Filled Button Style

struct GreenFilledButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .foregroundColor(.black)
            .fontWeight(.semibold)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Theme.accent)
            )
            .opacity(configuration.isPressed ? 0.7 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == GreenOutlineButtonStyle {
    static var greenOutline: GreenOutlineButtonStyle { GreenOutlineButtonStyle() }
}

extension ButtonStyle where Self == GreenFilledButtonStyle {
    static var greenFilled: GreenFilledButtonStyle { GreenFilledButtonStyle() }
}
