/**
* @author ULiT
* @description Handler for the trigger Trg_Assortment_BU_Ext
* @date 08/09/2023
* */
public class Trg_Assortment_BU_Handler_Ext {
    public static final Map<String, Id> assortmentRTIds = Negoptim.NegoptimHelper.getObjectRecordTypeMapIds(Negoptim__Assortment_BU__c.SObjectType);
    
    public static void onBeforeInsert(List<Negoptim__Assortment_BU__c> newAssortmentBUList) {
        system.debug('newAssortmentBUList >>> ' + JSON.serialize(newAssortmentBUList));
        populateFields(newAssortmentBUList);
    }
    
    public static void onAfterInsert(List<Negoptim__Assortment_BU__c> newAssortmentBUList) {
        generateASDTargetAssortment(newAssortmentBUList);
    }
    
    public static void onAfterUpdate(List<Negoptim__Assortment_BU__c> newAssortmentBU, Map<Id, Negoptim__Assortment_BU__c> oldAssortmentBUMap) {
        CheckOnTopUnicity(newAssortmentBU, oldAssortmentBUMap);
        generateTargetAssortment(newAssortmentBU, oldAssortmentBUMap);
    }
    
    /**
	* @description search if there is already an onTop match on the same key = (RT+ Target BU+ source BU+ Year) and deselect it
	* */
    public static void CheckOnTopUnicity(List<Negoptim__Assortment_BU__c> newAssortmentBU, Map<Id, Negoptim__Assortment_BU__c> oldAssortmentBUMap) {
        List<Negoptim__Assortment_BU__c> assortmentsToUpdate = new List<Negoptim__Assortment_BU__c>();
        Set<Id> buSourceIds = new Set<Id>();
        Set<Id> buTargetIds =  new Set<Id>();
        Set<Id> recordTypeIds =  new Set<Id>();
        Set<Decimal> yearSet = new Set<Decimal>();
        Set<String> keys = new Set<String>();
        
        for (Negoptim__Assortment_BU__c assortmentBu : newAssortmentBU) {
            if (oldAssortmentBUMap != null 
                && oldAssortmentBUMap.containsKey(assortmentBu.Id) 
                && assortmentBu.SPKERCADELACVersionforcompilation__c 
                && !oldAssortmentBUMap.get(assortmentBu.Id).SPKERCADELACVersionforcompilation__c) 
            {
                String key = assortmentBu.Negoptim__BU_source__c + '' + assortmentBu.Negoptim__BU_Target__c + assortmentBu.Negoptim__Year__c + assortmentBu.RecordTypeId;
                keys.add(key);
                buSourceIds.add(assortmentBu.Negoptim__BU_source__c);
                buTargetIds.add(assortmentBu.Negoptim__BU_Target__c);
                yearSet.add(assortmentBu.Negoptim__Year__c);
                recordTypeIds.add(assortmentBu.RecordTypeId);
            }
        }
        List<Negoptim__Assortment_BU__c> matchedAssortmentBu = [SELECT SPKERCADELACVersionforcompilation__c, Negoptim__BU_source__c, Negoptim__BU_Target__c, Negoptim__Year__c, RecordTypeId 
                                                                FROM Negoptim__Assortment_BU__c
                                                                WHERE Negoptim__BU_source__c IN :buSourceIds
                                                                AND Negoptim__BU_Target__c IN :buTargetIds 
                                                                AND Negoptim__Year__c IN :yearSet 
                                                                AND RecordTypeId IN :recordTypeIds
                                                                AND SPKERCADELACVersionforcompilation__c = TRUE
                                                                AND ID NOT IN :newAssortmentBU];
        for (Negoptim__Assortment_BU__c assortmentBu : matchedAssortmentBu) {
            String key = assortmentBu.Negoptim__BU_source__c + '' + assortmentBu.Negoptim__BU_Target__c + assortmentBu.Negoptim__Year__c + assortmentBu.RecordTypeId;
            if (keys.contains(key)) {
                assortmentBu.SPKERCADELACVersionforcompilation__c = false;
                assortmentsToUpdate.add(assortmentBu);
            }      
        }
        if (!assortmentsToUpdate.isEmpty()) {
            system.debug('assortmentsToUpdate >> '+ assortmentsToUpdate);
            update assortmentsToUpdate;
        }
    }
    
    /**
     * @description populate Status__c, Ext_Id__c, Name and Simulation_version__c
     * Status__c = Open (in bulding process) if record is a clone and the cloned record was validated
     * Ext_Id__c = null if record is a clone
     * Name = Name_Prefix__c + '-V' + le calculated version number;
     *
	*/
    public static void populateFields(List<Negoptim__Assortment_BU__c> newAssortmentBUList) {
        Map<Id, String> assortmentBU_RTIds = Negoptim.NegoptimHelper.getObjectRecordTypeMapLabels(Negoptim__Assortment_BU__c.SObjectType);
        Set<Id> buTargetIdSet = new Set<Id>();
        Map<String, Decimal> assortmentVersionMap = new Map<String, Decimal>();
        for (Negoptim__Assortment_BU__c item : newAssortmentBUList) {
            if (item.RecordTypeId == assortmentRTIds.get('Simulation')) {
                item.Negoptim__Assortment_Parent_Objective__c = null;
            }
            buTargetIdSet.add(item.Negoptim__BU_Target__c);
        }
        Map<Id, Negoptim__Orga_BU__c> buMap = new Map<Id, Negoptim__Orga_BU__c>([SELECT Id, Negoptim__Ext_Id__c FROM Negoptim__Orga_BU__c WHERE Id IN :buTargetIdSet]);
        for (Negoptim__Assortment_BU__c item : newAssortmentBUList) {
            if (item.Id == null) {
                item.Negoptim__Ext_Id__c = buMap.get(item.Negoptim__BU_Target__c).Negoptim__Ext_Id__c + '-'
                    + (assortmentBU_RTIds.get(item.RecordTypeId) + '-'
                       + (item.Negoptim__Contract__c != null ? item.Negoptim__Contract__c + '-' : '')
                       + Integer.valueOf(item.Negoptim__Year__c) + '-'
                       + (item.Negoptim__Simulation_version__c == null ? '' : '-V' + item.Negoptim__Simulation_version__c)); 
            }
        }
    }
    
    /**
     * @description Generate Assortment target on pre Validate Assortment Budget
	*/
    public static void generateTargetAssortment(List<Negoptim__Assortment_BU__c> newAssortmentBUList, Map<Id, Negoptim__Assortment_BU__c> oldAssortmentBUMap) {
        List<Negoptim__Assortment_BU__c> preValidatedBudgets = new List<Negoptim__Assortment_BU__c>();
        List<Negoptim__Assortment_BU__c> targetAssortmentsToInsert = new List<Negoptim__Assortment_BU__c>();
        Set<Integer> yearSet = new Set<Integer>();
        Set<Id> buTargetIdSet = new Set<Id>();
        Set<Id> categoryIdSet = new Set<Id>();
        for (Negoptim__Assortment_BU__c item : newAssortmentBUList) {
            if (item.RecordTypeId == assortmentRTIds.get('Budget')
                && oldAssortmentBUMap != null
                && oldAssortmentBUMap.containskey(item.Id)
                && item.Negoptim__Status__c != oldAssortmentBUMap.get(item.Id).Negoptim__Status__c
                && item.Negoptim__Status__c == 'Pre Validate')
            {
                preValidatedBudgets.add(item);
                yearSet.add(Integer.valueOf(item.Negoptim__Year__c) - 1);
                buTargetIdSet.add(item.Negoptim__BU_Target__c);
                categoryIdSet.add(item.Negoptim__Orga_HE__c);
            }
        }
        if (!preValidatedBudgets.isEmpty()) {
            List<Negoptim__Assortment_BU__c> negoAssortments = [SELECT Id, Negoptim__BU_Target__c, RecordType.DeveloperName, ownerId
                                                                FROM Negoptim__Assortment_BU__c
                                                                WHERE RecordType.DeveloperName = 'Nego'
                                                                AND Negoptim__Status__c = 'Validated'
                                                                AND Negoptim__Assortment_Type__c = 'Out'
                                                                AND Negoptim__Year__c = :yearSet
                                                                AND Negoptim__BU_Source__c = :buTargetIdSet
                                                                AND Negoptim__Orga_HE__c = :categoryIdSet];
            Map<String, List<Negoptim__Assortment_BU__c>> negoAssortmentMap = new Map<String, List<Negoptim__Assortment_BU__c>>();
            for (Negoptim__Assortment_BU__c item : negoAssortments) {
                String key = item.Negoptim__Year__c + '' + item.Negoptim__BU_Source__c + '' + item.Negoptim__Orga_HE__c;
                if (!negoAssortmentMap.containsKey(key)) {
                    negoAssortmentMap.put(key, new List<Negoptim__Assortment_BU__c>());
                }
                negoAssortmentMap.get(key).add(item);
            }
            for (Negoptim__Assortment_BU__c preValidateBudget : preValidatedBudgets) {
                String key = (preValidateBudget.Negoptim__Year__c + 1) + '' + preValidateBudget.Negoptim__BU_Target__c + '' + preValidateBudget.Negoptim__Orga_HE__c;
                if (negoAssortmentMap.containsKey(key)) {
                    for (Negoptim__Assortment_BU__c negoAssortment : negoAssortmentMap.get(key)) {
                        Negoptim__Assortment_BU__c targetAssortment = new Negoptim__Assortment_BU__c(Name = 'buId',
                                                                                                     Negoptim__BU_Source__c = preValidateBudget.Negoptim__BU_Target__c,
                                                                                                     Negoptim__BU_Target__c = negoAssortment.Negoptim__BU_Target__c,
                                                                                                     Negoptim__Orga_HE__c = preValidateBudget.Negoptim__Orga_HE__c,
                                                                                                     Negoptim__Ass_BDate__c = preValidateBudget.Negoptim__Ass_BDate__c,
                                                                                                     Negoptim__Ass_EDate__c = preValidateBudget.Negoptim__Ass_EDate__c,
                                                                                                     Negoptim__Year__c = preValidateBudget.Negoptim__Year__c,
                                                                                                     Negoptim__Assortment_type__c = 'In',
                                                                                                     Negoptim__Assortment__c = 'Target',
                                                                                                     Negoptim__Status__c = 'Open (in bulding process)',
                                                                                                     RecordTypeId = assortmentRTIds.get('Target'),
                                                                                                     Negoptim__Assortment_Parent_Objective__c = preValidateBudget.Id,
                                                                                                     Negoptim__Assortment_Parent__c = negoAssortment.Id,
                                                                                                     ownerId = negoAssortment.ownerId);
                        targetAssortmentsToInsert.add(targetAssortment);
                    }
                }
            }
            if (!targetAssortmentsToInsert.isEmpty()) {
                insert targetAssortmentsToInsert;
            }
        }
    }
    
    /**
     * @description Generate ASD target on insert
	*/
    public static void generateASDTargetAssortment(List<Negoptim__Assortment_BU__c> newAssortmentBUList) {
        for (Negoptim__Assortment_BU__c item : newAssortmentBUList) {
            if (item.RecordTypeId == assortmentRTIds.get('Target')
                && item.Negoptim__Assortment_Parent_Objective__c != null
                && item.Negoptim__Assortment_Parent__c != null)
            {
                Negoptim.NegoptimBatch.executeBatch(new Negoptim.GenerateAssortmentTargetDetailsBatch(Trg_Assortment_BU_Handler_Ext.class.getName() + ' - generateASDTargetAssortment', item.Negoptim__Assortment_Parent_Objective__c), 20);
            }
        }
    }
    /**
     * @description Generate Assortment Nego on Validate Assortment simulation
	*/
    public static void generateNegoAssortment(List<Negoptim__Assortment_BU__c> newAssortmentBUList, Map<Id, Negoptim__Assortment_BU__c> oldAssortmentBUMap) {
        List<Negoptim__Assortment_BU__c> validatedSimulations = new List<Negoptim__Assortment_BU__c>();
        Map<String, Negoptim__Assortment_BU__c> validatedSimulationsMap = new Map<String, Negoptim__Assortment_BU__c>();
        List<Negoptim__Assortment_BU__c> negoAssortmentToInsert = new List<Negoptim__Assortment_BU__c>();
        Map<String, Negoptim__Assortment_BU__c> negoAssortmentMap = new Map<String, Negoptim__Assortment_BU__c>();
        Set<Integer> previousYearSet = new Set<Integer>();
        Set<Integer> yearSet = new Set<Integer>();
        Set<Id> buTargetIdSet = new Set<Id>();
        Set<Id> categoryIdSet = new Set<Id>();
        for (Negoptim__Assortment_BU__c item : newAssortmentBUList) {
            if (item.RecordTypeId == assortmentRTIds.get('Simulation')
                && oldAssortmentBUMap != null
                && oldAssortmentBUMap.containskey(item.Id)
                && item.Negoptim__Status__c != oldAssortmentBUMap.get(item.Id).Negoptim__Status__c
                && item.Negoptim__Status__c == 'Validate')
            {
                validatedSimulations.add(item);
                previousYearSet.add(Integer.valueOf(item.Negoptim__Year__c) - 1);
                yearSet.add(Integer.valueOf(item.Negoptim__Year__c));
                buTargetIdSet.add(item.Negoptim__BU_Target__c);
                categoryIdSet.add(item.Negoptim__Orga_HE__c);
                validatedSimulationsMap.put(item.Negoptim__BU_Target__c + '-' + item.Negoptim__Orga_HE__c, item);
            }
        }
        if (!validatedSimulations.isEmpty()) {
            List<Negoptim__Assortment_BU__c> negoAssortments = [SELECT Id, Negoptim__BU_Target__c, RecordType.DeveloperName, ownerId
                                                                FROM Negoptim__Assortment_BU__c
                                                                WHERE RecordType.DeveloperName = 'Nego'
                                                                AND Negoptim__Status__c = 'Validated'
                                                                AND Negoptim__Assortment_Type__c = 'Out'
                                                                AND Negoptim__Year__c = :yearSet
                                                                AND Negoptim__BU_Source__c = :buTargetIdSet
                                                                AND Negoptim__Orga_HE__c = :categoryIdSet];
            if(!negoAssortments.isEmpty()){
                for (Negoptim__Assortment_BU__c negoAss : negoAssortments) {
                    String key = negoAss.Negoptim__BU_Target__c + '-' + negoAss.Negoptim__Orga_HE__c;
                    updateASD(validatedSimulationsMap.get(key), negoAss);
                }
            } else  {
                List<Negoptim__Assortment_BU__c> negoAssortmentsOfLastYear = [SELECT Id, Negoptim__BU_Target__c, RecordType.DeveloperName, ownerId
                                                                                FROM Negoptim__Assortment_BU__c
                                                                                WHERE RecordType.DeveloperName = 'Nego'
                                                                                AND Negoptim__Status__c = 'Validated'
                                                                                AND Negoptim__Assortment_Type__c = 'Out'
                                                                                AND Negoptim__Year__c = :previousYearSet
                                                                                AND Negoptim__BU_Source__c = :buTargetIdSet
                                                                                AND Negoptim__Orga_HE__c = :categoryIdSet];
                for(Negoptim__Assortment_BU__c negoAssLastYear : negoAssortmentsOfLastYear){
                    String key = negoAssLastYear.Negoptim__Year__c + '-' + negoAssLastYear.Negoptim__BU_Source__c + '-' + negoAssLastYear.Negoptim__Orga_HE__c;
                    if (!negoAssortmentMap.containsKey(key)) {
                        negoAssortmentMap.put(key, negoAssLastYear);
                    }
                }
                for (Negoptim__Assortment_BU__c validatedSimulation : validatedSimulations) {
                    String key = validatedSimulation.Negoptim__Year__c + '-' + validatedSimulation.Negoptim__BU_Source__c + '-' + validatedSimulation.Negoptim__Orga_HE__c;
                    Negoptim__Assortment_BU__c negoAssortment = new Negoptim__Assortment_BU__c(Name = 'nego-Ass',
                                                                                                Negoptim__BU_Source__c = validatedSimulation.Negoptim__BU_Target__c,
                                                                                                Negoptim__BU_Target__c = validatedSimulation.Negoptim__BU_Target__c,
                                                                                                Negoptim__Orga_HE__c = validatedSimulation.Negoptim__Orga_HE__c,
                                                                                                Negoptim__Ass_BDate__c = validatedSimulation.Negoptim__Ass_BDate__c,
                                                                                                Negoptim__Ass_EDate__c = validatedSimulation.Negoptim__Ass_EDate__c,
                                                                                                Negoptim__Year__c = validatedSimulation.Negoptim__Year__c,
                                                                                                Negoptim__Assortment_type__c = 'In',
                                                                                                Negoptim__Status__c = 'Open (in bulding process)',
                                                                                                RecordTypeId = assortmentRTIds.get('Nego'),
                                                                                                // Negoptim__Assortment_Parent_Objective__c = validatedSimulation.Id,
                                                                                                Negoptim__Assortment_Parent__c = negoAssortmentMap.get(key).Id);
                    negoAssortmentToInsert.add(negoAssortment);
                }
            }
            if (!negoAssortmentToInsert.isEmpty()) {
                insert negoAssortmentToInsert;
            }
        }
    }
    public static void updateASD(Negoptim__Assortment_BU__c simulationAssortment, Negoptim__Assortment_BU__c negoAssortment) {
        Map<Id,Negoptim__Assortment_Detail__c> simulASDMap = new Map<Id,Negoptim__Assortment_Detail__c>();
        List<Negoptim__Assortment_Detail__c> negoASDToUpdate = new List<Negoptim__Assortment_Detail__c>();
        List<Negoptim__Assortment_Detail__c> negoASDList = [SELECT Id, Negoptim__Product__c
                                                            FROM Negoptim__Assortment_Detail__c
                                                            WHERE Negoptim__Assortment_BU__c = :negoAssortment.Id];
        List<Negoptim__Assortment_Detail__c> simulationASDList = [SELECT Id, Negoptim__Product__c
                                                                FROM Negoptim__Assortment_Detail__c
                                                                WHERE Negoptim__Assortment_BU__c = :simulationAssortment.Id];

        for(Negoptim__Assortment_Detail__c asdSimul : simulationASDList){
            simulASDMap.put(asdSimul.Negoptim__Product__c, asdSimul);
        }
        
        for(Negoptim__Assortment_Detail__c asdNego : negoASDList){
            if(!simulASDMap.containsKey(asdNego.Negoptim__Product__c)){
                asdNego.Negoptim__Client_Status__c = 'Delete';
                negoASDToUpdate.add(asdNego);
            }
        }
        if(!negoASDToUpdate.isEmpty()){
            update negoASDToUpdate;
        }
    }
}