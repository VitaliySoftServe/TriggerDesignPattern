public with sharing class LookUpHistoriesAnnotation {

    @InvocableMethod
    public static void updateHistoriesNames(List<Id> TestAccountNameIds) {
        BatchChangeTestAccountHistoryName myBatchObject = new BatchChangeTestAccountHistoryName(TestAccountNameIds);
        ID batchprocessid = Database.executeBatch(myBatchObject);
    }
}
