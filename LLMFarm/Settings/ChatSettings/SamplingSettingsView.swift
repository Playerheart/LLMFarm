//
//  SamplingSettingsView.swift
//  LLMFarm
//
//  Created by guinmoon on 22.06.2024.
//

import SwiftUI

struct SamplingSettingsView: View {
    
    @Binding var model_sampling: String
    @Binding var model_samplings: [String]
    @Binding var model_temp: Float
    @Binding var model_top_k: Int32
    @Binding var model_top_p: Float
    @Binding var model_repeat_last_n: Int32
    @Binding var model_repeat_penalty: Float
    @Binding var mirostat: Int32
    @Binding var mirostat_tau: Float
    @Binding var mirostat_eta: Float
    @Binding var tfs_z: Float
    @Binding var typical_p: Float
    @Binding var grammar: String 
    @Binding var model_inference: String
    @Binding var grammars_previews: [String]
    
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
    
    // MARK: - Display name for sampling mode
    
    /// Переводит техническое имя режима сэмплинга для отображения в Picker.
    /// Хранимое значение (model_sampling) остаётся английским — оно сравнивается в onChange.
    private func samplingDisplayName(_ value: String) -> String {
        switch value {
        case "temperature":
            return NSLocalizedString("sampling.mode.temperature", comment: "Режим сэмплинга: temperature")
        case "greedy":
            return NSLocalizedString("sampling.mode.greedy", comment: "Режим сэмплинга: greedy")
        case "mirostat":
            return NSLocalizedString("sampling.mode.mirostat", comment: "Режим сэмплинга: mirostat")
        case "mirostat_v2":
            return NSLocalizedString("sampling.mode.mirostat_v2", comment: "Режим сэмплинга: mirostat_v2")
        default:
            return value
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        HStack(spacing: 4){
            Text("sampling.mode")
                .frame(maxWidth: 110, alignment: .leading)
            infoButton(
                key: "mode",
                title: NSLocalizedString("sampling.mode", comment: ""),
                description: NSLocalizedString("sampling.mode.desc", comment: "")
            )
            Picker("", selection: $model_sampling) {
                ForEach(model_samplings, id: \.self) {
                    Text(samplingDisplayName($0))
                }
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            .pickerStyle(.menu)
            .onChange(of: model_sampling) { sampling in
                if sampling == "temperature" {
                    mirostat = 0
                }
                if sampling == "greedy" {
                    mirostat = 0
                    model_temp = 0
                }
                if sampling == "mirostat" {
                    mirostat = 1
                }
                if sampling == "mirostat_v2" {
                    mirostat = 2
                }
            }
        }
        .padding(.horizontal, 5)
        .padding(.top, 8)
        
        if model_sampling == "temperature" {
            Group {
                
                HStack(spacing: 4) {
                    Text("sampling.repeatLastN")
                        .frame(maxWidth: 100, alignment: .leading)
                    infoButton(
                        key: "repeatLastN",
                        title: NSLocalizedString("sampling.repeatLastN", comment: ""),
                        description: NSLocalizedString("sampling.repeatLastN.desc", comment: "")
                    )
                    TextField("sampling.placeholder.count", value: $model_repeat_last_n, format:.number)
                        .frame( alignment: .leading)
                        .multilineTextAlignment(.trailing)
                        .textFieldStyle(.plain)
#if os(iOS)
                        .keyboardType(.numberPad)
#endif
                }
                .padding(.horizontal, 5)
                
                HStack(spacing: 4) {
                    Text("sampling.repeatPenalty")
                        .frame(maxWidth: 100, alignment: .leading)
                    infoButton(
                        key: "repeatPenalty",
                        title: NSLocalizedString("sampling.repeatPenalty", comment: ""),
                        description: NSLocalizedString("sampling.repeatPenalty.desc", comment: "")
                    )
                    TextField("sampling.placeholder.size", value: $model_repeat_penalty, format:.number)
                        .frame( alignment: .leading)
                        .multilineTextAlignment(.trailing)
                        .textFieldStyle(.plain)
#if os(iOS)
                        .keyboardType(.numbersAndPunctuation)
#endif
                }
                .padding(.horizontal, 5)
                
                HStack(spacing: 4) {
                    Text("sampling.temp")
                        .frame(maxWidth: 75, alignment: .leading)
                    infoButton(
                        key: "temp",
                        title: NSLocalizedString("sampling.temp", comment: ""),
                        description: NSLocalizedString("sampling.temp.desc", comment: "")
                    )
                    TextField("sampling.placeholder.size", value: $model_temp, format:.number)
                        .frame( alignment: .leading)
                        .multilineTextAlignment(.trailing)
                        .textFieldStyle(.plain)
#if os(iOS)
                        .keyboardType(.numbersAndPunctuation)
#endif
                }
                .padding(.horizontal, 5)
                
                HStack(spacing: 4) {
                    Text("sampling.topK")
                        .frame(maxWidth: 75, alignment: .leading)
                    infoButton(
                        key: "topK",
                        title: NSLocalizedString("sampling.topK", comment: ""),
                        description: NSLocalizedString("sampling.topK.desc", comment: "")
                    )
                    TextField("sampling.placeholder.val", value: $model_top_k, format:.number)
                        .frame( alignment: .leading)
                        .multilineTextAlignment(.trailing)
                        .textFieldStyle(.plain)
#if os(iOS)
                        .keyboardType(.numberPad)
#endif
                }
                .padding(.horizontal, 5)
                
                HStack(spacing: 4) {
                    Text("sampling.topP")
                        .frame(maxWidth: 95, alignment: .leading)
                    infoButton(
                        key: "topP",
                        title: NSLocalizedString("sampling.topP", comment: ""),
                        description: NSLocalizedString("sampling.topP.desc", comment: "")
                    )
                    TextField("sampling.placeholder.val", value: $model_top_p, format:.number)
                        .frame( alignment: .leading)
                        .multilineTextAlignment(.trailing)
                        .textFieldStyle(.plain)
#if os(iOS)
                        .keyboardType(.numbersAndPunctuation)
#endif
                }
                .padding(.horizontal, 5)
                
                HStack(spacing: 4) {
                    Text("sampling.tfsZ")
                        .frame(maxWidth: 100, alignment: .leading)
                    infoButton(
                        key: "tfsZ",
                        title: NSLocalizedString("sampling.tfsZ", comment: ""),
                        description: NSLocalizedString("sampling.tfsZ.desc", comment: "")
                    )
                    TextField("sampling.placeholder.val", value: $tfs_z, format:.number)
                        .frame( alignment: .leading)
                        .multilineTextAlignment(.trailing)
                        .textFieldStyle(.plain)
#if os(iOS)
                        .keyboardType(.numbersAndPunctuation)
#endif
                }
                .padding(.horizontal, 5)
                
                HStack(spacing: 4) {
                    Text("sampling.typicalN")
                        .frame(maxWidth: 140, alignment: .leading)
                    infoButton(
                        key: "typicalN",
                        title: NSLocalizedString("sampling.typicalN", comment: ""),
                        description: NSLocalizedString("sampling.typicalN.desc", comment: "")
                    )
                    TextField("sampling.placeholder.val", value: $typical_p, format:.number)
                        .frame( alignment: .leading)
                        .multilineTextAlignment(.trailing)
                        .textFieldStyle(.plain)
#if os(iOS)
                        .keyboardType(.numbersAndPunctuation)
#endif
                }
                .padding(.horizontal, 5)
                
            }
            
        }
        
        if model_sampling == "mirostat" || model_sampling == "mirostat_v2" {
            Group {
                HStack(spacing: 4) {
                    Text("sampling.mirostatEta")
                        .frame(maxWidth: 110, alignment: .leading)
                    infoButton(
                        key: "mirostatEta",
                        title: NSLocalizedString("sampling.mirostatEta", comment: ""),
                        description: NSLocalizedString("sampling.mirostatEta.desc", comment: "")
                    )
                    TextField("sampling.placeholder.val", value: $mirostat_eta, format:.number)
                        .frame( alignment: .leading)
                        .multilineTextAlignment(.trailing)
                        .textFieldStyle(.plain)
#if os(iOS)
                        .keyboardType(.numbersAndPunctuation)
#endif
                }
                .padding(.horizontal, 5)
                
                HStack(spacing: 4) {
                    Text("sampling.mirostatTau")
                        .frame(maxWidth: 110, alignment: .leading)
                    infoButton(
                        key: "mirostatTau",
                        title: NSLocalizedString("sampling.mirostatTau", comment: ""),
                        description: NSLocalizedString("sampling.mirostatTau.desc", comment: "")
                    )
                    TextField("sampling.placeholder.val", value: $mirostat_tau, format:.number)
                        .frame( alignment: .leading)
                        .multilineTextAlignment(.trailing)
                        .textFieldStyle(.plain)
#if os(iOS)
                        .keyboardType(.numbersAndPunctuation)
#endif
                }
                .padding(.horizontal, 5)
                
                HStack(spacing: 4) {
                    Text("sampling.temp")
                        .frame(maxWidth: 75, alignment: .leading)
                    infoButton(
                        key: "tempMirostat",
                        title: NSLocalizedString("sampling.temp", comment: ""),
                        description: NSLocalizedString("sampling.temp.desc", comment: "")
                    )
                    TextField("sampling.placeholder.size", value: $model_temp, format:.number)
                        .frame( alignment: .leading)
                        .multilineTextAlignment(.trailing)
                        .textFieldStyle(.plain)
#if os(iOS)
                        .keyboardType(.numbersAndPunctuation)
#endif
                }
                .padding(.horizontal, 5)
            }
        }
        
        if model_inference == "llama"{
            HStack(spacing: 4){
                Text("sampling.grammar")
                    .frame(maxWidth: .infinity, alignment: .leading)
                infoButton(
                    key: "grammar",
                    title: NSLocalizedString("sampling.grammar", comment: ""),
                    description: NSLocalizedString("sampling.grammar.desc", comment: "")
                )
                Picker("", selection: $grammar) {
                    ForEach(grammars_previews, id: \.self) {
                        Text($0)
                    }
                }
                .pickerStyle(.menu)
            }
            .padding(.horizontal, 5)
        }
    }
}

//#Preview {
//    SamplingSettingsView()
//}
