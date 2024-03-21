/**
 * @author ULiT
 * @description Trigger Trg_Assortment_Detail_Ext interface
 * @date 22/02/2024
 * */
trigger Trg_Assortment_Detail_Ext on Negoptim__Assortment_Detail__c (before insert, after insert, after update) {

    if (Trigger.isBefore) {
        if (Trigger.isInsert) {
            Trg_Assortment_Detail_Handler_Ext.onBeforeInsert(Trigger.new);
        }
    }
    if (Trigger.isAfter) {
        if (Trigger.isInsert || Trigger.isUpdate) {
            Trg_Assortment_Detail_Handler_Ext.onAfterInsertOrUpdate(Trigger.new, Trigger.oldMap);
        }
    }
}