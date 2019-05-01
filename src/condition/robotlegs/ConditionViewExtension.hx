package condition.robotlegs;

import condition.IConditionView;
import condition.robotlegs.IConditionViewMediator;
import org.swiftsuspenders.utils.DescribedType;
import robotlegs.bender.framework.api.IContext;
import robotlegs.bender.framework.api.IExtension;
import robotlegs.bender.extensions.mediatorMap.api.IMediatorMap;

class ConditionViewExtension implements DescribedType implements IExtension
{
	public function new() { }
	
	public function extend(context:IContext):Void
	{
		var mediatorMap:IMediatorMap = context.injector.getInstance(IMediatorMap);
		mediatorMap.map(IConditionView).toMediator(IConditionViewMediator);
	}
}