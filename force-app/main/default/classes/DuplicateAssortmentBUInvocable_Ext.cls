/**
* @author ULiT
* @description Duplicate assortment bu from another assortment bu 
* @date 7/9/2023
* */
public class DuplicateAssortmentBUInvocable_Ext {
    
    @InvocableMethod(label='Duplicate Assortment BU' description='Duplicate Assortment BU from another Assortment BU')
    public static List<duplicatedAssortment> duplicateAssortmentBU(List<AssortmentsWrapper> assortments) {
        AssortmentsWrapper assortment = assortments[0];
        String recordId = assortment.recordId;
        List<Id> clonedAssortmentBUIdList = new List<Id>();
        
        // get Assortment_BU__c fields        
        Map<String, Schema.SObjectField> assortmentBufields = Schema.Negoptim__Assortment_BU__c.sObjectType.getDescribe().fields.getMap();
        List<String> assortmentBUCreateUpdateFields = new List<String>();
        for (Schema.SObjectField field : assortmentBufields.values()) {
            Schema.DescribeFieldResult fieldResult = field.getDescribe();
            if (fieldResult.isCreateable() || fieldResult.isUpdateable()) {
                assortmentBUCreateUpdateFields.add(fieldResult.getName());
            }
        }
        
        // get current Assortment BU
        String queryAssortment = 'SELECT Id, Negoptim__Assortment_Parent_Objective__r.RecordType.DeveloperName, ' + String.join(assortmentBUCreateUpdateFields, ', ') ; 
        queryAssortment += ' FROM Negoptim__Assortment_BU__c';
        queryAssortment += ' WHERE Id = \'' + recordId + '\'';
        Negoptim__Assortment_BU__c currentAssortmentBU = Database.query(queryAssortment);
        
        Map<String, Negoptim__Assortment_BU__c> assortmnentBUMap = new Map<String, Negoptim__Assortment_BU__c>();
        Set<String> buSourceId = new Set<String>();
        Set<String> buTargetId = new Set<String>();
        
        // Generate Assortment BU for each selectedBUSource/selectedBUTarget
        for (SelectedBU bu : assortment.selectedBU) {
            Negoptim__Assortment_BU__c duplicatedAssortmentBU = currentAssortmentBU.clone(false, true, true, false);
            duplicatedAssortmentBU.Negoptim__BU_source__c = bu.selectedBUSource;
            duplicatedAssortmentBU.Negoptim__BU_Target__c = bu.selectedBUTarget;
            duplicatedAssortmentBU.Negoptim__Status__c = 'Open (in bulding process)';
            duplicatedAssortmentBU.Negoptim__Assortment_parent__c = null ;
            duplicatedAssortmentBU.Name = '';
            if (assortment.isGenerateRegionalAssortment) {
                duplicatedAssortmentBU.SPKERCADELACLevel__c = 'Regional';
            }
            if(currentAssortmentBU.Negoptim__Assortment_Parent_Objective__r.RecordType.DeveloperName == 'Simulation'){
                duplicatedAssortmentBU.Negoptim__Assortment_Parent_Objective__c = null;
            }
            String key = currentAssortmentBU.RecordTypeId + bu.selectedBUSource + bu.selectedBUTarget;
            assortmnentBUMap.put(key, duplicatedAssortmentBU);
            buSourceId.add(bu.selectedBUSource);
            buTargetId.add(bu.selectedBUTarget);
        } 
        List<Negoptim__Assortment_Detail__c> assortmentDetailsToInsert = new List<Negoptim__Assortment_Detail__c>();
        Map<String, Id> parentAssortmnentBuMap = new Map<String, Id>();
        List<Id> parentAssortmnentIds = new List<Id>();
        //get Parent Assortment if exists
        List<Negoptim__Assortment_BU__c> parentAssortment = [SELECT Id, Negoptim__BU_source__c, Negoptim__BU_Target__c, Negoptim__Assortment_parent__c, RecordTypeId
                                                             FROM Negoptim__Assortment_BU__c
                                                             WHERE Negoptim__BU_source__c IN :buSourceId
                                                             AND Negoptim__BU_Target__c IN :buTargetId
                                                             AND Negoptim__Status__c = 'Validated'
                                                             AND Negoptim__Year__c = :(Integer.valueOf(currentAssortmentBU.Negoptim__Year__c) - 1)
                                                             AND RecordTypeId = :currentAssortmentBU.RecordTypeId];
        if (parentAssortment != null && !parentAssortment.isEmpty()) {
            for (Negoptim__Assortment_BU__c parentAss : parentAssortment) {
                String key = String.valueOf(parentAss.RecordTypeId) + parentAss.Negoptim__BU_source__c + parentAss.Negoptim__BU_Target__c;
                parentAssortmnentBuMap.put(key, parentAss.Id);
                if (Negoptim.NegoptimHelper.checkAccessibility(Negoptim__Assortment_BU__c.SObjectType, assortmentBUCreateUpdateFields)) {
                    if (assortmnentBUMap.containsKey(key) && parentAssortmnentBuMap.size() != 0 && parentAssortmnentBuMap.containsKey(key)) {
                        Negoptim__Assortment_BU__c clonedAssortmentBU = assortmnentBUMap.get(key);
                        clonedAssortmentBU.Negoptim__Assortment_parent__c = parentAssortmnentBuMap.containsKey(key) ? parentAss.Id : null;
                        parentAssortmnentIds.add(parentAss.Id);
                        assortmnentBUMap.put(key, clonedAssortmentBU);
                        //assortmentBUToUpdate.add(assortmnentBUMap.get(key));
                    }
                }
            }
        }
        // Insert cloned Assortment BU
        if (Negoptim.NegoptimHelper.checkCreatibility(Negoptim__Assortment_BU__c.SObjectType, assortmentBUCreateUpdateFields)) {
           insert assortmnentBUMap.values();
        }
        if (!Test.isRunningTest()) {
           Negoptim.NegoptimBatch.executeBatch(new DuplicateAssortmentDetailBatch_Ext(DuplicateAssortmentBUInvocable_Ext.class.getName(), recordId, parentAssortmnentIds, assortmnentBUMap), 20);
        }
        if (assortment.isGenerateRegionalAssortment) {
            return null;  
        }
        return new List<duplicatedAssortment> { new duplicatedAssortment(String.valueOf(assortmnentBUMap.values()[0].Id))};
            }
    
    public class AssortmentsWrapper {
        @InvocableVariable(label='Assortment BU Id' description='Assortment BU Id' required=true)
        public String recordId;
        @InvocableVariable(label='List of selected Business Units' description='List of selected Business Units' required=true)
        public List<SelectedBU> selectedBU;
        @InvocableVariable(label='is Generate Regional Assortment' description='is Generate Regional Assortment' required=true)
        public Boolean isGenerateRegionalAssortment;
        public AssortmentsWrapper(){}
        public AssortmentsWrapper(String recordId, List<SelectedBU> selectedBU, Boolean isGenerateRegionalAssortment) {
            this.recordId = recordId;
            this.selectedBU = selectedBU;
            this.isGenerateRegionalAssortment = isGenerateRegionalAssortment;
        }
    }
    public class duplicatedAssortment{
        @InvocableVariable(label='record Id of duplicated assortment' description='record Id of duplicated assortment')
        public String duplicatedRecordId;
        duplicatedAssortment(String duplicatedRecordId){
            this.duplicatedRecordId = duplicatedRecordId;
        }
    }
}