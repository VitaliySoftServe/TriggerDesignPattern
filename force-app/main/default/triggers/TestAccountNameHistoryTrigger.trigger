trigger TestAccountNameHistoryTrigger on TestAccountName__c (after insert, after update) {
    new CustomMDTTriggerHandler().run();
    
 /*   if (Trigger.isInsert){
        List<TestAccountNameHistory__c> historiesToInsert = new List<TestAccountNameHistory__c>();
    
        for (TestAccountName__c test : Trigger.New){
            TestAccountNameHistory__c history = new TestAccountNameHistory__c(Name=test.Name+' History');
            history.TestAccountNameId__c=test.Id;
            history.Description__c='New TestAccountName Object with Id \''+test.Id+'\' and name \''+test.Name+'\' was created. Status is \''+test.Status__c+'\'';
            historiesToInsert.add(history);
        }
    
        insert(historiesToInsert);
    }  
    
    
    else if (Trigger.isUpdate){
        List<TestAccountNameHistory__c> historiesToUpdate = new List<TestAccountNameHistory__c>();
        Set<Id> testAccountNameIds = new Set<Id>();   

        for (TestAccountName__c test : Trigger.New){ 
            if (test!=Trigger.OldMap.get(test.Id)){
                testAccountNameIds.add(test.Id);
            }
        }
            
        for(TestAccountNameHistory__c history : [SELECT  Description__c, TestAccountNameId__c FROM TestAccountNameHistory__c WHERE TestAccountNameId__c IN :testAccountNameIds]){
            TestAccountName__c t = Trigger.newMap.get(history.TestAccountNameId__c);
            history.Name=t.Name+' History';
            history.Description__c=history.Description__c+'\n'+'TestAccountName Object with name \''+t.Name+'\' was changed. Status is \''+t.Status__c+'\'';
            historiesToUpdate.add(history);
        }    
            
        update historiesToUpdate;
    }*/
}
