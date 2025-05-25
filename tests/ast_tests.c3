module roll::tests;
import std::io;
import std::math::random;

struct DiceRollRollTestStruct{
    long            seed;
	Die             die ;
	int             mux ;
	int             mod ;
	ExplodingOp*    exp ;
	LimitOp*        lmt ;
	ComparisonOp*   succ;
	ComparisonOp*   fail;
	RerollOp[]      roll;
	SortType        sort;
	int[]           res ;
	int             scnt;
	int             totl;
}

// // Ensure the dice roll statement can get results correctly
fn void test_dice_roll_roll () @test {	

	DiceRollRollTestStruct[] tests = (DiceRollRollTestStruct[]){
		//0. Fate rolls
		{.seed = 0, .die = &&((FateDie)(0)), .mux = 4, .mod = 2, .res = (int[]){-1, 0, -1, -1}, .totl = -1},

		//1. Normal Die (3)
		{.seed = 1, .die = &&((NormalDie)(3)), .mux = 3, .mod = 8, .res = (int[]){3, 2, 1}, .totl = 14},

		//2. Normal Die (6)
		{.seed = 2, .die = &&((NormalDie)(6)), .mux = 2, .mod = -2, .res = (int[]){2, 4}, .totl = 4},

		//3. Exploding Die (6) on 5s
		{
			.seed = 20,
			.die =  &&((NormalDie)(6)),
			.mux =  2,
			.exp = &&(ExplodingOp){
				.type = roll::EXPLODING,
				.comparison_op = &&(ComparisonOp){
					.type =  roll::EQUALS,
					.value = 5,
				},
			},
			.res =  (int[]){5, 1, 1},
			.totl = 7,
		},

		//4. Exploding Die (6) on >1s
		{
			.seed = 1,
			.die =  &&((NormalDie)(6)),
			.mux =  2,
			.exp = &&(ExplodingOp){
				.type = roll::EXPLODING,
				.comparison_op = &&(ComparisonOp){
					.type =  roll::GREATER_THAN,
					.value = 1,
				},
			},
			.res =  (int[]){3, 2, 5, 6, 3, 3, 5, 5, 2, 4, 2, 1, 1},
			.totl = 42,
		},

		//5. Exploding Die (6) on <2s
		{
			.seed = 20,
			.die =  &&((NormalDie)(6)),
			.mux =  2,
			.exp = &&(ExplodingOp){
				.type = roll::EXPLODING,
				.comparison_op = &&(ComparisonOp){
					.type =  roll::LESS_THAN,
					.value = 2,
				},
			},
			.res =  (int[]){5, 1, 1, 3},
			.totl = 10,
		},

		//6. Compounded Die (6) on 5s
		{
			.seed = 2,
			.die =  &&((NormalDie)(6)),
			.mux =  2,
			.exp = &&(ExplodingOp){
				.type = roll::COMPOUNDED,
				.comparison_op = &&(ComparisonOp){
					.type =  roll::EQUALS,
					.value = 5,
				},
			},
			.res =  (int[]){2, 4, 0},
			.totl = 6,
		},

		//7. Compounded Die (6) on >1s
		{
			.seed = 1,
			.die =  &&((NormalDie)(6)),
			.mux =  2,
			.exp = &&(ExplodingOp){
				.type = roll::COMPOUNDED,
				.comparison_op = &&(ComparisonOp){
					.type =  roll::GREATER_THAN,
					.value = 1,
				},
			},
			.res =  (int[]){3, 2 , 37},
			.totl = 42,
		},

		//8. Compounded Die (6) on <2s
		{
			.seed = 10,
			.die =  &&((NormalDie)(6)),
			.mux =  2,
			.exp = &&(ExplodingOp){
				.type = roll::COMPOUNDED,
				.comparison_op = &&(ComparisonOp){
					.type =  roll::LESS_THAN,
					.value = 2,
				},
			},
			.res =  (int[]){6, 1, 5},
			.totl = 12,
		},

		//9. Penetrating Die (6) on 5s
		{
			.seed = 60,
			.die =  &&((NormalDie)(6)),
			.mux =  2,
			.exp = &&(ExplodingOp){
				.type = roll::PENETRATING,
				.comparison_op = &&(ComparisonOp){
					.type =  roll::EQUALS,
					.value = 5,
				},
			},
			.res =  (int[]){5, 4, 1},
			.totl = 10,
		},

		//10. Penetrating Die (6) on >1s
		{
			.seed = 1,
			.die =  &&((NormalDie)(6)),
			.mux =  2,
			.exp = &&(ExplodingOp){
				.type = roll::PENETRATING,
				.comparison_op = &&(ComparisonOp){
					.type =  roll::GREATER_THAN,
					.value = 1,
				},
			},
			.res =  (int[]){3, 2, 4, 5, 2, 2, 4, 4, 1, 3, 1, 0, 0},
			.totl = 31,
		},

		//11. Penetrating Die (6) on <2s
		{
			.seed = 12,
			.die =  &&((NormalDie)(6)),
			.mux =  2,
			.exp = &&(ExplodingOp){
				.type = roll::PENETRATING,
				.comparison_op = &&(ComparisonOp){
					.type =  roll::LESS_THAN,
					.value = 2,
				},
			},
			.res =  (int[]){6, 1, 0, 0, 4},
			.totl = 11,
		},

		//12. Limit (6) to the highest 3
		{
			.seed = 2,
			.die =  &&((NormalDie)(6)),
			.mux =  4,
			.lmt = &&(LimitOp){
				.type =   roll::KEEP_HIGHEST,
				.amount = 3,
			},
			.res =  (int[]){4},
			.totl = 4,
		},

		//12. Limit (6) to the lowest 3
		{
			.seed = 2,
			.die =  &&((NormalDie)(6)),
			.mux =  4,
			.lmt = &&(LimitOp){
				.type =   roll::KEEP_LOWEST,
				.amount = 3,
			},
			.res =  (int[]){2, 4, 1, 1},
			.totl = 8,
		},

		//13. Limit (6) and drop lowest 3
		{
			.seed = 2,
			.die =  &&((NormalDie)(6)),
			.mux =  4,
			.lmt = &&(LimitOp){
				.type =   roll::DROP_LOWEST,
				.amount = 3,
			},
			.res =  (int[]){2, 4, 1},
			.totl = 7,
		},

		//14. Limit (6) and drop highest 3
		{
			.seed = 2,
			.die =  &&((NormalDie)(6)),
			.mux =  4,
			.lmt = &&(LimitOp){
				.type =   roll::DROP_HIGHEST,
				.amount = 3,
			},
			.res =  (int[]){4},
			.totl = 4,
		},

		//15. Reroll (6) on a 1
		{
			.seed = 0,
			.die =  &&((NormalDie)(6)),
			.mux =  4,
			.roll = (RerollOp[]){
				(RerollOp){
					.comparison_op = &&(ComparisonOp){
						.type =  roll::EQUALS,
						.value = 1,
					},
					.once = false,
				},
			},
			.res =  (int[]){5, 6, 5, 5},
			.totl = 21,
		},

		// //16. Reroll (6) on values > 4
		// {
		// 	.seed = 0,
		// 	.die =  &&((NormalDie)(6)),
		// 	.mux =  4,
		// 	.roll = (RerollOp[]){
		// 		(RerollOp){
		// 			.comparison_op = &&(ComparisonOp){
		// 				.type =  roll::GREATER_THAN,
		// 				.value = 4,
		// 			},
		// 			.once = false,
		// 		},
		// 	},
		// 	.res =  (int[]){2, 1, 4, 1},
		// 	.totl = 8,
		// },

		//17. Reroll (6) on values < 3
		{
			.seed = 0,
			.die =  &&((NormalDie)(6)),
			.mux =  4,
			.roll = (RerollOp[]){
				(RerollOp){
					.comparison_op = &&(ComparisonOp){
						.type =  roll::LESS_THAN,
						.value = 3,
					},
					.once = false,
				},
			},
			.res =  (int[]){5, 6, 5, 5},
			.totl = 21,
		},

		// //18. Reroll (6) on values < 4, but once only
		// {
		// 	.seed = 2,
		// 	.die =  &&((NormalDie)(6)),
		// 	.mux =  4,
		// 	.roll = (RerollOp[]){
		// 		(RerollOp){
		// 			.comparison_op = &&(ComparisonOp){
		// 				.type =  roll::LESS_THAN,
		// 				.value = 4,
		// 			},
		// 			.once = true,
		// 		},
		// 	},
		// 	.res =  (int[]){6, 4, 4, 6}, 
		// 	.totl = 20,
		// },

		//19. Reroll (6) on 1s and 2s, but once only
		{
			.seed = 0,
			.die =  &&((NormalDie)(6)),
			.mux =  4,
			.roll = (RerollOp[]){
				(RerollOp){
					.comparison_op = &&(ComparisonOp){
						.type =  roll::EQUALS,
						.value = 1,
					},
					.once = true,
				},
				(RerollOp){
					.comparison_op = &&(ComparisonOp){
						.type =  roll::EQUALS,
						.value = 2,
					},
					.once = true,
				},
			},
			.res =  (int[]){5, 6, 5, 5},
			.totl = 21,
		},

		//20. Normal Die (3) sorted ascending
		{.seed = 1, .die = &&((NormalDie)(3)), .mux = 3, .res = (int[]){3, 2, 1}, .totl = 6, .sort = roll::ASCENDING},

		//21. Normal Die (3) sorted descending
		{.seed = 1, .die = &&((NormalDie)(3)), .mux = 3, .res = (int[]){1, 2, 3}, .totl = 6, .sort = roll::DESCENDING},

		//22. Normal Die (6) successes on 6s
		{
			.seed = 5,
			.die =  &&((NormalDie)(6)),
			.mux =  3,
			.res =  (int[]){6, 2, 1},
			.totl = 1,
			.succ = &&(ComparisonOp){
				.type =  roll::EQUALS,
				.value = 6,
			},
			.scnt = 1,
		},

		//23. Normal Die (6) successes on <5
		{
			.seed = 1,
			.die =  &&((NormalDie)(6)),
			.mux =  3,
			.res =  (int[]){3, 2, 5},
			.totl = 2,
			.succ = &&(ComparisonOp){
				.type =  roll::LESS_THAN,
				.value = 5,
			},
			.scnt = 2,
		},

		//24. Normal Die (6) successes on >3
		{
			.seed = 1,
			.die =  &&((NormalDie)(6)),
			.mux =  3,
			.res =  (int[]){3, 2, 5},
			.totl = 1,
			.succ = &&(ComparisonOp){
				.type =  roll::GREATER_THAN,
				.value = 3,
			},
			.scnt = 1,
		},

		//25. Normal Die (6) successes on 6s, failures on 4s
		{
			.seed = 12,
			.die =  &&((NormalDie)(6)),
			.mux =  3,
			.res =  (int[]){6, 1, 1},
			.totl = 1,
			.succ = &&(ComparisonOp){
				.type =  roll::EQUALS,
				.value = 6,
			},
			.fail = &&(ComparisonOp){
				.type =  roll::EQUALS,
				.value = 4,
			},
			.scnt = 1,
		},

		//26. Normal Die (6) successes on <5, failures on >5
		{
			.seed = 1,
			.die =  &&((NormalDie)(6)),
			.mux =  3,
			.res =  (int[]){3,2 , 5},
			.totl = 2,
			.succ = &&(ComparisonOp){
				.type =  roll::LESS_THAN,
				.value = 5,
			},
			.fail = &&(ComparisonOp){
				.type =  roll::GREATER_THAN,
				.value = 5,
			},
			.scnt = 2,
		},

		//27. Normal Die (6) successes on >4, failures <5
		{
			.seed = 1,
			.die =  &&((NormalDie)(6)),
			.mux =  3,
			.res =  (int[]){3, 2, 5},
			.totl = -1,
			.succ = &&(ComparisonOp){
				.type =  roll::GREATER_THAN,
				.value = 4,
			},
			.fail = &&(ComparisonOp){
				.type =  roll::LESS_THAN,
				.value = 5,
			},
			.scnt = -1,
		},

		//28. Normal Die (6) successes on =1, failures =2
		{
			.seed = 1,
			.die =  &&((NormalDie)(6)),
			.mux =  3,
			.res =  (int[]){3, 2, 5},
			.totl = -1,
			.succ = &&(ComparisonOp){
				.type =  roll::EQUALS,
				.value = 1,
			},
			.fail = &&(ComparisonOp){
				.type =  roll::EQUALS,
				.value = 2,
			},
			.scnt = -1,
		},
	};

	foreach (i, tt : tests) {
		random::srand(tt.seed);
		DiceRoll* stmt = &&(DiceRoll){
			.multiplier = tt.mux,
			.die =        tt.die,
			.modifier =   tt.mod,
			.exploding =  tt.exp,
			.limit =      tt.lmt,
			.success =    tt.succ,
			.failure =    tt.fail,
			.rerolls =   tt.roll,
			.sort =      tt.sort,
		};
		Result rolls = stmt.roll();
		defer rolls.free();
		assert(tt.res.len ==  rolls.results.len(), "%d. result count mismatch: exp=%d got=%d",i, tt.res.len, rolls.results.len());
        int[] results = mem::new_array(int, tt.res.len);
        defer mem::free(results);

		foreach (id, v : rolls.results) {
			results[id] = v.result;
		}

        for(int id = 0; id < tt.res.len; id++) assert(tt.res[id] == results[id], "%d|%d. result mismatch: exp=%s got=%s", i,id, tt.res, results);

		assert(tt.scnt == rolls.successes, "%d. successes mismatch: exp=%s got=%s", i, tt.scnt, rolls.successes);

        assert(tt.totl == rolls.total, "%d. total mismatch: exp=%s got=%s", i, tt.totl, rolls.total);
	}
}

struct DiceRollStringTestStruct{
    long                seed;
    Die                 die ;
    int                 mux ;
    int                 mod ;
    ExplodingOp*        exp ;
    LimitOp*            lmt ;
    ComparisonOp*       succ;
    ComparisonOp*       fail;
    RerollOp[]          roll;
    SortType            sort;
    String              res ;
}

// // Ensure the dice roll statement can be represented as a string
fn void test_dice_roll_string() @test {
	DiceRollStringTestStruct[] tests = (DiceRollStringTestStruct[]){
		// Fate rolls
		{.seed = 0, .die = &&((FateDie)(0)), .mux = 4, .mod = 2, .res = `+4dF+2`},

		// Normal Die (3)
		{.seed = 1, .die = &&((NormalDie)(3)), .mux = 3, .mod = 8, .res = `+3d3+8`},

		// Normal Die (6)
		{.seed = 2, .die = &&((NormalDie)(6)), .mux = 2, .mod = -2, .res = `+2d6-2`},

		// Normal Die (6), no modifier
		{.seed = 2, .die = &&((NormalDie)(6)), .mux = 2, .mod = 0, .res = `+2d6`},

		// Normal Die (20), no multiplier
		{.seed = 2, .die = &&((NormalDie)(20)), .mux = 1, .mod = 2, .res = `+d20+2`},

		// Normal Die (20), negative 1x multiplier
		{.seed = 2, .die = &&((NormalDie)(20)), .mux = -1, .mod = 2, .res = `-d20+2`},

		// Normal Die (6), negative multiplier
		{.seed = 2, .die = &&((NormalDie)(6)), .mux = -2, .mod = -2, .res = `-2d6-2`},

		// Exploding Die (6) on 5s
		{
			.die = &&((NormalDie)(6)),
			.mux = 2,
			.exp = &&(ExplodingOp){
				.type = roll::EXPLODING,
				.comparison_op = &&(ComparisonOp){
					.type =  roll::EQUALS,
					.value = 5,
				},
			},
			.res = "+2d6!5",
		},

		// Exploding Die (6) on >1s
		{
			.die = &&((NormalDie)(6)),
			.mux = 2,
			.exp = &&(ExplodingOp){
				.type = roll::EXPLODING,
				.comparison_op = &&(ComparisonOp){
					.type =  roll::GREATER_THAN,
					.value = 1,
				},
			},
			.res = "+2d6!>1",
		},

		// Exploding Die (6) on <2s
		{
			.die = &&((NormalDie)(6)),
			.mux = 2,
			.exp = &&(ExplodingOp){
				.type = roll::EXPLODING,
				.comparison_op = &&(ComparisonOp){
					.type =  roll::LESS_THAN,
					.value = 2,
				},
			},
			.res = "+2d6!<2",
		},

		// Compounded Die (6) on 5s
		{
			.die = &&((NormalDie)(6)),
			.mux = 2,
			.exp = &&(ExplodingOp){
				.type = roll::COMPOUNDED,
				.comparison_op = &&(ComparisonOp){
					.type =  roll::EQUALS,
					.value = 5,
				},
			},
			.res = "+2d6!!5",
		},

		// Compounded Die (6) on >1s
		{
			.die = &&((NormalDie)(6)),
			.mux = 2,
			.exp = &&(ExplodingOp){
				.type = roll::COMPOUNDED,
				.comparison_op = &&(ComparisonOp){
					.type =  roll::GREATER_THAN,
					.value = 1,
				},
			},
			.res = "+2d6!!>1",
		},

		// Compounded Die (6) on <2s
		{
			.die = &&((NormalDie)(6)),
			.mux = 2,
			.exp = &&(ExplodingOp){
				.type = roll::COMPOUNDED,
				.comparison_op = &&(ComparisonOp){
					.type =  roll::LESS_THAN,
					.value = 2,
				},
			},
			.res = "+2d6!!<2",
		},

		// Penetrating Die (6) on 5s
		{
			.die = &&((NormalDie)(6)),
			.mux = 2,
			.exp = &&(ExplodingOp){
				.type = roll::PENETRATING,
				.comparison_op = &&(ComparisonOp){
					.type =  roll::EQUALS,
					.value = 5,
				},
			},
			.res = "+2d6!p5",
		},

		// Penetrating Die (6) on >1s
		{
			.die = &&((NormalDie)(6)),
			.mux = 2,
			.exp = &&(ExplodingOp){
				.type = roll::PENETRATING,
				.comparison_op = &&(ComparisonOp){
					.type =  roll::GREATER_THAN,
					.value = 1,
				},
			},
			.res = "+2d6!p>1",
		},

		// Penetrating Die (6) on <2s
		{
			.die = &&((NormalDie)(6)),
			.mux = 2,
			.exp = &&(ExplodingOp){
				.type = roll::PENETRATING,
				.comparison_op = &&(ComparisonOp){
					.type =  roll::LESS_THAN,
					.value = 2,
				},
			},
			.res = "+2d6!p<2",
		},

		// Limit (6) to the highest 3
		{
			.seed = 2,
			.die =  &&((NormalDie)(6)),
			.mux =  4,
			.lmt = &&(LimitOp){
				.type =   roll::KEEP_HIGHEST,
				.amount = 3,
			},
			.res = "+4d6kh3",
		},

		// Limit (6) to the lowest 3
		{
			.die = &&((NormalDie)(6)),
			.mux = 4,
			.lmt = &&(LimitOp){
				.type =   roll::KEEP_LOWEST,
				.amount = 3,
			},
			.res = "+4d6kl3",
		},

		// Limit (6) and drop lowest 3
		{
			.die = &&((NormalDie)(6)),
			.mux = 4,
			.lmt = &&(LimitOp){
				.type =   roll::DROP_LOWEST,
				.amount = 3,
			},
			.res = "+4d6dl3",
		},

		// Limit (6) and drop highest 3
		{
			.die = &&((NormalDie)(6)),
			.mux = 4,
			.lmt = &&(LimitOp){
				.type =   roll::DROP_HIGHEST,
				.amount = 3,
			},
			.res = "+4d6dh3",
		},

		// Reroll (6) on a 1
		{
			.die = &&((NormalDie)(6)),
			.mux = 4,
			.roll = (RerollOp[]){
				(RerollOp){
					.comparison_op = &&(ComparisonOp){
						.type =  roll::EQUALS,
						.value = 1,
					},
					.once = false,
				},
			},
			.res = "+4d6r1",
		},

		// Reroll (6) on values > 4
		{
			.die = &&((NormalDie)(6)),
			.mux = 4,
			.roll = (RerollOp[]){
				(RerollOp){
					.comparison_op = &&(ComparisonOp){
						.type =  roll::GREATER_THAN,
						.value = 4,
					},
					.once = false,
				},
			},
			.res = "+4d6r>4",
		},

		// Reroll (6) on values < 3
		{
			.die = &&((NormalDie)(6)),
			.mux = 4,
			.roll = (RerollOp[]){
				(RerollOp){
					.comparison_op = &&(ComparisonOp){
						.type =  roll::LESS_THAN,
						.value = 3,
					},
					.once = false,
				},
			},
			.res = "+4d6r<3",
		},

		// Reroll (6) on values < 4, but once only
		{
			.die = &&((NormalDie)(6)),
			.mux = 4,
			.roll = (RerollOp[]){
				(RerollOp){
					.comparison_op = &&(ComparisonOp){
						.type =  roll::LESS_THAN,
						.value = 4,
					},
					.once = true,
				},
			},
			.res = "+4d6ro<4",
		},

		// Reroll (6) on 1s and 2s, but once only
		{
			.die = &&((NormalDie)(6)),
			.mux = 4,
			.roll = (RerollOp[]){
				(RerollOp){
					.comparison_op = &&(ComparisonOp){
						.type =  roll::EQUALS,
						.value = 1,
					},
					.once = true,
				},
				(RerollOp){
					.comparison_op = &&(ComparisonOp){
						.type =  roll::EQUALS,
						.value = 2,
					},
					.once = true,
				},
			},
			.res = "+4d6ro1ro2",
		},

		// Normal Die (3) sorted ascending
		{.die = &&((NormalDie)(3)), .mux = 3, .res = "+3d3s", .sort = roll::ASCENDING},

		// Normal Die (3) sorted descending
		{.die = &&((NormalDie)(3)), .mux = 3, .res = "+3d3sd", .sort = roll::DESCENDING},

		// Normal Die (6) successes on 6s
		{
			.die = &&((NormalDie)(6)),
			.mux = 3,
			.res = "+3d6=6",
			.succ = &&(ComparisonOp){
				.type =  roll::EQUALS,
				.value = 6,
			},
		},

		// Normal Die (6) successes on <5
		{
			.die = &&((NormalDie)(6)),
			.mux = 3,
			.res = "+3d6<5",
			.succ = &&(ComparisonOp){
				.type =  roll::LESS_THAN,
				.value = 5,
			},
		},

		// Normal Die (6) successes on >3
		{
			.die = &&((NormalDie)(6)),
			.mux = 3,
			.res = "+3d6>3",
			.succ = &&(ComparisonOp){
				.type =  roll::GREATER_THAN,
				.value = 3,
			},
		},

		// Normal Die (6) successes on 6s, failures on 4s
		{
			.die = &&((NormalDie)(6)),
			.mux = 3,
			.res = "+3d6=6f=4",
			.succ = &&(ComparisonOp){
				.type =  roll::EQUALS,
				.value = 6,
			},
			.fail = &&(ComparisonOp){
				.type =  roll::EQUALS,
				.value = 4,
			},
		},

		// Normal Die (6) successes on <5, failures on >5
		{
			.die = &&((NormalDie)(6)),
			.mux = 3,
			.res = "+3d6<5f>5",
			.succ = &&(ComparisonOp){
				.type =  roll::LESS_THAN,
				.value = 5,
			},
			.fail = &&(ComparisonOp){
				.type =  roll::GREATER_THAN,
				.value = 5,
			},
		},

		// Normal Die (6) successes on >4, failures <5
		{
			.die = &&((NormalDie)(6)),
			.mux = 3,
			.res = "+3d6>4f<5",
			.succ = &&(ComparisonOp){
				.type =  roll::GREATER_THAN,
				.value = 4,
			},
			.fail = &&(ComparisonOp){
				.type =  roll::LESS_THAN,
				.value = 5,
			},
		},
	};

	foreach (i, tt : tests) {
		random::srand(tt.seed);
		DiceRoll* stmt = &&(DiceRoll){
			.multiplier = tt.mux,
			.die =        tt.die,
			.modifier =   tt.mod,
			.exploding =  tt.exp,
			.rerolls =   tt.roll,
			.success =    tt.succ,
			.failure =    tt.fail,
			.sort =      tt.sort,
			.limit =      tt.lmt,
		};
        String str = stmt.to_string(mem);
        defer str.free(mem);
        assert(str == tt.res, "%d. result mismatch: exp=%s got=%s", i, tt.res, str);
	}
}

// // Ensure the group dice roll statement can get results correctly

struct GroupedRollRollTestStruct {
    long           seed;
	Roll[]          rolls;
    int             mod ;
    LimitOp*        lmit;
    ComparisonOp*   succ;
    ComparisonOp*   fail;
    bool            comb;
    int[]           res ;
    int             scnt;
	int             totl;
}


fn void test_group_roll_roll () @test {
	GroupedRollRollTestStruct[] tests = (GroupedRollRollTestStruct[]){
		// Single roll
		{
			.seed = 0,
			.rolls = ((Roll[])){
				&&(DiceRoll){
					.multiplier = 3,
					.die =        &&((NormalDie)(6)),
					.modifier =   4,
				},
			},
			.mod =  2,
			.res =  ((int[])){20},
			.totl = 22,
		},
		// Combined single roll
		{
			.seed = 0,
			.rolls = ((Roll[])){
				&&(DiceRoll){
					.multiplier = 3,
					.die =        &&((NormalDie)(6)),
					.modifier =   4,
				},
			},
			.mod =  2,
			.res =  (int[]){9, 10, 9},
			.totl = 30,
			.comb = true,
		},
		// Combined multi-roll
		{
			.seed = 0,
			.rolls = (Roll[]){
				&&(DiceRoll){
					.multiplier = 3,
					.die =        &&((NormalDie)(6)),
					.modifier =   4,
				},
				&&(DiceRoll){
					.multiplier = 2,
					.die =        &&((NormalDie)(4)),
					.modifier =   0,
				},
			},
			.mod =  0,
			.res =  (int[]){9, 10, 9, 1, 2},
			.totl = 31,
			.comb = true,
		},
		// Multi-roll with limit
		{
			.seed = 0,
			.rolls = (Roll[]){
				&&(DiceRoll){
					.multiplier = 3,
					.die =        &&((NormalDie)(6)),
					.modifier =   4,
				},
				&&(DiceRoll){
					.multiplier = 1,
					.die =        &&((NormalDie)(4)),
					.modifier =   0,
				},
				&&(DiceRoll){
					.multiplier = 2,
					.die =        &&((NormalDie)(8)),
					.modifier =   10,
				},
			},
			.mod =  2,
			.res =  (int[]){20, 13},
			.totl = 35,
			.lmit = &&(LimitOp){
				.type =   roll::KEEP_HIGHEST,
				.amount = 1,
			},
		},
		// Multi-roll combined with limit
		{
			.seed = 0,
			.rolls = (Roll[]){
				&&(DiceRoll){
					.multiplier = 3,
					.die =        &&((NormalDie)(6)),
					.modifier =   4,
				},
				&&(DiceRoll){
					.multiplier = 1,
					.die =        &&((NormalDie)(4)),
					.modifier =   0,
				},
				&&(DiceRoll){
					.multiplier = 2,
					.die =        &&((NormalDie)(8)),
					.modifier =   10,
				},
			},
			.mod =  2,
			.res =  (int[]){12, 11},
			.totl = 25,
			.comb = true,
			.lmit = &&(LimitOp){
				.type =   roll::KEEP_HIGHEST,
				.amount = 4,
			},
		},
		// Multi-roll with succ/fail
		{
			.seed = 0,
			.rolls = (Roll[]){
				&&(DiceRoll){
					.multiplier = 3,
					.die =        &&((NormalDie)(6)),
					.modifier =   4,
				},
				&&(DiceRoll){
					.multiplier = 1,
					.die =        &&((NormalDie)(4)),
					.modifier =   0,
				},
				&&(DiceRoll){
					.multiplier = 2,
					.die =        &&((NormalDie)(8)),
					.modifier =   10,
				},
			},
			.mod =  0,
			.res =  (int[]){20, 1, 13},
			.totl = 2,
			.succ = &&((ComparisonOp)){
				.type =  roll::GREATER_THAN,
				.value = 6,
			},
			.fail = &&((ComparisonOp)){
				.type =  roll::EQUALS,
				.value = 3,
			},
			.scnt = 2,
		},
		// Multi-roll combined with succ/fail
		{
			.seed = 0,
			.rolls = (Roll[]){
				&&(DiceRoll){
					.multiplier = 3,
					.die =        &&((NormalDie)(6)),
					.modifier =   4,
				},
				&&(DiceRoll){
					.multiplier = 1,
					.die =        &&((NormalDie)(4)),
					.modifier =   0,
				},
				&&(DiceRoll){
					.multiplier = 2,
					.die =        &&((NormalDie)(8)),
					.modifier =   10,
				},
			},
			.mod =  0,
			.res =  (int[]){9, 10, 9, 1, 12, 11},
			.totl = 5,
			.comb = true,
			.succ = &&((ComparisonOp)){
				.type =  roll::GREATER_THAN,
				.value = 6,
			},
			.fail = &&((ComparisonOp)){
				.type =  roll::EQUALS,
				.value = 3,
			},
			.scnt = 5,
		}
	};

	foreach (i, tt : tests) {
		random::srand(tt.seed);
		GroupedRoll* stmt = &&(GroupedRoll){
			.rolls =    tt.rolls,
			.modifier = tt.mod,
			.limit =    tt.lmit,
			.success =  tt.succ,
			.failure =  tt.fail,
			.combined = tt.comb,
		};
		Result rolls = stmt.roll();
        defer rolls.free();
        int[] results = mem::new_array(int, rolls.results.len());
        defer mem::free(results);

		foreach (id, v : rolls.results) {
			results[id] = v.result;
		}
        assert(tt.res.len == results.len);
        for(int id = 0; id < tt.res.len; id++) assert(tt.res[id] == results[id], "%d|%d. result mismatch: exp=%s got=%s", i,id, tt.res, results);

		assert(tt.scnt == rolls.successes, "%d. successes mismatch: exp=%s got=%s", i, tt.scnt, rolls.successes);

        assert(tt.totl == rolls.total, "%d. total mismatch: exp=%s got=%s", i, tt.totl, rolls.total);
	}
}

struct GroupedRollStringTestStruct {
    long           seed;
	Roll[]          rolls;
    int             mod ;
    LimitOp*        lmit;
    ComparisonOp*   succ;
    ComparisonOp*   fail;
    bool            comb;
    String          res ;
}


// Ensure the group dice roll statement string representation is correct
fn void test_group_roll_string() @test {
	GroupedRollStringTestStruct[] tests = (GroupedRollStringTestStruct[]) {
		// Single roll
		{
			.seed = 0,
			.rolls = ((Roll[])){
				&&(DiceRoll){
					.multiplier = 3,
					.die =        &&((NormalDie)(6)),
					.modifier =   4,
				},
			},
			.mod = 2,
			.res = "{3d6+4,}+2",
		},
		// Combined single roll
		{
			.seed = 0,
			.rolls = ((Roll[])){
				&&(DiceRoll){
					.multiplier = 3,
					.die =        &&((NormalDie)(6)),
					.modifier =   4,
				},
			},
			.mod =  2,
			.res =  "{3d6+4}+2",
			.comb = true,
		},
		// Combined multi-roll
		{
			.seed = 0,
			.rolls = ((Roll[])){
				&&(DiceRoll){
					.multiplier = 3,
					.die =        &&((NormalDie)(6)),
					.modifier =   4,
				},
				&&(DiceRoll){
					.multiplier = 2,
					.die =        &&((NormalDie)(4)),
					.modifier =   0,
				},
			},
			.mod =  0,
			.res =  "{3d6+4 + 2d4}",
			.comb = true,
		},
		// Multi-roll with limit
		{
			.seed = 0,
			.rolls = ((Roll[])){
				&&(DiceRoll){
					.multiplier = 3,
					.die =        &&((NormalDie)(6)),
					.modifier =   4,
				},
				&&(DiceRoll){
					.multiplier = 1,
					.die =        &&((NormalDie)(4)),
					.modifier =   0,
				},
				&&(DiceRoll){
					.multiplier = 2,
					.die =        &&((NormalDie)(8)),
					.modifier =   10,
				},
			},
			.mod = 2,
			.res = "{3d6+4, d4, 2d8+10}kh+2",
			.lmit = &&(LimitOp){
				.type =   roll::KEEP_HIGHEST,
				.amount = 1,
			},
		},
		// Multi-roll combined with limit
		{
			.seed = 0,
			.rolls = ((Roll[])){
				&&(DiceRoll){
					.multiplier = 3,
					.die =        &&((NormalDie)(6)),
					.modifier =   4,
				},
				&&(DiceRoll){
					.multiplier = 1,
					.die =        &&((NormalDie)(4)),
					.modifier =   0,
				},
				&&(DiceRoll){
					.multiplier = 2,
					.die =        &&((NormalDie)(8)),
					.modifier =   10,
				},
			},
			.mod =  2,
			.res =  "{3d6+4 + d4 + 2d8+10}kh4+2",
			.comb = true,
			.lmit = &&(LimitOp){
				.type =   roll::KEEP_HIGHEST,
				.amount = 4,
			},
		},
		// Multi-roll with succ/fail
		{
			.seed = 0,
			.rolls = ((Roll[])){
				&&(DiceRoll){
					.multiplier = 3,
					.die =        &&((NormalDie)(6)),
					.modifier =   4,
				},
				&&(DiceRoll){
					.multiplier = 1,
					.die =        &&((NormalDie)(4)),
					.modifier =   0,
				},
				&&(DiceRoll){
					.multiplier = 2,
					.die =        &&((NormalDie)(8)),
					.modifier =   10,
				},
			},
			.mod = 0,
			.res = "{3d6+4, d4, 2d8+10}>6f=3",
			.succ = &&((ComparisonOp)){
				.type =  roll::GREATER_THAN,
				.value = 6,
			},
			.fail = &&((ComparisonOp)){
				.type =  roll::EQUALS,
				.value = 3,
			},
		},
		// Multi-roll combined with succ/fail
		{
			.seed = 0,
			.rolls = ((Roll[])){
				&&(DiceRoll){
					.multiplier = 3,
					.die =        &&((NormalDie)(6)),
					.modifier =   4,
				},
				&&(DiceRoll){
					.multiplier = 1,
					.die =        &&((NormalDie)(4)),
					.modifier =   0,
				},
				&&(DiceRoll){
					.multiplier = 2,
					.die =        &&((NormalDie)(8)),
					.modifier =   10,
				},
			},
			.mod =  0,
			.res =  "{3d6+4 + d4 + 2d8+10}>6f=3",
			.comb = true,
			.succ = &&((ComparisonOp)){
				.type =  roll::GREATER_THAN,
				.value = 6,
			},
			.fail = &&((ComparisonOp)){
				.type =  roll::EQUALS,
				.value = 3,
			},
		},
		// Nested grouped roll combined
		{
			.seed = 0,
			.rolls = ((Roll[])){
				&&(DiceRoll){
					.multiplier = 3,
					.die =        &&((NormalDie)(6)),
					.modifier =   4,
				},
				&&(GroupedRoll){
					.rolls = ((Roll[])){
						&&(DiceRoll){
							.multiplier = 3,
							.die =        &&((NormalDie)(6)),
							.modifier =   4,
						},
					},
				},
			},
			.mod =  2,
			.res =  "{3d6+4 + {3d6+4,}}+2",
			.comb = true,
		},
		// Nested grouped roll non-combined
		{
			.seed = 0,
			.rolls = ((Roll[])){
				&&(DiceRoll){
					.multiplier = 3,
					.die =        &&((NormalDie)(6)),
					.modifier =   4,
				},
				&&(GroupedRoll){
					.rolls = ((Roll[])){
						&&(DiceRoll){
							.multiplier = 3,
							.die =        &&((NormalDie)(6)),
							.modifier =   4,
						},
					},
				},
			},
			.mod = 2,
			.res = "{3d6+4, {3d6+4,}}+2",
		},
	};

	foreach (i, tt :  tests ) @pool() {
		random::srand(tt.seed);
		GroupedRoll* stmt = &&(GroupedRoll){
			.rolls =    tt.rolls,
			.modifier = tt.mod,
			.limit =    tt.lmit,
			.success =  tt.succ,
			.failure =  tt.fail,
			.combined = tt.comb,
		};
        String tmp = stmt.to_string(mem);
        defer tmp.free(mem);
        assert(tt.res == tmp, "%d. result mismatch: exp=%s got=%s", i, tt.res[0..], tmp);
		// if !reflect.DeepEqual(tt.res, stmt.String()) {
		// 	t.Errorf("%d. result mismatch: exp=%v got=%v", i, tt.res, stmt.String())
		// }
	};
}