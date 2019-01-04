package condition;

import notifier.Notifier;
import condition.Operation;

/**
 * ...
 * @author P.J.Shand
 */
class Condition extends Notifier<Bool>
{
	public var notifier:Notifier<Dynamic>;
	public var operation:Operation;
	public var subProp:String;
	var targetIsFunction:Bool;
	var testValue(get, null):Dynamic;
	
	public var targetValue(get, null):Dynamic;
	var _targetValue:Dynamic;
	var _targetFunction:Void -> Dynamic;

	public function new(notifier:Notifier<Dynamic>, _targetValue:Dynamic, operation:Operation="==", subProp:String=null) 
	{
		this.operation = operation;
		
		targetIsFunction = Reflect.isFunction(_targetValue);
		if (targetIsFunction) _targetFunction = _targetValue;
		else this._targetValue = _targetValue;

		this.notifier = notifier;
		this.subProp = subProp;

		super();
		notifier.add(() -> {
			check();
		}, 1000);
		check();
	}

	public function get_targetValue():Dynamic
	{
		if (targetIsFunction) return _targetFunction();
		else return _targetValue;
	}
	
	public inline function check(forceDispatch:Bool = false) 
	{
		this.value = getValue();
		if (forceDispatch) this.dispatch();
	}

	function get_testValue()
	{
		if (subProp == null) return notifier.value;
		else {
			var split:Array<String> = subProp.split(".");
			if (subProp.indexOf(".") == -1) split = [subProp];
			
			var value:Dynamic = notifier.value;
			while (split.length > 0 && value != null){
				var prop:String = split.shift();
				value = Reflect.getProperty(value, prop);
			}
			
			return value;
		}
	}
	
	function getValue() 
	{
		switch (operation) 
		{
			case Operation.EQUAL_TO:
				return equalTo(testValue, targetValue);
			case Operation.NOT_EQUAL_TO:
				return notEqualTo(testValue, targetValue);
			case Operation.LESS_THAN_OR_EQUAL_TO:
				return lessThanOrEqualTo(testValue, targetValue);
			case Operation.LESS_THAN:
				return lessThan(testValue, targetValue);
			case Operation.GREATER_THAN_OR_EQUAL_TO:
				return greaterThanOrEqualTo(testValue, targetValue);
			case Operation.GREATER_THAN:
				return greaterThan(testValue, targetValue);
			default:
		}
		
		return false;
	}
	
	dynamic function equalTo(value1:Dynamic, value2:Dynamic) 
	{
		if (value1 == value2) return true;
		return false;
	}
	
	inline function notEqualTo(value1:Dynamic, value2:Dynamic) 
	{
		if (value1 != value2) return true;
		return false;
	}
	
	inline function lessThanOrEqualTo(value1:Dynamic, value2:Dynamic) 
	{
		if (value1 <= value2) return true;
		return false;
	}
	
	inline function lessThan(value1:Dynamic, value2:Dynamic) 
	{
		if (value1 < value2) return true;
		return false;
	}
	
	inline function greaterThanOrEqualTo(value1:Dynamic, value2:Dynamic) 
	{
		if (value1 >= value2) return true;
		return false;
	}
	
	inline function greaterThan(value1:Dynamic, value2:Dynamic) 
	{
		if (value1 > value2) return true;
		return false;
	}

	override function toString():String
	{
		return "[Condition] " + testValue + " " + operation + " " + targetValue + " | " + value + " | " + (testValue == targetValue);
	}

	public function clone():Condition
	{
		var _clone:Condition = new Condition(notifier, _targetValue, operation, subProp);
		_clone._targetFunction = _targetFunction;
		_clone.targetIsFunction = targetIsFunction;
		return _clone;
	}
}