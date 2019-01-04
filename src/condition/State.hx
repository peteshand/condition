package condition;

import condition.SceneModel;
import notifier.Notifier;
import signal.Signal;

/**
 * ...
 * @author P.J.Shand
 */
class State extends Notifier<Bool> implements IState
{
	var sceneModel:Notifier<Dynamic>;
	public var standardConditions:Array<Condition> = [];
	public var sceneConditions:Array<SceneCondition> = [];
	
	public var onActive = new Signal();
	public var onInactive = new Signal();
	public var uris:Array<String> = [];
	public var conditionPolicy = ConditionPolicy.AND;
	
	public function new(_sceneModel:SceneModel=null) 
	{
		this.sceneModel = untyped _sceneModel;
		if (this.sceneModel == null) {
			this.sceneModel = untyped SceneModel.instance;
		}
		super();
		this.add(OnValueChange);
	}
	
	function OnValueChange() 
	{
		if (value) onActive.dispatch();
		else onInactive.dispatch();
	}
	
	public function addURI(uri:String, wildcard:Bool=false):Void 
	{
		addSceneCondition(sceneModel, uri, "==", wildcard);
	}
	
	public function addURIMask(uri:String, wildcard:Bool=false):Void 
	{
		addSceneCondition(sceneModel, uri, "!=", wildcard);	
	}
	
	public function removeURI(uri:String):Void
	{
		removeSceneCondition(sceneModel, uri);
	}
	
	public function removeURIMask(uri:String):Void
	{
		removeSceneCondition(sceneModel, uri, "!=");
	}

	inline function addSceneCondition(notifier:Notifier<Dynamic>, value:Dynamic, operation:String="==", wildcard:Bool=false):Void 
	{
		uris.push(value);
		mapCondition(new SceneCondition(notifier, value, operation, wildcard), untyped sceneConditions);
		check();
	}
	
	public function addCondition(notifier:Notifier<Dynamic>, value:Dynamic, operation:String="==", subProp:String=null):Void 
	{
		mapCondition(new Condition(notifier, value, operation, subProp), standardConditions);
		check();
	}
	
	inline function removeSceneCondition(notifier:Notifier<Dynamic>, value:Dynamic=null, operation:String=null):Void 
	{
		removeCondition2(untyped sceneConditions, notifier, value, operation);
	}

	public function removeCondition(notifier:Notifier<Dynamic>, value:Dynamic=null, operation:String=null):Void 
	{
		removeCondition2(standardConditions, notifier, value, operation);
	}

	inline function removeCondition2(consitions:Array<Condition>, notifier:Notifier<Dynamic>, value:Dynamic=null, operation:String=null):Void 
	{
		var i:Int = consitions.length - 1;
		while (i >= 0) 
		{
			if (consitions[i].notifier == notifier) {
				if (value == consitions[i].targetValue || value == null) {
					if (operation == consitions[i].operation  || operation == null){	
						consitions[i].remove(onConditionChange);
						consitions.splice(i, 1);
					}
				}
			}
			i--;
		}
	}
	
	public function check(forceDispatch:Bool = false):Bool
	{
		for (i in 0...standardConditions.length) 
		{
			standardConditions[i].check(forceDispatch);
		}
		for (i in 0...sceneConditions.length) 
		{
			sceneConditions[i].check(forceDispatch);
		}
		onConditionChange();
		if (forceDispatch) this.dispatch();
		return this.value;
	}
	
	function onConditionChange() 
	{
		var _value1:Bool = checkWithPolicy(standardConditions, conditionPolicy);
		var _value2:Bool = checkWithPolicy(untyped sceneConditions, ConditionPolicy.SCENE);
		this.value = _value1 && _value2;
	}
	
	function checkWithPolicy(consitions:Array<Condition>, conditionPolicy:ConditionPolicy) 
	{
		if (consitions.length == 0) return true;
		var _value:Bool;
		if (conditionPolicy == ConditionPolicy.AND) {
			_value = true;
			for (i in 0...consitions.length) 
			{
				consitions[i].check();
				if (consitions[i].value == false) {
					_value = false;
					break;
				}
			}
		}
		else {
			_value = false;
			for (i in 0...consitions.length) 
			{
				consitions[i].check();
				if (consitions[i].value == true) {
					_value = true;
					if (conditionPolicy == ConditionPolicy.OR) break;
				}
				
				if (conditionPolicy == ConditionPolicy.SCENE) {
					if (consitions[i].value == false && consitions[i].operation == "!=") {
						_value = false;
						break;
					}
				}
			}
		}
		return _value;
	}
	
	public function dispose():Void
	{
		var i:Int = standardConditions.length - 1;
		while (i >= 0) 
		{
			standardConditions[i].remove(onConditionChange);
			i--;
		}
		standardConditions.splice(0, standardConditions.length);
		
		var i:Int = sceneConditions.length - 1;
		while (i >= 0) 
		{
			sceneConditions[i].remove(onConditionChange);
			i--;
		}
		sceneConditions.splice(0, sceneConditions.length);
	}
	
	public function clone():State
	{
		var _clone:State = new State(untyped sceneModel);
		_clone.conditionPolicy = this.conditionPolicy;
		for (i in 0...standardConditions.length) {
			_clone.addCondition(standardConditions[i].notifier, standardConditions[i].targetValue, standardConditions[i].operation, standardConditions[i].subProp);
			
		}
		for (i in 0...sceneConditions.length) {
			_clone.addSceneCondition(sceneConditions[i].notifier, sceneConditions[i].targetValue, sceneConditions[i].operation, sceneConditions[i].wildcard);
		}
		_clone.check();
		return _clone;
	}
	
	function mapCondition(condition:Condition, _conditions:Array<Condition>):Void
	{
		condition.add(onConditionChange, 1000);
		_conditions.push(condition);
	}

	override function toString():String
	{
		var s:String = "\n";
		for (i in 0...standardConditions.length) {
			s += standardConditions[i] + "\n";
		}
		for (i in 0...sceneConditions.length) {
			s += sceneConditions[i] + "\n";
		}
		s += "conditionPolicy = " + conditionPolicy;
		return s;
	}
}