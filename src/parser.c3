module rollc3;
import std::io;
import std::collections;
// Parser is our dice rolling parser
struct Parser {
	inline TokenScanner* s;
	struct buf {
    	inline Token token;
		int n  ;
		int mod;
	}
}

// new_parser returns a Parser instance
fn Parser* new_parser(InStream r) {
    Parser* p = allocator::new(allocator::temp(), Parser);
    p.s = new_scanner(r);
	return p;
}

// Parse parses a Roll statement.
fn Roll Parser.parse(Parser* p) {
	// tok token should be a NUM or a DIE
    Token tlit = p.scan_ignore_whitespace();
	RollError err;
    Roll r =  p.parse_roll(tlit, false, &err);
	if(r.err == NO_ERROR){
		return r;
	}
	return { false, {}, r.err };
}

// parse_roll gets a roll of any type
fn Roll Parser.parse_roll(Parser* p, Token tlit, bool grouped, RollError* err) {
	switch( tlit.tok ){
	    case NUM:
        case DIE:
			DiceRoll* dr = p.parse_dice_roll(grouped, err);
			if(dr){
				return {false, *dr, *err == END_OF_ROLL ? 0 : *err};
			}
			break;
	    	// return 
	    case GROUPSTART:
			GroupedRoll* gr = p.parse_grouped_roll(grouped, err);
			if(gr){
				Roll roll;
				roll.is_group = true;
				roll.gr =  *gr;
				roll.err = END_OF_ROLL ? 0 : *err;
				return roll;
			}
			break;
	    // 	return p.parse_grouped_roll(grouped);
	    default:
            return {false, {}, UNEXPECTED_TOKEN};
	}
    return {false, {}, *err};
}

def ReRerollList = List(<RerollOp>);

// parseGrouped parses a GroupedRoll statement
fn GroupedRoll* Parser.parse_grouped_roll(Parser* p, bool grouped, RollError* err) {
    GroupedRoll* roll = allocator::new(allocator::temp(), GroupedRoll);
	roll.combined = true;
    List(<Roll>) rolls; defer rolls.free();
    bool negative;
    int multiplier;

    while(*err != NO_ERROR){
        Token tlit = p.scan_ignore_whitespace();
        Roll r = p.parse_roll(tlit, true, err);

        if(multiplier != 0){
            if(r.is_group){
                if (multiplier < 0) {
		    		r.gr.negative = true;
		    	}
            }else{
		    	r.dr.multiplier = multiplier;
            }
            multiplier = 0;
        }
        roll.combined = true;

        if (negative) {
            if(r.is_group){
                r.gr.negative = true;
            }else{
				r.dr.multiplier *= -1;
            }
		}

        if (*err != NO_ERROR) {
			negative = false;
			// We got an ambiguous modifier, which means the *next* roll needs
			// to use this modifier as it's multiplier, so store it for later
            if (r.is_group ? r.gr.rolls.len == 0 : false) {
				return null;
			}
			if(*err == AMBIGUOUS_MODIFIER){
				multiplier = p.buf.mod;
				p.buf.mod = 0;
				*err = NO_ERROR;
				// Rollback
				p.unscan();
			}else{
				// Rollback
				p.unscan();
				Token tlit2 = p.scan_ignore_whitespace();
				// Handle separators of the group
				switch (tlit2.tok) {
				case PLUS:
				case MINUS:
					negative = true;
				case GROUPSEP:
					// If we have multiple rolls and are in combined mode when we
					// get a separator, then this is an invalid grouped roll
					if (roll.rolls.len > 1 && roll.combined ){
						return roll; 
					}
					// We aren't combining if grouping with the GROUPSEP delimiter
					roll.combined = false;
					// We've finished parsing a roll, so reset err for loop
					*err = NO_ERROR;
				case GROUPSTART:
					// We've finished parsing a roll, so reset err for loop and
					// unscan again to start us off on the new group
					p.unscan();
					*err = NO_ERROR;
				case GROUPEND:
					// We've exited the group, so leave loop by letting error fall
					// through
					*err = END_OF_ROLL;
					return roll;
				default:
					// Otherwise it IS an error
					return roll; 
				}
			}
		}

        // If we've ended up with a dummy roll for some reason, don't add it
        rolls.push(r);
    }

	// We now have the collection of rolls within the grouped roll, now we need
	// to apply the modifiers to it
	while(true) {
		// Read a modifier
		Token tlit = p.scan_ignore_whitespace();

		// Handle modifier or EOF
		switch (tlit.tok ){
			case PLUS: 
			case MINUS:
			int mod =  p.parse_modifier(tlit, err);
			if (*err == NO_ERROR) {
				roll.modifier += mod;
			} else {
				if (tlit.tok == MINUS) {
					mod = -1;
				}

				p.unscan();
				tlit = p.scan_ignore_whitespace();
				switch (tlit.tok) {
					case EOF:
						*err = END_OF_ROLL;
						return roll;
					case GROUPSTART:
						if (grouped) {
							// Technically this is an end of roll, but we want to
							// capture the multiplier to determine the sign of the
							// next term
							*err = AMBIGUOUS_MODIFIER;
							p.buf.mod = mod;
							return roll;
						}
						*err = UNEXPECTED_TOKEN;
						return null;
					case GROUPEND: 
					case GROUPSEP:
						if (grouped) {
							*err = END_OF_ROLL;
							return roll;
						}
						*err = UNEXPECTED_TOKEN;
						return null;
				default:
					return null;
				}
			}
		case KEEPHIGH: 
		case KEEPLOW: 
		case DROPHIGH:
		case DROPLOW:
			roll.limit = p.parse_limit(tlit, err);
		case GREATER: 
		case LESS: 
		case EQUAL:
			p.unscan();
			roll.success = p.parse_comparison(err);
		case FAILURES:
			roll.failure = p.parse_comparison(err);
		case EOF:
			*err = END_OF_ROLL;
			return roll;
		case GROUPSEP:
			if (grouped) {
				*err = END_OF_ROLL;
				return roll;
			}
			*err = UNEXPECTED_TOKEN;
			return null;
		case GROUPEND:
			p.unscan();
			*err = NO_ERROR;
			return roll;
		default:
			*err = UNEXPECTED_TOKEN;
			return null;
		}

		// If there is an error, lets bail out
		if (*err != NO_ERROR) {
			return null;
		}
	}

	// return roll;
}

// parse_dice_roll parses a DiceRoll statement
fn DiceRoll* Parser.parse_dice_roll(Parser* p, bool grouped, RollError* err)  {
	DiceRoll* roll = allocator::new(allocator::temp(), DiceRoll);
	Token tlit = {p.buf.tok, p.buf.lit};
	// If NUM, we store it as the multiplier, else we use 1
	if (tlit.tok == NUM ){
		roll.multiplier = tlit.lit.to_int()!!;
		tlit = p.scan_ignore_whitespace();
		if (tlit.tok != DIE) {
			*err = UNEXPECTED_TOKEN;
			return null;
		}
	} else {
		roll.multiplier = 1;
	}
    
    // We will have a DIE token here, so parse it
	roll.die = p.parse_die(tlit.lit, err);
	if( *err != NO_ERROR) {
	    return null;
	}

	// Next we should loop over all our modifiers and total them up
	int mod;
	Token lastTok;
	ReRerollList rerolls; defer rerolls.free();
	while(true) {
		// Read a modifier
		tlit = p.scan_ignore_whitespace();
		// Handle modifier or EOF
		switch (tlit.tok) {
		case PLUS:
		case MINUS:
			mod = p.parse_modifier(tlit, err);
			
			if (*err == NO_ERROR) {
				roll.modifier += mod;
			} else {
				if (tlit.tok == MINUS) {
					mod = -1;
				}

				p.unscan();
				tlit = p.scan_ignore_whitespace();
				switch (tlit.tok) {
				case EOF:
					*err = END_OF_ROLL;
                    return roll;
				case GROUPSTART:
					if (grouped) {
						*err = AMBIGUOUS_MODIFIER;
						// Technically this is an end of roll, but we want to
						// capture the multiplier to determine the sign of the
						// next term
						p.buf.mod = mod;
						return roll;
					}
					*err = UNEXPECTED_TOKEN;
					return null; 
				case GROUPEND:
				case GROUPSEP:
					if (grouped) {
						*err = END_OF_ROLL;
						return roll;
					}
					*err = UNEXPECTED_TOKEN;
					return null;
				default:
					return null;
				}
			}
		case EXPLODE:
		case COMPOUND:
		case PENETRATE:
            roll.exploding = p.parse_explosion(tlit, err);
			if(*err == COMPARISON_NO_INT){
				if(roll.exploding.op == null){
					ComparisonOp* new_op = mem::new(ComparisonOp);
					new_op.type = EQUALS;
					new_op.value = roll.die.max();
					roll.exploding.op = new_op;
					*err = NO_ERROR;
					p.unscan();
				}
			}else{
				allocator::free(allocator::temp(), roll.exploding);
				roll.exploding = null;
			}
            break;
		case KEEPHIGH:
		case KEEPLOW:
		case DROPHIGH:
		case DROPLOW:
			roll.limit = p.parse_limit(tlit, err);
            break;
		case SORT:
			switch (tlit.lit) {
			case "s":
				roll.sort = ASCENDING; break;
			case "sd":
				roll.sort = DESCENDING; break;
			}
            break;
		case REROLL:
            rerolls.push(p.parse_reroll(tlit.lit, err));
		case GREATER:
		case LESS:
		case EQUAL:
			p.unscan();
            roll.success = p.parse_comparison(err);
		case FAILURES:
			roll.failure = p.parse_comparison(err); 
		case EOF:
			*err = END_OF_ROLL;
			roll.rerolls = rerolls.to_new_array(allocator::temp());
			return roll; 
		case GROUPEND:
		case GROUPSEP:
			roll.rerolls = rerolls.to_new_array(allocator::temp());
			if (grouped) {
				*err = END_OF_ROLL;
				return roll;
			}
			*err = UNEXPECTED_TOKEN;
            return null;
		case DIE:
			// It's ambiguous whether or not a +/- number is a modifier or a
			// a combined die roll. If grouped and we get a die character AND
			// the last token processed was a modifier, then we rewind and then
			// raise a special error to indicate it needs attention.
			roll.rerolls = rerolls.to_new_array(allocator::temp());
			if (grouped && (lastTok.tok == PLUS || lastTok.tok == MINUS) ){
				p.unscan();
				roll.modifier -= mod;
				*err = AMBIGUOUS_MODIFIER;
				p.buf.mod = mod;
				return roll;
			}
			*err = UNEXPECTED_TOKEN;
			return null; 
		default:
			*err = UNEXPECTED_TOKEN;
			return null;
		}
		
		// If there is an error, lets bail out
		if (*err != NO_ERROR) {
			return null;
		}

		lastTok = tlit;
	}
	// return {(Roll*) roll, err};
}

// scan returns the next token from the underlying TokenScanner.
// If a token has been unscanned then read that instead.
fn Token Parser.scan(Parser* p) {
    // If we have a token on the buffer, then return it.
	if( p.buf.n = 0) {
		p.buf.n = 0;
		return {p.buf.tok, p.buf.lit};
	}
    // Otherwise read the next token from the TokenScanner.
    Token tlit =  p.s.scan();
    // Save it to the buffer in case we unscan later.
    p.buf.tok = tlit.tok;
    p.buf.lit = tlit.lit;
    return tlit;
}

// func (p *Parser) parse_reroll(lit string) (rr RerollOp, err error) 
fn RerollOp Parser.parse_reroll(Parser* p, String lit, RollError* err)
{
	RerollOp rr;
	if (lit == "ro") {
		rr.once = true;
	}

	// determine the comparison operator for the reroll op
	ComparisonOp* op = p.parse_comparison(err);
	if( *err == NO_ERROR ){
	    rr.op = op;
	    return rr;
	}
	*err = UNKNOWN_DIE;
	return rr;
}

fn int Parser.parse_modifier(Parser* p, Token tok, RollError* err)
{
	int mult = 1;
	if (tok.tok == MINUS) {
		mult = -1;
	}
	// Get modifer value
	Token tlit = p.scan_ignore_whitespace();
	if (tlit.tok != NUM) {
		*err = UNEXPECTED_TOKEN;
	}

	// Add to statement modifer
	int! mod = tlit.lit.to_int();
	if(try mod){
		return mod*mult;
	}
	*err = INT_PARSE_FAILURE;
	return 0;
}

fn Die Parser.parse_die(Parser* p, String dieCode, RollError* err)
{
	String trimmedDieCode = dieCode.new_ascii_to_upper().strip("D");
	int! num = trimmedDieCode.to_int();
	Die ret;
	if  (try num) {
		ret.normal = true;
		ret.nd = (NormalDie)num;
		return ret;
	}

	// Is it a Fate/Fudge die roll?
	if (trimmedDieCode == "F") {
        ret.fd = 0;
	    return ret;
	}
	*err = UNKNOWN_DIE;
    return {};
}

fn ExplodingOp* Parser.parse_explosion(Parser* p, Token token, RollError* err) {
    ExplodingOp* exp = allocator::new(allocator::temp(), ExplodingOp);
	switch (token.tok) {
	    case EXPLODE: exp.type = EXPLODING; break;
	    case COMPOUND: exp.type = COMPOUNDED; break;
	    case PENETRATE: exp.type = PENETRATING; break;
	    default:
            allocator::free(allocator::temp(), exp);
			*err = UNEXPECTED_TOKEN;
            return null;
	}
	
	// determine the comparison operator for the explosion op
    ComparisonOp* op = p.parse_comparison(err);
	if (*err != NO_ERROR) {
		allocator::free(allocator::temp(), op);
		return exp;
	}
	
	exp.op = op;

	return exp;
}

fn ComparisonOp* Parser.parse_comparison(Parser* p, RollError* err) {
    ComparisonOp* cmp = mem::new(ComparisonOp);
    Token tlit = p.scan();
	switch (tlit.tok) {
	    case NUM:
            int! v = tlit.lit.to_int();
		    if (try v) {
		    	cmp.value = v;
		    }
		    cmp.type = EQUALS;
		    return cmp;
	    case EQUAL: cmp.type = EQUALS; break;
	    case GREATER: cmp.type = GREATERTHAN; break;
	    case LESS: cmp.type = LESSTHAN; break;
	    default: *err = COMPARISON_NO_INT;  return cmp;
	}
	tlit = p.scan();
	if (tlit.tok != NUM) {
		*err = UNEXPECTED_TOKEN; return null;
	}

    int! tv = tlit.lit.to_int();
	if (try tv) {
        cmp.value = tv;
        return cmp;
	}
	// *err = UNEXPECTED_TOKEN;
	return cmp;
}

fn LimitOp* Parser.parse_limit(Parser* p, Token tok, RollError* err){
    LimitOp* lmt = mem::new(LimitOp);
    lmt.amount = 1;
	String lit = tok.lit.copy(allocator::temp());
	switch (tok.tok ){
	case KEEPHIGH:
		lmt.type = KEEPHIGHEST;
		lit = lit.strip("kh");
	case KEEPLOW:
		lmt.type = KEEPLOWEST;
		lit = lit.strip("kl");
	case DROPHIGH:
		lmt.type = DROPHIGHEST;
		lit = lit.strip("dh");
	case DROPLOW:
		lmt.type = DROPLOWEST;
		lit = lit.strip("dl");
	}

	if (lit != "") {
		int! i = lit.to_int();
		if(try i){
			lmt.amount = i;
		}else{
			*err = UNEXPECTED_TOKEN;
			return null;
		}
	}

	return lmt;
}

// unscan pushes the previously read token back onto the buffer.
fn void Parser.unscan(Parser* p) { p.buf.n = 1; }

// scan_ignore_whitespace scans the next non-whitespace token.
fn Token Parser.scan_ignore_whitespace(Parser* p){
    Token tlit = p.scan();
    if (tlit.tok == WS) {
		tlit = p.scan();
	}
    return tlit;
}