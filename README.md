# Test Data Factory
**This lib is used to simplify the process of generating test objects, it helps to automate the routine process of creating and populating sOjbect(s) with some random data.**

There is a list of features the lib is supported:

 1. Create a sObject with all primitives required fields filled in with random data.
 2. Create a sObject with required look ups and all required fields in them filled in with random data.
 3. Create a sObject with dependent-controlling picklists, it will intelligently set value for dependent picklist and its corresponding controlling field, and vice verse.
 4. Create a sObject with randomly filled in required fields apart from it you can a value for any field regardless it top level sObject record or its lookup field.
 5. Create a sObject with randomly filled in fields which can be pointed during setup.
 6. The creation of sObject record supports Unit of Work(UoF) concept pattern (https://trailhead.salesforce.com/en/content/learn/modules/apex_patterns_sl/apex_patterns_sl_learn_uow_principles).  

There is a **GeneratedTestDataBuilder** class which helps to construct a necessary sObject record:

    SObjectType sObjType = Contract.sObjectType;
    GeneratedTestDataBuilder builder = new GeneratedTestDataBuilder(sObjType);
    GeneratedTestDataBuilder.GeneratedTestData testData = builder.build();
    Contract record = (Contract)testData.record;
    
The **builder** object can be used for the further construction of the necessary sObject record, to finish construction call **build()** method of the **builder** object. In order to get the constructed sObject record use property **record** from the **GeneratedTestDataBuilder.GeneratedTestData** object, which the  **build()** method returns.

The example above shows how to create a sObject record with all required fields filled in with randomly generated data. In order to pass values to some fields the **GeneratedTestDataBuilder** provides a few methods which were created to provide such an ability:

    GeneratedTestDataBuilder builder = new GeneratedTestDataBuilder(sObjType);
    builder
        .addFieldValue('Status', 'Draft') // the method takes first String parameter as field name and second Object parameter as value of the field
        .addFieldValue('account_Link__c.name', 'value') // in order to pass a value for a lookup record field
        .addFieldToGenerateRandomValue('fieldName') // in order to just point an intention that such a field should be populated with some random value

The **GeneratedTestDataBuilder** is fluent builder, so it provides more convenient way of constructing the **GeneratedTestData** object. In order to pass a lookup record field you have to provide the lookup field name not its related field for instance:

    Account_Link__c
    but NOT
    Account_Link__r
Also, the field names which are passed to the builder methods are case-insensitive, so you may not worry about correct case spelling of the field you want to mention:

    AcCouNt_lInk__C

After the necessary sObject record was constructed with, it is persisted to the database and the Id of it is populated. And if it has a required lookup field or you did setup the lookup field or lookup's fields you can easily refer to the lookup after the sObject record was created, for instance:

    Contract obj  = (Contract) testData.record;
    System.assert(obj.Account_Link__c != null);
    System.assert(obj.Account_Link__c.Industry != null);

And once again you can no worry if the constructing sObject has a depending picklist, the **GeneratedTestDataBuilder** will handle it for you just instantly. More over it is quite intelligent to handle such a cases:

 - the dependent field is required - it will take random value and set corresponding value for controlling field
 - the dependent field value was passed by user - it will find and set value for corresponding controlling field
 - the controlling field is required - it will generate random value for the controlling and will find and set corresponding valued for dependent
 - the controlling filed was passed by user - it will find corresponding value for dependent field and set it.


The full example of usage is listed bellow:

    Contract obj;
    final  String accountName =  'test account name';
    try {
        GeneratedTestDataBuilder.GeneratedTestData testData =  new  GeneratedTestDataBuilder(Contract.sObjectType)
        .addFieldValue('Status', 'Draft')
        .addFieldValue('account_Link__c.name', accountName)
        .addFieldToGenerateRandomValue('account_link__c.Industry')
        .build();

        obj  = (Contract) testData.record;
        System.assert(obj  !=  null);
        System.assert(obj.Id  !=  null);
        System.assertEquals(accountName, obj.Account_Link__r.Name);
        System.assert(obj.Account_Link__r.Industry  !=  null);
    } finally {
        if (obj  !=  null  &&  obj.Id  !=  null) {
        delete  new  SObject[] { obj, obj.Account_Link__r, obj.Account };
    }


### For issues and proposals please create an [issue](https://10.10.8.108/salesforce/helpers/test-data-factory/issues) for the project.
