module rollc3;
import std::io;

//USE BYTE READER
struct Scanner{
    inline InStream r;
}

// new_scanner returns a new instance of scanner
fn Scanner* new_scanner(InStream r) {
    Scanner* scanner = allocator::new(allocator::temp(), Scanner);
    scanner.r = r;
    return scanner;
}

// Scan returns the next token and literal value
fn Token Scanner.scan(Scanner* s) {
	Rune ch = s.read();
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
		return {EOF, ""};
	}

	return {ILLEGAL, string::tformat("%c", ch)};
}

// scan_white_space consumes the current rune and all contiguous whitespace.
fn Token Scanner.scan_white_space(Scanner* s) {
	// Create a buffer and read the current Runeacter into it.
    DString buf;
	buf.append_char(s.read());

	// Read every subsequent whitespace Runeacter into the buffer.
	// Non-whitespace Runeacters and R_EOF will cause the loop to exit.
	while(true) {
        Rune ch = s.read();
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
fn Token Scanner.scan_number(Scanner* s) {
	// Create a buffer and read the current Runeacter into it.
	DString buf;
	buf.append_char(s.read());

	// Read every subsequent number Runeacter into the buffer.
	// Non-number Runeacters and R_EOF will cause the loop to exit.
	while(true) {
        Rune ch = s.read();
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
fn Token Scanner.scan_die_or_drop(Scanner* s){
	// Create a buffer and read the current Runeacter into it.
	DString buf;
	buf.append_char(s.read());

	// Read every subsequent Runeacter into the buffer.
	// We assume a die token by default and switch based on subsequent Runes.
	TokenType tt = DIE;
	while(true){
		Rune ch = s.read();

		if (ch == R_EOF) {
			break;
		} else if (tt == DIE && ch == 'l') {
			tt = DROPLOW;
		} else if( tt == DIE && ch == 'h' ){
			tt = DROPHIGH;
		} else if (tt == DIE && !is_number(ch) && !is_die_Rune(ch)) {
			if (is_valid_die_roll(ch)) {
				buf.append_char(ch);
			}
			s.unread();
			break;
		} else if (tt != DIE && !is_number(ch) ){
			if (is_valid_die_roll(ch)) {
				buf.append_char(ch);
			}
			s.unread();
			break;
		}
		buf.append_char(ch);
	}

	// Otherwise return as a regular identifier.
	return {tt, buf.str_view().copy(allocator::temp())};
}

// scan_keep consumes the current rune and all contiguous keep runes.
fn Token Scanner.scan_keep(Scanner* s){
	// Create a buffer and read the current Runeacter into it.
	DString buf;
	buf.append_char(s.read());

	// Read every subsequent Runeacter into the buffer.
	// We assume an illegal token by default and switch based on later Runes.
	TokenType tt = ILLEGAL;
	while(true){
		Rune ch = s.read();

		if (ch == R_EOF) {
			break;
		} else if (tt == ILLEGAL && ch == 'l') {
			tt = KEEPLOW;
		} else if( tt == ILLEGAL && ch == 'h' ){
			tt = KEEPHIGH;
		} else if (tt != ILLEGAL && !is_number(ch)) {
			s.unread();
			break;
		}
		buf.append_char(ch);
	}

	// Otherwise return as a regular identifier.
	return {tt, buf.str_view().copy(allocator::temp())};
}

// scan_explosions consumes the current rune and all contiguous explode runes.
fn Token Scanner.scan_explosions(Scanner* s){
	// Create a buffer and read the current Runeacter into it.
	DString buf;
	buf.append_char(s.read());

	// Read every subsequent Runeacter into the buffer.
	// We assume an explode token by default and switch based on later Runes.
	TokenType tt = EXPLODE;

	Rune ch = s.read();
	if (ch == R_EOF) {
		return {tt, buf.str_view().copy(allocator::temp())};
	}

	if (ch == '!') {
		tt = COMPOUND;
		buf.append_char(ch);
	} else if (ch == 'p') {
		tt = PENETRATE;
		buf.append_char(ch);
	} else {
		s.unread();
	}

	// Otherwise return as a regular identifier.
	return {tt, buf.str_view().copy(allocator::temp())};
}

// scan_reroll consumes the current rune and all contiguous reroll runes.
fn Token Scanner.scan_reroll(Scanner* s){
	// Create a buffer and read the current Runeacter into it.
	DString buf;
	buf.append_char(s.read());

	// Read every subsequent Runeacter into the buffer.
	// Rerolls are simple flags with an optional modifier
	TokenType tt = REROLL;

	Rune ch = s.read();
	if (ch == R_EOF) {
		return {tt, buf.str_view().copy(allocator::temp())};
	}

	if( ch == 'o') {
		buf.append_char(ch);
	} else {
		s.unread();
	}

	// Otherwise return as a regular identifier.
	return {tt, buf.str_view().copy(allocator::temp())};
}

// scan_sort consumes the current rune and all contiguous sort runes.
fn Token Scanner.scan_sort(Scanner* s) {
	// Create a buffer and read the current Runeacter into it.
	DString buf;
	buf.append_char(s.read());

	// Read every subsequent Runeacter into the buffer.
	// Sorts are simple flags with an optional modifier
	TokenType tt = SORT;

	Rune ch = s.read();
	if (ch == R_EOF) {
		return {tt, buf.str_view().copy(allocator::temp())};
	}

	if (ch == 'd') {
		buf.append_char(ch);
	} else {
		s.unread();
	}

	// Otherwise return as a regular identifier.
	return {tt, buf.str_view().copy(allocator::temp())};
}

// read reads the next rune from the buffered reader.
// Returns the rune(0) if an error occurs (or io.R_EOF is returned).
fn Rune Scanner.read(Scanner* s) {
	Rune! ch = s.r.read_byte();
	if (catch ch) {
		return R_EOF;
	}
	return ch;
}

// unread places the previously read rune back on the reader.
fn void Scanner.unread(Scanner* s) => s.r.pushback_byte()!!;