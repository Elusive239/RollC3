module roll;
import std::math::random;

// FateBlank is the symbol for a blank Fate die face
const String FATE_BLANK = "☐";
// FateMinus is the symbol for a minus Fate die face
const String FATE_MINUS = "⊟";
// FatePlus is the symbol for a plus Fate die face
const String FATE_PLUS = "⊞";

// Roll generates a random number and the appropriate symbol
fn DieRoll FateDie.roll(FateDie* d) @dynamic {
	int val = random::rand_in_range(-1, 1);
	String sym = FATE_BLANK;

	switch (val) {
        case -1:
            sym = FATE_MINUS;
        case 1:
            sym = FATE_PLUS;
	}

	return {
		.result = val,
		.symbol = string::format(mem, sym),
	};
}

// String returns the string representation of the FateDie 
fn String FateDie.to_string(FateDie* d, Allocator allocator = mem) @dynamic {
	return string::format(allocator, "dF");
}

// Roll generates a random number and the appropriate symbol
fn DieRoll NormalDie.roll(NormalDie* d) @dynamic  {
	int val = random::rand_in_range(1, (int) *d) ;
 	String sym = string::format(mem, "%d", val);
	return  {
		.result = val,
		.symbol = sym,
	};
}

// String returns the string representation of the NormalDie 
fn String NormalDie.to_string(NormalDie* d, Allocator allocator = mem) @dynamic {
    return string::format(allocator, "d%d",*d);
}