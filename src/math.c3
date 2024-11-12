module roll20::math;
import roll20::dice;
import std::io;

distinct Operation = uint;
const Operation ADD = 0;
const Operation SUB = ADD+1;
const Operation MUL = SUB+1;
const Operation DIV = MUL+1;
const Operation MOD = DIV+1;

struct BinaryOperation (Printable){
    DiceResult left;
    DiceResult right;
    Operation operation;
}

fn int BinaryOperation.evaluate(&self){
	int left = self.left.evaluate();
	int right = self.right.evaluate();
	switch(self.operation){
		case ADD: return left + right;
		case SUB: return left - right;
		case MUL: return left * right;
		case DIV: return left / right;
		case MOD: return left % right;
	}
    return 0;
}

fn String BinaryOperation.to_string(&self, Allocator allocator) @dynamic{
	switch(self.operation){
		case ADD: return string::format("%d + %d", self.left.evaluate(), self.right.evaluate(), allocator: allocator);
		case SUB: return string::format("%d - %d", self.left.evaluate(), self.right.evaluate(), allocator: allocator);
		case MUL: return string::format("%d * %d", self.left.evaluate(), self.right.evaluate(), allocator: allocator);
		case DIV: return string::format("%d / %d", self.left.evaluate(), self.right.evaluate(), allocator: allocator);
		case MOD: return string::format("%d % %d", self.left.evaluate(), self.right.evaluate(), allocator: allocator);
	}
    
    return "invalid or unimplemented operation";
}