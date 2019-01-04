package condition;

import notifier.Notifier;
import signal.Signal;

/**
 * ...
 * @author P.J.Shand
 */
interface IState
{
	public var conditionPolicy:ConditionPolicy;
	public var value(get, set):Null<Bool>;
	public var onActive:Signal;
	public var onInactive:Signal;
	public function addURI(uri:String, wildcard:Bool=false):Void;
	public function addURIMask(uri:String, wildcard:Bool=false):Void;
	public function removeURI(uri:String):Void;
	public function removeURIMask(uri:String):Void;
	public function addCondition(notifier:Notifier<Dynamic>, value:Dynamic, operation:String = "==", subProp:String=null):Void;
	public function removeCondition(notifier:Notifier<Dynamic>, value:Dynamic = null, operation:String = null):Void;
	public function check(forceDispatch:Bool = false):Bool;
	public function dispose():Void;
	public function clone():State;
}