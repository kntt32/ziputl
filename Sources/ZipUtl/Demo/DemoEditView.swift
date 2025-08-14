import SwiftUI

func addNewFile(result: Result<URL, any Error>, fileManager: IdentifiableFileManager, alertFlag: inout Bool, alertMsg: inout String) {
    switch result {
    case .success(let url):
        if url.startAccessingSecurityScopedResource() {
            defer { url.stopAccessingSecurityScopedResource() }
            
            do {
                let file = try ZipUtl.File(url: url)
                withAnimation {
                    fileManager.append(file: IdentifiableFile(file: file))
                }
            }catch(let zipError) {
                alertMsg = (zipError as! ZipError).msg
                alertFlag = true
            }
        }else {
            alertMsg = "Failed to access"
            alertFlag = true
        }
    case .failure(_):
        alertMsg = "Failed to add new file"
        alertFlag = true
    }
}

struct DemoEditView: View {
    @State private var fileImportFlag = false
    @ObservedObject var fileManager: IdentifiableFileManager
    @Binding var alertFlag: Bool
    @Binding var alertMsg: String
    
    var body: some View {
        VStack {
            HStack {
                Spacer()
            }
            ForEach($fileManager.files) { $file in
                HStack {
                    TextField("FileName", text: $file.file.name)
                    Button {
                        withAnimation {
                            fileManager.remove(id: file.id)
                        }
                    }label: {
                        Image(systemName: "trash")
                    }
                    .padding(10)
                        .background(in: .circle)
                        .backgroundStyle(.red)
                }
                    .padding(12)
                    .background(in: .rect(cornerRadius: 10))
                    .backgroundStyle(.bar)
                    .padding(13)
            }.transition(.move(edge: .bottom).combined(with: .opacity))
            Button {
                fileImportFlag.toggle()
            }label: {
                Image(systemName: "plus").foregroundStyle(.white)
            }.padding(15)
                .background(in: .circle)
                .backgroundStyle(.blue)
                .padding(10)
                .fileImporter(isPresented: $fileImportFlag, allowedContentTypes: [.data]) { result in
                    addNewFile(result: result, fileManager: fileManager, alertFlag: &alertFlag, alertMsg: &alertMsg)
                }
        }.buttonStyle(.plain)
    }
}


