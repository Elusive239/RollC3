module rollc3;
import std::math::random;

// DieRoll is the result of a die roll
struct DieRoll{
	int result;
	String symbol;
}

// Die is the interface allDice must confirm to
struct Die { 
    bool normal;
    union{
        NormalDie nd;
        FateDie fd;
    }
}

fn DieRoll Die.roll(Die d){
    if(d.normal) return d.nd.roll();
    return d.fd.roll();
}

fn String Die.string(Die d){
    if(d.normal) return d.nd.string();
    return d.fd.string();
}

// FateDie is a die representing the typical Fate/Fudge die
def FateDie = int;
// FATEBLANK is the symbol for a blank Fate die face
const String FATEBLANK = "☐";
// FATEMINUS is the symbol for a minus Fate die face
const String FATEMINUS = "⊟";
// FATEPLUS is the symbol for a plus Fate die face
const String FATEPLUS = "⊞";

// Roll generates a random number and the appropriate symbol
fn DieRoll FateDie.roll(FateDie d){
    int val = random::rand_in_range(-1, 1);
    String sym = FATEBLANK;
    switch (val) {
	    case -1: sym = FATEMINUS; break;
	    case 1: sym = FATEPLUS; break;
	}
    return {val,sym};
}

// String returns the string representation of the FateDie type
fn String FateDie.string(FateDie d) => "df";

// NormalDie is a die representing an N-sided die
def NormalDie = int;

// Roll generates a random number and the appropriate symbol
fn DieRoll NormalDie.roll(NormalDie d){
    int val = random::rand_in_range(1, d);
	String sym = string::tformat("%d", val);
    return {val, sym};
}

// String returns the string representation of the NormalDie type
fn String NormalDie.string(NormalDie d) => string::tformat("d%d", d);
