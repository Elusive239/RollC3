module rollc3;
def Token = int;

const Token  ILLEGAL =0;
const Token  EOF =ILLEGAL + 1;
const Token  WS =EOF + 1;
// Literas
const Token  NUM =WS+ 1;
const Token  DIE =NUM+ 1;
// Modifier
const Token  PLUS =DIE+ 1;
const Token  MINUS =PLUS+ 1;
// Extra rul =
const Token  FAILURES =MINUS+ 1;
const Token  EXPLODE =FAILURES+ 1;
const Token  COMPOUND =EXPLODE+ 1;
const Token  PENETRATE =COMPOUND + 1;
const Token  KEEPHIGH =PENETRATE + 1;
const Token  KEEPLOW =KEEPHIGH + 1;
const Token  DROPHIGH =KEEPLOW + 1;
const Token  DROPLOW =DROPHIGH + 1;
const Token  REROLL =DROPLOW+ 1;
const Token  SORT =REROLL+ 1;
// Tests 
const Token GREATER =SORT+1;
const Token LESS =GREATER+1;
const Token EQUAL =LESS+1;
// Grouping
const Token GROUPSTART = EQUAL + 1;
const Token GROUPEND = GROUPSTART + 1;
const Token GROUPSEP = GROUPEND + 1;