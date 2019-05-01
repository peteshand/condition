package mantle.view;

import fuse.display.Sprite;
import condition.IConditionView;
import condition.Condition;
import transition.Transition;

class ConditionView extends Sprite implements IConditionView
{
    public var transition = new Transition();
	public var condition:Condition;

    public function new(condition:Condition)
    {
        this.condition = condition;
        super();
        transition.add(this);
    }
}