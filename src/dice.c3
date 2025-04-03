module roll;
import std::math::random;

// fn void DieRoll.free(DieRoll* dieroll) {
//     if(dieroll.symbol.len > 0) dieroll.symbol.free();
// 	dieroll.symbol = "";
// }

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

	return DieRoll{
		.result = val,
		.symbol = string::format(sym, allocator: allocator::heap()),
	};
}

// String returns the string representation of the FateDie 
fn String FateDie.to_string(FateDie* d, Allocator allocator = allocator::heap()) @dynamic {
	return string::format("dF", allocator: allocator);
}

// Roll generates a random number and the appropriate symbol
fn DieRoll NormalDie.roll(NormalDie* d) @dynamic  {
	int val = random::rand_in_range(1, (int) *d) ;
	String sym = string::format("%d", val, allocator: allocator::heap());
	return DieRoll{
		.result = val,
		.symbol = sym,
	};
}

// String returns the string representation of the NormalDie 
fn String NormalDie.to_string(NormalDie* d, Allocator allocator = allocator::heap()) @dynamic {
    return string::format("d%d",*d, allocator: allocator);
}