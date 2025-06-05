# RollC3 [![License](https://img.shields.io/badge/license-MIT-blue.svg)](https://github.com/Elusive239/rollC3/blob/main/LICENSE) ![Static Badge](https://img.shields.io/badge/C3-darkblue?link=https%3A%2F%2Fc3-lang.org%2F) ![Static Badge](https://img.shields.io/badge/Roll-red?link=https%3A%2F%2Fgithub.com%2Fdarkliquid%2Froll%2Ftree%2Fmaster)


So I was going to make my own fancy dice engine in C3, and try to follow the [Roll20](https://wiki.roll20.net/How_to_Roll_Dice) rules for rolling, when I discovered [**Roll**](https://github.com/darkliquid/roll.git) which happened do everything I wanted... but in the wrong language (Go)!  

so NOW this is a port of **Roll** to [C3](https://c3-lang.org/), **RollC3**!  It *should* be on par with the original go implementation, and there are some portions I feel could do with a minor rewrite, but this isn't entirely tested. Use at your own risk...

> [!NOTE]  
> Upon furthere testing, I realized there are still some inconsistencies between this dice roller and Roll20. To actually have them behave the same I might have to do some rewriting, so I'm thinking of making a fork, and keeping this as it is.