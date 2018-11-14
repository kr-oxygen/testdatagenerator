@isTest
public class PicklistValuesEntity {
	public String controllingValue { get; private set; }
	public String dependentValue { get; private set; }

	public PicklistValuesEntity(String controllingValue, String dependentValue) {
		this.controllingValue = controllingValue;
		this.dependentValue = dependentValue;
	}
}