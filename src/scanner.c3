module roll;
import std::io;
import std::collections::tuple;

alias Rune = char;
alias Token = int;

alias TokenLiteral = Tuple{Token, String};

Rune eof;

// Return true if ch is a whitespace character
fn bool isWhitespace(Rune ch) {
	return ch == ' ' || ch == '\t' || ch == '\n';
}

// Return true if ch is a number
fn bool isNumber(Rune ch) {
	return ch >= '0' && ch <= '9';
}

// Return true if ch is a weird die character
fn bool isDieChar(Rune ch) {
	return ch == 'F' || ch == 'f';
}

// Return true if ch is a comparison character
fn bool isCompare(Rune ch) {
	return ch == '<' || ch == '>' || ch == '=';
}

// Return true if ch is a modifier character
fn bool isModifier(Rune ch) {
	return ch == '+' || ch == '-';
}

// Return true if ch is an exploding character
fn bool isExploding(Rune ch) {
	return ch == '!';
}

// Return true if ch is a reroll character
fn bool isReroll(Rune ch) {
	return ch == 'r';
}

// Return true if ch is a grouping character
fn bool isGrouping(Rune ch) {
	return ch == '{' || ch == ',' || ch == '}';
}

// Return true if ch is a keep limit character
fn bool isKeepLimit(Rune ch) {
	return ch == 'k';
}

// Return true if ch is a valid character for indicating a die roll
fn bool isValidDieRoll(Rune ch) {
	return !isWhitespace(ch) && !isGrouping(ch) && !isReroll(ch) && !isExploding(ch) && !isCompare(ch) && !isModifier(ch) && !isKeepLimit(ch) && ch != 'd' && ch != 'D';
}

// Scanner is our lexical scanner for dice roll strings
struct TokenScanner{
	InStream r;
}

// NewScanner returns a new instance of scanner
macro TokenScanner* newScanner(InStream r)  {
	if (&r.pushback_byte) return &&((TokenScanner){.r = r});
	DString tmp;
	tmp.tinit();
	tmp.read_from_stream(r)!!;
	ByteReader buffer;
	return &&((TokenScanner){.r = &(*buffer.init(tmp.str_view()))});
}

// Scan returns the next token and literal value
fn TokenLiteral TokenScanner.scan(TokenScanner* s, Allocator alloc =tmem) {
	Rune ch = s.read();
	
    DString buf;
    defer buf.free();
    buf.append_char(ch);

	switch {
	case isWhitespace(ch):
		s.unread();
		return s.scanWhitespace(alloc);
	case isNumber(ch):
		s.unread();
		return s.scanNumber(alloc);
	case ch == 'd':
		s.unread();
		return s.scanDieOrDrop(alloc);
	case ch == 'f':
		// return FAILURES, string(ch);
        return {.first = FAILURES, .second = buf.copy_str(allocator: alloc)};
	case ch == '!':
		s.unread();
		return s.scanExplosions(alloc);
	case ch == 'k':
		s.unread();
		return s.scanKeep(alloc);
	case ch == 'r':
		s.unread();
		return s.scanReroll(alloc);
	case ch == 's':
		s.unread();
		return s.scanSort(alloc);
	case ch == '-':
		// return MINUS, string(ch)
        return {.first = MINUS, .second = buf.copy_str(allocator: alloc)};
	case ch == '+':
		// return PLUS, string(ch)
        return {.first = PLUS, .second = buf.copy_str(allocator: alloc)};
	case ch == '>':
		// return GREATER, string(ch)
        return {.first = GREATER, .second = buf.copy_str(allocator: alloc)};
	case ch == '<':
		// return LESS, string(ch)
        return {.first = LESS, .second = buf.copy_str(allocator: alloc)};
	case ch == '=':
		// return EQUAL, string(ch)
        return {.first = EQUAL, .second = buf.copy_str(allocator: alloc)};
	case ch == '{':
		// return GROUPSTART, string(ch)
        return {.first = GROUPSTART, .second = buf.copy_str(allocator: alloc)};
	case ch == '}':
		// return GROUPEND, string(ch)
        return {.first = GROUPEND, .second = buf.copy_str(allocator: alloc)};
	case ch == ',':
		// return GROUPSEP, string(ch)
        return {.first = GROUPSEP, .second = buf.copy_str(allocator: alloc)};
	case (ch == eof):
        return {.first = EOF, .second = ""};
	}

    return {.first = ILLEGAL, .second = buf.copy_str(allocator: alloc)};
}

// scanWhitespace consumes the current Rune and all contiguous whitespace.
fn TokenLiteral TokenScanner.scanWhitespace(TokenScanner* s, Allocator alloc) {
	// Create a buffer and read the current character into it.
	DString buf;
    defer buf.free();
    buf.append(s.read());

	// Read every subsequent whitespace character into the buffer.
	// Non-whitespace characters and EOF will cause the loop to exit.
	while(true) {
        Rune ch = s.read();
		if (ch == eof) {
			break;
		} else if (!isWhitespace(ch)) {
			s.unread();
			break;
		} else {
            buf.append_char(ch);
		}
	}

    return {.first = WS, .second = buf.copy_str(allocator: alloc)};
}

// scanNumber consumes the current Rune and all contiguous number Runes.
fn TokenLiteral TokenScanner.scanNumber(TokenScanner* s, Allocator alloc) {
	// Create a buffer and read the current character into it.
	DString buf;
    defer buf.free();
    buf.append(s.read());

	// Read every subsequent number character into the buffer.
	// Non-number characters and EOF will cause the loop to exit.
	while(true) {
        Rune ch = s.read();
		if (ch == eof) {
			break;
		} else if (!isNumber(ch)) {
			s.unread();
			break;
		} else {
			buf.append_char(ch);
		}
	}

	// Otherwise return as a regular identifier.
    return {.first = NUM, .second = buf.copy_str(allocator: alloc)};
}

// scanDieOrDrop consumes the current Rune and all contiguous die/drop Runes.
fn TokenLiteral TokenScanner.scanDieOrDrop(TokenScanner* s, Allocator alloc)  {
	// Create a buffer and read the current character into it.
	DString buf;
    defer buf.free();
    buf.append(s.read());

	// Read every subsequent character into the buffer.
	// We assume a die token by default and switch based on subsequent chars.
	Token tok = DIE;
	while (true){
		Rune ch = s.read();
		if (ch == eof) {
			break;
		} else if (tok == DIE && ch == 'l') {
			tok = DROPLOW;
		} else if (tok == DIE && ch == 'h') {
			tok = DROPHIGH;
		} else if (tok == DIE && !isNumber(ch) && !isDieChar(ch)) {
			if (isValidDieRoll(ch)) {
				// _, _ = buf.WriteRune(ch)
                buf.append_char(ch);
			}
			s.unread();
			break;
		} else if (tok != DIE && !isNumber(ch) ){
			if (isValidDieRoll(ch)) {
				// _, _ = buf.WriteRune(ch)
                buf.append_char(ch);
			}
			s.unread();
			break;
		}
		// _, _ = buf.WriteRune(ch)
        buf.append_char(ch);
	}

	// Otherwise return as a regular identifier.
	return {.first = tok, .second = buf.copy_str(allocator: alloc)};
}

// scanKeep consumes the current Rune and all contiguous keep Runes.
fn TokenLiteral TokenScanner.scanKeep(TokenScanner* s, Allocator alloc)  {
	// Create a buffer and read the current character into it.
	DString buf;
    defer buf.free();
    buf.append(s.read());

	// Read every subsequent character into the buffer.
	// We assume an illegal token by default and switch based on later chars.
	Token tok = ILLEGAL;
	while(true) {
		Rune ch = s.read();

		if (ch == eof) {
			break;
		} else if (tok == ILLEGAL && ch == 'l') {
			tok = KEEPLOW;
		} else if (tok == ILLEGAL && ch == 'h') {
			tok = KEEPHIGH;
		} else if (tok != ILLEGAL && !isNumber(ch)) {
			s.unread();
			break;
		}
        buf.append_char(ch);
	}

	// Otherwise return as a regular identifier.
	return {.first = tok, .second = buf.copy_str(allocator: alloc)};
}

// scanExplosions consumes the current Rune and all contiguous explode Runes.
fn TokenLiteral TokenScanner.scanExplosions(TokenScanner* s, Allocator alloc) {
	// Create a buffer and read the current character into it.
	DString buf;
    defer buf.free();
    buf.append(s.read());

	// Read every subsequent character into the buffer.
	// We assume an explode token by default and switch based on later chars.
	Token tok = EXPLODE;

	Rune ch = s.read();
	if ((ch == eof)) {
		return {.first = tok, .second = buf.copy_str(allocator: alloc)};
	}

	if( ch == '!') {
		tok = COMPOUND;
		buf.append_char(ch);
	} else if (ch == 'p') {
		tok = PENETRATE;
		// _, _ = buf.WriteRune(ch)
        buf.append_char(ch);
	} else {
		s.unread();
	}

	// Otherwise return as a regular identifier.
	return {.first = tok, .second = buf.copy_str(allocator: alloc)};
}

// scanReroll consumes the current Rune and all contiguous reroll Runes.
fn TokenLiteral TokenScanner.scanReroll(TokenScanner* s, Allocator alloc) {
	// Create a buffer and read the current character into it.
	DString buf;
    defer buf.free();
    buf.append(s.read());

	// Read every subsequent character into the buffer.
	// Rerolls are simple flags with an optional modifier
	Token tok = REROLL;

	Rune ch = s.read();
	if ((ch == eof)) {
		return {.first = tok, .second = buf.copy_str(allocator: alloc)};
	}

	if (ch == 'o') {
		buf.append_char(ch);
	} else {
		s.unread();
	}

	// Otherwise return as a regular identifier.
	return {.first = tok, .second = buf.copy_str(allocator: alloc)};
}

// scanSort consumes the current Rune and all contiguous sort Runes.
fn TokenLiteral TokenScanner.scanSort(TokenScanner* s, Allocator alloc) {
	// Create a buffer and read the current character into it.
	// var buf bytes.Buffer
	// buf.WriteRune(s.read())
    DString buf;
    defer buf.free();
    buf.append_char(s.read());

	// Read every subsequent character into the buffer.
	// Sorts are simple flags with an optional modifier
	Token tok = SORT;

	Rune ch = s.read();
	if ((ch == eof)) {
		return {.first = tok, .second = buf.copy_str(allocator: alloc)};
	}

	if (ch == 'd' ){
        buf.append_char(ch);
	} else {
		s.unread();
	}

	// Otherwise return as a regular identifier.
	return {.first = tok, .second = buf.copy_str(allocator: alloc)};
}

// read reads the next Rune from the buffered reader.
// Returns the Rune(0) if an error occurs (or io.EOF is returned).
fn Rune TokenScanner.read(TokenScanner* s)  {
	// ch, _, err := s.r.ReadRune();
    Rune? ch = s.r.read_byte();
	if(catch ch) {
		return eof;
	}
	return ch;
}

// unread places the previously read Rune back on the reader.
fn void TokenScanner.unread(TokenScanner* s)  { 
    // _ = s.r.UnreadRune();
    @catch(s.r.pushback_byte());
 }