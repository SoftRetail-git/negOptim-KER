/*
This file is generated and isn't the actual source code for this
managed global class.
This read-only file shows the class's global constructors,
methods, variables, and properties.
To enable code to compile, all methods return null.
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
