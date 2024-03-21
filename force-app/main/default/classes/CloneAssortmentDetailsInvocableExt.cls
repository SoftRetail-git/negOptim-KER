/**
 * Called from process builder to
 * Clone assortment details from assortment parent
 * Valid for single clone
 * */
global class CloneAssortmentDetailsInvocableExt {

    @InvocableMethod(label='Clone Assortment Details From Parent Objective' description='Clone Assortment Details From Parent Objective')
    public static void cloneAssortmentDetails(List<AssortmentsWrapper> assortments) {
        Negoptim__Assortment_BU__c assortment;
        Set<Id> parentAssortmentObjSet = new Set<Id>();
        Map<Id, Negoptim__Assortment_BU__c> parentObjectiveAssortmentMap = new Map<Id, Negoptim__Assortment_BU__c>();
        List<Negoptim__Assortment_Detail__c> assortmentDetailsToInsert = new List<Negoptim__Assortment_Detail__c>();
        // check security on Assortment_Detail__c fields
        String[] assortmentDetailCreateFields = new String[] {
            SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__Assortment_BU__c.Name,
            SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__Product__c.Name,
            SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__Client_Status__c.Name,
            SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__Status__c.Name,
            SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__Ref_Client_Assortment__c.Name,
            SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__Last_History__c.Name,
            SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__Ext_id__c.Name
        };
        AssortmentsWrapper itemWrapper = assortments[0];
		if (itemWrapper.cloneDetailsFromParentObjective && itemWrapper.assortment.Negoptim__Assortment_Parent_Objective__c != null && !parentAssortmentObjSet.contains(itemWrapper.assortment.Negoptim__Assortment_Parent_Objective__c)) {
            parentAssortmentObjSet.add(itemWrapper.assortment.Negoptim__Assortment_Parent_Objective__c);
            parentObjectiveAssortmentMap.put(itemWrapper.assortment.Negoptim__Assortment_Parent_Objective__c, itemWrapper.assortment);
        }
        if (!parentAssortmentObjSet.isEmpty()) {
            Map<String, Schema.SObjectField> fields = Schema.Negoptim__Assortment_Detail__c.sObjectType.getDescribe().fields.getMap();
            List<String> editableFields = new List<String>();
            for (Schema.SObjectField fieldRef : fields.values()) {
                Schema.DescribeFieldResult fieldResult = fieldRef.getDescribe();
                if (fieldResult.isCreateable() || fieldResult.isUpdateable()) {
                    editableFields.add(fieldResult.getname());
                }
            }
            // get assortment details
            String query = 'SELECT Id, ' + String.join(editableFields, ',');
            query += ' FROM Negoptim__Assortment_Detail__c';
            query += ' WHERE Negoptim__Version__c = NULL';
            query += ' AND Negoptim__Assortment_BU__c IN (\'' + String.join(new List<Id>(parentAssortmentObjSet), '\',\'') +'\')';
            String[] assortmentDetailAccessFields = new String[] {
                SObjectType.Negoptim__Assortment_Detail__c.fields.Id.Name
            };
            for (String str : editableFields) {
                if (!assortmentDetailAccessFields.contains(str)) {
                    assortmentDetailAccessFields.add(str);
                }
            }
            if (Negoptim.NegoptimHelper.checkAccessibility(Negoptim__Assortment_Detail__c.SObjectType, assortmentDetailAccessFields)) {
                List<Negoptim__Assortment_Detail__c> assortmentDetails = Database.query(query);
                for (Negoptim__Assortment_Detail__c item : assortmentDetails) {
                    assortment = parentObjectiveAssortmentMap.get(item.Negoptim__Assortment_BU__c);
                    // check create permission before creating a new record
                    if (Negoptim.NegoptimHelper.checkCreatibility(Negoptim__Assortment_Detail__c.SObjectType, assortmentDetailCreateFields)) {
                        Negoptim__Assortment_Detail__c newAssortmentDetail = item.clone(false, true, true, false);
						newAssortmentDetail.Negoptim__Category__c = null;
                        newAssortmentDetail.Negoptim__Assortment_BU__c = assortment.Id;
                        newAssortmentDetail.Negoptim__Last_History__c = null;
                        newAssortmentDetail.Negoptim__Ext_id__c = null;
                        newAssortmentDetail.Negoptim__Status__c = item.Negoptim__Client_Status__c != null && assortment.Negoptim__Status__c == 'Validated' ? 'Validated' : 'In preparation';
                        newAssortmentDetail.Negoptim__Client_Status__c = item.Negoptim__Client_Status__c;
                        newAssortmentDetail.Negoptim__Ref_Corp_Assortment__c = item.Id;
                        assortmentDetailsToInsert.add(newAssortmentDetail);
                    }
                }
            }
        }
        system.debug('assortmentDetailsToInsert >>> ' + assortmentDetailsToInsert.size());
        if (!assortmentDetailsToInsert.isEmpty()) {
            if (Negoptim.NegoptimHelper.checkCreatibility(Negoptim__Assortment_Detail__c.SObjectType, assortmentDetailCreateFields)) {
                Database.SaveResult[] results = Database.insert(assortmentDetailsToInsert, false);
                String errorMessages = '';
                for (Integer i = 0; i < results.size(); i++) {
                    Database.SaveResult result = results.get(i);
                    Negoptim__Assortment_Detail__c record = assortmentDetailsToInsert.get(i);
                    if (!result.isSuccess()) {
                        String errorMessage = String.valueOf(record);
                        Database.Error[] errors = result.getErrors();
                        for (Database.Error err : errors) {
                            errorMessages += ('\nProduct2 Id [' + record.Negoptim__Product__c + '] ' + err.getFields() + ':' +err.getStatusCode() + ' - ' + err.getMessage());
                            System.debug(err.getFields() + ':' +err.getStatusCode() + ' - ' + err.getMessage() + '\n');
                        }
                    }
                }
                if (String.isNotBlank(errorMessages)) {
                    throw new HandledException(errorMessages);
                }
            }
        }
    }
    public class AssortmentsWrapper {
        @InvocableVariable(label='Assortment' description='Assortment' required=true)
        public Negoptim__Assortment_BU__c assortment;
        @InvocableVariable(label='Copy Details From Parent Objective' description='Copy Details From Parent Objective' required=true)
        public Boolean cloneDetailsFromParentObjective;
    }
}