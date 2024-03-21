/**
* @author ULiT
* @description Generate assortment details for duplicated assortment bu 
* @date 7/9/2023
* */
public class DuplicateAssortmentDetailBatch_Ext implements Database.Batchable<SObject> {
    
    private Negoptim.NegoptimBatch nb;
    public final String query;
    Map<String, Id> refAssortmentDetailsMap;
    Map<String, Negoptim__Assortment_BU__c> assortmnentBUMap;
    public List<String> assortmentDetailCreateUpdateFields;
    List<Id> clonedAssortmentBUIdList;
    
    public DuplicateAssortmentDetailBatch_Ext(String startedFrom, Id recordId, List<Id> parentAssortmnentIds, Map<String, Negoptim__Assortment_BU__c> assortmnentBUMap) {
        this.nb = new Negoptim.NegoptimBatch(DuplicateAssortmentDetailBatch_Ext.class.getName(), Negoptim.NegoptimBatch.BatchType.Stateless, startedFrom);
        this.assortmnentBUMap = assortmnentBUMap;
        this.clonedAssortmentBUIdList = new List<Id>();
        // get Assortment Detail field
        Map<String, Schema.SObjectField> assortmentDetailfields = Schema.Negoptim__Assortment_Detail__c.sObjectType.getDescribe().fields.getMap();
        assortmentDetailCreateUpdateFields = new List<String>();
        for (Schema.SObjectField field : assortmentDetailfields.values()) {
            Schema.DescribeFieldResult fieldResult = field.getDescribe();
            if (fieldResult.isCreateable() || fieldResult.isUpdateable()) {
                assortmentDetailCreateUpdateFields.add(fieldResult.getName());
            }
        }
        Map<Id, List<Negoptim__Assortment_Detail__c>> parentAssortmentDetails = new Map<Id, List<Negoptim__Assortment_Detail__c>>();
        refAssortmentDetailsMap = new Map<String, Id>();
        if (parentAssortmnentIds != null && !parentAssortmnentIds.isEmpty()){
            String queryParentAssortDetails = 'SELECT Id, Negoptim__Assortment_BU__r.Negoptim__BU_source__c, Negoptim__Assortment_BU__r.Negoptim__BU_Target__c, Negoptim__Assortment_BU__r.RecordTypeId, ' + String.join(assortmentDetailCreateUpdateFields, ', ') ;
            queryParentAssortDetails += ' FROM Negoptim__Assortment_Detail__c';
            queryParentAssortDetails += ' WHERE Negoptim__Version__c = NULL AND Negoptim__Status__c = \'Validated\'';
            queryParentAssortDetails += ' AND Negoptim__Assortment_BU__c IN (\'' + String.join(parentAssortmnentIds, '\', \'') +'\')';  
            List<Negoptim__Assortment_Detail__c> parentsAssortmentDList = Database.query(queryParentAssortDetails);
            for (Negoptim__Assortment_Detail__c ad : parentsAssortmentDList) {
                if (!parentAssortmentDetails.containsKey(ad.Negoptim__Assortment_BU__c)) {
                    parentAssortmentDetails.put(ad.Negoptim__Assortment_BU__c, new List<Negoptim__Assortment_Detail__c>());
                }
                parentAssortmentDetails.get(ad.Negoptim__Assortment_BU__c).add(ad);
            }
            for (Negoptim__Assortment_BU__c assortmentBU : assortmnentBUMap.values()) {
                if (parentAssortmentDetails.containsKey(assortmentBu.Negoptim__Assortment_parent__c)) {
                    for (Negoptim__Assortment_Detail__c ad : parentAssortmentDetails.get(assortmentBU.Negoptim__Assortment_parent__c)) {
                        String refKey = String.valueOf(ad.Negoptim__Product__c) + ad.Negoptim__Assortment_BU__r.Negoptim__BU_source__c + ad.Negoptim__Assortment_BU__r.Negoptim__BU_Target__c + ad.Negoptim__Assortment_BU__r.RecordTypeId;  
                        refAssortmentDetailsMap.put(refKey, ad.Id);
                    }
                } 
            } 
        }
        
        // get current Assortment Details
        String queryCurrentAssortmentDetails = 'SELECT Id, Negoptim__Assortment_BU__r.Negoptim__BU_source__c, Negoptim__Assortment_BU__r.Negoptim__BU_Target__c, Negoptim__Assortment_BU__r.RecordTypeId, ' + String.join(assortmentDetailCreateUpdateFields, ', ') ;
        queryCurrentAssortmentDetails += ' FROM Negoptim__Assortment_Detail__c';
        queryCurrentAssortmentDetails += ' WHERE Negoptim__Assortment_BU__c = \'' + recordId + '\'';
        this.query = queryCurrentAssortmentDetails;
        
    }
    
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext bc, List<Negoptim__Assortment_Detail__c> scope) {
        List<Negoptim__Assortment_Detail__c> assortmentDetailsToInsert = new List<Negoptim__Assortment_Detail__c>();
        for(Negoptim__Assortment_BU__c assortmentBU : assortmnentBUMap.values()) {
            for (Negoptim__Assortment_Detail__c item : scope) {
                // check create permission before creating a new record
                if (Negoptim.NegoptimHelper.checkCreatibility(Negoptim__Assortment_Detail__c.SObjectType, assortmentDetailCreateUpdateFields)) {
                    Negoptim__Assortment_Detail__c newAssortmentDetail;
                    String refKey = String.valueOf(item.Negoptim__Product__c)  + assortmentBU.Negoptim__BU_source__c + assortmentBU.Negoptim__BU_Target__c + assortmentBU.RecordTypeId;
                    Id refDetail = refAssortmentDetailsMap.containsKey(refKey) ? refAssortmentDetailsMap.get(refKey) : null;
                    newAssortmentDetail = item.clone(false, true, true, false);
                    newAssortmentDetail.Negoptim__Category__c = null;
                    newAssortmentDetail.Negoptim__Assortment_BU__c = assortmentBU.Id;
                    newAssortmentDetail.Negoptim__Last_History__c = null;
                    newAssortmentDetail.Negoptim__Ext_id__c = null;
                    newAssortmentDetail.Negoptim__Ref_Client_Assortment__c = refDetail;
                    newAssortmentDetail.Negoptim__Status__c = 'In preparation';
                    assortmentDetailsToInsert.add(newAssortmentDetail);
                }
            }
            clonedAssortmentBUIdList.add(assortmentBU.Id);
        }
        if (!assortmentDetailsToInsert.isEmpty()) {
            if (Negoptim.NegoptimHelper.checkCreatibility(Negoptim__Assortment_Detail__c.SObjectType, assortmentDetailCreateUpdateFields)) {
                Database.SaveResult[] results = Database.insert(assortmentDetailsToInsert, false);
                String errorMessages = '';
                for (Integer i = 0; i < results.size(); i++) {
                    Database.SaveResult result = results.get(i);
                    Negoptim__Assortment_Detail__c record = assortmentDetailsToInsert.get(i);
                    if (!result.isSuccess()) {
                        String errorMessage = String.valueOf(record);
                        Database.Error[] errors = result.getErrors();
                        for (Database.Error err : errors) {
                            errorMessages += (err.getFields() + ':' +err.getStatusCode() + ' - ' + err.getMessage());
                            System.debug(err.getFields() + ':' +err.getStatusCode() + ' - ' + err.getMessage() + '\n');
                        }
                    }
                }
            }
        }
        nb.saveLog(bc);
    }
    
    public void finish(Database.BatchableContext bc) {
        Negoptim.NegoptimBatch.executeBatch(new Negoptim.RefreshAssortmentClusterBatch(DuplicateAssortmentDetailBatch_Ext.class.getName(), clonedAssortmentBUIdList, null, null, null), 200);
        String customSubject = DuplicateAssortmentDetailBatch_Ext.class.getName() + ' : ' + [SELECT Status, NumberOfErrors, TotalJobItems, JobItemsProcessed,
                                                                                             CompletedDate, MethodName,	CreatedBy.name, CreatedDate, ExtendedStatus
                                                                                             FROM AsyncApexJob WHERE Id = :bc.getJobId()]?.Status;
        nb.sendEmail(bc, null, customSubject);
    }

}