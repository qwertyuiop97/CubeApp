import SwiftUI

struct AboutView: View {
    let version: String

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "cube.fill")
                .font(.system(size: 64))
                .foregroundStyle(Color.accentColor)
                .padding(.top, 24)

            Text("CubeNotch")
                .font(.system(size: 24, weight: .semibold, design: .rounded))

            Text("Version \(version)")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text("Made for speedcubers. Built with ❤️")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            Spacer()

            Text("© 2026 CubeNotch")
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .padding(.bottom, 16)
        }
        .frame(width: 400, height: 280)
        .background(.regularMaterial)
    }
}
