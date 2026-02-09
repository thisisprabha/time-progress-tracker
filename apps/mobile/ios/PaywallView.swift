import SwiftUI

struct PaywallView: View {
    @EnvironmentObject var purchaseManager: PurchaseManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 24) {
            Text("Unlock Pro")
                .font(.sabdeviBold(size: 24))

            VStack(alignment: .leading, spacing: 8) {
                bullet("Unlimited countdowns, count ups, habits")
                bullet("All widgets, including Habits & Leave")
                bullet("Multiple reminders per event")
            }

            if purchaseManager.purchaseInFlight {
                ProgressView()
            }

            Button(action: { Task { await purchaseManager.purchase() } }) {
                Text("Unlock (one-time)")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)

            Button("Restore") { Task { await purchaseManager.restore() } }
                .buttonStyle(.bordered)

            Button("Not now") { dismiss() }
                .foregroundStyle(.secondary)
        }
        .padding(24)
        .presentationDetents([.fraction(0.5)])
    }

    private func bullet(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "checkmark.circle.fill").foregroundStyle(.secondary)
            Text(text)
                .font(.sabdeviRegular(size: 15))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
