package condition;

@:enum abstract Operation(String) from String to String
{	
	public var EQUAL_TO:String = "==";
    public var NOT_EQUAL_TO:String = "!=";
    public var LESS_THAN_OR_EQUAL_TO:String = "<=";
    public var LESS_THAN:String = "<";
    public var GREATER_THAN_OR_EQUAL_TO:String = ">=";
    public var GREATER_THAN:String = ">";
}