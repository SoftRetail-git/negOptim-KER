public with sharing class AssortmentManagementPanelCtrlExt {

    @AuraEnabled
    public static string loadData(String FilterParameterJSON) {
        try {
            ResultWrapper res = new ResultWrapper();
            FilterParameter filterParam = (FilterParameter) JSON.deserialize(FilterParameterJSON, FilterParameter.class);
            List<String> queriedAssortmetnfields = new List<String>{ 
                SObjectType.Negoptim__Assortment_BU__c.fields.Negoptim__Year__c.Name,  
                SObjectType.Negoptim__Assortment_BU__c.fields.Name.Name,       
                SObjectType.Negoptim__Assortment_BU__c.fields.SPKERC_SumNewClientQuantityYE__c.Name,       
                SObjectType.Negoptim__Assortment_BU__c.fields.SPKERC_SumNewClientProductNumberGap__c.Name,       
                SObjectType.Negoptim__Assortment_BU__c.fields.SPKERC_SumNewClientNDCltBasedPtsGapNegoP__c.Name,       
                SObjectType.Negoptim__Assortment_BU__c.fields.SPKERC_SumNewClientWDMarketBasedGap__c.Name,    
                Negoptim.NegoptimHelper.getFieldNameAsRelation(SObjectType.Negoptim__Assortment_BU__c.fields.Negoptim__BU_source__c.Name) + '.' + SObjectType.Negoptim__Orga_BU__c.fields.Name.Name,
                Negoptim.NegoptimHelper.getFieldNameAsRelation(SObjectType.Negoptim__Assortment_BU__c.fields.Negoptim__BU_Target__c.Name) + '.' + SObjectType.Negoptim__Orga_BU__c.fields.Name.Name,
                Negoptim.NegoptimHelper.getFieldNameAsRelation(SObjectType.Negoptim__Assortment_BU__c.fields.Negoptim__BU_Target__c.Name) + '.' + SObjectType.Negoptim__Orga_BU__c.fields.Negoptim__Logo__c.Name
            };
            String query = 'SELECT Id, RecordType.DeveloperName, ToLabel(Negoptim__Status__c), ' + String.join(queriedAssortmetnfields, ', ');
            query += ' FROM Negoptim__Assortment_BU__c ';
            query += ' WHERE Negoptim__Year__c = ' + filterParam.yearParam;
            if(!String.isBlank(filterParam.typeAssParam)){
                query += ' AND Negoptim__Assortment_type__c = \'' + filterParam.typeAssParam + '\'';
            }
            if(!String.isBlank(filterParam.clientParam)){
                query += ' AND Negoptim__BU_Target__r.Negoptim__Related_Client__c = \'' + filterParam.clientParam + '\'';
            }
            System.debug('query: ' + query);
            res.assortmentBuStringify = database.query(query);
            res.displayedFields = fillDisplayedFields();
            return JSON.serialize(res);
        } catch (Exception e) {
            System.debug('Error load assortmentPanel ::>>>'+ e.getMessage() + '--' + e.getStackTraceString());
            throw new AuraHandledException(e.getMessage());
        }
    }
    private static List<FieldWrapper> fillDisplayedFields() {
        Map<String,Schema.SObjectField> assBuFields = Schema.Negoptim__Assortment_BU__c.SObjectType.getDescribe().fields.getMap();
        List<FieldWrapper> displayedFields = new List<FieldWrapper>();
        List<String> fields = new List<String>{
            SObjectType.Negoptim__Assortment_BU__c.fields.Negoptim__Year__c.Name,  
            SObjectType.Negoptim__Assortment_BU__c.fields.Negoptim__BU_source__c.Name,
            SObjectType.Negoptim__Assortment_BU__c.fields.Negoptim__BU_Target__c.Name,
            SObjectType.Negoptim__Assortment_BU__c.fields.Name.Name,
            SObjectType.Negoptim__Assortment_BU__c.fields.Negoptim__Status__c.Name,       
            SObjectType.Negoptim__Assortment_BU__c.fields.SPKERC_SumNewClientQuantityYE__c.Name,       
            SObjectType.Negoptim__Assortment_BU__c.fields.SPKERC_SumNewClientProductNumberGap__c.Name,       
            SObjectType.Negoptim__Assortment_BU__c.fields.SPKERC_SumNewClientNDCltBasedPtsGapNegoP__c.Name,       
            SObjectType.Negoptim__Assortment_BU__c.fields.SPKERC_SumNewClientWDMarketBasedGap__c.Name       
            // SObjectType.Negoptim__Assortment_BU__c.fields.Negoptim__Assortment_type__c.Name
        };
        
        for (String fieldName : fields) {
            Schema.DescribeFieldResult dfr = assBuFields.get(fieldName).getDescribe();
            FieldWrapper field = new FieldWrapper(fieldName, dfr.getLabel(), dfr.getType().Name());
            
            displayedFields.add(field);
        }
        return displayedFields;
    }
    
    public class ResultWrapper {
        public List<FieldWrapper> displayedFields {get; set;}
        public List<Negoptim__Assortment_BU__c> assortmentBuStringify {get; set;}
        
        public ResultWrapper() {}
    }

    /* Wrapper class for FieldWrapper */
    public class FieldWrapper {
        public String fieldApiName;
        public String fieldLabel;
        public String fieldType;
        public FieldWrapper(String fieldApiName, String fieldLabel, String fieldType) {
            this.fieldApiName = fieldApiName;
            this.fieldLabel = fieldLabel;
            this.fieldType = fieldType;
        }
    }
    
    public class FilterParameter {
        public String typeAssParam;
        public Integer yearParam;
        public String clientParam;
        public FilterParameter(String typeAssParam, Integer yearParam, String clientParam) {
            this.typeAssParam = typeAssParam;
            this.yearParam = yearParam;
            this.clientParam = clientParam;
        }
    }
}