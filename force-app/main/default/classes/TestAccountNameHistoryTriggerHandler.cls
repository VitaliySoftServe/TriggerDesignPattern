public with sharing class TestAccountNameHistoryTriggerHandler extends TriggerHandler {
    private List<TestAccountName__c> newAccountList;
    private Map<Id, TestAccountName__c> oldAccountMap;

    public TestAccountNameHistoryTriggerHandler() {
        newAccountList = (List<TestAccountName__c>) Trigger.NEW;
        oldAccountMap  = (Map<Id, TestAccountName__c>) Trigger.oldMap;
    }


    public override void  afterInsert () {
        List<TestAccountNameHistory__c> historiesToInsert = new List<TestAccountNameHistory__c>();
        for (TestAccountName__c test : newAccountList) {
            TestAccountNameHistory__c history = new TestAccountNameHistory__c(Name = test.Name + ' History');
            history.TestAccountNameId__c = test.Id;
            history.Description__c = 'New TestAccountName Object with Id \'' + test.Id + '\' and name \''
                                     + test.Name + '\' was created. Status is \'' + test.Status__c + '\'';
            historiesToInsert.add(history);
        }
        insert historiesToInsert;
    }

    
    public override void afterUpdate() {
        List<TestAccountNameHistory__c> historiesToInsert = new List<TestAccountNameHistory__c>();
        Set <Id> ids = new Set<Id>();
        for (TestAccountName__c test : newAccountList) {
            TestAccountNameHistory__c history = new TestAccountNameHistory__c(Name = test.Name + ' History');
            history.Description__c = 'TestAccountName Object with Id \''
                                     + test.Id + '\' and name \''
                                     + test.Name + '\' was changed. Status is \''
                                     + test.Status__c + '\'';
            history.TestAccountNameId__c = test.Id;
            historiesToInsert.add(history);
            if (test.Name != oldAccountMap.get(test.Id).Name) {
                ids.add(test.Id);
            }
        }
        insert historiesToInsert;
        if (ids.size() > 0) {
            BatchChangeTestAccountHistoryName myBatchObject = new BatchChangeTestAccountHistoryName(ids);
            ID batchprocessid = Database.executeBatch(myBatchObject);
        }
    }
}
