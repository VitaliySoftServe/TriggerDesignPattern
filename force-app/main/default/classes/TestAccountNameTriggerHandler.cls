public with sharing class TestAccountNameTriggerHandler extends TriggerHandler {
    private List<Account> newAccountList;
    private Map<Id, Account> oldAccountMap;
    private Map<Id, Account> newAccountMap;

    public TestAccountNameTriggerHandler() {
        newAccountList = (List<Account>) Trigger.NEW;
        oldAccountMap  = (Map<Id, Account>) Trigger.oldMap;
        newAccountMap  = (Map<Id, Account>) Trigger.newMap;
    }


    public override void  afterInsert() {
        List<TestAccountName__c> testsToInsert = new List<TestAccountName__c>();
        for (Account a : newAccountList) {
            TestAccountName__c test = new TestAccountName__c(Name = a.Name);
            test.AccountId__c = a.Id;
            testsToInsert.add(test);
        }
        insert(testsToInsert);
    }


    public override void afterUpdate() {
        List<TestAccountName__c> testsToUpdate = new List<TestAccountName__c>();
        Set<Id> accountIds = new Set<Id>();
        for (Account a : newAccountList) {
            if (a.Name != oldAccountMap.get(a.Id).Name) {
                accountIds.add(a.Id);
            }
        }
        for (TestAccountName__c test : [SELECT Name, Status__c, AccountId__c
                                        FROM TestAccountName__c
                                        WHERE AccountId__c IN :accountIds]) {
            test.Name = newAccountMap.get(test.AccountId__c).Name;
            test.Status__c = Constants.UPDATED;
            testsToUpdate.add(test);
        }
        if (testsToUpdate.size() > 0) {
            update testsToUpdate;
        }
    }

    
    public override void afterDelete() {
        List<TestAccountName__c> testsToChangeStatus = new List<TestAccountName__c>();
        Set<Id> accountIds = oldAccountMap.keySet();
        for (TestAccountName__c test : [SELECT Status__c
                                        FROM TestAccountName__c
                                        WHERE DeletedAccountId__c IN :accountIds]) {
            test.Status__c = Constants.DELETED;
            testsToChangeStatus.add(test);
        }
        update testsToChangeStatus;
    }
}