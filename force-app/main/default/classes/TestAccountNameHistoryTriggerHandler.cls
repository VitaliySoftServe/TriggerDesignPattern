public with sharing class TestAccountNameHistoryTriggerHandler extends TriggerHandler{

    private List<TestAccountName__c> newTrigger; 
    private Map<Id, TestAccountName__c> oldMap; 
    private Map<Id, TestAccountName__c> newMap;
    public TestAccountNameHistoryTriggerHandler() {
         newTrigger = (List<TestAccountName__c>) Trigger.NEW;
         oldMap  = (Map<Id, TestAccountName__c>) Trigger.oldMap;
         newMap  = (Map<Id, TestAccountName__c>) Trigger.newMap;  
   } 

   public override void  afterInsert () {
    List<TestAccountNameHistory__c> historiesToInsert = new List<TestAccountNameHistory__c>();
    
    for (TestAccountName__c test : newTrigger){
        TestAccountNameHistory__c history = new TestAccountNameHistory__c(Name=test.Name+' History');
        history.TestAccountNameId__c=test.Id;
        history.Description__c='New TestAccountName Object with Id \''+test.Id+'\' and name \''+test.Name+'\' was created. Status is \''+test.Status__c+'\'';
        historiesToInsert.add(history);
    }
    insert historiesToInsert;
   }


   public override void afterUpdate() {
    List<TestAccountNameHistory__c> historiesToInsert = new List<TestAccountNameHistory__c>();
    Set <Id> ids = new Set<Id>();

    for (TestAccountName__c test : newTrigger){ 
        
        TestAccountNameHistory__c history = new TestAccountNameHistory__c(Name=test.Name+' History');
        history.Description__c='TestAccountName Object with Id \''+test.Id+'\' and name \''+test.Name+'\' was changed. Status is \''+test.Status__c+'\'';  
        history.TestAccountNameId__c=test.Id;  
        historiesToInsert.add(history);

        if (test.Name != oldMap.get(test.Id).Name) {
            ids.add(test.Id);
        }
    }  
    insert historiesToInsert;

    if (ids.size()>0){
        BatchChangeTestAccountHistoryName myBatchObject = new BatchChangeTestAccountHistoryName(ids);
        ID batchprocessid = Database.executeBatch(myBatchObject);
    }
   }

}
