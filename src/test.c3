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
            .die =       {.normal = true, .nd = (NormalDie)6},
            .modifier =   0,
        },
    };
    // fate roll statement
    Roll test_1 = {
        .is_group = false,
        .dr = /*(DiceRoll)*/{
            .multiplier = 4,
            .die =       {.normal = false, .fd = (FateDie)0},
            .modifier =   0,
        },
    };
    // simple roll with modifier
    Roll test_2 = {
        .is_group = false,
        .dr = /*(DiceRoll)*/{
            .multiplier = 3,
            .die =       {.normal = true, .nd = (NormalDie)6},
            .modifier =   4,
        },
    };
    // fate roll with modifier
    Roll test_3 = {
        .is_group = false,
        .dr = /*(DiceRoll)*/{
            .multiplier = 3,
            .die =       {.normal = false, .fd = (FateDie)0},
            .modifier =   4,
        },
    };
    // simple roll with multiple modifiers
    Roll test_4 = {
        .is_group = false,
        .dr = /*(DiceRoll)*/{
            .multiplier = 3,
            .die =       {.normal = true, .nd = (NormalDie)6},
            .modifier =   6,
        },
    };

    // simple roll with no multiplier
    Roll test_5 = {
        .is_group = false,
        .dr = /*(DiceRoll)*/{
            .multiplier = 1,
            .die =       {.normal = true, .nd = (NormalDie)6},
            .modifier =   0,
        },
    };

    // simple roll with limit
    Roll test_6 = {
        .is_group = false,
        .dr = /*(DiceRoll)*/{
            .multiplier = 4,
            .die =  {.normal = true, .nd =(NormalDie)6},
            .limit = new_limit(rollc3::KEEPHIGHEST, 3)
            ,
        },
    };
  
    // multi-roll, COMPOUNDED on 5s, keep top 3, sort DESCENDING, +3
    Roll test_7 = {
        .is_group = false,
        .dr = /*(DiceRoll)*/{
            .multiplier = 6,
            .die =       {.normal = true, .nd = (NormalDie)6},
            .modifier =   3,
            .sort =       rollc3::DESCENDING,
            .limit = new_limit(rollc3::KEEPHIGHEST, 3),
            .exploding = new_exploding(rollc3::COMPOUNDED, rollc3::KEEPHIGHEST, 5),
        },
    };

    // multi-roll, reroll 2s, reroll once on 4s, successes > 3, failures on 1s
    Roll test_8 = {
        .is_group = false,
        .dr = /*(DiceRoll)*/{
            .multiplier = 6,
            .die =       {.normal = true, .nd = (NormalDie)6},
            .rerolls = {
                new_reroll(false, rollc3::EQUALS, 2),
                new_reroll(true, rollc3::EQUALS, 4),
            },
            .success = new_comparison(rollc3::GREATERTHAN, 3),
            .failure =  new_comparison(rollc3::EQUALS, 1),
        },
    };

    // grouped multi-roll, drop lowest, successes on 1s, fails > 5
    Roll test_9 = {
        .is_group = true,
        .gr = /*(GroupedRoll)*/{
            .rolls = {
            {
                .is_group = false,
                .dr = /*(DiceRoll)*/{
                    .multiplier = 3,
                    .die =       {.normal = true, .nd = (NormalDie)6},
                    .modifier =   4,
                }
            },
            {
                .is_group = false,
                .dr = /*(DiceRoll)*/{
                    .multiplier = 2,
                    .die =       {.normal = true, .nd = (NormalDie)8},
                }
            }},
        .limit = new_limit(rollc3::DROPLOWEST, 1),
        .success = new_comparison(rollc3::EQUALS, 1),
        .failure = new_comparison(rollc3::GREATERTHAN, 5),
        .combined = false,
        },
    };
    // grouped combined nested multi-roll, keep high 3, succ <4, fail >3
    LimitOp op = {    .amount = 1,    .type =   rollc3::DROPLOWEST};
    Roll test_10 = {
        .is_group = true,
        .gr = {
        .rolls = /*(GroupedRoll)*/{
            
            {
                .is_group = false,
                .dr = /*(DiceRoll)*/{
                    .multiplier = 3,
                    .die =       {.normal = true, .nd = (NormalDie)6},
                }
            },
            {
                .is_group = false,
                .dr = /*(DiceRoll)*/{
                    .multiplier = 2,
                    .die =       {.normal = true, .nd = (NormalDie)8},
                }
            },
            {
                .is_group = true,
                .gr = /*(GroupedRoll)*/{
                    .rolls = {{
                        .is_group = false,
                        .dr = /*(DiceRoll)*/{
                            .multiplier = 4,
                            .die =       {.normal = true, .nd = (NormalDie)4},
                            .modifier =   -1,
                        }
                    }},
                    .limit = &op,
                    .combined = true,
                    .negative = true,
                }
            },
        },
        .limit = new_limit(rollc3::KEEPHIGHEST, 3)
        ,
        .success = new_comparison(rollc3::LESSTHAN, 4),
        .failure = new_comparison(rollc3::GREATERTHAN, 3),
        .combined = true,
        }
    };
    @pool(){
        Parser* p = rollc3::new_parser(buffer.init(rolls_strings[0]));
        assertion::assert_any_roll(test_0,p.parse());
        p = rollc3::new_parser(buffer.init(rolls_strings[1]));
        assertion::assert_any_roll(test_1,p.parse());
        p = rollc3::new_parser(buffer.init(rolls_strings[2]));
        assertion::assert_any_roll(test_2,p.parse());
        p = rollc3::new_parser(buffer.init(rolls_strings[3]));
        assertion::assert_any_roll(test_3,p.parse());
        p = rollc3::new_parser(buffer.init(rolls_strings[4]));
        assertion::assert_any_roll(test_4,p.parse());
        p = rollc3::new_parser(buffer.init(rolls_strings[5]));
        assertion::assert_any_roll(test_5,p.parse());
        p = rollc3::new_parser(buffer.init(rolls_strings[6]));
        assertion::assert_any_roll(test_6,p.parse());
        p = rollc3::new_parser(buffer.init(rolls_strings[7]));
        assertion::assert_any_roll(test_7,p.parse());
        p = rollc3::new_parser(buffer.init(rolls_strings[8]));
        assertion::assert_any_roll(test_8,p.parse());
        p = rollc3::new_parser(buffer.init(rolls_strings[9]));
        assertion::assert_any_roll(test_9,p.parse()) ;
        p = rollc3::new_parser(buffer.init(rolls_strings[10]));
        assertion::assert_any_roll(test_10,p.parse());
    };
}

fn void error_tests() @test{
    ByteReader buffer;
    String[] roll_give_err = {"foo", "dX",  "d4--","3d4d5",};
    RollError[] errs = {rollc3::UNEXPECTED_TOKEN, rollc3::UNKNOWN_DIE,  rollc3::UNEXPECTED_TOKEN,  rollc3::UNEXPECTED_TOKEN};
    foreach(index, err : errs){
        @pool(){
            Parser* p = rollc3::new_parser(buffer.init(roll_give_err[index]));
            Roll r = p.parse();
            assert(r.err == err, "Expected %d, got %d", r.err, err);
        };
    }
}

macro RerollOp new_reroll(bool once, ComparisonType t, int v){
    RerollOp new;
    new.op = new_comparison(t, v);
    new.once = once;
    return new;
}


macro LimitOp* new_limit(LimitType t, int v){
    LimitOp* new = allocator::new(allocator::temp(), LimitOp);
    new.amount = v;
    new.type = t;
    return new;
}

macro ExplodingOp* new_exploding(ExplodingType t1, ComparisonType t2, int v){
    ExplodingOp* new = allocator::new(allocator::temp(), ExplodingOp);
    new.op = new_comparison(t2, v);
    new.type = t1;
    return new;
}

macro ComparisonOp* new_comparison(ComparisonType t, int v){
    ComparisonOp* new = allocator::new(allocator::temp(), ComparisonOp);
    new.type = t;
    new.value = v;
    return new;
}

module rollc3::assertion;

fn void assert_any_roll(Roll a, Roll b){
    assert(a.is_group == b.is_group, "Expected %d, got %d", (int)a.is_group, (int)b.is_group) ;
    assert(a.err == b.err, "Expected %d, got %d", a.err, b.err) ;
    if(a.is_group){
        assert_grouped_roll(a.gr, b.gr);
    }else{
        assert_dice_roll(a.dr, b.dr);
    }
}

fn void assert_dice_roll(DiceRoll a, DiceRoll b){
    assert(a.multiplier == b.multiplier) ;
    assert(a.modifier == b.modifier) ;
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
    assert(a.rerolls.len == b.rerolls.len) ;
    foreach(index, reroll : a.rerolls){
        assert_reroll(a.rerolls[index], b.rerolls[index]) ;
    }
    // 	SortType sort;
    assert(a.sort == b.sort) ;
}

fn void assert_grouped_roll(GroupedRoll a, GroupedRoll b){
    // Roll[] rolls; 
    assert(a.rolls.len == b.rolls.len) ;
    foreach(index, rolls : a.rolls){
        assert_any_roll(a.rolls[index], b.rolls[index]) ;
    }
	// int modifier;
    assert(a.modifier == b.modifier) ;
	// LimitOp* limit;
    assert_limit(a.limit, b.limit) ;
	// ComparisonOp* success;
    assert_comparison(a.success, b.success) ;
    // ComparisonOp* failure;
    assert_comparison(a.failure, b.failure) ;
	// bool combined;
    assert(a.combined == b.combined) ;
	// bool negative;
    assert(a.negative == b.negative) ;
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
    assert(a.type == b.type, "Expected %d, got %d", a.type, b.type);
    assert(a.value == b.value);
}

fn void assert_limit(LimitOp* a, LimitOp* b){
    assert(((a != null && b != null) || a == b && a == null));
    assert(a.amount == b.amount);
    assert(a.type == b.type);
}

fn void assert_any_die(Die a, Die b){
    assert(a.normal == b.normal) ;
    if(a.normal) {assert_normal_die(a.nd, b.nd);}
    else { assert_fate_die(a.fd, b.fd);}
}

fn void assert_normal_die(NormalDie a, NormalDie b){
    assert( a == b);
}

fn void assert_fate_die(FateDie a, FateDie b){
    assert( a == b);
}