module rollc3;
def TokenType = int;

struct Token{
    inline TokenType tok;
    String lit;
}

//CONSTANTS
const TokenType ILLEGAL =0;
const TokenType EOF =ILLEGAL + 1;
const TokenType WS =EOF + 1;
// Literas
const TokenType NUM =WS+ 1;
const TokenType DIE =NUM+ 1;
// Modifier
const TokenType PLUS =DIE+ 1;
const TokenType MINUS =PLUS+ 1;
// Extra rul =
const TokenType FAILURES =MINUS+ 1;
const TokenType EXPLODE =FAILURES+ 1;
const TokenType COMPOUND =EXPLODE+ 1;
const TokenType PENETRATE =COMPOUND + 1;
const TokenType KEEPHIGH =PENETRATE + 1;
const TokenType KEEPLOW =KEEPHIGH + 1;
const TokenType DROPHIGH =KEEPLOW + 1;
const TokenType DROPLOW =DROPHIGH + 1;
const TokenType REROLL =DROPLOW+ 1;
const TokenType SORT =REROLL+ 1;
// Tests 
const TokenType GREATER =SORT+1;
const TokenType LESS =GREATER+1;
const TokenType EQUAL =LESS+1;
// Grouping
const TokenType GROUPSTART = EQUAL + 1;
const TokenType GROUPEND = GROUPSTART + 1;
const TokenType GROUPSEP = GROUPEND + 1;