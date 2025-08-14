# ziputl
A Swift package of ZIP Utility Library build with only Swift Playgrounds App on iPad

## Requirment
- Swift Playgrounds App or XCode
- iOS 18.0+ or macOS 14.0+
- Swift 5.9

## Features
- Create and load stored ZIP files build by ziputl
- Add multile files to a ZIP archive
- Extract files from ZIP archives
- No external dependencies
- Build with only Swift Playgrounds App on iPad

## Install
Please see [Adding a Swift package to your app playground](https://developer.apple.com/documentation/swift-playgrounds/add-a-swift-package)

## Demo
```swift
import SwiftUI
import ZipUtl

struct ContentView: View {
    var body: some View {
        VStack {
            DemoView()
        }
    }
}
```

## Usage
```swift
let ziputl = ZipUtl(url: inputUrl)

Task {
    do {
        let files = try ziputl.extract()
        ziputl.appendFile(name: "hello.txt", data: Data("hello, world!".utf8))
        try await ziputl.saveAs(url: outputUrl)
    }catch(let err) {
        print(err)
    }
}
```

## Author
knt.t - https://github.com/kntt32
