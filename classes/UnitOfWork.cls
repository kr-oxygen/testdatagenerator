@isTest
public class UnitOfWork {
	private Map<Integer, List<SObject>> newRecordsMap = new Map<Integer, List<SObject>> ();
	private Map<Integer, Relationships> relationshipsMap = new Map<Integer, Relationships> ();

	public void addNew(Integer layer, SObject newRecord) {
		addNew(layer, newRecord, null, null);
	}

	public void addNew(Integer layer, SObject newRecord, Schema.SObjectField relatedToField, SObject relatedTo) {
		if (!newRecordsMap.containsKey(layer)) {
			newRecordsMap.put(layer, new List<SObject> ());
		}

		newRecordsMap.get(layer).add(newRecord);

		registerRelationship(layer, newRecord, relatedToField, relatedTo);
	}

	public void registerRelationship(Integer layer, SObject record, Schema.SObjectField relatedToField, SObject relatedTo) {
		if (!relationshipsMap.containsKey(layer)) {
			relationshipsMap.put(layer, new Relationships());
		}

		if (relatedToField != null && relatedTo != null) {
			relationshipsMap.get(layer).add(record, relatedToField, relatedTo);
		}
	}

	public void commitWork() {
		Savepoint sp = Database.setSavePoint();

		try
		{
			List<Integer> newList = new List<Integer> (newRecordsMap.keySet());
			
			ReverseIterator reverseIter = new ReverseIterator(newList);

			while (reverseIter.hasNext()) {
				Integer key = reverseIter.next();

				List<SObject> recordsToCreate = newRecordsMap.get(key);

				insert recordsToCreate;

				Relationships relationshipsList = relationshipsMap.get(key);

				relationshipsList.resolve();
			}
		}
		catch(Exception e)
		{
			Database.rollback(sp);

			throw e;
		}
	}

	private class Relationship
	{
		public SObject Record { get; private set; }
		public Schema.sObjectField RelatedToField { get; private set; }
		public SObject RelatedTo { get; private set; }

		public Relationship(SObject record, Schema.sObjectField relatedToField, SObject relatedTo) {
			this.Record = record;
			this.RelatedToField = relatedToField;
			this.RelatedTo = relatedTo;
		}
	}

	private class Relationships
	{
		private List<Relationship> relationshipsList = new List<Relationship> ();

		public void resolve()
		{
			for (Relationship relationship : relationshipsList) {
				relationship.Record.put(relationship.RelatedToField, relationship.RelatedTo.Id);
				relationship.Record.putSObject(relationship.RelatedToField, relationship.RelatedTo);
			}
		}

		public void add(SObject record, Schema.sObjectField relatedToField, SObject relatedTo)
		{
			Relationship relationship = new Relationship(record, relatedToField, relatedTo);
			relationshipsList.add(relationship);
		}
	}

	private class ReverseIterator implements Iterator<Integer> {
		private final List<Integer> internalList;

		private Integer position;

		public ReverseIterator(List<Integer> internalList) {
			this.internalList = internalList;
			this.internalList.sort();
			this.position = internalList.size();
		}

		public Boolean hasNext() {
			return position > 0;
		}

		public Integer next() {
			return internalList[-- position];
		}
	}
}