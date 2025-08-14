import Foundation
import zlib

public struct Crc32 {
    /*
    let crcTable: [UInt32]
    
    public init() {
        var table: [UInt32] = []
        table.reserveCapacity(256)
        let poly: UInt32 = 0xedb88320
        
        for i in 0 ..< 256 {
            var c: UInt32 = UInt32(i)
            for _ in 0 ..< 8 {
                if (c & 1) != 0 {
                    c = (c >> 1) ^ poly
                }else {
                    c = c >> 1
                }
            }
            table.append(c)
        }
        
        self.crcTable = table
    }
    
    public func crc32(src: [UInt8]) -> UInt32 {
        var c: UInt32 = 0xffffffff
        
        for i in src {
            c = self.crcTable[Int((c ^ UInt32(i)) & 0xff)] ^ (c >> 8)
        }
        
        return ~c
    }
    */
    
    public func crc32(data: Data) -> UInt32 {
        return data.withUnsafeBytes { buffer -> UInt32 in
            return UInt32(zlib.crc32(0, buffer.bindMemory(to: Bytef.self).baseAddress, uInt(buffer.count)))
        }
    }
    
    public func check(crc32: UInt32, data: Data) -> Bool {
        self.crc32(data: data) == crc32
    }
}
