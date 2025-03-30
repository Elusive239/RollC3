module roll;
import std::io;
import std::collections;

// Scanner is our lexical scanner for dice roll strings
struct TokenScanner{
	InStream r;
}

def Rune = char;
def Token = int;

def TokenLiteral = Tuple(<Token, String>);