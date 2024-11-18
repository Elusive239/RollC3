module rollc3;
import std::io;
import std::collections::tuple;
import std::collections::list;

fault RollError{
    UNEXPECTED_TOKEN,
    UNKNOWN_DIE,
    END_OF_ROLL,
    AMBIGUOUS_MODIFIER
}

// Parser is our dice rolling parser
struct Parser {
	inline Scanner* s;
	struct buf {
    	Token tok;
		String lit;
		int n  ;
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
	// First token should be a NUM or a DIE
	// io::printfn("Hi!");
    TokenAndLit tlit = p.scan_ignore_whitespace();
	Roll re = p.parse_roll(tlit.first, tlit.second, false);
	return re;
}

// parse_roll gets a roll of any type
fn Roll Parser.parse_roll(Parser* p, Token tok, String lit, bool grouped) {
    Roll r;
	switch( tok ){
	    case NUM:
        case DIE:
	    	r = (Roll)  p.parse_dice_roll(grouped)!!; break;
	    case GROUPSTART:
	    	r =  (Roll) p.parse_grouped_roll(grouped); break;
	    default:
            return null;
	}
    return r;
}

// parseGrouped parses a GroupedRoll statement
fn GroupedRoll* Parser.parse_grouped_roll(Parser* p, bool grouped) {
    GroupedRoll* roll;// = allocator::new(allocator::temp(), GroupedRoll);
    List(<Roll>) rolls; defer rolls.free();
    bool negative;
    int multiplier;
    Roll re;
    while(true){
        TokenAndLit tlit = p.scan_ignore_whitespace();
        Roll! r = p.parse_roll(tlit.first, tlit.second, true);
        if( try r){
            if(multiplier != 0){
                if(r.is_group()){
                    GroupedRoll* gr = (GroupedRoll*) r;
                    if (multiplier < 0 && gr != null) {
			    		gr.negative = true;
			    	}
                    re = r;
                }else{
                    DiceRoll* dr = (DiceRoll*) r;
                    if (dr != null) {
			    		dr.multiplier = multiplier;
			    	}
			    	re = r;
                }
                multiplier = 0;
            }
        }
        roll.combined = true;

        if (negative) {
            if(re.is_group()){
                GroupedRoll* gr = (GroupedRoll*) re;
                gr.negative = true;
                re = (Roll) gr;
            }else{
                DiceRoll* dr = (DiceRoll*) re;
                dr.multiplier *= -1;
				re = (Roll) dr;
            }
		}

        if (catch r) {
			negative = false;
			// We got an ambiguous modifier, which means the *next* roll needs
			// to use this modifier as it's multiplier, so store it for later
            if (try r) {
				// Rollback
				p.unscan();
                TokenAndLit tlit2 = p.scan_ignore_whitespace();

				// Handle separators of the group
				switch (tlit2.first) {
				case PLUS:
				case MINUS:
					negative = true;
				case GROUPSEP:
					// If we have multiple rolls and are in combined mode when we
					// get a separator, then this is an invalid grouped roll
					if (roll.rolls.len > 1 && roll.combined ){
						return roll; //new_roll(roll, re.second);
						// return {(Roll*) roll, re.second};
					}

					// We aren't combining if grouping with the GROUPSEP delimiter
					roll.combined = false;
					// We've finished parsing a roll, so reset err for loop
				case GROUPSTART:
					// We've finished parsing a roll, so reset err for loop and
					// unscan again to start us off on the new group
					p.unscan();
				case GROUPEND:
					// We've exited the group, so leave loop by letting error fall
					// through
                    return roll;
					// re.second = new_error_s(END_OF_ROLL, tlit2.second);
				default:
					// Otherwise it IS an error
					return roll; //new_roll(roll,re.second);
					// return {(Roll*) roll, };
				}
			}
			else if (roll.rolls.len == 0) {
				return roll; //new_roll(roll, re.second);
				// return {(Roll*) roll, re.second};
			}else{
				multiplier = 1;
				p.unscan();
                // If we got an error and we have no rolls, it's definitely broken
			}
		}

        // If we've ended up with a dummy roll for some reason, don't add it
		if (re != null) {
            rolls.push(re);
		}
    }
    // roll.rolls = rolls.to_new_array(allocator::temp());
    // return roll; ////new_roll(roll);
}

// parse_dice_roll parses a DiceRoll statement
fn DiceRoll*! Parser.parse_dice_roll(Parser* p, bool grouped)  {
	DiceRoll* roll = mem::new(DiceRoll);
	TokenAndLit tlit = {p.buf.tok, p.buf.lit};


	// If NUM, we store it as the multiplier, else we use 1
	if (tlit.first == NUM ){
		roll.multiplier = tlit.second.to_int()!!;
		tlit = p.scan_ignore_whitespace();
		if (tlit.first != DIE) {
            return RollError.UNEXPECTED_TOKEN?;
			// return {null, new_error_s(UNEXPECTED_TOKEN,tlit.second)};
		}
	} else {
		roll.multiplier = 1;
	}
    
    // We will have a DIE token here, so parse it
	Die! die = p.parse_die(tlit.second);
	if( try die) {
	    roll.die = die;
	}else {
        return RollError.UNKNOWN_DIE?;}

	// Next we should loop over all our modifiers and total them up
	int mod;
	Token lastTok;
	List(<RerollOp>) rerolls; defer rerolls.free();
	while(true) {
		// Read a modifier
		tlit = p.scan_ignore_whitespace();

		// Handle modifier or EOF
		switch (tlit.first) {
		case PLUS:
		case MINUS:
			int! merr = p.parse_modifier(tlit.first);
			
			if (try merr) {
                mod = merr;
				roll.modifier += mod;
			} else {
				if (tlit.first == MINUS) {
					mod = -1;
				}

				p.unscan();
				tlit = p.scan_ignore_whitespace();
				switch (tlit.first) {
				case EOF:
                    return roll;
					// err = new_error_s(END_OF_ROLL, tlit.second);
					// return roll; //new_roll(roll, err);
				case GROUPSTART:
					if (grouped) {
						// Technically this is an end of roll, but we want to
						// capture the multiplier to determine the sign of the
						// next term
						// err = new_error_i(AMBIGUOUS_MODIFIER, mod);
						return roll; //new_roll(roll, err);
						// {(Roll*)roll, err};
					}
					return RollError.UNEXPECTED_TOKEN?; //new_roll(roll, new_error_s(UNEXPECTED_TOKEN, tlit.second));
				case GROUPEND:
				case GROUPSEP:
					if (grouped) {
						// err = new_error_s(END_OF_ROLL, tlit.second);
						return roll; //new_roll(roll, err);
					}
					return RollError.UNEXPECTED_TOKEN?; //new_roll(roll, new_error_s(UNEXPECTED_TOKEN, tlit.second));
				default:
					return roll; //new_roll(roll,err);
				}
			}
		case EXPLODE:
		case COMPOUND:
		case PENETRATE:
			ExplodingOp*! ee = p.parse_explosion(tlit.first, tlit.second);
            if(try ee){
			    roll.exploding = ee;
            }
            break;
		case KEEPHIGH:
		case KEEPLOW:
		case DROPHIGH:
		case DROPLOW:
			roll.limit = p.parse_limit(tlit.first, tlit.second);
            break;
		case SORT:
			switch (tlit.second) {
			case "s":
				roll.sort = ASCENDING; break;
			case "sd":
				roll.sort = DESCENDING; break;
			}
            break;
		case REROLL:
			RerollOp! rr = p.parse_reroll(tlit.second);
            if(try rr){
			    rerolls.push(rr);
            }
			// roll.rerolls = append(roll.rerolls, rr);
		case GREATER:
		case LESS:
		case EQUAL:
			p.unscan();
			ComparisonOp*! comp = p.parse_comparison(); 
            if(try comp) {
                roll.success = comp;
            }
		case FAILURES:
			ComparisonOp*! comp = p.parse_comparison(); 
            if(try comp) {
                roll.failure = comp;
            }
		case EOF:
			// err = new_error_s(END_OF_ROLL, tlit.second);
			roll.rerolls = rerolls.to_new_array();
			return roll; //new_roll(roll, err);
			// return {(Roll*)roll, err};
		case GROUPEND:
		case GROUPSEP:
			roll.rerolls = rerolls.to_new_array();
			if (grouped) {
				// err = new_error_s(END_OF_ROLL, tlit.second);
				return roll; //new_roll(roll, err);
			}
            return RollError.UNEXPECTED_TOKEN?;
			// err = new_error_s(UNEXPECTED_TOKEN, tlit.second);
			// return roll; //new_roll(roll, err);
		case DIE:
			// It's ambiguous whether or not a +/- number is a modifier or a
			// a combined die roll. If grouped and we get a die character AND
			// the last token processed was a modifier, then we rewind and then
			// raise a special error to indicate it needs attention.
			roll.rerolls = rerolls.to_new_array();
			if (grouped && (lastTok == PLUS || lastTok == MINUS) ){
				p.unscan();
				roll.modifier -= mod;
				// err = new_error_i(AMBIGUOUS_MODIFIER, mod);
				return roll; //new_roll(roll, err);
			}
			return roll; //new_roll(roll, new_error_s(END_OF_ROLL, tlit.second));
			// return {(Roll*)roll, new_error_s(END_OF_ROLL, tlit.second)};
		default:
			roll.rerolls = rerolls.to_new_array();
			return roll; //new_roll(roll, new_error_s(END_OF_ROLL, tlit.second));
		}
		
		// If there is an error, lets bail out
		if (roll != null) {
            
			return roll; //new_roll(roll, err);
		}

		lastTok = tlit.first;
	}
	// return {(Roll*) roll, err};
}

// func (p *Parser) parse_reroll(lit string) (rr RerollOp, err error) 
fn RerollOp! Parser.parse_reroll(Parser* p, String lit)
{
	RerollOp rr;
	if (lit == "ro") {
		rr.once = true;
	}

	// determine the comparison operator for the reroll op
	ComparisonOp*! op = p.parse_comparison();
	if( try op ){
	    rr.op = op;
	    return rr;
	}
	return RollError.UNKNOWN_DIE?;
}

// func (p *Parser) parse_modifier(tok Token) (int, error) 
fn int! Parser.parse_modifier(Parser* p, Token tok)
{
	int mult = 1;
	if (tok == MINUS) {
		mult = -1;
	}
	// Get modifer value
	TokenAndLit tlit = p.scan_ignore_whitespace();
	if (tlit.first != NUM) {
        return RollError.UNEXPECTED_TOKEN?;
		// return {0, new_error_s(UNEXPECTED_TOKEN, tlit.second)};
		// return 0, ErrUnexpectedToken(lit)
	}

	// Add to statement modifer
	int! mod = tlit.second.to_int();
	// mod, err := strconv.Atoi(lit)
    if(try mod) return mod*mult;
    return mod;
	// return {mod * mult, new_error_i()};
}

// func (p *Parser) parse_die(dieCode string) (Die, error) 
fn Die! Parser.parse_die(Parser* p, String dieCode)
{
	String trimmedDieCode = dieCode.new_ascii_to_upper().strip("D");
	int! num = trimmedDieCode.to_int();
	if  (try num) {
		Die nd = (Die) mem::new(NormalDie, (NormalDie)num);
		return nd;// (Die) nd;
	}

	// Is it a Fate/Fudge die roll?
	if (trimmedDieCode == "F") {
        Die fd = (Die) mem::new(FateDie, (FateDie)0);
	    return fd;

		// FateDie fd;
		// // return (Die) fd;
		// return (Die) mem::new(NormalDie, fd);
	}
    return RollError.UNKNOWN_DIE?;
	// NormalDie nds = 0;
	// return (Die) nds;
	// return (Die) mem::new(NormalDie, nds);
	// return null, ErrUnknownDie(dieCode)
}



fn ExplodingOp*! Parser.parse_explosion(Parser* p, Token tok, String lit) {
    ExplodingOp* exp = mem::new(ExplodingOp);

	switch (tok) {
	    case EXPLODE: exp.type = EXPLODING; break;
	    case COMPOUND: exp.type = COMPOUNDED; break;
	    case PENETRATE: exp.type = PENETRATING; break;
	    default:
            mem::free(exp);
            return RollError.UNEXPECTED_TOKEN?;
	    	// return {null, new_error_s(UNEXPECTED_TOKEN, lit) };
	}

	// determine the comparison operator for the explosion op
    ComparisonOp*! op = p.parse_comparison();
	if (catch op) {
        mem::free(exp);
		return null;
	}
	exp.op = op;

	return exp;
}

fn ComparisonOp*! Parser.parse_comparison(Parser* p) {
    ComparisonOp* cmp = mem::new(ComparisonOp);
    TokenAndLit tlit = p.scan();

	switch (tlit.first) {
	    case NUM:
		    // cmp.Value, err = strconv.Atoi(lit)
            int! v = tlit.second.to_int();
		    if (try v) {
		    	cmp.value = v;
		        cmp.type = EQUALS;
		        return cmp;
		    }
            return RollError.UNEXPECTED_TOKEN?;
	    case EQUAL: cmp.type = EQUALS; break;
	    case GREATER: cmp.type = GREATERTHAN; break;
	    case LESS: cmp.type = LESSTHAN; break;
	    default: return RollError.UNEXPECTED_TOKEN?;
        // cmp.second = new_error_s(UNEXPECTED_TOKEN, tlit.second); return cmp;
	}

	tlit = p.scan();
	if (tlit.first != NUM) {
		// cmp.second = new_error_s(UNEXPECTED_TOKEN, tlit.second);
		// return cmp;
        return RollError.UNEXPECTED_TOKEN?;
	}

    int! tv = tlit.second.to_int();
    // , err = strconv.Atoi(lit)
	if (try tv) {
        cmp.value = tv;
        return cmp;
	}

	return RollError.UNEXPECTED_TOKEN?;
}


fn LimitOp* Parser.parse_limit(Parser* p, Token tok, String lit){
    LimitOp* lmt = mem::new(LimitOp);
    lmt.amount = 1;

	switch (tok ){
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
		lmt.amount = lit.to_int()!!;
        // , err = strconv.Atoi(lit)
	}

	return lmt;
}

// scan returns the next token from the underlying scanner.
// If a token has been unscanned then read that instead.
fn TokenAndLit Parser.scan(Parser* p) {
    // If we have a token on the buffer, then return it.
	if( p.buf.n != 0) {
		p.buf.n = 0;
		return {p.buf.tok, p.buf.lit};
	}
	io::printfn("Hi!");
    // Otherwise read the next token from the scanner.
    TokenAndLit tlit =  p.s.scan();
	io::printfn("Hi!");
    // Save it to the buffer in case we unscan later.
    p.buf.tok = tlit.first;
    p.buf.lit = tlit.second;
	io::printfn("Hi!");
    return tlit;
}

// unscan pushes the previously read token back onto the buffer.
fn void Parser.unscan(Parser* p) { p.buf.n = 1; }

// scan_ignore_whitespace scans the next non-whitespace token.
fn TokenAndLit Parser.scan_ignore_whitespace(Parser* p){
	
    TokenAndLit tlit = p.scan();
    if (tlit.first == WS) {
		tlit = p.scan();
	}
    return tlit;
}