import Foundation

struct IdentifiableFile: Identifiable {
    let id = UUID()
    var file: ZipUtl.File
    
    init(file: ZipUtl.File) {
        self.file = file
    }
    
    public var name: String {
        get {
            self.file.name
        }
    }
    
    public var data: Data {
        get {
            self.file.data
        }
    }
}

class IdentifiableFileManager: ObservableObject {
    @Published var files: [IdentifiableFile] = []
    
    func enumulates() -> [IdentifiableFile] {
        self.files
    }
    
    func append(file: IdentifiableFile) {
        self.files.append(file)
    }
    
    func remove(file: IdentifiableFile) {
        self.remove(id: file.id)
    }
    
    func remove(id: UUID) {
        for i in 0 ..< self.files.count {
            if self.files[i].id == id {
                self.files.remove(at: i)
                break
            }
        }
    }
}

