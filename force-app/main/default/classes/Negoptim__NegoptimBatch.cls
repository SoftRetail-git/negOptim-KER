/*
This file is generated and isn't the actual source code for this
managed global class.
This read-only file shows the class's global constructors,
methods, variables, and properties.
To enable code to compile, all methods return null.
*/
global class NegoptimBatch {
    global NegoptimBatch(String batchName, Negoptim.NegoptimBatch.BatchType batchType, String startedFrom) {

    }
    global static Id executeBatch(Database.Batchable<sObject> batchClass, Integer batchSize) {
        return null;
    }
    global void incrementBatchIndex() {

    }
    global void logError(Exception ex) {

    }
    global void logError(String error) {

    }
    global void logMessage(String body) {

    }
    global void logParameter(String parameterName, Object value) {

    }
    global void logResults(List<Database.SaveResult> results, List<SObject> records) {

    }
    global void logResults(List<Database.UndeleteResult> results, List<SObject> records) {

    }
    global void logResults(List<Database.UpsertResult> results, List<SObject> records) {

    }
    global Negoptim__Log__c saveLog(Database.BatchableContext bc) {
        return null;
    }
    global void sendEmail(Database.BatchableContext bc, String customHtmlBody, String customSubject) {

    }
global enum BatchType {Stateful, Stateless}
}
