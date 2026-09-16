import SwiftUI

struct ModelSelector: View {
    
    @Binding var models_previews: [Dictionary<String, String>]
    @Binding var model_file_path: String
    @Binding var model_file_url: URL
    @Binding var model_title: String
    @Binding var toggleSettings: Bool
    @Binding var edit_chat_dialog: Bool

    var import_lable: String
    var download_lable: String
    var selection_lable: String
    var avalible_lable: String

    @State private var isModelImporting: Bool = false

    // Плейсхолдеры, которые приходят из ChatSettingsView как @State-значения
    // и одновременно используются в сравнениях (нельзя менять). Но при
    // отображении в UI показываем локализованный selection_lable.
    private var modelSelectorLabel: String {
        if model_file_path.isEmpty ||
           model_file_path == "Select model" ||
           model_file_path == "Select Clip model" ||
           model_file_path == "Add LoRA adapter" {
            return selection_lable
        }
        return model_file_path
    }

    var body: some View {
        HStack {
            Menu {
                Button {
                    Task {
                        isModelImporting = true
                    }
                } label: {
                    Label(import_lable, systemImage: "plus.app")
                }
                
                if !edit_chat_dialog{
                    Button {
                        Task {
                            toggleSettings = true
                        }
                    } label: {
                        Label(download_lable, systemImage: "icloud.and.arrow.down")
                    }
                    
                }
                    
                Divider()
                
                Section(avalible_lable) {
                    ForEach(models_previews, id: \.self) { model in
                        Button(model["file_name"]!){
//                                            model_file_name = model["file_name"]!
                            model_file_path = model["file_name"]!
                            model_title = GetFileNameWithoutExt(fileName:model_file_path)
                        }
                    }
                }
            } label: {
                Label(modelSelectorLabel, systemImage: "ellipsis.circle")
            }
        }
        .fileImporter(
            isPresented: $isModelImporting,
            allowedContentTypes: [.data],
            allowsMultipleSelection: false
        ) { result in
            do {
                guard let selectedFile: URL = try result.get().first else { return }
                //                                model_file.input = selectedFile.lastPathComponent
//                                model_file_name = selectedFile.lastPathComponent
                model_file_url = selectedFile
                //                                    saveBookmark(url: selectedFile)
                //#if os(iOS) || os(watchOS) || os(tvOS)
                model_file_path = selectedFile.lastPathComponent
                //#else
                //                                    model_file_path = selectedFile.path
                //#endif
                model_title = GetFileNameWithoutExt(fileName:selectedFile.lastPathComponent)
            } catch {
                // Handle failure.
                print("Unable to read file contents")
                print(error.localizedDescription)
            }
        }
    }
}
