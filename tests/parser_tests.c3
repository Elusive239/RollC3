module roll::tests;
import std::math::random;
import std::io;

struct ParserRollTestStruct{
    String s;
    Roll roll;
    String err;
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
		// {
		// 	.s= `4d6kh3`,
		// 	.roll= &&(DiceRoll){
		// 		.multiplier= 4,
		// 		.die= &&(NormalDie)(6),
		// 		.limit= &&LimitOp{
		// 			.type= roll::KEEP_HIGHEST,
		// 			.amount= 3,
		// 		},
		// 	},
		// },

		// // Multi-roll, compounded on 5s, keep top 3, sort descending, +3
		// {
		// 	.s= `6d6!!5kh3sd+3`,
		// 	.roll= &&(DiceRoll){
		// 		.multiplier= 6,
		// 		.die=        &&(NormalDie)(6),
		// 		.modifier=   3,
		// 		.sort=       roll::DESCENDING,
		// 		.limit= &&LimitOp{
		// 			.type=   roll::KEEP_HIGHEST,
		// 			.amount= 3,
		// 		},
		// 		.exploding= &&ExplodingOp{
		// 			.type= roll::COMPOUNDED,
		// 			.comparison_op= &&ComparisonOp{
		// 				.type=  roll::EQUALS,
		// 				.value= 5,
		// 			},
		// 		},
		// 	},
		// },

		// // Multi-roll, reroll 2s, reroll once on 4s, successes > 3, failures on 1s
		// {
		// 	.s= `6d6r2ro4>3f=1`,
		// 	.roll= &&(DiceRoll){
		// 		.multiplier= 6,
		// 		.die=        &&(NormalDie)(6),
		// 		.rerolls= RerollOp[]{
		// 			RerollOp{
		// 				.comparison_op= &&ComparisonOp{
		// 					.type=  roll::EQUALS,
		// 					.value= 2,
		// 				},
		// 			},
		// 			RerollOp{
		// 				.comparison_op= &&ComparisonOp{
		// 					.type=  roll::EQUALS,
		// 					.value= 4,
		// 				},
		// 				.once= true,
		// 			},
		// 		},
		// 		.success= &&ComparisonOp{
		// 			.type=  roll::GREATER_THAN,
		// 			.value= 3,
		// 		},
		// 		.failure= &&ComparisonOp{
		// 			.type=  roll::EQUALS,
		// 			.value= 1,
		// 		},
		// 	},
		// },
    };

    foreach(idx, test : tests){
		if(catch (roll::END_OF_ROLL?)){
			String tmp =  test.roll.to_string(tmem);
			defer tmp.free(tmem);
			io::printfn("From Test: %s",tmp );
			continue;			
		}
        ByteReader br;
        br.init(test.s);
		@pool(){
			Parser* parser = roll::newParser(&br);
			// defer mem::free(parser.s);
			// defer roll.free();
			Roll? roll = parser.parse();
			if(catch e = roll){
				// continue;
				assert(e == roll::END_OF_ROLL, "%d. Parser error, %s", idx, e);
			}
			if(try roll) {
				// assert(test.roll.multiplier == roll.multiplier, "%d. Multiplier not equal. Got %d Expected %d", idx, test.roll.multiplier, roll.multiplier);
				// assert(test.roll.die == roll.die, "%d. Die not equal. Got: %s Expected: %s", idx, test.roll.to_string(allocator::temp()), roll.die.to_string(allocator::temp()));
				// assert(test.roll.modifier == roll.modifier, "%d. Modifier not equal. Got %d Expected %d", idx, test.roll.modifier, roll.modifier);
				// assert(test.roll.multiplier == roll.multiplier, "%d. Multiplier not equal.", idx);
				// assert(test.roll.typeid == roll.typeid, "%d. Die type not equal.", idx, test.roll.typeid, roll.typeid);
				// io::printfn("Get: %s"   ,  roll);
				// assert(test.roll == roll, "%d. Not equal. Got %s Expected %s", idx , test.roll.to_string(allocator::heap()), roll.to_string(allocator::heap()));
			}
        };
    }
}