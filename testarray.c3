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