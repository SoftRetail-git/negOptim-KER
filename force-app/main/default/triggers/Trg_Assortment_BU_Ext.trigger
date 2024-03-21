/**
 * @author ULiT
 * @description Trigger Trg_Assortment_BU_Ext interface
 * @date 08/09/2023
 * */
trigger Trg_Assortment_BU_Ext on Negoptim__Assortment_BU__c (before insert, after update) {
    
    if (Trigger.isBefore) {
        if (Trigger.isInsert) {
            Trg_Assortment_BU_Handler_Ext.onBeforeInsert(Trigger.new);
        }
    }
    if (Trigger.isAfter) {
        if (Trigger.isUpdate) {
            Trg_Assortment_BU_Handler_Ext.onAfterUpdate(Trigger.new, Trigger.oldMap);
        }
    }
}