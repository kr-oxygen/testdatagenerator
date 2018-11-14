@isTest
public class GeneratedTestDataBuilder {
	private final GeneratedTestData generatedTestData;
	private final SObjectType sObjType;
	private final Map<String, Object> fieldsWithValuesMap = new Map<String, Object> ();

	public GeneratedTestDataBuilder(SObjectType sobjType) {
		this.sObjType = sobjType;
	}

	public GeneratedTestDataBuilder addFieldValue(String fieldName, Object value) {
		fieldsWithValuesMap.put(fieldName, value);

		return this;
	}

	public GeneratedTestDataBuilder addFieldToGenerateRandomValue(String fieldName) {
		fieldsWithValuesMap.put(fieldName, null);

		return this;
	}

	public GeneratedTestDataBuilder addFieldsWithValueMap(Map<String, Object> fieldsWithValuesMap) {
		this.fieldsWithValuesMap.putAll(fieldsWithValuesMap);

		return this;
	}

	public GeneratedTestData build() {
		UnitOfWork uof = new UnitOfWork();

		GeneratedTestData gtd = new GeneratedTestData(this.sObjType, uof, 0, fieldsWithValuesMap);

		gtd.generateFields();

		uof.commitWork();

		return gtd;
	}

	public class GeneratedTestData {
		private final Map<String, Object> fieldsWithValuesMap;
		private final SObjectType sobjType;
		private final UnitOfWork uof;
		private final Integer level;
		private final FieldRandomGeneratorFactory generatorFactory;
		private final Map<Schema.SObjectField, Schema.SObjectField> dependentToControllingMap;

		public SObject record { get; private set; }

		{
			fieldsWithValuesMap = new Map<String, Object> ();
			generatorFactory = new FieldRandomGeneratorFactory();
			dependentToControllingMap = new Map<Schema.SObjectField, Schema.SObjectField>();
		}

		public GeneratedTestData(SObjectType sobjType, UnitOfWork uof, Integer level, Map<String, Object> fieldsWithValuesMap) {
			this.sobjType = sobjType;
			this.uof = uof;
			this.level = level;

			if (fieldsWithValuesMap != null) {
				for (String key :fieldsWithValuesMap.keySet()) {
					this.fieldsWithValuesMap.put(key.toUpperCase(), fieldsWithValuesMap.get(key));
				}
			}
		}

		public void generateFields() {
			record = sobjType.newSObject(null, true);
			uof.addNew(level, record);

			Schema.DescribeSObjectResult dsr = sobjType.getDescribe();

			Map<String, Schema.SObjectField> fieldsMap = dsr.fields.getMap();

			for (String fieldName : fieldsMap.keySet())
			{
				Schema.SObjectField field = fieldsMap.get(fieldName);
				String fieldNameUppered = fieldName.toUpperCase();
				Schema.DescribeFieldResult dfr = field.getDescribe();

				if (dfr.isDependentPicklist()) {
					Schema.SObjectField controllingField = dfr.getController();

					if (controllingField != null) {
						dependentToControllingMap.put(field, controllingField);

						continue;
					}
				}

				Boolean isFieldRequired = TestDataGeneratorUtils.isFieldRequired(dfr);

				if (this.fieldsWithValuesMap.containsKey(fieldNameUppered)) {
					if (this.fieldsWithValuesMap.get(fieldNameUppered) == null) {
						isFieldRequired = true;
					} else {
						record.put(fieldName, fieldsWithValuesMap.get(fieldNameUppered));

						continue;
					}
				}

				if (isFieldRequired) {
					generatorFactory.setValueForField(record, dfr, uof, level, fieldsWithValuesMap, field);
				}
			}

			processDependentPicklistFields();
		}

		private void processDependentPicklistFields() {
			DependentPicklistStrategyFactory factory = new DependentPicklistStrategyFactory();

			for (Schema.SObjectField dependent :dependentToControllingMap.keySet()) {
				Schema.SObjectField controlling = dependentToControllingMap.get(dependent);

				Boolean isDependentPresentInMap = fieldsWithValuesMap.containsKey(dependent.getDescribe().getName().toUpperCase());
				Boolean isControllingPresentInMap = fieldsWithValuesMap.containsKey(controlling.getDescribe().getName().toUpperCase());

				if (isDependentPresentInMap || TestDataGeneratorUtils.isFieldRequired(dependent.getDescribe())) {
					DependentPicklistStrategyFactory.DependentPicklistValueSetterStrategyBase strategy = 
						factory.getStrategy(isDependentPresentInMap, isControllingPresentInMap);

					PicklistValuesEntity values = strategy.getPicklistValues(controlling, dependent, fieldsWithValuesMap);
					record.put(controlling.getDescribe().getName(), values.controllingValue);
					record.put(dependent.getDescribe().getName(), values.dependentValue);
				}
			}
		}
	}

	@isTest
	private static void testShouldProperlyGenerateData() {
		Contract obj;
		final String accountName = 'test account name';

		try {
			GeneratedTestDataBuilder.GeneratedTestData testData = new GeneratedTestDataBuilder(Contract.sObjectType)
				.addFieldValue('Status', 'Draft')
				.addFieldValue('account_Link__c.name', accountName)
				.addFieldToGenerateRandomValue('account_link__c.Industry')
				.build();

			obj = (Contract) testData.record;

			System.debug(obj);
			System.assert(obj != null);
			System.assert(obj.Id != null);
			System.assertEquals(accountName, obj.Account_Link__r.Name);
			System.assert(obj.Account_Link__r.Industry != null);
		} finally {
			if (obj != null && obj.Id != null) {
				delete new SObject[] { obj, obj.Account_Link__r, obj.Account };
			}
		}
	}

	@isTest
	private static void testShouldGenerateRecordWithDependingPicklistField() {
		GeneratedTestDataBuilder.GeneratedTestData gtd = new GeneratedTestDataBuilder(Account.sObjectType)
			.build();

		System.debug(gtd.record);

		System.assert(gtd.record != null);
		System.assert(gtd.record.Id != null);
	}
}