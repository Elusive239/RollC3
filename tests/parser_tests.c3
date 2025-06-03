module roll::tests;
import std::math::random;
import std::io;

struct ParserRollTestStruct{
    String s;
    Roll roll;
    fault err;
}

fn void parser_roll_no_groups_test() @test {
    ParserRollTestStruct[] tests = (ParserRollTestStruct[]){
		// Simple roll
		{
			.s= `3d6`,
			.roll= &&(DiceRoll){
				.multiplier= 3,
				.die=        &&(NormalDie)(6),
				.modifier=   0,
			},
		},

		// Fate roll statement
		{
			.s= `4dF`,
			.roll= &&(DiceRoll){
				.multiplier= 4,
				.die=        &&(FateDie)(0),
				.modifier=   0,
			},
		},

		// Simple roll with modifier
		{
			.s= `3d6+4`,
			.roll= &&(DiceRoll){
				.multiplier= 3,
				.die=        &&(NormalDie)(6),
				.modifier=   4,
			},
		},

		// Fate roll with modifier
		{
			.s= `3dF+4`,
			.roll= &&(DiceRoll){
				.multiplier= 3,
				.die=        &&(FateDie)(0),
				.modifier=   4,
			},
		},

		// Simple roll with multiple modifiers
		{
			.s= `3d6+4-1+6-3`,
			.roll= &&(DiceRoll){
				.multiplier= 3,
				.die=        &&(NormalDie)(6),
				.modifier=   6,
			},
		},

		// Simple roll with no multiplier
		{
			.s= `d6`,
			.roll= &&(DiceRoll){
				.multiplier= 1,
				.die=        &&(NormalDie)(6),
				.modifier=   0,
			},
		},

		// // Simple roll with limit
		{
			.s= `4d6kh3`,
			.roll= &&(DiceRoll){
				.multiplier= 4,
				.die= &&(NormalDie)(6),
				.limit= &&(LimitOp){
					.type= roll::KEEP_HIGHEST,
					.amount= 3,
				},
			},
		},

		// // Multi-roll, compounded on 5s, keep top 3, sort descending, +3
		{
			.s= `6d6!!5kh3sd+3`,
			.roll= &&(DiceRoll){
				.multiplier= 6,
				.die=        &&(NormalDie)(6),
				.modifier=   3,
				.sort=       roll::DESCENDING,
				.limit= &&(LimitOp){
					.type=   roll::KEEP_HIGHEST,
					.amount= 3,
				},
				.exploding= &&(ExplodingOp){
					.type= roll::COMPOUNDED,
					.comparison_op= &&(ComparisonOp){
						.type=  roll::EQUALS,
						.value= 5,
					},
				},
			},
		},

		// // Multi-roll, reroll 2s, reroll once on 4s, successes > 3, failures on 1s
		{
			.s= `6d6r2ro4>3f=1`,
			.roll= &&(DiceRoll){
				.multiplier= 6,
				.die=        &&(NormalDie)(6),
				.rerolls= (RerollOp[]){
					(RerollOp){
						.comparison_op= &&(ComparisonOp){
							.type=  roll::EQUALS,
							.value= 2,
						},
					},
					(RerollOp){
						.comparison_op= &&(ComparisonOp){
							.type=  roll::EQUALS,
							.value= 4,
						},
						.once= true,
					},
				},
				.success= &&(ComparisonOp){
					.type=  roll::GREATER_THAN,
					.value= 3,
				},
				.failure= &&(ComparisonOp){
					.type=  roll::EQUALS,
					.value= 1,
				},
			},
		},
    };

    foreach(idx, test : tests){
		if(catch (roll::END_OF_ROLL?)){
			io::printfn("From Test: %s",test.roll );
			continue;			
		}
        ByteReader br;
        br.init(test.s);
		@pool(){
			Parser* parser = roll::newParser(&br, tmem);
			Roll? roll = parser.parse();
			if(catch e = roll){
				assert(e == roll::END_OF_ROLL, "%d. Parser error, %s", idx, e);
			}
			if(try roll) {
				DString tmp;
				tmp.tinit();
				tmp.appendf("%s", test.roll);
				String test_str = tmp.copy_str(tmem);
				tmp.clear();
				tmp.appendf("%s", roll);
				assert(tmp.str_view() == test_str, "%d. Got: {%s} Expected: {%s}", idx, tmp.str_view(), test_str);
			}
        };
    }
}

fn void parser_roll_only_groups_test() @test {
    ParserRollTestStruct[] tests = (ParserRollTestStruct[]){
		// Grouped multi-roll, drop lowest, successes on 1s, fails > 5
		{
			.s= `{3d6+4,2d8}dl=1f>5`,
			.roll= &&(GroupedRoll){
				.rolls= (Roll[]){
					&&(DiceRoll){
						.multiplier= 3,
						.die=        &&(NormalDie)(6),
						.modifier=   4,
					},
					&&(DiceRoll){
						.multiplier= 2,
						.die=        &&(NormalDie)(8),
					},
				},
				.limit= &&(LimitOp){
					.amount= 1,
					.type=   roll::DROP_LOWEST,
				},
				.success= &&(ComparisonOp){
					.type=  roll::EQUALS,
					.value= 1,
				},
				.failure= &&(ComparisonOp){
					.type=  roll::GREATER_THAN,
					.value= 5,
				},
				.combined= false,
			},
		},

		// Grouped combined nested multi-roll, keep high 3, succ <4, fail >3
		{
			.s= "{3d6+2d8-{4d4-1}dl}kh3<4f>3",
			.roll= &&(GroupedRoll){
				.rolls= (Roll[]){
					&&(DiceRoll){
						.multiplier= 3,
						.die=        &&(NormalDie)(6),
					},
					&&(DiceRoll){
						.multiplier= 2,
						.die=        &&(NormalDie)(8),
					},
					&&(GroupedRoll){
						.rolls= (Roll[]){
							&&(DiceRoll){
								.multiplier= 4,
								.die=        &&(NormalDie)(4),
								.modifier=   -1,
							},
						},
						.limit= &&(LimitOp){
							.amount= 1,
							.type=   roll::DROP_LOWEST,
						},
						.combined= true,
						.negative= true,
					},
				},
				.limit= &&(LimitOp){
					.amount= 3,
					.type=   roll::KEEP_HIGHEST,
				},
				.success= &&(ComparisonOp){
					.type=  roll::LESS_THAN,
					.value= 4,
				},
				.failure= &&(ComparisonOp){
					.type=  roll::GREATER_THAN,
					.value= 3,
				},
				.combined = true,
			},
		},
	};

	foreach(idx, test : tests){
		
        ByteReader br;
        br.init(test.s);
		@pool(){
			Parser* parser = roll::newParser(&br, tmem);
			Roll? roll = parser.parse();
			if(catch e = roll){
				assert(e == roll::END_OF_ROLL, "%d. Parser error, %s", idx, e);
			}
			if(try roll) {
				DString tmp;
				tmp.tinit();
				tmp.appendf("%s", test.roll);
				String test_str = tmp.copy_str(tmem);
				tmp.clear();
				tmp.appendf("%s", roll);
				assert(tmp.str_view() == test_str, "%d. Got: {%s} Expected: {%s}", idx, tmp.str_view(), test_str);
			}
        };
    }
}


fn void parser_roll_failures_test() @test {
	ParserRollTestStruct[] tests = (ParserRollTestStruct[]){
		{.s="foo", .err = roll::UNEXPECTED_TOKEN},
		{.s="dX", .err = roll::UNKNOWN_DIE},
		{.s="d4--", .err = roll::UNEXPECTED_TOKEN},
		{.s="3d4d5", .err = roll::UNEXPECTED_TOKEN},
	};

	foreach(idx, test : tests){
		@pool(){
			ByteReader br;
			br.init(test.s);
			Parser* parser = roll::newParser(&br, tmem);
			Roll? roll = parser.parse();
			if(catch e = roll){
				assert(e == test.err, "%d. Parser error, Got %s, Expected %s", idx, e, test.err);
			}else {
				assert(false, "%d. Roll didn't return an error. Result: %s",idx, roll);
			}
        };
    }
}