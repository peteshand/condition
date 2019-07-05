package condition;

import notifier.Notifier;
import signal.Signal;
import haxe.extern.EitherType;
import haxe.Timer;
import utils.FunctionUtil;
import haxe.Constraints.Function;
import condition.modifier.DefaultModifier;
import condition.modifier.IModifier;

/**
 * ...
 * @author P.J.Shand
 */
@:access(condition.Operation)
@:access(condition.Condition.Case)
class Condition {
	var cases:Array<ICase> = [];

	public var numCases(get, never):Int;
	public var active = new Notifier<Bool>(true);
	public var onActive:SignalA;
	public var onInactive:SignalA;
	public var value(get, never):Bool;

	var currentCase:ICase;

	public var activeDelay:Float = 0;
	public var inactiveDelay:Float = 0;

	var timer:Timer;

	public function new(?activeCallback:() -> Void, ?inactiveCallback:() -> Void) {
		onActive = new SignalA(active, true);
		onInactive = new SignalA(active, false);
		if (activeCallback != null)
			onActive.add(activeCallback);
		if (inactiveCallback != null)
			onInactive.add(inactiveCallback);
		active.add(() -> {
			if (active.value)
				onActive.dispatch();
			else
				onInactive.dispatch();
		});
	}

	public function add(notifier:Notifier<Dynamic>, ?operation:Operation = EQUAL, targetValue:Dynamic = null, subProp:String = null,
			wildcard:Bool = false, modifier:IModifier = null):Condition {
		#if debug
		if (!Operation.valid(operation)) {
			trace("invalid");
		}
		#end
		if (!Operation.valid(operation) /*&& targetValue == true*/) {
			// In the case that the targetValue is a string and the operation is omitted
			// then the targetValue will incorrectly be set into the operation
			targetValue = operation;
			operation = EQUAL;
		}

		_add(new Case(notifier, operation, targetValue, subProp, wildcard, modifier));
		return this;
	}

	public function addFunc(notifier:NotifierOrArray, checkFunction:Function, modifier:IModifier = null):Condition {
		_add(new FuncCase(notifier, checkFunction, modifier));
		return this;
	}

	function _add(_case:ICase) {
		currentCase = _case;
		currentCase.add(onConditionChange, 1000);
		cases.push(currentCase);
		check();
	}

	public function remove(notifier:Notifier<Dynamic>, ?operation:Operation = null, targetValue:Dynamic = true, subProp:String = null,
			wildcard:Bool = false):Condition {
		var i:Int = cases.length - 1;
		while (i >= 0) {
			if (Std.is(cases[i], Case)) {
				var _case:Case = untyped cases[i];
				if (_case.match(notifier, targetValue, operation, subProp, wildcard)) {
					_case.remove(onConditionChange);
					cases.splice(i, 1);
				}
			}
			i--;
		}
		return this;
	}

	public function removeAll():Condition {
		var i:Int = cases.length - 1;
		while (i >= 0) {
			if (Std.is(cases[i], Case)) {
				var _case:Case = untyped cases[i];
				_case.remove(onConditionChange);
				cases.splice(i, 1);
			}
			i--;
		}
		return this;
	}

	public function removeFunc(?notifier:NotifierOrArray, checkFunction:Function):Condition {
		var i:Int = cases.length - 1;
		while (i >= 0) {
			if (Std.is(cases[i], FuncCase)) {
				var _case:FuncCase = untyped cases[i];
				if (_case.match(notifier, checkFunction)) {
					_case.remove(onConditionChange);
					cases.splice(i, 1);
				}
			}
			i--;
		}
		return this;
	}

	public function and(priority:Int = 0):Condition {
		if (currentCase != null)
			currentCase.bitOperator = BitOperator.AND;
		return this;
	}

	public function or(priority:Int = 0):Condition {
		if (currentCase != null)
			currentCase.bitOperator = BitOperator.OR;
		return this;
	}

	public function xor(priority:Int = 0):Condition {
		if (currentCase != null)
			currentCase.bitOperator = BitOperator.XOR;
		return this;
	}

	public function check(forceDispatch:Bool = false):Bool {
		for (i in 0...cases.length) {
			cases[i].check(forceDispatch);
		}

		onConditionChange();
		if (forceDispatch)
			active.dispatch();
		return active.value;
	}

	function onConditionChange() {
		var value:Bool = checkWithPolicy(cases);
		var delay:Float = inactiveDelay;
		if (value)
			delay = activeDelay;

		if (timer != null) {
			timer.stop();
			timer = null;
		}
		if (delay == 0)
			active.value = value;
		else
			timer = Timer.delay(() -> {
				active.value = value;
			}, Math.floor(delay * 1000));
	}

	function checkWithPolicy(cases:Array<ICase>) {
		var bitOperator = BitOperator.AND;
		var _value:Bool = true;
		for (i in 0...cases.length) {
			cases[i].check();
			var caseValue:Bool = cases[i].value;
			if (bitOperator == BitOperator.AND)
				_value = _value && caseValue;
			else if (bitOperator == BitOperator.OR)
				_value = _value || caseValue;
			else if (bitOperator == BitOperator.XOR)
				_value = (_value && !caseValue) || (!_value && caseValue);
			bitOperator = cases[i].bitOperator;
		}
		return _value;
	}

	public function dispose():Void {
		var i:Int = cases.length - 1;
		while (i >= 0) {
			cases[i].remove(onConditionChange);
			i--;
		}
		cases.splice(0, cases.length);
	}

	public function clone() {
		var _clone = new Condition();
		copyCases(this, _clone);
		_clone.check();
		return _clone;
	}

	function copyCases(from:Condition, to:Condition, startIndex:Int=0) {
		for (i in startIndex...from.cases.length) {
			var _icase:ICase = null;
			if (Std.is(from.cases[i], Case)) {
				var _case:Case = untyped _icase = from.cases[i];
				to.add(_case.notifier, _case.operation, _case._targetValue, _case.subProp, _case.wildcard);
			} else if (Std.is(from.cases[i], FuncCase)) {
				var _case:FuncCase = untyped _icase = from.cases[i];
				to.addFunc(_case.notifiers, _case.checkFunction);
			}
			if (_icase.bitOperator == BitOperator.AND)
				to.and();
			else if (_icase.bitOperator == BitOperator.OR)
				to.or();
			else if (_icase.bitOperator == BitOperator.XOR)
				to.xor();
		}
	}

	function toString():String {
		var s:String = "(";
		for (i in 0...cases.length) {
			cases[i].check();
			s += cases[i];
			if (i < cases.length - 1)
				s += " " + cases[i].bitOperator + " ";
		}
		s += ") :: value = " + check();
		return s;
	}

	function get_value():Bool {
		return active.value;
	}

	function get_numCases():Int {
		return cases.length;
	}
}

class Case extends Notifier<Bool> implements ICase {
	static var defaultModifier = new DefaultModifier();
	public var notifier:Notifier<Dynamic>;
	public var operation:Operation;
	public var subProp:String;
	public var wildcard:Bool;
	public var bitOperator = BitOperator.AND;
	public var modifier:IModifier;

	var targetIsFunction:Bool;
	var testValue(get, null):Dynamic;

	public var targetValue(get, null):Dynamic;

	public var _targetValue:Dynamic;
	var _targetFunction:Void->Dynamic;
	var getValue:Dynamic->Dynamic->Bool;
	
	public function new(notifier:Notifier<Dynamic>, ?operation:Operation = EQUAL, _targetValue:Dynamic, subProp:String = null, wildcard:Bool = false, _modifier:IModifier = null) {
		this.operation = operation;
		this.wildcard = wildcard;

		if (_modifier != null){
			modifier = _modifier;
		} else {
			modifier = defaultModifier;
		}

		this._targetValue = _targetValue;
		targetIsFunction = Reflect.isFunction(_targetValue);
		if (targetIsFunction)
			_targetFunction = _targetValue;
			

		this.notifier = notifier;
		this.subProp = subProp;

		switch (operation) {
			case Operation.EQUAL:
				if (wildcard)
					getValue = wildcardEqualTo;
				else
					getValue = equalTo;
			case Operation.NOT_EQUAL:
				getValue = notEqualTo;
			case Operation.LESS_THAN_OR_EQUAL:
				getValue = lessThanOrEqualTo;
			case Operation.LESS_THAN:
				getValue = lessThan;
			case Operation.GREATER_THAN_OR_EQUAL:
				getValue = greaterThanOrEqualTo;
			case Operation.GREATER_THAN:
				getValue = greaterThan;
			default:
		}

		super();

		notifier.add(() -> {
			check();
		}, 1000);
		check();
	}

	function get_targetValue():Dynamic {
		if (targetIsFunction)
			return _targetFunction();
		else
			return _targetValue;
	}

	public function check(forceDispatch:Bool = false):Void {
		if (targetIsFunction)
			//this.value = _targetFunction();
			modifier.setValue(_targetFunction(), forceDispatch, onModChange);
		else
			//this.value = getValue(testValue, targetValue);
			modifier.setValue(getValue(testValue, targetValue), forceDispatch, onModChange);

		//if (forceDispatch)
		//	this.dispatch();
		//return this.value;
	}

	function onModChange(value:Bool, forceDispatch:Bool)
	{
		this.value = modifier.value;
		if (forceDispatch)
			this.dispatch();
	}

	function get_testValue() {
		if (subProp == null) {
			return notifier.value;
		}
		else {
			var split:Array<String> = subProp.split(".");
			if (subProp.indexOf(".") == -1)
				split = [subProp];

			var value:Dynamic = notifier.value;
			while (split.length > 0 && value != null) {
				var prop:String = split.shift();
				value = Reflect.getProperty(value, prop);
			}

			return value;
		}
	}

	function wildcardEqualTo(value1:Dynamic, value2:Dynamic) {
		if (value1 == null)
			value1 = "";
		if (value2 == null)
			value2 = "";
		return value1.indexOf(value2) != -1;
	}

	function equalTo(value1:Dynamic, value2:Dynamic) {
		return value1 == value2;
	}

	function notEqualTo(value1:Dynamic, value2:Dynamic) {
		return value1 != value2;
	}

	function lessThanOrEqualTo(value1:Dynamic, value2:Dynamic) {
		return value1 <= value2;
	}

	function lessThan(value1:Dynamic, value2:Dynamic) {
		return value1 < value2;
	}

	function greaterThanOrEqualTo(value1:Dynamic, value2:Dynamic) {
		return value1 >= value2;
	}

	function greaterThan(value1:Dynamic, value2:Dynamic) {
		return value1 > value2;
	}

	override function toString():String {
		if (wildcard)
			return testValue + " " + operation + " " + targetValue + "*  = " + getValue(testValue, targetValue);
		else
			return testValue + " " + operation + " " + targetValue + " = " + getValue(testValue, targetValue);
		// return "[Case] " + testValue + " " + operation + " " + targetValue + " | " + value + " | " + (testValue == targetValue);
	}

	public function match(notifier:Notifier<Dynamic>, targetValue:Dynamic = null, ?operation:Operation = null, subProp:String = null,
			wildcard:Bool = false):Bool {
		if (this.notifier != notifier)
			return false;
		if (this.targetValue != targetValue && targetValue != null)
			return false;
		if (this.operation != operation && operation != null)
			return false;
		if (this.subProp != subProp && subProp != null)
			return false;
		if (this.wildcard != wildcard)
			return false;
		return true;
	}

	public function clone():Case {
		var _clone:Case = new Case(notifier, operation, _targetValue, subProp);
		_clone._targetFunction = _targetFunction;
		_clone.targetIsFunction = targetIsFunction;
		return _clone;
	}
}

class FuncCase extends Notifier<Bool> implements ICase {
	static var defaultModifier = new DefaultModifier();
	public var bitOperator = BitOperator.AND;
	public var notifiers:Array<Notifier<Dynamic>>;
	public var checkFunction:Function;
	public var modifier:IModifier;

	var isArray:Bool;
	var values:Array<Dynamic> = [];

	public function new(value:NotifierOrArray, checkFunction:Function, _modifier:IModifier = null) {
		super();
		
		this.checkFunction = checkFunction;
		if (_modifier != null){
			modifier = _modifier;
		} else {
			modifier = defaultModifier;
		}

		if (Std.is(value, Array)) {
			this.notifiers = value;
			isArray = true;
		} else {
			notifiers = [cast(value, Notifier<Dynamic>)];
			isArray = false;
		}

		for (i in 0...notifiers.length) {
			values.push(notifiers[i].value);
			notifiers[i].add(() -> {
				check();
			}, 1000);
		}

		check();
	}

	public function match(value:NotifierOrArray, checkFunction:Function):Bool {
		if (value != null) {
			if (isArray) {
				var _notifiers:Array<Notifier<Dynamic>> = value;
				var matchCount:Int = 0;
				for (i in 0..._notifiers.length) {
					for (j in 0...notifiers.length) {
						if (_notifiers[i] == notifiers[j])
							matchCount++;
					}
				}
				if (matchCount != notifiers.length)
					return false;
			} else {
				if (notifiers[0] != value)
					return false;
			}
		}
		if (this.checkFunction != checkFunction && checkFunction != null)
			return false;
		return true;
	}

	public function check(forceDispatch:Bool = false):Void {
		for (i in 0...notifiers.length)
			values[i] = notifiers[i].value;
		//this.value = FunctionUtil.dispatch(checkFunction, values);
		modifier.setValue(FunctionUtil.dispatch(checkFunction, values), forceDispatch, onModChange);
		//return modifier.value;
	}

	function onModChange(value:Bool, forceDispatch:Bool)
	{
		this.value = modifier.value;
		if (forceDispatch)
			this.dispatch();
	}
}

interface ICase {
	var bitOperator:BitOperator;
	var value(get, set):Null<Bool>;
	function check(forceDispatch:Bool = false):Void;
	function add(callback:Void->Void, ?fireOnce:Bool = false, ?priority:Int = 0, ?fireOnAdd:Null<Bool> = null):Void;
	function remove(callback:EitherType<Bool, Void->Void> = false):Void;
}

class SignalA extends Signal {
	var active:Notifier<Bool>;
	var target:Bool;

	public function new(active:Notifier<Bool>, target:Bool) {
		super();
		this.active = active;
		this.target = target;
	}

	override public function add(callback:Void->Void, ?fireOnce:Bool = false, ?priority:Int = 0, ?fireOnAdd:Null<Bool> = null):Void {
		callbacks.push({
			callback: callback,
			callCount: 0,
			fireOnce: fireOnce,
			priority: priority,
			remove: false
		});
		if (priority != 0)
			priorityUsed = true;
		if (priorityUsed == true)
			requiresSort = true;

		if (active.value == target)
			callback();
	}
}

typedef NotifierOrArray = EitherType<Notifier<Dynamic>, Array<Notifier<Dynamic>>>;
