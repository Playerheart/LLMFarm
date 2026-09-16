//
//  ChatView.swift
//
//  Created by Guinmoon
//

import SwiftUI

struct ChatView: View {
    
    @EnvironmentObject var aiChatModel: AIChatModel
    @EnvironmentObject var orientationInfo: OrientationInfo
    
    @State var placeholderString: String = "Type your message..."
    @State private var inputText: String = "Type your message..."
    
    @Binding var modelName: String
    @Binding var chatSelection: Dictionary<String, String>?
    @Binding var title: String
    var CloseChat: () -> Void
    @Binding var AfterChatEdit: () -> Void
    @Binding var addChatDialog: Bool
    @Binding var editChatDialog: Bool
    @State var chatStyle: String = "None"
    @State private var reloadButtonIcon: String = "arrow.counterclockwise.circle"
    @State private var clearChatButtonIcon: String = "eraser.line.dashed.fill"
    
    @State private var scrollProxy: ScrollViewProxy? = nil
    @State private var scrollTarget: Int?
    @State private var toggleEditChat = false
    @State private var clearChatAlert = false
    @State private var autoScroll = true
    @State private var enableRAG = false

    @FocusState var focusedField: Field?
    @Namespace var bottomID
    
    @FocusState
    private var isInputFieldFocused: Bool
    
    // MARK: - Status overlay helpers
    
    private var isWorking: Bool {
        switch aiChatModel.state {
        case .loading, .ragIndexLoading, .ragSearch:
            return true
        default:
            return false
        }
    }
    
    private var statusText: String {
        switch aiChatModel.state {
        case .loading:
            return "Loading model into memory…"
        case .ragIndexLoading:
            return "Loading RAG index…"
        case .ragSearch:
            return "Searching documents…"
        default:
            return ""
        }
    }
    
    private var statusPercentText: String? {
        switch aiChatModel.state {
        case .loading, .ragIndexLoading:
            return "\(Int(aiChatModel.load_progress * 100))%"
        default:
            return nil
        }
    }
    
    private var showsDeterminateProgress: Bool {
        switch aiChatModel.state {
        case .loading, .ragIndexLoading:
            return true
        default:
            return false
        }
    }
    
    @ViewBuilder
    private var statusOverlay: some View {
        if isWorking {
            VStack(spacing: 6) {
                HStack(spacing: 10) {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .scaleEffect(0.8)
                    Text(statusText)
                        .font(.footnote)
                        .foregroundColor(.accentColor)
                        .lineLimit(1)
                    if let pct = statusPercentText {
                        Text(pct)
                            .font(.footnote)
                            .foregroundColor(.accentColor)
                            .monospacedDigit()
                    }
                }
                if showsDeterminateProgress {
                    ProgressView(value: aiChatModel.load_progress)
                        .progressViewStyle(.linear)
                        .tint(.accentColor)
                        .frame(maxWidth: 280)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.accentColor.opacity(0.12))
            )
            .padding(.top, 4)
            .transition(.opacity.combined(with: .move(edge: .top)))
        }
    }
    
    // MARK: - Scroll helpers
    
    func scrollToBottom(with_animation: Bool = false) {
        var scroll_bug = true
#if os(macOS)
        scroll_bug = false
#else
        if #available(iOS 16.4, *){
            scroll_bug = false
        }
#endif
        if scroll_bug { return }
        if !autoScroll { return }
        let last_msg = aiChatModel.messages.last
        if last_msg != nil && last_msg?.id != nil && scrollProxy != nil {
            if with_animation {
                withAnimation {
                    scrollProxy?.scrollTo("latest")
                }
            } else {
                scrollProxy?.scrollTo("latest")
            }
        }
    }
    
    func reload() async {
        if chatSelection == nil { return }
        print(chatSelection)
        print("\nreload\n")
        aiChatModel.reload_chat(chatSelection!)
    }
    
    func hard_reload_chat() {
        self.aiChatModel.hard_reload_chat()
    }
    
    private var scrollDownOverlay: some View {
        Button {
            Task {
                autoScroll = true
                scrollToBottom()
            }
        } label: {
            Image(systemName: "arrow.down.circle")
                .resizable()
                .foregroundColor(.white)
                .frame(width: 25, height: 25)
                .padding([.bottom, .trailing], 15)
                .opacity(0.4)
        }
        .buttonStyle(BorderlessButtonStyle())
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack {
            statusOverlay
            
            ScrollViewReader { scrollView in
                VStack {
                    List {
                        ForEach(aiChatModel.messages, id: \.id) { message in
                            MessageView(message: message, chatStyle: $chatStyle, status: nil).id(message.id)
                                .textSelection(.enabled)
                        }
                        .listRowSeparator(.hidden)
                        Text("").id("latest")
                    }
                    .textSelection(.enabled)
                    .listStyle(PlainListStyle())
                    .overlay(scrollDownOverlay, alignment: .bottomTrailing)
                }
                .textSelection(.enabled)
                .onChange(of: aiChatModel.AI_typing) { _ in
                    scrollToBottom(with_animation: false)
                }
                .disabled(chatSelection == nil)
                .onAppear {
                    scrollProxy = scrollView
                    scrollToBottom(with_animation: false)
                }
            }
            .textSelection(.enabled)
            .frame(maxHeight: .infinity)
            .disabled(aiChatModel.state == .loading)
            .onChange(of: chatSelection) { selection in
                Task {
                    if selection == nil {
                        CloseChat()
                    } else {
                        print(selection)
                        chatStyle = selection!["chat_style"] as String? ?? "none"
                        await self.reload()
                    }
                }
            }
            .onTapGesture { location in
                print("Tapped at \(location)")
                focusedField = nil
                autoScroll = false
            }
            .toolbar {
                Button {
                    Task { clearChatAlert = true }
                } label: {
                    Image(systemName: clearChatButtonIcon)
                }
                .alert("Are you sure?", isPresented: $clearChatAlert, actions: {
                    Button("Cancel", role: .cancel, action: {})
                    Button("Clear", role: .destructive, action: {
                        aiChatModel.messages = []
                        save_chat_history(aiChatModel.messages, aiChatModel.chat_name + ".json")
                        clearChatButtonIcon = "checkmark"
                        hard_reload_chat()
                        run_after_delay(delay: 1200, function: { clearChatButtonIcon = "eraser.line.dashed.fill" })
                    })
                }, message: {
                    Text("The message history will be cleared")
                })
                
                Button {
                    Task {
                        hard_reload_chat()
                        reloadButtonIcon = "checkmark"
                        run_after_delay(delay: 1200, function: { reloadButtonIcon = "arrow.counterclockwise.circle" })
                    }
                } label: {
                    Image(systemName: reloadButtonIcon)
                }
                .disabled(aiChatModel.predicting)
                
                Button {
                    Task {
                        toggleEditChat = true
                        editChatDialog = true
                    }
                } label: {
                    Image(systemName: "slider.horizontal.3")
                }
            }
            .navigationTitle(aiChatModel.Title)
            
            LLMTextInput(messagePlaceholder: placeholderString,
                         show_attachment_btn: self.aiChatModel.is_mmodal,
                         focusedField: $focusedField,
                         auto_scroll: $autoScroll,
                         enableRAG: $enableRAG).environmentObject(aiChatModel)
                .disabled(self.aiChatModel.chat_name == "")
        }
        .sheet(isPresented: $toggleEditChat) {
            ChatSettingsView(add_chat_dialog: $toggleEditChat,
                             edit_chat_dialog: $editChatDialog,
                             chat_name: aiChatModel.chat_name,
                             after_chat_edit: $AfterChatEdit,
                             toggleSettings: .constant(false)).environmentObject(aiChatModel)
#if os(macOS)
                .frame(minWidth: 400, minHeight: 600)
#endif
        }
        .textSelection(.enabled)
    }
}
