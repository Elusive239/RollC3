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

fn int Die.max(Die d) => d.normal ? (int) d.nd : 1;

fn DieRoll Die.roll(Die d){
    if(d.normal){
        int val = random::rand_in_range(1, d.nd);
	    String sym = string::tformat("%d", val);
        return {val, sym};
    }else{
        int val = random::rand_in_range(-1, 1);
        String sym = FATEBLANK;
        switch (val) {
	        case -1: sym = FATEMINUS; break;
	        case 1: sym = FATEPLUS; break;
	    }
        return {val,sym};
    }
}

fn String Die.string(Die d){
    return d.normal ? string::tformat("d%d", d.nd) : "dF";
}

// FateDie is a die representing the typical Fate/Fudge die
def FateDie = int;
// FATEBLANK is the symbol for a blank Fate die face
const String FATEBLANK = "☐";
// FATEMINUS is the symbol for a minus Fate die face
const String FATEMINUS = "⊟";
// FATEPLUS is the symbol for a plus Fate die face
const String FATEPLUS = "⊞";

// NormalDie is a die representing an N-sided die
def NormalDie = int;
