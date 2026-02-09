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

            Text("1) Long‑press Home/Lock screen\n2) Tap + and search ‘Time Progress’\n3) Pick the \(section.title) widget size")
                .font(.sabdeviRegular(size: 14))
                .foregroundColor(.secondary)

            Button(action: openWidgetGallery) {
                Text("Open widget picker")
                    .font(.sabdeviBold(size: 14))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.accentColor))
            }

            Spacer()
        }
        .padding(20)
        .presentationBackground(.ultraThinMaterial)
    }

    private func openWidgetGallery() {
        // There is no public API to deep-link directly to widget gallery.
        // As a best-effort, open the app’s settings page to hint; user can then long-press home.
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
}
