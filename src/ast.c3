module roll;
import std::io;
import std::collections;
import std::collections::map;

// ComparisonType is the type of comparison
typedef ComparisonType = int;

// Equals matches only values that are equal to the comparison value
const ComparisonType EQUALS = 0;
// GreaterThan matches only values greater than the comparison value
const ComparisonType GREATER_THAN = 1;
// LessThan matches only values less than the comparison value
const ComparisonType LESS_THAN = 2;

// ComparisonOp is the operation that defines how you compare against a roll
// to determine whether the result counts
struct ComparisonOp (Printable) {
	ComparisonType type;
    int value;
}

// Match returns true if the given value compares positively against the op val
fn bool ComparisonOp.match(ComparisonOp* op, int val) {
	switch (op.type) {
	case EQUALS:
		return val == op.value;
	case GREATER_THAN:
		return val > op.value;
	case LESS_THAN:
		return val < op.value;
	}
	return false;
}

// String returns the string representation of the comparison operator
fn usz? ComparisonOp.to_format(ComparisonOp* op,  Formatter* formatter) @dynamic {
	switch (op.type) {
        case GREATER_THAN:
            return formatter.printf(">%d", op.value)!;
        case LESS_THAN:
            return formatter.printf("<%d", op.value)!;
        case EQUALS:
            return formatter.printf("=%d", op.value)!;
        default: unreachable("How did we get here?");
	}
}

// ExplodingType is the type of exploding die
typedef ExplodingType = int;
// Exploding adds new dice for each roll satisfying the exploding condition
const ExplodingType EXPLODING = 0;
// Compounded adds to a single new result for each roll
const ExplodingType COMPOUNDED = 1;
// Penetrating is like Exploding, except each die result has a -1 modifier
const ExplodingType PENETRATING = 2;


// ExplodingOp is the operation that defines how a dice roll explodes
struct ExplodingOp (Printable) {
	inline ComparisonOp* comparison_op;
	ExplodingType type;
}

// String returns the string representation of the exploding dice operation
fn usz? ExplodingOp.to_format(ExplodingOp* e,  Formatter* formatter) @dynamic => @pool() {
    String output;
	switch (e.type) {
        case EXPLODING:
            output = "!";
        case COMPOUNDED:
            output = "!!";
        case PENETRATING:
		    output = "!p";
	}

	DString tmp;
	tmp.tinit();
	tmp.appendf("%s", e.comparison_op);
	return formatter.printf("%s%s",output,tmp.str_view().trim_left("="))!;
}

// LimitType is the type of roll limitation
typedef LimitType = int;

// KeepHighest indicated we should keep the highest results
const LimitType KEEP_HIGHEST = 0;
// KeepLowest indicated we should keep the lowest results
const LimitType KEEP_LOWEST = 1;
// DropHighest indicated we should drop the highest results
const LimitType DROP_HIGHEST = 2;
// DropLowest indicated we should drop the lowest results
const LimitType DROP_LOWEST = 3;

// LimitOp is the operation that defines how dice roll results are limited
struct LimitOp (Printable) {
	int amount;
	LimitType type;
}

fn usz? LimitOp.to_format (LimitOp* op, Formatter* formatter) @dynamic {
	String output;
    switch (op.type) {
        case KEEP_HIGHEST:
            output = "kh";
        case KEEP_LOWEST:
            output = "kl";
        case DROP_HIGHEST:
            output = "dh";
        case DROP_LOWEST:
            output = "dl";
	}

	if (op.amount > 1) {
		return formatter.printf("%s%d", output, op.amount)!;
	}else {
		return formatter.printf("%s", output)!;
    }
}

// RerollOp is the operation that defines how dice are rerolled
struct RerollOp (Printable) {
	inline ComparisonOp* comparison_op;
	bool once;
}

fn usz? RerollOp.to_format (RerollOp* e, Formatter* formatter) @dynamic => @pool() {
    String output = "r";
	if (e.once) {
		output = "ro";
	}
	
	DString tmp;
	tmp.tinit();
	tmp.appendf("%s", e.comparison_op);
	return formatter.printf("%s%s",output,tmp.str_view().trim_left("="))!;
}


// SortType is the type of sorting to use for dice roll results
typedef SortType (Printable) = int;

// Unsorted doesn't sort dice rolls
const SortType UNSORTED   = 0;
// Ascending sorts dice rolls from lowest to highest
const SortType ASCENDING  = 1;
// Descending sorts dice rolls from highest to lowest
const SortType DESCENDING = 2;

// String return the string representation of a SortType value
fn String SortType.to_constant_string (SortType* t) @dynamic {
	switch (*t) {
		case ASCENDING:
			return "s";
		case DESCENDING:
			return "sd";
		case UNSORTED:
		default: 
			return "";
	}
}

// Roll is any kind of roll
interface Roll : Printable {
    fn Result roll();
    fn int mod();
}

// Result is a collection of die rolls and a count of successes
struct Result (Printable) {
    List{DieRoll} results;
	// DieRoll[] results;
	int total    ;
	int successes;
}

// Len is the number of results
fn int Result.len(Result* r) => (int) r.results.len();

// Less return true if DieRoll at index i is less than the one at index j
fn bool Result.less(Result* r, int i, int j) {
	return r.results[i].result < r.results[j].result;
}

// Swap swaps the DieRoll at index i with the one at index j
fn void Result.swap(Result* r, int i, int j) {
    DieRoll tmp = r.results[i];
	r.results[i] = r.results[j];
    r.results[j] = tmp;
}

fn void Result.free(&self) {
    foreach(&r : self.results) r.symbol.free(mem);
    self.results.free();
}

fn usz? Result.to_format(&result, Formatter* formatter) @dynamic {
	usz amt = formatter.printf("Total: %d [", result.total)!;
	foreach(roll : result.results){
		amt += formatter.printf("%s, ", roll)!;
	}
	amt += formatter.printf("] Successes: %d", result.successes)!;
	return amt;
}

// DiceRoll is an individual Dice Roll
struct DiceRoll (Roll) {
	int             multiplier;
	Die             die       ;
	int             modifier  ;
	ExplodingOp*    exploding ;
	LimitOp*        limit     ;
	ComparisonOp*   success   ;
	ComparisonOp*   failure   ;
	RerollOp[]      rerolls   ;
	SortType        sort      ;
}

fn int DiceRoll.mod(&self) @dynamic  => self.modifier;

// Roll gets the results of rolling the dice that make up a dice roll
fn Result DiceRoll.roll(DiceRoll* dr) @dynamic  {
    Result result;
	// 1. Do Multiplier rolls of Die
	if (dr.multiplier == 0 ) return result;

	int totalMultiplier = 1;
	if (dr.multiplier < 0) totalMultiplier = -1;

	for( int i = 0; i < dr.multiplier*totalMultiplier; i++) result.results.push(dr.die.roll());

	// 2. For each result, check reroll criteria and reroll if a match
	foreach (usz i, DieRoll* &roll : result.results ) {
        bool do_reroll = true;
        while(do_reroll) {
            do_reroll= false;
            foreach  (reroll : dr.rerolls ) {
                for (;reroll.comparison_op.match(roll.result); ) {
					roll.symbol.free(mem);
                    *roll = dr.die.roll();

                    if (reroll.once) {
                        do_reroll = true;
                        break;
                    }
                }
                if(do_reroll) break;
            }
        }
    }

	// 3. For each result, check exploding criteria and generate new rolls
	if (dr.exploding != null) {
		int len =  (int)result.results.len();
		switch (dr.exploding.type) {
		case EXPLODING:
            for(int i =0 ; i < len; i++){
                DieRoll roll = result.results[i];
				while (dr.exploding.comparison_op.match(roll.result)) {
					roll = dr.die.roll();
                    result.results.push(roll);
				}
			}
		case COMPOUNDED:
			int compound = 0;
            for(int i =0 ; i < len; i++){
				int ires = result.results[i].result;
				while (dr.exploding.comparison_op.match(ires)) {
					ires = dr.die.roll_free(mem);
					compound += ires;
				}
			}
			result.results.push ((DieRoll){ .result = compound, .symbol = string::format(mem, "%d", compound) }); 
		case PENETRATING:
			for(int i =0 ; i < len; i++){
				int ires = result.results[i].result;
				for (;dr.exploding.comparison_op.match(ires);) {
					ires = dr.die.roll_free(mem);
					result.results.push({
						.result = ires-1,
						.symbol = string::format(mem, "%d", ires-1)
					});
				}
			}
		}
	}
	// 4. Check results and apply limit operation
	applyLimit(dr.limit, &result);

	// 5. If success op set, add modifier to each result and add successes for each match
	applySuccess(dr.success, dr.modifier, &result);

	// 6. If failure op set, add modifier to each result and subtract successes for each match
	applyFailure(dr.failure, dr.modifier, &result);

	// 7. If sort op set, sort results
	applySort(dr.sort, &result);

	// 8. If success and failure ops not set, add modifier to total result
	finaliseTotals(dr.success, dr.failure, dr.modifier, totalMultiplier, &result);
    
	return result;
}

// usz represents the dice roll as a string
fn usz? DiceRoll.to_format (DiceRoll* dr, Formatter* output) @dynamic {
	usz amount;
	
	switch{
		case dr.multiplier < -1 || dr.multiplier > 1:  	amount += output.printf("%+d", dr.multiplier)!;
		case dr.multiplier == -1: 						amount += output.printf("-")!;
		case dr.multiplier == 1:  						amount += output.printf("+")!;
	}

	if (dr.die != null)       amount += output.printf("%s", dr.die)!;
	if (dr.modifier != 0 )    amount += output.printf("%+d", dr.modifier)!;

	foreach  (r : dr.rerolls) amount += output.printf("%s", r)!;

	if (dr.exploding != null) amount += output.printf("%s", *dr.exploding)!;
    if (dr.limit != null)     amount += output.printf("%s", *dr.limit)!;
    if (dr.success != null)   amount += output.printf("%s", *dr.success)!;
    if (dr.failure != null)   amount += output.printf("f%s", *dr.failure)!;

	return ( amount += output.printf("%s", dr.sort)!);
}

// GroupedRoll is a group of other rolls. You can have nested groups.
struct GroupedRoll (Roll) {
	Roll[]           rolls   ;
	int              modifier;
	LimitOp*         limit   ;
	ComparisonOp*    success ;
	ComparisonOp*    failure ;
	bool             combined;
	bool             negative;
}

fn int GroupedRoll.mod(&self) @dynamic  => self.modifier;

// Roll gets the results of rolling the dice that make up a dice roll
fn Result GroupedRoll.roll(GroupedRoll* gr) @dynamic {
    Result result;
	// 1. Generate results for each roll
	foreach (roll : gr.rolls) {
		if (gr.combined) {
			// 2. If combined, merge all roll results into one result set
			// NOTE: in combined mode, the roll modifier is added to each result
			int mod = roll.mod();

            Result roll_result = roll.roll();
            foreach( &res : roll_result.results) {
                result.results.push((DieRoll){
					res.result + mod,
                    string::format(mem, "%d", res.result + mod)
				});
                res.symbol.free(mem);
			}
		} else {
			// 3. If not combined, make new result set out of the totals for each roll
            Result t = roll.roll();
            defer t.free();
            DieRoll r = (DieRoll){t.total, string::format(mem, "%d",t.total)};
			result.results.push(r);
		}
	}

	// 4. If limit set, apply limit operation to results
	applyLimit(gr.limit, &result);

	// 5. If Success set, apply success op to results
	applySuccess(gr.success, gr.modifier, &result);

	// 6. If Failure set, apply failure op to results
	applyFailure(gr.failure, gr.modifier, &result);

	// 7. Add modifier or tally successes
	finaliseTotals(gr.success, gr.failure, gr.modifier, 1, &result);

	if( gr.negative ){
		result.total *= -1;
		foreach (i, &r : result.results ){
			r.result *= -1;
		}
	}
    
	return result;
}

// usz represents the grouped roll as a string
fn usz? GroupedRoll.to_format (GroupedRoll* gr, Formatter* formatter) @dynamic => @pool() {
    List{String} parts;
    parts.tinit();
    
	foreach (roll : gr.rolls) if(roll) parts.push( string::format( tmem, "%s",roll));
    
    String sep = ", ";
	if (gr.combined) sep = " + ";
 
    DString  output;
    output.tinit();
    String joined = string::join(tmem, parts.array_view(), sep);
    output.append(joined);
    defer output.free();

	if (gr.combined) {
        output.replace("+-", "-");
	} else if (gr.rolls.len == 1) {
		// This case should be impossible, but we want to be able to identify
		// it if it *does* somehow happen.
        output.append(",");
	}

    output.insert_char_at(0,'{');
    output.append_char('}');
	output.replace("{+", "{");
	output.replace("{-", "{");
	output.replace(", +", ", ");
	output.replace(", -", ", ");
	output.replace("+ +", "+ ");
	output.replace("+ -", "- ");

	if (gr.limit != null) output.appendf("%s", (*(gr.limit)));
    if (gr.success != null) output.appendf("%s", (*(gr.success)));
    if (gr.failure != null) output.appendf("f%s", (*(gr.failure)));
    if (gr.modifier) output.appendf("%+d", (gr.modifier));
    if (gr.negative) output.insert_char_at(0,'-');

	return formatter.printf("%s", output);
}

fn void applyLimit(LimitOp* limitOp ,Result* result ) => @pool() {
	if (limitOp == null ) return; 
    Result rolls;
    rolls.results.init_with_array(tmem, result.results.array_view());

	// Sort our tmp result copy
	sort(&rolls);

	// Work out limit
	int limit = limitOp.amount;
	if (limit > rolls.results.len()) limit = (int) rolls.results.len();

	switch (limitOp.type) {
        case KEEP_HIGHEST: while(limit > 0) {
			rolls.results.last()!!.free();
            @catch(rolls.results.remove_last());
            limit--;
        }
        case KEEP_LOWEST: while(limit-- > rolls.results.len()) {
            rolls.results.first()!!.free();
            @catch(rolls.results.remove_first());
        }
        case DROP_HIGHEST: while(limit > 0) {
			rolls.results.last()!!.free();
            @catch(rolls.results.remove_last());
            limit--;
        }
        case DROP_LOWEST: while(rolls.results.len() > limit) {
			rolls.results.last()!!.free();
			@catch(rolls.results.remove_last());
		}
	}

    HashMap{int, int} m;
	m.tinit(capacity: (uint) rolls.results.len());
	foreach (r : rolls.results) {
        if(m.has_key(r.result)){
            m.set(r.result, m[r.result]!! + 1);
        }else{
            m.set(r.result, 1);
        }
	}

    List{DieRoll} newResults;
    newResults.tinit(initial_capacity: rolls.results.len());
	foreach (&a : result.results) {
        int? b = m[a.result];
        if(catch b) continue;
		newResults.push(*a);
        b--;
		if (b == 0) {
            m.remove(a.result);
		}
        else {
            m.set(a.result, b);
        }
	}
	
    result.results.free();
	result.results = {};
	result.results.init_wrapping_array(mem, newResults.to_array(mem));
}

fn void applySuccess(ComparisonOp* successOp ,int modifier , Result* result) {
	if (successOp == null) return;

	foreach (roll : result.results)  if (successOp.match(roll.result + modifier)) {
		result.successes++;
	}
}

fn void applyFailure(ComparisonOp* failureOp ,int modifier ,Result* result ) {
    if (failureOp == null) return;

	foreach (roll : result.results) if (failureOp.match(roll.result + modifier)) {
		result.successes--;
	}
}

fn void applySort(SortType sortType,Result* result ) {
	switch (sortType) {
    	case ASCENDING:  sort(result);
    	case DESCENDING: sort(result, reverse: true);
    	default:  break;
	}
}


fn void finaliseTotals(ComparisonOp* successOp,ComparisonOp* failureOp ,int modifier,int multiplier ,Result* result ) {
	if ( !(successOp == null && failureOp == null) ){
		result.total = result.successes;
		return;
	}
	foreach (roll : result.results ) result.total += roll.result;
	result.total += modifier;
	result.total *= multiplier;
}

// insertion stort: https://www.geeksforgeeks.org/insertion-sort-algorithm/
fn void sort(Result* result, bool reverse = false) {
    List{DieRoll} rolls = result.results;
    usz len = rolls.len();
    for(int i =1; i < len; i++){
        DieRoll key = rolls[i];
        int j = i-1;

        if(reverse){
            while (j >= 0 && rolls[j].result > key.result) rolls[(usz)(j + 1)] = rolls[j--];
        } else {
            while (j >= 0 && rolls[j].result < key.result) rolls[(usz)(j + 1)] = rolls[j--];
        }

        rolls[(usz)(j + 1)] = key;
    }
}