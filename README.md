The aim of the Condition library is to offer a way of defining Conditions and trigger a response in a compact manner.

Condition objects are based on / extend Notifiers (You can read more about notifiers [here](https://github.com/peteshand/notifier)).

A Condition object is a Notifier<Bool> who's value is set internally set based on if a defined condition is true or not.

## Simple example

Let's say we have a Notifier object that represents the number of minutes that have past since the start of a football game.

```
var minutes = new Notifier<Int>(0);
```

And let's assume that every minute this value increments by one. 

```
minutes.value++;
```

If we want to know when the game has finished we need to check when the value is greater than or equal to 90. This can be done as follows:

```
minutes.add(() -> {
	if (minutes.value >= 90){
		trace("the game is over");
	}
});
```

The same can be achieved by using a Condition object. 

```
var condition = new Condition(minutes, 90, ">=");

condition.add(() -> {
	if (condition.value){
		trace("the game is over");
	}
});
```

For more complex conditions the State class can be used, which can essentially be thought of as a group of Conditions.

Now let's add a new Notifier that defines if a penalty shootout is happening and then add this to the state.

```
var penaltyShootout = new Notifier<Bool>(false);

var state = new State();
state.addCondition(minutes, 90, ">=");
state.addCondition(penaltyShootout, false, "==");
state.onActive.add(onActive);
state.onInactive.add(onInactive);
if (state.value) onActive();

function onActive()
{
	trace("the game is over");
}

function onInactive()
{
	trace("the game is being played");
}
```
