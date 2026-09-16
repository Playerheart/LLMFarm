//
//  PromptSettingsView.swift
//  LLMFarm
//
//  Created by guinmoon on 22.06.2024.
//

import SwiftUI

struct PromptSettingsView: View {
    
    @Binding var prompt_format: String
    @Binding var warm_prompt: String
    @Binding var skip_tokens: String
    @Binding var reverse_prompt:String
    @Binding var add_bos_token: Bool
    @Binding var add_eos_token: Bool
    @Binding var parse_special_tokens: Bool
    @Binding var model_inference:String
    
    /// Идентификатор открытого popover'а (nil — закрыт)
    @State private var activeInfo: String? = nil
    
    // MARK: - Info button
    
    private func infoButton(key: String,
                            title: String,
                            description: String) -> some View {
        Button {
            activeInfo = (activeInfo == key) ? nil : key
        } label: {
            Image(systemName: "info.circle")
                .foregroundColor(.secondary)
                .font(.caption)
        }
        .buttonStyle(.plain)
        .popover(isPresented: Binding(
            get: { activeInfo == key },
            set: { if !$0 { activeInfo = nil } }
        ), arrowEdge: .top) {
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    Text(title)
                        .font(.headline)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(description)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(idealWidth: 320, maxWidth: 360, maxHeight: 400)
            .presentationCompactAdaptation(.popover)
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        ScrollView{
            GroupBox(label:
                        HStack(spacing: 4) {
                            Text("promptSettings.section.format")
                            infoButton(
                                key: "format",
                                title: NSLocalizedString("promptSettings.section.format", comment: ""),
                                description: NSLocalizedString("promptSettings.section.format.desc", comment: "")
                            )
                        }
            ) {
                VStack {
                    //                Text("Format:")
                    //                    .frame(maxWidth: .infinity, alignment: .leading)
                    TextEditor(text: $prompt_format)
                        .frame(minHeight: 30)
                    //                                TextField("prompt..", text: $prompt_format, axis: .vertical)
                    //                                    .lineLimit(2)
                    //                                    .textFieldStyle(.roundedBorder)
                    //                                    .frame( alignment: .leading)
                    //                                .multilineTextAlignment(.trailing)
                    //                                .textFieldStyle(.plain)
                }
                .padding(.top, 8)
                .padding(.horizontal, 1)
            }.frame(minHeight: 200)
            
            GroupBox(label:
                        Text("promptSettings.section.options")
            ) {
                VStack {
                    HStack(spacing: 4) {
                        Text("promptSettings.reversePrompts")
                            .frame(maxWidth: .infinity, alignment: .leading)
                        infoButton(
                            key: "reversePrompts",
                            title: NSLocalizedString("promptSettings.reversePrompts", comment: ""),
                            description: NSLocalizedString("promptSettings.reversePrompts.desc", comment: "")
                        )
                    }
#if os(macOS)
                    DidEndEditingTextField(text: $reverse_prompt, didEndEditing: { newName in})
                        .frame( alignment: .leading)
#else
                    TextField("promptSettings.placeholder.prompt", text: $reverse_prompt, axis: .vertical)
                        .lineLimit(2)
                        .textFieldStyle(.roundedBorder)
                        .frame( alignment: .leading)
#endif
                    //                                .multilineTextAlignment(.trailing)
                    //                                .textFieldStyle(.plain)
                }
                .padding(.top, 8)
                .padding(.horizontal, 5)
                
                VStack {
                    HStack(spacing: 4) {
                        Text("promptSettings.skipTokens")
                            .frame(maxWidth: .infinity, alignment: .leading)
                        infoButton(
                            key: "skipTokens",
                            title: NSLocalizedString("promptSettings.skipTokens", comment: ""),
                            description: NSLocalizedString("promptSettings.skipTokens.desc", comment: "")
                        )
                    }
#if os(macOS)
                    DidEndEditingTextField(text: $skip_tokens, didEndEditing: { newName in})
                        .frame( alignment: .leading)
#else
                    TextField("promptSettings.placeholder.prompt", text: $skip_tokens, axis: .vertical)
                        .lineLimit(2)
                        .textFieldStyle(.roundedBorder)
                        .frame( alignment: .leading)
#endif
                    //                                .multilineTextAlignment(.trailing)
                    //                                .textFieldStyle(.plain)
                }
                .padding(.top, 8)
                .padding(.horizontal, 5)
                
                HStack(spacing: 4) {
                    Text("promptSettings.parseSpecial")
                    infoButton(
                        key: "parseSpecial",
                        title: NSLocalizedString("promptSettings.parseSpecial", comment: ""),
                        description: NSLocalizedString("promptSettings.parseSpecial.desc", comment: "")
                    )
                    Toggle("", isOn: $parse_special_tokens)
                        .labelsHidden()
                        .disabled(model_inference != "llama" )
                    Spacer()
                }
                .frame(maxWidth: 160, alignment: .leading)
                .padding(.horizontal, 5)
                .padding(.bottom, 4)
                
                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Text("promptSettings.bos")
                        infoButton(
                            key: "bos",
                            title: NSLocalizedString("promptSettings.bos", comment: ""),
                            description: NSLocalizedString("promptSettings.bos.desc", comment: "")
                        )
                        Toggle("", isOn: $add_bos_token)
                            .labelsHidden()
                    }
                    .frame(maxWidth: 130, alignment: .leading)
                    
                    HStack(spacing: 4) {
                        Text("promptSettings.eos")
                        infoButton(
                            key: "eos",
                            title: NSLocalizedString("promptSettings.eos", comment: ""),
                            description: NSLocalizedString("promptSettings.eos.desc", comment: "")
                        )
                        Toggle("", isOn: $add_eos_token)
                            .labelsHidden()
                    }
                    .frame(maxWidth: 130, alignment: .leading)
                    
                    Spacer()
                }
                .padding(.horizontal, 5)
                .padding(.bottom, 4)
                
                Divider()
                    .padding(.top, 8)
            }
        }
    }
}
//
//#Preview {
//    PromptSettingsView()
//}
