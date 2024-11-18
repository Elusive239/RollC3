// module rollc3;
// import std::io;
// import std::collections::tuple;
// import std::collections::list;

// distinct ErrCode = uint;
// const ErrCode NO_ERROR = 0;
// const ErrCode UNEXPECTED_TOKEN = NO_ERROR+1;
// const ErrCode UNKOWN_DIE = UNEXPECTED_TOKEN+1;
// const ErrCode END_OF_ROLL = UNKOWN_DIE+1;
// const ErrCode AMBIGUOUS_MODIFIER = END_OF_ROLL+1;

// struct RollError{
//     ErrCode code; // 0 == no error
//     union{
//         String s;
//         int i;
//     }
// }

// fn String RollError.error_msg(RollError e){
//     switch(e.code){
//         case UNEXPECTED_TOKEN: return string::tformat("found unexpected token %s", e.s);
//         case UNKOWN_DIE: return string::tformat("unrecognised die type %s", e.s);
//         case END_OF_ROLL: return string::tformat("roll parsing terminated on %s", e.s);
//         case AMBIGUOUS_MODIFIER: return string::tformat("misread %d as modifier", e.i);
//     }
//     return "";
// }

// fn RollError new_error_s(ErrCode code, String val){
// 	RollError err;
//     switch(code){
//         case UNEXPECTED_TOKEN: 
//         case UNKOWN_DIE:
//         case END_OF_ROLL: err.s = (String) val.copy(allocator::temp());
// 		default: return err;
//     }
// 	err.code = code;
// 	return err;
// }

// fn RollError new_error_i(ErrCode code = NO_ERROR, int val = 0){
// 	RollError err;
//     switch(code){
//         case AMBIGUOUS_MODIFIER: err.i =  val; 
// 		default: return err;
//     }
// 	err.code = code;
// 	return err;
// }

// struct RollAndError{
//     Roll* first;
//     RollError second;
// }

// struct IntAndError{
//     int first;
//     RollError second;
// }

// // Parser is our dice rolling parser
// struct Parser {
// 	inline Scanner* s;
// 	struct buf {
//     	Token tok;
// 		String lit;
// 		int n  ;
// 	}
// }

// // new_parser returns a Parser instance
// fn Parser* new_parser(InStream r) {
//     Parser* p = allocator::new(allocator::temp(), Parser);
//     p.s = new_scanner(r);
// 	return p;
// }

// // Parse parses a Roll statement.
// fn RollAndError Parser.parse(Parser* p) {
// 	// First token should be a NUM or a DIE
// 	// io::printfn("Hi!");
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
//             return {null, new_error_s(UNEXPECTED_TOKEN, lit)};
// 	}
// }

// // parseGrouped parses a GroupedRoll statement
// fn RollAndError Parser.parse_grouped_roll(Parser* p, bool grouped) {
//     GroupedRoll* roll = allocator::new(allocator::temp(), GroupedRoll);
//     List(<Roll>) rolls; defer rolls.free();
//     roll.combined = true;
//     bool negative;
//     int multiplier;
//     RollAndError re;
//     while(re.second.code == 0){
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

//         if (re.second.code != 0) {
// 			negative = false;
// 			// If we got an error and we have no rolls, it's definitely broken
// 			if (re.first == null && roll.rolls.len == 0) {
// 				return {(Roll*) roll, re.second};
// 			}

// 			// We got an ambiguous modifier, which means the *next* roll needs
// 			// to use this modifier as it's multiplier, so store it for later
// 			if (re.second.code == AMBIGUOUS_MODIFIER) {
// 				multiplier = re.second.i;
// 				p.unscan();
// 				re.second = {};
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
// 						return {(Roll*) roll, re.second};
// 					}

// 					// We aren't combining if grouping with the GROUPSEP delimiter
// 					roll.combined = false;
// 					// We've finished parsing a roll, so reset err for loop
// 					re.second = {};
// 				case GROUPSTART:
// 					// We've finished parsing a roll, so reset err for loop and
// 					// unscan again to start us off on the new group
// 					p.unscan();
// 					re.second = {};
// 				case GROUPEND:
// 					// We've exited the group, so leave loop by letting error fall
// 					// through
// 					re.second = new_error_s(END_OF_ROLL, tlit2.second);
// 				default:
// 					// Otherwise it IS an error
// 					return {(Roll*) roll, re.second};
// 				}
// 			}
// 		}

//         // If we've ended up with a dummy roll for some reason, don't add it
// 		if (re.first != null) {
//             rolls.push(*re.first);
// 		}
//     }
//     roll.rolls = rolls.to_new_array(allocator::temp());
//     return {(Roll*) roll, new_error_i()};
// }

// // parse_dice_roll parses a DiceRoll statement
// fn RollAndError Parser.parse_dice_roll(Parser* p, bool grouped)  {
// 	DiceRoll* roll = mem::new(DiceRoll);
// 	RollError err;
// 	TokenAndLit tlit;


// 	// If NUM, we store it as the multiplier, else we use 1
// 	if (tlit.first == NUM ){
// 		roll.multiplier = tlit.second.to_int()!!;
// 		tlit = p.scan_ignore_whitespace();
// 		if (tlit.first != DIE) {
// 			return {null, new_error_s(UNEXPECTED_TOKEN,tlit.second)};
// 		}
// 	} else {
// 		roll.multiplier = 1;
// 	}

// 	Die die = p.parse_die(tlit.second);
// 	roll.die = die;
// 	// We will have a DIE token here, so parse it
// 	if( err.code == 0) {
// 		return {null, err};
// 	}

// 	// Next we should loop over all our modifiers and total them up
// 	int mod;
// 	Token lastTok;
// 	List(<RerollOp>) rerolls; defer rerolls.free();
// 	while(true) {
// 		// Read a modifier
// 		tlit = p.scan_ignore_whitespace();

// 		// Handle modifier or EOF
// 		switch (tlit.first) {
// 		case PLUS:
// 		case MINUS:
// 			IntAndError merr = p.parse_modifier(tlit.first);
// 			mod = merr.first;
// 			err = merr.second;
// 			if (err.code == 0) {
// 				roll.modifier += mod;
// 			} else {
// 				if (tlit.first == MINUS) {
// 					mod = -1;
// 				}

// 				p.unscan();
// 				tlit = p.scan_ignore_whitespace();
// 				switch (tlit.first) {
// 				case EOF:
// 					err = new_error_s(END_OF_ROLL, tlit.second);
// 					return {(Roll*)roll, err};
// 				case GROUPSTART:
// 					if (grouped) {
// 						// Technically this is an end of roll, but we want to
// 						// capture the multiplier to determine the sign of the
// 						// next term
// 						err = new_error_i(AMBIGUOUS_MODIFIER, mod);
// 						return {(Roll*)roll, err};
// 					}
// 					return {null, new_error_s(UNEXPECTED_TOKEN, tlit.second)};
// 				case GROUPEND:
// 				case GROUPSEP:
// 					if (grouped) {
// 						err = new_error_s(END_OF_ROLL, tlit.second);
// 						return {(Roll*)roll, err};
// 					}
// 					return {null, new_error_s(UNEXPECTED_TOKEN, tlit.second)};
// 				default:
// 					return {null, err};
// 				}
// 			}
// 		case EXPLODE:
// 		case COMPOUND:
// 		case PENETRATE:
// 			ExplodingOpAndError ee = p.parse_explosion(tlit.first, tlit.second);
// 			roll.exploding = ee.first;
// 			err = ee.second;
// 		case KEEPHIGH:
// 		case KEEPLOW:
// 		case DROPHIGH:
// 		case DROPLOW:
// 			roll.limit = p.parse_limit(tlit.first, tlit.second);
// 		case SORT:
// 			switch (tlit.second) {
// 			case "s":
// 				roll.sort = ASCENDING;
// 			case "sd":
// 				roll.sort = DESCENDING;
// 			}
// 		case REROLL:
// 			RerollOp rr = p.parse_reroll(tlit.second);
// 			// roll.rerolls = append(roll.rerolls, rr);
// 			rerolls.push(rr);
// 		case GREATER:
// 		case LESS:
// 		case EQUAL:
// 			p.unscan();
// 			ComparisonOpAndError compErr = p.parse_comparison(); 
// 			roll.success = compErr.first;
// 			err = compErr.second;
// 		case FAILURES:
// 			ComparisonOpAndError compErr = p.parse_comparison(); 
// 			roll.failure = compErr.first;
// 			err = compErr.second;
// 		case EOF:
// 			err = new_error_s(END_OF_ROLL, tlit.second);
// 			roll.rerolls = rerolls.to_new_array();
// 			return {(Roll*)roll, err};
// 		case GROUPEND:
// 		case GROUPSEP:
// 			roll.rerolls = rerolls.to_new_array();
// 			if (grouped) {
// 				err = new_error_s(END_OF_ROLL, tlit.second);
// 				return {(Roll*)roll, err};
// 			}
// 			err = new_error_s(UNEXPECTED_TOKEN, tlit.second);
// 			return{ null, err};
// 		case DIE:
// 			// It's ambiguous whether or not a +/- number is a modifier or a
// 			// a combined die roll. If grouped and we get a die character AND
// 			// the last token processed was a modifier, then we rewind and then
// 			// raise a special error to indicate it needs attention.
// 			roll.rerolls = rerolls.to_new_array();
// 			if (grouped && (lastTok == PLUS || lastTok == MINUS) ){
// 				p.unscan();
// 				roll.modifier -= mod;
// 				err = new_error_i(AMBIGUOUS_MODIFIER, mod);
// 				return {(Roll*)roll, err};
// 			}
// 			return {(Roll*)roll, new_error_s(END_OF_ROLL, tlit.second)};
// 		default:
// 			roll.rerolls = rerolls.to_new_array();
// 			return {(Roll*)roll, new_error_s(END_OF_ROLL, tlit.second)};
// 		}
		
// 		// If there is an error, lets bail out
// 		if (err.code != 0) {
// 			return {null, err};
// 		}

// 		lastTok = tlit.first;
// 	}
// 	// return {(Roll*) roll, err};
// }

// // func (p *Parser) parse_reroll(lit string) (rr RerollOp, err error) 
// fn RerollOp Parser.parse_reroll(Parser* p, String lit)
// {
// 	RerollOp rr;
// 	if (lit == "ro") {
// 		rr.once = true;
// 	}

// 	// determine the comparison operator for the reroll op
// 	ComparisonOpAndError err = p.parse_comparison();
// 	if( err.second.code != 0 ){
// 		return rr;
// 	}
// 	rr.op = err.first;
// 	return rr;
// }

// // func (p *Parser) parse_modifier(tok Token) (int, error) 
// fn IntAndError Parser.parse_modifier(Parser* p, Token tok)
// {
// 	int mult = 1;
// 	if (tok == MINUS) {
// 		mult = -1;
// 	}
// 	// Get modifer value
// 	TokenAndLit tlit = p.scan_ignore_whitespace();
// 	if (tlit.first != NUM) {
// 		return {0, new_error_s(UNEXPECTED_TOKEN, tlit.second)};
// 		// return 0, ErrUnexpectedToken(lit)
// 	}

// 	// Add to statement modifer
// 	int mod = tlit.second.to_int()!!;
// 	// mod, err := strconv.Atoi(lit)
// 	return {mod * mult, new_error_i()};
// }

// struct DieAndError{
// 	Die first;
// 	RollError second;
// }

// // func (p *Parser) parse_die(dieCode string) (Die, error) 
// fn Die Parser.parse_die(Parser* p, String dieCode)
// {
// 	String trimmedDieCode = dieCode.new_ascii_to_upper().strip("D");
// 	int! num = trimmedDieCode.to_int();
// 	if  (try num) {
// 		NormalDie nd = num;
// 		return (Die) mem::new(NormalDie, nd);// (Die) nd;
// 	}

// 	// Is it a Fate/Fudge die roll?
// 	if (trimmedDieCode == "F") {
// 		FateDie fd;
// 		// return (Die) fd;
// 		return (Die) mem::new(NormalDie, fd);
// 	}
// 	NormalDie nds = 0;
// 	// return (Die) nds;
// 	return (Die) mem::new(NormalDie, nds);
// 	// return null, ErrUnknownDie(dieCode)
// }


// struct ExplodingOpAndError{
//     ExplodingOp* first;
//     RollError second;
// }

// fn ExplodingOpAndError Parser.parse_explosion(Parser* p, Token tok, String lit) {
//     ExplodingOp* exp = mem::new(ExplodingOp);

// 	switch (tok) {
// 	    case EXPLODE: exp.type = EXPLODING; break;
// 	    case COMPOUND: exp.type = COMPOUNDED; break;
// 	    case PENETRATE: exp.type = PENETRATING; break;
// 	    default:
//             mem::free(exp);
// 	    	return {null, new_error_s(UNEXPECTED_TOKEN, lit) };
// 	}

// 	// determine the comparison operator for the explosion op
//     ComparisonOpAndError op = p.parse_comparison();
// 	if (op.second.code != 0) {
//         mem::free(exp);
// 		return {null, op.second};
// 	}
// 	exp.op = op.first;

// 	return {exp, new_error_i()};
// }

// struct ComparisonOpAndError{
//     ComparisonOp* first;
//     RollError second;
// }

// fn ComparisonOpAndError Parser.parse_comparison(Parser* p) {
//     ComparisonOpAndError cmp;
//     cmp.first = mem::new(ComparisonOp);
//     TokenAndLit tlit = p.scan();

// 	switch (tlit.first) {
// 	    case NUM:
// 		    // cmp.Value, err = strconv.Atoi(lit)
//             int! v = tlit.second.to_int();
// 		    if (catch v) {
// 		    	return cmp;
// 		    }
//             cmp.first.value = v;
// 		    cmp.first.type = EQUALS;
// 		    return cmp;
// 	    case EQUAL: cmp.first.type = EQUALS; break;
// 	    case GREATER: cmp.first.type = GREATERTHAN; break;
// 	    case LESS: cmp.first.type = LESSTHAN; break;
// 	    default: cmp.second = new_error_s(UNEXPECTED_TOKEN, tlit.second); return cmp;
// 	}

// 	tlit = p.scan();
// 	if (tlit.first != NUM) {
// 		cmp.second = new_error_s(UNEXPECTED_TOKEN, tlit.second);
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


// fn LimitOp* Parser.parse_limit(Parser* p, Token tok, String lit){
//     LimitOp* lmt = mem::new(LimitOp);
//     lmt.amount = 1;

// 	switch (tok ){
// 	case KEEPHIGH:
// 		lmt.type = KEEPHIGHEST;
// 		lit = lit.strip("kh");
// 	case KEEPLOW:
// 		lmt.type = KEEPLOWEST;
// 		lit = lit.strip("kl");
// 	case DROPHIGH:
// 		lmt.type = DROPHIGHEST;
// 		lit = lit.strip("dh");
// 	case DROPLOW:
// 		lmt.type = DROPLOWEST;
// 		lit = lit.strip("dl");
// 	}

// 	if (lit != "") {
// 		lmt.amount = lit.to_int()!!;
//         // , err = strconv.Atoi(lit)
// 	}

// 	return lmt;
// }

// // scan returns the next token from the underlying scanner.
// // If a token has been unscanned then read that instead.
// fn TokenAndLit Parser.scan(Parser* p) {
//     // If we have a token on the buffer, then return it.
// 	if( p.buf.n != 0) {
// 		p.buf.n = 0;
// 		return {p.buf.tok, p.buf.lit};
// 	}
// 	io::printfn("Hi!");
//     // Otherwise read the next token from the scanner.
//     TokenAndLit tlit =  p.s.scan();
// 	io::printfn("Hi!");
//     // Save it to the buffer in case we unscan later.
//     p.buf.tok = tlit.first;
//     p.buf.lit = tlit.second;
// 	io::printfn("Hi!");
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