import SwiftUI
import Foundation
import SVGView

struct LaunchScreenView: View {
    var body: some View {
        ZStack {
            // Animated SVG background
            if let logoURL = Bundle.main.url(forResource: "SurgiTrackLogo", withExtension: "svg") {
                SVGView(contentsOf: logoURL)
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 320, height: 320)
            } else {
                // Fallback view if SVG is not found
                Image(systemName: "stethoscope")
                    .font(.system(size: 120))
                    .foregroundColor(.gray)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

#Preview {
    LaunchScreenView()
}
