package condition;

import notifier.Notifier;

/**
 * @author P.J.Shand
 */
interface ICondition 
{
	public var notifier:Notifier<Dynamic>;
	public var targetValue:Dynamic;
	public var operation:String;
	public function check():Void;
	public function add(listener:Void -> Void):Void;
	public function remove(listener:Void -> Void):Void;
	public var value(get, set):Null<Bool>;
}