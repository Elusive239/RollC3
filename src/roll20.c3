module roll20;
import std::collections::list;
import roll20::dice;
import roll20::math;
import std::io;

// fn DiceResult[] interperet(String roll){
// 	DString buffer; defer buffer.free();
// 	List(<DiceResult>) results;
// 	for(int i =0; i < roll.len; i++){
// 		if(roll[i].is_digit()){
// 			while(roll[i].is_digit()) buffer.append_char(roll[i++]);
// 			int x = buffer.str_view().to_int()!!;
// 			buffer.clear();
// 			skip_whitespace(&i, roll);
// 			if(roll[i] == 'd'){
// 				i++;
// 				while(roll[i].is_digit()) buffer.append_char(roll[i++]);
// 				int y = buffer.str_view().to_int()!!;
// 				buffer.clear();
// 				skip_whitespace(&i, roll);

// 				results.push(result);
// 			}
// 		}
// 	}
// }
def DiceRolls = List(<DiceResult>);

fn void test(){
	const String ROLL = "1d20";
	Token[] tokens = tokenize(ROLL);
	io::printfn("%s", tokens);
	DiceResult fin = interperet(tokens);
	io::printfn("%s", fin);
}

fn DiceResult interperet(Token[] tokens){
	DiceRolls rolls; defer rolls.free();
	for(int i =0; i < tokens.len; i++){
		if(tokens[i].type == TokenType.NUMBER){
			int x = tokens[i++].number;
			if(tokens[i].type == TokenType.TEXT && tokens[i].text == "d"){
				interperet_dice(x, &i, &rolls, tokens);
				continue;
			}
			DiceResult res = { {x}, -1 };
			rolls.push(res);
		}else if(tokens[i].type == TokenType.TEXT && tokens[i].text == "d"){
			interperet_dice(1, &i, &rolls, tokens);
			continue;
		} 
		else if(tokens[i].type == TokenType.OPENING_BRACKETS){
			interperet_inner(&i, &rolls, tokens, TokenType.OPENING_BRACKETS, TokenType.CLOSING_BRACKETS);
		}
	}

	DiceResult final = { {0}, -1};
	foreach(roll : rolls){
		final.results[0] += roll.evaluate();
	}

	return final;
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
	DiceResult inner = interperet(tokens[current:i]);
	rolls.push(inner);
	(*xi) = i;
}

macro interperet_dice(int x, int* xi, DiceRolls* rolls, Token[] tokens){
	int i= (*xi) + 1;
	if(tokens[i].type == TokenType.NUMBER){ 
		int y = tokens[i++].number;
		// io::printfn("%d, %d", x, y);
		if(tokens[i].type == TokenType.EXPLODE){
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
			token.text = buffer.str_view().copy(allocator::temp());
			token.type = TokenType.TEXT;
			buffer.clear();
			tokens.push(token);
			token = {};
		}else if(text[index].is_digit()){
			while(index < text.len && (text[index].is_digit() || text[index] == '.')){
				buffer.append_char(text[index++]);
			}
			token.number = buffer.str_view().to_int() ?? 0; //.copy(allocator::temp());
			token.type = TokenType.NUMBER;
			buffer.clear();
			tokens.push(token);
			token = {};
		}else if (text[index] == '['){
			index++;
			if(text[index] == '['){
				index++;
				token.text = "[[";
				token.type = TokenType.OPENING_BRACKETS;
				tokens.push(token);
				token = {};
			}else{ //SINGLE
				token.text = "[";
				token.type = TokenType.OPENING_BRACKETS;
				tokens.push(token);
				token = {};
			}
		}else if (text[index] == ']' && text[index+1] == ']'){
			index+=2;
			token.text = "]]";
			token.type = TokenType.OPENING_BRACKETS;
			tokens.push(token);
			token = {};
		}else if(text[index] == '+' || text[index] == '-' || text[index] == '*' || text[index] == '/' || text[index] == '%'){
			switch(text[index++]){
				case '+': token.operator = math::ADD;
				case '-': token.operator = math::SUB;
				case '*': token.operator = math::MUL;
				case '/': token.operator = math::DIV;
				case '%': token.operator = math::MOD;
			}
			token.type = TokenType.OPERATOR;
			tokens.push(token);
			token = {};
		}else if (text[index] == '!'){
			index++;
			token.type = TokenType.EXPLODE;
			tokens.push(token);
			token = {};
		}
		index++;
	}
	return tokens.to_new_array();
}

enum TokenType{
	TEXT, NUMBER, OPERATOR, OPENING_BRACKETS, CLOSING_BRACKETS, EXPLODE
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
		case TokenType.OPERATOR: return string::format("%d", self.operator, allocator: allocator); 
		case TokenType.NUMBER: return string::format("%d", self.number, allocator: allocator); 
		case TokenType.OPENING_BRACKETS: return "[[";// break;
		case TokenType.CLOSING_BRACKETS: return "]]";
		case TokenType.EXPLODE: return "!";
		default: return string::format("%s", self.text, allocator: allocator); 
	}
}

fn void skip_whitespace(int *i, String text){
	while( (*i) < text.len &&  (text[*i] == ' '  || text[*i] == '\n' || text[*i] == '\r' || text[*i] == '\t') ) (*i)++;
}