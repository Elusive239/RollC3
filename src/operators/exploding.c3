module rollc3;

// ExplodingType is the type of exploding die
def ExplodingType = int;
// EXPLODING adds new dice for each roll satisfying the exploding condition
const ExplodingType EXPLODING = 0;
// COMPOUNDED adds to a single new result for each roll
const ExplodingType COMPOUNDED = 1;
// PENETRATING is like Exploding, except each die result has a -1 modifier
const ExplodingType PENETRATING = 2;

// ExplodingOp is the operation that defines how a dice roll explodes
struct ExplodingOp {
	inline ComparisonOp* op;
	ExplodingType type;
}

// String returns the string representation of the exploding dice operation
fn String ExplodingOp.string(ExplodingOp e) {
    DString output;
	switch (e.type) {
        case EXPLODING: output  .append  (  "!");
        case COMPOUNDED: output .append  ( "!!");
        case PENETRATING: output.append  ("!p" );
	}
    output.append(e.op.string().strip("="));

	return output.str_view().tcopy();
}