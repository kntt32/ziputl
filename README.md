# ziputl
A Swift package of Zip Utility build with only Swift Playgrounds App on iPad

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
ziputl.appendFile(name: "hello.txt", data: Data("hello, world!".utf8))
Task {
    do {
        await ziputl.saveAs(url: outputUrl)
    }catch(let err) {
        print(err)
    }
}
```
