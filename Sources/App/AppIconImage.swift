import SwiftUI
import UIKit

/// The SproutLab icon, loaded from the SwiftPM resource bundle (Bundle.module).
struct AppIconImage: View {
    var body: some View {
        if let path = Bundle.module.path(forResource: "AppIcon", ofType: "png"),
           let image = UIImage(contentsOfFile: path) {
            Image(uiImage: image)
                .resizable()
                .frame(width: 40, height: 40)
                .clipShape(RoundedRectangle(cornerRadius: 9))
                .accessibilityHidden(true)
        }
    }
}
