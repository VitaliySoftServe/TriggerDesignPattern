public with sharing class DeleteHistories {
    @AuraEnabled
    public static String deleteAll(String testId) {
        Id i = Id.valueOf(testId);
        BatchDeleteHistories myBatchObject = new BatchDeleteHistories(i);
        ID jobID  = Database.executeBatch(myBatchObject);

        AsyncApexJob jobInfo  = [ SELECT NumberOfErrors FROM AsyncApexJob WHERE ID =: jobID ];

        Integer count1 = [SELECT Id FROM TestAccountNameHistory__c WHERE TestAccountNameId__c =:i].size() - jobInfo.NumberOfErrors;
        Integer count2 = jobInfo.NumberOfErrors;
        String s;

        if (count1 == 0) {
            s = count2 == 0?'There are no related History records to delete':
                'There were problems with deleting of ' + count2 + ' History records';
        } else {
            s = count2 == 0?count1 + ' related History records were successfully deleted':
                count1 + ' related History records were successfully deleted; But there were problems with deleting of ' 
                + count2 + ' History records';
        }
        return s;
    }
}
