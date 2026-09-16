//
//  SettingsHeaderView.swift
//  LLMFarm
//
//  Created by guinmoon on 22.06.2024.
//

import SwiftUI

struct SettingsHeaderView: View {
    
    @Binding var add_chat_dialog: Bool
    @Binding var edit_chat_dialog: Bool
    @Binding var model_title: String
    @Binding var model_not_selected_alert: Bool
    
    var save_chat_settings: () -> Void
    
    var body: some View {
        VStack{
            HStack{
                Button {
                    Task {
                        add_chat_dialog = false
                        //                            edit_chat_dialog = false
                    }
                } label: {
                    Text("settingsHeader.cancel")
                }
                Group {
                    if edit_chat_dialog {
                        Text("settingsHeader.title.edit")
                    } else {
                        Text("settingsHeader.title.add")
                    }
                }
                .fontWeight(.semibold)
                .font(.title3)
                .frame(maxWidth:.infinity, alignment: .center)
                .padding(.trailing, 30)
                Spacer()
                Button {
                    Task {
                        save_chat_settings()
                    }
                } label: {
                    if edit_chat_dialog {
                        Text("settingsHeader.save")
                    } else {
                        Text("settingsHeader.add")
                    }
                }
                .alert("settingsHeader.modelNotSelected.title", isPresented: $model_not_selected_alert) {
                    Button("settingsHeader.modelNotSelected.ok", role: .cancel) { }
                }
                .disabled(model_title=="")
                
            }
//            Text(edit_chat_dialog ? model_title : ""  )
//                .padding(.top,4)
//                .font(.title3)
        }
    }
}

//#Preview {
//    SettingsHeaderView()
//}
