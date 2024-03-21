/**
* @author ULiT
* @description unit test for  Duplicate assortment bu from another assortment bu 
* @date 7/9/2023
* */
@isTest
private class DuplicateAssortmentBUInvocable_Ext_Test {
    
    private static Integer count = 20;
    private static Negoptim__Assortment_BU__c assortmentBU;
    private static Negoptim__Assortment_BU__c parentAssortmentBU;
    private static Negoptim__Orga_BU__c country;
    private static List<Product2> products;
    private static Negoptim__Orga_HE__c department ;
    private static Negoptim__Orga_HE__c section;
    private static Negoptim__Orga_BU__c buSource;
    private static Negoptim__Orga_BU__c buTarget;
    
    static void init () {
        try {
            SelectedBU bu = new SelectedBU();
            // Root element Id.
            Id rootId = Negoptim.NegoptimHelper.getRootIdByRT('Product');
            // Insert Country List.
            Negoptim__Country_List__c myCountry = TestDataFactoryExt.createCountry(true, 'FRANCE', 'FR');
            // Insert Region.
            Negoptim__Orga_BU__c region = TestDataFactoryExt.createBURegion(true, 'EU');
            // Insert Country.
            country = TestDataFactoryExt.createBUCountry(true, myCountry, region.Id);
            // Assortment BU Source
            buSource = TestDataFactoryExt.createBUBanner(false, country);
            buSource.Negoptim__isMasterBU__c = true;
            // Assortment BU Target
            buTarget = TestDataFactoryExt.createBUBanner(false, country);
            insert new List<Negoptim__Orga_BU__c> {BUSource, BUTarget};
                // create HEs
            department = TestDataFactoryExt.createDepartment(false, rootId);
            department.Negoptim__Set_Product_link_level__c = true;
            insert department;
            assortmentBU = TestDataFactoryExt.createAssortmentBU(false, buSource, buTarget, department);
            assortmentBU.Negoptim__Status__c = 'Validated';
            insert assortmentBU;
            section = TestDataFactoryExt.createSection(true, department.Id);
            // Create Assortment Details manually to cover as many cases as possible
            products = new List<Product2>();
            for(Integer i = 0; i < count; i++) {
                Product2 product = TestDataFactoryExt.createProduct(false, section.Id, null);
                products.add(product);
            }
            insert products;
            List<Negoptim__Assortment_Detail__c> assortmentDetails = new List<Negoptim__Assortment_Detail__c>();
            for(Integer i = 0; i < count; i++) {
                Negoptim__Assortment_Detail__c assortmentDetail = TestDataFactoryExt.createAssortmentDetail(false, assortmentBU.Id, products[i], null);
                assortmentDetails.add(assortmentDetail);
            }
            insert assortmentDetails;
        } catch (Exception ex) {
            System.debug(ex.getMessage() ); 
            System.debug(ex.getStackTraceString());
        }
    }
    static testmethod void cloneAssortmentBUWithSelectedBUs() {
        init();
        parentAssortmentBU = TestDataFactoryExt.createAssortmentBU(false, buSource, buTarget, department);
        Integer lastYear = System.Today().year() - 1;
        parentAssortmentBU.Negoptim__Year__c = lastYear;
        parentAssortmentBU.Negoptim__Ass_BDate__c = Date.newInstance(lastYear, 1, 1);
        parentAssortmentBU.Negoptim__Ass_EDate__c = Date.newInstance(lastYear, 12, 31);
        parentAssortmentBU.Negoptim__Status__c = 'Validated';
        insert parentAssortmentBU;
        List<Negoptim__Assortment_Detail__c> parentAssortmentDetails = new List<Negoptim__Assortment_Detail__c>();
        for(Integer i = 0; i < count; i++) {
            Negoptim__Assortment_Detail__c assortmentDetail = TestDataFactoryExt.createAssortmentDetail(false, parentAssortmentBU.Id, products[i], null);
            assortmentDetail.Negoptim__Status__c = 'Validated';
            parentAssortmentDetails.add(assortmentDetail);
        }
        insert parentAssortmentDetails;
        assortmentBU.Negoptim__Assortment_parent__c = parentAssortmentBU.Id;
        update assortmentBU;
        Test.startTest();
        DuplicateAssortmentBUInvocable_Ext.AssortmentsWrapper assortmentToBecreated = new DuplicateAssortmentBUInvocable_Ext.AssortmentsWrapper(String.valueOf(assortmentBU.Id), 
                                                                                                                                                new List<SelectedBU> {new SelectedBU(String.valueOf(buSource.Id), 
                                                                                                                                                                                     String.valueOf(buTarget.Id))},
                                                                                                                                                false);
        List<DuplicateAssortmentBUInvocable_Ext.duplicatedAssortment> dupAssortBU = DuplicateAssortmentBUInvocable_Ext.duplicateAssortmentBU(new List<DuplicateAssortmentBUInvocable_Ext.AssortmentsWrapper> {assortmentToBecreated});
        String dupAssortmentBU = dupAssortBU[0].duplicatedRecordId;
        
        Negoptim__Assortment_BU__c duplicatedAssortment = [SELECT Id, Negoptim__Assortment_parent__c, Negoptim__Year__c, Negoptim__BU_source__c, Negoptim__BU_Target__c, RecordTypeId, 
                                                           Negoptim__Assortment_parent__r.Negoptim__BU_source__c, Negoptim__Assortment_parent__r.Negoptim__BU_Target__c, Negoptim__Assortment_parent__r.RecordTypeId
                                                           FROM Negoptim__Assortment_BU__c WHERE Id = :dupAssortmentBU];
        Map<String, Negoptim__Assortment_BU__c> assortmnentBUMap = new Map<String, Negoptim__Assortment_BU__c>();
        assortmnentBUMap.put(duplicatedAssortment.Negoptim__Assortment_parent__r.RecordTypeId + '' +  duplicatedAssortment.Negoptim__Assortment_parent__r.Negoptim__BU_source__c + '' + duplicatedAssortment.Negoptim__Assortment_parent__r.Negoptim__BU_Target__c, duplicatedAssortment);
        Negoptim.NegoptimBatch.executeBatch(new DuplicateAssortmentDetailBatch_Ext(DuplicateAssortmentBUInvocable_Ext_Test.class.getName(), assortmentBU.Id, new List<Id>{parentAssortmentBU.Id}, assortmnentBUMap), 20);
        Test.stopTest(); 
        System.assertEquals(duplicatedAssortment.Negoptim__BU_source__c, buSource.Id);
        System.assertEquals(duplicatedAssortment.Negoptim__BU_Target__c, buTarget.Id);
        System.assertEquals(duplicatedAssortment.Negoptim__Assortment_parent__c, parentAssortmentBU.Id);
        List<Negoptim__Assortment_Detail__c> duplicatedAssortmentDetail = [SELECT Id
                                                                           FROM Negoptim__Assortment_Detail__c 
                                                                           WHERE Negoptim__Assortment_BU__c = :duplicatedAssortment.Id];
        
        System.assertEquals(count, duplicatedAssortmentDetail.size());
    }
    static testmethod void generateRegionalAssortment() {
        init();
        // Assortment BU Source
        Negoptim__Orga_BU__c buSource = TestDataFactoryExt.createBUBanner(false, country);
        buSource.Negoptim__isMasterBU__c = true;
        // Assortment BU Target
        Negoptim__Orga_BU__c buTarget = TestDataFactoryExt.createBUBanner(false, country);
        insert new List<Negoptim__Orga_BU__c> {buSource, buTarget};
        parentAssortmentBU = TestDataFactoryExt.createAssortmentBU(false, buSource, buTarget, department);
        Integer lastYear = System.Today().year() - 1;
        parentAssortmentBU.Negoptim__Year__c = lastYear;
        parentAssortmentBU.Negoptim__Ass_BDate__c = Date.newInstance(lastYear, 1, 1);
        parentAssortmentBU.Negoptim__Ass_EDate__c = Date.newInstance(lastYear, 12, 31);
        parentAssortmentBU.Negoptim__Status__c = 'Validated';
        insert parentAssortmentBU;
        List<Negoptim__Assortment_Detail__c> parentAssortmentDetails = new List<Negoptim__Assortment_Detail__c>();
        for(Integer i = 0; i < count; i++) {
            Negoptim__Assortment_Detail__c assortmentDetail = TestDataFactoryExt.createAssortmentDetail(false, parentAssortmentBU.Id, products[i], null);
            assortmentDetail.Negoptim__Status__c = 'Validated';
            parentAssortmentDetails.add(assortmentDetail);
        }
        insert parentAssortmentDetails;
        Test.startTest();
        DuplicateAssortmentBUInvocable_Ext.AssortmentsWrapper assortmentToBecreated = new DuplicateAssortmentBUInvocable_Ext.AssortmentsWrapper(String.valueOf(assortmentBU.Id), 
                                                                                                                                                new List<SelectedBU> {new SelectedBU(String.valueOf(buSource.Id), 
                                                                                                                                                                                     String.valueOf(buTarget.Id))},
                                                                                                                                                true);
        DuplicateAssortmentBUInvocable_Ext.duplicateAssortmentBU(new List<DuplicateAssortmentBUInvocable_Ext.AssortmentsWrapper> {assortmentToBecreated});
        //Negoptim.NegoptimBatch.executeBatch(new DuplicateAssortmentDetailBatch_Ext(DuplicateAssortmentBUInvocable_Ext.class.getName(), assortmentBU.Id, new List<id>{'parentAssortmentBU'}, new Map<String, Negoptim__Assortment_BU__c>{assortmentBU.RecordTypeId + assortmentBU.selectedBUSource + assortmentBU.selectedBUTarget}), 20);
        Test.stopTest();
    }
}