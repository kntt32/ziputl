import Foundation

extension Date {
    func asMsDosFileTime() -> UInt16 {
        let calender = Calendar(identifier: .gregorian)
        
        let sec = calender.component(.second, from: self)
        let min = calender.component(.minute, from: self)
        let hour = calender.component(.hour, from: self)
        
        let secMask = (UInt16(sec) >> 1) & 0x001f
        let minMask = (UInt16(min) << 5) & 0x07e0
        let hourMask = (UInt16(hour) << 11) & 0xf800
        
        return secMask | minMask | hourMask
    }
    
    func asMsDosFileDate() -> UInt16 {
        let calender = Calendar(identifier: .gregorian)
        
        let day = calender.component(.day, from: self)
        let month = calender.component(.month, from: self)
        let year = calender.component(.year, from: self)
        
        let dayMask = UInt16(day) & 0x001f
        let monthMask = (UInt16(month) << 5) & 0x01e0
        let yearMask = (UInt16(year - 1980) << 9) & 0xfe00
        
        return dayMask | monthMask | yearMask
    }
}


