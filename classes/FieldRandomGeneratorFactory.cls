@isTest
public class FieldRandomGeneratorFactory {
	public void setValueForField(
								 SObject record,
								 Schema.DescribeFieldResult dfr,
								 UnitOfWork uof,
								 Integer level,
								 Map<String, Object> fieldsWithValuesMap,
								 Schema.SObjectField field) {
		FieldRandomValueSetter rvfs;
		Schema.DisplayType fieldDisplayType = dfr.getType();

		switch on fieldDisplayType {
			when BASE64 {
				rvfs = new BlobFieldRandomSetter(record, dfr);
			}
			when DATE {
				rvfs = new DateFieldRandomSetter(record, dfr);
			}
			when DATETIME {
				rvfs = new DatetimeFieldRandomSetter(record, dfr);
			}
			when CURRENCY, PERCENT {
				rvfs = new DecimalFieldRandomSetter(record, dfr);
			}
			when DOUBLE {
				rvfs = new DoubleFieldRandomSetter(record, dfr);
			}
			when INTEGER {
				rvfs = new IntegerFieldRandomSetter(record, dfr);
			}
			when TIME {
				rvfs = new TimeFieldRandomSetter(record, dfr);
			}
			when PICKLIST, MULTIPICKLIST {
				rvfs = new PicklistFieldRandomSetter(record, dfr);
			}
			when REFERENCE {
				rvfs = new ReferenceFieldRandomSetter(record, dfr, uof, level, fieldsWithValuesMap, field);
			}
			when else {
				rvfs = new StringFieldRandomSetter(record, dfr);
			}
		}

		rvfs.setRandomValueForField();
	}

	private abstract class FieldRandomValueSetter {
		protected Schema.DescribeFieldResult dfr { get; private set; }
		protected SObject record { get; private set; }

		public FieldRandomValueSetter(SObject record, Schema.DescribeFieldResult dfr) {
			this.record = record;
			this.dfr = dfr;
		}

		public abstract void setRandomValueForField();
	}

	private class BlobFieldRandomSetter extends FieldRandomValueSetter {
		public BlobFieldRandomSetter(SObject record, Schema.DescribeFieldResult dfr) {
			super(record, dfr);
		}

		public override void setRandomValueForField() {
			Integer size = dfr.getByteLength();

			String randomContent = Randomizer.getRandomString(size);

			record.put(dfr.getName(), Blob.valueOf(randomContent));
		}
	}

	private class DateFieldRandomSetter extends FieldRandomValueSetter {
		public DateFieldRandomSetter(SObject record, Schema.DescribeFieldResult dfr) {
			super(record, dfr);
		}

		public override void setRandomValueForField() {
			record.put(dfr.getName(), Randomizer.getRandomDate(Randomizer.DateDirection.future));
		}
	}

	private class DatetimeFieldRandomSetter extends FieldRandomValueSetter {
		public DatetimeFieldRandomSetter(SObject record, Schema.DescribeFieldResult dfr) {
			super(record, dfr);
		}

		public override void setRandomValueForField() {
			record.put(dfr.getName(), Randomizer.getRandomDatetime(Randomizer.DateDirection.future));
		}
	}

	private class DecimalFieldRandomSetter extends DoubleFieldRandomSetter {
		public DecimalFieldRandomSetter(SObject record, Schema.DescribeFieldResult dfr) {
			super(record, dfr);
		}

		protected override Object getRandomValue() {
			return Decimal.valueOf((Double) super.getRandomValue());
		}
	}

	private virtual class DoubleFieldRandomSetter extends FieldRandomValueSetter {
		public DoubleFieldRandomSetter(SObject record, Schema.DescribeFieldResult dfr) {
			super(record, dfr);
		}

		public override void setRandomValueForField() {
			Integer precision = dfr.getPrecision();
			Integer scale = dfr.getScale();

			record.put(dfr.getName(), getRandomValue());
		}

		protected virtual Object getRandomValue() {
			Integer precision = dfr.getPrecision();
			Integer scale = dfr.getScale();

			return Double.valueOf(String.format('{0}.{1}', new List<String> {
												   String.valueOf(Randomizer.getRandomNumber(precision - scale)),
												   String.valueOf(Randomizer.getRandomNumber(scale))
												}));
		}
	}

	private virtual class IntegerFieldRandomSetter extends FieldRandomValueSetter {
		public IntegerFieldRandomSetter(SObject record, Schema.DescribeFieldResult dfr) {
			super(record, dfr);
		}

		public override void setRandomValueForField() {
			record.put(dfr.getName(), Randomizer.getRandomNumber(dfr.getDigits()));
		}
	}

	private class LongFieldRandomSetter extends FieldRandomValueSetter {
		public LongFieldRandomSetter(SObject record, Schema.DescribeFieldResult dfr) {
			super(record, dfr);
		}

		public override void setRandomValueForField() {
			record.put(dfr.getName(), (Long) Randomizer.getRandomNumber(dfr.getDigits()));
		}
	}

	private class StringFieldRandomSetter extends FieldRandomValueSetter {
		public StringFieldRandomSetter(SObject record, Schema.DescribeFieldResult dfr) {
			super(record, dfr);
		}

		public override void setRandomValueForField() {
			record.put(dfr.getName(), Randomizer.getRandomString(dfr.getLength()));
		}
	}

	private class TimeFieldRandomSetter extends FieldRandomValueSetter {
		public TimeFieldRandomSetter(SObject record, Schema.DescribeFieldResult dfr) {
			super(record, dfr);
		}

		public override void setRandomValueForField() {
			record.put(dfr.getName(), Randomizer.getRandomTime(Randomizer.DateDirection.present));
		}
	}

	private class PicklistFieldRandomSetter extends FieldRandomValueSetter {
		public PicklistFieldRandomSetter(SObject record, Schema.DescribeFieldResult dfr) {
			super(record, dfr);
		}

		public override void setRandomValueForField() {
			List<String> values = new List<String> ();

			for (Schema.PicklistEntry ple : dfr.getPicklistValues()) {
				if (ple.isActive()) {
					values.add(ple.getValue());
				}
			}

			record.put(dfr.getName(), values.size() > 0 ? Randomizer.getRandomString(values) : '');
		}
	}

	private class ReferenceFieldRandomSetter extends FieldRandomValueSetter {
		private final UnitOfWork uof;
		private final Integer level;
		private final Map<String, Object> fieldsWithValuesMap;
		private final Schema.SObjectField field;

		public ReferenceFieldRandomSetter(
			SObject record,
			Schema.DescribeFieldResult dfr,
			UnitOfWork uof,
			Integer level,
			Map<String, Object> fieldsWithValuesMap,
			Schema.SObjectField field) {
			super(record, dfr);

			this.uof = uof;
			this.level = ++level;
			this.fieldsWithValuesMap = fieldsWithValuesMap;
			this.field = field;
		}

		public override void setRandomValueForField() {
			Schema.SObjectType firstRef = dfr.getReferenceTo() [0];
			Map<String, Object> newMap = getReferencedObjectFieldsMap();

			GeneratedTestDataBuilder.GeneratedTestData gtd = new GeneratedTestDataBuilder.GeneratedTestData(firstRef, uof, level, newMap);

			gtd.generateFields();
			uof.registerRelationship(level, record, field, gtd.record);
		}

		private Map<String, Object> getReferencedObjectFieldsMap() {
			Map<String, Object> newMap = new Map<String, Object> ();
			String currentFieldName = this.dfr.getName();

			for (String fieldName : fieldsWithValuesMap.keySet()) {
				String currentFiledNameWithDot = currentFieldName + '.';

				if (fieldName.startsWithIgnoreCase(currentFiledNameWithDot.toUpperCase())) {
					String newFieldKey = fieldName.substring(currentFiledNameWithDot.length());

					newMap.put(newFieldKey.toUpperCase(), fieldsWithValuesMap.get(fieldName));
				}
			}

			return newMap;
		}
	}
}