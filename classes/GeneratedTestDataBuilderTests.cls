@isTest
private class GeneratedTestDataBuilderTests {
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
			System.assert(obj.Account_Link__c != null);
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
