module rollc3;
import std::io;
import std::collections;

distinct RollError = int;
const RollError NO_ERROR 			= 0;
const RollError UNEXPECTED_TOKEN 	= 1;
const RollError UNKNOWN_DIE 		= 2;
const RollError END_OF_ROLL 		= 3;
const RollError AMBIGUOUS_MODIFIER 	= 4;
const RollError INT_PARSE_FAILURE 	= 5;
const RollError COMPARISON_NO_INT 	= 6;

// roll is any kind of roll
struct Roll { 
    bool is_group;
    union{
        DiceRoll dr;
        GroupedRoll gr;
    }
	RollError err;
}

fn Result Roll.roll(Roll r){
    if(r.is_group) return r.gr.roll() ;
    return r.dr.roll();
}

fn String Roll.string(Roll r){
    if(r.is_group) return r.gr.string() ;
    return r.dr.string();
}

fn int Roll.modifier(Roll r){
    if(r.is_group) return r.gr.modifier ;
    return r.dr.modifier;
}

fn bool Roll.is_group(Roll r){
    return r.is_group;
}

def ResultList = List(<DieRoll>);

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
macro Result DiceRoll.roll(DiceRoll* dr){
    Result result;
	// 1. Do Multiplier rolls of Die
	if (dr.multiplier == 0) {
		return result;
	}

	int totalMultiplier = 1;
	if (dr.multiplier < 0 ){
		totalMultiplier = -1;
	}

    ResultList initial; defer initial.free();

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
    ResultList total; defer total.free();
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
macro Result GroupedRoll.roll(GroupedRoll* gr) {
    Result result;
    ResultList group_rolls; defer group_rolls.free();
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
		parts[index] =  roll.string();
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

def FaceMap =  HashMap(<int, int>);

fn void apply_limit(LimitOp* limitOp , Result* result) {
	if (limitOp != null) {
		// Work out limit
		int limit = limitOp.amount;
		result.sort();
		if(limit >= result.len()){
			switch (limitOp.type) {
				case KEEPHIGHEST:
				case KEEPLOWEST:
					return;
				case DROPHIGHEST:
				case DROPLOWEST:
					allocator::free(allocator::temp(), result.results);
					result.results = allocator::new_array(allocator::temp(), DieRoll, 0);
					return;
			}
		}
		switch (limitOp.type) {
			case KEEPHIGHEST:
				result.results = result.results[limit..]; break;
			case KEEPLOWEST:
				result.results = result.results[..limit-1]; break;
			case DROPHIGHEST:
				result.results = result.results[..limit-1]; break;
			case DROPLOWEST:
				result.results = result.results[limit..]; break;
		}
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

fn void apply_sort(SortType sortType, Result* result) {
	switch (sortType) {
	case UNSORTED: return;
	case ASCENDING:  result.sort(); 
        break;
	case DESCENDING: result.sort(true); 
        break;
	}
}

fn void Result.sort(Result* result, bool reverse = false){
	for(int i = 0; i < result.len()-1; i++){
		int min = i;
		for(int y = i+1; y < result.len(); y++){
			if(result.less(y, min)){ 
				min = y;
			}
		}
		result.swap(i, min);
	}
	

	if(reverse) for(int i = 0 ; i < result.len()/2; i++){
		int other = result.len()-1;
		result.swap( i, other);
	}
}

fn void finalise_totals(ComparisonOp* successOp, ComparisonOp*  failureOp, int modifier, int multiplier,Result*  result) {
	result.total = 0;
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
