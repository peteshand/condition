package condition;

/**
 * ...
 * @author P.J.Shand
 */
@:enum abstract BitOperator(String) from String to String {
	
	public var AND = '&&';
	public var OR = "||";
	public var XOR = "^";
}