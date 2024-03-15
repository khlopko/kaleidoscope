// The compiler entry point

@main
struct App {
    static func main() {
        let lexer = Lexer()
        let parser = Parser(lexer: lexer)
        if let codegen = Codegen() {
            var driver = Driver(parser: parser, codegen: codegen)
            driver.mainLoop()
        } else {
            print("Failed to load codegen submodule of compiler")
        }
    }
}

