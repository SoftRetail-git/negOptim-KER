/*
Ce fichier est généré ne correspond pas au code source de cette
classe globale gérée.
Ce fichier en lecture seule affiche les constructeurs globaux,
les méthodes, les variables et les propriétés de la classe.
Pour activer le code à compiler, toutes les méthodes renvoient null.
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
