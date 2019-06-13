package condition.modifier;

class DefaultModifier implements IModifier
{
	public var value:Bool;
	
	public function new()
	{

	}

	public inline function setValue(value:Bool, forceDispatch:Bool, callback:(value:Bool, forceDispatch:Bool) -> Void):Void
	{
		this.value = value;
		callback(value, forceDispatch);
	}
}