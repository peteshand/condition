The aim of this library is to offer a way to encapsulate conditions within a portable object. The Condition object allows easy separation of logic and data within applications and will trigger active / inactive signals when it's state changes.

Conditions heavily rely on [Notifiers](https://github.com/peteshand/notifier), so if you're not already familiar with them head over to the github [README](https://github.com/peteshand/notifier) to find out more. 

A Condition consists of one or more conditional operators statements.

##Simply Example
```
var notifier = new Notifier<Int>(0);

var condition = new Condition();
condition.add(notifier, "==", 1); // currently not true
```

There is a onActive and onInactive signal within the condition. Subscribing to these will trigger a callback whenever the condition's state changes to true or false respectively. Additionally when subscribing to onActive and onInactive the callback will be called immediately if the state corresponds to the signal, in the case of this example the onInactive callback will be triggered because notifier.value != 1.

```
condition.onActive.add(() -> {
	trace("This is be triggered when notifier.value == 1");
});
condition.onInactive.add(() -> {
	trace("This is be triggered when notifier.value != 1");
});

notifier.value = 1; // this will trigger the onActive callback because notifier.value == 1
```

The above is equivalent to the following:

```
@:isVar var value(default, set):Int = 0;
var targetValue:Int = 1;

public function new()
{
	this.value = 1;
}

function set_value(v:Int):Int
{
	if (this.value = v) return v;
	if (v == targetValue){
		trace("This is be triggered when notifier.value == 1");
	} else {
		trace("This is be triggered when notifier.value != 1");
	}
	this.value = v;
}
```

While with a simple case there isn't a huge different in the amount of code involved, the "Condition" approach allows for portability of the statement and as more complex cases are required the difference in the amount of required code and readability becomes more obvious.

###Arguments
There are 5 arguments in the add function.

```
add(notifier:Notifier<Dynamic>, operation:Operation="==", targetValue:Dynamic=true, subProp:String=null, wildcard:Bool=false):Condition
```
* notifier:Notifier\<Dynamic> (**mandatory**), When the notifiers value property is set this will trigger a check of if the Condition is active or inactive.
* operation:Operation (**optional, default: ==**). This is the comparison operator to use on the condition statement, eg: "notifier.value == true". Available options are: 
  * **==** 
  * **!=**
  * **<=**
  * **<**
  * **>=**
  * **>**
* targetValue:Dynamic (**optional, default: true**). This is the target value for the notifier
* subProp:String (**optional, default: null**). This can be used to check the value of a subProperty of a notifier's value object. Example below:
* wildcard:Bool (**optional, default: false**). This is only used when the Notifier is of type Notifier\<String>. When set to true only a partial match is required. Example below.

##SubProp Example
```
typedef Data = { example:String }
var data = new Notifier<Data>;
var condition = new Condition();
condition.add(data, "==", "foo", "example");
condition.onActive.add(() -> {
	trace("This is be triggered when notifier.value is set and it's sub property data.example == 'foo'");
});
data.value = { example:"test" }; // this will not trigger onActive;
data.value = { example:"foo" }; // this will trigger onActive;

// equivalent to: /////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////

@:isVar var value(default, set):Data = 0;
var targetValue:String = "foo";

public function new()
{
	this.value = { example:"foo" };
}

function set_value(v:Data):Data
{
	if (this.value = v) return v;
	if (v.example == targetValue){
		trace("This is be triggered when v.example == foo");
	} else {
		trace("This is be triggered when v.example != foo");
	}
	this.value = v;
}

```

##Wildcard Example
```
var rout = new Notifier<String>();

var condition = new Condition();
condition.add(rout, "app://main", "==", true);
condition.onActive.add(() -> {
	trace("This is be triggered when rout.value contains "app://main");
});
condition.onInactive.add(() -> {
	trace("This is be triggered when rout.value does not contain "app://main");
});
rout.value = "app://main/page1"; // active
```

##Multiple Notifiers Example

It's possible to add multiple cases into a single Condition. By default all cases will need to be true before the condition will triggers it's onActive signal. You can override the default && by calling or condition.or(), or condition.xor() between add calls. Precedence is the same as Haxe defaults, (**||, && and ^ have the same precedence in Haxe, so they will be always grouped from left-to-right**).

```
var notifier1 = new Notifier<Int>(0);
var notifier2 = new Notifier<Int>(0);
var notifier3 = new Notifier<Int>(0);

var condition = new Condition();
condition.add(notifier1, 1, "==");
condition.or();
condition.add(notifier2, 1, "==");
condition.and();
condition.add(notifier3, 1, "==");

//equivalent to

if ((notifier1.value == 1 || notifier2.value == 1) && notifier3.value == 1){

}
```

##addFunc

For complex precedence it is recommended to use the addFunc method which has a slightly different signature to add and is a little more manual in the way that it works.

```
addFunc(notifier:Notifier<Dynamic> || Array<Notifier<Dynamic>>, checkFunction:Function):Condition
```

* notifier:Notifier\<Dynamic> or Array\<Notifier\<Dynamic>> (**mandatory**), When the notifiers value property is set this will trigger a check of if the Condition is active or inactive.
* checkFunction: Function (**mandatory**). This function will be called everytime the notifier/s value changes. The function expects the same numver of params as there are notifiers past to the notifier value and should return true or false depending on if the condition should be active or inactive.
eg:

```
if (value1 == true || ((value2 < 2 && value3 == 3) || value4 == false)) {
	return true;
}
```


```
var notifier1 = new Notifier<Bool>(0);
var notifier2 = new Notifier<Int>(0);
var notifier3 = new Notifier<Int>(0);
var notifier4 = new Notifier<Bool>(0);

var condition = new Condition();
condition.addFunc(
	[notifier1, notifier2, notifier3, notifier4], 
	(v1:Bool, v2:Int, v3:Int, v4:Bool) -> {
		return v1 == true || ((v2 < 2 && v3 == 3) || v4 == false);
	}
);
```

##Daisychaining

The majority of condition methods return this which allows for daisy chaining.

```
var notifier1 = new Notifier<Int>(0);
var notifier2 = new Notifier<Int>(0);

var condition = new Condition().add(notifier1, 1).or().add(notifier2, 1);
```

##Nesting Conditions within Conditions

TODO: add description