module roll;
import std::io;
import std::collections;

// Scanner is our lexical scanner for dice roll strings
struct TokenScanner{
	InStream r;
}

alias Rune = char;
alias Token = int;

alias TokenLiteral = Tuple{Token, String};

// DieRoll is the result of a die roll
struct DieRoll{
	int result; 
	String symbol;
}

macro void DieRoll.free(&dr, Allocator allocator = mem) {
	dr.symbol.free(allocator);
}

fn usz? DieRoll.to_format(&dr, Formatter* formatter) @dynamic {
	return formatter.printf("%s(%d)", dr.symbol, dr.result)!;
}

// Die is the interface allDice must confirm to
interface Die : Printable {
	fn DieRoll roll();
	// fn String to_string(Allocator);
}

// FateDie is a die representing the typical Fate/Fudge die
typedef FateDie (Die, Printable) = int;
// NormalDie is a die representing an N-sided die
typedef NormalDie (Die, Printable) = int;

