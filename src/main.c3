module main;

import roll; 
import std::io;
import std::math::random ;

fn int main() {
    // random::srand(SEED_HERE);
    @pool() {
        // String? output = roll::parse(io::stdin(), tmem);
        String input = "{d6 + 5 + 6}";
        String? output = roll::parse_string(input, tmem);
        io::printfn("Actual Input: %s", input);
        if(catch err = output) {
            io::printfn("Err: %s", err);
            return 1;
        }else{
            io::printfn("%s", output);
            return 0;
        }
    };
}