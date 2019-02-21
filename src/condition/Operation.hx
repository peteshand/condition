package condition;

@:enum abstract Operation(String) from String to String
{	
	var EQUAL = "==";
    var NOT_EQUAL = "!=";
    var LESS_THAN_OR_EQUAL = "<=";
    var LESS_THAN = "<";
    var GREATER_THAN_OR_EQUAL = ">=";
    var GREATER_THAN = ">";

    static function valid(s:String) {
        return s == EQUAL || s == NOT_EQUAL || s == LESS_THAN_OR_EQUAL || s == LESS_THAN || s == GREATER_THAN_OR_EQUAL || s == GREATER_THAN;
    }
}