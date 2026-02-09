import SwiftUI

struct WidgetInviteCard: View {
    var action: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            Spacer().frame(height: 4)

            Image(systemName: "rectangle.3.offgrid")
                .font(.system(size: 28, weight: .semibold))
                .foregroundColor(.accentColor)

            VStack(spacing: 6) {
                Text("Widgets available")
                    .font(.sabdeviBold(size: 16))
                    .foregroundColor(.primary)
                Text("Tap to see where to add it on Home/Lock screen")
                    .font(.sabdeviRegular(size: 12))
                    .foregroundColor(.secondary)
            }

            Button(action: action) {
                Text("Where to find?")
                    .font(.sabdeviBold(size: 13))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.accentColor)
                    )
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(uiColor: .secondarySystemBackground))
        )
    }
}
