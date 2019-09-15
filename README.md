The aim of this library is to offer a way to encapsulate conditional statements within a portable object. The Condition object allows easy separation of logic and data within applications and will trigger active / inactive signals when it's state changes.

Conditions heavily rely on [Notifiers](https://github.com/peteshand/notifier), so if you're not already familiar with them head over to the github [README](https://github.com/peteshand/notifier) to find out more. 

A Condition consists of one or more conditional operator statements and is constructed via the static macro method `make`. the `make` method expects one or more binary operator operations with one or more notifiers being used within the operation/s. When any of the notifiers that was using within the operations the Condition will check the result of the binary operator operations and condition's `value` to true or false, and call onActive or onInactive accordingly.

##Simply Example
```
var notifier = new Notifier<Int>(0);

var condition = Condition.make(notifier.value == 1); // currently false as notifier.value == 0
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

Alternatively

```
condition.add((active:Bool) -> {
	if (active) trace("This is be triggered when notifier.value == 1");
	else trace("This is be triggered when notifier.value != 1");
});

notifier.value = 1; // this will trigger the callback with active == true
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

##Combining Conditions

The .or .and and .xor methods can be used to combine condition requirements.

```
var notifier1 = new Notifier<Int>(0);
var notifier2 = new Notifier<Int>(0);

var condition1 = Condition.make(notifier1.value == 1);
var condition2 = Condition.make(notifier2.value == 4);
condition1.or(condition2);

```

##Cloning

```
var condition1 = Condition.make(notifier1.value == 1);
var condition2 = condition1.clone();

```

##Multiple Notifiers Example

It's possible to add multiple cases into a single Condition. By default all cases will need to be true before the condition will triggers it's onActive signal. You can override the default && by calling or condition.or(), or condition.xor() between add calls. Precedence is the same as Haxe defaults, (**||, && and ^ have the same precedence in Haxe, so they will be always grouped from left-to-right**).

```
var notifier1 = new Notifier<Int>(0);
var notifier2 = new Notifier<Bool>(true);
var notifier3 = new Notifier<Int>(0);

var condition = Condition( (notifier1.value == 1 || notifier2.value == false) && notifier3.value == 0);
```
