module rollc3;

// LimitType is the type of roll limitation
def LimitType = int;
// KEEPHIGHEST indicated we should keep the highest results
const LimitType KEEPHIGHEST = 0;
// KEEPLOWEST indicated we should keep the lowest results
const LimitType KEEPLOWEST = 1;
// DROPHIGHEST indicated we should drop the highest results
const LimitType DROPHIGHEST = 2;
// DROPLOWEST indicated we should drop the lowest results
const LimitType DROPLOWEST = 3;

// LimitOp is the operation that defines how dice roll results are limited
struct LimitOp {
	int amount;
	LimitType type;
}

fn String LimitOp.string(LimitOp op) {
    DString output;
	switch (op.type) {
	    case KEEPHIGHEST: output.append( "kh") ; break;
        case KEEPLOWEST: output .append("kl" ); break;
        case DROPHIGHEST: output.append( "dh") ; break;
        case DROPLOWEST: output .append("dl"); break;
	}

	if (op.amount > 1) {
		output.append(string::tformat("%d", op.amount));
	}

	return output.str_view().tcopy();
}