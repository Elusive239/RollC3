module main;

import roll; 
import std::io;
import std::math::random ;

fn void main() {
    // random::srand(SEED_HERE);
    @pool() {
        String? output = roll::parse(io::stdin(), tmem);
        if(catch err = output) err?!!;
        io::printfn("%s", output);
    };
}