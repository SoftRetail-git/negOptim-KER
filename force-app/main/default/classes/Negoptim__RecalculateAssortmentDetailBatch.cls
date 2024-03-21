/*
Ce fichier est généré ne correspond pas au code source de cette
classe globale gérée.
Ce fichier en lecture seule affiche les constructeurs globaux,
les méthodes, les variables et les propriétés de la classe.
Pour activer le code à compiler, toutes les méthodes renvoient null.
*/
global class RecalculateAssortmentDetailBatch implements Database.Batchable<SObject>, Database.Stateful {
    global RecalculateAssortmentDetailBatch(String startedFrom, List<Id> assortmentBUIds, List<Id> assortmentDetailIds, List<Id> buSourceList, List<Id> buTargetList, Integer year, Boolean L4LOnly, Boolean inPreparationOnly) {

    }
    global RecalculateAssortmentDetailBatch(String startedFrom, List<Id> assortmentBUIds, List<Id> assortmentDetailIds, List<Id> buSourceList, List<Id> buTargetList, Integer year, Boolean L4LOnly, Boolean inPreparationOnly, List<String> recordTypes) {

    }
    global void execute(Database.BatchableContext bc, List<Negoptim__Assortment_Detail__c> scope) {

    }
    global void finish(Database.BatchableContext bc) {

    }
    global Database.QueryLocator start(Database.BatchableContext bc) {
        return null;
    }
}
