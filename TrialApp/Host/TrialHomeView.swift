import SwiftUI

struct TrialHomeView: View {
    @State private var sampleText = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    VStack(alignment: .leading, spacing: 8) {
                        Image(systemName: "keyboard")
                            .font(.system(size: 42, weight: .light))
                            .foregroundStyle(.tint)
                        Text("Keyboard Trial")
                            .font(.largeTitle.bold())
                        Text("A clean, open-source keyboard powered by OpenKeyboardKit. This first build lets you test the keyboard layout and responsiveness on your iPad.")
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    GroupBox {
                        VStack(alignment: .leading, spacing: 14) {
                            Label("Enable the keyboard", systemImage: "checkmark.circle")
                                .font(.headline)
                            Text("1. Open Settings → General → Keyboard → Keyboards.")
                            Text("2. Tap Add New Keyboard and select Keyboard Trial.")
                            Text("3. Open Notes or tap the editor below and select Keyboard Trial using the globe key.")
                            Text("No Full Access permission is needed for this test.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Test typing here")
                            .font(.headline)
                        TextEditor(text: $sampleText)
                            .scrollContentBackground(.hidden)
                            .frame(minHeight: 160)
                            .padding(8)
                            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 15))
                            .overlay(
                                RoundedRectangle(cornerRadius: 15)
                                    .strokeBorder(.quaternary, lineWidth: 1)
                            )
                        Text("The small toolbar includes buttons that insert sample text. Hebrew typing itself will be added after the layout test.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(24)
                .frame(maxWidth: 700)
                .frame(maxWidth: .infinity)
            }
            .navigationTitle("Keyboard Trial")
        }
        .tint(.indigo)
    }
}
