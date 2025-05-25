module roll;
import std::io;
import std::core::mem::allocator;

const usz PARSER_DEFAULT_ALLOC = 1024;


faultdef UNEXPECTED_TOKEN;
faultdef UNKNOWN_DIE;
faultdef END_OF_ROLL;
faultdef AMBIGUOUS_MODIFIER;

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
	DynamicArenaAllocator alloc;
}

macro Parser* newParser(InStream r, Allocator alloc = allocator::temp()) {
	Parser* parser = && (Parser){.s = newScanner(r), .alloc = {}};
	parser.alloc.init(alloc, PARSER_DEFAULT_ALLOC);
	return parser;
}
// Parse parses a Roll statement.
macro Roll? Parser.parse(&p) {
	p.alloc.reset();
	// First token should be a NUM or a DIE
	TokenLiteral tlit = p.scanIgnoreWhitespace();
	// tok, lit := 

	Roll roll;
	// if e, ok := err.(ErrEndOfRoll); ok && e == "" {
	// 	err = nil
	// }
	if(catch err =  p.parseRoll(&roll, tlit, false)){
		if(err == END_OF_ROLL) return roll; //unreachable("How do we deal with this if we can't return the roll AND an error...?");
		return err?;
	}
	return roll;
}

// parseRoll gets a roll of any type
fn void? Parser.parseRoll(&p, Roll* roll, TokenLiteral tlit, bool grouped) { //(Roll, error) 
	switch (tlit.first) {
		case NUM:
		case DIE:
			DiceRoll* rd = p.pclone((DiceRoll){});
			p.parseDiceRoll(rd, grouped)!;
			*roll = rd;
		case GROUPSTART:
			GroupedRoll* rd = p.pclone((GroupedRoll){});
			p.parseGroupedRoll(rd, grouped)!;
			*roll = rd;
		default:
			// return nil, ErrUnexpectedToken(lit);
			return UNEXPECTED_TOKEN?;
	}
	return UNEXPECTED_TOKEN?;
}

//parseGroupedRoll V

 // parseGrouped parses a GroupedRoll statement
fn void? Parser.parseGroupedRoll(&p, GroupedRoll* roll, bool grouped) { // (roll *GroupedRoll, err error) 

}
//parseDiceRoll    V
// parseDiceRoll parses a DiceRoll statement
fn void? Parser.parseDiceRoll(&p, DiceRoll* roll, bool grouped) { // (roll *GroupedRoll, err error) 
	roll = p.pclone((DiceRoll){});
	TokenLiteral tlit = p.buf.tlit;
	
	// If NUM, we store it as the multiplier, else we use 1
	if (tlit.first == NUM) {
		roll.multiplier = tlit.second.to_int()!;

		tlit = p.scanIgnoreWhitespace();
		if (tlit.first != DIE) {
			return UNEXPECTED_TOKEN?;
		}
	} else {
		roll.multiplier = 1;
	}

	// We will have a DIE token here, so parse it
	io::printfn("TokenLiteral: %s, %s", tlit.first, tlit.second);
	ParsedDie? die = p.parseDie(tlit.second);
	if (catch err = die) {
		return err?;
	}
	if(die.type == NormalDie.typeid ){
		roll.die = p.pclone(((NormalDie) die.value));
	} else if(die.type == FateDie.typeid ){
		roll.die = p.pclone(((FateDie) 0));
	}

	int mod;
	Token lastTok;

	while (true) {
		// Read a modifier
		tlit = p.scanIgnoreWhitespace();

		// Handle modifier or EOF
		switch (tlit.first) {
		case PLUS:
		case MINUS:

			int? moderr = p.parseModifier(tlit.first);
			if ( try moderr ) {
				mod = moderr;
				roll.modifier += mod;
			}
			if (catch err = moderr){
				if (tlit.first == MINUS) {
					mod = -1;
				}

				p.unscan();
				tlit = p.scanIgnoreWhitespace();
				switch (tlit.first) {
				case EOF:
					return END_OF_ROLL?;
				case GROUPSTART:
					if (grouped) {
						// Technically this is an end of roll, but we want to
						// capture the multiplier to determine the sign of the
						// next term
						// err = ErrAmbiguousModifier(mod)
						return AMBIGUOUS_MODIFIER?;
					}
					return UNEXPECTED_TOKEN?;
					// return nil, ErrUnexpectedToken(lit)
				case GROUPEND:
				case GROUPSEP:
					if (grouped) {
						// err = ErrEndOfRoll(lit)
						// return
						return END_OF_ROLL?;
					}
					return UNEXPECTED_TOKEN?;
				default:
					return err?;
				}
			}
		case EXPLODE:
		case COMPOUND:
		case PENETRATE: 
			roll.exploding = p.parseExplosion(tlit)!;
		case KEEPHIGH:
		case KEEPLOW:
		case DROPHIGH:
		case DROPLOW:
		io::printfn("Limit!");
			roll.limit = p.parseLimit(tlit)!;
		case SORT:
			switch (tlit.second) {
			case "s":
				roll.sort = ASCENDING;
			case "sd":
				roll.sort = DESCENDING;
			}
		case REROLL:
			RerollOp? rr = p.parseReroll(tlit.second);
			if(try rr){
				usz elements = roll.rerolls.len;
				usz new_size = RerollOp.sizeof * (elements + 1);
				roll.rerolls = ((RerollOp*)allocator::realloc(allocator::temp(), (void*) roll.rerolls.ptr, new_size))[:elements+1];
				roll.rerolls[elements] = rr;
			}
		case GREATER:
		case LESS:
		case EQUAL:
			p.unscan();
			// ComparisonOp*? success = p.parseComparison();
			// if(try success){
			// 	roll.success = success;
			// }
			roll.success = p.parseComparison()!;
		case FAILURES:
			// roll.Failure, err = p.parseComparison()
			// ComparisonOp*? failure = p.parseComparison();
			// if(try failure){
			// 	roll.failure = failure;
			// }
			roll.failure = p.parseComparison()!;
		case EOF: return END_OF_ROLL?;
		case GROUPEND:
		case GROUPSEP: 
			if (grouped) {
				return END_OF_ROLL?;
			}
			return UNEXPECTED_TOKEN?;
		case DIE: 
			// It's ambiguous whether or not a +/- number is a modifier or a
			// a combined die roll. If grouped and we get a die character AND
			// the last token processed was a modifier, then we rewind and then
			// raise a special error to indicate it needs attention.
			if (grouped && (lastTok == PLUS || lastTok == MINUS)) {
				p.unscan();
				roll.modifier -= mod;
				return AMBIGUOUS_MODIFIER?;
			}
			return UNEXPECTED_TOKEN?;
		default: return UNEXPECTED_TOKEN?;
			// return nil, ErrUnexpectedToken(lit)
		}

		// If there is an error, lets bail out
		// if (err != nil) {
		// 	return err?;
		// }

		lastTok = tlit.first;
	}

}

fn RerollOp? Parser.parseReroll(&p, String lit) { //(rr RerollOp, err error)
	RerollOp rr;
	if (lit == "ro") {
		rr.once = true;
	}

	// determine the comparison operator for the reroll op
	ComparisonOp*? compOp = p.parseComparison();
	if (catch err = compOp) {
		return err?;
	}

	rr.comparison_op = compOp;
	return rr;
}

fn int? Parser.parseModifier(&p, Token tok) { //(int, error)
	int mult = 1;
	if (tok == MINUS) {
		mult = -1;
	}
	// Get modifer value
	TokenLiteral tlit = p.scanIgnoreWhitespace();

	if (tlit.first != NUM) {
		return UNEXPECTED_TOKEN?;
	}

	// Add to statement modifer
	int? mod = tlit.second.to_int();
	if(catch err = mod) {
		p.unscan();
		io::printfn("Err, %s", err);
		return err?;
	}
	return mult*mod;
}

fn ParsedDie? Parser.parseDie(&p, String dieCode) { //(Die, error) 
	String trimmedDieCode = dieCode;
	trimmedDieCode.convert_to_upper();
	trimmedDieCode = trimmedDieCode.strip("D");

	int? value = trimmedDieCode.to_int();
	if (try value ){
		io::printfn("Normaldie from: %s", dieCode);
		return { NormalDie.typeid, value};
	}

	// Is it a Fate/Fudge die roll?
	if( trimmedDieCode == "F") {
		io::printfn("Fatedie from: %s", dieCode);
		return {FateDie.typeid, 0};
	}
	io::printfn("Invalid Die Code: \"%s\" from \"%s\"", trimmedDieCode, dieCode);
	return UNKNOWN_DIE?;
}

fn ExplodingOp*? Parser.parseExplosion(&p, TokenLiteral tlit) { //(*ExplodingOp, error) 
	ExplodingOp* exp = p.pclone((ExplodingOp){});

	switch (tlit.first) {
		case EXPLODE:
			exp.type = EXPLODING;
		case COMPOUND:
			exp.type = COMPOUNDED;
		case PENETRATE:
			exp.type = PENETRATING;
		default:
			return UNEXPECTED_TOKEN?;
	}

	// determine the comparison operator for the explosion op
	ComparisonOp*? comp = p.parseComparison();
	if (catch err = comp) {
		return err?;
	}
	exp.comparison_op = comp;
	return exp;
}

fn ComparisonOp*? Parser.parseComparison(&p)  { // (cmp *ComparisonOp, err error)
	TokenLiteral tlit = p.scan();
	ComparisonOp* cmp = p.pclone((ComparisonOp){.value = 0});

	switch (tlit.first) {
		case NUM:
			int? value = tlit.second.to_int();

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
			return UNEXPECTED_TOKEN?;
	}

	tlit = p.scan();
	if (tlit.first != NUM) {
		return UNEXPECTED_TOKEN?;
	}

	// cmp.Value, err = strconv.Atoi(lit)
    int? value = tlit.second.to_int();
	if (catch e = value) {
		return e?;
	}
    cmp.value = value;
   
	return cmp;
}

fn LimitOp*? Parser.parseLimit(&p, TokenLiteral tlit) { //(lmt *LimitOp, err error)
	LimitOp* lmt = p.pclone((LimitOp){
		.amount= 1,
	});
    String lit = tlit.second;
	switch (tlit.first) {
        case KEEPHIGH:
            lmt.type = KEEP_HIGHEST;
            lit = lit.strip("kh");
        case KEEPLOW:
            lmt.type = KEEP_LOWEST;
            lit = lit.strip("kl");
        case DROPHIGH:
            lmt.type = DROP_HIGHEST;
            lit = lit.strip("dh");
        case DROPLOW:
            lmt.type = DROP_LOWEST;
            lit = lit.strip("dl");
	}

	if (lit != "") {
        int? new_amount = lit.to_int();
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
	TokenLiteral tlit = p.s.scan(&p.alloc);

	// Save it to the buffer in case we unscan later.
	p.buf.tlit = tlit;

	return tlit;
}

// unscan pushes the previously read token back onto the buffer.
fn void Parser.unscan(&p) {
    p.buf.n = 1;
}

// scanIgnoreWhitespace scans the next non-whitespace token.
fn TokenLiteral Parser.scanIgnoreWhitespace(&p) {
    TokenLiteral tlit = p.scan();
	if (tlit.first == WS) {
		tlit = p.scan();
	}
	return tlit;
}

macro Parser.pclone(&p, expr) {
	return allocator::new(&p.alloc, $typeof(expr), expr);
}