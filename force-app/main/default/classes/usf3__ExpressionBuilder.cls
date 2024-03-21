/*
Ce fichier est généré ne correspond pas au code source de cette
classe globale gérée.
Ce fichier en lecture seule affiche les constructeurs globaux,
les méthodes, les variables et les propriétés de la classe.
Pour activer le code à compiler, toutes les méthodes renvoient null.
*/
global class ExpressionBuilder {
    global ExpressionBuilder() {

    }
    @AuraEnabled
    global static String assembleFormulaString(String customLogic, String logicType, String expressionLines) {
        return null;
    }
    global static String convertExpressionLines(usf3.ExpressionBuilder.ExpressionLineWrapper expressionLine) {
        return null;
    }
    global static List<usf3.ExpressionBuilder.ExpressionLineWrapper> convertSetToExpressionLineWrapper(Set<String> lines, String customVariableDelimiter) {
        return null;
    }
    global static String convertValueType(String fieldValue, String dataType) {
        return null;
    }
    @AuraEnabled
    global static Map<String,Object> disassemblyFormulaString(String expression, String customVariableDelimiter) {
        return null;
    }
    global static String simpleFormulaConversion(List<String> formulaItems, String logicType, Integer size) {
        return null;
    }
global class ExpressionLineWrapper {
    @AuraEnabled
    global String dataType;
    @AuraEnabled
    global String fieldName;
    @AuraEnabled
    global String objectType;
    @AuraEnabled
    global String operator;
    @AuraEnabled
    global String parameter;
    global ExpressionLineWrapper(String objectType, String fieldName, String dataType, String operator, String parameter) {

    }
}
}
