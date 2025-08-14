import SwiftUI

struct ZipError: Error {
    var localizedDescription: String
    
    init(msg: String) {
        self.localizedDescription = msg
    }
    
    public var msg: String {
        get {
            self.localizedDescription
        }
    }
}
