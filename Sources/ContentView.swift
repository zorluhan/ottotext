import SwiftUI

struct ContentView: View {
    @EnvironmentObject var model: ChatModel
    @State private var input: String = ""
    @State private var showKeySheet: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider().background(Color.green.opacity(0.5))
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 8) {
                        ForEach(model.messages) { m in
                            MessageRow(entry: m)
                                .id(m.id)
                        }
                    }.padding(.horizontal)
                }
                .onChange(of: model.messages.count) { _ in
                    if let last = model.messages.last?.id {
                        withAnimation { proxy.scrollTo(last, anchor: .bottom) }
                    }
                }
            }
            inputBar
        }
        .background(Color.black.edgesIgnoringSafeArea(.all))
        .preferredColorScheme(.dark)
        .onAppear { if model.messages.isEmpty { model.addSystem("Ottotext ready. Paste your API key if prompted (key icon).") } }
    }

    var header: some View {
        HStack {
            Text("ottotext")
                .font(.system(.headline, design: .monospaced))
                .foregroundColor(.green)
            Spacer()
            Button(action: { showKeySheet = true }) {
                Image(systemName: "key.fill").foregroundColor(.green)
            }
            .sheet(isPresented: $showKeySheet) {
                VStack(spacing: 12) {
                    Text("Google Gemini API Key").font(.headline)
                    SecureField("paste key", text: $model.apiKey)
                        .textFieldStyle(.roundedBorder)
                    Button("Save") { showKeySheet = false }
                }
                .padding()
                .presentationDetents([.medium])
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }

    var inputBar: some View {
        HStack(spacing: 8) {
            TextField("Type Turkish…", text: $input)
                .textFieldStyle(.roundedBorder)
                .onSubmit(send)
            Button(action: send) {
                Image(systemName: "arrow.up.circle.fill").font(.system(size: 26))
            }
            .disabled(input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding()
    }

    func send() {
        let text = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        model.addUser(text)
        Task { await model.convert(text: text) }
        input = ""
    }
}

struct MessageRow: View {
    let entry: ChatEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("[\(entry.timeString)] * \(entry.role) *")
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.gray)
            Text(entry.text)
                .font(.system(.body, design: .monospaced))
                .foregroundColor(.green)
                .textSelection(.enabled)
        }
    }
}
