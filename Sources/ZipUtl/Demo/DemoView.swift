import SwiftUI
import UniformTypeIdentifiers

func importZipFile(result: Result<URL, any Error>, fileManager: IdentifiableFileManager, alertFlag: inout Bool, alertMsg: inout String) {
    switch result {
    case .success(let url):
        do {
            if url.startAccessingSecurityScopedResource() {
                defer { url.stopAccessingSecurityScopedResource() }
                let ziputl = try ZipUtl(from: url)
                let files = try ziputl.extract()
                for file in files {
                    fileManager.append(file: IdentifiableFile(file: file))
                }
            }else {
                alertMsg = "Failed to access"
                alertFlag = true
            }
        }catch(let zipError) {
            alertMsg = (zipError as! ZipError).msg
            alertFlag = true
        }
    case .failure(_):
        alertMsg = "Failed to import"
        alertFlag = true
    }
}

struct ZipDocument: FileDocument {
    static var readableContentTypes: [UTType] = [.zip]
    var data: Data
    
    init(data: Data) {
        self.data = data
    }
    
    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw NSError(
                domain: "ZipUtlDemo",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Failed to get regularFileContent"]
            )
        }
        
        self.data = data
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        .init(regularFileWithContents: self.data)
    }
}

public struct DemoView: View {
    @StateObject private var fileManager = IdentifiableFileManager()
    @State private var zipImportFlag = false
    @State private var zipExportFlag = false
    @State private var exportZipDocument: ZipDocument? = nil
    @State private var alertFlag = false
    @State private var alertMsg = "errmsg"
    @State private var progressFlag = false
    
    public var body: some View {
        VStack {
            ScrollView {
                DemoEditView(fileManager: fileManager, alertFlag: $alertFlag, alertMsg: $alertMsg)
            }
            if progressFlag {
                ProgressView().progressViewStyle(.circular)
            }
            HStack {
                Spacer()
                Button("Import") {
                    zipImportFlag.toggle()
                }.fileImporter(isPresented: $zipImportFlag, allowedContentTypes: [.zip]) { result in
                    withAnimation {
                        importZipFile(result: result, fileManager: fileManager, alertFlag: &alertFlag, alertMsg: &alertMsg)
                    }
                }
                Spacer()
                Button("Export") {
                    progressFlag.toggle()
                    Task {
                        let zipData = await Task.detached {
                            let ziputl = ZipUtl()
                            for file in await fileManager.enumulates() {
                                ziputl.appendFile(name: file.name, data: file.data)
                            }
                            return await ziputl.build()
                        }.value
                        
                        exportZipDocument = ZipDocument(data: zipData)
                        zipExportFlag.toggle()
                        progressFlag = false
                    }
                }.fileExporter(isPresented: $zipExportFlag, document: exportZipDocument, contentType: .zip) { result in
                    switch result {
                    case .failure(_):
                        alertMsg = "Failed to export zip file"
                        alertFlag = true
                    default: break
                    }
                }
                Spacer()
            }.padding(20)
        }.accentColor(.blue)
            .buttonStyle(.automatic)
            .alert("Error", isPresented: $alertFlag, actions: {
                Button("OK") {
                    alertFlag.toggle()
                }
            }, message: {
                Text(alertMsg)
            })
    }
}
