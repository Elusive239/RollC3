# RollC3 [![License](https://img.shields.io/badge/license-MIT-blue.svg)](https://github.com/Elusive239/rollC3/blob/main/LICENSE) ![Static Badge](https://img.shields.io/badge/C3-darkblue?link=https%3A%2F%2Fc3-lang.org%2F) ![Static Badge](https://img.shields.io/badge/Roll-red?link=https%3A%2F%2Fgithub.com%2Fdarkliquid%2Froll%2Ftree%2Fmaster)


A port of a *[Roll20](https://wiki.roll20.net/How_to_Roll_Dice)-like* dice roller, [*Roll*](https://github.com/darkliquid/roll.git) (Originally written in Go by [darkliquid](https://github.com/darkliquid/roll/tree/master)) to [*C3*](https://c3-lang.org/).  

> [!NOTE]  
> There are some inconsistencies between this dice roller, the original Go version, and Roll20. To have them behave the same requires some major refactoring, But i'm currently very happy where this is. There may be a fork of this in the future that works on that.

## Usage

```C++
module main;

import roll; 
import std::io;
import std::math::random ;

fn void main() {
    // random::srand(SEED_HERE); // OPTIONAL!
    @pool() {
        String? output = roll::parse(io::stdin(), tmem);
        if(catch err = output) err?!!;
        io::printfn("%s", output);
    };
}
```

Then run `echo "12d6-3" | c3c run` to get something like:  
`Rolled "12d6-3" and got 3, 3, 2, 5, 2, 2, 6, 3, 1, 3, 1, 6 for a total of 34`

Important to note, group rolls require wrapping braces like:  
`echo "1d6 + 1d6 + 1d6"`    -> fails!  
`echo "{1d6 + 1d6 + 1d6}"`  -> does not!  
