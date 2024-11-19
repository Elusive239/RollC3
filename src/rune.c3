module rollc3;
def Rune = char; //honestly not necessary, trying to keep it like the original.

const Rune R_EOF = 0;

// Return true if ch is a whitespace Runeacter
fn bool is_whitespace(Rune ch) => ch == ' ' || ch == '\t' || ch == '\n';

// Return true if ch is a number
fn bool is_number(Rune ch) => ch >= '0' && ch <= '9';

// Return true if ch is a weird die Runeacter
fn bool is_die_Rune(Rune ch) => ch == 'F' || ch == 'f';

// Return true if ch is a comparison Runeacter
fn bool is_compare(Rune ch) => ch == '<' || ch == '>' || ch == '=';

// Return true if ch is a modifier Runeacter
fn bool is_modifier(Rune ch) => ch == '+' || ch == '-';

// Return true if ch is an exploding Runeacter
fn bool is_exploding(Rune ch) => ch == '!';

// Return true if ch is a reroll Runeacter
fn bool is_reroll(Rune ch) => ch == 'r';

// Return true if ch is a grouping Runeacter
fn bool is_grouping(Rune ch) => ch == '{' || ch == ',' || ch == '}';

// Return true if ch is a keep limit Runeacter
fn bool is_keep_limit(Rune ch) => ch == 'k';

// Return true if ch is a valid Runeacter for indicating a die roll
fn bool is_valid_die_roll(Rune ch) => !is_whitespace(ch) && !is_grouping(ch) && !is_reroll(ch) && !is_exploding(ch) && !is_compare(ch) && !is_modifier(ch) && !is_keep_limit(ch) && ch != 'd' && ch != 'D';
