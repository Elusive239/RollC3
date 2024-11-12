import roll20;
import roll20::dice;
import std::io;

fn int main(String[] args)
{
	DiceResult result = dice::roll_x(32);
	io::printfn("%s", result);
	return 0;
}

// fn int main(String[] args)
// {
// 	DiceResult result = dice::roll_xy(9, 100);
// 	result.keep_more(50);
// 	io::printfn("[%s], rolled = %d, len = %d", result, result.num_rolls, result.rolled_len);
// 	// io::printfn("[%s], rolled = %d, len = %d", result.print_friendly(5, allocator: allocator::temp()), result.num_rolls, result.rolled_len);

// 	DiceResultArray results = dice::roll_xyz(2, 20, 4);
// 	io::printfn("%s", results);
// 	for(int i = 0; i < results.len; i++) results[i].free();
// 	allocator::free(allocator::heap(), results);
// 	result.free();

// 	DiceResultArray results2 = roll20::interperet("6d20 ");
// 	io::printfn("%s", results2);
// 	for(int i = 0; i < results2.len; i++) results2[i].free();

// 	DiceResult result2;
// 	result2.value = 32;
// 	io::printfn("[%s]", result2);
// 	result2.free();

// 	DiceResultArray results3 = roll20::interperet("d20 ");
// 	io::printfn("%s", results3);
// 	for(int i = 0; i < results3.len; i++) results3[i].free();

// 	MathResult math;
// 	math.left = result;
// 	math.right = result2;
// 	math.operation = roll20::ADD;
// 	io::printfn("Math: [%s] + [%s] = %s", result, result2, math.evaluate());
// 	return 0;
// }

// module roll20;
// import roll20::dice;
// import std::collections::list;

// distinct MathOperation = uint;
// const MathOperation ADD = 0;
// const MathOperation SUB = ADD+1;
// const MathOperation MUL = SUB+1;
// const MathOperation DIV = MUL+1;
// const MathOperation MOD = DIV+1;

// struct MathResult{
// 	DiceResult left;
// 	DiceResult right;
// 	MathOperation operation;
// }

// fn DiceResult MathResult.evaluate(&self){
// 	int left = self.left.evaluate();
// 	int right = self.right.evaluate();
// 	int result;
// 	switch(self.operation){
// 		case ADD: result = left + right; break;
// 		case SUB: result = left - right; break;
// 		case MUL: result = left * right; break;
// 		case DIV: result = left / right; break;
// 		case MOD: result = left % right; break;
// 	}
// 	DiceResult ret;
// 	ret.value = result;
// 	ret.die_type = MATH;
// 	return ret;
// }

// def ResultList = List(<DiceResult>);

// //TODO:: rewrite to implement a proper kinda AST thing so we can do math
// fn DiceResultArray interperet(String roll, Allocator allocator = allocator::heap()){
// 	ResultList list;
// 	DString buffer;
// 	for(int index = 0; index < roll.len; index++){
// 		if(roll[index] == ' ' || index == roll.len-1){
// 			if(index == roll.len-1 && roll[index] != ' ' ) buffer.append_char(roll[index++]);
// 			String[] strs = buffer.str_view().split("d");
// 			if(strs.len == 3){
// 				int v1, v2, v3;
// 				v1 = strs[0].trim().len == 0 ? 1 : strs[0].trim().to_int()!!;
// 				v2 = strs[1].trim().to_int()!!; 
// 				v3 = strs[2].trim().to_int()!!;

// 				DiceResultArray results = dice::roll_xyz(v1, v2, v3, strs[2][^1] == '!', allocator);
// 				foreach(result : results) list.push(result);
// 				allocator::free(allocator, results);
// 			}else if(strs.len == 2){
// 				int v1, v2;
// 				v1 = strs[0].trim().len == 0 ? 1 : strs[0].trim().to_int()!!;
// 				v2 = strs[1].trim().to_int()!!; 
// 				DiceResult result = dice::roll_xy(v1, v2, strs[1][^1] == '!', allocator);
// 				list.push(result);
// 			}else{
// 				return {};
// 			}
// 			buffer.clear();
// 		}else if(roll[index] == '[' && roll[index + 1] == '['){
// 			String current = buffer.str_view().copy(allocator);
// 			buffer.clear();
// 			index+=2;
// 			while(roll[index] != ']' && roll[index+1] != ']'){
// 				buffer.append_char(roll[index++]);
// 			}
// 			DiceResult[] results = interperet(buffer.str_view());
// 			foreach(result : results) list.push(result);
// 			buffer.clear();
// 			buffer.append(current);
// 			current.free();
// 		}
// 		else{
// 			buffer.append_char(roll[index]);
// 		}
// 	}

// 	return list.to_new_array(allocator);
// }

// module roll20::dice;
// import std::io;
// import std::math::random;
// import std::collections::list;

// distinct DiceResultType = uint;
// const DiceResultType VALUE = 0;
// const DiceResultType ROLLED = VALUE+1;
// const DiceResultType MATH = VALUE+1;

// struct DiceResult (Printable){
// 	int num_rolls;
// 	int rolled_len;
// 	int max_value;
// 	union {
// 		int[] rolled;
// 		int value;
// 		MathResult math;
// 	}
// 	bool exploded;
// 	DiceResultType die_type;
// }

// fn void DiceResult.free(&self, Allocator allocator = allocator::heap()){
// 	if(self.num_rolls != 0 && self.rolled_len != 0) allocator::free(allocator, self.rolled);
// }

// fn String DiceResult.print_friendly(&self, int max_to_print, Allocator allocator) @dynamic{
// 	if(self.max_value == 0){
// 		return string::tformat("%d", self.evaluate());
// 	}
// 	DString dstr; defer dstr.free();

// 	dstr.append("%dd%d");
// 	if(self.exploded) dstr.append_char('!');
// 	dstr.append(" = ");

// 	if(max_to_print > self.rolled_len) max_to_print = self.rolled_len;

// 	if(max_to_print == self.rolled_len){
// 		for(int i = 0; i < self.rolled_len; i++){
// 			dstr.appendf("%d", self.rolled[i]);
// 			if(self.rolled.len -1 != i) dstr.appendf(" + ");
// 		}
// 	}else{
// 		for(int i = 0; i < max_to_print; i++){
// 			dstr.appendf("%d", self.rolled[i]);
// 			if(max_to_print -1 != i) dstr.appendf(" + ");
// 		}
// 		if(self.rolled.len > 1) {dstr.append(" + ...");}
// 		else{
// 			dstr.append("...");
// 		}
// 	}

// 	dstr.append(" = %d");

// 	return string::tformat(dstr.str_view(), self.num_rolls, self.max_value, self.evaluate());
// }

// fn String DiceResult.to_string(&self, Allocator allocator) @dynamic{
// 	return self.print_friendly(self.rolled.len, allocator);
// }

// fn int DiceResult.evaluate(&self){
// 	if(self.die_type == VALUE){
// 		return self.value;
// 	}else if (self.die_type == MATH){
// 		return self.value.evaluate().value;
// 	}

// 	int x =0;
// 	for(int i = 0; i < self.rolled_len; ++i){
// 		x += self.rolled[i];
// 	}
// 	return x;
// }

// fn int DiceResult.count(&self, int v){
// 	int x =0;
// 	for(int i = 0; i < self.rolled_len; ++i){
// 		if(self.rolled[i] == v) x++;
// 	}
// 	return x;
// }

// fn void DiceResult.drop_equal(&self, int v){
// 	int len = self.rolled_len;
// 	for(int i = 0 ; i < len; i++){
// 		while(len > 0 && self.rolled[i] == v){
// 			int vt = self.rolled[i];
// 			self.rolled[i] = self.rolled[len-1];
// 			self.rolled[len-1] = vt;
// 			len--;
// 		}
// 	}
// 	self.rolled_len = len;
// }

// fn void DiceResult.drop_less(&self, int v){
// 	int len = self.rolled_len;
// 	for(int i = 0 ; i < len; i++){
// 		while(len > 0 && self.rolled[i] <= v){
// 			int vt = self.rolled[i];
// 			self.rolled[i] = self.rolled[len-1];
// 			self.rolled[len-1] = vt;
// 			len--;
// 		}
// 	}
// 	self.rolled_len = len;
// }

// fn void DiceResult.drop_more(&self, int v){
// 	int len = self.rolled_len;
// 	for(int i = 0 ; i < len; i++){
// 		while(len > 0 && self.rolled[i] >= v){
// 			int vt = self.rolled[i];
// 			self.rolled[i] = self.rolled[len-1];
// 			self.rolled[len-1] = vt;
// 			len--;
// 		}
// 	}
// 	self.rolled_len = len;
// }

// fn void DiceResult.keep_equal(&self, int v){
// 	int len = self.rolled_len;
// 	for(int i = 0 ; i < len; i++){
// 		while(len > 0 && self.rolled[i] != v){
// 			int vt = self.rolled[i];
// 			self.rolled[i] = self.rolled[len-1];
// 			self.rolled[len-1] = vt;
// 			len--;
// 		}
// 	}
// 	self.rolled_len = len;
// }

// fn void DiceResult.keep_more(&self, int v){
// 	int len = self.rolled_len;
// 	for(int i = 0 ; i < len; i++){
// 		while(len > 0 && self.rolled[i] <= v){
// 			int vt = self.rolled[i];
// 			self.rolled[i] = self.rolled[len-1];
// 			self.rolled[len-1] = vt;
// 			len--;
// 		}
// 	}
// 	self.rolled_len = len;
// }

// fn void DiceResult.keep_less(&self, int v){
// 	int len = self.rolled_len;
// 	for(int i = 0 ; i < len; i++){
// 		while(len > 0 && self.rolled[i] >= v){
// 			int vt = self.rolled[i];
// 			self.rolled[i] = self.rolled[len-1];
// 			self.rolled[len-1] = vt;
// 			len--;
// 		}
// 	}
// 	self.rolled_len = len;
// }

// def IntList = List(<int>);

// fn DiceResult roll_xy(int x, int y, bool explode = false, Allocator allocator = allocator::heap()){
// 	DiceResult result;// = {x, y, 0};
// 	result.num_rolls = x;
// 	result.max_value = y;
// 	IntList results; defer results.free();
// 	for(int i =0 ;i < result.num_rolls; ++i){
// 		int v = random::rand_in_range(1, result.max_value);
// 		results.push(v);
// 		if(v == result.max_value && explode) i--;
// 	}
// 	result.exploded = results.len() != x;
// 	result.rolled = results.to_new_array(allocator);
// 	result.rolled_len = result.rolled.len;
// 	result.die_type = ROLLED;
// 	return result;
// }

// def DiceResultArray = DiceResult[];

// fn DiceResultArray roll_xyz(int x, int y, int z, bool explode = false, Allocator allocator = allocator::heap()){
// 	DiceResultArray results = allocator::new_array(allocator, DiceResult, z);
// 	for(int i = 0; i < z; i++){
// 		results[i] = roll_xy(x, y, explode, allocator);
// 	}
// 	return results;
// }

// fn int[] DiceResultArray.evaluate(&self, Allocator allocator = allocator::heap()){
// 	int[] s = allocator::new_array(allocator, int, self.len);
// 	for(int i =0; i < s.len; i++) {
// 		DiceResult result = (*self)[i];
// 		s[i] = result.evaluate();
// 	}
// 	return s;
// }