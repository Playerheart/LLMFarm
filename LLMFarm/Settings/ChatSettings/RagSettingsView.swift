//
//  RagSettingsView.swift
//  LLMFarm
//
//  Created by guinmoon on 20.10.2024.
//

import SwiftUI
import SimilaritySearchKit
import SimilaritySearchKitDistilbert
import SimilaritySearchKitMiniLMAll
import SimilaritySearchKitMiniLMMultiQA

struct RagSettingsView: View {
    @State var ragDir: String
    
    @State var inputText:String  = ""
    var searchUrl:URL
    var ragUrl:URL
    var searchResultsCount:Int = 3
    @State var loadIndexResult: String = ""
    @State var searchResults: String = ""
    
    
    @Binding private var chunkSize: Int
    @Binding private var chunkOverlap: Int 
    @Binding private var currentModel: EmbeddingModelType 
    @Binding private var comparisonAlgorithm: SimilarityMetricType 
    @Binding private var chunkMethod: TextSplitterType
    @Binding private var ragTop: Int
    
    /// Идентификатор открытого popover'а (nil — закрыт)
    @State private var activeInfo: String? = nil
    
    init (  ragDir:String,
            chunkSize: Binding<Int>,
            chunkOverlap: Binding<Int>,
            currentModel: Binding<EmbeddingModelType>,
            comparisonAlgorithm: Binding<SimilarityMetricType>,
            chunkMethod: Binding<TextSplitterType>,
            ragTop:Binding<Int>){
        self.ragDir = ragDir
        self.ragUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent(ragDir) ?? URL(fileURLWithPath: "")
        self.searchUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent(ragDir+"/docs") ?? URL(fileURLWithPath: "")
        self._chunkSize = chunkSize
        self._chunkOverlap = chunkOverlap
        self._currentModel = currentModel
        self._comparisonAlgorithm = comparisonAlgorithm
        self._chunkMethod  = chunkMethod
        self._ragTop = ragTop
    }

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
    
    var body: some View {
        ScrollView(showsIndicators: false){
            VStack {
                GroupBox(label:
                            Text("rag.section.settings")
                ) {
                    HStack(spacing: 4) {
                        Text("rag.chunkSize")
                            .frame(maxWidth: 100, alignment: .leading)
                        infoButton(
                            key: "chunkSize",
                            title: NSLocalizedString("rag.chunkSize", comment: ""),
                            description: NSLocalizedString("rag.chunkSize.desc", comment: "")
                        )
                        TextField("rag.placeholder.size", value: $chunkSize, format:.number)
                            .frame( alignment: .leading)
                            .multilineTextAlignment(.trailing)
                            .textFieldStyle(.plain)
                             #if os(iOS)
                            .keyboardType(.numbersAndPunctuation)
                             #endif
                    }   
//                    .padding(.horizontal, 5)
                    
                    HStack(spacing: 4) {
                        Text("rag.chunkOverlap")
                            .frame(maxWidth: 100, alignment: .leading)
                        infoButton(
                            key: "chunkOverlap",
                            title: NSLocalizedString("rag.chunkOverlap", comment: ""),
                            description: NSLocalizedString("rag.chunkOverlap.desc", comment: "")
                        )
                        TextField("rag.placeholder.size", value: $chunkOverlap, format:.number)
                            .frame( alignment: .leading)
                            .multilineTextAlignment(.trailing)
                            .textFieldStyle(.plain)
                             #if os(iOS)
                            .keyboardType(.numbersAndPunctuation)
                             #endif
                    }   
//                    .padding(.horizontal, 5)

                    
                    HStack(spacing: 4){
                        Text("rag.embeddingModel")
                            .frame(maxWidth: 100, alignment: .leading)
                        infoButton(
                            key: "embeddingModel",
                            title: NSLocalizedString("rag.embeddingModel", comment: ""),
                            description: NSLocalizedString("rag.embeddingModel.desc", comment: "")
                        )
                        Picker("", selection: $currentModel) {
                            ForEach(SimilarityIndex.EmbeddingModelType.allCases, id: \.self) { option in
                                Text(String(describing: option))
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .pickerStyle(.menu)
                    }
                    
                    HStack(spacing: 4){
                        Text("rag.similarityMetric")
                            .frame(maxWidth: 120, alignment: .leading)
                        infoButton(
                            key: "similarityMetric",
                            title: NSLocalizedString("rag.similarityMetric", comment: ""),
                            description: NSLocalizedString("rag.similarityMetric.desc", comment: "")
                        )
                        Picker("", selection: $comparisonAlgorithm) {
                            ForEach(SimilarityIndex.SimilarityMetricType.allCases, id: \.self) { option in
                                Text(String(describing: option))
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .pickerStyle(.menu)
                    }
                    
                    HStack(spacing: 4){
                        Text("rag.textSplitter")
                            .frame(maxWidth: 120, alignment: .leading)
                        infoButton(
                            key: "textSplitter",
                            title: NSLocalizedString("rag.textSplitter", comment: ""),
                            description: NSLocalizedString("rag.textSplitter.desc", comment: "")
                        )
                        Picker("", selection: $chunkMethod) {
                            ForEach(TextSplitterType.allCases, id: \.self) { option in
                                Text(String(describing: option))
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .pickerStyle(.menu)
                    }
                    
                    HStack(spacing: 4) {
                        Text("rag.maxAnswers")
                            .frame(maxWidth: 100, alignment: .leading)
                        infoButton(
                            key: "maxAnswers",
                            title: NSLocalizedString("rag.maxAnswers", comment: ""),
                            description: NSLocalizedString("rag.maxAnswers.desc", comment: "")
                        )
                        TextField("rag.placeholder.count", value: $ragTop, format:.number)
                            .frame( alignment: .leading)
                            .multilineTextAlignment(.trailing)
                            .textFieldStyle(.plain)
                             #if os(iOS)
                            .keyboardType(.numbersAndPunctuation)
                             #endif
                    }

                }
//                .padding(.horizontal, 1)

                GroupBox(label:
                            Text("rag.section.debug")
                ) {
                    HStack{
                        Button(
                            action: {
                                Task{
                                    await BuildIndex(ragURL: ragUrl)
                                }
                            },
                            label: {
                                Text("rag.debug.rebuildIndex")
                                    .font(.title2)
                            }
                        )
                        .padding()
                        
                        Button(
                            action: {
                                Task{
                                    await LoadIndex(ragURL: ragUrl)
                                }
                            },
                            label: {
                                Text("rag.debug.loadIndex")
                                    .font(.title2)
                            }
                        )
                        .padding()
                    }
                    
                    Text(loadIndexResult)
//                        .padding(.top)
                    
                    TextField("rag.debug.searchPlaceholder", text: $inputText, axis: .vertical )
                        .onSubmit {
                            Task{
                                await Search()
                            }
                        }
                        .textFieldStyle(.plain)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background {
                            RoundedRectangle(cornerRadius: 20)
    #if os(macOS)
                                .stroke(Color(NSColor.systemGray), lineWidth: 0.2)
    #else
                                .stroke(Color(UIColor.systemGray2), lineWidth: 0.2)
    #endif
                                .background {
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(.white.opacity(0.1))
                                }
                                .padding(.trailing, 2)
                            
                            
                        }
                        .lineLimit(1...5)
                    
//                    Button(
//                        action: {
//                            Task{
//                                await Search()
//                            }
//                        },
//                        label: {
//                            Text("Search")
//                                .font(.title2)
//                        }
//                    )
//                    .padding()
                    
                    Button(
                        action: {
                            Task{
                                await GeneratePrompt()
                            }
                        },
                        label: {
                            Text("rag.debug.searchAndGenerate")
                                .font(.title2)
                        }
                    )
//                    .padding()
                    
                    Text(searchResults)
                        .padding()
                        .textSelection(.enabled)
                }
//                .padding(.horizontal, 1)
                
            }
//            .padding()
        }
    }
    
    func BuildIndex(ragURL: URL) async{
        let start = DispatchTime.now()
        updateIndexComponents(currentModel:currentModel,comparisonAlgorithm:comparisonAlgorithm,chunkMethod:chunkMethod)
        await BuildNewIndex(searchUrl: searchUrl,
                            chunkSize: chunkSize,
                            chunkOverlap: chunkOverlap)
        let end = DispatchTime.now()   // конец замера времени
        let nanoTime = end.uptimeNanoseconds - start.uptimeNanoseconds // наносекунды
        let timeInterval = Double(nanoTime) / 1_000_000_000 // преобразуем в секунды
        loadIndexResult = String(timeInterval) + " " + NSLocalizedString("rag.debug.sec", comment: "Единица измерения времени: секунды")
        saveIndex(url: ragURL, name: "RAG_index")
    }
    
    func LoadIndex(ragURL: URL) async{
        updateIndexComponents(currentModel:currentModel,comparisonAlgorithm:comparisonAlgorithm,chunkMethod:chunkMethod)
        await loadExistingIndex(url: ragURL, name: "RAG_index")
        loadIndexResult = NSLocalizedString("rag.debug.loaded", comment: "Статус: индекс загружен")
    }
    
    func Search() async{
        let start = DispatchTime.now()
        let results = await searchIndexWithQuery(query: inputText, top: searchResultsCount)
        let end = DispatchTime.now()   // конец замера времени
        let nanoTime = end.uptimeNanoseconds - start.uptimeNanoseconds // наносекунды
        let timeInterval = Double(nanoTime) / 1_000_000_000 // преобразуем в секунды
                
        
        searchResults = String(describing:results)
        print(results)
        
        print("Search time: \(timeInterval) sec")
    }
    
    
    func GeneratePrompt() async{
        let start = DispatchTime.now()
        let results = await searchIndexWithQuery(query: inputText, top: searchResultsCount)
        let end = DispatchTime.now()   // конец замера времени
        let nanoTime = end.uptimeNanoseconds - start.uptimeNanoseconds // наносекунды
        let timeInterval = Double(nanoTime) / 1_000_000_000 // преобразуем в секунды
        
        if results == nil{
            return
        }
        
        let llmPrompt = SimilarityIndex.exportLLMPrompt(query: inputText, results: results!)
        
        searchResults = llmPrompt
        print(llmPrompt)
        
        print("Search time: \(timeInterval) sec")
    }
}

//#Preview {
//    RagSettingsView()
//}
