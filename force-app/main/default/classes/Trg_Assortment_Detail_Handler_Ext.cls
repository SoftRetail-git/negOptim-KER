public class Trg_Assortment_Detail_Handler_Ext {
    
    public static void onBeforeInsert(List<Negoptim__Assortment_Detail__c> newAssortmentDetail) {
        removeVersion(newAssortmentDetail);
    }
    
    public static void onAfterInsertOrUpdate(List<Negoptim__Assortment_Detail__c> newAssortmentDetail, Map<Id, Negoptim__Assortment_Detail__c> oldAssortmentDetailMap) {
        aggregateFields(newAssortmentDetail, oldAssortmentDetailMap);
    }
    
    /**
	* @description remove ASD Version from Ext Id
	* */
    public static void removeVersion(List<Negoptim__Assortment_Detail__c> newAssortmentDetail) {
        for (Negoptim__Assortment_Detail__c item : newAssortmentDetail) {
            if (item.Negoptim__Ext_Id__c != null) {
                // remove version from Ext Id
                Integer lastIndexOf = item.Negoptim__Ext_Id__c.lastIndexOf('-');
                item.Negoptim__Ext_Id__c = item.Negoptim__Ext_Id__c.substring(0, lastIndexOf);
            }
        }
    }
    
    /**
	* @description Aggregate Result from ASD
	* */
    public static void aggregateFields(List<Negoptim__Assortment_Detail__c> newAssortmentDetail, Map<Id, Negoptim__Assortment_Detail__c> oldAssortmentDetailMap) {
        Set<Id> assortmentBUIds = new Set<Id>();
        List<Negoptim__Assortment_BU__c> assortmentBUListToUpdate = new List<Negoptim__Assortment_BU__c>();
        for (Negoptim__Assortment_Detail__c item : newAssortmentDetail) {
            if ((oldAssortmentDetailMap == null && (item.Negoptim__New_Client_ProductNumber_Gap__c != null))
               || (oldAssortmentDetailMap != null && (item.Negoptim__New_Client_ProductNumber_Gap__c != oldAssortmentDetailMap.get(item.Id).Negoptim__New_Client_ProductNumber_Gap__c)))
            {
                assortmentBUIds.add(item.Negoptim__Assortment_BU__c);
            }
        }
        if (!assortmentBUIds.isEmpty()) {
            List<AggregateResult> results = [SELECT Negoptim__Assortment_BU__c bu, SUM(Negoptim__New_Client_ProductNumber_Gap__c) New_Client_ProductNumber_Gap,
                                             SUM(Negoptim__NewClientNDCltBasedPtsGapNegoP1__c) NewClientNDCltBasedPtsGapNegoP1,
                                             SUM(Negoptim__New_Client_WD_MarketBased_Gap__c) New_Client_WD_MarketBased_Gap
                                             FROM Negoptim__Assortment_Detail__c
                                             WHERE Negoptim__Assortment_BU__c IN :assortmentBUIds
                                             GROUP BY Negoptim__Assortment_BU__c];
            for (AggregateResult result : results) {
                Id assortmentBUId = (Id) result.get('bu');
                assortmentBUListToUpdate.add(new Negoptim__Assortment_BU__c(Id = assortmentBUId,
                                                                            SPKERC_SumNewClientProductNumberGap__c = (Decimal) result.get('New_Client_ProductNumber_Gap'),
                                                                            SPKERC_SumNewClientNDCltBasedPtsGapNegoP__c = (Decimal) result.get('NewClientNDCltBasedPtsGapNegoP1'),
                                                                            SPKERC_SumNewClientWDMarketBasedGap__c = (Decimal) result.get('New_Client_WD_MarketBased_Gap')));
            }
            if (!assortmentBUListToUpdate.isEmpty()) {
                update assortmentBUListToUpdate;
            }
        }
    }

    
    
    /**
* @description consolidate AS & ASD
* */
    private static void consolidateAssortmentDetails(AssortmentWrapper assortmentWrapper, Map<Id, Negoptim__Assortment_Detail__c> oldAssortmentDetailsMap, Boolean afterDelete) {
        NegoptimSettings negoSettings = (NegoptimSettings) JSON.deserialize(Negoptim.GlobalSettingsManager.loadGlobalSettingsSerialized(), NegoptimSettings.class);
        if (!assortmentWrapper.isAssortmentUniqueAndBudget()) {
            List<Negoptim__Assortment_Detail__c> assortmentDetails = new List<Negoptim__Assortment_Detail__c>();
            Set<Id> countryOriginSet = new Set<Id>();
            Set<Id> buSourceSet = new Set<Id>();
            Set<Id> categorySet = new Set<Id>();
            Set<Id> productSet = new Set<Id>();
            Set<Integer> yearSet = new Set<Integer>();
            if(!afterDelete) {
                for (Negoptim__Assortment_Detail__c item : assortmentWrapper.assortmentDetails) {
                    Negoptim__Assortment_BU__c assortmentBU = assortmentWrapper.assortmentBUMap.get(item.Negoptim__Assortment_BU__c);
                    String recordType = assortmentBU.RecordType.DeveloperName;
                    if ((recordType == 'Nego' || recordType == 'Target' || recordType == 'Simulation') &&
                        item.Negoptim__Version__c == null /*&& (item.Negoptim__Status__c == 'Validated' || (item.Negoptim__Status__c == 'Request for Approval' && assortmentBU.Negoptim__Target_Simulation__c == true))) ||*/
                         /*(item.Negoptim__Status__c == 'Previously Validated' && item.Negoptim__Client_Status__c == 'Substitute')) &&
                        (oldAssortmentDetailsMap == null || (oldAssortmentDetailsMap.get(item.Id) != null && item.Negoptim__Status__c != oldAssortmentDetailsMap.get(item.Id).Negoptim__Status__c))*/)
                    {
                        assortmentDetails.add(item);
                    }
                }
            } else {
                assortmentDetails.addAll(oldAssortmentDetailsMap.values());
            }
            if (!assortmentDetails.isEmpty()) {
                for (Negoptim__Assortment_Detail__c item : assortmentDetails) {
                    if(assortmentWrapper.assortmentBUMap.containsKey(item.Negoptim__Assortment_BU__c)) {
                        Negoptim__Assortment_BU__c assortmentBU = assortmentWrapper.assortmentBUMap.get(item.Negoptim__Assortment_BU__c);
                        if(assortmentBU.Negoptim__BU_Target__r.Negoptim__Country_origin__c != null && !countryOriginSet.contains(assortmentBU.Negoptim__BU_Target__r.Negoptim__Country_origin__c)) {
                            countryOriginSet.add(assortmentBU.Negoptim__BU_Target__r.Negoptim__Country_origin__c);
                        }
                        if(assortmentBU.Negoptim__BU_Source__c != null && !buSourceSet.contains(assortmentBU.Negoptim__BU_Source__c)) {
                            buSourceSet.add(assortmentBU.Negoptim__BU_Source__c);
                        }
                        if(assortmentBU.Negoptim__Orga_HE__c != null && !categorySet.contains(assortmentBU.Negoptim__Orga_HE__c)) {
                            categorySet.add(assortmentBU.Negoptim__Orga_HE__c);
                        }
                        if(item.Negoptim__Product__c != null && !productSet.contains(item.Negoptim__Product__c)) {
                            productSet.add(item.Negoptim__Product__c);
                        }
                        if(item.Negoptim__Year__c != null && !yearSet.contains(Integer.valueOf(item.Negoptim__Year__c))) {
                            yearSet.add(Integer.valueOf(item.Negoptim__Year__c));
                        }
                    }
                }
                if(!System.isBatch() && !countryOriginSet.isEmpty() && !buSourceSet.isEmpty() && !categorySet.isEmpty() && !productSet.isEmpty() && !yearSet.isEmpty() && negoSettings.assortmentSynchroMode == 'Conso') {
                    // call batch ConsolidateAssortmentBatchExt
                    Negoptim.NegoptimBatch.executeBatch(new ConsolidateAssortmentBatchExt('Trg_Assortment_Detail_Handler', countryOriginSet, buSourceSet, categorySet, productSet, yearSet), 200);
                }
            }
        }
    }
    /* Assortment Wrapper Class */
    public with sharing class AssortmentWrapper {
        public Map<Id, Negoptim__Assortment_BU__c> allAssortmentBUMap {get; set;}
        public Map<Id, Negoptim__Assortment_BU__c> assortmentBUMap {get; set;} // excluding conso
        public List<Negoptim__Assortment_Detail__c> assortmentDetails {get; set;}
        
        public AssortmentWrapper(List<Negoptim__Assortment_Detail__c> newAssortmentDetails) {
            this.assortmentDetails  = new List<Negoptim__Assortment_Detail__c>();
            getNotConsolidateRecords(newAssortmentDetails);
        }
        
        // get not consolidate assortment details
        public void getNotConsolidateRecords(List<Negoptim__Assortment_Detail__c> newAssortmentDetails) {
            Set<Id> assortmentBUIdSet = new Set<Id>();
            for (Negoptim__Assortment_Detail__c item : newAssortmentDetails) {
                assortmentBUIdSet.add(item.Negoptim__Assortment_BU__c);
            }
            this.assortmentBUMap = new Map<Id, Negoptim__Assortment_BU__c>();
            String[] assortmentBUFields = new String[] {
                SObjectType.Negoptim__Assortment_BU__c.fields.Name.Name,
                    SObjectType.Negoptim__Assortment_BU__c.fields.Negoptim__Status__c.Name,
                    SObjectType.Negoptim__Assortment_BU__c.fields.Negoptim__Orga_HE__c.Name,
                    SObjectType.Negoptim__Assortment_BU__c.fields.Negoptim__BU_Target__c.Name,
                    SObjectType.Negoptim__Assortment_BU__c.fields.Negoptim__Ass_BDate__c.Name,
                    SObjectType.Negoptim__Assortment_BU__c.fields.Negoptim__Ass_EDate__c.Name,
                    SObjectType.Negoptim__Assortment_BU__c.fields.Negoptim__BU_Source__c.Name,
                    SObjectType.Negoptim__Assortment_BU__c.fields.Negoptim__Assortment_parent__c.Name,
                    SObjectType.Negoptim__Assortment_BU__c.fields.Negoptim__Assortment_Parent_Objective__c.Name,
                    SObjectType.Negoptim__Assortment_BU__c.fields.Negoptim__Is_Detail_Recently_updated__c.Name,
                    SObjectType.Negoptim__Assortment_BU__c.fields.Negoptim__Recent_Detail_updates__c.Name,
                    SObjectType.Negoptim__Assortment_BU__c.fields.Negoptim__Target_Simulation__c.Name
                    };
                        String[] orgaHEFields = new String[] {
                            SObjectType.Negoptim__Orga_HE__c.fields.Name.Name,
                                SObjectType.Negoptim__Orga_HE__c.fields.Negoptim__Path__c.Name,
                                SObjectType.Negoptim__Orga_HE__c.fields.Negoptim__Elt_Code__c.Name
                                };
                                    String[] orgaBUFields = new String[] {
                                        SObjectType.Negoptim__Orga_BU__c.fields.Name.Name,
                                            SObjectType.Negoptim__Orga_BU__c.fields.Negoptim__Country_origin__c.Name,
                                            SObjectType.Negoptim__Orga_BU__c.fields.Negoptim__IsMasterBU__c.Name,
                                            SObjectType.Negoptim__Orga_BU__c.fields.Negoptim__Multiple_Complementary__c.Name,
                                            SObjectType.Negoptim__Orga_BU__c.fields.Negoptim__SiteOfSales_Number__c.Name,
                                            SObjectType.Negoptim__Orga_BU__c.fields.Negoptim__SiteOfSales_Number_N1__c.Name,
                                            SObjectType.Negoptim__Orga_BU__c.fields.Negoptim__SiteOfSales_Number_P1__c.Name,
                                            SObjectType.Negoptim__Orga_BU__c.fields.Negoptim__SiteOfSales_Number_P2__c.Name
                                            };
                                                if (Negoptim.NegoptimHelper.checkAccessibility(Negoptim__Assortment_BU__c.SObjectType, assortmentBUFields)
                                                    && Negoptim.NegoptimHelper.checkAccessibility(Negoptim__Orga_HE__c.SObjectType, orgaHEFields)
                                                    && Negoptim.NegoptimHelper.checkAccessibility(Negoptim__Orga_BU__c.SObjectType, orgaBUFields))
                                            {
                                                this.allAssortmentBUMap = new Map<Id, Negoptim__Assortment_BU__c>([SELECT Id, Name, Negoptim__Status__c, Negoptim__Orga_HE__c, Negoptim__Orga_HE__r.Name, Negoptim__Orga_HE__r.Negoptim__Path__c, Negoptim__Orga_HE__r.Negoptim__Elt_Code__c, Negoptim__BU_Target__c, Negoptim__Ass_BDate__c, Negoptim__Ass_EDate__c,
                                                                                                                   Negoptim__BU_Source__r.Negoptim__Format_Origin__c, Negoptim__BU_Source__r.Negoptim__SiteOfSales_Number__c, Negoptim__BU_Source__r.Negoptim__SiteOfSales_Number_N1__c, Negoptim__BU_Source__r.Negoptim__SiteOfSales_Number_P1__c, Negoptim__BU_Source__r.Negoptim__SiteOfSales_Number_P2__c,
                                                                                                                   Negoptim__Assortment_parent__c, Negoptim__Assortment_parent__r.RecordType.DeveloperName, Negoptim__Assortment_Parent__r.Negoptim__Ass_BDate__c, Negoptim__Assortment_Parent__r.Negoptim__Ass_EDate__c,
                                                                                                                   Negoptim__Assortment_Parent_Objective__c, Negoptim__Assortment_Parent_Objective__r.RecordType.DeveloperName,
                                                                                                                   Negoptim__BU_Source__c, Negoptim__BU_Target__r.Name, Negoptim__BU_Target__r.Negoptim__Country_origin__c, Negoptim__BU_Target__r.Negoptim__IsMasterBU__c, Negoptim__BU_Target__r.Negoptim__Multiple_Complementary__c,
                                                                                                                   Negoptim__BU_Target__r.Negoptim__Weighted_Distribution_Manual__c, Negoptim__BU_Target__r.Negoptim__Weighted_Distribution_Manual_N1__c, Negoptim__BU_Target__r.Negoptim__Weighted_Distribution_Manual_P1__c, Negoptim__BU_Target__r.Negoptim__Weighted_Distribution_Manual_P2__c,
                                                                                                                   Negoptim__BU_Target__r.Negoptim__SiteOfSales_Number__c, Negoptim__BU_Target__r.Negoptim__SiteOfSales_Number_N1__c, Negoptim__BU_Target__r.Negoptim__SiteOfSales_Number_P1__c, Negoptim__BU_Target__r.Negoptim__SiteOfSales_Number_P2__c,
                                                                                                                   Negoptim__Year__c, RecordType.DeveloperName, Negoptim__BU_Source__r.Negoptim__IsMasterBU__c,
                                                                                                                   Negoptim__Is_Detail_Recently_updated__c, Negoptim__Recent_Detail_updates__c, Negoptim__Target_Simulation__c
                                                                                                                   FROM Negoptim__Assortment_BU__c
                                                                                                                   WHERE Id IN :assortmentBUIdSet]);
                                                for (Negoptim__Assortment_Detail__c item : newAssortmentDetails) {
                                                    Negoptim__Assortment_BU__c assortmentBU = this.allAssortmentBUMap.get(item.Negoptim__Assortment_BU__c);
                                                    if (assortmentBU != null && assortmentBU.RecordType.DeveloperName != 'Conso' && assortmentBU.RecordType.DeveloperName != 'Conso_Target'/* && item.Promo_Event_Detail__c == null*/) {
                                                        this.assortmentDetails.add(item);
                                                        this.assortmentBUMap.put(assortmentBU.Id, assortmentBU);
                                                    }
                                                }
                                            }
        }
        
        public boolean isAssortmentUniqueAndBudget() {
            return assortmentBUMap != null && assortmentBUMap.size() == 1 && assortmentBUMap.values().get(0).RecordType.DeveloperName == 'Budget';
        }
    }
    
    
	public class NegoptimSettings {
    // synchro mode for assortment bus (conso or diffusion)
    public String assortmentSynchroMode {get; set;}
	}
}