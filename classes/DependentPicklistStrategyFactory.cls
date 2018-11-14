@isTest
public class DependentPicklistStrategyFactory {
	private final DependentPresentControllingNotStrategy dpcn;
	private final DependentPresentControllingPresentStrategy dpcp;
	private final DependentNotControllingNotStrategy dncn;
	private final DependentNotControllingPresentStrategy dncp;
	private final Map<Boolean, Map<Boolean, DependentPicklistValueSetterStrategyBase>> strategiesMap;

	{
		dpcn = new DependentPresentControllingNotStrategy();
		dpcp = new DependentPresentControllingPresentStrategy();
		dncn = new DependentNotControllingNotStrategy();
		dncp = new DependentNotControllingPresentStrategy();

		strategiesMap = new Map<Boolean, Map<Boolean, DependentPicklistValueSetterStrategyBase>> {
			true => new Map<Boolean, DependentPicklistValueSetterStrategyBase> {
				true => dpcn,
				false => dpcp
			},
			false => new Map<Boolean, DependentPicklistValueSetterStrategyBase> {
				true => dncp,
				false => dncn
			}
		};
	}

	public DependentPicklistValueSetterStrategyBase getStrategy(Boolean isDependentPresentInMap, Boolean isControllingPresentInMap) {
		return strategiesMap.get(isDependentPresentInMap).get(isControllingPresentInMap);
	}

	public abstract class DependentPicklistValueSetterStrategyBase {
		private DependentPicklistValueSetterStrategyBase() {
		}

		public PicklistValuesEntity getPicklistValues(
			Schema.SObjectField controlling, 
			Schema.SObjectField dependent,
			Map<String, Object> fieldsValuesMap) {
			DependentPicklistValuesProvider.DependentPicklistValuesResultEntity picklistsValues = DependentPicklistValuesProvider.getDependentOptions(
				controlling.getDescribe(), 
				dependent.getDescribe());

			return getDependentFieldValue(
				fieldsValuesMap, 
				picklistsValues, 
				controlling.getDescribe().getName().toUpperCase(), 
				dependent.getDescribe().getName().toUpperCase());
		}

		protected abstract PicklistValuesEntity getDependentFieldValue(
			Map<String, Object> fieldsValuesMap, 
			DependentPicklistValuesProvider.DependentPicklistValuesResultEntity picklistsValues,
			String controllingName,
			String dependentName);
	}

	private class DependentPresentControllingNotStrategy extends DependentPicklistValueSetterStrategyBase {
		protected override PicklistValuesEntity getDependentFieldValue(
			Map<String, Object> fieldsValuesMap, 
			DependentPicklistValuesProvider.DependentPicklistValuesResultEntity picklistsValues,
			String controllingName,
			String dependentName) {
			String dependentValue = (String)fieldsValuesMap.get(dependentName);
			String controllingValue = picklistsValues.dependentToControllingMap.get(dependentValue);

			return new PicklistValuesEntity(controllingValue, dependentValue);
		}
	}

	private class DependentPresentControllingPresentStrategy extends DependentPicklistValueSetterStrategyBase {
		protected override PicklistValuesEntity getDependentFieldValue(
			Map<String, Object> fieldsValuesMap, 
			DependentPicklistValuesProvider.DependentPicklistValuesResultEntity picklistsValues,
			String controllingName,
			String dependentName) {
			String dependentValue = (String)fieldsValuesMap.get(dependentName);
			String controllingValue = (String)fieldsValuesMap.get(controllingName);

			return new PicklistValuesEntity(controllingValue, dependentValue);
		}
	}

	private class DependentNotControllingNotStrategy extends DependentPicklistValueSetterStrategyBase {
		protected override PicklistValuesEntity getDependentFieldValue(
			Map<String, Object> fieldsValuesMap, 
			DependentPicklistValuesProvider.DependentPicklistValuesResultEntity picklistsValues,
			String controllingName,
			String dependentName) {
			String controllingValue = Randomizer.getRandomString(new List<String>(picklistsValues.controllingToDependentMap.keySet()));
			String dependentValue = Randomizer.getRandomString(picklistsValues.controllingToDependentMap.get(controllingValue));

			return new PicklistValuesEntity(controllingValue, dependentValue);
		}
	}

	private class DependentNotControllingPresentStrategy extends DependentPicklistValueSetterStrategyBase {
		protected override PicklistValuesEntity getDependentFieldValue(
			Map<String, Object> fieldsValuesMap, 
			DependentPicklistValuesProvider.DependentPicklistValuesResultEntity picklistsValues,
			String controllingName,
			String dependentName) {
			String controllingValue = (String)fieldsValuesMap.get(controllingName);
			String dependentValue = Randomizer.getRandomString(picklistsValues.controllingToDependentMap.get(controllingValue));

			return new PicklistValuesEntity(controllingValue, dependentValue);
		}
	}
}
