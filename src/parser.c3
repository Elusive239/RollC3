// module rollc3;
// import std::io;
// import std::collections::tuple;
// import std::collections::list;

// interface RollError{
//     fn String error();
//     fn int error_code();
//     fn int to_int() @optional;
// }

// distinct NoErr = uint;
// fn String NoErr.error(NoErr e)  => "";
// fn int NoErr.error_code(NoErr e)  => -1;
// const NoErr NOERROR = 1;

// // ErrUnexpectedToken is raised on unexpected tokens
// distinct ErrUnexpectedToken = String;
// fn String ErrUnexpectedToken.error(ErrUnexpectedToken e)  => string::tformat("found unexpected token %q", e);
// fn int ErrUnexpectedToken.error_code(ErrUnexpectedToken e)  => 0;

// // ErrUnknownDie is raised on unrecognised die types
// distinct ErrUnknownDie = String;
// fn String ErrUnknownDie.error(ErrUnknownDie e) => string::tformat("unrecognised die type %q", e);
// fn int ErrUnknownDie.error_code(ErrUnknownDie e)  => 1;

// // ErrEndOfRoll is raised when parsing a roll has reached a terminating token
// distinct ErrEndOfRoll = String;
// fn String ErrEndOfRoll.error(ErrEndOfRoll e) => string::tformat("roll parsing terminated on %q", e);
// fn int ErrEndOfRoll.error_code(ErrEndOfRoll e)  => 2;

// // ErrAmbiguousModifier is raised when a multiplier was misread as a modifier
// distinct ErrAmbiguousModifier = int;
// fn String ErrAmbiguousModifier.error(ErrAmbiguousModifier e) => string::tformat("misread %+d as modifier", e);
// fn int ErrAmbiguousModifier.error_code(ErrAmbiguousModifier e)  => 3;
// fn int ErrAmbiguousModifier.to_int(ErrAmbiguousModifier e) => (int)e;
// // def RollAndError = Tuple(<Roll*, RollError>);

// struct RollAndError{
//     Roll* first;
//     RollError second;
// }

// // Parser is our dice rolling parser
// struct Buf {
//     Token tok;
// 	String lit;
// 	int n  ;
// }

// struct Parser {
// 	inline Scanner* s;
// 	Buf buf;
// }

// // new_parser returns a Parser instance
// fn Parser* new_parser(InStream* r) {
//     Parser* p = allocator::new(allocator::temp(), Parser);
//     p.s = new_scanner(r);
// 	return p;
// }

// // Parse parses a Roll statement.
// fn RollAndError Parser.parse(Parser* p) {
// 	// First token should be a NUM or a DIE
//     TokenAndLit tlit = p.scan_ignore_whitespace();
// 	RollAndError re = p.parse_roll(tlit.first, tlit.second, false);
// 	return re;
// }

// // parse_roll gets a roll of any type
// fn RollAndError Parser.parse_roll(Parser* p, Token tok, String lit, bool grouped) {
// 	switch( tok ){
// 	    case NUM:
//         case DIE:
// 	    	return p.parse_dice_roll(grouped);
// 	    case GROUPSTART:
// 	    	return p.parse_grouped_roll(grouped);
// 	    default:
//             ErrUnexpectedToken un = lit;
//             return {0, un};
// 		// return null, ErrUnexpectedToken(lit)
// 	}
// }

// // parseGrouped parses a GroupedRoll statement
// fn RollAndError Parser.parseGroupedRoll(Parser* p, bool grouped) {
//     GroupedRoll* roll = allocator::new(allocator::temp(), GroupedRoll);
//     List(<Roll>) rolls; defer rolls.free();
//     roll.combined = true;
//     bool negative;
//     int multiplier;
//     RollAndError re;
//     while(re.second.error() == ""){
//         TokenAndLit tlit = p.scan_ignore_whitespace();
//         re = p.parse_roll(tlit.first, tlit.second, true);
//         if(re.first != null && multiplier != 0){
//             if(re.first.is_group()){
//                 GroupedRoll* gr = (GroupedRoll*) re.first;
//                 if (multiplier < 0 && gr != null) {
// 					gr.negative = true;
// 				}
//                 re.first = (Roll*) gr;
//             }else{
//                 DiceRoll* dr = (DiceRoll*) re.first;
//                 if (dr != null) {
// 					dr.multiplier = multiplier;
// 				}
// 				re.first = (Roll*) dr;
//             }
//             multiplier = 0;
//         }

//         if (negative) {
//             if(re.first.is_group()){
//                 GroupedRoll* gr = (GroupedRoll*) re.first;
//                 gr.negative = true;
//                 re.first = (Roll*) gr;
//             }else{
//                 DiceRoll* dr = (DiceRoll*) re.first;
//                 dr.multiplier *= -1;
// 				re.first = (Roll*) dr;
//             }
// 		}

//         if (re.second.error() != "") {
// 			negative = false;
// 			// If we got an error and we have no rolls, it's definitely broken
// 			if (re.first == null && roll.rolls.len == 0) {
// 				return {(Roll*) roll, re.second};
// 			}

// 			// We got an ambiguous modifier, which means the *next* roll needs
// 			// to use this modifier as it's multiplier, so store it for later
// 			if (re.second.error_code() == 3) {
// 				multiplier = re.second.to_int();
// 				p.unscan();
// 				re.second = NOERROR;
// 			} else {
// 				// Rollback
// 				p.unscan();
//                 TokenAndLit tlit2 = p.scan_ignore_whitespace();

// 				// Handle separators of the group
// 				switch (tlit2.first) {
// 				case PLUS:
// 				case MINUS:
// 					negative = true;
// 				case GROUPSEP:
// 					// If we have multiple rolls and are in combined mode when we
// 					// get a separator, then this is an invalid grouped roll
// 					if (roll.rolls.len > 1 && roll.combined ){
// 						return {roll, re.second};
// 					}

// 					// We aren't combining if grouping with the GROUPSEP delimiter
// 					roll.combined = false;
// 					// We've finished parsing a roll, so reset err for loop
// 					re.second = NOERROR;
// 				case GROUPSTART:
// 					// We've finished parsing a roll, so reset err for loop and
// 					// unscan again to start us off on the new group
// 					p.unscan();
// 					re.second = NOERROR;
// 				case GROUPEND:
// 					// We've exited the group, so leave loop by letting error fall
// 					// through
// 					re.second = (ErrEndOfRoll) lit;
// 				default:
// 					// Otherwise it IS an error
// 					return {(Roll*) roll, re.second};
// 				}
// 			}
// 		}

//         // If we've ended up with a dummy roll for some reason, don't add it
// 		if (re.first != null) {
//             rolls.push(*re.first);
// 			// roll.Rolls = append(roll.Rolls, r)
// 		}
//     }
//     roll.rolls = rolls.to_new_array(allocator::temp());
//     return {roll, NOERROR};
// }

// // parseDiceRoll parses a DiceRoll statement
// fn RollAndError parseDiceRoll(Parser* p, bool grouped) {
//     DiceRoll* roll = allocator::new(allocator::temp(), DiceRoll);
//     TokenAndLit tlit = {p.buf.tok, p.buf.lit};

// 	// If NUM, we store it as the multiplier, else we use 1
// 	if tlit.first == NUM {
// 		roll.multiplier = lit.to_double()!!;
// 		tlit = p.scan_ignore_white_space();
// 		if (tlit.first != DIE) {
// 			return {null, (ErrUnexpectedToken)tlit.second};
// 		}
// 	} else {
// 		roll.multiplier = 1;
// 	}   
//     RollAndError re =  p.parseDie(tlit.second)
// 	// We will have a DIE token here, so parse it
// 	if (re.second != "") {
// 		return {null, re.second};
// 	}

// 	// Next we should loop over all our modifiers and total them up
// 	int mod;
// 	Token lastTok;
// 	while(true) {
// 		// Read a modifier
// 		tlit = p.scan_ignore_white_space();

// 		// Handle modifier or EOF
// 		switch (tlit.first) {
// 		case PLUS, MINUS:
// 			mod, err = p.parse_modifier(tlit.first);
// 			if err == null {
// 				roll.modifier += mod
// 			} else {
// 				if (tlit.first == tMINUS) {
// 					mod = -1;
// 				}

// 				p.unscan();
// 				tlit = p.scan_ignore_white_space();
// 				switch (tlit.first) {
// 				case EOF:
// 					return {(Roll*)roll, (ErrEndOfRoll)tlit.second};
// 				case GROUPSTART:
// 					if (grouped) {
// 						// Technically this is an end of roll, but we want to
// 						// capture the multiplier to determine the sign of the
// 						// next term
// 						return  {(Roll*)roll, (ErrAmbiguousModifier)mod};
// 					}
// 					return {null, ErrUnexpectedToken(tlit.second)}
// 				case GROUPEND, GROUPSEP:
// 					if grouped {
// 						return  {(Roll*)roll, (ErrEndOfRoll)tlit.second};
// 					}
// 					return {null, (ErrUnexpectedToken)tlit.second};
// 				default:
// 					return {null, err}
// 				}
// 			}
// 		case EXPLODE, COMPOUND, PENETRATE:
// 			roll.exploding, err = p.parse_explosion(tlit.first, tlit.second)
// 		case KEEPHIGH, KEEPLOW, DROPHIGH, DROPLOW:
// 			roll.limit, err = p.parse_limit(tlit.first, tlit.second)
// 		case SORT:
// 			switch (tlit.second) {
// 			    case "s": roll.sort = ASCENDING;
// 			    case "sd": roll.sort = DESCENDING;
// 	        }
// 		case tREROLL:
// 			var rr RerollOp
// 			rr, err = p.parseReroll(tlit.second);
// 			roll.rerolls = append(roll.rerolls, rr);
// 		case GREATER, LESS, EQUAL:
// 			p.unscan();
// 			roll.success, err = p.parse_comparison();
// 		case FAILURES:
// 			roll.failure, err = p.parse_comparison();
// 		case EOF:
// 			err = (ErrEndOfRoll)tlit.second;
// 			return
// 		case GROUPEND, GROUPSEP:
// 			if grouped {
// 				err = ErrEndOfRoll(tlit.second)
// 				return
// 			}
// 			return null, ErrUnexpectedToken(tlit.second)
// 		case DIE:
// 			// It's ambiguous whether or not a +/- number is a modifier or a
// 			// a combined die roll. If grouped and we get a die character AND
// 			// the last token processed was a modifier, then we rewind and then
// 			// raise a special error to indicate it needs attention.
// 			if grouped && (lastTok == PLUS || lastTok == tMINUS) {
// 				p.unscan()
// 				roll.modifier -= mod
// 				err = ErrAmbiguousModifier(mod)
// 				return
// 			}
// 			return null, ErrUnexpectedToken(tlit.second)
// 		default:
// 			return null, ErrUnexpectedToken(tlit.second)
// 		}

// 		// If there is an error, lets bail out
// 		if err != null {
// 			return null, err
// 		}

// 		lastTok = tok
// 	}
// }
// /*
// // parse_dice_roll parses a DiceRoll statement
// func (p *Parser) parse_dice_roll(grouped bool) (roll *DiceRoll, err error) {
// 	roll = &DiceRoll{}
// 	tok := p.buf.tok
// 	lit := p.buf.lit

// 	// If NUM, we store it as the multiplier, else we use 1
// 	if tok == NUM {
// 		roll.multiplier, _ = strconv.Atoi(lit)
// 		tok, lit = p.scan_ignore_whitespace()
// 		if tok != tDIE {
// 			return null, ErrUnexpectedToken(lit)
// 		}
// 	} else {
// 		roll.multiplier = 1
// 	}

// 	// We will have a DIE token here, so parse it
// 	if roll.Die, err = p.parseDie(lit); err != null {
// 		return null, err
// 	}

// 	// Next we should loop over all our modifiers and total them up
// 	var mod int
// 	var lastTok Token
// 	for {
// 		// Read a modifier
// 		tok, lit := p.scan_ignore_whitespace()

// 		// Handle modifier or EOF
// 		switch tok {
// 		case PLUS, tMINUS:
// 			mod, err = p.parse_modifier(tok)
// 			if err == null {
// 				roll.modifier += mod
// 			} else {
// 				if tok == tMINUS {
// 					mod = -1
// 				}

// 				p.unscan()
// 				tok, lit = p.scan_ignore_whitespace()
// 				switch tok {
// 				case EOF:
// 					err = ErrEndOfRoll(lit)
// 					return
// 				case tGROUPSTART:
// 					if grouped {
// 						// Technically this is an end of roll, but we want to
// 						// capture the multiplier to determine the sign of the
// 						// next term
// 						err = ErrAmbiguousModifier(mod)
// 						return
// 					}
// 					return null, ErrUnexpectedToken(lit)
// 				case GROUPEND, GROUPSEP:
// 					if grouped {
// 						err = ErrEndOfRoll(lit)
// 						return
// 					}
// 					return null, ErrUnexpectedToken(lit)
// 				default:
// 					return null, err
// 				}
// 			}
// 		case EXPLODE, COMPOUND, PENETRATE:
// 			roll.exploding, err = p.parse_explosion(tok, lit)
// 		case KEEPHIGH, KEEPLOW, DROPHIGH, DROPLOW:
// 			roll.limit, err = p.parse_limit(tok, lit)
// 		case SORT:
// 			switch lit {
// 			case "s":
// 				roll.sort = ASCENDING
// 			case "sd":
// 				roll.sort = DESCENDING
// 			}
// 		case tREROLL:
// 			var rr RerollOp
// 			rr, err = p.parseReroll(lit)
// 			roll.rerolls = append(roll.rerolls, rr)
// 		case GREATER, LESS, EQUAL:
// 			p.unscan()
// 			roll.success, err = p.parse_comparison()
// 		case tFAILURES:
// 			roll.failure, err = p.parse_comparison()
// 		case EOF:
// 			err = ErrEndOfRoll(lit)
// 			return
// 		case GROUPEND, GROUPSEP:
// 			if grouped {
// 				err = ErrEndOfRoll(lit)
// 				return
// 			}
// 			return null, ErrUnexpectedToken(lit)
// 		case tDIE:
// 			// It's ambiguous whether or not a +/- number is a modifier or a
// 			// a combined die roll. If grouped and we get a die character AND
// 			// the last token processed was a modifier, then we rewind and then
// 			// raise a special error to indicate it needs attention.
// 			if grouped && (lastTok == PLUS || lastTok == tMINUS) {
// 				p.unscan()
// 				roll.modifier -= mod
// 				err = ErrAmbiguousModifier(mod)
// 				return
// 			}
// 			return null, ErrUnexpectedToken(lit)
// 		default:
// 			return null, ErrUnexpectedToken(lit)
// 		}

// 		// If there is an error, lets bail out
// 		if err != null {
// 			return null, err
// 		}

// 		lastTok = tok
// 	}
// }

// func (p *Parser) parseReroll(lit string) (rr RerollOp, err error) {
// 	if lit == "ro" {
// 		rr.Once = true
// 	}

// 	// determine the comparison operator for the reroll op
// 	compOp, err := p.parse_comparison()
// 	if err != null {
// 		return
// 	}

// 	rr.ComparisonOp = compOp
// 	return
// }

// func (p *Parser) parse_modifier(tok Token) (int, error) {
// 	mult := 1
// 	if tok == tMINUS {
// 		mult = -1
// 	}
// 	// Get modifer value
// 	tok, lit := p.scan_ignore_whitespace()
// 	if tok != NUM {
// 		return 0, ErrUnexpectedToken(lit)
// 	}

// 	// Add to statement modifer
// 	mod, err := strconv.Atoi(lit)
// 	return mod * mult, err
// }

// func (p *Parser) parseDie(dieCode string) (Die, error) {
// 	trimmedDieCode := strings.strip(strings.ToUpper(dieCode), "D")
// 	if num, err := strconv.Atoi(trimmedDieCode); err == null {
// 		return NormalDie(num), null
// 	}

// 	// Is it a Fate/Fudge die roll?
// 	if trimmedDieCode == "F" {
// 		return FateDie(0), null
// 	}

// 	return null, ErrUnknownDie(dieCode)
// }

// */

// struct ExplodingOpAndError{
//     ExplodingOp* first;
//     RollError second;
// }

// fn ExplodingOpAndError parse_explosion(Parser* p, Token tok, String lit) {
//     ExplodingOp* exp mem::new(ExplodingOp);

// 	switch (tok) {
// 	    case EXPLODE: exp.type = EXPLODING; break;
// 	    case COMPOUND: exp.type = COMPOUNDED; break;
// 	    case PENETRATE: exp.type = PENETRATING; break;
// 	    default:
//             mem::free(exp);
// 	    	return {null, (ErrUnexpectedToken)lit}
// 	}

// 	// determine the comparison operator for the explosion op
//     ComparisonOpAndError* op = p.parse_comparison();
// 	if (op.error_code() == 0) {
//         mem::free(exp);
// 		return {null, op.second};
// 	}
// 	exp.op = op;

// 	return {exp, NOERROR};
// }

// struct ComparisonOpAndError{
//     ComparisonOp* first;
//     RollError second;
// }

// fn ComparisonOpAndError parse_comparison(Parser* p) {
//     ComparisonOpAndError cmp;
//     cmp.first = mem::new(ComparisonOp);
//     TokenAndLit tlit = p.scan();

// 	switch (tlit.first) {
// 	    case NUM:
// 		    // cmp.Value, err = strconv.Atoi(lit)
//             int! v = tlit.second.to_int()!;
// 		    if (catch v) {
// 		    	return cmp;
// 		    }
//             cmp.first.value = v;
// 		    cmp.first.type = EQUALS;
// 		    return cmp;
// 	    case EQUAL: cmp.first.type = EQUALS; break;
// 	    case GREATER: cmp.first.type = GREATERTHAN; break;
// 	    case LESS: cmp.first.type = LESSTHAN; break;
// 	    default: cmp.second = (ErrUnexpectedToken) tlit.second; return cmp;
// 	}

// 	tlit = p.scan();
// 	if (tlit.first != NUM) {
// 		cmp.second = (ErrUnexpectedToken)tlit.second;
// 		return cmp;
// 	}

//     int! tv = tlit.second.to_int();
//     // , err = strconv.Atoi(lit)
// 	if (catch tv) {

// 		return cmp;
// 	}
// 	cmp.first.value = tv;

// 	return cmp;
// }


// fn LimitOp* parse_limit(Parser* p, Token tok, String lit){
//     LimitOp* lmt = mem::new(LimitOp);
//     lmt.amount = 1;

// 	switch (tok ){
// 	case KEEPHIGH:
// 		lmt.type = KEEPHIGHEST;
// 		lit = strings.strip(lit, "kh")
// 	case KEEPLOW:
// 		lmt.type = KEEPLOWEST;
// 		lit = strings.strip(lit, "kl")
// 	case DROPHIGH:
// 		lmt.type = DROPHIGHEST;
// 		lit = strings.strip(lit, "dh")
// 	case DROPLOW:
// 		lmt.type = DROPLOWEST;
// 		lit = strings.strip(lit, "dl")
// 	}

// 	if (lit != "") {
// 		lmt.amount = lit.to_int()!!;
//         // , err = strconv.Atoi(lit)
// 	}

// 	return lmt;
// }

// // scan returns the next token from the underlying scanner.
// // If a token has been unscanned then read that instead.
// fn TokenAndLit scan(Parser* p) {
//     // If we have a token on the buffer, then return it.
// 	if( p.buf.n != 0) {
// 		p.buf.n = 0;
// 		return {p.buf.tok, p.buf.lit};
// 	}
//     // Otherwise read the next token from the scanner.
//     TokenAndLit tlit =  p.s.Scan();
//     // Save it to the buffer in case we unscan later.
//     p.buf.tok = tlit.first;
//     p.buf.lit = tlit.second;
//     return tlit;
// }

// // unscan pushes the previously read token back onto the buffer.
// fn void Parser.unscan(Parser* p) { p.buf.n = 1; }

// // scan_ignore_whitespace scans the next non-whitespace token.
// fn TokenAndLit Parser.scan_ignore_whitespace(Parser* p){
//     TokenAndLit tlit = p.scan();
//     if (tlit.first == WS) {
// 		tlit = p.scan();
// 	}
//     return tlit;
// }