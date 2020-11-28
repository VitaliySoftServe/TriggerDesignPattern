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

    insert(historiesToInsert);
   }


   public override void afterUpdate() {
    List<TestAccountNameHistory__c> historiesToUpdate = new List<TestAccountNameHistory__c>();
    Set<Id> testAccountNameIds = new Set<Id>();   

    for (TestAccountName__c test : newTrigger){ 
        if (test!=oldMap.get(test.Id)){
            testAccountNameIds.add(test.Id);
        }
    }
        
    for(TestAccountNameHistory__c history : [SELECT  Description__c, TestAccountNameId__c FROM TestAccountNameHistory__c WHERE TestAccountNameId__c IN :testAccountNameIds]){
        TestAccountName__c t = newMap.get(history.TestAccountNameId__c);
        history.Name=t.Name+' History';
        history.Description__c=history.Description__c+'\n'+'TestAccountName Object with name \''+t.Name+'\' was changed. Status is \''+t.Status__c+'\'';
        historiesToUpdate.add(history);
    }    
        
    update historiesToUpdate;
   }

}
