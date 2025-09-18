import SwiftUI
import Foundation

struct AppMessageView: View {
    @ObservedObject var viewModel: AppMessageViewModel
    var onCommandSelected: ((TableEntry) -> Void)?
    
    var body: some View {
        VStack(spacing: 0) {
            List(viewModel.tableEntries, id: \.label) { entry in
                Button(action: {
                    onCommandSelected?(entry)
                }) {
                    Text(entry.label)
                }
            }
            .listStyle(PlainListStyle())
            .frame(maxHeight: 300)
            Divider()
            ScrollView {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(viewModel.logMessages, id: \.self) { msg in
                        Text(msg)
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(8)
            }
            .background(Color(.systemGray6))
        }
    }
}

// Preview for SwiftUI canvas
#Preview {
    let entries = [TableEntry(label: "Test", message: "Hello" as AnyObject)]
    let vm = AppMessageViewModel(tableEntries: entries, logMessages: ["Log 1", "Log 2"])
    AppMessageView(viewModel: vm)
}
