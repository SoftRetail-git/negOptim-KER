/*
Ce fichier est généré ne correspond pas au code source de cette
classe globale gérée.
Ce fichier en lecture seule affiche les constructeurs globaux,
les méthodes, les variables et les propriétés de la classe.
Pour activer le code à compiler, toutes les méthodes renvoient null.
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
