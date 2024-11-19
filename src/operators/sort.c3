module rollc3;

// SortType is the type of sorting to use for dice roll results
def SortType = int;

// String return the string representation of a SortType value
fn String SortType.string(SortType t) => t == ASCENDING ? "s" : t == DESCENDING ? "sd" : "";

// UNSORTED doesn't sort dice rolls
const SortType UNSORTED = 0;
// ASCENDING sorts dice rolls from lowest to highest
const SortType ASCENDING = 1;
// DESCENDING sorts dice rolls from highest to lowest
const SortType DESCENDING = 2;