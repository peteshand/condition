package condition.modifier;

interface IModifier {
	public var value:Bool;
	function setValue(value:Bool, forceDispatch:Bool, callback:(value:Bool, forceDispatch:Bool) -> Void):Void;
}
