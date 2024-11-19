module rollc3;
// ComparisonType is the type of comparison
def ComparisonType = int;	
// EQUALS matches only values that are equal to the comparison value
const ComparisonType EQUALS = 0;
// GREATERTHAN matches only values greater than the comparison value
const ComparisonType GREATERTHAN = 1;
// LESSTHAN matches only values less than the comparison value
const ComparisonType LESSTHAN = 2;

// ComparisonOp is the operation that defines how you compare against a roll
// to determine whether the result counts
struct ComparisonOp {
	ComparisonType type;
	int value;
}

// Match returns true if the given value compares positively against the op val
fn bool ComparisonOp.match(ComparisonOp* op, int val) {
	switch (op.type) {
	    case EQUALS: return val == op.value;
	    case GREATERTHAN: return val > op.value;
	    case LESSTHAN: return val < op.value;
	}
	return false;
}

// String returns the string representation of the comparison operator
fn String ComparisonOp.string(ComparisonOp* op) {
	switch (op.type) {
	    case EQUALS: return string::tformat("=%d", op.value);
	    case GREATERTHAN: return string::tformat(">%d", op.value);
	    case LESSTHAN: return string::tformat("<%d", op.value);
	}
	return "";
}