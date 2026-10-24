import SwiftUI

/// Tiled dark dirt, the classic menu background.
struct DirtBackground: View {
    var body: some View {
        Image(nsImage: Sprites.dirtTile)
            .interpolation(.none)
            .resizable(resizingMode: .tile)
            .ignoresSafeArea()
    }
}
