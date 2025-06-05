module main;
import std::io;
import roll; 
import std::math::random;

fn int main(String[] args) => @pool() {
    if(args.len <2 ) {
        io::printfn("Requires 1 min argument..");
        return 1;
    }
    String input = string::join (tmem, args[1..], "").trim();
    String? output = roll::parse_string(input);
    defer (void) output.free(mem);
    if(catch err = output) err?!!;
    io::printfn("%s", output);
    return 0;
}