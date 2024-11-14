module roll20;
import std::collections::list;
import roll20::dice;
import roll20::math;
import std::io;

def DiceRolls = List(<DiceResult>);

fn void test(){
	const String ROLL = "1d20 / 1d10 + 1";
	Token[] tokens = tokenize(ROLL);
	io::printfn("%s", tokens);
	DiceResult[] fin = interperet(tokens);
	io::printfn("%s", fin);
}

fn DiceResult[] interperet(Token[] tokens){
	DiceRolls rolls; defer rolls.free();
	for(int i =0; i < tokens.len; i++){
		io::printfn("Current token %d: {%s, %s}",i, tokens[i], tokens[i].type);
		if(tokens[i].type == TokenType.NUMBER){
			int x = tokens[i++].number;
			if(i < tokens.len && tokens[i].type == TokenType.TEXT && tokens[i].text == "d"){
				interperet_dice(x, &i, &rolls, tokens);
				continue;
			}
			DiceResult res = { {x}, -1 };
			rolls.push(res);
		}else if(tokens[i].type == TokenType.TEXT && tokens[i].text == "d"){
			interperet_dice(1, &i, &rolls, tokens);
			continue;
		} 
		else if(tokens[i].type == TokenType.OPENING_DOUBLE_BRACKETS){
			interperet_inner(&i, &rolls, tokens, TokenType.OPENING_DOUBLE_BRACKETS, TokenType.CLOSING_DOUBLE_BRACKETS);
		}else if(tokens[i].type == TokenType.OPENING_BRACKET){
			interperet_inner(&i, &rolls, tokens, TokenType.OPENING_BRACKET, TokenType.CLOSING_BRACKET);
		}else if(tokens[i].type == TokenType.OPENING_PARENTHESIS){
			interperet_inner(&i, &rolls, tokens, TokenType.OPENING_PARENTHESIS, TokenType.CLOSING_PARENTHESIS);
		}else if(tokens[i].type == TokenType.OPENING_BRACE){
			interperet_inner(&i, &rolls, tokens, TokenType.OPENING_BRACE, TokenType.CLOSING_BRACE);
		}else if(tokens[i].type == TokenType.MATH_OPERATOR){
			io::printfn("Math Operator!");
			DiceResult[] next_rolls = interperet(tokens[i+1..]);
			if(tokens[i].operator == math::ADD || tokens[i].operator == math::SUB ){
				if(tokens[i].operator == math::SUB){next_rolls[0].results[0] *= -1;}
				foreach(r : next_rolls) rolls.push(r);
			}else{
				int right;
				foreach(r : next_rolls) right += r.evaluate();
				for(int z =0; z < rolls.last()!!.results.len; z++){
					if(tokens[i].operator == math::MUL) rolls.last()!!.results[z] *= right;
					if(tokens[i].operator == math::DIV) rolls.last()!!.results[z] /= right;
					if(tokens[i].operator == math::MOD) rolls.last()!!.results[z] %= right;
				}
			}
			i = tokens.len;
		}else if(tokens[i].type == TokenType.TEXT){continue;}
	}
	return rolls.to_new_array();
}

macro interperet_inner(int* xi, DiceRolls* rolls, Token[] tokens, TokenType open, TokenType close){
	int i = (*xi) + 1;
	int current = i;
	int open_count = 1;
	while(open_count != 0){
		i++;
		if(tokens[i].type == open) open_count++;
		if(tokens[i].type == close) open_count--;
	}
	DiceResult[] inner = interperet(tokens[current:i]);
	foreach(r : inner) rolls.push(r);
	(*xi) = i;
}

macro interperet_dice(int x, int* xi, DiceRolls* rolls, Token[] tokens){
	int i= (*xi)+1;
	if(tokens[i].type == TokenType.NUMBER){ 
		int y = tokens[i].number;
		if( i < tokens.len && tokens[i].type == TokenType.EXPLODE){
			rolls.push(dice::roll_x(x, y, true));
			i++;
		}else{
			rolls.push(dice::roll_x(x, y));
		}
	}
	(*xi) = i;
}

def TokenList = List(<Token>);

fn Token[] tokenize(String text){
	int index = 0;
	DString buffer; defer buffer.clear();
	TokenList tokens;
	Token token;
	while(index < text.len){
		skip_whitespace(&index, text);
		if(text[index].is_alpha()){
			while(index < text.len && text[index].is_alpha()){
				buffer.append_char(text[index++]);
			}
			// io::printfn("GOT STRING %s", buffer);
			token.text = buffer.str_view().copy(allocator::temp());
			token.type = TokenType.TEXT;
			buffer.clear();
			tokens.push(token);
			
		}else if(text[index].is_digit()){
			while(index < text.len && (text[index].is_digit() || text[index] == '.')){
				// io::printfn("%c", text[index]);
				buffer.append_char(text[index++]);
			}
			// io::printfn("GOT NUMBER %s", buffer);
			token.number = buffer.str_view().to_int() ?? 0; //.copy(allocator::temp());
			token.type = TokenType.NUMBER;
			buffer.clear();
			tokens.push(token);
		}else if (text[index] == '['){
			index++;
			if(text[index] == '['){
				index++;
				token.text = "[[";
				token.type = TokenType.OPENING_DOUBLE_BRACKETS;
				tokens.push(token);
			}else{ //SINGLE
				token.text = "[";
				token.type = TokenType.OPENING_BRACKET;
				tokens.push(token);
			}
			
		}else if (text[index] == ']' && text[index+1] == ']'){
			index++;
			if(text[index] == ']'){
				index++;
				token.text = "]]";
				token.type = TokenType.CLOSING_DOUBLE_BRACKETS;
				tokens.push(token);
			}else{ //SINGLE
				token.text = "]";
				token.type = TokenType.CLOSING_BRACKET;
				tokens.push(token);
			}
			
		}else if(text[index] == '('){
			index++;
			token.text = "(";
			token.type = TokenType.OPENING_PARENTHESIS;
			tokens.push(token);
			
		}else if(text[index] == ')'){
			index++;
			token.text = ")";
			token.type = TokenType.CLOSING_PARENTHESIS;
			tokens.push(token);
			
		}else if(text[index] == '{'){
			index++;
			token.text = "{";
			token.type = TokenType.OPENING_BRACE;
			tokens.push(token);
			
		}else if(text[index] == '}'){
			index++;
			token.text = "}";
			token.type = TokenType.CLOSING_BRACE;
			tokens.push(token);
			
		}else if(text[index] == '+' || text[index] == '-' || text[index] == '*' || text[index] == '/' || text[index] == '%'){
			io::printfn("PARSE OPERATOR");
			switch(text[index++]){
				case '+': token.operator = math::ADD;
				case '-': token.operator = math::SUB;
				case '*': token.operator = math::MUL;
				case '/': token.operator = math::DIV;
				case '%': token.operator = math::MOD;
			}
			token.type = TokenType.MATH_OPERATOR;
			tokens.push(token);
			
		}else if (text[index] == '!'){
			index++;
			token.type = TokenType.EXPLODE;
			tokens.push(token);
			
		}
		token = {};
		// index++;
	}
	// foreach(i, tok : tokens){
	// 	io::printfn("Current token %d: {%s, %s}",i, tok, tok.type);
	// }
	return tokens.to_new_array();
}


enum TokenType{
	TEXT, NUMBER, MATH_OPERATOR, 
	OPENING_DOUBLE_BRACKETS, CLOSING_DOUBLE_BRACKETS, 	//[[]] 
	OPENING_BRACKET, CLOSING_BRACKET,					//[]
	OPENING_PARENTHESIS, CLOSING_PARENTHESIS, 			//()
	OPENING_BRACE, CLOSING_BRACE,						//{}
	EXPLODE												//!
}

struct Token (Printable){
	union {
		String text;
		int number;
		Operation operator;
	}
	TokenType type;
}

fn String Token.to_string(&self, Allocator allocator) @dynamic{
	switch(self.type){
		case TokenType.MATH_OPERATOR: return string::format("%d", self.operator, allocator: allocator); 
		case TokenType.NUMBER: return string::format("%d", self.number, allocator: allocator); 
		case TokenType.OPENING_DOUBLE_BRACKETS: return "[[";// break;
		case TokenType.CLOSING_DOUBLE_BRACKETS: return "]]";
		case TokenType.EXPLODE: return "!";
		default: return string::format("%s", self.text, allocator: allocator); 
	}
}

fn void skip_whitespace(int *i, String text){
	while( (*i) < text.len &&  (text[*i] == ' '  || text[*i] == '\n' || text[*i] == '\r' || text[*i] == '\t') ) (*i)++;
}