module main;
import std::io;
import roll; 
import std::math::random;

fn void main(String[] args) {
    String input = args[1];
    String? output = roll::parse_string(input);
    defer (void) output.free(mem);
    if(catch err = output) {
        io::printfn("Error: %s", err);
    }else{
        io::printfn("%s", output);
    }
}