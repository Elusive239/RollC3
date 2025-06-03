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
	int modifier;
	DynamicArenaAllocator alloc;
}

macro Parser* newParser(InStream r, Allocator alloc = mem) {
	Parser* parser = && (Parser){.s = newScanner(r), .alloc = {}};
	parser.alloc.init(alloc, PARSER_DEFAULT_ALLOC);
	return parser;
}
// Parse parses a Roll statement.
fn Roll? Parser.parse(&p) {
	p.alloc.reset();
	// First token should be a NUM or a DIE
	TokenLiteral tlit = p.scanIgnoreWhitespace();

	any roll;
	if(catch err = p.parseRoll(&roll, tlit, false)){
		if(err == END_OF_ROLL){
			if(roll.type  == DiceRoll.typeid) {return anycast(roll, DiceRoll);}
			else if(roll.type  == GroupedRoll.typeid) {return anycast(roll, GroupedRoll);}
			unreachable("Parse should never return anything that isn't DiceRoll or GroupedRoll...");
		}
		return err?;
	}
	if(roll.type  == DiceRoll.typeid) {return anycast(roll, DiceRoll);}
	else if(roll.type  == GroupedRoll.typeid) {return anycast(roll, GroupedRoll);}
	unreachable("Parse should never return anything that isn't DiceRoll or GroupedRoll...");
}

// parseRoll gets a roll of any type
fn void? Parser.parseRoll(&p, any* roll, TokenLiteral tlit, bool grouped) { //(Roll, error) 
	switch (tlit.first) {
		case NUM:
		case DIE:
			DiceRoll* rd = p.pclone((DiceRoll){});
			fault err = @catch(p.parseDiceRoll(rd, grouped));
			(*roll) = any_make(rd, DiceRoll.typeid);
			if(err) return err?; 
		case GROUPSTART:
			GroupedRoll* rd = p.pclone((GroupedRoll){});
			fault err = @catch(p.parseGroupedRoll(rd, grouped));
			(*roll) = any_make(rd, GroupedRoll.typeid);
			if(err) return err?; 
		default:
			*roll = null;
			return UNEXPECTED_TOKEN?;
	}
}

 // parseGrouped parses a GroupedRoll statement
fn void? Parser.parseGroupedRoll(&p, GroupedRoll* roll, bool grouped) { // (roll *GroupedRoll, err error) 
	bool negative;
	int multiplier;

	fault err = @catch(p.parseAndCollectRolls(roll, grouped, &negative, &multiplier));
	if(err == END_OF_ROLL) return err?;
	// We now have the collection of rolls within the grouped roll, now we need
	// to apply the modifiers to it
	while (true) {
		// Read a modifier
		TokenLiteral tlit = p.scanIgnoreWhitespace();

		// Handle modifier or EOF
		switch (tlit.first) {
			case PLUS:
			case MINUS:
			int? moderr = p.parseModifier(tlit.first);

			if (try moderr) {
				roll.modifier += moderr;
			} else {
				int mod;
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
							p.modifier = mod;
							return AMBIGUOUS_MODIFIER?;
						}
						return UNEXPECTED_TOKEN?;
					case GROUPEND:
					case GROUPSEP:
						if (grouped) {
							return END_OF_ROLL?;
						}
						return UNEXPECTED_TOKEN?;
					default:
						return err?;
				}
			}
			case KEEPHIGH:
			case KEEPLOW:
			case DROPHIGH:
			case DROPLOW:
				roll.limit = p.parseLimit(tlit)!;
			case GREATER:
			case LESS:
			case EQUAL:
				p.unscan();
				roll.success = p.parseComparison()!;
			case FAILURES:
				roll.failure = p.parseComparison()!;
			case EOF:
				return END_OF_ROLL?;
			case GROUPSEP:
				if (grouped) {
					return END_OF_ROLL?;
				}
				return UNEXPECTED_TOKEN?;
			case GROUPEND:
				p.unscan();
				return;
			default:
				return UNEXPECTED_TOKEN?;
		}
	}
}

fn void? Parser.parseAndCollectRolls(&p, GroupedRoll* roll, bool grouped, bool* negative, int* multiplier) {
	fault err;
	while(!err) {
		TokenLiteral tlit = p.scanIgnoreWhitespace();
		any anyr;
		err = @catch(p.parseRoll(&anyr, tlit, true));
		switch{
			case anyr == null: break;
			case anyr.type == GroupedRoll.typeid:
				GroupedRoll* gr = anycast(anyr, GroupedRoll)!;
				if(*multiplier < 0 ){
					gr.negative = true;
					*multiplier = 0;
				}
				if(*negative){
					gr.negative = true;
				}
			case anyr.type == DiceRoll.typeid:
				DiceRoll* dr = anycast(anyr, DiceRoll)!;
				if(*multiplier != 0){ 
					dr.multiplier = *multiplier;
					*multiplier = 0;
				}
				if(*negative){
					dr.multiplier *= -1;
				}
			default: unreachable("Unimplemented roll type.");
		}	

		//if there is a problem, try to correct
		if(err){
			*negative = false;
			// If we got an error and we have no rolls, it's definitely broken
			if(anyr == null && roll.rolls.len == 0){
				return err?;
			}

			// We got an ambiguous modifier, which means the *next* roll needs
			// to use this modifier as it's multiplier, so store it for later
			if(err == AMBIGUOUS_MODIFIER){
				*multiplier = p.modifier;
				p.unscan();
				err = {};
			}else{
				// Rollback
				p.unscan();
				tlit = p.scanIgnoreWhitespace();

				// Handle separators of the group
				switch (tlit.first) {
					case PLUS:
					case MINUS:
						*negative = true;
					case GROUPSEP:
						// If we have multiple rolls and are in combined mode when we
						// get a separator, then this is an invalid grouped roll
						if (roll.rolls.len > 1 && roll.combined) {
							return;
						}

						// We aren't combining if grouping with the GROUPSEP delimiter
						roll.combined = false;
						// We've finished parsing a roll, so reset err for loop
						err = {};
					case GROUPSTART:
						// We've finished parsing a roll, so reset err for loop and
						// unscan again to start us off on the new group
						p.unscan();
						err = {};
					case GROUPEND:
						// We've exited the group, so leave loop by letting error fall
						// through
						return END_OF_ROLL?;
					default:
						// Otherwise it IS an error
						return err?;
				}
			}
		}

		// If we've ended up with a dummy roll for some reason, don't add it (if anyr == null)
		if (anyr != null) switch(anyr.type){
			case DiceRoll.typeid :  append_roll(mem, roll, anyr, DiceRoll);
			case GroupedRoll.typeid :  append_roll(mem, roll, anyr, GroupedRoll);
			//if we get to here, we somehow returned something thats NOT a roll, which we shouldn't be doing...
			default: return err?;
		}
	}
	if(err) return err?;
}

macro void append_roll(Allocator allocator, GroupedRoll* roll, any anyr, $Type) {
	usz elements = roll.rolls.len;
	usz new_size = Roll.sizeof * (elements + 1);
	roll.rolls = ((Roll*)allocator::realloc(mem, (void*) roll.rolls.ptr, new_size))[:elements+1];
	roll.rolls[elements]= anycast(anyr, $Type)!!;
}

// parseDiceRoll parses a DiceRoll statement
fn void? Parser.parseDiceRoll(&p, DiceRoll* roll, bool grouped) { // (roll *GroupedRoll, err error) 
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
	ParsedDie? die = p.parseDie(tlit.second);
	if (catch err = die) {
		return err?;
	}
	if(die.type == NormalDie.typeid ){
		roll.die = p.pclone(((NormalDie) die.value));
	} else if(die.type == FateDie.typeid ){
		roll.die = p.pclone(((FateDie) 0));
	}

	if(catch (END_OF_ROLL?)) return; // PROBLEM IS ABOVE
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
			else if (catch err = moderr){
				if (tlit.first == MINUS) {
					mod = -1;
				}

				p.unscan();
				tlit = p.scanIgnoreWhitespace();
				switch (tlit.first) {
				case EOF:
					return;
				case GROUPSTART:
					if (grouped) {
						// Technically this is an end of roll, but we want to
						// capture the multiplier to determine the sign of the
						// next term
						p.modifier = mod;
						return AMBIGUOUS_MODIFIER?;
					}
					return UNEXPECTED_TOKEN?;
				case GROUPEND:
				case GROUPSEP:
					if (grouped) {
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
			roll.success = p.parseComparison()!;
		case FAILURES:
			roll.failure = p.parseComparison()!;
		case EOF: 
			return;
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
		default: 
			// io::printfn("Final Token: %s %d", tlit.second, tlit.first);
		return UNEXPECTED_TOKEN?;
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
		return { NormalDie.typeid, value};
	}

	// Is it a Fate/Fudge die roll?
	if( trimmedDieCode == "F") {
		return {FateDie.typeid, 0};
	}
	// io::printfn("Invalid Die Code: \"%s\" from \"%s\"", trimmedDieCode, dieCode);
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

macro Parser.pclone(&p, val) {
	return allocator::new(&p.alloc, $typeof(val), val);
}