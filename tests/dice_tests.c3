module roll::tests;
import std::math::random;

struct DieRollTestStruct{
    long seed;
	Die die;
	int res;
	String sym;
}

// Ensure the die can roll results correctly.
fn void die_roll_tests() @test {
	DieRollTestStruct[*] tests =( DieRollTestStruct[]){
		// Fate rolls
		{.seed = 2, .die = &&(FateDie)(0), .res = 0, .sym = roll:: FATE_BLANK},
		{.seed = 1, .die = &&(FateDie)(0), .res = 1, .sym = roll:: FATE_PLUS},
		{.seed = 0, .die = &&(FateDie)(0), .res = -1, .sym =roll:: FATE_MINUS},

		// Normal Die (3)
		{.seed = 0, .die = &&(NormalDie)(3), .res = 1, .sym = "1"},
		{.seed = 2, .die = &&(NormalDie)(3), .res = 2, .sym = "2"},
		{.seed = 1, .die = &&(NormalDie)(3), .res = 3, .sym = "3"},

		// Normal Die (6)
		{.seed = 0, .die = &&(NormalDie)(6), .res = 5, .sym = "5"},
		{.seed = 4, .die = &&(NormalDie)(6), .res = 3, .sym = "3"},
		{.seed = 7, .die = &&(NormalDie)(6), .res = 4, .sym = "4"},
		{.seed = 12, .die = &&(NormalDie)(6), .res = 6, .sym = "6"},
		{.seed = 3, .die = &&(NormalDie)(6), .res = 2, .sym = "2"},
		{.seed = 1, .die = &&(NormalDie)(6), .res = 3, .sym = "3"},
	};

	foreach (i, tt : tests) {
		random::srand(tt.seed);
		DieRoll result = tt.die.roll();
        defer result.symbol.free(mem);
        assert(tt.res == result.result, "%d. result mismatch: exp=%d got=%d", i, tt.res, result.result);
        assert(tt.sym == result.symbol, "%d. symbol mismatch: exp=%s got=%s", i, tt.sym, result.symbol);
	}
}