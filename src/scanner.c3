module rollc3;
import std::io;
import std::math;
import std::math::random;
import std::collections::list;
import std::collections::tuple;

def Rune = char;

const Rune R_EOF = 0;

// Return true if ch is a whitespace Runeacter
fn bool is_whitespace(Rune ch) => ch == ' ' || ch == '\t' || ch == '\n';

// Return true if ch is a number
fn bool is_number(Rune ch) => ch >= '0' && ch <= '9';

// Return true if ch is a weird die Runeacter
fn bool is_die_Rune(Rune ch) => ch == 'F' || ch == 'f';

// Return true if ch is a comparison Runeacter
fn bool is_compare(Rune ch) => ch == '<' || ch == '>' || ch == '=';

// Return true if ch is a modifier Runeacter
fn bool is_modifier(Rune ch) => ch == '+' || ch == '-';

// Return true if ch is an exploding Runeacter
fn bool is_exploding(Rune ch) => ch == '!';

// Return true if ch is a reroll Runeacter
fn bool is_reroll(Rune ch) => ch == 'r';

// Return true if ch is a grouping Runeacter
fn bool is_grouping(Rune ch) => ch == '{' || ch == ',' || ch == '}';

// Return true if ch is a keep limit Runeacter
fn bool is_keep_limit(Rune ch) => ch == 'k';

// Return true if ch is a valid Runeacter for indicating a die roll
fn bool is_valid_die_roll(Rune ch) => !is_whitespace(ch) && !is_grouping(ch) && !is_reroll(ch) && !is_exploding(ch) && !is_compare(ch) && !is_modifier(ch) && !is_keep_limit(ch) && ch != 'd' && ch != 'D';

//USE BYTE BUFFER
struct Scanner{
    inline InStream* r;
}

// new_scanner returns a new instance of scanner
fn Scanner* new_scanner(InStream* r) {
    Scanner* scanner = allocator::new(allocator::temp(), Scanner);
    scanner.r = r;
    return scanner;
}

def TokenAndLit = Tuple(<Token, String>);

// Scan returns the next token and literal value
fn TokenAndLit Scanner.scan(Scanner* s) {
	io::printfn("Hi!");
	Rune ch = s.read();
	io::printfn("Hi!");
	switch {
	case is_whitespace(ch):
		s.unread();
		return s.scan_white_space();
	case is_number(ch):
		s.unread();
		return s.scan_number();
	case ch == 'd':
		s.unread();
		return s.scan_die_or_drop();
	case ch == 'f':
		return {FAILURES, string::tformat("%c", ch)};
	case ch == '!':
		s.unread();
		return s.scan_explosions();
	case ch == 'k':
		s.unread();
		return s.scan_keep();
	case ch == 'r':
		s.unread();
		return s.scan_reroll();
	case ch == 's':
		s.unread();
		return s.scan_sort();
	case ch == '-':
		return {MINUS, string::tformat("%c", ch)};
	case ch == '+':
		return {PLUS, string::tformat("%c", ch)};
	case ch == '>':
		return {GREATER, string::tformat("%c", ch)};
	case ch == '<':
		return {LESS, string::tformat("%c", ch)};
	case ch == '=':
		return {EQUAL, string::tformat("%c", ch)};
	case ch == '{':
		return {GROUPSTART, string::tformat("%c", ch)};
	case ch == '}':
		return {GROUPEND, string::tformat("%c", ch)};
	case ch == ',':
		return {GROUPSEP, string::tformat("%c", ch)};
	case ch == R_EOF:
		return {R_EOF, ""};
	}

	return {ILLEGAL, string::tformat("%c", ch)};
}

// scan_white_space consumes the current rune and all contiguous whitespace.
fn TokenAndLit Scanner.scan_white_space(Scanner* s) {
	// Create a buffer and read the current Runeacter into it.
    DString buf;
	buf.append_char(s.read());

	// Read every subsequent whitespace Runeacter into the buffer.
	// Non-whitespace Runeacters and R_EOF will cause the loop to exit.
	while(true) {
        Rune ch = s.read();;
		if ( ch == R_EOF) {
			break;
		} else if (!is_whitespace(ch)) {
			s.unread();
			break;
		} else {
			buf.append_char(ch);
		}
	}

	return {WS, buf.str_view().copy(allocator::temp())};
}

// scan_number consumes the current rune and all contiguous number runes.
fn TokenAndLit Scanner.scan_number(Scanner* s) {
	// Create a buffer and read the current Runeacter into it.
	DString buf;
	buf.append_char(s.read());

	// Read every subsequent number Runeacter into the buffer.
	// Non-number Runeacters and R_EOF will cause the loop to exit.
	while(true) {
        Rune ch = s.read();;
		if (ch == R_EOF) {
			break;
		} else if (!is_number(ch)) {
			s.unread();
			break;
		} else {
			buf.append_char(ch);
		}
	}

	// Otherwise return as a regular identifier.
	return {NUM, buf.str_view().copy(allocator::temp())};
}

// scan_die_or_drop consumes the current rune and all contiguous die/drop runes.
fn TokenAndLit Scanner.scan_die_or_drop(Scanner* s){
	// Create a buffer and read the current Runeacter into it.
	DString buf;
	buf.append_char(s.read());

	// Read every subsequent Runeacter into the buffer.
	// We assume a die token by default and switch based on subsequent Runes.
	Token tok = DIE;
	while(true){
		Rune ch = s.read();

		if (ch == R_EOF) {
			break;
		} else if (tok == DIE && ch == 'l') {
			tok = DROPLOW;
		} else if( tok == DIE && ch == 'h' ){
			tok = DROPHIGH;
		} else if (tok == DIE && !is_number(ch) && !is_die_Rune(ch)) {
			if (is_valid_die_roll(ch)) {
				buf.append_char(ch);
			}
			s.unread();
			break;
		} else if (tok != DIE && !is_number(ch) ){
			if (is_valid_die_roll(ch)) {
				buf.append_char(ch);
			}
			s.unread();
			break;
		}
		buf.append_char(ch);
	}

	// Otherwise return as a regular identifier.
	return {tok, buf.str_view().copy(allocator::temp())};
}

// scan_keep consumes the current rune and all contiguous keep runes.
fn TokenAndLit Scanner.scan_keep(Scanner* s){
	// Create a buffer and read the current Runeacter into it.
	DString buf;
	buf.append_char(s.read());

	// Read every subsequent Runeacter into the buffer.
	// We assume an illegal token by default and switch based on later Runes.
	Token tok = ILLEGAL;
	while(true){
		Rune ch = s.read();;

		if (ch == R_EOF) {
			break;
		} else if (tok == ILLEGAL && ch == 'l') {
			tok = KEEPLOW;
		} else if( tok == ILLEGAL && ch == 'h' ){
			tok = KEEPHIGH;
		} else if (tok != ILLEGAL && !is_number(ch)) {
			s.unread();
			break;
		}
		buf.append_char(ch);
	}

	// Otherwise return as a regular identifier.
	return {tok, buf.str_view().copy(allocator::temp())};
}

// scan_explosions consumes the current rune and all contiguous explode runes.
fn TokenAndLit Scanner.scan_explosions(Scanner* s){
	// Create a buffer and read the current Runeacter into it.
	DString buf;
	buf.append_char(s.read());

	// Read every subsequent Runeacter into the buffer.
	// We assume an explode token by default and switch based on later Runes.
	Token tok = EXPLODE;

	Rune ch = s.read();
	if (ch == R_EOF) {
		return {tok, buf.str_view().copy(allocator::temp())};
	}

	if (ch == '!') {
		tok = COMPOUND;
		buf.append_char(ch);
	} else if (ch == 'p') {
		tok = PENETRATE;
		buf.append_char(ch);
	} else {
		s.unread();
	}

	// Otherwise return as a regular identifier.
	return {tok, buf.str_view().copy(allocator::temp())};
}

// scan_reroll consumes the current rune and all contiguous reroll runes.
fn TokenAndLit Scanner.scan_reroll(Scanner* s){
	// Create a buffer and read the current Runeacter into it.
	DString buf;
	buf.append_char(s.read());

	// Read every subsequent Runeacter into the buffer.
	// Rerolls are simple flags with an optional modifier
	Token tok = REROLL;

	Rune ch = s.read();
	if (ch == R_EOF) {
		return {tok, buf.str_view().copy(allocator::temp())};
	}

	if( ch == 'o') {
		buf.append_char(ch);
	} else {
		s.unread();
	}

	// Otherwise return as a regular identifier.
	return {tok, buf.str_view().copy(allocator::temp())};
}

// scan_sort consumes the current rune and all contiguous sort runes.
fn TokenAndLit Scanner.scan_sort(Scanner* s) {
	// Create a buffer and read the current Runeacter into it.
	DString buf;
	buf.append_char(s.read());

	// Read every subsequent Runeacter into the buffer.
	// Sorts are simple flags with an optional modifier
	Token tok = SORT;

	Rune ch = s.read();;
	if (ch == R_EOF) {
		return {tok, buf.str_view().copy(allocator::temp())};
	}

	if (ch == 'd') {
		buf.append_char(ch);
	} else {
		s.unread();
	}

	// Otherwise return as a regular identifier.
	return {tok, buf.str_view().copy(allocator::temp())};
}

// read reads the next rune from the buffered reader.
// Returns the rune(0) if an error occurs (or io.R_EOF is returned).
fn Rune Scanner.read(Scanner* s) {
	io::printfn("hi");
	InStream stream = *s.r;
	io::printfn("hi");
	Rune! ch = stream.read_byte();
	io::printfn("hi");
	if (catch ch) {
		return R_EOF;
	}
	return ch;
}

// unread places the previously read rune back on the reader.
fn void Scanner.unread(Scanner* s) => s.r.pushback_byte()!!;