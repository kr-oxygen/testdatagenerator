@isTest 
global class TestDataGenerator {
	private static final Set<String> STANDARD_OBJECT_FIELDS_FILLED_BY_SYSTEM = new Set<String>();
	private static final FieldRandomGeneratorFactory generatorFactory = new FieldRandomGeneratorFactory();

	static {
		STANDARD_OBJECT_FIELDS_FILLED_BY_SYSTEM.add('Id');
		STANDARD_OBJECT_FIELDS_FILLED_BY_SYSTEM.add('OwnerId');
		STANDARD_OBJECT_FIELDS_FILLED_BY_SYSTEM.add('CreatedDate');
		STANDARD_OBJECT_FIELDS_FILLED_BY_SYSTEM.add('CreatedById');
		STANDARD_OBJECT_FIELDS_FILLED_BY_SYSTEM.add('LastModifiedById');
		STANDARD_OBJECT_FIELDS_FILLED_BY_SYSTEM.add('LastModifiedDate');
		STANDARD_OBJECT_FIELDS_FILLED_BY_SYSTEM.add('SystemModstamp');
	}

	global static SObject generateObject(SObjectUnitOfWork uof, SObjectType sobjType, Map<String, Object> fieldValueMap) {
		SObject newObject = sobjType.newSObject(null, true);
		Map<String, Object> fieldsWithValuesMap = generateFieldsValues(uof, sobjType, newObject, fieldValueMap);

		for (String field :fieldsWithValuesMap.keySet()) {
			try {
				newObject.put(field, fieldsWithValuesMap.get(field));
			} catch (System.SObjectException e) {
				System.debug(field + ' : ' +  e);
			}
		}

		return newObject;
	}

	private static Map<String, Object> generateFieldsValues(SObjectUnitOfWork uof, SObjectType sobjType, SObject record, Map<String, Object> fieldValueMap) {
		Map<String, Object> fieldsWithValuesMap = new Map<String, Object>();

		Schema.DescribeSObjectResult dsr = sobjType.getDescribe();

		Map<String, Schema.SObjectField> fieldsMap = dsr.fields.getMap();

		for(String fieldName : fieldsMap.keySet())
		{
			if (fieldValueMap.containsKey(fieldName)) {
				fieldsWithValuesMap.put(fieldName, fieldValueMap.get(fieldName));

				continue;
			}

			Schema.SObjectField field = fieldsMap.get(fieldName);
			Schema.DescribeFieldResult dfr = field.getDescribe();
			Boolean isFieldRequired  = isFieldRequired(dfr);

			if (isFieldRequired) {
				IFieldRandomGenerator generator = generatorFactory.getGenerator(dfr.getType());

				Object value = generator.getRandomValueForField(uof, record, field, dfr);

				if (value != null) {
					fieldsWithValuesMap.put(fieldName, value);
				}
			}
		}

		return fieldsWithValuesMap;
	}

	private static Boolean isFieldRequired(Schema.DescribeFieldResult dfr) {
		Boolean isFieldreq  = !dfr.isNillable() 
			&& dfr.getType() != Schema.DisplayType.BOOLEAN 
				&& !STANDARD_OBJECT_FIELDS_FILLED_BY_SYSTEM.contains(dfr.getName())
					&& dfr.isCreateable();

		return isFieldreq;
	}

	private interface IFieldRandomGenerator {
		Object getRandomValueForField(SObjectUnitOfWork uof, SObject record, SObjectField field, Schema.DescribeFieldResult dfr);
	}

	private class BlobFieldRandomGenerator implements IFieldRandomGenerator {
		public Object getRandomValueForField(SObjectUnitOfWork uof, SObject record, SObjectField field, Schema.DescribeFieldResult dfr) {
			Integer size = dfr.getByteLength();

			String randomContent = Randomizer.getRandomString(size);

			return Blob.valueOf(randomContent);
		}
	}

	private class DateFieldRandomGenerator implements IFieldRandomGenerator {
		public Object getRandomValueForField(SObjectUnitOfWork uof, SObject record, SObjectField field, Schema.DescribeFieldResult dfr) {
			return Randomizer.getRandomDate(Randomizer.DateDirection.future);
		}
	}

	private class DatetimeFieldRandomGenerator implements IFieldRandomGenerator {
		public Object getRandomValueForField(SObjectUnitOfWork uof, SObject record, SObjectField field, Schema.DescribeFieldResult dfr) {
			return Randomizer.getRandomDatetime(Randomizer.DateDirection.future);
		}
	}

	private class DecimalFieldRandomGenerator extends DoubleFieldRandomGenerator {
		public override Object getRandomValueForField(SObjectUnitOfWork uof, SObject record, SObjectField field, Schema.DescribeFieldResult dfr) {
			return Decimal.valueOf((Double)super.getRandomValueForField(uof, record, field, dfr));
		}
	}

	private virtual class DoubleFieldRandomGenerator implements IFieldRandomGenerator {
		public virtual Object getRandomValueForField(SObjectUnitOfWork uof, SObject record, SObjectField field, Schema.DescribeFieldResult dfr) {
			Integer precision = dfr.getPrecision();
			Integer scale = dfr.getScale();

			return Double.valueOf(String.format('{0}.{1}', new List<String> {
				String.valueOf(Randomizer.getRandomNumber(precision - scale)), 
				String.valueOf(Randomizer.getRandomNumber(scale))
			}));
		}
	}

	private virtual class IntegerFieldRandomGenerator implements IFieldRandomGenerator {
		public virtual Object getRandomValueForField(SObjectUnitOfWork uof, SObject record, SObjectField field, Schema.DescribeFieldResult dfr) {
			return Randomizer.getRandomNumber(dfr.getDigits());
		}
	}

	private class LongFieldRandomGenerator extends IntegerFieldRandomGenerator {
		public override Object getRandomValueForField(SObjectUnitOfWork uof, SObject record, SObjectField field, Schema.DescribeFieldResult dfr) {
			return (Long)super.getRandomValueForField(uof, record, field, dfr);
		}
	}

	private class StringFieldRandomGenerator implements IFieldRandomGenerator {
		public Object getRandomValueForField(SObjectUnitOfWork uof, SObject record, SObjectField field, Schema.DescribeFieldResult dfr) {
			return Randomizer.getRandomString(dfr.getLength());
		}
	}

	private class TimeFieldRandomGenerator implements IFieldRandomGenerator {
		public Object getRandomValueForField(SObjectUnitOfWork uof, SObject record, SObjectField field, Schema.DescribeFieldResult dfr) {
			return Randomizer.getRandomTime(Randomizer.DateDirection.present);
		}
	}

	private class PicklistFieldRandomGenerator implements IFieldRandomGenerator {
		public Object getRandomValueForField(SObjectUnitOfWork uof, SObject record, SObjectField field, Schema.DescribeFieldResult dfr) {
			List<String> values = new List<String>();

			for (Schema.PicklistEntry ple :dfr.getPicklistValues()) {
				if (ple.isActive()) {
					values.add(ple.getValue());
				}
			}

			return values.size() > 0 ? Randomizer.getRandomString(values) : '';
		}
	}

	private class ReferenceFieldRandomGenerator implements IFieldRandomGenerator {
		public Object getRandomValueForField(SObjectUnitOfWork uof, SObject record, SObjectField field, Schema.DescribeFieldResult dfr) {
			Schema.SObjectType firstRef = dfr.getReferenceTo()[0];

			SObject generateObj = TestDataGenerator.generateObject(uof, firstRef, new Map<String, Object>());
			
			uof.registerNew(generateObj);
			uof.registerRelationship(record, field, generateObj);

			insert generateObj;

			return generateObj.get('Id');
		}
	}

	private class FieldRandomGeneratorFactory {
		private final Map<Type, IFieldRandomGenerator> generatorsCache = new Map<Type, IFieldRandomGenerator>();

		public IFieldRandomGenerator getGenerator(Schema.DisplayType fieldDisplayType) {
			switch on fieldDisplayType {
				when BASE64 {
					return getObjectForType(BlobFieldRandomGenerator.class);
				}
				when DATE {
					return getObjectForType(DateFieldRandomGenerator.class);
				}
				when DATETIME {
					return getObjectForType(DatetimeFieldRandomGenerator.class);
				}
				when CURRENCY, PERCENT {
					return getObjectForType(DecimalFieldRandomGenerator.class);
				}
				when DOUBLE {
					return getObjectForType(DoubleFieldRandomGenerator.class);
				}
				when INTEGER {
					return getObjectForType(IntegerFieldRandomGenerator.class);
				}
				when TIME {
					return getObjectForType(TimeFieldRandomGenerator.class);
				}
				when PICKLIST, MULTIPICKLIST {
					return getObjectForType(PicklistFieldRandomGenerator.class);
				}
				when REFERENCE {
					return getObjectForType(ReferenceFieldRandomGenerator.class);
				}
				when else {
					return getObjectForType(StringFieldRandomGenerator.class);
				}
			}
		}

		private IFieldRandomGenerator getObjectForType(Type t) {
			if (!generatorsCache.containsKey(t)) {
				generatorsCache.put(t, (IFieldRandomGenerator)t.newInstance());
			}

			return generatorsCache.get(t);
		}
	}
}