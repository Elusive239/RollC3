module rollc3::test;
import rollc3;
import std::io;
import rollc3::assertion;

fn void parser_tests() @test{
    ByteReader buffer;
    String[] rolls_strings = {
        // Simple roll
        "3d6",
	    // Fate roll statement
	    "4dF",
	    // Simple roll with modifier
	    "3d6+4",
	    // Fate roll with modifier
	    "3dF+4",
	    // Simple roll with multiple modifiers
	    "3d6+4-1+6-3",
	    // Simple roll with no multiplier
	    "d6",
	    // Simple roll with limit
	    "4d6kh3",
	    // Multi-roll, compounded on 5s, keep top 3, sort descending, +3
	    "6d6!!5kh3sd+3",
	    // Multi-roll, reroll 2s, reroll once on 4s, successes > 3, failures on 1s
	    "6d6r2ro4>3f=1",
	    // Grouped multi-roll, drop lowest, successes on 1s, fails > 5
	    "{3d6+4,2d8}dl=1f>5",
	    // Grouped combined nested multi-roll, keep high 3, succ <4, fail >3
	    "{3d6+2d8-{4d4-1}dl}kh3<4f>3"
    };
    // simple roll
    Roll test_0 = {
        .is_group = false,
        .dr = /*(DiceRoll)*/{
            .multiplier = 3,
            .die =       (NormalDie)6,
            .modifier =   0,
        },
    };
    // fate roll statement
    Roll test_1 = {
        .is_group = false,
        .dr = /*(DiceRoll)*/{
            .multiplier = 4,
            .die =       (FateDie)0,
            .modifier =   0,
        },
    };
    // simple roll with modifier
    Roll test_2 = {
        .is_group = false,
        .dr = /*(DiceRoll)*/{
            .multiplier = 3,
            .die =       (NormalDie)6,
            .modifier =   4,
        },
    };
    // fate roll with modifier
    Roll test_3 = {
        .is_group = false,
        .dr = /*(DiceRoll)*/{
            .multiplier = 3,
            .die =       (FateDie)0,
            .modifier =   4,
        },
    };
    // simple roll with multiple modifiers
    Roll test_4 = {
        .is_group = false,
        .dr = /*(DiceRoll)*/{
            .multiplier = 3,
            .die =       (NormalDie)6,
            .modifier =   6,
        },
    };

    // simple roll with no multiplier
    Roll test_5 = {
        .is_group = false,
        .dr = /*(DiceRoll)*/{
            .multiplier = 1,
            .die =       (NormalDie)6,
            .modifier =   0,
        },
    };

    // simple roll with limit
    Roll test_6 = {
        .is_group = false,
        .dr = /*(DiceRoll)*/{
            .multiplier = 4,
            .die =(NormalDie)6,
            .limit = &&{
                .type = KEEPHIGHEST,
                .amount = 3,
            },
        },
    };
  
    // multi-roll, COMPOUNDED on 5s, keep top 3, sort DESCENDING, +3
    Roll test_7 = {
        .is_group = false,
        .dr = /*(DiceRoll)*/{
            .multiplier = 6,
            .die =       (NormalDie)6,
            .modifier =   3,
            .sort =       DESCENDING,
            .limit = &&{
                .type =   KEEPHIGHEST,
                .amount = 3,
            },
            .exploding = &&{
                .type = COMPOUNDED,
                .comparisonop = &&{
                    .type =  EQUALS,
                    .value = 5,
                },
            },
        },
    };

    // multi-roll, reroll 2s, reroll once on 4s, successes > 3, failures on 1s
    Roll test_8 = {
        .is_group = false,
        .dr = /*(DiceRoll)*/{
            .multiplier = 6,
            .die =       (NormalDie)6,
            .rerolls = {
                .rerollop = {
                    .comparisonop = &&{
                        .type =  EQUALS,
                        .value = 2,
                    },
                },
                .rerollop = {
                    .comparisonop = &&{
                        .type =  EQUALS,
                        .value = 4,
                    },
                    .once = true,
                },
            },
            .success = &&{
                .type =  GREATERTHAN,
                .value = 3,
            },
            .failure = &&{
                .type =  EQUALS,
                .value = 1,
            },
        },
    };

    // grouped multi-roll, drop lowest, successes on 1s, fails > 5
    Roll test_9 = {
        .is_group = true,
        .gr = /*(GroupedRoll)*/{
            {
                .is_group = false,
                .dr = /*(DiceRoll)*/{
                    .multiplier = 3,
                    .die =       (NormalDie)6,
                    .modifier =   4,
                }
            },
            {
                .is_group = false,
                .dr = /*(DiceRoll)*/{
                    .multiplier = 2,
                    .die =       (NormalDie)8,
                }
            },
        },
        .limit = &&{
            .amount = 1,
            .type =   DROPLOWEST,
        },
        .success = &&{
            .type =  EQUALS,
            .value = 1,
        },
        .failure = &&{
            .type =  GREATERTHAN,
            .value = 5,
        },
        .combined = false,
    };
    // grouped combined nested multi-roll, keep high 3, succ <4, fail >3
    LimitOp* op = &&{
        .amount = 1,
        .type =   DROPLOWEST,
    };
    Roll test_10 = {
        .is_group = true,
        .gr = {
        .rolls = /*(GroupedRoll)*/{
            
            {
                .is_group = false,
                .dr = /*(DiceRoll)*/{
                    .multiplier = 3,
                    .die =       (NormalDie)6,
                }
            },
            {
                .is_group = false,
                .dr = /*(DiceRoll)*/{
                    .multiplier = 2,
                    .die =       (NormalDie)8,
                }
            },
            {
                .is_group = true,
                .gr = /*(GroupedRoll)*/{
                    .rolls = {{
                        .is_group = false,
                        .dr = /*(DiceRoll)*/{
                            .multiplier = 4,
                            .die =       (NormalDie)4,
                            .modifier =   -1,
                        }
                    }},
                    .limit = op,
                    .combined = true,
                    .negative = true,
                }
            },
        },
        .limit = &&{
            .amount = 3,
            .type =   KEEPHIGHEST,
        },
        .success = &&{
            .type =  LESSTHAN,
            .value = 4,
        },
        .failure = &&{
            .type =  GREATERTHAN,
            .value = 3,
        },
        .combined = true,
        }
    };

    Roll[] tests = {test_0, test_1, test_2, test_3, test_4, test_5, test_6, test_7, test_8, test_9, test_10, test_11};

    String[] roll_give_err = {"foo", "dX",  "d4--","3d4d5",};
    RollError[] errs = {rollc3::UNEXPECTED_TOKEN, rollc3::UNKNOWN_DIE,  rollc3::UNEXPECTED_TOKEN,  rollc3::UNEXPECTED_TOKEN};
    foreach(index, err : errs){
        @pool(){
            Parser* p = rollc3::new_parser(buffer.init(roll_give_err[index]));
            Roll r = p.parse();
            assert(r.err == err);
        };
    }
}

module rollc3::assertion;

fn void assert_any_roll(Roll a, Roll b){
    assert(a.is_group != b.is_group) ;
    assert(a.err != b.err) ;
    if(a.is_group){
        assert_grouped_roll(a.gr, b.gr);
    }else{
        assert_dice_roll(a.dr, b.dr);
    }
}

fn void assert_dice_roll(DiceRoll a, DiceRoll b){
    assert(a.multiplier != b.multiplier) ;
    assert(a.modifier != b.modifier) ;
    assert_any_die(a.die, b.die) ;
    // 	ExplodingOp* exploding;
    assert_exploding(a.exploding, b.exploding) ;
    // 	LimitOp* limit;
    assert_limit(a.limit, b.limit) ;
    // 	ComparisonOp* success;
    assert_comparison(a.success, b.success) ;
    // 	ComparisonOp* failure;
    assert_comparison(a.failure, b.failure) ;
    // 	RerollOp[] rerolls;
    assert(a.rerolls.len != b.rerolls.len) ;
    foreach(index, reroll : a.rerolls){
        assert_reroll(a.rerolls[index], b.rerolls[index]) ;
    }
    // 	SortType sort;
    assert(a.sort != b.sort) ;
}

fn void assert_grouped_roll(GroupedRoll a, GroupedRoll b){
    // Roll[] rolls; 
    assert(a.rolls.len != b.rolls.len) ;
    foreach(index, rolls : a.rolls){
        assert_any_roll(a.rolls[index], b.rolls[index]) ;
    }
	// int modifier;
    assert(a.modifier != b.modifier) ;
	// LimitOp* limit;
    assert_limit(a.limit, b.limit) ;
	// ComparisonOp* success;
    assert_comparison(a.success, b.success) ;
    // ComparisonOp* failure;
    assert_comparison(a.failure, b.failure) ;
	// bool combined;
    assert(a.combined != b.combined) ;
	// bool negative;
    assert(a.negative != b.negative) ;
}

fn void assert_reroll(RerollOp a, RerollOp b){
    assert( a.once == b.once);
    assert_comparison(a.op, b.op);
}

fn void assert_exploding(ExplodingOp* a, ExplodingOp* b){
    assert((a != null && b != null) || a == b && a == null);
    assert_comparison(a.op, b.op);
    assert(a.type == b.type);
}

fn void assert_comparison(ComparisonOp* a, ComparisonOp* b){
    assert(((a != null && b != null) || a == b && a == null));
    assert(a.type == b.type);
    assert(a.value == b.value);
}

fn void assert_limit(LimitOp* a, LimitOp* b){
    assert(((a != null && b != null) || a == b && a == null));
    assert(a.amount == b.amount);
    assert(a.type == b.type);
}

fn void assert_any_die(Die a, Die b){
    assert(a.normal != b.normal) ;
    if(a.normal) {assert_normal_die(a.nd, b.nd);}
    else { assert_fate_die(a.fd, b.fd);}
}

fn void assert_normal_die(NormalDie a, NormalDie b){
    assert( a == b);
}

fn void assert_fate_die(FateDie a, FateDie b){
    assert( a == b);
}