/**
 * @author ULiT
 * @date 05/06/2017
 * @description Helper Methods
 **/
global with sharing class NegoptimHelper {

    public static String FOLDER_SETTINGS_NAME = 'private';
    public static String DOCUMENT_SETTINGS_NAME = 'globalSettings';

    // constant values of colors used in myOffer to indicate if a product in old, inno, intro...
    // N is Assortment Year
    public static final String INNO_INTRO_DATE_LESS_N = '#008000';		// used for products with (isInnovation__c true or of record type unit need) market_introduction_Date__c year < N
    public static final String INNO_INTRO_DATE_GREATER_N = '#5ab403';	// used for products with (isInnovation__c true or of record type unit need) and market_introduction_Date__c year >= N
    public static final String STOP_DATE_LESS_N = '#FA5E00';			// used for products with market_end_of_life_date__c year < N
    public static final String STOP_DATE_GREATER_N = '#ff0000';			// used for products with market_end_of_life_date__c year >= N

    public class RecordTypeException extends Exception {}
    public class GlobalSettingsException extends Exception {}
    public class NoAccessException extends Exception {}
    
    public static String getObjectRecordTypeId(SObjectType sObjectType, String recordTypeName) {
        // If sObjectType is wrong, then an Exception is thrown.
        Id rt;
        Map<Id, Schema.RecordTypeInfo> sObjectTypeRecordTypeInfo = sObjectType.getDescribe().getRecordTypeInfosById();
        for (Id RTId : sObjectTypeRecordTypeInfo.keySet()) {
            if (sObjectTypeRecordTypeInfo.get(RTId).getDeveloperName() == recordTypeName) {
                rt = RTId;
            }
        }
        if (rt == null) {
            // If recordTypeName is wrong, then an Exception is thrown.
            throw new RecordTypeException('Record type "'+ recordTypeName +'" does not exist.');
        }
        //Return the record type id
        return rt;
    }
    
    public static Map<String, Id> getObjectRecordTypeMapIds(SObjectType sObjectType) {
        Map<String, Id> rtMap = new Map<String, Id>();
        // If sObjectType is wrong, then an Exception is thrown.
        String sObjectName = sObjectType.getDescribe().getName();
        // Check Accessibility.
        Schema.DescribeSObjectResult R = sObjectType.getDescribe();
        List<Schema.RecordTypeInfo> RTs = R.getRecordTypeInfos();
        for (Schema.RecordTypeInfo RT : RTs) {
            rtMap.put(RT.getDeveloperName(), RT.getRecordTypeId());
        }
        //Return the record type id
        return rtMap;
    }
    
}