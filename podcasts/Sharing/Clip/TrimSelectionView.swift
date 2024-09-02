import SwiftUI

struct TrimSelectionView: View {
    @Binding var leading: CGFloat
    @Binding var trailing: CGFloat
    let handleWidth: CGFloat
    let indicatorWidth: CGFloat

    let changed: (CGFloat, TrimHandle.Side) -> Void

    private enum Constants {
        static let borderWidth: CGFloat = 4
    }

    var body: some View {
        ZStack(alignment: .leading) {
            Rectangle()
                .foregroundColor(Color.clear)
                .border(.tint, width: Constants.borderWidth)
                // Offset and frame are adjusted to hide this rectangle behind the Trim Handles
                .frame(width: (trailing - leading + indicatorWidth) + (Constants.borderWidth * 2))
                .offset(x: leading - Constants.borderWidth)
            TrimHandle(position: $leading, side: .leading, width: handleWidth, onChanged: { changed($0, .leading) })
            TrimHandle(position: $trailing, side: .trailing, width: handleWidth, onChanged: { changed( $0, .trailing) })
        }
    }
}
