module rollc3;

// RerollOp is the operation that defines how dice are rerolled
struct RerollOp {
	ComparisonOp* op;
	bool once;
}

// String returns the string representation of the exploding dice operation
fn String RerollOp.string(RerollOp e){
    DString output; defer output.free();
	if (e.once) {output.append("ro");}
	else {output.append("r");}
    output.append(e.op.string().strip( "="));
	return output.str_view().tcopy();
}