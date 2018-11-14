@isTest
public class DependentPicklistValuesProvider {
	public static DependentPicklistValuesResultEntity getDependentOptions(Schema.DescribeFieldResult controllingField, Schema.DescribeFieldResult dependentField){
		Map<String, List<String>> controllingToDependentMap = new Map<String, List<String>>();
		Map<String, String> dependentToControllingMap = new Map<String, String>();

		//get the control values   
		List<Schema.PicklistEntry> ctrl_ple = controllingField.getPicklistValues();
		//get the dependent values
		List<Schema.PicklistEntry> dep_ple = dependentField.getPicklistValues();
		//iterate through the values and get the ones valid for the controlling field name
		//set up the results
		for(Integer pControllingIndex = 0; pControllingIndex < ctrl_ple.size(); pControllingIndex++) {
			//get the pointer to the entry
			Schema.PicklistEntry ctrl_entry = ctrl_ple[pControllingIndex];
			//get the label
			String pControllingLabel = ctrl_entry.getLabel();
			//create the entry with the label
			controllingToDependentMap.put(pControllingLabel,new List<String>());
		}
		////cater for null and empty
		//objResults.put('', new List<String>());
		//objResults.put(null, new List<String>());
		//check the dependent values
		for(Integer pDependentIndex=0; pDependentIndex<dep_ple.size(); pDependentIndex++){
			//get the pointer to the dependent index
			Schema.PicklistEntry dep_entry = dep_ple[pDependentIndex];
			//get the valid for
			String pEntryStructure = JSON.serialize(dep_entry);
			TPicklistEntry objDepPLE = (TPicklistEntry)JSON.deserialize(pEntryStructure, TPicklistEntry.class);
			//if valid for is empty, skip
			if (objDepPLE.validFor == null || objDepPLE.validFor == '') {
				continue;
			}
			//iterate through the controlling values
			for(Integer pControllingIndex = 0; pControllingIndex < ctrl_ple.size(); pControllingIndex++) {
				if (Bitset.testBit(objDepPLE.validFor, pControllingIndex)) {
					//get the label
					String pControllingLabel = ctrl_ple[pControllingIndex].getLabel();
					controllingToDependentMap.get(pControllingLabel).add(objDepPLE.label);
					dependentToControllingMap.put(objDepPLE.label, pControllingLabel);
				}
			}
		}
		
		return new DependentPicklistValuesResultEntity(controllingToDependentMap, dependentToControllingMap);
	}

	public class DependentPicklistValuesResultEntity {
		public Map<String, List<String>> controllingToDependentMap { get; private set; }
		public Map<String, String> dependentToControllingMap { get; private set; }

		public DependentPicklistValuesResultEntity(Map<String, List<String>> controllingToDependentMap, Map<String, String> dependentToControllingMap) {
			this.controllingToDependentMap = controllingToDependentMap;
			this.dependentToControllingMap = dependentToControllingMap;
		}
	}

	private class TPicklistEntry {
		public string active { get; set; }
		public string defaultValue { get; set; }
		public string label { get; set; }
		public string value { get; set; }
		public string validFor { get; set; }
	}
}