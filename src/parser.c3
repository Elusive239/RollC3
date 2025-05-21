module roll;
import std::io;


fault ParserError {
    UNEXPECTED_TOKEN,
    UNKNOWN_DIE,
    END_OF_ROLL, 
    AMBIGUOUS_MODIFIER, 
}

struct ParsedDie{
	typeid type;
	int value;
}

struct Parser{
    TokenScanner* s;
	struct buf {
		TokenLiteral tlit;
		int    n;
	}
}

macro Parser* newParser(InStream r) => &&Parser{s = newScanner(r)};

// Parse parses a Roll statement.
fn Roll! Parser.parse(&p) {
	// First token should be a NUM or a DIE
	TokenLiteral tlit = p.scanIgnoreWhitespace();
	// tok, lit := 

	Roll! roll = p.parseRoll(tlit, false);
	// if e, ok := err.(ErrEndOfRoll); ok && e == "" {
	// 	err = nil
	// }
	if(catch err = roll){
		if(err == ParserError.END_OF_ROLL) unreachable("How do we deal with this if we can't return the roll AND an error...?");
		
	}
	return roll;
}

// parseRoll gets a roll of any type
fn Roll! Parser.parseRoll(&p, TokenLiteral tlit, bool grouped) { //(Roll, error) 
	switch (tlit.first) {
	case NUM:
	case DIE:
		// return p.parseDiceRoll(grouped);
		break;
	case GROUPSTART:
		break;
		// return p.parseGroupedRoll(grouped);
	default:
		// return nil, ErrUnexpectedToken(lit);
		return ParserError.UNEXPECTED_TOKEN?;
	}
	return ParserError.UNEXPECTED_TOKEN?;
}

//parseGroupedRoll V
 
//parseDiceRoll    V


fn RerollOp! Parser.parseReroll(&p, String lit) { //(rr RerollOp, err error)
	RerollOp rr;
	if (lit == "ro") {
		rr.once = true;
	}

	// determine the comparison operator for the reroll op
	ComparisonOp*! compOp = p.parseComparison();
	if (catch err = compOp) {
		return err?;
	}

	rr.comparison_op = compOp;
	return rr;
}

fn int! Parser.parseModifier(&p, Token tok) { //(int, error)
	int mult = 1;
	if (tok == MINUS) {
		mult = -1;
	}
	// Get modifer value
	TokenLiteral tlit = p.scanIgnoreWhitespace();

	if (tlit.first != NUM) {
		return ParserError.UNEXPECTED_TOKEN?;
	}

	// Add to statement modifer
	int! mod = tlit.second.to_int();
	if(catch err = mod) {
		p.unscan();
		return err?;
	}
	return mult*mod;
}

fn ParsedDie! Parser.parseDie(&p, String dieCode) { //(Die, error) 
	String trimmedDieCode = dieCode;
	trimmedDieCode.convert_ascii_to_upper();
	trimmedDieCode.strip("D");

	int! value = trimmedDieCode.to_int();
	if (try value ){
		return { NormalDie.typeid, value};
	}

	// Is it a Fate/Fudge die roll?
	if( trimmedDieCode == "F") {
		return {FateDie.typeid, 0};
	}

	return ParserError.UNKNOWN_DIE?;
}

fn ExplodingOp*! Parser.parseExplosion(&p, TokenLiteral tlit) { //(*ExplodingOp, error) 
	ExplodingOp* exp = &&ExplodingOp{};

	switch (tlit.first) {
		case EXPLODE:
			exp.type = EXPLODING;
		case COMPOUND:
			exp.type = COMPOUNDED;
		case PENETRATE:
			exp.type = PENETRATING;
		default:
			return ParserError.UNEXPECTED_TOKEN?;
	}

	// determine the comparison operator for the explosion op
	ComparisonOp*! comp = p.parseComparison();
	if (catch err = comp) {
		return err?;
	}
	exp.comparison_op = comp;
	return exp;
}

fn ComparisonOp*! Parser.parseComparison(&p)  { // (cmp *ComparisonOp, err error)
	TokenLiteral tlit = p.scan();
	ComparisonOp* cmp = &&ComparisonOp{};

	switch (tlit.first) {
		case NUM:
			int! value = tlit.second.to_int();

			if(catch e = value) {
				// return {e, null};
				return e?;
			}
			cmp.value = value;
			cmp.type = EQUALS;
			return cmp;
		case EQUAL:
			cmp.type = EQUALS;
		case GREATER:
			cmp.type = GREATER_THAN;
		case LESS:
			cmp.type = LESS_THAN;
		default:
			return ParserError.UNEXPECTED_TOKEN?;
	}

	tlit = p.scan();
	if (tlit.first != NUM) {
		return ParserError.UNEXPECTED_TOKEN?;
	}

	// cmp.Value, err = strconv.Atoi(lit)
    int! value = tlit.second.to_int();
	if (catch e = value) {
		return e?;
	}
    cmp.value = value;
   
	return cmp;
}

fn LimitOp*! Parser.parseLimit(&p, TokenLiteral tlit) { //(lmt *LimitOp, err error)
	LimitOp* lmt = &&LimitOp{
		.amount= 1,
	};
    String lit = tlit.second;
	switch (tlit.first) {
        case KEEPHIGH:
            lmt.type = KEEP_HIGHEST;
            lit.strip("kh");
        case KEEPLOW:
            lmt.type = KEEP_LOWEST;
            lit.strip("kl");
        case DROPHIGH:
            lmt.type = DROP_HIGHEST;
            lit.strip("dh");
        case DROPLOW:
            lmt.type = DROP_LOWEST;
            lit.strip("dl");
	}

	if (lit != "") {
        int! new_amount = lit.to_int();
        if(catch e = new_amount){
            return e?;
        }else{
            lmt.amount = new_amount;
        }
	}
	return lmt;
}

// scan returns the next token from the underlying scanner.
// If a token has been unscanned then read that instead.
fn TokenLiteral Parser.scan(&p) {
	// If we have a token on the buffer, then return it.
	if (p.buf.n != 0) {
		p.buf.n = 0;
		return p.buf.tlit;
	}

	// Otherwise read the next token from the scanner.
	TokenLiteral tlit = p.s.scan();

	// Save it to the buffer in case we unscan later.
	p.buf.tlit = tlit;

	return tlit;
}

// unscan pushes the previously read token back onto the buffer.
fn void Parser.unscan(&p) {
    p.buf.n = 1;
}

// scanIgnoreWhitespace scans the next non-whitespace token.
fn TokenLiteral Parser.scanIgnoreWhitespace(&p){
    TokenLiteral tlit = p.s.scan();
	if (tlit.first == WS) {
		tlit = p.scan();
	}
	return tlit;
}