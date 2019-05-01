package condition.robotlegs;

import condition.IConditionView;
import robotlegs.bender.bundles.mvcs.Mediator;
import delay.Delay;

/**
* ...
* @author P.J.Shand
*/
class IConditionViewMediator extends Mediator
{
    @inject public var view:IConditionView;

    override public function initialize():Void
	{
        Delay.nextFrame(() -> {
            view.transition.condition = view.condition;
        });
	}
}