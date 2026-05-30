import SwiftUI

/// Common rooms / locations shown in the dropdown. "Custom..." opens a free-text field.
enum PlantLocation {
    static let presets: [String] = [
        "Living Room",
        "Bedroom",
        "Kitchen",
        "Bathroom",
        "Office",
        "Dining Room",
        "Patio",
        "Balcony",
        "Backyard",
        "Front Yard",
        "Greenhouse",
    ]
}

/// Form section that lets the user pick a typical room from a menu or enter a custom string.
/// `location` is the canonical bound value: nil means "no location set", otherwise any string.
struct LocationPickerSection: View {
    @Binding var location: String?
    @State private var customDraft: String = ""
    @FocusState private var customFocused: Bool

    private var isCustom: Bool {
        guard let loc = location, !loc.isEmpty else { return false }
        return !PlantLocation.presets.contains(loc)
    }

    private var menuLabel: String {
        if let loc = location, !loc.isEmpty { return loc }
        return "Choose a room"
    }

    var body: some View {
        Section("Location") {
            Menu {
                Button("None") { location = nil }
                ForEach(PlantLocation.presets, id: \.self) { preset in
                    Button(preset) {
                        location = preset
                        customDraft = ""
                    }
                }
                Divider()
                Button("Custom…") {
                    customDraft = isCustom ? (location ?? "") : ""
                    location = customDraft
                    customFocused = true
                }
            } label: {
                HStack {
                    Image(systemName: "mappin.and.ellipse")
                        .foregroundColor(Theme.accent)
                    Text(menuLabel)
                        .foregroundColor(location == nil ? Theme.textSecondary : Theme.textPrimary)
                    Spacer()
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption)
                        .foregroundColor(Theme.textSecondary)
                }
            }

            if isCustom {
                TextField("Custom location", text: Binding(
                    get: { location ?? "" },
                    set: { location = $0.isEmpty ? nil : $0 }
                ))
                .focused($customFocused)
                .foregroundColor(Theme.textPrimary)
            }
        }
        .listRowBackground(Color.white.opacity(0.05))
    }
}
