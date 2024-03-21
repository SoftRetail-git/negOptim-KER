/*
Ce fichier est généré ne correspond pas au code source de cette
classe globale gérée.
Ce fichier en lecture seule affiche les constructeurs globaux,
les méthodes, les variables et les propriétés de la classe.
Pour activer le code à compiler, toutes les méthodes renvoient null.
*/
global class SearchUtils {
    global static Map<String,String> TYPE_TO_ID_FIELD;
    global SearchUtils() {

    }
    @AuraEnabled
    global static Map<String,List<usf3.SearchUtils.Member>> describeSObjects(List<String> types) {
        return null;
    }
    global static Map<String,SObject> getMembersByTypeAndId(Map<String,Set<String>> typeToIds) {
        return null;
    }
    @AuraEnabled
    global static Map<String,SObject> getSingleMembersByTypeAndId(String type, String id) {
        return null;
    }
    @AuraEnabled
    global static Map<String,List<usf3.SearchUtils.Member>> searchMemberByType(List<String> memberTypes, String searchString) {
        return null;
    }
global class Member {
    @AuraEnabled
    global String dataType;
    @AuraEnabled
    global String label;
    @AuraEnabled
    global String type;
    @AuraEnabled
    global String value;
    global Member(String label, String value) {

    }
    global Member(String label, String value, String type, String dataType) {

    }
}
}
