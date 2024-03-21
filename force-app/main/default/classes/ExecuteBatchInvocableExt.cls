/**
 * @author ULiT
 * @date 19/03/2024
 * @description executes batches, used in screen flows
*/
global class ExecuteBatchInvocableExt {
        
    @InvocableMethod(label = 'ExecuteBatch')
    global static void execute(List<BatchParametersWrapper> batchParamsList) {
        if (batchParamsList != null && !batchParamsList.isEmpty()) {
            BatchParametersWrapper batchParams = batchParamsList[0];
            switch on batchParams.batchName {
                when 'ConsolidateAssortmentBatchExt' {
                    List<Negoptim__Assortment_BU__c> assortments = [SELECT Id, Negoptim__BU_Source__c, Negoptim__Orga_HE__c, Negoptim__Year__c,
                                                                    Negoptim__BU_Target__r.Negoptim__Country_origin__c
                                                                    FROM Negoptim__Assortment_BU__c
                                                                    WHERE Id = :batchParams.recordId];
                    if (!assortments.isEmpty()) {
                        Negoptim.NegoptimBatch.executeBatch(new ConsolidateAssortmentBatchExt(ExecuteBatchInvocableExt.class.getName() + ' [' + batchParams.startedFrom + ']',
                                                                                              new Set<Id>{assortments[0].Negoptim__BU_Target__r.Negoptim__Country_origin__c},
                                                                                              new Set<Id>{assortments[0].Negoptim__BU_Source__c},
                                                                                              new Set<Id>{assortments[0].Negoptim__Orga_HE__c},
                                                                                              NULL,
                                                                                              new Set<Integer>{Integer.valueOf(assortments[0].Negoptim__Year__c)}), 200);
                    }
                }
            }
        }
    }
    
    global class BatchParametersWrapper {
        
        @InvocableVariable(required=true)
        global String batchName;
        @InvocableVariable
        global String startedFrom;
        @InvocableVariable
        global Id recordId;
    }
}