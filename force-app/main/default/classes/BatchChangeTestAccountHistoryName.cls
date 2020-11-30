public class BatchChangeTestAccountHistoryName implements Database.Batchable<sObject> {
    List<Id> TestAccountNameIds;
    
    public BatchChangeTestAccountHistoryName (List<Id> TestAccountNameIds){
        this.TestAccountNameIds=TestAccountNameIds;
    }

    
    public Database.QueryLocator start(Database.BatchableContext bc) {
        String query = 'SELECT Name, (SELECT Name FROM TestAccountNameHistories__r) FROM TestAccountName__c WHERE Id in:' + TestAccountNameIds;
        return Database.getQueryLocator(query);
    }


    public void execute(Database.BatchableContext bc, List<TestAccountName__c> scope){
        List<TestAccountNameHistory__c> historiesToUpdate = new List<TestAccountNameHistory__c>();
            for(TestAccountName__c test : scope){
                for (TestAccountNameHistory__c history : test.TestAccountNameHistories__r) {
                    history.Name=test.Name+' History';
                    historiesToUpdate.add(history);
                }
            }
        update historiesToUpdate; 
    }


    public void finish(Database.BatchableContext bc){}
}