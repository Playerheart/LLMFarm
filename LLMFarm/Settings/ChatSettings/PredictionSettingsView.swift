//
//  PredictionSettingsView.swift
//  LLMFarm
//
//  Created by guinmoon on 22.06.2024.
//

import SwiftUI

struct PredictionSettingsView: View {
    
    @Binding var model_context: Int32
    @Binding var model_n_batch: Int32
    @Binding var n_predict: Int32
    @Binding var numberOfThreads: Int32
    @Binding var use_metal: Bool
    @Binding var use_clip_metal: Bool
    @Binding var mlock: Bool
    @Binding var mmap: Bool
    @Binding var flash_attn: Bool
    @Binding var model_inference:String
    @Binding var model_inference_inner:String
    @Binding var has_clip: Bool
    
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
        HStack(spacing: 4) {
            Text("prediction.threads")
                .frame(maxWidth: 75, alignment: .leading)
            infoButton(
                key: "threads",
                title: NSLocalizedString("prediction.threads", comment: ""),
                description: NSLocalizedString("prediction.threads.desc", comment: "")
            )
            TextField("prediction.placeholder.count", value: $numberOfThreads, format:.number)
                .frame( alignment: .leading)
                .multilineTextAlignment(.trailing)
                .textFieldStyle(.plain)
#if os(iOS)
                .keyboardType(.numberPad)
#endif
        }
        .padding(.horizontal, 5)
        .padding(.top)
        
        HStack {
            HStack(spacing: 4) {
                Text("prediction.metal")
                infoButton(
                    key: "metal",
                    title: NSLocalizedString("prediction.metal", comment: ""),
                    description: NSLocalizedString("prediction.metal.desc", comment: "")
                )
                Toggle("", isOn: $use_metal)
                    .labelsHidden()
                    .disabled((model_inference != "llama" && model_inference_inner != "gpt2" ) /*|| hardware_arch=="x86_64"*/)
            }
            .frame(maxWidth: 140, alignment: .leading)
            
            if (has_clip == true){
                HStack(spacing: 4) {
                    Text("prediction.clipMetal")
                    infoButton(
                        key: "clipMetal",
                        title: NSLocalizedString("prediction.clipMetal", comment: ""),
                        description: NSLocalizedString("prediction.clipMetal.desc", comment: "")
                    )
                    Toggle("", isOn: $use_clip_metal)
                        .labelsHidden()
                }
                .frame(maxWidth: 140, alignment: .leading)
            }
            
            HStack(spacing: 4) {
                Text("prediction.flashAttn")
                infoButton(
                    key: "flashAttn",
                    title: NSLocalizedString("prediction.flashAttn", comment: ""),
                    description: NSLocalizedString("prediction.flashAttn.desc", comment: "")
                )
                Toggle("", isOn: $flash_attn)
                    .labelsHidden()
                    .disabled((self.model_inference != "llama" && self.model_inference_inner != "gpt2" ) /*|| hardware_arch=="x86_64"*/)
            }
            .frame(maxWidth: 140, alignment: .leading)
            
            Spacer()
        }
        .padding(.horizontal, 5)
        .padding(.bottom, 4)
        
        HStack {
            HStack(spacing: 4) {
                Text("prediction.mlock")
                infoButton(
                    key: "mlock",
                    title: NSLocalizedString("prediction.mlock", comment: ""),
                    description: NSLocalizedString("prediction.mlock.desc", comment: "")
                )
                Toggle("", isOn: $mlock)
                    .labelsHidden()
                    .disabled(self.model_inference != "llama" && self.model_inference_inner != "gpt2" )
            }
            .frame(maxWidth: 140, alignment: .leading)
            
            HStack(spacing: 4) {
                Text("prediction.mmap")
                infoButton(
                    key: "mmap",
                    title: NSLocalizedString("prediction.mmap", comment: ""),
                    description: NSLocalizedString("prediction.mmap.desc", comment: "")
                )
                Toggle("", isOn: $mmap)
                    .labelsHidden()
                    .disabled(self.model_inference != "llama" && self.model_inference_inner != "gpt2" )
            }
            .frame(maxWidth: 140, alignment: .leading)
            
            Spacer()
        }
        .padding(.horizontal, 5)
        .padding(.bottom, 4)
        
        HStack(spacing: 4) {
            Text("prediction.context")
                .frame(maxWidth: 75, alignment: .leading)
            infoButton(
                key: "context",
                title: NSLocalizedString("prediction.context", comment: ""),
                description: NSLocalizedString("prediction.context.desc", comment: "")
            )
            TextField("prediction.placeholder.size", value: $model_context, format:.number)
                .frame( alignment: .leading)
                .multilineTextAlignment(.trailing)
                .textFieldStyle(.plain)
#if os(iOS)
                .keyboardType(.numberPad)
#endif
        }
        .padding(.horizontal, 5)
        
        HStack(spacing: 4) {
            Text("prediction.batchSize")
                .frame(maxWidth: 100, alignment: .leading)
            infoButton(
                key: "batchSize",
                title: NSLocalizedString("prediction.batchSize", comment: ""),
                description: NSLocalizedString("prediction.batchSize.desc", comment: "")
            )
            TextField("prediction.placeholder.size", value: $model_n_batch, format:.number)
                .frame( alignment: .leading)
                .multilineTextAlignment(.trailing)
                .textFieldStyle(.plain)
#if os(iOS)
                .keyboardType(.numberPad)
#endif
        }
        .padding(.horizontal, 5)

        HStack(spacing: 4) {
            Text("prediction.predictCount")
                .frame(maxWidth: 120, alignment: .leading)
            infoButton(
                key: "predictCount",
                title: NSLocalizedString("prediction.predictCount", comment: ""),
                description: NSLocalizedString("prediction.predictCount.desc", comment: "")
            )
            TextField("prediction.placeholder.count", value: $n_predict, format:.number)
                .frame( alignment: .leading)
                .multilineTextAlignment(.trailing)
                .textFieldStyle(.plain)
#if os(iOS)
                .keyboardType(.numberPad)
#endif
        }
        .padding(.horizontal, 5)
    }
}

//#Preview {
//    PredictionSettingsView()
//}
