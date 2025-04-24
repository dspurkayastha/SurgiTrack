import SwiftUI
import Foundation
import SVGView

struct LaunchScreenView: View {
    var body: some View {
        ZStack {
            // Animated SVG background
            SVGView(contentsOf: Bundle.main.url(forResource: "SurgiTrackLogo", withExtension: "svg")!)
                .aspectRatio(contentMode: .fit)
                .frame(width: 320, height: 320)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

#Preview {
    LaunchScreenView()
}
