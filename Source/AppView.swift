//
//  AppView.swift
//  LapTimerCompanion
//
//  Created by Jai Sinha on 9/18/25.


import SwiftUI

struct AppView: View {
    private let appMessageViewModel = AppMessageViewModel()
    var body: some View {
        VStack(spacing: 0) {
            Text("Lap Timer Companion")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top, 32)
                .padding(.bottom, 16)
            Divider()
            DeviceListView(viewModel: DeviceListViewModel())
            Divider()
            AppMessageView(viewModel: appMessageViewModel)
        }
    }
}

struct AppView_Previews: PreviewProvider {
    static var previews: some View {
        AppView()
    }
}
