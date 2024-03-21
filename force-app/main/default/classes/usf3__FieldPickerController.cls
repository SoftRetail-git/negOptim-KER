/*
Ce fichier est généré ne correspond pas au code source de cette
classe globale gérée.
Ce fichier en lecture seule affiche les constructeurs globaux,
les méthodes, les variables et les propriétés de la classe.
Pour activer le code à compiler, toutes les méthodes renvoient null.
*/
global class FieldPickerController {
    global FieldPickerController() {

    }
    @AuraEnabled
    global static List<usf3.FieldPickerController.Member> getObjects(List<String> availableObjectTypes) {
        return null;
    }
    @AuraEnabled
    global static List<usf3.FieldPickerController.Member> getPicklistValues(String objectApiName, String fieldName) {
        return null;
    }
global class Member implements System.Comparable {
    @AuraEnabled
    global Boolean isActive;
    @AuraEnabled
    global Boolean isDefaultValue;
    @AuraEnabled
    global String label;
    @AuraEnabled
    global String value;
    global Member(String value, String label) {

    }
    global Member(String value, String label, Boolean isActive, Boolean isDefaultValue) {

    }
    global Integer compareTo(Object compareTo) {
        return null;
    }
}
}
