/*
 * @author ULiT
 * @date 19-03-2024
 * @description
 * 1- case consolidate assortment details by Assortment_BU__r.Orga_HE__c + BU_Target__r.Related_Client__c + BU_Target__r.Country_Origin + BU_Target__r.Format_Origin__c
 * 2- case reset assortment details
 */
global with sharing class ConsolidateAssortmentBatchExt implements Database.Batchable<SObject>, Database.Stateful {

    private Negoptim.NegoptimBatch nb;
    private String query;
    private Set<Id> countrySet;
    private Set<Id> buSourceSet;
    private Set<Id> categorySet;
    private Set<Id> productSet;
    private Set<Integer> yearSet;
    private Set<Id> assortmentDetailConsoIds;
    private Set<Id> exceptValidatedAssortmentDetailsSet;
    private Integer P2 {get; set;}
    private Integer P1 {get; set;}
    private Integer N {get; set;}
    private Integer N1 {get; set;}
    /**
     * countryIds: selected country in MassBatchForm + updated assortment details (Trg_Assortment_Detail_Handler)
     * year: selected year in MassBatchForm + updated assortment details (Trg_Assortment_Detail_Handler)
     * buSourceIds, categoryIds, productIds : updated assortment details (Trg_Assortment_Detail_Handler)
     **/
    global ConsolidateAssortmentBatchExt(String startedFrom, Set<Id> countryIds, Set<Id> buSourceIds, Set<Id> categoryIds, Set<Id> productIds, Set<Integer> years) {
        this.nb = new Negoptim.NegoptimBatch(ConsolidateAssortmentBatchExt.class.getName(), Negoptim.NegoptimBatch.BatchType.Stateful, startedFrom);
        this.countrySet = countryIds;
        this.buSourceSet = buSourceIds;
        this.categorySet = categoryIds;
        this.productSet = productIds;
        this.yearSet = years;
        this.assortmentDetailConsoIds = new Set<Id>();
        this.exceptValidatedAssortmentDetailsSet = new Set<Id>();
        P2 = Date.today().year() - 2;
        P1 = Date.today().year() - 1;
        N = Date.today().year();
        N1 = Date.today().year() + 1;
        query = 'SELECT Id, Negoptim__Assortment_BU__r.RecordType.DeveloperName, Negoptim__Product__c, Negoptim__Year__c, Negoptim__Category__c, Negoptim__Assortment_BU__c, Negoptim__Movement_Date__c, Negoptim__Version__c, Negoptim__Last_History__c, Negoptim__Status__c, Negoptim__Client_Status__c, Negoptim__Last_History__r.Negoptim__Status__c,';
        query += ' Negoptim__Assortment_BU__r.Negoptim__Ass_BDate__c, Negoptim__Assortment_BU__r.Negoptim__Ass_EDate__c, Negoptim__Assortment_BU__r.Negoptim__Assortment_type__c, Negoptim__Assortment_BU__r.Negoptim__Assortment__c, Negoptim__Assortment_BU__r.RecordTypeId, Negoptim__Assortment_BU__r.Negoptim__Target_Simulation__c,';
        query += ' Negoptim__Assortment_BU__r.Negoptim__BU_Source__r.Negoptim__Related_Client__c, Negoptim__Assortment_BU__r.Negoptim__BU_Source__r.Negoptim__Country_origin__c, Negoptim__Assortment_BU__r.Negoptim__BU_Source__r.Negoptim__Format_Origin__c,';
        query += ' Negoptim__Assortment_BU__r.Negoptim__BU_Target__r.Negoptim__Related_Client__c, Negoptim__Assortment_BU__r.Negoptim__BU_Target__r.Negoptim__Country_origin__c, Negoptim__Assortment_BU__r.Negoptim__BU_Target__r.Negoptim__Format_Origin__c,';
        query += ' Negoptim__Assortment_BU__r.Negoptim__BU_Target__r.Negoptim__Weighted_Distribution_Manual_P2__c, Negoptim__Assortment_BU__r.Negoptim__BU_Target__r.Negoptim__Weighted_Distribution_Manual_P1__c,';
        query += ' Negoptim__Assortment_BU__r.Negoptim__BU_Target__r.Negoptim__Weighted_Distribution_Manual__c, Negoptim__Assortment_BU__r.Negoptim__BU_Target__r.Negoptim__Weighted_Distribution_Manual_N1__c,';
        query += ' Negoptim__Assortment_BU__r.Negoptim__BU_Source__c, Negoptim__Assortment_BU__r.Negoptim__BU_Target__c, Negoptim__Assortment_BU__r.Negoptim__Orga_HE__c,';
        query += ' Negoptim__Fact_WD_MarketBased__c,Negoptim__L4L_Client_ND_ClientBased__c,Negoptim__L4L_Client_ND_MarketBased__c,Negoptim__L4L_Client_ProductNumber__c,Negoptim__L4L_Client_WD_ClientBased__c,';
        query += ' Negoptim__L4L_Client_WD_MarketBased__c,Negoptim__New_Client_ND_ClientBased__c,Negoptim__New_Client_ND_MarketBased__c,Negoptim__New_Client_ProductNumber__c,Negoptim__New_Client_Quantity_SEQ__c,';
        query += ' Negoptim__New_Client_Quantity_YE__c,Negoptim__New_Client_WD_ClientBased__c,Negoptim__New_Client_WD_MarketBased__c,Negoptim__New_Corp_ND_ClientBased__c,Negoptim__New_Corp_ND_MarketBased__c,';
        query += ' Negoptim__New_Corp_WD_ClientBased__c,Negoptim__New_Corp_WD_MarketBased__c,Negoptim__New_Client_Unit_Cost__c,Negoptim__Ref_Client_Assortment__c, Negoptim__WD_Conso__c';
        query += ' FROM Negoptim__Assortment_Detail__c';
        query += ' WHERE Negoptim__Assortment_BU__r.RecordType.DeveloperName IN (\'Nego\', \'Target\', \'Simulation\') AND Negoptim__Movement_Date__c <> NULL';
        query += ' AND ((Negoptim__Status__c = \'Validated\' OR (Negoptim__Status__c = \'Request for Approval\' AND Negoptim__Version__c = NULL AND Negoptim__Assortment_BU__r.Negoptim__Target_Simulation__c = TRUE) OR (Negoptim__Version__c = NULL AND Negoptim__WD_Conso__c = TRUE))';
        query += ' OR (Negoptim__Status__c = \'Previously Validated\' AND Negoptim__Client_Status__c = \'Substitute\'))';
        query += ' AND Negoptim__Assortment_BU__r.Negoptim__Orga_HE__c <> NULL AND Negoptim__Assortment_BU__r.Negoptim__BU_Target__r.Negoptim__Format_Origin__c <> NULL AND Negoptim__Assortment_BU__r.Negoptim__BU_Target__r.Negoptim__Country_origin__c <> NULL';
        query += ' AND Negoptim__Assortment_BU__r.Negoptim__BU_Target__r.Negoptim__Layer_Nego_Conso__c = FALSE';
        if(this.countrySet != null) {
            query += ' AND Negoptim__Assortment_BU__r.Negoptim__BU_Target__r.Negoptim__Country_origin__c IN (\'' + String.join(new List<Id>(countrySet), '\',\'') +'\') ';
        }
        if(this.buSourceSet != null) {
            query += ' AND Negoptim__Assortment_BU__r.Negoptim__BU_Source__c IN (\'' + String.join(new List<Id>(buSourceSet), '\',\'') +'\') ';
        }
        if(this.categorySet != null) {
            query += ' AND Negoptim__Assortment_BU__r.Negoptim__Orga_HE__c IN (\'' + String.join(new List<Id>(categorySet), '\',\'') +'\') ';
        }
        if(this.productSet != null) {
            query += ' AND Negoptim__Product__c IN (\'' + String.join(new List<Id>(productSet), '\',\'') +'\') ';
        }
        if(this.yearSet != null) {
            query += ' AND Negoptim__Year__c  IN (' + String.join(new List<Integer>(this.yearSet), ',') + ')';
        }
        query += ' ORDER BY Negoptim__Status__c ASC, Negoptim__Movement_Date__c DESC, Negoptim__Product__c';
        nb.logParameter('countryIds', countryIds);
        nb.logParameter('buSourceIds', buSourceIds);
        nb.logParameter('categoryIds', categoryIds);
        nb.logParameter('productIds', productIds);
        nb.logParameter('years', years);
        nb.logParameter('query', query);
    }

    global Database.QueryLocator start(Database.BatchableContext bc) {
        String[] assortmentBUFields = new String[] {
            SObjectType.Negoptim__Assortment_BU__c.fields.Id.Name,
                SObjectType.Negoptim__Assortment_BU__c.fields.RecordTypeId.Name,
                SObjectType.Negoptim__Assortment_BU__c.fields.Negoptim__Ass_BDate__c.Name,
                SObjectType.Negoptim__Assortment_BU__c.fields.Negoptim__Ass_EDate__c.Name,
                SObjectType.Negoptim__Assortment_BU__c.fields.Negoptim__Assortment_type__c.Name,
                SObjectType.Negoptim__Assortment_BU__c.fields.Negoptim__Assortment__c.Name,
                SObjectType.Negoptim__Assortment_BU__c.fields.Negoptim__BU_Source__c.Name,
                SObjectType.Negoptim__Assortment_BU__c.fields.Negoptim__BU_Target__c.Name,
                SObjectType.Negoptim__Assortment_BU__c.fields.Negoptim__Orga_HE__c.Name,
                SObjectType.Negoptim__Assortment_BU__c.fields.Negoptim__Target_Simulation__c.Name,
                SObjectType.Negoptim__Assortment_BU__c.fields.Negoptim__Assortment_parent__c.Name,
                SObjectType.Negoptim__Assortment_BU__c.fields.Negoptim__Year__c.Name,
                SObjectType.Negoptim__Assortment_BU__c.fields.Negoptim__Status__c.Name
                };
        String[] assortmentDetailFields = new String[] {
            SObjectType.Negoptim__Assortment_Detail__c.fields.Id.Name,
                SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__Product__c.Name,
                SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__Year__c.Name,
                SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__Category__c.Name,
                SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__Assortment_BU__c.Name,
                SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__Fact_WD_MarketBased__c.Name,
                SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__L4L_Client_ND_ClientBased__c.Name,
                SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__L4L_Client_ND_MarketBased__c.Name,
                SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__L4L_Client_ProductNumber__c.Name,
                SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__L4L_Client_WD_ClientBased__c.Name,
                SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__L4L_Client_WD_MarketBased__c.Name,
                SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__New_Client_ND_ClientBased__c.Name,
                SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__New_Client_ND_MarketBased__c.Name,
                SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__New_Client_ProductNumber__c.Name,
                SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__New_Client_Quantity_SEQ__c.Name,
                SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__New_Client_Quantity_YE__c.Name,
                SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__New_Client_WD_ClientBased__c.Name,
                SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__New_Client_WD_MarketBased__c.Name,
                SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__New_Corp_ND_ClientBased__c.Name,
                SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__New_Corp_ND_MarketBased__c.Name,
                SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__New_Corp_WD_ClientBased__c.Name,
                SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__New_Corp_WD_MarketBased__c.Name,
                SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__New_Client_Unit_Cost__c.Name,
                SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__Ref_Client_Assortment__c.Name,
                SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__Status__c.Name,
                SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__Version__c.Name,
                SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__Movement_Date__c.Name,
                SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__Client_Status__c.Name,
                SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__New_Client_LM__c.Name
                };
        String[] orgaBUFields = new String[] {
            SObjectType.Negoptim__Orga_BU__c.fields.Id.Name,
                SObjectType.Negoptim__Orga_BU__c.fields.Name.Name,
                SObjectType.Negoptim__Orga_BU__c.fields.Negoptim__Related_Client__c.Name,
                SObjectType.Negoptim__Orga_BU__c.fields.Negoptim__Country_origin__c.Name,
                SObjectType.Negoptim__Orga_BU__c.fields.Negoptim__Format_Origin__c.Name,
                SObjectType.Negoptim__Orga_BU__c.fields.Negoptim__Layer_Nego_Conso__c.Name,
                SObjectType.Negoptim__Orga_BU__c.fields.Negoptim__Weighted_Distribution_Manual_P2__c.Name,
                SObjectType.Negoptim__Orga_BU__c.fields.Negoptim__Weighted_Distribution_Manual_P1__c.Name,
                SObjectType.Negoptim__Orga_BU__c.fields.Negoptim__Weighted_Distribution_Manual__c.Name,
                SObjectType.Negoptim__Orga_BU__c.fields.Negoptim__Weighted_Distribution_Manual_N1__c.Name
                };
        if (Negoptim.NegoptimHelper.checkAccessibility(Negoptim__Assortment_BU__c.SObjectType, assortmentBUFields)
            && Negoptim.NegoptimHelper.checkAccessibility(Negoptim__Assortment_Detail__c.SObjectType, assortmentDetailFields)
            && Negoptim.NegoptimHelper.checkAccessibility(Negoptim__Orga_BU__c.SObjectType, orgaBUFields))
        {
            return Database.getQueryLocator(query);
        } else {
            return null;
        }
    }

    global void execute(Database.BatchableContext bc, List<Negoptim__Assortment_Detail__c> scope) {
        Set<Id> buSourceSet = new Set<Id>();
        Set<Id> clientSet = new Set<Id>();
        Set<Id> countryOriginSet = new Set<Id>();
        Set<Id> categorySet = new Set<Id>();
        Set<Id> productSet = new Set<Id>();
        Set<Integer> yearSet = new Set<Integer>();
        Set<Integer> previousYearSet = new Set<Integer>();
        Set<String> recordTypeSet = new Set<String>();
        List<Negoptim__Assortment_BU__c> assortmentBUConsoList = new List<Negoptim__Assortment_BU__c>();
        List<Negoptim__Assortment_Detail__c> assortmentDetailsUpdatedList = new List<Negoptim__Assortment_Detail__c>();
        Map<String, List<Negoptim__Assortment_Detail__c>> assortmentDetailsMap = new Map<String, List<Negoptim__Assortment_Detail__c>>();
        Map<String, Negoptim__Assortment_BU__c> assortmentBUConsoMap = new Map<String, Negoptim__Assortment_BU__c>();
        Map<String, Negoptim__Assortment_Detail__c> assortmentDetailConsoMap = new Map<String, Negoptim__Assortment_Detail__c>();
        Map<String, Negoptim__Assortment_BU__c> parentAssortmentBUConsoMap = new Map<String, Negoptim__Assortment_BU__c>();
        Map<String, Negoptim__Assortment_BU__c> parentObjAssortmentBUConsoMap = new Map<String, Negoptim__Assortment_BU__c>();
        Map<String, Negoptim__Assortment_Detail__c> parentAssortmentDetailConsoMap = new Map<String, Negoptim__Assortment_Detail__c>();
        Map<String, Negoptim__Assortment_Detail__c> parentObjAssortmentDetailConsoMap = new Map<String, Negoptim__Assortment_Detail__c>();
        Map<String, Negoptim__Orga_BU__c> buConsoMap = new Map<String, Negoptim__Orga_BU__c>();
        List<AssortmentConsoWrapper> assortmentConsoWrapperList = new List<AssortmentConsoWrapper>();

        for (Negoptim__Assortment_Detail__c item : scope) {
            // check excepted assortment details: Status='Request for Approval' and Last_History.Status='Validated'
            if(item.Negoptim__Status__c == 'Request for Approval' && item.Negoptim__Version__c == null && item.Negoptim__Assortment_BU__r.Negoptim__Target_Simulation__c == true && item.Negoptim__Last_History__c != null) {
                this.exceptValidatedAssortmentDetailsSet.add(item.Negoptim__Last_History__c);
            }
            if(item.Negoptim__Status__c == 'Validated' && item.Negoptim__Version__c != null && this.exceptValidatedAssortmentDetailsSet.contains(item.Id)) {
                continue;
            }
            if(!buSourceSet.contains(item.Negoptim__Assortment_BU__r.Negoptim__BU_Source__c)) {
                buSourceSet.add(item.Negoptim__Assortment_BU__r.Negoptim__BU_Source__c);
            }
            if(!clientSet.contains(item.Negoptim__Assortment_BU__r.Negoptim__BU_Target__r.Negoptim__Related_Client__c)) {
                clientSet.add(item.Negoptim__Assortment_BU__r.Negoptim__BU_Target__r.Negoptim__Related_Client__c);
            }
            if(item.Negoptim__Assortment_BU__r.Negoptim__BU_Target__r.Negoptim__Country_origin__c != null && !countryOriginSet.contains(item.Negoptim__Assortment_BU__r.Negoptim__BU_Target__r.Negoptim__Country_origin__c)) {
                countryOriginSet.add(item.Negoptim__Assortment_BU__r.Negoptim__BU_Target__r.Negoptim__Country_origin__c);
            }
            if(!categorySet.contains(item.Negoptim__Assortment_BU__r.Negoptim__Orga_HE__c)) {
                categorySet.add(item.Negoptim__Assortment_BU__r.Negoptim__Orga_HE__c);
            }
            if(!productSet.contains(item.Negoptim__Product__c)) {
                productSet.add(item.Negoptim__Product__c);
            }
            if(!yearSet.contains(Integer.valueOf(item.Negoptim__Year__c))) {
                yearSet.add(Integer.valueOf(item.Negoptim__Year__c));
                previousYearSet.add(Integer.valueOf(item.Negoptim__Year__c) - 1);
            }
            if(item.Negoptim__Assortment_BU__r.RecordType.DeveloperName == 'Nego' && !recordTypeSet.contains('Conso')) {
                recordTypeSet.add('Conso');
            } else if(item.Negoptim__Assortment_BU__r.RecordType.DeveloperName == 'Target' && !recordTypeSet.contains('Conso_Target')) {
                recordTypeSet.add('Conso_Target');
                if(!recordTypeSet.contains('Conso')) recordTypeSet.add('Conso');
            } else if(item.Negoptim__Assortment_BU__r.RecordType.DeveloperName == 'Simulation' && !recordTypeSet.contains('Conso_Simulation')) {
                recordTypeSet.add('Conso_Simulation');
                if(!recordTypeSet.contains('Conso_Target')) recordTypeSet.add('Conso_Target');
            }
            String key = item.Negoptim__Assortment_BU__r.RecordType.DeveloperName + '' + item.Negoptim__Assortment_BU__r.Negoptim__BU_Source__c + '' + item.Negoptim__Assortment_BU__r.Negoptim__Orga_HE__c + '' + item.Negoptim__Assortment_BU__r.Negoptim__BU_Target__r.Negoptim__Related_Client__c + '' +
                item.Negoptim__Assortment_BU__r.Negoptim__BU_Target__r.Negoptim__Country_origin__c + '' + getSortedFormatOrigin(item.Negoptim__Assortment_BU__r.Negoptim__BU_Target__r.Negoptim__Format_Origin__c) + '' + Integer.valueOf(item.Negoptim__Year__c);
            if(!assortmentDetailsMap.containsKey(key)) {
                assortmentDetailsMap.put(key, new List<Negoptim__Assortment_Detail__c>{item});
            } else {
                assortmentDetailsMap.get(key).add(item);
            }
        }
        // get BU conso
        if(!clientSet.isEmpty() && !countryOriginSet.isEmpty()) {
            // check security on Orga_BU__c fields
            String[] orgaBUFields = new String[] {
                SObjectType.Negoptim__Orga_BU__c.fields.Id.Name,
                    SObjectType.Negoptim__Orga_BU__c.fields.Name.Name,
                    SObjectType.Negoptim__Orga_BU__c.fields.Negoptim__Related_Client__c.Name,
                    SObjectType.Negoptim__Orga_BU__c.fields.Negoptim__Country_origin__c.Name,
                    SObjectType.Negoptim__Orga_BU__c.fields.Negoptim__Format_Origin__c.Name,
                    SObjectType.Negoptim__Orga_BU__c.fields.Negoptim__Layer_Nego_Conso__c.Name,
                    SObjectType.Negoptim__Orga_BU__c.fields.Negoptim__Weighted_Distribution_Manual_P2__c.Name,
                    SObjectType.Negoptim__Orga_BU__c.fields.Negoptim__Weighted_Distribution_Manual_P1__c.Name,
                    SObjectType.Negoptim__Orga_BU__c.fields.Negoptim__Weighted_Distribution_Manual__c.Name,
                    SObjectType.Negoptim__Orga_BU__c.fields.Negoptim__Weighted_Distribution_Manual_N1__c.Name
                    };
            if (Negoptim.NegoptimHelper.checkAccessibility(Negoptim__Orga_BU__c.SObjectType, orgaBUFields)) {
                for(Negoptim__Orga_BU__c item : [SELECT Id, Name, Negoptim__Country_origin__c, Negoptim__Format_Origin__c, Negoptim__Related_Client__c,
                                       Negoptim__Weighted_Distribution_Manual_P2__c, Negoptim__Weighted_Distribution_Manual_P1__c, Negoptim__Weighted_Distribution_Manual__c, Negoptim__Weighted_Distribution_Manual_N1__c
                                       FROM Negoptim__Orga_BU__c WHERE Negoptim__Related_Client__c IN :clientSet
                                       AND Negoptim__Country_origin__c IN : countryOriginSet
                                       AND Negoptim__Layer_Nego_Conso__c = TRUE AND Negoptim__Format_Origin__c <> NULL])
                {
                    String keyBU = item.Negoptim__Related_Client__c + '' + item.Negoptim__Country_origin__c  + '' + getSortedFormatOrigin(item.Negoptim__Format_Origin__c);
                    buConsoMap.put(keyBU, item);
                }
            }
        }
        // get Assortment conso
        if(!buSourceSet.isEmpty() && !yearSet.isEmpty()) {
            Set<Id> assortmentBUConsoSet = new Set<Id>();
            // check security on Assortment_BU__c fields
            String[] assortmentBUFields = new String[] {
                SObjectType.Negoptim__Assortment_BU__c.fields.Id.Name,
                    SObjectType.Negoptim__Assortment_BU__c.fields.RecordTypeId.Name,
                    SObjectType.Negoptim__Assortment_BU__c.fields.Negoptim__Ass_BDate__c.Name,
                    SObjectType.Negoptim__Assortment_BU__c.fields.Negoptim__Ass_EDate__c.Name,
                    SObjectType.Negoptim__Assortment_BU__c.fields.Negoptim__Assortment_type__c.Name,
                    SObjectType.Negoptim__Assortment_BU__c.fields.Negoptim__Assortment__c.Name,
                    SObjectType.Negoptim__Assortment_BU__c.fields.Negoptim__BU_Source__c.Name,
                    SObjectType.Negoptim__Assortment_BU__c.fields.Negoptim__BU_Target__c.Name,
                    SObjectType.Negoptim__Assortment_BU__c.fields.Negoptim__Orga_HE__c.Name,
                    SObjectType.Negoptim__Assortment_BU__c.fields.Negoptim__Target_Simulation__c.Name,
                    SObjectType.Negoptim__Assortment_BU__c.fields.Negoptim__Assortment_parent__c.Name,
                    SObjectType.Negoptim__Assortment_BU__c.fields.Negoptim__Year__c.Name,
                    SObjectType.Negoptim__Assortment_BU__c.fields.Negoptim__Status__c.Name
                    };
            // check security on Assortment_Detail__c fields
            String[] assortmentDetailFields = new String[] {
                SObjectType.Negoptim__Assortment_Detail__c.fields.Id.Name,
                    SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__Product__c.Name,
                    SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__Year__c.Name,
                    SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__Category__c.Name,
                    SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__Assortment_BU__c.Name,
                    SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__Fact_WD_MarketBased__c.Name,
                    SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__L4L_Client_ND_ClientBased__c.Name,
                    SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__L4L_Client_ND_MarketBased__c.Name,
                    SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__L4L_Client_ProductNumber__c.Name,
                    SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__L4L_Client_WD_ClientBased__c.Name,
                    SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__L4L_Client_WD_MarketBased__c.Name,
                    SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__New_Client_ND_ClientBased__c.Name,
                    SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__New_Client_ND_MarketBased__c.Name,
                    SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__New_Client_ProductNumber__c.Name,
                    SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__New_Client_Quantity_SEQ__c.Name,
                    SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__New_Client_Quantity_YE__c.Name,
                    SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__New_Client_WD_ClientBased__c.Name,
                    SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__New_Client_WD_MarketBased__c.Name,
                    SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__New_Corp_ND_ClientBased__c.Name,
                    SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__New_Corp_ND_MarketBased__c.Name,
                    SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__New_Corp_WD_ClientBased__c.Name,
                    SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__New_Corp_WD_MarketBased__c.Name,
                    SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__New_Client_Unit_Cost__c.Name,
                    SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__Ref_Client_Assortment__c.Name,
                    SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__Status__c.Name,
                    SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__Version__c.Name,
                    SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__New_Client_LM__c.Name
                    };
            String[] orgaBUFields = new String[] {
                SObjectType.Negoptim__Orga_BU__c.fields.Id.Name,
                    SObjectType.Negoptim__Orga_BU__c.fields.Name.Name,
                    SObjectType.Negoptim__Orga_BU__c.fields.Negoptim__Related_Client__c.Name,
                    SObjectType.Negoptim__Orga_BU__c.fields.Negoptim__Country_origin__c.Name,
                    SObjectType.Negoptim__Orga_BU__c.fields.Negoptim__Format_Origin__c.Name,
                    SObjectType.Negoptim__Orga_BU__c.fields.Negoptim__Layer_Nego_Conso__c.Name
                    };
           if (Negoptim.NegoptimHelper.checkAccessibility(Negoptim__Assortment_BU__c.SObjectType, assortmentBUFields)
               && Negoptim.NegoptimHelper.checkAccessibility(Negoptim__Assortment_Detail__c.SObjectType, assortmentDetailFields)
               && Negoptim.NegoptimHelper.checkAccessibility(Negoptim__Orga_BU__c.SObjectType, orgaBUFields))
           {
               for(Negoptim__Assortment_BU__c item : [SELECT Id, Negoptim__Assortment_parent__c, Negoptim__BU_Source__c, Negoptim__BU_Target__c, Negoptim__Orga_HE__c, Negoptim__BU_Source__r.Negoptim__Related_Client__c, Negoptim__BU_Source__r.Negoptim__Country_origin__c,
                                            RecordType.DeveloperName, Negoptim__BU_Target__r.Negoptim__Related_Client__c, Negoptim__BU_Target__r.Negoptim__Country_origin__c, Negoptim__BU_Target__r.Negoptim__Format_Origin__c, Negoptim__Year__c,
                                            (SELECT Id, Negoptim__Product__c, Negoptim__Category__c, Negoptim__Assortment_BU__r.Negoptim__BU_Source__c, Negoptim__Assortment_BU__r.Negoptim__BU_Source__r.Negoptim__Related_Client__c,
                                             Negoptim__Assortment_BU__r.Negoptim__Orga_HE__c, Negoptim__Assortment_BU__r.Negoptim__BU_Source__r.Negoptim__Country_origin__c, Negoptim__Assortment_BU__r.Negoptim__BU_Target__r.Negoptim__Related_Client__c,
                                             Negoptim__Assortment_BU__r.Negoptim__BU_Target__r.Negoptim__Country_origin__c, Negoptim__Assortment_BU__r.Negoptim__BU_Target__r.Negoptim__Format_Origin__c, Negoptim__Year__c, Negoptim__New_Client_LM__c,
                                             Negoptim__Fact_WD_MarketBased__c,Negoptim__L4L_Client_ND_ClientBased__c,Negoptim__L4L_Client_ND_MarketBased__c,Negoptim__L4L_Client_ProductNumber__c,
                                             Negoptim__L4L_Client_WD_ClientBased__c, Negoptim__L4L_Client_WD_MarketBased__c, Negoptim__New_Client_ND_ClientBased__c, Negoptim__New_Client_ND_MarketBased__c,
                                             Negoptim__New_Client_ProductNumber__c,Negoptim__New_Client_Quantity_SEQ__c,Negoptim__New_Client_Quantity_YE__c, Negoptim__New_Client_WD_ClientBased__c,
                                             Negoptim__New_Client_WD_MarketBased__c,Negoptim__New_Corp_ND_ClientBased__c, Negoptim__New_Corp_ND_MarketBased__c, Negoptim__Status__c, Negoptim__Movement_Date__c, Negoptim__Client_Status__c,
                                             Negoptim__New_Corp_WD_ClientBased__c, Negoptim__New_Corp_WD_MarketBased__c, Negoptim__New_Client_Unit_Cost__c, Negoptim__Ref_Client_Assortment__c
                                             FROM Negoptim__Assortment_BU_Details__r WHERE Negoptim__Product__c IN :productSet)
                                            FROM Negoptim__Assortment_BU__c
                                            WHERE Negoptim__BU_Source__c IN :buSourceSet AND Negoptim__Orga_HE__c IN :categorySet AND (Negoptim__Year__c IN :yearSet OR Negoptim__Year__c IN :previousYearSet)
                                            AND RecordType.DeveloperName IN :recordTypeSet AND Negoptim__Status__c = 'Validated'])
               {
                   String recordType = item.RecordType.DeveloperName == 'Conso' ? 'Nego' : item.RecordType.DeveloperName == 'Conso_Target'? 'Target' : 'Simulation';
                   String key = recordType + '' + item.Negoptim__BU_Source__c + '' + item.Negoptim__Orga_HE__c + '' + item.Negoptim__BU_Target__r.Negoptim__Related_Client__c + '' +
                       item.Negoptim__BU_Target__r.Negoptim__Country_origin__c + '' + getSortedFormatOrigin(item.Negoptim__BU_Target__r.Negoptim__Format_Origin__c) + '' + Integer.valueOf(item.Negoptim__Year__c);
                   if(yearSet.contains(Integer.valueOf(item.Negoptim__Year__c))) {
                       assortmentBUConsoMap.put(key, item);
                       // get assortment details conso
                       for(Negoptim__Assortment_Detail__c detail :item.Negoptim__Assortment_BU_Details__r) {
                           String keyDetail = key + '' + detail.Negoptim__Product__c;
                           assortmentDetailConsoMap.put(keyDetail, detail);
                       }
                       
                   } else if(previousYearSet.contains(Integer.valueOf(item.Negoptim__Year__c)) && (item.RecordType.DeveloperName == 'Conso' || item.RecordType.DeveloperName == 'Conso_Simulation')) {
                       // get parent assortment conso
                       parentAssortmentBUConsoMap.put(key, item);
                       for(Negoptim__Assortment_Detail__c detail :item.Negoptim__Assortment_BU_Details__r) {
                           String keyDetail = key + '' + detail.Negoptim__Product__c;
                           parentAssortmentDetailConsoMap.put(keyDetail, detail);
                       }
                   } else if(N == Integer.valueOf(item.Negoptim__Year__c)) {
                       parentObjAssortmentBUConsoMap.put(key, item);
                       for(Negoptim__Assortment_Detail__c detail :item.Negoptim__Assortment_BU_Details__r) {
                           String keyDetail = key + '' + detail.Negoptim__Product__c;
                           parentObjAssortmentDetailConsoMap.put(keyDetail, detail);
                       }
                   }
               }
           }
        }
        // list of calculated Assortment_Detail__c fields
        List<String> assortmentDetailsCalculateFields = new List<String> {
            SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__Fact_WD_MarketBased__c.Name,
                SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__L4L_Client_ND_ClientBased__c.Name,
                SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__L4L_Client_ND_MarketBased__c.Name,
                SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__L4L_Client_ProductNumber__c.Name,
                SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__L4L_Client_WD_ClientBased__c.Name,
                SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__L4L_Client_WD_MarketBased__c.Name,
                SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__New_Client_ND_ClientBased__c.Name,
                SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__New_Client_ND_MarketBased__c.Name,
                SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__New_Client_ProductNumber__c.Name,
                SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__New_Client_Quantity_SEQ__c.Name,
                SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__New_Client_Quantity_YE__c.Name,
                SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__New_Client_WD_ClientBased__c.Name,
                SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__New_Client_WD_MarketBased__c.Name,
                SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__New_Corp_ND_ClientBased__c.Name,
                SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__New_Corp_ND_MarketBased__c.Name,
                SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__New_Corp_WD_ClientBased__c.Name,
                SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__New_Corp_WD_MarketBased__c.Name,
                SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__New_Client_Unit_Cost__c.Name
                };
        for(String key : assortmentDetailsMap.keySet()) {
            AssortmentConsoWrapper wAssortmentConso = new AssortmentConsoWrapper();
            // insert assortment BU Conso
            Negoptim__Assortment_BU__c assortmentBUConso;
            Negoptim__Assortment_Detail__c firstAssortmentDetail = assortmentDetailsMap.get(key)[0];
            String recordType = firstAssortmentDetail.Negoptim__Assortment_BU__r.RecordType.DeveloperName;
            String keyParentAssortment = 'Nego' + firstAssortmentDetail.Negoptim__Assortment_BU__r.Negoptim__BU_Source__c + '' + firstAssortmentDetail.Negoptim__Assortment_BU__r.Negoptim__Orga_HE__c + '' +
                firstAssortmentDetail.Negoptim__Assortment_BU__r.Negoptim__BU_Target__r.Negoptim__Related_Client__c + '' + firstAssortmentDetail.Negoptim__Assortment_BU__r.Negoptim__BU_Target__r.Negoptim__Country_origin__c + '' +
                getSortedFormatOrigin(firstAssortmentDetail.Negoptim__Assortment_BU__r.Negoptim__BU_Target__r.Negoptim__Format_Origin__c) + '' + (Integer.valueOf(firstAssortmentDetail.Negoptim__Year__c) - 1);
            // get BU Conso
            String keyBU = firstAssortmentDetail.Negoptim__Assortment_BU__r.Negoptim__BU_Target__r.Negoptim__Related_Client__c + '' + firstAssortmentDetail.Negoptim__Assortment_BU__r.Negoptim__BU_Target__r.Negoptim__Country_origin__c + '' +
                getSortedFormatOrigin(firstAssortmentDetail.Negoptim__Assortment_BU__r.Negoptim__BU_Target__r.Negoptim__Format_Origin__c);
            if(!buConsoMap.containsKey(keyBU)) continue;
            Negoptim__Orga_BU__c buConso = buConsoMap.get(keyBU);
            Id recordTypeId = recordType == 'Nego' ? NegoptimHelper.getObjectRecordTypeId(Negoptim__Assortment_BU__c.SObjectType, 'Conso') : recordType == 'Target' ? Negoptim.NegoptimHelper.getObjectRecordTypeId(Negoptim__Assortment_BU__c.SObjectType, 'Conso_Target') : Negoptim.NegoptimHelper.getObjectRecordTypeId(Negoptim__Assortment_BU__c.SObjectType, 'Conso_Simulation');
            String name = recordType == 'Nego' ? 'Conso - ' :  recordType == 'Target' ? 'Target - ' : 'Simulation - ';
            if(!assortmentBUConsoMap.containsKey(key)) {
                assortmentBUConso = new Negoptim__Assortment_BU__c(Name = name + buConso.Name + ' - ' + firstAssortmentDetail.Negoptim__Year__c,
                                                         Negoptim__BU_Source__c = firstAssortmentDetail.Negoptim__Assortment_BU__r.Negoptim__BU_Source__c,
                                                         Negoptim__BU_Target__c = buConso.Id,
                                                         Negoptim__Orga_HE__c = firstAssortmentDetail.Negoptim__Assortment_BU__r.Negoptim__Orga_HE__c,
                                                         Negoptim__Ass_BDate__c = firstAssortmentDetail.Negoptim__Assortment_BU__r.Negoptim__Ass_BDate__c,
                                                         Negoptim__Ass_EDate__c = firstAssortmentDetail.Negoptim__Assortment_BU__r.Negoptim__Ass_EDate__c,
                                                         Negoptim__Year__c = firstAssortmentDetail.Negoptim__Year__c,
                                                         Negoptim__Assortment_type__c = firstAssortmentDetail.Negoptim__Assortment_BU__r.Negoptim__Assortment_type__c,
                                                         Negoptim__Assortment__c = firstAssortmentDetail.Negoptim__Assortment_BU__r.Negoptim__Assortment__c,
                                                         Negoptim__Status__c = 'Open (in bulding process)',
                                                         Negoptim__Target_Simulation__c = true,
                                                         RecordTypeId = recordTypeId);
                assortmentBUConso.Negoptim__Assortment_parent__c = parentAssortmentBUConsoMap.containsKey(keyParentAssortment) ? parentAssortmentBUConsoMap.get(keyParentAssortment).Id : null;
                assortmentBUConso.Negoptim__Assortment_Parent_Objective__c = parentObjAssortmentBUConsoMap.containsKey(keyParentAssortment) ? parentObjAssortmentBUConsoMap.get(keyParentAssortment).Id : null; 
                assortmentBUConsoMap.put(key, assortmentBUConso);
            } else {
                assortmentBUConso = assortmentBUConsoMap.get(key);
                assortmentBUConso.Negoptim__Assortment_Parent_Objective__c = parentObjAssortmentBUConsoMap.containsKey(keyParentAssortment) ? parentObjAssortmentBUConsoMap.get(keyParentAssortment).Id : null; 
                
                //if(assortmentBUConso.Negoptim__Assortment_parent__c == null) {
                    assortmentBUConso.Negoptim__Assortment_parent__c = parentAssortmentBUConsoMap.containsKey(keyParentAssortment) ? parentAssortmentBUConsoMap.get(keyParentAssortment).Id : null;
                    wAssortmentConso.isUpdated = true;
                //}
            }
            // insert assortment detail conso
            for(Negoptim__Assortment_Detail__c assortmentDetail : assortmentDetailsMap.get(key)) {
                String keyDetail = key + '' + assortmentDetail.Negoptim__Product__c;
                String keyParentAssortmentDetail;
                if(!key.contains('Simulation')){
                    keyParentAssortmentDetail = 'Nego' + assortmentDetail.Negoptim__Assortment_BU__r.Negoptim__BU_Source__c + '' + assortmentDetail.Negoptim__Assortment_BU__r.Negoptim__Orga_HE__c + '' + assortmentDetail.Negoptim__Assortment_BU__r.Negoptim__BU_Target__r.Negoptim__Related_Client__c + '' + 
                        assortmentDetail.Negoptim__Assortment_BU__r.Negoptim__BU_Target__r.Negoptim__Country_origin__c + '' + getSortedFormatOrigin(assortmentDetail.Negoptim__Assortment_BU__r.Negoptim__BU_Target__r.Negoptim__Format_Origin__c) + '' + (Integer.valueOf(assortmentDetail.Negoptim__Year__c) - 1) + '' + 
                        assortmentDetail.Negoptim__Product__c;
                } else {
                    keyParentAssortmentDetail = 'Simulation' + assortmentDetail.Negoptim__Assortment_BU__r.Negoptim__BU_Source__c + '' + assortmentDetail.Negoptim__Assortment_BU__r.Negoptim__Orga_HE__c + '' + assortmentDetail.Negoptim__Assortment_BU__r.Negoptim__BU_Target__r.Negoptim__Related_Client__c + '' +
                        assortmentDetail.Negoptim__Assortment_BU__r.Negoptim__BU_Target__r.Negoptim__Country_origin__c + '' + getSortedFormatOrigin(assortmentDetail.Negoptim__Assortment_BU__r.Negoptim__BU_Target__r.Negoptim__Format_Origin__c) + '' + (Integer.valueOf(assortmentDetail.Negoptim__Year__c) - 1) + '' + 
                        assortmentDetail.Negoptim__Product__c;
                }
                Negoptim__Assortment_Detail__c assortmentDetailConso;
                if(!assortmentDetailConsoMap.containsKey(keyDetail)) {
                    assortmentDetailConso = new Negoptim__Assortment_Detail__c(Negoptim__Assortment_BU__c = assortmentBUConso.Id,
                                                                     Negoptim__Category__c = assortmentDetail.Negoptim__Category__c,
                                                                     Negoptim__Product__c = assortmentDetail.Negoptim__Product__c,
                                                                     Negoptim__Movement_Date__c = assortmentDetail.Negoptim__Movement_Date__c,
                                                                     Negoptim__Client_Status__c = assortmentDetail.Negoptim__Client_Status__c,
                                                                     Negoptim__New_Client_LM__c = 0);
                    assortmentDetailConso.Negoptim__Ref_Client_Assortment__c = parentAssortmentDetailConsoMap.containsKey(keyParentAssortmentDetail) ? parentAssortmentDetailConsoMap.get(keyParentAssortmentDetail).Id : null;
                    assortmentDetailConso.Negoptim__Ref_Corp_Assortment__c = parentObjAssortmentDetailConsoMap.containsKey(keyParentAssortmentDetail) ? parentObjAssortmentDetailConsoMap.get(keyParentAssortmentDetail).Id : null;
                } else {
                    assortmentDetailConso = assortmentDetailConsoMap.get(keyDetail);
                    assortmentDetailConso.Negoptim__Ref_Corp_Assortment__c = parentObjAssortmentDetailConsoMap.containsKey(keyParentAssortmentDetail) ? parentObjAssortmentDetailConsoMap.get(keyParentAssortmentDetail).Id : null;
                    //if(assortmentDetailConso.Negoptim__Ref_Client_Assortment__c == null)
                        assortmentDetailConso.Negoptim__Ref_Client_Assortment__c = parentAssortmentDetailConsoMap.containsKey(keyParentAssortmentDetail) ? parentAssortmentDetailConsoMap.get(keyParentAssortmentDetail).Id : null;
                    }
                // reset assortment details conso in first load
                if(assortmentDetailConso.Id != null && !this.assortmentDetailConsoIds.contains(assortmentDetailConso.Id)) {
                    for(String field : assortmentDetailsCalculateFields) {
                        if(assortmentDetailConso.get(field) != null) {
                            assortmentDetailConso.put(field, null);
                        }
                    }
                    // clear movement date case status=In Preparation
                    assortmentDetailConso.Negoptim__Movement_Date__c = null;
                    assortmentDetailConso.Negoptim__Client_Status__c = null;
                    assortmentDetailConso.Negoptim__New_Client_LM__c = 0;
                    this.assortmentDetailConsoIds.add(assortmentDetailConso.Id);
                }
                // reset WD_Conso__c
                if(assortmentDetail.Negoptim__Status__c == 'Validated' || (assortmentDetail.Negoptim__Status__c == 'Request for Approval' && assortmentDetail.Negoptim__Assortment_BU__r.Negoptim__Target_Simulation__c == true) ||
                   (assortmentDetail.Negoptim__Status__c == 'Previously Validated' && assortmentDetail.Negoptim__Client_Status__c == 'Substitute'))
                {
                    // Set New_Client_LM__c
                    assortmentDetailConso.Negoptim__New_Client_LM__c++;
                    // Set Movement_Date__c/Client_Status__c
                    if(assortmentDetail.Negoptim__Movement_Date__c != null && (assortmentDetailConso.Negoptim__Movement_Date__c == null || assortmentDetailConso.Negoptim__Movement_Date__c < assortmentDetail.Negoptim__Movement_Date__c)) {
                        // add max movement date in assortment detail conso
                        assortmentDetailConso.Negoptim__Movement_Date__c = assortmentDetail.Negoptim__Movement_Date__c;
                        assortmentDetailConso.Negoptim__Client_Status__c = assortmentDetail.Negoptim__Client_Status__c;
                    }
                    assortmentDetailConso.Negoptim__Status__c = 'Validated';
                    assortmentDetail.Negoptim__WD_Conso__c = true;
                    Decimal DVNego, DVConso;
                    if(Integer.valueOf(assortmentDetail.Negoptim__Year__c) == P2) {
                        DVConso = buConso.Negoptim__Weighted_Distribution_Manual_P2__c != null ? buConso.Negoptim__Weighted_Distribution_Manual_P2__c : 0;
                        DVNego = assortmentDetail.Negoptim__Assortment_BU__r.Negoptim__BU_Target__r.Negoptim__Weighted_Distribution_Manual_P2__c != null ? assortmentDetail.Negoptim__Assortment_BU__r.Negoptim__BU_Target__r.Negoptim__Weighted_Distribution_Manual_P2__c : 0;
                    } else if(Integer.valueOf(assortmentDetail.Negoptim__Year__c) == P1) {
                        DVConso = buConso.Negoptim__Weighted_Distribution_Manual_P1__c != null ? buConso.Negoptim__Weighted_Distribution_Manual_P1__c : 0;
                        DVNego = assortmentDetail.Negoptim__Assortment_BU__r.Negoptim__BU_Target__r.Negoptim__Weighted_Distribution_Manual_P1__c != null ? assortmentDetail.Negoptim__Assortment_BU__r.Negoptim__BU_Target__r.Negoptim__Weighted_Distribution_Manual_P1__c : 0;
                    } else if(Integer.valueOf(assortmentDetail.Negoptim__Year__c) == N) {
                        DVConso = buConso.Negoptim__Weighted_Distribution_Manual__c != null ? buConso.Negoptim__Weighted_Distribution_Manual__c : 0;
                        DVNego = assortmentDetail.Negoptim__Assortment_BU__r.Negoptim__BU_Target__r.Negoptim__Weighted_Distribution_Manual__c != null ? assortmentDetail.Negoptim__Assortment_BU__r.Negoptim__BU_Target__r.Negoptim__Weighted_Distribution_Manual__c : 0;
                    } else if(Integer.valueOf(assortmentDetail.Negoptim__Year__c) == N1) {
                        DVConso = buConso.Negoptim__Weighted_Distribution_Manual_N1__c != null ? buConso.Negoptim__Weighted_Distribution_Manual_N1__c : 0;
                        DVNego = assortmentDetail.Negoptim__Assortment_BU__r.Negoptim__BU_Target__r.Negoptim__Weighted_Distribution_Manual_N1__c != null ? assortmentDetail.Negoptim__Assortment_BU__r.Negoptim__BU_Target__r.Negoptim__Weighted_Distribution_Manual_N1__c : 0;
                    }
                    // calculate new values
                    for(String fieldName : assortmentDetailsCalculateFields) {
                        decimal value = 0;
                        if(assortmentDetailConso.get(fieldName) != null) {
                            value = Decimal.valueOf(String.valueOf(assortmentDetailConso.get(fieldName)));
                        }
                        if(assortmentDetail.get(fieldName) != null) {
                            if(fieldName == SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__New_Client_WD_ClientBased__c.Name) {
                                if(DVConso != null && DVConso != 0) {
                                    value += (Decimal.valueOf(String.valueOf(assortmentDetail.get(fieldName))) * DVNego)/DVConso;
                                }
                            } else {
                                value += Decimal.valueOf(String.valueOf(assortmentDetail.get(fieldName)));
                            }
                            assortmentDetailConso.put(fieldName, value);
                        }
                    }
                } else {
                    // Case Status__c == 'In preparation'
                    assortmentDetail.Negoptim__WD_Conso__c = false;
                    assortmentDetailConso.Negoptim__Status__c = 'In preparation';
                }
                if(!wAssortmentConso.assortmentDetailsLinkedMap.containsKey(assortmentDetail.Negoptim__Product__c)) {
                    wAssortmentConso.assortmentDetailsLinkedMap.put(assortmentDetail.Negoptim__Product__c, new List<Negoptim__Assortment_Detail__c>{assortmentDetail});
                } else {
                    wAssortmentConso.assortmentDetailsLinkedMap.get(assortmentDetail.Negoptim__Product__c).add(assortmentDetail);
                }
                assortmentDetailConsoMap.put(keyDetail, assortmentDetailConso);
                wAssortmentConso.assortmentDetailsConsoMap.put(assortmentDetail.Negoptim__Product__c, assortmentDetailConso);
            }
            wAssortmentConso.assortmentBUConso = assortmentBUConso;
            assortmentConsoWrapperList.add(wAssortmentConso);
        }
        Savepoint sp = Database.setSavepoint();
        try {
            // check security on Assortment_BU__c fields
            String[] assortmentBUFields = new String[] {
                SObjectType.Negoptim__Assortment_BU__c.fields.Name.Name,
                    SObjectType.Negoptim__Assortment_BU__c.fields.Negoptim__BU_Source__c.Name,
                    SObjectType.Negoptim__Assortment_BU__c.fields.Negoptim__BU_Target__c.Name,
                    SObjectType.Negoptim__Assortment_BU__c.fields.Negoptim__Orga_HE__c.Name,
                    SObjectType.Negoptim__Assortment_BU__c.fields.Negoptim__Ass_BDate__c.Name,
                    SObjectType.Negoptim__Assortment_BU__c.fields.Negoptim__Ass_EDate__c.Name,
                    SObjectType.Negoptim__Assortment_BU__c.fields.Negoptim__Year__c.Name,
                    SObjectType.Negoptim__Assortment_BU__c.fields.Negoptim__Assortment_type__c.Name,
                    SObjectType.Negoptim__Assortment_BU__c.fields.Negoptim__Assortment__c.Name,
                    SObjectType.Negoptim__Assortment_BU__c.fields.Negoptim__Assortment_parent__c.Name,
                    SObjectType.Negoptim__Assortment_BU__c.fields.Negoptim__Status__c.Name
                    };
            // check security on Assortment_Detail__c fields
            String[] assortmentDetailFields = new String[] {
                SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__Product__c.Name,
                    SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__Client_Status__c.Name,
                    SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__Status__c.Name,
                    SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__WD_Conso__c.Name,
                    SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__Category__c.Name,
                    SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__Ref_Client_Assortment__c.Name,
                    SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__Movement_Date__c.Name,
                    SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__New_Client_LM__c.Name
                    };
            String[] assortmentDetailInsertFields = new String[] {
                SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__Assortment_BU__c.Name
                    };
            assortmentDetailFields.addAll(assortmentDetailsCalculateFields);
            assortmentDetailInsertFields.addAll(assortmentDetailFields);

            for(AssortmentConsoWrapper item : assortmentConsoWrapperList) {
                if(item.assortmentBUConso.Id == null || item.isUpdated) {
                    assortmentBUConsoList.add(item.assortmentBUConso);
                }
            }
            if(Negoptim.NegoptimHelper.checkCreatibility(Negoptim__Assortment_BU__c.SObjectType, assortmentBUFields) &&
               Negoptim.NegoptimHelper.checkCreatibility(Negoptim__Assortment_Detail__c.SObjectType, assortmentDetailInsertFields) &&
               Negoptim.NegoptimHelper.checkUpdatibility(Negoptim__Assortment_Detail__c.SObjectType, assortmentDetailFields))
            {
                // upsert assortment BU conso
                if(!assortmentBUConsoList.isEmpty()) {
                    List<Database.UpsertResult> results = Database.upsert(assortmentBUConsoList, false);
                    for (Integer i = 0; i < results.size(); i++) {
                        Database.UpsertResult result = results.get(i);
                        Negoptim__Assortment_BU__c assortmentBUConso = assortmentBUConsoList.get(i);
                        if (!result.isSuccess()) {
                            String errorMessage = result.Id != null ? assortmentBUConso.Name + '(' + result.Id + ') : ' : String.valueOf(assortmentBUConso) + '\n';
                            Database.Error[] errors = result.getErrors();
                            for (Database.Error err : errors) {
                                errorMessage += err.getFields() + ' - ' + err.getStatusCode() + ' - ' + err.getMessage() + '\n';
                            }
                            nb.logError(errorMessage);
                        }
                    }
                }
                // upsert assortment details conso
                Map<Id, AssortmentConsoWrapper> assortmentConsoWrapperMap = new Map<Id, AssortmentConsoWrapper>();
                List<Negoptim__Assortment_Detail__c> assortmentDetailConsoList = new List<Negoptim__Assortment_Detail__c>();
                for(AssortmentConsoWrapper item : assortmentConsoWrapperList) {
                    if(item.assortmentBUConso.Id != null) {
                        for(Negoptim__Assortment_Detail__c assortmentDetailConso : item.assortmentDetailsConsoMap.values()) {
                            for(String field : assortmentDetailsCalculateFields) {
                                decimal value = 0;
                                if(assortmentDetailConso.get(field) != null) {
                                    value = Decimal.valueOf(String.valueOf(assortmentDetailConso.get(field)));
                                    value = value.setScale(1, System.RoundingMode.HALF_DOWN);
                                    assortmentDetailConso.put(field, value);
                                }
                            }
                            if(assortmentDetailConso.Negoptim__Assortment_BU__c == null) assortmentDetailConso.Negoptim__Assortment_BU__c = item.assortmentBUConso.Id;
                        }
                        assortmentConsoWrapperMap.put(item.assortmentBUConso.Id, item);
                        assortmentDetailConsoList.addAll(item.assortmentDetailsConsoMap.values());
                    }
                }
                if(!assortmentDetailConsoList.isEmpty()) {
                    List<Database.UpsertResult> resultsDetail = Database.upsert(assortmentDetailConsoList, false);
                    for (Integer i = 0; i < resultsDetail.size(); i++) {
                        Database.UpsertResult result = resultsDetail.get(i);
                        Negoptim__Assortment_Detail__c assortmentDetailConso = assortmentDetailConsoList.get(i);
                        if (!result.isSuccess()) {
                            String errorMessage = '';
                            Database.Error[] errors = result.getErrors();
                            for (Database.Error err : errors) {
                                errorMessage += err.getFields() + ' - ' + err.getStatusCode() + ' - ' + err.getMessage() + '\n';
                            }
                            nb.logError(errorMessage);
                        } else {
                            AssortmentConsoWrapper assortmentConsoWrapper = assortmentConsoWrapperMap.get(assortmentDetailConso.Negoptim__Assortment_BU__c);
                            assortmentDetailsUpdatedList.addAll(assortmentConsoWrapper.assortmentDetailsLinkedMap.get(assortmentDetailConso.Negoptim__Product__c));
                            if(!this.assortmentDetailConsoIds.contains(assortmentDetailConso.Id)) {
                                this.assortmentDetailConsoIds.add(assortmentDetailConso.Id);
                            }
                        }
                    }
                }
                // update assortment details
                if(!assortmentDetailsUpdatedList.isEmpty()) {
                    List<Database.SaveResult> results = Database.update(assortmentDetailsUpdatedList, false);
                    nb.logResults(results, assortmentDetailsUpdatedList);
                }
            }
        } catch(DmlException e) {
            Database.rollback(sp);
            nb.logError('Exception: ' + e.getDmlMessage(0) + ' - ' + e.getLineNumber());
        } catch(Exception e) {
            Database.rollback(sp);
            nb.logError('Exception: ' + e.getMessage() + ' - ' + e.getLineNumber());
        }
        nb.incrementBatchIndex();
    }

    global void finish(Database.BatchableContext bc) {
        // Get the Job.
        String customSubject = ConsolidateAssortmentBatchExt.class.getName() + ' : ' + [SELECT Status, NumberOfErrors, TotalJobItems, JobItemsProcessed,
                                                                                             CompletedDate, MethodName,	CreatedBy.name, CreatedDate, ExtendedStatus
                                                                                             FROM AsyncApexJob WHERE Id = :bc.getJobId()]?.Status;
        nb.sendEmail(bc, null, customSubject);
    }

    /* Assortment Conso Wrapper Class */
    global class AssortmentConsoWrapper {
        private Negoptim__Assortment_BU__c assortmentBUConso {get; set;}
        private Map<Id, Negoptim__Assortment_Detail__c> assortmentDetailsConsoMap {get; set;}
        private Map<Id, List<Negoptim__Assortment_Detail__c>> assortmentDetailsLinkedMap {get; set;}
        private Boolean isUpdated {get; set;}
        public AssortmentConsoWrapper() {
            this.assortmentDetailsConsoMap = new Map<Id, Negoptim__Assortment_Detail__c>();
            this.assortmentDetailsLinkedMap = new Map<Id, List<Negoptim__Assortment_Detail__c>>();
            this.isUpdated = false;
        }
    }

    private String getSortedFormatOrigin(String formatOrigin) {
        List<String> formatsList = formatOrigin.split(';');
        formatsList.sort();
        return String.join(formatsList, ';');
    }
}