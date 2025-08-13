import SwiftUI

struct ContentView: View {
    @EnvironmentObject var model: ChatModel
    @State private var input: String = ""

    private let headerHeight: CGFloat = 34

    var body: some View {
        ZStack(alignment: .topLeading) {
            VStack(spacing: 0) {
                chatList
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .padding(.top, headerHeight) // keep content below header

            header
        }
        .background(Color.black.ignoresSafeArea())
        .preferredColorScheme(.dark)
        .safeAreaInset(edge: .bottom) { inputBar.background(Color.black) }
    }

    var header: some View {
        HStack {
            Text("ottotext")
                .font(.system(size: 16, weight: .semibold, design: .monospaced))
                .foregroundColor(.green)
            Spacer()
        }
        .padding(.horizontal)
        .padding(.top, 6)
        .frame(height: headerHeight, alignment: .bottom)
    }

    var chatList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 8) {
                    ForEach(model.messages) { m in
                        MessageRow(entry: m)
                            .id(m.id)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 12)
            }
            .onChange(of: model.messages.count) { _ in
                if let last = model.messages.last?.id {
                    withAnimation { proxy.scrollTo(last, anchor: .bottom) }
                }
            }
        }
    }

    var inputBar: some View {
        HStack(spacing: 8) {
            TextField("Type Turkish…", text: $input)
                .textFieldStyle(.roundedBorder)
                .textInputAutocapitalization(.sentences)
                .keyboardType(.default)
                .disableAutocorrection(false)
                .onSubmit(send)
            Button(action: send) {
                Image(systemName: "arrow.up.circle.fill").font(.system(size: 26))
            }
            .disabled(input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding([.horizontal, .top])
        .padding(.bottom, 8)
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
