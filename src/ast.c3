module rollc3;
import std::io;
import std::collections;

// ComparisonType is the type of comparison
def ComparisonType = int;	
// EQUALS matches only values that are equal to the comparison value
const ComparisonType EQUALS = 0;
// GREATERTHAN matches only values greater than the comparison value
const ComparisonType GREATERTHAN = 1;
// LESSTHAN matches only values less than the comparison value
const ComparisonType LESSTHAN = 2;

// ComparisonOp is the operation that defines how you compare against a roll
// to determine whether the result counts
struct ComparisonOp {
	ComparisonType type;
	int value;
}

// Match returns true if the given value compares positively against the op val
fn bool ComparisonOp.match(ComparisonOp* op, int val) {
	switch (op.type) {
	    case EQUALS: return val == op.value;
	    case GREATERTHAN: return val > op.value;
	    case LESSTHAN: return val < op.value;
	}
	return false;
}

// String returns the string representation of the comparison operator
fn String ComparisonOp.string(ComparisonOp* op) {
	switch (op.type) {
	    case EQUALS: return string::tformat("=%d", op.value);
	    case GREATERTHAN: return string::tformat(">%d", op.value);
	    case LESSTHAN: return string::tformat("<%d", op.value);
	}
	return "";
}

// ExplodingType is the type of exploding die
def ExplodingType = int;
// EXPLODING adds new dice for each roll satisfying the exploding condition
const ExplodingType EXPLODING = 0;
// COMPOUNDED adds to a single new result for each roll
const ExplodingType COMPOUNDED = 1;
// PENETRATING is like Exploding, except each die result has a -1 modifier
const ExplodingType PENETRATING = 2;

// ExplodingOp is the operation that defines how a dice roll explodes
struct ExplodingOp {
	inline ComparisonOp* op;
	ExplodingType type;
}

// String returns the string representation of the exploding dice operation
fn String ExplodingOp.string(ExplodingOp e) {
    DString output;
	switch (e.type) {
        case EXPLODING: output  .append  (  "!");
        case COMPOUNDED: output .append  ( "!!");
        case PENETRATING: output.append  ("!p" );
	}
    output.append(e.op.string().strip("="));

	return output.str_view().tcopy();
}

// LimitType is the type of roll limitation
def LimitType = int;
// KEEPHIGHEST indicated we should keep the highest results
const LimitType KEEPHIGHEST = 0;
// KEEPLOWEST indicated we should keep the lowest results
const LimitType KEEPLOWEST = 1;
// DROPHIGHEST indicated we should drop the highest results
const LimitType DROPHIGHEST = 2;
// DROPLOWEST indicated we should drop the lowest results
const LimitType DROPLOWEST = 3;

// LimitOp is the operation that defines how dice roll results are limited
struct LimitOp {
	int amount;
	LimitType type;
}

fn String LimitOp.string(LimitOp op) {
    DString output;
	switch (op.type) {
	    case KEEPHIGHEST: output.append( "kh") ; break;
        case KEEPLOWEST: output .append("kl" ); break;
        case DROPHIGHEST: output.append( "dh") ; break;
        case DROPLOWEST: output .append("dl"); break;
	}

	if (op.amount > 1) {
		output.append(string::tformat("%d", op.amount));
	}

	return output.str_view().tcopy();
}

// RerollOp is the operation that defines how dice are rerolled
struct RerollOp {
	ComparisonOp* op;
	bool once;
}

// String returns the string representation of the exploding dice operation
fn String RerollOp.string(RerollOp e){
    DString output; defer output.free();
	if (e.once) {output.append("ro");}
	else {output.append("r");}
    output.append(e.op.string().strip( "="));
	return output.str_view().tcopy();
}

// SortType is the type of sorting to use for dice roll results
def SortType = int;

// String return the string representation of a SortType value
fn String SortType.string(SortType t) => t == ASCENDING ? "s" : t == DESCENDING ? "sd" : "";

// UNSORTED doesn't sort dice rolls
const SortType UNSORTED = 0;
// ASCENDING sorts dice rolls from lowest to highest
const SortType ASCENDING = 1;
// DESCENDING sorts dice rolls from highest to lowest
const SortType DESCENDING = 2;


// roll is any kind of roll
interface Roll {
	fn Result roll();
	fn String string();
    fn int modifier();
    fn bool is_group();
}

// Result is a collection of die rolls and a count of successes
struct Result {
    DieRoll[] results;
    int total;
    int successes;
}

// len is the number of results
fn int Result.len(Result* r) => r.results.len;

// less return true if DieRoll at index i is less than the one at index j
fn bool Result.less(Result* r, int i, int j) =>  r.results[i].result < r.results[j].result;

// swap swaps the DieRoll at index i with the one at index j
fn void Result.swap(Result* r, int i, int j) {
    DieRoll temp = r.results[i];
    r.results[i] = r.results[j];
    r.results[j] = temp;
}

// DiceRoll is an individual Dice roll
struct DiceRoll {
	int multiplier;
	Die die;
	int modifier;
	ExplodingOp* exploding;
	LimitOp* limit;
	ComparisonOp* success;
	ComparisonOp* failure;
	RerollOp[] rerolls;
	SortType sort;
}
fn bool DiceRoll.is_group(DiceRoll dr) => false;
fn int DiceRoll.modifier(DiceRoll dr) => dr.modifier;

// roll gets the results of rolling the dice that make up a dice roll
fn Result DiceRoll.roll(DiceRoll* dr){
    Result result;
	// 1. Do Multiplier rolls of Die
	if (dr.multiplier == 0) {
		return result;
	}

	int totalMultiplier = 1;
	if (dr.multiplier < 0 ){
		totalMultiplier = -1;
	}

    List(<DieRoll>) initial; defer initial.free();

	for( int i = 0; i < dr.multiplier*totalMultiplier; i++) {
		initial.push(dr.die.roll());
	}

	// 2. For each result, check reroll criteria and reroll if a match
	foreach(i, roll : initial){
	    do REROLLONCE: {
            foreach(reroll : dr.rerolls){
			    while (reroll.op.match(roll.result)) {
			    	roll = dr.die.roll();
			    	result.results[i] = roll;
			    	if (reroll.once) {
			    		break REROLLONCE;
			    	}
			    }
		    }
        };
	}
    List(<DieRoll>) total; defer total.free();
	// 3. For each result, check exploding criteria and generate new rolls
	if (dr.exploding != null) {
		switch (dr.exploding.type) {
		case EXPLODING:
			foreach(roll : initial){
				while (dr.exploding.op.match(roll.result)) {
					roll = dr.die.roll();
					total.push(roll);
				}
			}
		case COMPOUNDED:
			int compound = 0;
			foreach(roll : initial){
				while (dr.exploding.op.match(roll.result)) {
					compound += roll.result;
					roll = dr.die.roll();
				}
			}
			total.push({compound,string::tformat("%d", compound) });
		case PENETRATING:
            foreach(roll : initial){
				while (dr.exploding.op.match(roll.result)) {
					roll = dr.die.roll();
					DieRoll newroll = roll;
					newroll.result--;
					newroll.symbol = string::tformat("%d", newroll.result);
					total.push(newroll);
				}
			}
		}
	}
    foreach(z : initial) total.push(z);
    result.results = total.to_new_array(allocator::temp());

	// 4. Check results and apply limit operation
	apply_limit(dr.limit, &result);

	// 5. If success op set, add modifier to each result and add successes for each match
	apply_success(dr.success, dr.modifier, &result);

	// 6. If failure op set, add modifier to each result and subtract successes for each match
	apply_failure(dr.failure, dr.modifier, &result);

	// 7. If sort op set, sort results
	apply_sort(dr.sort, &result);

	// 8. If success and failure ops not set, add modifier to total result
	finalise_totals(dr.success, dr.failure, dr.modifier, totalMultiplier, &result);

	return result;
}

// String represents the dice roll as a string
fn String DiceRoll.string(DiceRoll* dr) {
	DString output; defer output.free();
	if( dr.multiplier > 1 || dr.multiplier < -1) {
		output.append(string::tformat("%+d", dr.multiplier));
	} else if (dr.multiplier == -1 ){
		output.append("-");
	} else if (dr.multiplier == 1) {
		output.append("+");
	}

	output.append(dr.die.string());

	if (dr.modifier != 0) {
		output.append(string::tformat("+%d", dr.modifier));
	}

	foreach (r : dr.rerolls)  {
		output.append(r.string());
	}

	if (dr.exploding != null) {
		output.append((*dr.exploding).string());
	}

	if (dr.limit != null ){
		output.append((*dr.limit).string());
	}

	if (dr.success != null) {
		output.append((*dr.success).string());
	}

	if (dr.failure != null) {
		output.appendf("f%d", (*dr.failure).string());
	}

	output.append(dr.sort.string());

	return output.str_view().tcopy();
}

// GroupedRoll is a group of other rolls. You can have nested groups.
struct GroupedRoll {
	Roll[] rolls; 
	int modifier;
	LimitOp* limit;
	ComparisonOp* success;
	ComparisonOp* failure;
	bool combined;
	bool negative;
}

fn bool GroupedRoll.is_group(GroupedRoll gr) => true;
fn int GroupedRoll.modifier(GroupedRoll gr) => gr.modifier;

// roll gets the results of rolling the dice that make up a dice roll
fn Result GroupedRoll.roll(GroupedRoll* gr) {
    Result result;
    List(<DieRoll>) group_rolls; defer group_rolls.free();
	// 1. Generate results for each roll
	foreach (index, roll : gr.rolls) {
		if (gr.combined) {
			// 2. If combined, merge all roll results into one result set
			// NOTE: in combined mode, the roll modifier is added to each result
			int mod = roll.modifier();	
            foreach(res : roll.roll().results){
                group_rolls.push({
					res.result + mod,
					string::tformat("%d", res.result + mod)
				});
			}
		} else {
			// 3. If not combined, make new result set out of the totals for each roll
			int total = roll.roll().total;
			// result.results = append(result.results, DieRoll{total, strconv.Itoa(total)});
            group_rolls.push({total, string::tformat("%d", total)});
		}
	}
    result.results = mem::new_array(DieRoll, group_rolls.len());
    foreach(i, dr : group_rolls) result.results[i] = dr;

	// 4. If limit set, apply limit operation to results
	apply_limit(gr.limit, &result);

	// 5. If Success set, apply success op to results
	apply_success(gr.success, gr.modifier, &result);

	// 6. If Failure set, apply failure op to results
	apply_failure(gr.failure, gr.modifier, &result);

	// 7. Add modifier or tally successes
	finalise_totals(gr.success, gr.failure, gr.modifier, 1, &result);

	if (gr.negative) {
		result.total *= -1;
        foreach(i, r : result.results){
			r.result *= -1;
			result.results[i] = r;
		}
	}

	return result;
}

// String represents the grouped roll as a string
fn String GroupedRoll.string(GroupedRoll* gr) {
    DString output;
	String[] parts = mem::temp_new_array(String, gr.rolls.len);
    foreach(index, roll : gr.rolls){
		if (roll != null) {
			parts[index] =  roll.string();
		}
	}

	String sep = ", ";
	if( gr.combined) {
		sep = " + ";
	}
    foreach(p : parts) output.append(p);
    output.append(sep);
	// output = strings.Join(parts, sep);
	if (gr.combined) {
		output.replace( "+-", "-");
	} else if (gr.rolls.len == 1) {
		// This case should be impossible, but we want to be able to identify
		// it if it *does* somehow happen.
		output.append(",");
	}
    output.insert_at(0, '{');
    output.append_char('}');
	output.replace("{+", "{");
	output.replace("{-", "{");
	output.replace(", +", ", ");
	output.replace(", -", ", ");
	output.replace("+ +", "+ ");
	output.replace("+ -", "- ");

	if (gr.limit != null) {
		output.append((*gr.limit).string());
	}

	if (gr.success != null) {
		output.append((*gr.success).string());
	}

	if (gr.failure != null) {
		output.appendf("f%s", (*gr.failure).string());
	}

	if (gr.modifier != 0) {
		output.append(string::tformat("%+d", gr.modifier));
	}

	if( gr.negative) {
        output.insert_char_at(0, '-');
	}

	return output.str_view().tcopy();
}

fn void apply_limit(LimitOp* limitOp , Result* result) {
	if (limitOp != null) {
		Result rolls;
		rolls.results = mem::temp_new_array(DieRoll, result.results.len);
        foreach(i, r :result.results ) rolls.results[i] = r;
		// Sort our tmp result copy
        //TODO MAKE SORT FUNCTION
		// sort.sort(&rolls);

		// Work out limit
		int limit = limitOp.amount;
		if (limit > rolls.results.len) {
			limit = rolls.results.len;
		}

		switch (limitOp.type) {
		case KEEPHIGHEST:
			rolls.results = rolls.results[rolls.results.len-limit..];
		case KEEPLOWEST:
			rolls.results = rolls.results[..limit];
		case DROPHIGHEST:
			rolls.results = rolls.results[..rolls.results.len-limit];
		case DROPLOWEST:
			rolls.results = rolls.results[limit..];
		}
        HashMap(<int, int>) m; defer m.free();
		foreach(r : rolls.results){
            if(m.has_key(r.result)){
                m.set(r.result, m[r.result]!! + 1);
            }else{
                m.set(r.result, 0);
            }
		}

		DieRoll[] newResults = allocator::new_array(allocator::temp(), DieRoll, rolls.results.len);
        foreach(i, a : result.results ){
            int ok = m[a.result]!!;
			if (ok) {
                newResults[i] = a;
                m[a.result]--;
			}else{
                m.remove(a.result);
            }
		}

		result.results = newResults;
	}
}

fn void apply_success(ComparisonOp* successOp, int modifier, Result* result) {
	if (successOp != null) {
        foreach(roll : result.results){
			if (successOp.match(roll.result + modifier)) {
				result.successes++;
			}
		}
	}
}

fn void apply_failure(ComparisonOp* failureOp , int modifier, Result* result) {
	if (failureOp != null) {
		foreach(roll : result.results) {
			if (failureOp.match(roll.result + modifier)) {
				result.successes--;
			}
		}
	}
}

//TODO:
// 1. Create a sort function for a array of results
// 2. Create a reverse function for a array of results
fn void apply_sort(SortType sortType, Result* result) {
	switch (sortType) {
	case UNSORTED: return;
	case ASCENDING: // sort.sort(result); 
        break;
	case DESCENDING: // sort.sort(sort.reverse(result));
        break;
	}
}

fn void finalise_totals(ComparisonOp* successOp, ComparisonOp*  failureOp, int modifier, int multiplier,Result*  result) {
	if (successOp == null && failureOp == null) {
		foreach(roll : result.results) {
			result.total += roll.result;
		}
		result.total += modifier;
		result.total *= multiplier;
	} else {
		result.total = result.successes;
	}
}