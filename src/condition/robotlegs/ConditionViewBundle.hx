package condition.robotlegs;

import robotlegs.bender.framework.api.IBundle;
import robotlegs.bender.framework.api.IContext;

/**
 * ...
 * @author P.J.Shand
 */
class ConditionViewBundle implements IBundle {
	public function extend(context:IContext):Void {
		context.install(ConditionViewExtension);
	}
}
