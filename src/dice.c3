module roll;
import std::math::random;
import std::io;

// DieRoll is the result of a die roll
struct DieRoll{
	int result; 
	String symbol;
}

macro void DieRoll.free(&dr, Allocator allocator = mem) => dr.symbol.free(allocator);

fn usz? DieRoll.to_format(&dr, Formatter* formatter) @dynamic => formatter.printf("%s(%d)", dr.symbol, dr.result)!;

// Die is the interface allDice must confirm to
interface Die : Printable {
	fn DieRoll roll();
}

// Gets the result without the symbol, incase you don't need it
macro int Die.roll_free(&self, Allocator allocator) {
	DieRoll roll = self.roll();
	roll.free(allocator);
	return roll.result;
}

// FateDie is a die representing the typical Fate/Fudge die
typedef FateDie (Die) = int;

// FateBlank is the symbol for a blank Fate die face
const String FATE_BLANK = "☐";
// FateMinus is the symbol for a minus Fate die face
const String FATE_MINUS = "⊟";
// FatePlus is the symbol for a plus Fate die face
const String FATE_PLUS = "⊞";

// Roll generates a random number and the appropriate symbol
fn DieRoll FateDie.roll(FateDie* d) @dynamic {
	int val = random::rand_in_range(-1, 1);
	switch (val) {
        case -1: return {val, FATE_MINUS.copy(mem)};
        case 1:  return {val, FATE_PLUS.copy(mem)};
		case 0:  return {val, FATE_BLANK.copy(mem)};
		default: unreachable("How did we get here?");
	}
}

// String returns the string representation of the FateDie 
fn String FateDie.to_constant_string(&d) @dynamic =>"dF";

// NormalDie is a die representing an N-sided die
typedef NormalDie (Die) = int;

// Roll generates a random number and the appropriate symbol
fn DieRoll NormalDie.roll(NormalDie* d) @dynamic  {
	int val = random::rand_in_range(1, (int) *d) ;
	return  { val, string::format(mem, "%d", val)};
}

// String returns the string representation of the NormalDie 
fn usz? NormalDie.to_format(&d, Formatter* formatter) @dynamic => formatter.printf("d%d", *d)!;