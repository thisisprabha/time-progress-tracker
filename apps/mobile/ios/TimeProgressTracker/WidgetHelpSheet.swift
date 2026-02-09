import SwiftUI

struct WidgetHelpSheet: View {
    let section: HomeSection

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Capsule()
                .fill(Color.secondary.opacity(0.3))
                .frame(width: 40, height: 4)
                .frame(maxWidth: .infinity)
                .padding(.top, 8)

            Text("Add \(section.title) widget")
                .font(.sabdeviBold(size: 18))

            VStack(alignment: .leading, spacing: 10) {
                Text("1) Long‑press Home or Lock screen until icons jiggle")
                Text("2) Tap + and search ‘Time Progress’")
                Text("3) Choose the \(section.title) widget size and add")
                Text("4) Optional: edit widgets to pick this section’s style")
            }
            .font(.sabdeviRegular(size: 14))
            .lineSpacing(4)
            .foregroundColor(.secondary)

            Button(action: openWidgetGallery) {
                Text("Go to Home screen")
                    .font(.sabdeviBold(size: 14))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.accentColor))
            }

            Text("We’ll take you to the Home screen so you can long‑press and add the widget.")
                .font(.sabdeviRegular(size: 12))
                .foregroundColor(.secondary)

            Spacer()
        }
        .padding(20)
        .presentationBackground(.ultraThinMaterial)
    }

    private func openWidgetGallery() {
        // There is no public API to deep-link directly to widget gallery.
        // Best effort: jump to the home screen so user can long-press and add.
        UIApplication.shared.perform(#selector(NSXPCConnection.suspend))
    }
}
