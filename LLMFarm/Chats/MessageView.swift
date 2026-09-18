//
//  MessageView.swift
//  Created by guinmoon
//


import SwiftUI
import MarkdownUI


struct MessageView: View {
    var message: Message
    @Binding var chatStyle: String
    @State var status: String?

    // Для кнопок "Копировать"
    @State private var copiedAll: Bool = false
    @State private var copiedCode: Bool = false

    private struct SenderView: View {
        var sender: Message.Sender
        var current_model = "LLM"
        
        var body: some View {
            switch sender {
            case .user:
                Text("message.sender.you")
                    .font(.caption)
                    .foregroundColor(.accentColor)
            case .user_rag:
                Text("RAG")
                    .font(.caption)
                    .foregroundColor(.accentColor)
            case .system:
                Text(current_model)
                    .font(.caption)
                    .foregroundColor(.accentColor)
            }
        }
    }

    private struct MessageContentView: View {
        var message: Message
        @Binding var chatStyle: String
        @Binding var status: String?
        var sender: Message.Sender
        @State var showRag = false
        
        var body: some View {
            switch message.state {
            case .none:
                VStack(alignment: .leading) {
                    ProgressView()
                    if status != nil{
                        Text(status!)
                            .font(.footnote)
                    }
                }

            case .error:
                Text(message.text)
                    .foregroundColor(Color.red)
                    .textSelection(.enabled)

            case .typed:
                VStack(alignment: .leading) {
                    if message.header != ""{
                        Text(message.header)
                            .font(.footnote)
                            .foregroundColor(Color.gray)
                            .textSelection(.enabled)
                    }
                    MessageImage(message: message)
                    if sender == .user_rag{
                        VStack{
                            Button(
                                action: {
                                    showRag = !showRag
                                },
                                label: {
                                    if showRag{
                                        Text("message.hide")
                                            .font(.footnote)
                                    }else{
                                        Text("message.showText")
                                            .font(.footnote)
                                    }
                                }
                            )
                            .buttonStyle(.borderless)
                            if showRag{
                                Text(LocalizedStringKey(message.text)).font(.footnote).textSelection(.enabled)
                            }
                        }.textSelection(.enabled)
                    }else{
                        Text(LocalizedStringKey(message.text))
                            .textSelection(.enabled)
                    }
                }.textSelection(.enabled)

            case .predicting:
                HStack {
                    Text(message.text).textSelection(.enabled)
                    ProgressView()
                        .padding(.leading, 3.0)
                        .frame(maxHeight: .infinity,alignment: .bottom)
                }.textSelection(.enabled)

            case .predicted(totalSecond: let totalSecond):
                VStack(alignment: .leading) {
                    switch chatStyle {
                    case "DocC":
                        Markdown(message.text).markdownTheme(.docC).textSelection(.enabled)
                    case "Basic":
                        Markdown(message.text).markdownTheme(.basic).textSelection(.enabled)
                    case "GitHub":
                        Markdown(message.text).markdownTheme(.gitHub).textSelection(.enabled)
                    default:
                        Text(message.text).textSelection(.enabled).textSelection(.enabled)
                    }
                    if (message.tokens_count==0){
                        Text(String(
                            format: NSLocalizedString("message.stats.timeAndSpeed", comment: "Статистика генерации: время и скорость, токенов/сек"),
                            totalSecond,
                            message.tok_sec
                        ))
                            .font(.footnote)
                            .foregroundColor(Color.gray)
                    }else{
                        Text(String(
                            format: NSLocalizedString("message.stats.tokensTimeSpeed", comment: "Статистика генерации: количество токенов, время и скорость"),
                            message.tokens_count,
                            totalSecond,
                            message.tok_sec
                        ))
                            .font(.footnote)
                            .foregroundColor(Color.gray)
                    }
                }.textSelection(.enabled)
            }
        }
    }

    var body: some View {
        HStack {
            if message.sender == .user {
                Spacer()
            }

            VStack(alignment: .leading, spacing: 6.0) {
                SenderView(sender: message.sender)
                MessageContentView(message: message, 
                                   chatStyle: $chatStyle,
                                   status:$status,
                                   sender: message.sender)
                    .padding(12.0)
                    .background(Color.secondary.opacity(0.2))
                    .cornerRadius(12.0)
                
                // Кнопки «Копировать» — только для готовых ответов LLM
                if message.sender == .system {
                    if case .predicted = message.state {
                        HStack(spacing: 14) {
                            copyAllButton
                            if !codeBlocks.isEmpty {
                                copyCodeButton
                            }
                            Spacer()
                        }
                    }
                }
            }

            if message.sender == .system {
                Spacer()
            }
        }
    }
    
    // MARK: - Блоки кода в тексте сообщения
    
    /// Все блоки ```...``` из Markdown-текста, склеенные построчно.
    /// Строку с указанием языка (```swift, ```python) пропускает.
    private var codeBlocks: [String] {
        MessageView.extractCodeBlocks(from: message.text)
    }
    
    // MARK: - Кнопки копирования
    
    private var copyAllButton: some View {
        Button {
            copyToClipboard(message.text)
            withAnimation(.easeInOut(duration: 0.15)) {
                copiedAll = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation(.easeInOut(duration: 0.15)) {
                    copiedAll = false
                }
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: copiedAll ? "checkmark" : "doc.on.doc")
                    .font(.footnote)
                    .foregroundColor(copiedAll ? .green : .secondary)
                Text(LocalizedStringKey(copiedAll
                                        ? "message.copied.all"
                                        : "message.copy.all"))
                    .font(.caption2)
                    .foregroundColor(copiedAll ? .green : .secondary)
            }
        }
        .buttonStyle(.plain)
    }
    
    private var copyCodeButton: some View {
        Button {
            let code = codeBlocks.joined(separator: "\n\n")
            copyToClipboard(code)
            withAnimation(.easeInOut(duration: 0.15)) {
                copiedCode = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation(.easeInOut(duration: 0.15)) {
                    copiedCode = false
                }
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: copiedCode ? "checkmark" : "chevron.left.forwardslash.chevron.right")
                    .font(.footnote)
                    .foregroundColor(copiedCode ? .green : .secondary)
                Text(LocalizedStringKey(copiedCode
                                        ? "message.copied.code"
                                        : "message.copy.code"))
                    .font(.caption2)
                    .foregroundColor(copiedCode ? .green : .secondary)
            }
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Буфер обмена
    
    private func copyToClipboard(_ text: String) {
#if os(macOS)
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(text, forType: .string)
#else
        UIPasteboard.general.string = text
#endif
    }
    
    // MARK: - Разбор блоков кода
    
    /// Возвращает содержимое всех блоков ```...``` из текста.
    /// Строку с указанием языка (```swift, ```python и т.п.) пропускает.
    static func extractCodeBlocks(from text: String) -> [String] {
        var blocks: [String] = []
        let lines = text.components(separatedBy: "\n")
        var inCode = false
        var current: [String] = []
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("```") {
                if inCode {
                    // Закрывающая ```
                    if !current.isEmpty {
                        blocks.append(current.joined(separator: "\n"))
                    }
                    current = []
                    inCode = false
                } else {
                    // Открывающая ```
                    inCode = true
                    current = []
                }
            } else if inCode {
                current.append(line)
            }
        }
        
        // Если блок не был закрыт — всё равно добавим
        if inCode && !current.isEmpty {
            blocks.append(current.joined(separator: "\n"))
        }
        
        return blocks
    }
}

// struct MessageView_Previews: PreviewProvider {
//     static var previews: some View {
//         VStack {
//             MessageView(message: Message(sender: .user, state: .none, text: "none", tok_sec: 0))
//             MessageView(message: Message(sender: .user, state: .error, text: "error", tok_sec: 0))
//             MessageView(message: Message(sender: .user, state: .predicting, text: "predicting", tok_sec: 0))
//             MessageView(message: Message(sender: .user, state: .predicted(totalSecond: 3.1415), text: "predicted", tok_sec: 0))
//         }
//     }
// }
