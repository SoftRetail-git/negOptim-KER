/*
This file is generated and isn't the actual source code for this
managed global class.
This read-only file shows the class's global constructors,
methods, variables, and properties.
To enable code to compile, all methods return null.
*/
global class AssortmentServices {
    global Map<Id,Negoptim.AssortmentServices.ResultWrapper> resultWrapperMap;
    global AssortmentServices(List<Negoptim__Assortment_Detail__c> assortmentDetailsList) {

    }
    global AssortmentServices(Set<Id> assortmentDetailsIdSet) {

    }
    global Map<Integer,Negoptim__Orga_BU__c> getCpltClusters(Negoptim__Assortment_Detail__c assortmentDetail) {
        return null;
    }
    global Map<Id,Negoptim__Assortment_Detail__c> getLastMovementHistory() {
        return null;
    }
    global Negoptim.AssortmentServices.ResultWrapper getResultWrapperForAssortment(Id buTargetId) {
        return null;
    }
    global Map<Id,Negoptim__Orga_BU__c> getStratClusters(Negoptim__Assortment_Detail__c assortmentDetail) {
        return null;
    }
global class ResultWrapper {
    global Map<Id,Map<Integer,Negoptim__Orga_BU__c>> categoryCpltMap {
        get;
        set;
    }
    global Map<Id,Map<Integer,Negoptim__Orga_BU__c>> categoryStratMap {
        get;
        set;
    }
}
}
