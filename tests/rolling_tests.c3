module roll::tests;
import std::math::random;
import std::io;

struct ParserTestStruct{
    long seed;
    String in;
    union{
        String out;
        fault err;
    }
}

// Ensure the parser works
fn void test_parse() @test {
	ParserTestStruct[] tests =( ParserTestStruct[]){
		// Fate rolls
		{.seed= 0, .in= "2dF+4", .out=  "Rolled \"2dF+4\" and got ⊟, ☐ for a total of 3"},
		{.seed= 0, .in= "dF", .out= "Rolled \"dF\" and got ⊟ for a total of -1"},

		// Normal Die (3)
		{.seed= 0, .in= "3d3-2", .out= "Rolled \"3d3-2\" and got 1, 2, 1 for a total of 2"},
		{.seed= 0, .in= "d3+1", .out= "Rolled \"d3+1\" and got 1 for a total of 2"},

		// Normal Die (6)
		{.seed= 4, .in= "3d6+4", .out= "Rolled \"3d6+4\" and got 3, 1, 2 for a total of 10"},
		{.seed= 9, .in= "d6-1", .out= "Rolled \"d6-1\" and got 1 for a total of 0"},

		// Normal Die (6) Successes
		{.seed= 0, .in= "3d6+4>4f=6", .out= "Rolled \"3d6+4>4f=6\" and got 5, 6, 5 for a total of 3"},
		{.seed= 3, .in= "d6-1<3", .out= "Rolled \"d6-1<3\" and got 2 for a total of 1"},

		// Grouped rolls
		{.seed= 0, .in= "{3d6+4}", .out= "Rolled \"{3d6+4}\" and got 9, 10, 9 for a total of 28"},
		{.seed= 0, .in= "{3d6, 2d8}", .out= "Rolled \"{3d6, 2d8}\" and got 16, 7 for a total of 23"},
		{.seed= 0, .in= "{3d6 + 2d8}", .out= "Rolled \"{3d6 + 2d8}\" and got 5, 6, 5, 5, 2 for a total of 23"},

		// Grouped Successes
		{.seed= 0, .in= "{3d6 + 2d8}>3", .out= "Rolled \"{3d6 + 2d8}>3\" and got 5, 6, 5, 5, 2 for a total of 4"},
		{.seed= 0, .in= "{3d6 + 2d8}>2f=1", .out= "Rolled \"{3d6 + 2d8}>2f=1\" and got 5, 6, 5, 5, 2 for a total of 4"},

		// Errors
		{.seed= 0, .in= "3dX-2", .err=roll::UNKNOWN_DIE},
		{.seed= 0, .in= "CRAP", .err=roll::UNEXPECTED_TOKEN},
	};

	foreach (i, tt : tests) @pool() {
        random::srand(tt.seed);
        ByteReader br;
        br.init (tt.in);
        String? out = roll::parse(&br, tmem);

		if (catch err =out) {
            assert(err == tt.err, "%d. unexpected parse error: exp=%s got=%s", i, tt.err, err);
		} else{
            assert(tt.out == out, "%d. result mismatch: exp=%s got=%s", i, tt.out, out);
        }
        
	};
}

// Ensure the parser works
fn void  test_parse_string() @test {
	ParserTestStruct[] tests =( ParserTestStruct[]){
		// Fate rolls
		{.seed= 0, .in= "2dF+4", .out= `Rolled "2dF+4" and got ⊟, ☐ for a total of 3`},
		{.seed= 0, .in= "dF", .out= `Rolled "dF" and got ⊟ for a total of -1`},

		// Normal Die (3)
		{.seed= 0, .in= "3d3-2", .out= `Rolled "3d3-2" and got 1, 2, 1 for a total of 2`},
		{.seed= 0, .in= "d3+1", .out= `Rolled "d3+1" and got 1 for a total of 2`},

		// Normal Die (6)
		{.seed= 0, .in= "3d6+4", .out= `Rolled "3d6+4" and got 5, 6, 5 for a total of 20`},
		{.seed= 9, .in= "d6-1", .out= `Rolled "d6-1" and got 1 for a total of 0`},

		// Errors
		{.seed= 0, .in= "3dX-2", .err=roll::UNKNOWN_DIE},
		{.seed= 0, .in= "CRAP", .err= roll::UNEXPECTED_TOKEN},
	};

	foreach (i, tt : tests) @pool() {
        random::srand(tt.seed);
        String? out = roll::parse_string(tt.in, tmem);
		if (catch err =out) {
            assert(err == tt.err, "%d. unexpected parse error: exp=%s got=%s", i, tt.err, err);
		} else{
            assert(tt.out == out, "%d. result mismatch: exp=%s got=%s", i, tt.out, out);
        }
	};
}