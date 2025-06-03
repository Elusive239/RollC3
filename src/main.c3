module main;
import std::io;
import roll; 

fn void main() {
    // io::printfn("Hello World!");
    ByteReader br;
    br.init("6dF");
    Parser* parser = roll::newParser(&br);
    Roll? roll = parser.parse();
    Result result = roll.roll()!!;
    if(catch err = roll){
        io::printfn("%s", err);
    }
    io::printfn("roll = {%s}", roll!!);
    io::printfn("%s", result);
    // io::print("[");
    // foreach (res : result.results) io::printf("%d(%s), ", res.result, res.symbol);
    // io::printfn("] Total: %d, Successes: %d", result.total, result.successes);
}