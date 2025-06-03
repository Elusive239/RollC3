module roll::tests;
import roll;
import std::io;

struct ScannerTestStruct{
    TokenLiteral tlit;
    String s;
}

// Ensure the scanner can scan tokens correctly.
fn void scanner_test() @test {
	ScannerTestStruct[*] tests = (ScannerTestStruct[]){
		// Special tokens (EOF, ILLEGAL, WS)
		{.s = "", .tlit = { .first = roll::EOF, .second = ""}},
		{.s = "#", .tlit = { .first = roll::ILLEGAL, .second = "#"}},
		{.s = " ", .tlit = { .first = roll::WS, .second = " "}},
		{.s = "\t", .tlit = { .first = roll::WS, .second = "\t"}},
		{.s = "\n", .tlit = { .first = roll::WS, .second = "\n"}},

		// Numbers
		{.s = "3", .tlit = { .first = roll::NUM, .second = "3"}},
		{.s = "123", .tlit = { .first = roll::NUM, .second = "123"}},

		// Dice
		{.s = "d200", .tlit = { .first = roll::DIE, .second = "d200"}},
		{.s = "dF", .tlit = { .first = roll::DIE, .second = "dF"}},
		{.s = "d4d5", .tlit = { .first = roll::DIE, .second = "d4"}},
		{.s = "d6!!", .tlit = { .first = roll::DIE, .second = "d6"}},
		{.s = "d6r", .tlit = { .first = roll::DIE, .second = "d6"}},
		{.s = "d6}", .tlit = { .first = roll::DIE, .second = "d6"}},
		{.s = "d6 ", .tlit = { .first = roll::DIE, .second = "d6"}},
		{.s = "d6kh3", .tlit = { .first = roll::DIE, .second = "d6"}},

		// Modifiers
		{.s = "+", .tlit = { .first = roll::PLUS, .second = "+"}},
		{.s = "-", .tlit = { .first = roll::MINUS, .second = "-"}},

		// Extra rules
		{.s = "f", .tlit = { .first = roll::FAILURES, .second = "f"}},
		{.s = "!", .tlit = { .first = roll::EXPLODE, .second = "!"}},
		{.s = "!!", .tlit = { .first = roll::COMPOUND, .second = "!!"}},
		{.s = "!p", .tlit = { .first = roll::PENETRATE, .second = "!p"}},
		{.s = "kh", .tlit = { .first = roll::KEEPHIGH, .second = "kh"}},
		{.s = "kh3", .tlit = { .first =roll::KEEPHIGH, .second = "kh3"}},
		{.s = "kl", .tlit = { .first = roll::KEEPLOW, .second = "kl"}},
		{.s = "kl3", .tlit = { .first = roll::KEEPLOW, .second = "kl3"}},
		{.s = "kx", .tlit = { .first = roll::ILLEGAL, .second = "kx"}},
		{.s = "dh", .tlit = { .first = roll::DROPHIGH, .second = "dh"}},
		{.s = "dh3", .tlit = { .first = roll::DROPHIGH, .second = "dh3"}},
		{.s = "dl", .tlit = { .first = roll::DROPLOW, .second = "dl"}},
		{.s = "dl3", .tlit = { .first = roll::DROPLOW, .second = "dl3"}},
		{.s = "r", .tlit = { .first = roll::REROLL, .second = "r"}},
		{.s = "ro", .tlit = { .first = roll::REROLL, .second = "ro"}},
		{.s = "s", .tlit = { .first = roll::SORT, .second = "s"}},
		{.s = "sd", .tlit = { .first = roll::SORT, .second = "sd"}},

		// Tests
		{.s = ">", .tlit = { .first = roll::GREATER, .second = ">"}},
		{.s = "<", .tlit = { .first = roll::LESS, .second = "<"}},
		{.s = "=", .tlit = { .first = roll::EQUAL, .second = "="}},

		// Grouping
		{.s = "{", .tlit = { .first = roll::GROUPSTART, .second = "{"}},
		{.s = "}", .tlit = { .first = roll::GROUPEND, .second = "}"}},
		{.s = ",", .tlit = { .first = roll::GROUPSEP, .second = ","}},
	};

	foreach (i, tt : tests) {
        ByteReader bytes;
        bytes.init(tt.s);
		@pool() {
			TokenScanner* s = roll::newScanner(&bytes);
			TokenLiteral tlit =  s.scan();
			assert(tt.tlit.first == tlit.first, "%d. %q token mismatch: exp=%q got=%q <%q>", i, tt.s, tt.tlit.first, tlit.first, tlit.second);
			assert(tt.tlit.second == tlit.second, "%d. %q literal mismatch: exp=%q got=%q", i, tt.s, tt.tlit.first, tlit.first);
		};
	}
}