import SwiftUI

/// First-run onboarding cards.
/// macOS-compatible implementation using horizontal ScrollView + paging (no PageTabViewStyle, which is unavailable on macOS).
struct OnboardingView: View {
    var onComplete: () -> Void
    @State private var currentPage: Int = 0

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "cube.fill",
            title: "Your Speedcubing HUD",
            body: "See OLL, PLL, and F2L algorithms instantly while solving. Always on top, never steals focus."
        ),
        OnboardingPage(
            icon: "book.fill",
            title: "Algorithm Library",
            body: "57 OLL + 21 PLL cases always one glance away. Primary alg + alternatives with move counts."
        ),
        OnboardingPage(
            icon: "target",
            title: "Train Your Recognition",
            body: "Random cases appear. Recall the alg from memory, then reveal and score yourself to improve."
        )
    ]

    var body: some View {
        VStack(spacing: 12) {
            // Swipeable content
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 0) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { idx, page in
                        VStack(spacing: 14) {
                            Image(systemName: page.icon)
                                .font(.system(size: 52))
                                .foregroundStyle(Color.accentColor)
                                .padding(.top, 12)

                            Text(page.title)
                                .font(.system(size: 20, weight: .semibold, design: .rounded))

                            Text(page.body)
                                .font(.system(size: 13))
                                .multilineTextAlignment(.center)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: 260)
                                .padding(.horizontal, 16)

                            Spacer()
                        }
                        .frame(width: 300, height: 180)
                        .id(idx)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.paging)
            .frame(height: 200)

            // Page dots
            HStack(spacing: 8) {
                ForEach(0..<pages.count, id: \.self) { i in
                    Circle()
                        .fill(i == currentPage ? Color.primary : Color.secondary.opacity(0.3))
                        .frame(width: 6, height: 6)
                }
            }

            // Get Started on last page
            if currentPage == pages.count - 1 {
                Button(action: onComplete) {
                    Text("Get Started")
                        .font(.system(size: 14, weight: .semibold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.regular)
                .padding(.horizontal, 40)
                .padding(.top, 4)
            } else {
                Button("Next") {
                    withAnimation { currentPage = min(currentPage + 1, pages.count - 1) }
                }
                .font(.caption)
                .padding(.top, 4)
            }
        }
        .padding(12)
        .frame(width: 320)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .onAppear {
            // keep currentPage in sync if user swipes (SwiftUI paging updates via drag, we use simple dots)
        }
    }
}

private struct OnboardingPage {
    let icon: String
    let title: String
    let body: String
}
