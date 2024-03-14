// The Swift Programming Language
// https://docs.swift.org/swift-book

@main
struct App {
    static func main() {
        let lexer = Lexer()
        let parser = Parser(lexer: lexer)
        var driver = Driver(parser: parser)
        driver.mainLoop()
    }
}

