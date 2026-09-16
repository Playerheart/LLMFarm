//
//  TabsView.swift
//  LLMFarm
//
//  Created by guinmoon on 18.10.2024.
//

import SwiftUI



struct ChatSettingTabs : View {
    @Environment(\.colorScheme) var colorScheme
    @Binding var index:Int
    @Binding var edit_chat_dialog:Bool
    
    var body: some View{
        VStack{
            
            TabButton(
                index: $index,
                targetIndex: 0,
                image: Image(systemName: "gear"),
                text: NSLocalizedString("chatSettings.tab.basic", comment: "Вкладка: основные настройки чата")
            )
#if os(macOS)			
                .padding(.top,topSafeAreaInset())
#else
                .padding(.top,UIApplication.shared.keyWindow?.safeAreaInsets.top)
#endif
            
            TabButton(
                index: $index,
                targetIndex: 1,
                image: Image(systemName: "text.viewfinder"),
                text: NSLocalizedString("chatSettings.tab.prompt", comment: "Вкладка: настройки промпта")
            )
                .padding(.top,12)
            
            TabButton(
                index: $index,
                targetIndex: 2,
                image: Image(systemName: "square.stack.3d.forward.dottedline.fill"),
                text: NSLocalizedString("chatSettings.tab.sampling", comment: "Вкладка: параметры сэмплинга")
            )
                .padding(.top,12)
            
            
            TabButton(
                index: $index,
                targetIndex: 4,
                image: Image(systemName: "doc.badge.gearshape"),
                text: NSLocalizedString("chatSettings.tab.rag", comment: "Вкладка: RAG")
            )
                .padding(.top,12)
            if edit_chat_dialog {
                TabButton(
                    index: $index,
                    targetIndex: 5,
                    image: Image(systemName: "doc.on.doc.fill"),
                    text: NSLocalizedString("chatSettings.tab.docs", comment: "Вкладка: документы RAG")
                )
                    .padding(.top,12)
            }
            Spacer(minLength: 0)
            
            TabButton(
                index: $index,
                targetIndex: 3,
                image: Image(systemName: "ellipsis"),
                text: NSLocalizedString("chatSettings.tab.other", comment: "Вкладка: прочие настройки")
            )
            //            .padding(.bottom)
#if os(macOS)
                .padding(.top,bottomSafeAreaInset())
#else
                .padding(.top,UIApplication.shared.keyWindow?.safeAreaInsets.bottom)
#endif
            
            
            
        }
        .padding(.vertical)
        // Fixed Width....
        .frame(width: 60)
        //        .background(colorScheme == .dark ? Color.white.opacity(0.3) : Color.black.opacity(0.3))
        .background(.thinMaterial)
        .clipShape(CShape())
    }
}
