public class BatchDeleteHistories implements Database.Batchable<sObject> {
    
    Id i;
    
    public BatchDeleteHistories(Id i) {
        this.i=i;
    }

    public List<TestAccountNameHistory__c> start(Database.BatchableContext bc) {
        return [SELECT Id FROM TestAccountNameHistory__c WHERE TestAccountNameId__c=:i];
    }


    public void execute(Database.BatchableContext bc, List<TestAccountNameHistory__c> scope) {
        delete scope;  
    }


    public void finish(Database.BatchableContext bc) {}
}
