package condition;

import notifier.Notifier;
import signal.Signal;
import haxe.extern.EitherType;
import haxe.Timer;
import haxe.macro.Expr;
import haxe.macro.Context;
import haxe.macro.Type.ClassType;

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
		var exprStr:String = expr.toString();

		var notifiers:Array<String> = [];
		var wrapped:Bool = findNotifiers(expr, notifiers, 0);

		if (!wrapped)
			exprStr = 'function() return $exprStr';

		// trace("notifiers = " + notifiers);
		// trace(exprStr);
		return untyped Context.parse('new Condition($notifiers, $exprStr)', Context.currentPos());
	}

	#if macro
	public static function findNotifiers(e:haxe.macro.Expr, props:Array<String>, level:Int) {
		if (e == null)
			return false;
		//
		//

		// trace("\n\n");
		// trace(e.expr);
		var nextLevel:Int = level + 1;
		switch (e.expr) {
			case EField(e, field):
				var type:haxe.macro.Type = Context.typeof(Context.parse(e.toString(), Context.currentPos()));
				if (isNotifier(type)) {
					props.push(e.toString());
				}
			case EConst(CIdent(s)):
				switch (s) {
					case 'null' | 'true' | 'false':
					default:
						// var type:haxe.macro.Type = Context.typeof(Context.parse(s, Context.currentPos()));
						// var classType:haxe.macro.Type.ClassType = type.getClass();
						// if (classType.module == 'notifier.Notifier') {
						//	props.push(s);
						// }

						try {
							var type:haxe.macro.Type = Context.typeof(Context.parse(s, Context.currentPos()));
							if (isNotifier(type)) {
								props.push(s);
							}
						} catch (e:Dynamic) {
							// trace(e);
						}
				}
			case EConst(CInt(s) | CFloat(s) | CString(s)):
			// ignore
			case EBinop(_, e1, e2):
				findNotifiers(e1, props, nextLevel);
				findNotifiers(e2, props, nextLevel);
			case EFunction(name, f):
				findNotifiers(f.expr, props, nextLevel);
				if (level == 0)
					return true;
			case EReturn(e):
				findNotifiers(e, props, nextLevel);
			case ECall(e, params):
				findNotifiers(e, props, nextLevel);
				for (expr in params) {
					findNotifiers(expr, props, nextLevel);
				}
			case EMeta(s, e):
				findNotifiers(e, props, nextLevel);
			case EIf(econd, eif, eelse):
				findNotifiers(econd, props, nextLevel);
				findNotifiers(eif, props, nextLevel);
				findNotifiers(eelse, props, nextLevel);
			case EBlock(exprs):
				for (expr in exprs) {
					// trace("1 expr: " + expr);
					findNotifiers(expr, props, nextLevel);
				}
			case EUnop(op, postFix, e):
				findNotifiers(e, props, nextLevel);
			case EVars(vars):
				for (_var in vars) {
					findNotifiers(_var.expr, props, nextLevel);
				}
			case EParenthesis(e):
				findNotifiers(e, props, nextLevel);
			case _:
				trace("unhandled: " + e.expr);
		}
		return false;
	}

	static function isNotifier(type:haxe.macro.Type) {
		switch (type) {
			case TInst(t, params):
				var classType:ClassType = type.getClass();
				return inherents(classType);
			case _:
				// ignore
		}
		return false;
	}

	static function inherents(classType:ClassType):Bool {
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
			for (notifier in notifiers) {
				addFunc(notifier, testFunc);
			}
		}

		check();
	}

	function addFunc(notifier:Notifier<Dynamic>, checkFunction:haxe.Constraints.Function /*, modifier:IModifier = null*/):Condition {
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
		for (i in 0...cases.length) {
			cases[i].check();
		}
		var _value:Bool = true;
		for (i in 0...cases.length) {
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
	public var bitOperator = BitOperator.AND;
	public var innerCheckFunction:haxe.Constraints.Function;
	public var checkFunction:haxe.Constraints.Function;

	var notifier:Notifier<Dynamic>;
	var condition:Condition;

	public var debug:String;

	public function new(notifier:Notifier<Dynamic>, checkFunction:haxe.Constraints.Function /*, _modifier:IModifier = null*/) {
		super();

		this.notifier = notifier;
		this.innerCheckFunction = checkFunction;

		if (Std.is(notifier, Condition)) {
			condition = untyped notifier;
		}

		this.checkFunction = () -> {
			if (condition != null) {
				condition.check();
			}
			innerCheckFunction();
		};

		notifier.add(() -> {
			check();
		}).priority(1000);

		check();
	}

	public function match(value:Notifier<Dynamic>, checkFunction:haxe.Constraints.Function):Bool {
		if (value != null) {
			if (notifier != value)
				return false;
		}
		if (this.innerCheckFunction != checkFunction && checkFunction != null)
			return false;
		return true;
	}

	public function check(forceDispatch:Bool = false):Void {
		this.value = checkFunction();
	}

	public function clone():Case {
		var newCase = new Case(notifier, innerCheckFunction /*, modifier*/);
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
