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
            .die =       {.normal = true, .nd = (NormalDie)6},
            .modifier =   3,
            .sort =       DESCENDING,
            .limit = &&{
                .type =   KEEPHIGHEST,
                .amount = 3,
            },
            .exploding = &&{
                .type = COMPOUNDED,
                .op = &&{
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
            .die =       {.normal = true, .nd = (NormalDie)6},
            .rerolls = {
               {
                    .op = &&{
                        .type =  rollc3::EQUALS,
                        .value = 2,
                    },
                },
                {
                    .op = &&{
                        .type =  rollc3::EQUALS,
                        .value = 4,
                    },
                    .once = true,
                },
            },
            .success = &&{
                .type =  rollc3::GREATERTHAN,
                .value = 3,
            },
            .failure = &&{
                .type =  rollc3::EQUALS,
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
            },
        },
        .limit = &&{
            .amount = 1,
            .type =   rollc3::DROPLOWEST,
        },
        .success = &&{
            .type =  rollc3::EQUALS,
            .value = 1,
        },
        .failure = &&{
            .type =  rollc3::GREATERTHAN,
            .value = 5,
        },
        .combined = false,
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
                    .limit = &&op,
                    .combined = true,
                    .negative = true,
                }
            },
        },
        .limit = &&{
            .amount = 3,
            .type =   rollc3::KEEPHIGHEST,
        },
        .success = &&{
            .type =  rollc3::LESSTHAN,
            .value = 4,
        },
        .failure = &&{
            .type =  rollc3::GREATERTHAN,
            .value = 3,
        },
        .combined = true,
        }
    };