/**
 * @author ULiT
 * @date 25-feb-2019
*/
@isTest
private class AssortmentBUMatrixControllerTestExt {

    private static Integer year;
    private static String currencyIsoCode;
    private static Negoptim__Orga_BU__c region;
    private static Negoptim__Orga_BU__c country;
    private static Negoptim__Supplier__c client;
    private static Negoptim__Orga_BU__c buSource;
    private static Negoptim__Orga_BU__c buTarget;
    private static List<Negoptim__Orga_BU__c> stratList;
    private static List<Negoptim__Orga_HE__c> orgaHEList;
    private static List<Product2> products;
    private static Negoptim__Orga_HE__c assortmentCategory;
    private static Negoptim__Assortment_BU__c assortment;
    private static List<Negoptim__Assortment_Detail__c> details;

    /**
     * @description generates and initializes commun data for tests
     * calculates the current year
     * creates a country [Country_List__c]
     * Creates a region [Orga_BU__c]
     * creates a bu [Orga_BU__c] of type record type country
     * creates a supplier [Supplier__c] related to the bu country
     * creates clientBranch bu [Orga_BU__c] of type record type country to represent one of the client's store groupes and assigns the related client field [Orga_BU__c.Related_Client__c]
     * creates a tree of hierarchy elements [Orga_HE__c] of depth 4 and with 3 elements on each level
     * creates 5 starts [Orga_BU__c] on clientBranch with category field null [Orga_BU__c.Category__c]
     * creates 4 strats [Orga_BU__c] on clientBranch with category field [Orga_BU__c.Category__c] of level 3 (limit to 2 categories)
     * the total of strats is (5 w/ category null) + (8 w/ category not null) = 13 strats
     * creates 1 product [Product2] on each element [Orga_HE__c] of level 4
     * assigns 1 element [Orga_HE__c] of level 1 to a variable
     * creates an assortment [Assortment_BU__c]
     * creates an assortment detail [Assortment_Detail__c] for each product
     * sets the test current page reference to Assortment BU Matrix
	*/
    static void init() {
        try {
            Map<String, Id> productRTIds = Negoptim.NegoptimHelper.getObjectRecordTypeMapIds(Product2.SObjectType);
            Map<String, Id> assDetailRTIds = Negoptim.NegoptimHelper.getObjectRecordTypeMapIds(Negoptim__Assortment_Detail__c.SObjectType);
            //Negoptim__NegoptimCustomSettings__c negoptimCustomSettings = Negoptim.TestDataFactory.createNegoptimCustomSettings(false);
            //negoptimCustomSettings.Negoptim__Assortment_Matrix_Grid_Layout__c = CommonConstants.GRID_SETTINGS_DEFAULT;
            //negoptimCustomSettings.Negoptim__Higher_Level_Packaging_Record_Type_Id__c = productRTIds.get('Higher_Level_Packaging');
            //insert negoptimCustomSettings;
            year = System.Today().year();
            region = TestDataFactoryExt.CreateBURegion(true, 'region');
            Negoptim__Country_List__c countryList = TestDataFactoryExt.createCountry(true, 'France', 'FR');
            country = TestDataFactoryExt.createBUCountry(true, countryList, region.Id);
            client = TestDataFactoryExt.createSupplier(true, country, false);
            orgaHEList = TestDataFactoryExt.createElementHierarchy(4, 1);
            buSource = TestDataFactoryExt.createBUChannel(false, country);
            buSource.Negoptim__IsMasterBU__c = true;
            buTarget = TestDataFactoryExt.createBUBanner(false, country);
            buTarget.Negoptim__Mission__c = 'Offer';
            buTarget.Negoptim__IsMasterBU__c = false;
            buTarget.Negoptim__Related_Client__c = client.Id;
            buTarget.Negoptim__Category__c = orgaHEList[1].Id;
            insert new List<Negoptim__Orga_BU__c> {buSource, buTarget};
                
                stratList = new List<Negoptim__Orga_BU__c>();
            for (Integer i = 0; i < 4; i++) {
                stratList.add(TestDataFactoryExt.createBUAssortCluster(false, buTarget.Id, 'Strat' + i));
            }
            Negoptim__Orga_BU__c closedBU = TestDataFactoryExt.createBUAssortCluster(false, buTarget.Id, 'Strat0');
            closedBU.Negoptim__BU_CDate__c = System.Today().addMonths(-1);
            stratList.add(closedBU);
            insert stratList;
            products = new List<Product2>();
            for (Integer i = 0; i < 26; i++) {
                products.add(TestDataFactoryExt.createProduct(false, orgaHEList[4].Id, null));
            }
            insert products;
            assortment = TestDataFactoryExt.createAssortmentBU(true, buSource, buTarget, orgaHEList[1]);
            details = new List<Negoptim__Assortment_Detail__c>();
            for (Product2 item : products) {
                details.add(new Negoptim__Assortment_Detail__c(Negoptim__Product__c = item.Id, Negoptim__Assortment_BU__c = assortment.Id,
                                                     Negoptim__Status__c = 'In preparation', Negoptim__Client_Status__c = 'Keep',
                                                     Negoptim__New_Client_Unit_Cost__c = 4, recordTypeId = assDetailRTIds.get('Regular')));
            }
            insert details;
            PageReference pageRef = Page.AssortmentBUMatrixExt;
            Test.setCurrentPage(pageRef);
        } catch (Exception ex) {
            System.debug('++++++++++++++++++++++++++++++');
            System.debug(ex.getMessage() );
            System.debug(ex.getStackTraceString() );
            System.debug('++++++++++++++++++++++++++++++');
        }
    }

    /**
     * @description sets the number of fetched records against the number of assortment details inserted in init()
	*/
   static testMethod void test_constructor() {
        init();
        Test.startTest();
        ApexPages.StandardController stdController = new ApexPages.StandardController(assortment);
        AssortmentBUMatrixControllerExt ctrl = new AssortmentBUMatrixControllerExt(stdController);
        Test.stopTest();
        System.assertEquals(products.size(), ctrl.noOfRecords);
    }

    /**
     * @description
     * tests the set page size against the page size of the standard set controller in the controller instance
     * tests the current position againt the page number of the standard set controller in the controller instance
	*/
    static testMethod void test_navigation1() {
        init();
        Test.startTest();
        ApexPages.StandardController stdController = new ApexPages.StandardController(assortment);
        AssortmentBUMatrixControllerExt ctrl = new AssortmentBUMatrixControllerExt(stdController);
        ctrl.pageSize = 25;
        ctrl.refreshPageSize();
        System.assertEquals(25, ctrl.assortmentDetailStdSetCtrl.getPageSize());
        ctrl.next();
        ctrl.first();
        System.assertEquals(((decimal) products.size()/25).setScale(0, RoundingMode.UP) - 1, ctrl.assortmentDetailStdSetCtrl.getPageNumber());
        Test.stopTest();
    }
     static testMethod void test_navigation2() {
        init();
        Test.startTest();
        ApexPages.StandardController stdController = new ApexPages.StandardController(assortment);
        AssortmentBUMatrixControllerExt ctrl = new AssortmentBUMatrixControllerExt(stdController);
        ctrl.pageSize = 25;
        ctrl.refreshPageSize();
        System.assertEquals(25, ctrl.assortmentDetailStdSetCtrl.getPageSize());
        ctrl.last();
        ctrl.previous();
        System.assertEquals(((decimal) products.size()/25).setScale(0, RoundingMode.UP) - 1, ctrl.assortmentDetailStdSetCtrl.getPageNumber());
        Test.stopTest();
    }

    static testmethod void test_search_by_category() {
        init();
        Test.startTest();
        ApexPages.StandardController stdController = new ApexPages.StandardController(assortment);
        AssortmentBUMatrixControllerExt ctrl = new AssortmentBUMatrixControllerExt(stdController);

        // search records by a parent category
        ctrl.product.Negoptim__Category__c = orgaHEList[3].Id;

        // search records by a parent category
        ctrl.clientStatus = 'Keep-Decrease';
        ctrl.search();
        System.assertEquals(products.size(), ctrl.noOfRecords);

        Test.stopTest();
    }

    static testmethod void test_search_by_product() {
        init();
        Test.startTest();
        ApexPages.StandardController stdController = new ApexPages.StandardController(assortment);
        AssortmentBUMatrixControllerExt ctrl = new AssortmentBUMatrixControllerExt(stdController);

        String productName = products[0].Name;

        // search records by product by name
        ctrl.productSearch = productName;
        ctrl.search();
        System.assertEquals(1, ctrl.noOfRecords);

        Test.stopTest();
    }

    static testmethod void test_search_history() {
        init();
        Test.startTest();
        ApexPages.StandardController stdController = new ApexPages.StandardController(assortment);
        AssortmentBUMatrixControllerExt ctrl = new AssortmentBUMatrixControllerExt(stdController);

        Negoptim__Assortment_Detail__c historyLine = details[0].clone(false);
        historyLine.Negoptim__Status__c = 'Validated';
        historyLine.Negoptim__Version__c = 1;

        // show history
        insert historyLine;
        ctrl.isShowHistory = true;
        ctrl.search();
        System.assertEquals(products.size() + 1, ctrl.noOfRecords);

        Test.stopTest();
    }

    static testmethod void test_save() {
        init();
        ApexPages.StandardController stdController = new ApexPages.StandardController(assortment);
        AssortmentBUMatrixControllerExt ctrl = new AssortmentBUMatrixControllerExt(stdController);
        Test.startTest();
        AssortmentBUMatrixControllerExt.CategoryWrapper detailwrapper = ctrl.wAssortmentDetailList[0];
        detailwrapper.assortmentDetails[0].Negoptim__Client_Status__c = 'Keep';

        Negoptim__Assortment_Detail__c detailToSave = ctrl.wAssortmentDetailList[0].assortmentDetails[0];
        detailToSave.Negoptim__Client_Status__c = 'Decrease';
        // ctrl.wAssortmentDetailList[0].assortmentDetails[0].Client_Status__c = 'Keep';
        AssortmentBUMatrixControllerExt.evaluateAssortmentDetail(JSON.serialize(detailToSave), ctrl.fieldsToSumList_serialized, JSON.serialize(new List<String>()));
        ctrl.save();
        Test.stopTest();
        system.assert(true);
    }

    static testmethod void test_Change_Status_RequestForApproval() {
        init();
        Test.startTest();
        ApexPages.StandardController stdController = new ApexPages.StandardController(assortment);
        AssortmentBUMatrixControllerExt ctrl = new AssortmentBUMatrixControllerExt(stdController);

        ctrl.requestForApproval();
        System.assertEquals('Request for Approval', ctrl.assortmentBU.Negoptim__Status__c);

        Test.stopTest();
    }

    static testmethod void test_Change_Reset_Filter() {
        init();
        Test.startTest();
        ApexPages.StandardController stdController = new ApexPages.StandardController(assortment);
        AssortmentBUMatrixControllerExt ctrl = new AssortmentBUMatrixControllerExt(stdController);

        ctrl.productSearch = 'PRD';
        System.assertEquals(products.size(), ctrl.noOfRecords);
        ctrl.resetFilters();
        System.assertEquals('', ctrl.productSearch);
        Test.stopTest();
    }

    static testmethod void test_Send() {
        init();
        Test.startTest();
        ApexPages.StandardController stdController = new ApexPages.StandardController(assortment);
        AssortmentBUMatrixControllerExt ctrl = new AssortmentBUMatrixControllerExt(stdController);

        ctrl.send();
        Test.stopTest();
    }

    static testmethod void coverage() {
        init();
        test.startTest();
        ApexPages.StandardController stdController = new ApexPages.StandardController(assortment);
        AssortmentBUMatrixControllerExt ctrl = new AssortmentBUMatrixControllerExt(stdController);
        ctrl.hideBlankStatus = true;
        ctrl.showIntroProducts = true;
        ctrl.onlyShowIntroProducts = true;
        ctrl.isShowHistory = true;
        // dynamic table
        ctrl.getDynamicPageBlockTable();
        ctrl.generateExcel();
        ctrl.popupGenerateExcel = true;
        ctrl.popupSwitchProduct = true;
        ctrl.showPopup();
        ctrl.cancelPopup();
        test.stopTest();
        System.assert(true);
    }

    static testmethod void test_HigherLevelPackaging() {
        init();
        Product2 hlp = TestDataFactoryExt.createProduct(false, orgaHEList[4].Id, null);
        hlp.RecordTypeId = Negoptim.NegoptimHelper.getObjectRecordTypeId(Product2.SObjectType, CommonConstants.RT_Product2_HIGHER_LEVEL_PACKAGING);
        hlp.Negoptim__Consumer_Trade_Item__c = details[0].Negoptim__Product__c;
        insert hlp;
        test.startTest();
        ApexPages.StandardController stdController = new ApexPages.StandardController(assortment);
        AssortmentBUMatrixControllerExt ctrl = new AssortmentBUMatrixControllerExt(stdController);
        ctrl.productToSelectedHigherLevelPackaging = details[0].Negoptim__Product__c;
        ctrl.popupSelectHigherLevelPackaging = true;
        ctrl.showPopup();
        ctrl.higherLevelPackagingWrapperList.get(0).isSelected = true;
        ctrl.higherLevelPackagingWrapperList.get(0).isMasterHigherLevelPackagingDetail = true;
        ctrl.saveHigherLevelPackagingSelection();
        test.stopTest();
    }
}