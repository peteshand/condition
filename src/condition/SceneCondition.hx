package condition;

import notifier.Notifier;

/**
 * ...
 * @author P.J.Shand
 */
class SceneCondition extends Condition
{
	public var wildcard:Bool;
	var wildcardValue:String;
	var wildcardLength:Int;
	
	public function new(notifier:Notifier<Dynamic>, uri:String, operation:String="==", wildcard:Bool=false) 
	{
		super(notifier, uri, operation);
		wildcardLength = uri.indexOf("*");
		if (wildcardLength > 0) {
			this.wildcard = true;
			wildcardValue = uri.substr(0, wildcardLength);
		}

		if (this.wildcard){
			equalTo = stringEqualTo;
		}
	}
	
	function stringEqualTo(value1:String, value2:String) 
	{
		if (value1 == null) value1 = "";
		if (value2 == null) value2 = "";
		
		if (wildcard) {
			var s1:String = untyped value1;
			var s2:String = s1.substr(0, wildcardLength);
			if (s2 == wildcardValue) return true;
			else return false;
		}
		else {
			if (value1 == value2) return true;
			return false;
		}
	}

	override function toString():String
	{
		return "[SceneCondition] " + testValue + " " + operation + " " + targetValue + " | " + value + " | " + (targetValue == targetValue);
	}
}