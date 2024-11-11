import roll20;
import roll20::dice;
import std::io;


fn int main(String[] args)
{
	// DiceResult result = dice::roll_xy(902, 100);
	// result.keep_more(90);
	// io::printfn("%s, rolled = %d, len = %d", result, result.num_rolls, result.rolled_len);
	// io::printfn("%s, rolled = %d, len = %d", result.print_friendly(5, allocator: allocator::temp()), result.num_rolls, result.rolled_len);

	// DiceResultArray results = dice::roll_xyz(6, 20, 4);
	// io::printfn("%s", results);
	// for(int i = 0; i < results.len; i++) results[i].free();
	// allocator::free(allocator::heap(), results);
	// result.free();

	DiceResultArray results = roll20::interperet("6d20 ");
	io::printfn("%s", results);

	DiceResult result;
	io::printfn("[%s]", result);
	return 0;
}

module roll20;
import roll20::dice;
import std::collections::list;

def ResultList = List(<DiceResult>);

//TODO:: rewrite to implement a proper kinda AST thing so we can do math
fn DiceResultArray interperet(String roll, Allocator allocator = allocator::heap()){
	ResultList list;
	DString buffer;
	for(int index = 0; index < roll.len; index++){
		if(roll[index] == ' ' || index == roll.len-1){
			if(index == roll.len-1 && roll[index] != ' ' ) buffer.append_char(roll[index++]);
			String[] strs = buffer.str_view().split("d");
			if(strs.len == 3){
				DiceResultArray results = dice::roll_xyz(strs[0].trim().to_int()!!, strs[1].trim().to_int()!!, strs[2].trim().to_int()!!, strs[2][^1] == '!', allocator);
				foreach(result : results) list.push(result);
				allocator::free(allocator, results);
			}else if(strs.len == 2){
				DiceResult result;
				result = dice::roll_xy(strs[0].to_int()!!, strs[1].to_int()!!, strs[1][^1] == '!', allocator);
				list.push(result);
			}else{
				return {};
			}
			buffer.clear();
		}else if(roll[index] == '[' && roll[index + 1] == '['){
			String current = buffer.str_view().copy(allocator);
			buffer.clear();
			index+=2;
			while(roll[index] != ']' && roll[index+1] != ']'){
				buffer.append_char(roll[index++]);
			}
			DiceResult[] results = interperet(buffer.str_view());
			foreach(result : results) list.push(result);
			buffer.clear();
			buffer.append(current);
			current.free();
		}
		// else if(roll[index] == '+' || roll[index] == '-' || roll[index] == '/' || roll[index] == '%' || roll[index] == '*'){
		// }
		else{
			buffer.append_char(roll[index]);
		}
	}

	return list.to_new_array(allocator);
}

module roll20::dice;
import std::io;
import std::math::random;
import std::collections::list;

struct DiceResult (Printable){
	int num_rolls;
	int rolled_len;
	int max_value;
	int[] rolled;
	bool exploded;
}

fn void DiceResult.free(&self, Allocator allocator = allocator::heap()){
	allocator::free(allocator, self.rolled);
}

fn String DiceResult.print_friendly(&self, int max_to_print, Allocator allocator) @dynamic{
	if(self.max_value == 0){
		return string::tformat("%d", self.sum());
	}
	DString dstr; defer dstr.free();

	dstr.append("%dd%d");
	if(self.exploded) dstr.append_char('!');
	dstr.append(" = ");

	if(max_to_print > self.rolled_len) max_to_print = self.rolled_len;

	if(max_to_print == self.rolled_len){
		for(int i = 0; i < self.rolled_len; i++){
			dstr.appendf("%d", self.rolled[i]);
			if(self.rolled.len -1 != i) dstr.appendf(" + ");
		}
	}else{
		for(int i = 0; i < max_to_print; i++){
			dstr.appendf("%d", self.rolled[i]);
			if(max_to_print -1 != i) dstr.appendf(" + ");
		}
		if(self.rolled.len > 1) {dstr.append(" + ...");}
		else{
			dstr.append("...");
		}
	}

	dstr.append(" = %d");

	return string::tformat(dstr.str_view(), self.num_rolls, self.max_value, self.sum());
}

fn String DiceResult.to_string(&self, Allocator allocator) @dynamic{
	return self.print_friendly(self.rolled.len, allocator);
}

fn int DiceResult.sum(&self){
	int x =0;
	for(int i = 0; i < self.rolled_len; ++i){
		x += self.rolled[i];
	}
	return x;
}

fn int DiceResult.count(&self, int v){
	int x =0;
	for(int i = 0; i < self.rolled_len; ++i){
		if(self.rolled[i] == v) x++;
	}
	return x;
}

fn void DiceResult.drop_equal(&self, int v){
	int len = self.rolled_len;
	for(int i = 0 ; i < len; i++){
		while(self.rolled[i] == v){
			int vt = self.rolled[i];
			self.rolled[i] = self.rolled[len-1];
			self.rolled[len-1] = vt;
			len--;
		}
	}
	self.rolled_len = len;
}

fn void DiceResult.drop_less(&self, int v){
	int len = self.rolled_len;
	for(int i = 0 ; i < len; i++){
		while(self.rolled[i] <= v){
			int vt = self.rolled[i];
			self.rolled[i] = self.rolled[len-1];
			self.rolled[len-1] = vt;
			len--;
		}
	}
	self.rolled_len = len;
}

fn void DiceResult.drop_more(&self, int v){
	int len = self.rolled_len;
	for(int i = 0 ; i < len; i++){
		while(self.rolled[i] >= v){
			int vt = self.rolled[i];
			self.rolled[i] = self.rolled[len-1];
			self.rolled[len-1] = vt;
			len--;
		}
	}
	self.rolled_len = len;
}

fn void DiceResult.keep_equal(&self, int v){
	int len = self.rolled_len;
	for(int i = 0 ; i < len; i++){
		while(self.rolled[i] != v){
			int vt = self.rolled[i];
			self.rolled[i] = self.rolled[len-1];
			self.rolled[len-1] = vt;
			len--;
		}
	}
	self.rolled_len = len;
}

fn void DiceResult.keep_more(&self, int v){
	int len = self.rolled_len;
	for(int i = 0 ; i < len; i++){
		while(self.rolled[i] <= v){
			int vt = self.rolled[i];
			self.rolled[i] = self.rolled[len-1];
			self.rolled[len-1] = vt;
			len--;
		}
	}
	self.rolled_len = len;
}

fn void DiceResult.keep_less(&self, int v){
	int len = self.rolled_len;
	for(int i = 0 ; i < len; i++){
		while(self.rolled[i] >= v){
			int vt = self.rolled[i];
			self.rolled[i] = self.rolled[len-1];
			self.rolled[len-1] = vt;
			len--;
		}
	}
	self.rolled_len = len;
}

def IntList = List(<int>);

fn DiceResult roll_xy(int x, int y, bool explode = false, Allocator allocator = allocator::heap()){
	DiceResult result;// = {x, y, 0};
	result.num_rolls = x;
	result.max_value = y;
	IntList results; defer results.free();
	for(int i =0 ;i < result.num_rolls; ++i){
		int v = random::rand_in_range(1, result.max_value);
		results.push(v);
		if(v == result.max_value && explode) i--;
	}
	result.exploded = results.len() != x;
	result.rolled = results.to_new_array(allocator);
	result.rolled_len = result.rolled.len;
	return result;
}

def DiceResultArray = DiceResult[];

fn DiceResultArray roll_xyz(int x, int y, int z, bool explode = false, Allocator allocator = allocator::heap()){
	DiceResultArray results = allocator::new_array(allocator, DiceResult, z);
	for(int i = 0; i < z; i++){
		results[i] = roll_xy(x, y, explode, allocator);
	}
	return results;
}

fn int[] DiceResultArray.sum(&self, Allocator allocator = allocator::heap()){
	int[] s = allocator::new_array(allocator, int, self.len);
	for(int i =0; i < s.len; i++) {
		DiceResult result = (*self)[i];
		s[i] = result.sum();
	}
	return s;
}