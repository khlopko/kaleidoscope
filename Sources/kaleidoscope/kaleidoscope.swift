// The Swift Programming Language
// https://docs.swift.org/swift-book

@main
struct App {
    static func main() {
        var lexer = Lexer()
        print(lexer.getTok(), lexer.identifierStr, lexer.numVal)
    }
}

