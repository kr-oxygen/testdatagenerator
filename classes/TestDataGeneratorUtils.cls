@isTest
public class TestDataGeneratorUtils  {
	public static final Set<String> STANDARD_OBJECT_FIELDS_FILLED_BY_SYSTEM = new Set<String>();
	
	static {
		STANDARD_OBJECT_FIELDS_FILLED_BY_SYSTEM.add('Id');
		STANDARD_OBJECT_FIELDS_FILLED_BY_SYSTEM.add('OwnerId');
		STANDARD_OBJECT_FIELDS_FILLED_BY_SYSTEM.add('CreatedDate');
		STANDARD_OBJECT_FIELDS_FILLED_BY_SYSTEM.add('CreatedById');
		STANDARD_OBJECT_FIELDS_FILLED_BY_SYSTEM.add('LastModifiedById');
		STANDARD_OBJECT_FIELDS_FILLED_BY_SYSTEM.add('LastModifiedDate');
		STANDARD_OBJECT_FIELDS_FILLED_BY_SYSTEM.add('SystemModstamp');
	}

	public static Boolean isFieldRequired(Schema.DescribeFieldResult dfr) {
		Boolean isFieldreq  = !dfr.isNillable() 
			&& dfr.getType() != Schema.DisplayType.BOOLEAN 
				&& !STANDARD_OBJECT_FIELDS_FILLED_BY_SYSTEM.contains(dfr.getName())
					&& dfr.isCreateable();

		return isFieldreq;
	}
}