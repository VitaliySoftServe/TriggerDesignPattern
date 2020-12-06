public class BatchChangeTestAccountHistoryName implements Database.Batchable<sObject> {
    Set<Id> testAccountNameIds;
    public BatchChangeTestAccountHistoryName (Set<Id> testAccountNameIds) {
        this.testAccountNameIds = testAccountNameIds;
    }

    public List<TestAccountNameHistory__c> start(Database.BatchableContext bc) {
        return [SELECT Name, TestAccountNameId__r.Name
                FROM TestAccountNameHistory__c
                WHERE TestAccountNameId__c in : testAccountNameIds];
    }

    public void execute(Database.BatchableContext bc, List<TestAccountNameHistory__c> scope) {
        List<TestAccountNameHistory__c> historiesToUpdate = new List<TestAccountNameHistory__c>();
        for (TestAccountNameHistory__c history : scope) {
            if (history.Name != history.TestAccountNameId__r.Name + ' History') {
                history.Name = history.TestAccountNameId__r.Name + ' History';
                historiesToUpdate.add(history);
            }
        }
           update historiesToUpdate;
    }

    public void finish(Database.BatchableContext bc) {}
}