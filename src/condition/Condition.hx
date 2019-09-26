package condition;

import haxe.macro.MacroStringTools;
import notifier.Notifier;
import signal.Signal;
import haxe.extern.EitherType;
import haxe.Timer;
import utils.FunctionUtil;
// import condition.modifier.DefaultModifier;
// import condition.modifier.IModifier;
import haxe.macro.Expr;
import haxe.macro.Context;
import Type as RunTimeType;
import haxe.macro.Type.ClassType;
import location.Location;

// #if macro
using haxe.macro.Tools;

// #end

/**
 * ...
 * @author P.J.Shand
 */
@:access(condition.Condition)
@:access(condition.Condition.Case)
class Condition extends Notifier<Bool> {
	macro public static function make(expr:haxe.macro.Expr):haxe.macro.Expr {
		// trace(expr.toString());
		var notifiers:Array<String> = [];
		var wrapped:Bool = findNotifiers(expr, notifiers, 0);
		var exprStr:String = expr.toString();
		// trace("wrapped = " + wrapped);
		if (!wrapped)
			exprStr = 'function() return $exprStr';

		// trace("notifiers = " + notifiers);
		// trace(exprStr);

		return Context.parse('untyped new Condition($notifiers, $exprStr)', Context.currentPos());
	}

	#if macro
	public static function findNotifiers(e:haxe.macro.Expr, props:Array<String>, level:Int) {
		if (e == null)
			return false;
		// trace("---");
		// trace(e.expr);
		switch (e.expr) {
			case EField(e, field):
				// trace("1 EField");

				// trace(e.toString());

				var type:haxe.macro.Type = Context.typeof(Context.parse(e.toString(), Context.currentPos()));
				if (isNotifier(type)) {
					props.push(e.toString());
				}
			// findNotifiers(e, props, level + 1);
			case EConst(CIdent(s)):
				// trace("2 EConst");
				switch (s) {
					case 'null' | 'true' | 'false':
					default:
						// var type:haxe.macro.Type = Context.typeof(Context.parse(s, Context.currentPos()));
						// var classType:haxe.macro.Type.ClassType = type.getClass();
						// if (classType.module == 'notifier.Notifier') {
						//	props.push(s);
						// }

						var type:haxe.macro.Type = Context.typeof(Context.parse(s, Context.currentPos()));
						if (isNotifier(type)) {
							props.push(s);
						}
				}
			case EConst(CInt(s) | CFloat(s) | CString(s)):
			// ("3 EConst");
			// ignore
			case EBinop(_, e1, e2):
				// trace("4 EBinop");
				var nextLevel:Int = level + 1;
				findNotifiers(e1, props, nextLevel);
				findNotifiers(e2, props, nextLevel);
			case EFunction(name, f):
				// trace("5 EFunction");
				findNotifiers(f.expr, props, level + 1);
				// trace("5 EFunction B");
				if (level == 0)
					return true;
			case EReturn(e):
				// trace("6 EReturn");
				findNotifiers(e, props, level++);
			case ECall(e, params):
				// trace("7 ECall");
				findNotifiers(e, props, level++);
			case EMeta(s, e):
				// trace("8 EMeta");
				findNotifiers(e, props, level++);
			case EIf(econd, eif, eelse):
				// trace("9 EIf");
				findNotifiers(econd, props, level);
				findNotifiers(eif, props, level);
				findNotifiers(eelse, props, level);
				level++;
			case EBlock(exprs):
				// trace("10 EBlock");
				// Current not parsing EBlock
				// findNotifiers(expr, props, level++);
				for (expr in exprs) {
					// trace("1 expr: " + expr);
					findNotifiers(expr, props, level);
				}

			case EUnop(op, postFix, e):
				findNotifiers(e, props, level);
			case EVars(vars):
				for (_var in vars) {
					findNotifiers(_var.expr, props, level);
				}

			case _:
				trace("unhandled: " + e.expr);
		}
		return false;
	}

	static function isNotifier(type:haxe.macro.Type) {
		// trace('type = ' + type);
		switch (type) {
			case TMono(t): // t:Ref<Null<Type>>
			// trace("1 TMono");
			case TEnum(t, params): // t:Ref<EnumType>, params:Array<Type>
			// trace("2 TEnum");
			case TInst(t, params): // t:Ref<ClassType>, params:Array<Type>
				var classType:ClassType = type.getClass();
				// var module:String = classType.module;
				// if (module == 'notifier.Notifier') {
				//	return true;
				// }
				return inherents(classType);
			case TType(t, params): // t:Ref<DefType>, params:Array<Type>
			// trace("3 TType");
			case TFun(args, ret): // args:Array<{t:Type, opt:Bool, name:String}>, ret:Type
			// trace("4 TFun");
			case TAnonymous(a): // a:Ref<AnonType>
			// trace("5 TAnonymous");
			case TDynamic(t): // t:Null<Type>
			// trace("6 TDynamic");
			case TLazy(f): // f:Void ‑> Type
			// trace("7 TLazy");
			case TAbstract(t, params): // t:Ref<AbstractType>, params:Array<Type>
				// trace("8 TAbstract");
		}
		return false;
	}

	static function inherents(classType:ClassType):Bool {
		// trace("classType.module = " + classType.module);

		if (classType.module == 'notifier.Notifier') {
			return true;
		} else if (classType.superClass != null) {
			return inherents(classType.superClass.t.get());
		}
		return false;
	}
	#end

	var cases:Array<Case> = [];

	public var numCases(get, never):Int;
	public var onActive:SignalA;
	public var onInactive:SignalA;
	public var activeDelay:Float = 0;
	public var inactiveDelay:Float = 0;

	var currentCase:Case;
	var timer:Timer;

	public function new(notifiers:Array<Notifier<Dynamic>> = null, testFunc:Void->Bool = null) {
		super(true);

		onActive = new SignalA(this, true);
		onInactive = new SignalA(this, false);
		this.add(() -> {
			if (this.value)
				onActive.dispatch();
			else
				onInactive.dispatch();
		});

		if (notifiers != null && testFunc != null) {
			addFunc(notifiers, testFunc);
		}

		check();
	}

	function addFunc(notifier:NotifierOrArray, checkFunction:haxe.Constraints.Function /*, modifier:IModifier = null*/):Condition {
		_add(new Case(notifier, checkFunction /*, modifier*/));
		return this;
	}

	function _add(_case:Case) {
		currentCase = _case;
		currentCase.add(onConditionChange).priority(1000);
		cases.push(currentCase);
		check();
	}

	public function and(condition:Condition):Condition {
		if (currentCase != null)
			currentCase.bitOperator = BitOperator.AND;
		addFunc(condition, () -> return condition.value);
		return this;
	}

	public function or(condition:Condition):Condition {
		if (currentCase != null)
			currentCase.bitOperator = BitOperator.OR;
		addFunc(condition, () -> return condition.value);
		return this;
	}

	public function xor(condition:Condition):Condition {
		if (currentCase != null)
			currentCase.bitOperator = BitOperator.XOR;
		addFunc(condition, () -> return condition.value);
		return this;
	}

	public function check(forceDispatch:Bool = false):Bool {
		for (i in 0...cases.length) {
			cases[i].check(forceDispatch);
		}

		onConditionChange();
		if (forceDispatch)
			this.dispatch();
		return this.value;
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
			this.value = value;
		else
			timer = Timer.delay(() -> {
				this.value = value;
			}, Math.floor(delay * 1000));
	}

	function checkWithPolicy(cases:Array<Case>) {
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

	function copyCases(from:Condition, to:Condition) {
		for (i in 0...from.cases.length) {
			to._add(from.cases[i].clone());
		}
	}

	override public function toString():String {
		var s:String = "(";
		for (i in 0...cases.length) {
			cases[i].check();
			s += cases[i].toString();
			if (i < cases.length - 1)
				s += " " + cases[i].bitOperator + " ";
		}
		s += ") :: value = " + check();
		return s;
	}

	function get_numCases():Int {
		return cases.length;
	}
}

class Case extends Notifier<Bool> {
	// static var defaultModifier = new DefaultModifier();
	public var bitOperator = BitOperator.AND;
	public var notifiers:Array<Notifier<Dynamic>>;
	public var conditions:Array<Condition> = [];
	public var checkFunction:haxe.Constraints.Function;

	// public var modifier:IModifier;
	var notifier:NotifierOrArray;
	var isArray:Bool;
	var values:Array<Dynamic> = [];

	public var debug:String;

	public function new(notifier:NotifierOrArray, checkFunction:haxe.Constraints.Function /*, _modifier:IModifier = null*/) {
		super();

		this.notifier = notifier;
		this.checkFunction = checkFunction;
		/*if (_modifier != null) {
				modifier = _modifier;
			} else {
				modifier = defaultModifier;
		}*/

		if (Std.is(notifier, Array)) {
			this.notifiers = notifier;
			isArray = true;
		} else {
			notifiers = [cast(notifier, Notifier<Dynamic>)];
			isArray = false;
		}

		for (i in 0...notifiers.length) {
			if (Std.is(notifiers[i], Condition)) {
				conditions.push(untyped notifiers[i]);
			}
			values.push(notifiers[i].value);
			notifiers[i].add(() -> {
				check();
			}).priority(1000);
		}

		check();
	}

	public function match(value:NotifierOrArray, checkFunction:haxe.Constraints.Function):Bool {
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
		for (i in 0...conditions.length) {
			conditions[i].check();
		}
		this.value = checkFunction();
		/*if (debug != null) {
			trace("check: " + debug + " - " + this.value + " - " + Location.instance.uri);
		}*/
		/*
			for (i in 0...notifiers.length) {
				trace(notifiers[i].value);
				values[i] = notifiers[i].value;
			}
			modifier.setValue(FunctionUtil.dispatch(checkFunction, values), forceDispatch, onModChange); */
	}

	/*function onModChange(value:Bool, forceDispatch:Bool) {
		this.value = modifier.value;
		trace("onModChange: " + debug + " - " + this.value);
		if (forceDispatch)
			this.dispatch();
	}*/
	public function clone():Case {
		// trace(notifier == null);
		var newCase = new Case(notifier, checkFunction /*, modifier*/);
		newCase.bitOperator = bitOperator;
		return newCase;
	}

	override public function toString():String {
		return Std.string(checkFunction());
	}
}

class SignalA extends Signal {
	var active:Notifier<Bool>;
	var target:Bool;

	public function new(active:Notifier<Bool>, target:Bool) {
		super();
		this.active = active;
		this.target = target;
	}

	override public function add(callback:Void->Void, ?fireOnce:Bool = false, ?priority:Int = 0, ?fireOnAdd:Null<Bool> = null):Signal {
		super.add(callback, fireOnce, priority, fireOnAdd);

		if (active.value == target)
			callback();
		return this;
	}
}

typedef NotifierOrArray = EitherType<Notifier<Dynamic>, Array<Notifier<Dynamic>>>;
