import SwiftUI

private extension FixedWidthInteger {
    init(array: [UInt8]) {
        self = 0
        for i in 0 ..< array.count {
            self = self &+ (Self(array[i]) &<< (i * 8))
        }
    }
    
    init(data: Data) {
        self = Self(array: Array(data))
    }
    
    func asBytes(count: Int) -> [UInt8] {
        var bytes: [UInt8] = []
        
        for i in 0 ..< count {
            bytes.append(UInt8((self &>> (i*8)) & 0xff))
        }
        
        return bytes
    }
}

private extension Data {
    func getChecked(_ index: Int) throws -> UInt8 {
        guard self.indices.contains(index) else {
            throw ZipError(msg: "Out of range")
        }
        return self[index]
    }
    
    func getChecked(_ index: Range<Int>) throws -> Data
    {
        guard 0 <= index.lowerBound && index.upperBound <= self.count else { 
            throw ZipError(msg: "Out of range") 
        }
        return Data(self[index])
    }
}

public class ZipUtl {
    static let versionMadeBy: [UInt8] = [0x14, 0x00]
    static let versionNeededToExtract: [UInt8] = [0x14, 0x00]
    static let centralDirectoryEntrySignature: [UInt8] = [0x50, 0x4b, 0x01, 0x02]
    static let fileHeaderSignature: [UInt8] = [0x50, 0x4b, 0x03, 0x04]
    static let endOfCentralDirectoryRecordSignature: [UInt8] = [0x50, 0x4b, 0x05, 0x06]
    static let crc32 = Crc32()
    
    var fileHeaders: Data
    var centralDirectoryEntries: Data
    var numberOfCentralDirectoryEntries: Int
    
    public init() {
        self.fileHeaders = Data()
        self.centralDirectoryEntries = Data()
        self.numberOfCentralDirectoryEntries = 0
    }
    
    public convenience init(from: URL) throws {
        try self.init(data: Data(contentsOf: from))
    }
    
    public init(data: Data) throws {
        let endOfCentralDirectoryRecord = try data.getChecked(data.count - 22 ..< data.count)
        if ZipUtl.endOfCentralDirectoryRecordSignature != Array(endOfCentralDirectoryRecord[0 ..< 4]) {
            throw ZipError(msg: "Invalid EndOfCentralDirectoryRecord Signature found")
        }
        
        let fileHeadersSize = try Int(data: endOfCentralDirectoryRecord.getChecked(16 ..< 20))
        let centralDirectoryEntriesSize = try Int(data: endOfCentralDirectoryRecord.getChecked(12 ..< 16))
        let centralDirectoryEntriesOffset = try Int(data: endOfCentralDirectoryRecord.getChecked(16 ..< 20))
        self.fileHeaders = try data.getChecked(0 ..< fileHeadersSize)
        self.centralDirectoryEntries = try data.getChecked(centralDirectoryEntriesOffset ..< centralDirectoryEntriesOffset + centralDirectoryEntriesSize)
        self.numberOfCentralDirectoryEntries = try Int(data: endOfCentralDirectoryRecord.getChecked(10 ..< 12))
    }
    
    func appendCentralDirectoryEntry(name: String, data: Data, comment: String = "", crc32 crc32Code: UInt32) {
        let signature: [UInt8] = ZipUtl.centralDirectoryEntrySignature
        let versionMadeBy: [UInt8] = ZipUtl.versionMadeBy
        let versionNeededToExtract: [UInt8] = ZipUtl.versionNeededToExtract
        let generalPurposeBitFlag: [UInt8] = [0x00, 0x08]
        let compressionMethod: [UInt8] = [0x00, 0x00]// stored
        let lastModFileTime: [UInt8] = Date.now.asMsDosFileTime().asBytes(count: 2)
        let lastModFileDate: [UInt8] = Date.now.asMsDosFileDate().asBytes(count: 2)
        let crc32: [UInt8] = crc32Code.asBytes(count: 4)
        let compressedSize: [UInt8] = data.count.asBytes(count: 4)
        let uncompressedSize: [UInt8] = data.count.asBytes(count: 4)
        let fileNameLength: [UInt8] = name.utf8.count.asBytes(count: 2)
        let extraFieldLength: [UInt8] = [0x00, 0x00]
        let fileCommentLength: [UInt8] = comment.utf8.count.asBytes(count: 2)
        let diskNumberStart: [UInt8] = [0x00, 0x00]
        let internalFileAttributes: [UInt8] = [0x00, 0x00]
        let externalFileAttributes: [UInt8] = [0x00, 0x00, 0x00, 0x00]
        let relativeOffsetOfLFH: [UInt8] = self.fileHeaders.count.asBytes(count: 4)
        let fileName: [UInt8] = Array(name.utf8)
        let extraField: [UInt8] = []
        let fileComment: [UInt8] = Array(comment.utf8)
        
        self.centralDirectoryEntries.reserveCapacity(46 + fileName.count + fileComment.count)
        
        self.centralDirectoryEntries.append(contentsOf: signature)
        self.centralDirectoryEntries.append(contentsOf: versionMadeBy)
        self.centralDirectoryEntries.append(contentsOf: versionNeededToExtract)
        self.centralDirectoryEntries.append(contentsOf: generalPurposeBitFlag)
        self.centralDirectoryEntries.append(contentsOf: compressionMethod)
        self.centralDirectoryEntries.append(contentsOf: lastModFileTime)
        self.centralDirectoryEntries.append(contentsOf: lastModFileDate)
        self.centralDirectoryEntries.append(contentsOf: crc32)
        self.centralDirectoryEntries.append(contentsOf: compressedSize)
        self.centralDirectoryEntries.append(contentsOf: uncompressedSize)
        self.centralDirectoryEntries.append(contentsOf: fileNameLength)
        self.centralDirectoryEntries.append(contentsOf: extraFieldLength)
        self.centralDirectoryEntries.append(contentsOf: fileCommentLength)
        self.centralDirectoryEntries.append(contentsOf: diskNumberStart)
        self.centralDirectoryEntries.append(contentsOf: internalFileAttributes)
        self.centralDirectoryEntries.append(contentsOf: externalFileAttributes)
        self.centralDirectoryEntries.append(contentsOf: relativeOffsetOfLFH)
        self.centralDirectoryEntries.append(contentsOf: fileName)
        self.centralDirectoryEntries.append(contentsOf: extraField)
        self.centralDirectoryEntries.append(contentsOf: fileComment)
        
        self.numberOfCentralDirectoryEntries += 1
    }
    
    func appendFileHeader(name: String, data: Data, crc32 crc32Code: UInt32) {
        let signature: [UInt8] = ZipUtl.fileHeaderSignature
        let versionNeededToExtract: [UInt8] = ZipUtl.versionNeededToExtract
        let generalPurposeBitFlag: [UInt8] = [0x00, 0x08]
        let compressionMethod: [UInt8] = [0x00, 0x00]// stored
        let lastModFileTime: [UInt8] = Date.now.asMsDosFileTime().asBytes(count: 2)
        let lastModFileDate: [UInt8] = Date.now.asMsDosFileDate().asBytes(count: 2)
        let crc32: [UInt8] = crc32Code.asBytes(count: 4)
        let compressedSize: [UInt8] = data.count.asBytes(count: 4)
        let uncompressedSize: [UInt8] = data.count.asBytes(count: 4)
        let fileNameLength: [UInt8] = name.utf8.count.asBytes(count: 2)
        let extraFieldLength: [UInt8] = [0x00, 0x00]
        let fileName: [UInt8] = Array(name.utf8)
        let extraField: [UInt8] = []
        
        self.fileHeaders.reserveCapacity(30 + fileName.count + data.count)
        
        self.fileHeaders.append(contentsOf: signature)
        self.fileHeaders.append(contentsOf: versionNeededToExtract)
        self.fileHeaders.append(contentsOf: generalPurposeBitFlag)
        self.fileHeaders.append(contentsOf: compressionMethod)
        self.fileHeaders.append(contentsOf: lastModFileTime)
        self.fileHeaders.append(contentsOf: lastModFileDate)
        self.fileHeaders.append(contentsOf: crc32)
        self.fileHeaders.append(contentsOf: compressedSize)
        self.fileHeaders.append(contentsOf: uncompressedSize)
        self.fileHeaders.append(contentsOf: fileNameLength)
        self.fileHeaders.append(contentsOf: extraFieldLength)
        self.fileHeaders.append(contentsOf: fileName)
        self.fileHeaders.append(contentsOf: extraField)
        self.fileHeaders.append(data)
    }
    
    public func appendFile(name: String, data: Data) {
        let crc32 = ZipUtl.crc32.crc32(data: data)
        self.appendCentralDirectoryEntry(name: name, data: data, crc32: crc32)
        self.appendFileHeader(name: name, data: data, crc32: crc32)
    }
    
    public func build() async -> Data {
        let signature: [UInt8] = ZipUtl.endOfCentralDirectoryRecordSignature
        let diskNumber: [UInt8] = [0x00, 0x00]
        let diskWithCentralDir: [UInt8] = [0x00, 0x00]
        let centralDirRecordsOnDisk: [UInt8] = self.numberOfCentralDirectoryEntries.asBytes(count: 2)
        let centralDirRecordsTotal: [UInt8] = self.numberOfCentralDirectoryEntries.asBytes(count: 2)
        let centralDirSize: [UInt8] = self.centralDirectoryEntries.count.asBytes(count: 4)
        let centralDirOffset: [UInt8] = self.fileHeaders.count.asBytes(count: 4)
        let commentLength: [UInt8] = [0x00, 0x00]
        let comment: [UInt8] = []
        
        var bin = Data()
        bin.reserveCapacity(self.fileHeaders.count + self.centralDirectoryEntries.count + 22)
        
        bin.append(self.fileHeaders)
        bin.append(self.centralDirectoryEntries)
        
        bin.append(contentsOf: signature)
        bin.append(contentsOf: diskNumber)
        bin.append(contentsOf: diskWithCentralDir)
        bin.append(contentsOf: centralDirRecordsOnDisk)
        bin.append(contentsOf: centralDirRecordsTotal)
        bin.append(contentsOf: centralDirSize)
        bin.append(contentsOf: centralDirOffset)
        bin.append(contentsOf: commentLength)
        bin.append(contentsOf: comment)
        
        return bin
    }
    
    public struct File {
        public var name: String
        public var data: Data
        
        init(name: String, data: Data) {
            self.name = name
            self.data = data
        }
        
        init(url: URL) throws {
            self.name = url.pathComponents.last!
            do {
                self.data = try Data(contentsOf: url)
            }catch {
                throw ZipError(msg: "Failed to load from \"" + url.path + "\"")
            }
        }
    }
    
    func checkFileHeaderSignature(fileHeaderOffset offset: Int) throws {
        let signature = try self.fileHeaders.getChecked(offset ..< offset + 4)
        if ZipUtl.fileHeaderSignature != Array(signature) {
            throw ZipError(msg: "Invalid FileHeader Signature found")
        }
    }
    
    func checkCompressionMethodIsStored(fileHeaderOffset offset: Int) throws {
        let method = try self.fileHeaders.getChecked(offset + 8 ..< offset + 10)
        if [0x00, 0x00] != Array(method) {
            throw ZipError(msg: "Unsupported compression method found")
        }
    }
    
    static func checkCrc32(crc32: UInt32, data: Data) throws {
        if ZipUtl.crc32.check(crc32: crc32, data: data) {
            throw ZipError(msg: "CRC-32 mismatch")
        }
    }
    
    func extractFileAndReturnNextOffset(fileHeaderOffset offset: Int) throws -> (file: ZipUtl.File, offset: Int) {
        try self.checkFileHeaderSignature(fileHeaderOffset: offset)
        try self.checkCompressionMethodIsStored(fileHeaderOffset: offset)
        
        let fileSize = Int(data: try self.fileHeaders.getChecked(offset + 18 ..< offset + 22))
        
        let fileNameLength = Int(data: try self.fileHeaders.getChecked(offset + 26 ..< offset + 28))
        let fileNameRaw = try self.fileHeaders.getChecked(offset + 30 ..< offset + 30 + fileNameLength)
        guard let fileName = String(data: fileNameRaw, encoding: .utf8) else {
            throw ZipError(msg: "Invalid UTF8 FileName Found")
        }
        
        let extraFieldLength = Int(data: try self.fileHeaders.getChecked(offset + 28 ..< offset + 30))
        
        let fileOffset = offset + 30 + fileNameLength + extraFieldLength
        let file = try self.fileHeaders.getChecked(fileOffset ..< fileOffset + fileSize)
        let crc32 = UInt32(data: try self.fileHeaders.getChecked(offset + 16 ..< offset + 20))
        try ZipUtl.checkCrc32(crc32: crc32, data: file)
        
        return (file: File(name: fileName, data: file), offset: fileOffset + fileSize)
    }
    
    public func extract() throws -> [ZipUtl.File] {
        var files: [ZipUtl.File] = []
        var fileHeaderOffset = 0
        
        while fileHeaderOffset < self.fileHeaders.count {
            let (file, newFileHeaderOffset) = try self.extractFileAndReturnNextOffset(fileHeaderOffset: fileHeaderOffset)
            files.append(file)
            fileHeaderOffset = newFileHeaderOffset
        }
        
        return files
    }
    
    public func saveAsTempolaryFile(name: String = "untitled.zip") async throws -> URL {
        let url = FileManager.default.temporaryDirectory.appending(component: name)
        try await self.saveAs(url: url)
        return url
    }
    
    public func saveAs(url: URL) async throws {
        let bin = await self.build()
        try bin.write(to: url)
    }
}


