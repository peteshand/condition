package condition;

class State {

    static var map:Map<String,Condition>;
	static var states:Dynamic;

    public static function __init__()
    {
        map = new Map<String,Condition>();
        #if html5
            states = {};
            Reflect.setProperty(js.Browser.window, 'states', states);
        #end
    }

	public static function get(field:String):Condition {
		var condition = map.get(field);
        if (condition == null){
            condition = new Condition();
            map.set(field, condition);
            #if html5
                Reflect.setProperty(states, field, condition);
            #end
        }
        return condition;
	}
}