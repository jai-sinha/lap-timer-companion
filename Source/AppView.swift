import SwiftUI

struct AppView: View {
    var body: some View {
        VStack(spacing: 0) {
            Text("Lap Timer Companion")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top, 32)
                .padding(.bottom, 16)
            Divider()
            DeviceListView(viewModel: DeviceListViewModel())
        }
    }
}

struct AppView_Previews: PreviewProvider {
    static var previews: some View {
        AppView()
    }
}
