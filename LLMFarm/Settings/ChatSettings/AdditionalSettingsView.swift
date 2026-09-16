//
//  AdditionalSettingsView.swift
//  LLMFarm
//
//  Created by guinmoon on 22.06.2024.
//

import SwiftUI

struct AdditionalSettingsView: View {
    
    @Binding var save_load_state: Bool
    @Binding var save_as_template_name:String
    @Binding var chat_style: String
    @Binding var chat_styles: [String]
    
    var get_chat_options_dict: (Bool) -> Dictionary<String, Any>
    var refresh_templates: () -> Void
    
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
        )) {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(12)
            .frame(maxWidth: 280)
            .presentationCompactAdaptation(.popover)
        }
    }
    
    // MARK: - Display name for chat styles
    
    /// Переводит техническое имя стиля чата для отображения в Picker.
    /// Хранимое значение (chat_style) остаётся английским — оно сохраняется в конфиг.
    private func chatStyleDisplayName(_ value: String) -> String {
        switch value {
        case "None":
            return NSLocalizedString("additional.chatStyle.none", comment: "Стиль чата: без оформления")
        case "DocC":
            return NSLocalizedString("additional.chatStyle.docc", comment: "Стиль чата: DocC")
        case "Basic":
            return NSLocalizedString("additional.chatStyle.basic", comment: "Стиль чата: Basic")
        case "GitHub":
            return NSLocalizedString("additional.chatStyle.github", comment: "Стиль чата: GitHub")
        default:
            return value
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack{
            HStack(spacing: 4) {
                Text("additional.saveAsTemplate")
                    .frame(maxWidth: .infinity, alignment: .leading)
                infoButton(
                    key: "saveAsTemplate",
                    title: NSLocalizedString("additional.saveAsTemplate", comment: ""),
                    description: NSLocalizedString("additional.saveAsTemplate.desc", comment: "")
                )
            }
            .padding(.horizontal, 5)
            
            HStack {
#if os(macOS)
                DidEndEditingTextField(text: $save_as_template_name,didEndEditing: { newName in})
                    .frame(maxWidth: .infinity, alignment: .leading)
#else
                TextField("additional.newTemplatePlaceholder", text: $save_as_template_name)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textFieldStyle(.plain)
#endif
                Button {
                    Task {
                        let options = get_chat_options_dict(true)
                        _ = CreateChat(options,edit_chat_dialog:true,chat_name:save_as_template_name + ".json",save_as_template:true)
                        refresh_templates()
                    }
                } label: {
                    Image(systemName: "doc.badge.plus")
                }
                .frame(alignment: .trailing)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 5)
        }
        .padding(.top)
        
        HStack(spacing: 4) {
            Text("additional.saveLoadState")
            infoButton(
                key: "saveLoadState",
                title: NSLocalizedString("additional.saveLoadState", comment: ""),
                description: NSLocalizedString("additional.saveLoadState.desc", comment: "")
            )
            Toggle("", isOn: $save_load_state)
                .labelsHidden()
             Spacer()
        }
        .frame(maxWidth: 200, alignment: .leading)
        .padding(.top, 5)
        .padding(.horizontal, 5)
        .padding(.bottom, 4)

        HStack(spacing: 4){
            Text("additional.chatStyle")
                .frame(maxWidth: .infinity, alignment: .leading)
            infoButton(
                key: "chatStyle",
                title: NSLocalizedString("additional.chatStyle", comment: ""),
                description: NSLocalizedString("additional.chatStyle.desc", comment: "")
            )
            Picker("", selection: $chat_style) {
                ForEach(chat_styles, id: \.self) {
                    Text(chatStyleDisplayName($0))
                }
            }
            .pickerStyle(.menu)            
            //
        }
        .padding(.horizontal, 5)
        .padding(.top, 8)
    }
}

//#Preview {
//    AdditionalSettingsView()
//}
