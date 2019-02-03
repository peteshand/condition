package condition;

#if notifier
	import notifier.Notifier;
#else
	import imagsyd.notifier.Notifier;
	import imagsyd.notifier.Notifier.BaseNotifier;
#end

import signal.Signal;
import haxe.extern.EitherType;
import utils.FunctionUtil;
import haxe.Constraints.Function;
/**
 * ...
 * @author P.J.Shand
 */
 @:access(condition.Operation)
@:access(condition.Condition.Case)
class Condition
{
	var cases:Array<ICase> = [];
	public var active = new Notifier<Bool>();
	
	public var onActive:SignalA;
	public var onInactive:SignalA;
	public var value(get, never):Bool;
	
	var currentCase:ICase;

	public function new() 
	{
		//bitOperator = BitOperator.AND;
		onActive = new SignalA(active, true);
		onInactive = new SignalA(active, false);
		active.add(() -> {
			if (active.value) onActive.dispatch();
			else onInactive.dispatch();
		});
	}
	
	public function add(notifier:Notifier<Dynamic>, ?operation:Operation=EQUAL, targetValue:Dynamic=true, subProp:String=null, wildcard:Bool=false):Condition 
	{
		if (!Operation.valid(operation) && targetValue == true) {
			// In the case that the targetValue is a string and the operation is not 
			// omitted then the targetValue will incorrectly be set into the operation
			targetValue = operation;
			operation = EQUAL;
		}
		
		_add(new Case(notifier, operation, targetValue, subProp, wildcard));
		return this;
	}

	public function addFunc(notifier:NotifierOrArray, checkFunction:Function):Condition 
	{
		_add(new FuncCase(notifier, checkFunction));
		return this;
	}

	function _add(_case:ICase)
	{
		currentCase = _case;
		#if notifier
			currentCase.add(onConditionChange, 1000);
		#else
			currentCase.change.add(onConditionChange, 1000);
		#end
		cases.push(currentCase);
		check();
	}

	public function remove(notifier:Notifier<Dynamic>, ?operation:Operation=null, targetValue:Dynamic=null, subProp:String=null, wildcard:Bool=false):Condition 
	{
		var i:Int = cases.length - 1;
		while (i >= 0) 
		{
			if (Std.is(cases[i], Case)){
				var _case:Case = untyped cases[i];
				if (_case.match(notifier, targetValue, operation, subProp, wildcard)){
					#if notifier
						_case.remove(onConditionChange);
					#else
						_case.change.remove(onConditionChange);
					#end
					cases.splice(i, 1);
				}
			}
			i--;
		}
		return this;
	}
	
	

	public function removeFunc(?notifier:NotifierOrArray, checkFunction:Function):Condition 
	{
		var i:Int = cases.length - 1;
		while (i >= 0) 
		{
			if (Std.is(cases[i], FuncCase)){
				var _case:FuncCase = untyped cases[i];
				if (_case.match(notifier, checkFunction)){
					#if notifier
						_case.remove(onConditionChange);
					#else
						_case.change.remove(onConditionChange);
					#end
					cases.splice(i, 1);
				}
			}
			i--;
		}
		return this;
	}

	public function and(priority:Int=0):Condition
	{
		if (currentCase != null) currentCase.bitOperator = BitOperator.AND;
		return this;
	}
	
	public function or(priority:Int=0):Condition
	{
		if (currentCase != null) currentCase.bitOperator = BitOperator.OR;
		return this;
	}
	
	public function xor(priority:Int=0):Condition
	{
		if (currentCase != null) currentCase.bitOperator = BitOperator.XOR;
		return this;
	}
	
	public function check(forceDispatch:Bool = false):Bool
	{
		for (i in 0...cases.length) 
		{
			cases[i].check(forceDispatch);
		}
		
		onConditionChange();
		if (forceDispatch) active.dispatch();
		return active.value;
	}
	
	function onConditionChange() 
	{
		active.value = checkWithPolicy(cases);
	}
	
	function checkWithPolicy(cases:Array<ICase>) 
	{
		var bitOperator = BitOperator.AND;
		var _value:Bool = true;
		for (i in 0...cases.length) 
		{
			var caseValue:Bool = cases[i].check();
			if (bitOperator == BitOperator.AND)			_value = _value && caseValue;
			else if (bitOperator == BitOperator.OR)		_value = _value || caseValue;
			else if (bitOperator == BitOperator.XOR)	_value = (_value && !caseValue) || (!_value && caseValue);
			bitOperator = cases[i].bitOperator;
		}
		return _value;
	}

	public function dispose():Void
	{
		var i:Int = cases.length - 1;
		while (i >= 0) 
		{
			#if notifier
				cases[i].remove(onConditionChange);
			#else
				cases[i].change.remove(onConditionChange);
			#end
			i--;
		}
		cases.splice(0, cases.length);
	}
	
	public function clone():Condition
	{
		var _clone:Condition = new Condition();
		for (i in 0...cases.length) {
			if (Std.is(cases[i], Case)){
				var _case:Case = untyped cases[i];
				_clone.add(_case.notifier, _case.targetValue, _case.operation, _case.subProp, _case.wildcard);
				if (_case.bitOperator == BitOperator.AND) _clone.and();
				else if (_case.bitOperator == BitOperator.OR) _clone.or();
				else if (_case.bitOperator == BitOperator.XOR) _clone.xor();
			}
			
			
		}
		_clone.check();
		return _clone;
	}
	
	function toString():String
	{
		var s:String = "(";
		for (i in 0...cases.length) {
			s += cases[i];
			if (i < cases.length-1) s += " " + cases[i].bitOperator + " ";
		}
		s += ") :: value = " + value;
		return s;
	}

	function get_value():Bool
	{
		return active.value;
	}
}

#if notifier
class Case extends Notifier<Bool> implements ICase
#else
class Case extends BaseNotifier<Bool> implements ICase
#end
{
	public var notifier:Notifier<Dynamic>;
	public var operation:Operation;
	public var subProp:String;
	public var wildcard:Bool;
	public var bitOperator = BitOperator.AND;
	
	var targetIsFunction:Bool;
	var testValue(get, null):Dynamic;
	
	public var targetValue(get, null):Dynamic;
	var _targetValue:Dynamic;
	var _targetFunction:Void -> Dynamic;

	var getValue:Dynamic -> Dynamic -> Bool;

	public function new(notifier:Notifier<Dynamic>, ?operation:Operation=EQUAL, _targetValue:Dynamic, subProp:String=null, wildcard:Bool=false) 
	{
		this.operation = operation;
		
		targetIsFunction = Reflect.isFunction(_targetValue);
		if (targetIsFunction) _targetFunction = _targetValue;
		else this._targetValue = _targetValue;

		this.notifier = notifier;
		this.subProp = subProp;
		
		switch (operation) 
		{
			case Operation.EQUAL: 
				if (wildcard) 						getValue = wildcardEqualTo;
				else								getValue = equalTo;
			case Operation.NOT_EQUAL:				getValue = notEqualTo;
			case Operation.LESS_THAN_OR_EQUAL:		getValue = lessThanOrEqualTo;
			case Operation.LESS_THAN:				getValue = lessThan;
			case Operation.GREATER_THAN_OR_EQUAL:	getValue = greaterThanOrEqualTo;
			case Operation.GREATER_THAN:			getValue = greaterThan;
			default:
		}
		
		super();

		notifier.add(() -> {
			check();
		}, 1000);
		check();
	}

	function get_targetValue():Dynamic
	{
		if (targetIsFunction) return _targetFunction();
		else return _targetValue;
	}
	
	public function check(forceDispatch:Bool = false):Bool
	{
		if (targetIsFunction) this.value = _targetFunction();
		else this.value = getValue(testValue, targetValue);
		
		if (forceDispatch) this.dispatch();
		return this.value;
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
	
	function wildcardEqualTo(value1:Dynamic, value2:Dynamic) 
	{	
		if (value1 == null) value1 = "";
		if (value2 == null) value2 = "";
		return value1.indexOf(value2) != -1;
	}

	function equalTo(value1:Dynamic, value2:Dynamic)				{	return value1 == value2; }
	function notEqualTo(value1:Dynamic, value2:Dynamic)				{	return value1 != value2; }
	function lessThanOrEqualTo(value1:Dynamic, value2:Dynamic)		{	return value1 <= value2; }
	function lessThan(value1:Dynamic, value2:Dynamic) 				{	return value1 <  value2; }
	function greaterThanOrEqualTo(value1:Dynamic, value2:Dynamic)	{	return value1 >= value2; }
	function greaterThan(value1:Dynamic, value2:Dynamic)			{	return value1 >  value2; }

	override function toString():String
	{
		return testValue + " " + operation + " " + targetValue;
		//return "[Case] " + testValue + " " + operation + " " + targetValue + " | " + value + " | " + (testValue == targetValue);
	}

	public function match(notifier:Notifier<Dynamic>, targetValue:Dynamic=null, ?operation:Operation=null, subProp:String=null, wildcard:Bool=false):Bool
	{
		if (this.notifier != notifier) return false;
		if (this.targetValue != targetValue && targetValue != null) return false;
		if (this.operation != operation && operation != null) return false;
		if (this.subProp != subProp && subProp != null) return false;
		if (this.wildcard != wildcard) return false;
		return true;
	}

	public function clone():Case
	{
		var _clone:Case = new Case(notifier, operation, _targetValue, subProp);
		_clone._targetFunction = _targetFunction;
		_clone.targetIsFunction = targetIsFunction;
		return _clone;
	}
}
#if notifier
class FuncCase extends Notifier<Bool> implements ICase
#else
class FuncCase extends BaseNotifier<Bool> implements ICase
#end
{
	public var bitOperator = BitOperator.AND;
	var notifiers:Array<Notifier<Dynamic>>;
	var checkFunction:Function;
	var isArray:Bool;
	var values:Array<Dynamic> = [];

	public function new(value:NotifierOrArray, checkFunction:Function)
	{
		super();
		
		this.checkFunction = checkFunction;
		
		if (Std.is(value, Array)){
			this.notifiers = value;
			isArray = true;
		} else {
			notifiers = [cast (value, Notifier<Dynamic>)];
			isArray = false;
		}

		for (i in 0...notifiers.length){
			values.push(notifiers[i].value);
			notifiers[i].add(() -> { check(); }, 1000);
		}
		
		check();
	}

	public function match(value:NotifierOrArray, checkFunction:Function):Bool
	{
		if (value != null){
			if (isArray){
				var _notifiers:Array<Notifier<Dynamic>> = value;
				var matchCount:Int = 0;
				for (i in 0..._notifiers.length){
					for (j in 0...notifiers.length){
						if (_notifiers[i] == notifiers[j]) matchCount++;
					}
				}
				if (matchCount != notifiers.length) return false;
			} else {
				if (notifiers[0] != value) return false;
			}
		}
		if (this.checkFunction != checkFunction && checkFunction != null) return false;
		return true;
	}

	public function check(forceDispatch:Bool = false):Bool
	{
		for (i in 0...notifiers.length) values[i] = notifiers[i].value;
		this.value = FunctionUtil.dispatch(checkFunction, values);
		return this.value;
	}
}

interface ICase
{
	var bitOperator:BitOperator;
	function check(forceDispatch:Bool = false):Bool;
	
	#if notifier
		function add(callback:Void -> Void, ?fireOnce:Bool=false, ?priority:Int = 0, ?fireOnAdd:Null<Bool> = null):Void;
		function remove(callback:EitherType<Bool, Void -> Void>=false):Void;
	#else
		var change:Signal0;
	#end
}

class SignalA extends Signal
{
	var active:Notifier<Bool>;
	var target:Bool;

	public function new(active:Notifier<Bool>, target:Bool)
	{
		super();
		this.active = active;
		this.target = target;
	}

	override public function add(callback:Void -> Void, ?fireOnce:Bool=false, ?priority:Int = 0, ?fireOnAdd:Null<Bool> = null):Void
	{
		callbacks.push({
			callback:callback,
			callCount:0,
			fireOnce:fireOnce,
			priority:priority,
			remove:false
		});
		if (priority != 0) priorityUsed = true;
		if (priorityUsed == true) requiresSort = true;
		
		if (active.value == target) callback();
	}
}

typedef NotifierOrArray = EitherType<Notifier<Dynamic>, Array<Notifier<Dynamic>>>;
