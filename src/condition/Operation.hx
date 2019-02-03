package condition;

@:enum abstract Operation(String) from String to String
{	
	var EQUAL = "==";
    var NOT_EQUAL = "!=";
    var LESS_THAN_OR_EQUAL = "<=";
    var LESS_THAN = "<";
    var GREATER_THAN_OR_EQUAL = ">=";
    var GREATER_THAN = ">";

    /*@:from
    static public function fromString(s:String) {
        if (s == "==") return EQUAL;
        if (s == "!=") return NOT_EQUAL;
        if (s == "<=") return LESS_THAN_OR_EQUAL;
        if (s == "<")  return LESS_THAN;
        if (s == ">=") return GREATER_THAN_OR_EQUAL;
        if (s == ">")  return GREATER_THAN;
        //throw 'Error: "' + s + '" is not a valid comparison operators, use one of the following: ==, !=, <=, <, >=, >';
        return EQUAL;
    }*/

    static function valid(s:String) {
        return s == EQUAL || s == NOT_EQUAL || s == LESS_THAN_OR_EQUAL || s == LESS_THAN || s == GREATER_THAN_OR_EQUAL || s == GREATER_THAN;
    }

    //@:to
    //public function toArray() {
    //    return [this];
    //}
}

/*enum Operation
{
    EQUAL_TO;
	NOT_EQUAL_TO;
	LESS_THAN_OR_EQUAL_TO;
	LESS_THAN;
	GREATER_THAN_OR_EQUAL_TO;
	GREATER_THAN;
}*/