package condition.modifier;

import delay.Delay;

class DelayModifier implements IModifier
{
	public var value:Bool;
    public var forceDispatch:Bool;
	public var callback:(value:Bool, forceDispatch:Bool) -> Void;
	var activeDelay:Float = 0;
    var inactiveDelay:Float = 0;

	public function new(activeDelay:Float = 0, inactiveDelay:Float = 0)
	{
        this.activeDelay = activeDelay;
        this.inactiveDelay = inactiveDelay;
	}

	public inline function setValue(value:Bool, forceDispatch:Bool, callback:(value:Bool, forceDispatch:Bool) -> Void):Void
	{
		this.value = value;
        this.forceDispatch = forceDispatch;
        this.callback = callback;
        
        Delay.killDelay(setActive);
        Delay.killDelay(setInactive);
        if (value){
            if (activeDelay == 0) setActive();
            Delay.byTime(activeDelay, setActive);
        } else {
            if (inactiveDelay == 0) setInactive();
            Delay.byTime(inactiveDelay, setInactive);
        }
	}

    function setActive()
    {
        callback(true, forceDispatch);
    }

    function setInactive()
    {
        callback(false, forceDispatch);
    }
}