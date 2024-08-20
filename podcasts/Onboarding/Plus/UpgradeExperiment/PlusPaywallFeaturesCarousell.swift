import SwiftUI
import PocketCastsServer

struct PlusPaywallFeaturesCarousell: View {
    @ObservedObject var viewModel: PlusLandingViewModel

    let tier: UpgradeTier

    private var title: some View {
        Text(tier.header)
            .font(size: Constants.titleSize, style: .body, weight: .bold)
            .foregroundStyle(.white)
            .multilineTextAlignment(.center)
            .lineLimit(Constants.titleLineLimit)
            .padding(.horizontal, Constants.titleHPadding)
            .padding(.bottom, Constants.bottomPadding)
    }

    private var badge: some View {
        SubscriptionBadge(tier: tier.tier, displayMode: .gradient, foregroundColor: .black)
            .padding(.bottom, Constants.badgeBottomPadding)
    }

    var body: some View {
        ScrollView {
            badge
            title
            Rectangle()
                .fill(.red)
                .frame(height: 394)
        }
    }

    private enum Constants {
        static let bottomPadding = 16.0

        static let badgeBottomPadding = 12.0

        static let titleSize = 22.0
        static let titleLineLimit = 2
        static let titleHPadding = 32.0
        static let titleBottomPadding = 40.0
    }
}

#Preview {
    PlusPaywallFeaturesCarousell(viewModel: PlusLandingViewModel(source: .login), tier: .plus)
}