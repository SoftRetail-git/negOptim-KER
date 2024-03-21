/*
 * @author ULiT
 * @date 19-03-2024
 * @description Unit test for ConsolidateAssortmentBatchExt
 */
@isTest
private class ConsolidateAssortmentBatchExtTest {

    private static Integer year;
    private static Integer month;
    private static Id rootId;
    private static String currencyIsoCode;
    private static Negoptim__Orga_BU__c country;
    private static Negoptim__Orga_BU__c buConsoHMSM;
    private static Negoptim__Orga_BU__c buConsoDrive;
    private static Negoptim__Orga_BU__c masterBU;
    private static Negoptim__Orga_BU__c buBannerHM;
    private static Negoptim__Orga_BU__c buBannerSM;
    private static Negoptim__Orga_BU__c buBannerDrive;
    private static Negoptim__Supplier__c client;
    private static Negoptim__Orga_HE__c department;
    private static Negoptim__Orga_HE__c section;
    private static Product2 product1;
    private static Product2 product2;
    private static Negoptim__Orga_BU__c cluster1;
    private static Negoptim__Orga_BU__c cluster2;
    private static Negoptim__Orga_BU__c cluster3;
    
    static void init() {
        year = System.Today().year();
        month = System.Today().month();
        // Root element Id.
        rootId = Negoptim.NegoptimHelper.getRootIdByRT('Product');
        // Get the Corporate Currency.
        currencyIsoCode = Negoptim.NegoptimHelper.getCorporateCurrency();
        // Insert Country List.
        Negoptim__Country_List__c myCountry = TestDataFactoryExt.createCountry(true, 'FRANCE', 'FR');
        // Insert Region.
        Negoptim__Orga_BU__c region = TestDataFactoryExt.createBURegion(true, 'EU');
        // Insert Country.
        country = TestDataFactoryExt.createBUCountry(true, myCountry, region.Id);
        // Create Supplier
        client = TestDataFactoryExt.createSupplier(false, country, true);
        insert client;
        // Get the default negoscope created on supplier creation.
        // Create Departments & Sections.
        department = TestDataFactoryExt.createDepartment(true, rootId);
        section = TestDataFactoryExt.createSection(true, department.Id);
        // Create Product.
        product1 = TestDataFactoryExt.createProduct(false, section.Id, null);
        product1.Name = 'product1';
        product1.Negoptim__Ext_id__c = '1';
        product2 = TestDataFactoryExt.createProduct(false, section.Id, null);
        product2.Name = 'product2';
        product2.Negoptim__Ext_id__c = '2';
        insert new List<Product2>{product1,product2};
        // Create Conso BO
        buConsoHMSM = TestDataFactoryExt.createBUBanner(false, country);
        buConsoHMSM.Negoptim__Mission__c = 'Panelist;Offer';
        buConsoHMSM.Negoptim__Format_Origin__c = CommonConstants.HMSM;
        buConsoHMSM.Negoptim__Related_Client__c = client.Id;
        buConsoHMSM.Negoptim__Layer_Nego_Conso__c = true;
        buConsoHMSM.Negoptim__Category__c = department.Id;
        buConsoHMSM.Negoptim__Weighted_Distribution_Manual__c = 50;
        buConsoDrive = TestDataFactoryExt.createBUBanner(false, country);
        buConsoDrive.Negoptim__Mission__c = 'Panelist;Offer';
        buConsoDrive.Negoptim__Format_Origin__c = 'Drive';
        buConsoDrive.Negoptim__Related_Client__c = client.Id;
        buConsoDrive.Negoptim__Layer_Nego_Conso__c = true;
        buConsoDrive.Negoptim__Category__c = department.Id;
        buConsoDrive.Negoptim__Weighted_Distribution_Manual__c = 60;
        // Create Master BU
        masterBU = TestDataFactoryExt.createBUChannel(false, country);
        masterBU.Negoptim__Mission__c = 'Panelist;Offer';
        masterBU.Negoptim__Format_Origin__c = CommonConstants.HMSM;
        masterBU.Negoptim__Related_Client__c = client.Id;
        masterBU.Negoptim__IsMasterBU__c = true;
        masterBU.Negoptim__SiteOfSales_Number__c = 100;

        // Create BU Banner
        buBannerHM = TestDataFactoryExt.createBUBanner(false, country);
        buBannerHM.Negoptim__Mission__c = 'Offer';
        buBannerHM.Negoptim__Format_Origin__c = CommonConstants.HMSM;
        buBannerHM.Negoptim__Related_Client__c = client.Id;
        buBannerHM.Negoptim__Category__c = department.Id;
        buBannerHM.Negoptim__Weighted_Distribution_Manual__c = 10;
        buBannerSM = TestDataFactoryExt.createBUBanner(false, country);
        buBannerSM.Negoptim__Mission__c = 'Offer';
        buBannerSM.Negoptim__Format_Origin__c = CommonConstants.HMSM;
        buBannerSM.Negoptim__Related_Client__c = client.Id;
        buBannerSM.Negoptim__Category__c = department.Id;
        buBannerSM.Negoptim__Weighted_Distribution_Manual__c = 20;
        buBannerDrive = TestDataFactoryExt.createBUBanner(false, country);
        buBannerDrive.Negoptim__Mission__c = 'Offer';
        buBannerDrive.Negoptim__Format_Origin__c = 'Drive;';
        buBannerDrive.Negoptim__Related_Client__c = client.Id;
        buBannerDrive.Negoptim__Category__c = department.Id;
        buBannerDrive.Negoptim__Weighted_Distribution_Manual__c = 30;
        insert new List<Negoptim__Orga_BU__c>{buConsoHMSM,buConsoDrive,masterBU,buBannerHM,buBannerSM,buBannerDrive};
        // Create BU Cluster
        cluster1 = TestDataFactoryExt.createBUAssortCluster(false, buBannerHM.Id, 'Strat0');
        cluster1.Negoptim__Category__c = department.Id;
        cluster1.Negoptim__Weighted_Distribution_Manual__c = 10;
        cluster1.Negoptim__Weighted_Distribution_Manual_N1__c = 10;
        cluster1.Negoptim__SiteOfSales_Number__c = 20;
        cluster1.Negoptim__Mission__c = 'Offer';
        cluster1.Negoptim__BU_ODate__c = Date.today().addDays(-1);
        cluster1.Negoptim__Country_origin__c = buBannerHM.Id;
        cluster2 = TestDataFactoryExt.createBUAssortCluster(false, buBannerSM.Id, 'Strat0');
        cluster2.Negoptim__Category__c = department.Id;
        cluster2.Negoptim__Weighted_Distribution_Manual__c = 20;
        cluster2.Negoptim__Weighted_Distribution_Manual_N1__c = 20;
        cluster2.Negoptim__SiteOfSales_Number__c = 30;
        cluster2.Negoptim__BU_ODate__c = Date.today().addDays(-1);
        cluster2.Negoptim__Mission__c = 'Offer';
        cluster2.Negoptim__Country_origin__c = buBannerSM.Id;
        cluster3 = TestDataFactoryExt.createBUAssortCluster(false, buBannerDrive.Id, 'Strat0');
        cluster3.Negoptim__Category__c = department.Id;
        cluster3.Negoptim__Weighted_Distribution_Manual__c = 20;
        cluster3.Negoptim__Weighted_Distribution_Manual_N1__c = 20;
        cluster3.Negoptim__SiteOfSales_Number__c = 30;
        cluster3.Negoptim__BU_ODate__c = Date.today().addDays(-1);
        cluster3.Negoptim__Mission__c = 'Offer';
        cluster3.Negoptim__Country_origin__c = buBannerDrive.Id;
        insert new List<Negoptim__Orga_BU__c>{cluster1,cluster2,cluster3};
    }
    
    @isTest static void case1_consolidate_nego() {
        init();
        Test.startTest();
        // insert parent assortment Conso
        Negoptim__Assortment_BU__c parentAssortmentConsoHMSM = TestDataFactoryExt.createAssortmentBU(false, masterBU, buConsoHMSM, department);
        parentAssortmentConsoHMSM.RecordTypeId = TestDataFactoryExt.assortmentRTIds.get('Conso');
        parentAssortmentConsoHMSM.Negoptim__Ass_BDate__c = Date.newInstance(year - 1, 1, 1);
        parentAssortmentConsoHMSM.Negoptim__Ass_EDate__c = Date.newInstance(year - 1, 12, 31);
        parentAssortmentConsoHMSM.Negoptim__Year__c = Integer.valueOf(year - 1);
        parentAssortmentConsoHMSM.Negoptim__Assortment_type__c = 'Out';
        parentAssortmentConsoHMSM.Negoptim__Status__c = 'Validated';
        Negoptim__Assortment_BU__c parentAssortmentConsoDrive = TestDataFactoryExt.createAssortmentBU(false, masterBU, buConsoDrive, department);
        parentAssortmentConsoDrive.RecordTypeId = TestDataFactoryExt.assortmentRTIds.get('Conso');
        parentAssortmentConsoDrive.Negoptim__Ass_BDate__c = Date.newInstance(year - 1, 1, 1);
        parentAssortmentConsoDrive.Negoptim__Ass_EDate__c = Date.newInstance(year - 1, 12, 31);
        parentAssortmentConsoDrive.Negoptim__Year__c = Integer.valueOf(year - 1);
        parentAssortmentConsoDrive.Negoptim__Assortment_type__c = 'Out';
        parentAssortmentConsoDrive.Negoptim__Status__c = 'Validated';
        // insert assortment_BU
        Negoptim__Assortment_BU__c assortmentBU1 = TestDataFactoryExt.createAssortmentBU(false, masterBU, buBannerHM, department);
        assortmentBU1.Negoptim__Status__c = 'Validated';
        assortmentBU1.Negoptim__Assortment_type__c = 'Out';
        assortmentBU1.Negoptim__Target_Simulation__c = true;
        Negoptim__Assortment_BU__c assortmentBU2 = TestDataFactoryExt.createAssortmentBU(false, masterBU, buBannerSM, department);
        assortmentBU2.Negoptim__Status__c = 'Validated';
        assortmentBU2.Negoptim__Assortment_type__c = 'Out';
        assortmentBU2.Negoptim__Target_Simulation__c = true;
        Negoptim__Assortment_BU__c assortmentBU3 = TestDataFactoryExt.createAssortmentBU(false, masterBU, buBannerDrive, department);
        assortmentBU3.Negoptim__Status__c = 'Validated';
        assortmentBU3.Negoptim__Assortment_type__c = 'Out';
        insert new List<Negoptim__Assortment_BU__c>{parentAssortmentConsoHMSM,parentAssortmentConsoDrive,assortmentBU1,assortmentBU2,assortmentBU3};
        // insert parent Assortment_Detail__c
        Negoptim__Assortment_Detail__c parentAssortmentDetail1 = TestDataFactoryExt.createAssortmentDetail(false, parentAssortmentConsoHMSM.Id, product1, null);
        parentAssortmentDetail1.Negoptim__Status__c = 'Validated';
        parentAssortmentDetail1.Negoptim__Movement_Date__c = Date.newInstance(year - 1, month, Date.today().day());
        parentAssortmentDetail1.Negoptim__Record_date__c = Date.newInstance(year - 1, month, Date.today().day());
        // insert Assortment_Detail__c
        Negoptim__Assortment_Detail__c assortmentDetail1 = TestDataFactoryExt.createAssortmentDetail(false, assortmentBU1.Id, product1, null);
        assortmentDetail1.Negoptim__Status__c = 'Validated';
        assortmentDetail1.Negoptim__Client_Status__c = 'New';
        assortmentDetail1.Negoptim__New_Client_WD_ClientBased__c = 11.27;
        assortmentDetail1.Negoptim__New_Client_WD_MarketBased__c = 11.27;
        assortmentDetail1.Negoptim__WD_Conso__c = false;
        assortmentDetail1.Negoptim__Movement_Date__c = Date.newInstance(year - 1, month, Date.today().day());
        /*Assortment_Detail__c assortmentDetail2 = TestDataFactoryExt.createAssortmentDetail(false, assortmentBU1.Id, product2, null);
        assortmentDetail2.Status__c = 'Validated';
        assortmentDetail2.Client_Status__c = 'New';
        assortmentDetail2.New_Client_WD_ClientBased__c = 22;
        assortmentDetail2.WD_Conso__c = false;
        
        Assortment_Detail__c assortmentDetail3 = TestDataFactoryExt.createAssortmentDetail(false, assortmentBU2.Id, product1, null);
        assortmentDetail3.Status__c = 'Validated';
        assortmentDetail3.Client_Status__c = 'New';
        assortmentDetail3.New_Client_WD_ClientBased__c = 33.23;
        assortmentDetail3.New_Client_WD_MarketBased__c = 33.23;
        assortmentDetail3.WD_Conso__c = false;
        assortmentDetail3.Movement_Date__c = Date.newInstance(year, month, Date.today().day());
        Assortment_Detail__c assortmentDetail4 = TestDataFactoryExt.createAssortmentDetail(false, assortmentBU2.Id, product2, null);
        assortmentDetail4.Status__c = 'Validated';
        assortmentDetail4.Client_Status__c = 'New';
        assortmentDetail4.New_Client_WD_ClientBased__c = 88;
        assortmentDetail4.WD_Conso__c = false;
        
        Assortment_Detail__c assortmentDetail5 = TestDataFactoryExt.createAssortmentDetail(false, assortmentBU3.Id, product1, null);
        assortmentDetail5.Status__c = 'Validated';
        assortmentDetail5.Client_Status__c = 'New';
        assortmentDetail5.New_Client_WD_ClientBased__c = 6;
        assortmentDetail5.WD_Conso__c = false;
        Assortment_Detail__c assortmentDetail6 = TestDataFactoryExt.createAssortmentDetail(false, assortmentBU3.Id, product2, null);
        assortmentDetail6.Status__c = 'Validated';
        assortmentDetail6.Client_Status__c = 'New';
        assortmentDetail6.New_Client_WD_ClientBased__c = 7;
        assortmentDetail6.WD_Conso__c = false;*/
        insert new List<Negoptim__Assortment_Detail__c>{parentAssortmentDetail1,assortmentDetail1/*,assortmentDetail2,assortmentDetail3,assortmentDetail4,assortmentDetail5,assortmentDetail6*/};
        
        // case Status='Request for Approval' and Last_History.Status='Validated'
        assortmentDetail1.Negoptim__New_Client_WD_MarketBased__c = 0;
        //assortmentDetail3.New_Client_WD_MarketBased__c = 0;
        update new List<Negoptim__Assortment_Detail__c>{assortmentDetail1/*,assortmentDetail3*/};
        assortmentDetail1.Negoptim__Status__c = 'Request for Approval';
        //assortmentDetail3.Status__c = 'Request for Approval';
        update new List<Negoptim__Assortment_Detail__c>{assortmentDetail1/*,assortmentDetail3*/};
        
        Database.executeBatch(new ConsolidateAssortmentBatchExt('ConsolidateAssortmentBatchExtTest', null, new Set<Id>{masterBU.Id}, new Set<Id>{department.Id},
                                                             new Set<Id>{product1.Id,product2.Id}, new Set<Integer>{year}));
        Test.stopTest();
        Negoptim__Assortment_Detail__c assortmentDetailConso1 = [SELECT Negoptim__New_Client_WD_ClientBased__c, Negoptim__Ref_Client_Assortment__c, Negoptim__Movement_Date__c, Negoptim__New_Client_LM__c FROM Negoptim__Assortment_Detail__c
                                                       WHERE Negoptim__Product__c = :product1.Id AND Negoptim__Assortment_BU__r.Negoptim__BU_Target__c = :buConsoHMSM.Id
                                                       AND Negoptim__Assortment_BU__r.RecordType.DeveloperName = 'Conso' AND Negoptim__Year__c = :year];
        /*Assortment_Detail__c assortmentDetailConso2 = [SELECT New_Client_WD_ClientBased__c, New_Client_LM__c FROM Assortment_Detail__c
                                                       WHERE Product__c = :product2.Id AND Assortment_BU__r.BU_Target__c = :buConsoHMSM.Id
                                                       AND Assortment_BU__r.RecordType.DeveloperName = 'Conso' AND Year__c = :year];
        Assortment_Detail__c assortmentDetailConso3 = [SELECT New_Client_WD_ClientBased__c, New_Client_LM__c FROM Assortment_Detail__c 
                                                       WHERE Product__c = :product1.Id AND Assortment_BU__r.BU_Target__c = :buConsoDrive.Id
                                                       AND Assortment_BU__r.RecordType.DeveloperName = 'Conso' AND Year__c = :year];*/
        System.assertEquals(3, [SELECT COUNT() FROM Negoptim__Assortment_BU__c WHERE RecordType.DeveloperName = 'Conso']);
        System.assertEquals(parentAssortmentDetail1.Id, assortmentDetailConso1.Negoptim__Ref_Client_Assortment__c);
        System.assertEquals(1, assortmentDetailConso1.Negoptim__New_Client_LM__c);
        //System.assertEquals(2, assortmentDetailConso2.New_Client_LM__c);
        //System.assertEquals(1, assortmentDetailConso3.New_Client_LM__c);
        Decimal weightedDistributionManual_HMSM = 50, weightedDistributionManual_Drive = 60;
        // case Conso HM/SM
        Decimal DV1 = 11.27*10/weightedDistributionManual_HMSM, DV2 = 33.23*20/weightedDistributionManual_HMSM;
        ////DV1 = DV1.setScale(1, System.RoundingMode.HALF_DOWN);
        Decimal DVTotal = DV1;
        System.assertEquals(/*15.6*/ DVTotal.setScale(1, System.RoundingMode.HALF_DOWN), assortmentDetailConso1.Negoptim__New_Client_WD_ClientBased__c);
        DV1 = 22*10/weightedDistributionManual_HMSM;
        ////DV1 = DV1.setScale(1, System.RoundingMode.HALF_DOWN);
        DV2 = 88*20/weightedDistributionManual_HMSM;
        DVTotal = DV1 + DV2;
        //System.assertEquals(DVTotal.setScale(1, System.RoundingMode.HALF_DOWN), assortmentDetailConso2.New_Client_WD_ClientBased__c);
        // case Conso Drive
        DV1 = 6*30/weightedDistributionManual_Drive;
        //System.assertEquals(DV1.setScale(1, System.RoundingMode.HALF_DOWN), assortmentDetailConso3.New_Client_WD_ClientBased__c);
        System.assertEquals(Date.newInstance(year-1, month, Date.today().day()), assortmentDetailConso1.Negoptim__Movement_Date__c);
        //assortmentDetail5 = [SELECT Id, WD_Conso__c FROM Assortment_Detail__c WHERE Id = :assortmentDetail5.Id];
        //System.assertEquals(true, assortmentDetail5.WD_Conso__c);
    }
    
    @isTest static void case1_consolidate_target() {
        init();
        Test.startTest();
        // insert parent assortment Conso
        Negoptim__Assortment_BU__c parentAssortmentConsoHMSM = TestDataFactoryExt.createAssortmentBU(false, masterBU, buConsoHMSM, department);
        parentAssortmentConsoHMSM.RecordTypeId = TestDataFactoryExt.assortmentRTIds.get('Conso');
        parentAssortmentConsoHMSM.Negoptim__Ass_BDate__c = Date.newInstance(year - 1, 1, 1);
        parentAssortmentConsoHMSM.Negoptim__Ass_EDate__c = Date.newInstance(year - 1, 12, 31);
        parentAssortmentConsoHMSM.Negoptim__Year__c = Integer.valueOf(year - 1);
        parentAssortmentConsoHMSM.Negoptim__Assortment_type__c = 'Out';
        parentAssortmentConsoHMSM.Negoptim__Status__c = 'Validated';
        Negoptim__Assortment_BU__c parentAssortmentConsoDrive = TestDataFactoryExt.createAssortmentBU(false, masterBU, buConsoDrive, department);
        parentAssortmentConsoDrive.RecordTypeId = TestDataFactoryExt.assortmentRTIds.get('Conso');
        parentAssortmentConsoDrive.Negoptim__Ass_BDate__c = Date.newInstance(year - 1, 1, 1);
        parentAssortmentConsoDrive.Negoptim__Ass_EDate__c = Date.newInstance(year - 1, 12, 31);
        parentAssortmentConsoDrive.Negoptim__Year__c = Integer.valueOf(year - 1);
        parentAssortmentConsoDrive.Negoptim__Assortment_type__c = 'Out';
        parentAssortmentConsoDrive.Negoptim__Status__c = 'Validated';
        // insert assortment_BU
        Negoptim__Assortment_BU__c assortmentBU1 = TestDataFactoryExt.createAssortmentBU(false, masterBU, buBannerHM, department);
        assortmentBU1.RecordTypeId = TestDataFactoryExt.assortmentRTIds.get('Target');
        assortmentBU1.Negoptim__Status__c = 'Validated';
        assortmentBU1.Negoptim__Assortment_type__c = 'In';
        assortmentBU1.Negoptim__Target_Simulation__c = true;
        Negoptim__Assortment_BU__c assortmentBU2 = TestDataFactoryExt.createAssortmentBU(false, masterBU, buBannerSM, department);
        assortmentBU2.RecordTypeId = TestDataFactoryExt.assortmentRTIds.get('Target');
        assortmentBU2.Negoptim__Status__c = 'Validated';
        assortmentBU2.Negoptim__Assortment_type__c = 'In';
        assortmentBU2.Negoptim__Target_Simulation__c = true;
        Negoptim__Assortment_BU__c assortmentBU3 = TestDataFactoryExt.createAssortmentBU(false, masterBU, buBannerDrive, department);
        assortmentBU3.RecordTypeId = TestDataFactoryExt.assortmentRTIds.get('Target');
        assortmentBU3.Negoptim__Status__c = 'Validated';
        assortmentBU3.Negoptim__Assortment_type__c = 'In';
        insert new List<Negoptim__Assortment_BU__c>{parentAssortmentConsoHMSM,parentAssortmentConsoDrive,assortmentBU1,assortmentBU2,assortmentBU3};
        // insert parent Assortment_Detail__c
        Negoptim__Assortment_Detail__c parentAssortmentDetail1 = TestDataFactoryExt.createAssortmentDetail(false, parentAssortmentConsoHMSM.Id, product1, null);
        parentAssortmentDetail1.Negoptim__Status__c = 'Validated';
        parentAssortmentDetail1.Negoptim__Movement_Date__c = Date.newInstance(year - 1, month, Date.today().day());
        parentAssortmentDetail1.Negoptim__Record_date__c = Date.newInstance(year - 1, month, Date.today().day());
        // insert Assortment_Detail__c
        Negoptim__Assortment_Detail__c assortmentDetail1 = TestDataFactoryExt.createAssortmentDetail(false, assortmentBU1.Id, product1, null);
        assortmentDetail1.Negoptim__Status__c = 'Validated';
        assortmentDetail1.Negoptim__Client_Status__c = 'New';
        assortmentDetail1.Negoptim__New_Client_WD_ClientBased__c = 11.27;
        assortmentDetail1.Negoptim__New_Client_WD_MarketBased__c = 11.27;
        assortmentDetail1.Negoptim__WD_Conso__c = false;
        assortmentDetail1.Negoptim__Movement_Date__c = Date.newInstance(year - 1, month, Date.today().day());
        Negoptim__Assortment_Detail__c assortmentDetail2 = TestDataFactoryExt.createAssortmentDetail(false, assortmentBU1.Id, product2, null);
        assortmentDetail2.Negoptim__Status__c = 'Validated';
        assortmentDetail2.Negoptim__Client_Status__c = 'New';
        assortmentDetail2.Negoptim__New_Client_WD_ClientBased__c = 22;
        assortmentDetail2.Negoptim__WD_Conso__c = false;
        
        Negoptim__Assortment_Detail__c assortmentDetail3 = TestDataFactoryExt.createAssortmentDetail(false, assortmentBU2.Id, product1, null);
        assortmentDetail3.Negoptim__Status__c = 'Validated';
        assortmentDetail3.Negoptim__Client_Status__c = 'New';
        assortmentDetail3.Negoptim__New_Client_WD_ClientBased__c = 33.23;
        assortmentDetail3.Negoptim__New_Client_WD_MarketBased__c = 33.23;
        assortmentDetail3.Negoptim__WD_Conso__c = false;
        assortmentDetail3.Negoptim__Movement_Date__c = Date.newInstance(year, month, Date.today().day());
        Negoptim__Assortment_Detail__c assortmentDetail4 = TestDataFactoryExt.createAssortmentDetail(false, assortmentBU2.Id, product2, null);
        assortmentDetail4.Negoptim__Status__c = 'Validated';
        assortmentDetail4.Negoptim__Client_Status__c = 'New';
        assortmentDetail4.Negoptim__New_Client_WD_ClientBased__c = 88;
        assortmentDetail4.Negoptim__WD_Conso__c = false;
        
        Negoptim__Assortment_Detail__c assortmentDetail5 = TestDataFactoryExt.createAssortmentDetail(false, assortmentBU3.Id, product1, null);
        assortmentDetail5.Negoptim__Status__c = 'Validated';
        assortmentDetail5.Negoptim__Client_Status__c = 'New';
        assortmentDetail5.Negoptim__New_Client_WD_ClientBased__c = 6;
        assortmentDetail5.Negoptim__WD_Conso__c = false;
        Negoptim__Assortment_Detail__c assortmentDetail6 = TestDataFactoryExt.createAssortmentDetail(false, assortmentBU3.Id, product2, null);
        assortmentDetail6.Negoptim__Status__c = 'Validated';
        assortmentDetail6.Negoptim__Client_Status__c = 'New';
        assortmentDetail6.Negoptim__New_Client_WD_ClientBased__c = 7;
        assortmentDetail6.Negoptim__WD_Conso__c = false;
        insert new List<Negoptim__Assortment_Detail__c>{parentAssortmentDetail1,assortmentDetail1,assortmentDetail2,assortmentDetail3,assortmentDetail4,assortmentDetail5,assortmentDetail6};
        
        // case Status='Request for Approval' and Last_History.Status='Validated'
        assortmentDetail1.Negoptim__New_Client_WD_MarketBased__c = 0;
        assortmentDetail3.Negoptim__New_Client_WD_MarketBased__c = 0;
        update new List<Negoptim__Assortment_Detail__c>{assortmentDetail1,assortmentDetail3};
        assortmentDetail1.Negoptim__Status__c = 'Request for Approval';
        assortmentDetail3.Negoptim__Status__c = 'Request for Approval';
        update new List<Negoptim__Assortment_Detail__c>{assortmentDetail1,assortmentDetail3};
        
        Database.executeBatch(new ConsolidateAssortmentBatchExt('ConsolidateAssortmentBatchExtTest', null, new Set<Id>{masterBU.Id}, new Set<Id>{department.Id},
                                                             new Set<Id>{product1.Id,product2.Id}, new Set<Integer>{year}));
        Test.stopTest();
        Negoptim__Assortment_Detail__c assortmentDetailConso1 = [SELECT Negoptim__New_Client_WD_ClientBased__c, Negoptim__Ref_Client_Assortment__c, Negoptim__Movement_Date__c, Negoptim__New_Client_LM__c FROM Negoptim__Assortment_Detail__c
                                                       WHERE Negoptim__Product__c = :product1.Id AND Negoptim__Assortment_BU__r.Negoptim__BU_Target__c = :buConsoHMSM.Id
                                                       AND Negoptim__Assortment_BU__r.RecordType.DeveloperName = 'Conso_Target' AND Negoptim__Year__c = :year];
        Negoptim__Assortment_Detail__c assortmentDetailConso2 = [SELECT Negoptim__New_Client_WD_ClientBased__c, Negoptim__New_Client_LM__c FROM Negoptim__Assortment_Detail__c
                                                       WHERE Negoptim__Product__c = :product2.Id AND Negoptim__Assortment_BU__r.Negoptim__BU_Target__c = :buConsoHMSM.Id
                                                       AND Negoptim__Assortment_BU__r.RecordType.DeveloperName = 'Conso_Target' AND Negoptim__Year__c = :year];
        Negoptim__Assortment_Detail__c assortmentDetailConso3 = [SELECT Negoptim__New_Client_WD_ClientBased__c, Negoptim__New_Client_LM__c FROM Negoptim__Assortment_Detail__c 
                                                       WHERE Negoptim__Product__c = :product1.Id AND Negoptim__Assortment_BU__r.Negoptim__BU_Target__c = :buConsoDrive.Id
                                                       AND Negoptim__Assortment_BU__r.RecordType.DeveloperName = 'Conso_Target' AND Negoptim__Year__c = :year];
        System.assertEquals(2, [SELECT COUNT() FROM Negoptim__Assortment_BU__c WHERE RecordType.DeveloperName = 'Conso_Target']);
        System.assertEquals(parentAssortmentDetail1.Id, assortmentDetailConso1.Negoptim__Ref_Client_Assortment__c);
        System.assertEquals(2, assortmentDetailConso1.Negoptim__New_Client_LM__c);
        System.assertEquals(2, assortmentDetailConso2.Negoptim__New_Client_LM__c);
        System.assertEquals(1, assortmentDetailConso3.Negoptim__New_Client_LM__c);
        Decimal weightedDistributionManual_HMSM = 50, weightedDistributionManual_Drive = 60;
        // case Conso HM/SM
        Decimal DV1 = 11.27*10/weightedDistributionManual_HMSM, DV2 = 33.23*20/weightedDistributionManual_HMSM;
        ////DV1 = DV1.setScale(1, System.RoundingMode.HALF_DOWN);
        Decimal DVTotal = DV1 + DV2;
        System.assertEquals(/*15.6*/ DVTotal.setScale(1, System.RoundingMode.HALF_DOWN), assortmentDetailConso1.Negoptim__New_Client_WD_ClientBased__c);
        DV1 = 22*10/weightedDistributionManual_HMSM;
        ////DV1 = DV1.setScale(1, System.RoundingMode.HALF_DOWN);
        DV2 = 88*20/weightedDistributionManual_HMSM;
        DVTotal = DV1 + DV2;
        System.assertEquals(DVTotal.setScale(1, System.RoundingMode.HALF_DOWN), assortmentDetailConso2.Negoptim__New_Client_WD_ClientBased__c);
        // case Conso Drive
        DV1 = 6*30/weightedDistributionManual_Drive;
        System.assertEquals(DV1.setScale(1, System.RoundingMode.HALF_DOWN), assortmentDetailConso3.Negoptim__New_Client_WD_ClientBased__c);
        System.assertEquals(Date.newInstance(year, month, Date.today().day()), assortmentDetailConso1.Negoptim__Movement_Date__c);
        assortmentDetail5 = [SELECT Id, Negoptim__WD_Conso__c FROM Negoptim__Assortment_Detail__c WHERE Id = :assortmentDetail5.Id];
        System.assertEquals(true, assortmentDetail5.Negoptim__WD_Conso__c);
    }
        
    @isTest static void case1_consolidate_simulation() {
        init();
        Test.startTest();
        // insert parent assortment Conso
        Negoptim__Assortment_BU__c parentAssortmentConsoHMSM = TestDataFactoryExt.createAssortmentBU(false, masterBU, buConsoHMSM, department);
        parentAssortmentConsoHMSM.RecordTypeId = TestDataFactoryExt.assortmentRTIds.get('Conso_Simulation');
        parentAssortmentConsoHMSM.Negoptim__Ass_BDate__c = Date.newInstance(year - 1, 1, 1);
        parentAssortmentConsoHMSM.Negoptim__Ass_EDate__c = Date.newInstance(year - 1, 12, 31);
        parentAssortmentConsoHMSM.Negoptim__Year__c = Integer.valueOf(year - 1);
        parentAssortmentConsoHMSM.Negoptim__Assortment_type__c = 'Out';
        parentAssortmentConsoHMSM.Negoptim__Status__c = 'Validated';
        // insert assortment_BU
        Negoptim__Assortment_BU__c assortmentBU1 = TestDataFactoryExt.createAssortmentBU(false, masterBU, buBannerHM, department);
        assortmentBU1.RecordTypeId = TestDataFactoryExt.assortmentRTIds.get('Simulation');
        assortmentBU1.Negoptim__Status__c = 'Validated';
        assortmentBU1.Negoptim__Assortment_type__c = 'In';
        assortmentBU1.Negoptim__Target_Simulation__c = true;
        Negoptim__Assortment_BU__c assortmentBU2 = TestDataFactoryExt.createAssortmentBU(false, masterBU, buBannerSM, department);
        assortmentBU2.RecordTypeId = TestDataFactoryExt.assortmentRTIds.get('Simulation');
        assortmentBU2.Negoptim__Status__c = 'Validated';
        assortmentBU2.Negoptim__Assortment_type__c = 'In';
        assortmentBU2.Negoptim__Target_Simulation__c = true;
        Negoptim__Assortment_BU__c assortmentBU3 = TestDataFactoryExt.createAssortmentBU(false, masterBU, buBannerDrive, department);
        assortmentBU3.RecordTypeId = TestDataFactoryExt.assortmentRTIds.get('Simulation');
        assortmentBU3.Negoptim__Status__c = 'Validated';
        assortmentBU3.Negoptim__Assortment_type__c = 'In';
        insert new List<Negoptim__Assortment_BU__c>{parentAssortmentConsoHMSM,assortmentBU1,assortmentBU2,assortmentBU3};
        // insert parent Assortment_Detail__c
        Negoptim__Assortment_Detail__c parentAssortmentDetail1 = TestDataFactoryExt.createAssortmentDetail(false, parentAssortmentConsoHMSM.Id, product1, null);
        parentAssortmentDetail1.Negoptim__Status__c = 'Validated';
        parentAssortmentDetail1.Negoptim__Movement_Date__c = Date.newInstance(year - 1, month, Date.today().day());
        parentAssortmentDetail1.Negoptim__Record_date__c = Date.newInstance(year - 1, month, Date.today().day());
        // insert Assortment_Detail__c
        Negoptim__Assortment_Detail__c assortmentDetail1 = TestDataFactoryExt.createAssortmentDetail(false, assortmentBU1.Id, product1, null);
        assortmentDetail1.Negoptim__Status__c = 'Validated';
        assortmentDetail1.Negoptim__Client_Status__c = 'New';
        assortmentDetail1.Negoptim__New_Client_WD_ClientBased__c = 11.27;
        assortmentDetail1.Negoptim__New_Client_WD_MarketBased__c = 11.27;
        assortmentDetail1.Negoptim__WD_Conso__c = false;
        assortmentDetail1.Negoptim__Movement_Date__c = Date.newInstance(year - 1, month, Date.today().day());
        Negoptim__Assortment_Detail__c assortmentDetail2 = TestDataFactoryExt.createAssortmentDetail(false, assortmentBU1.Id, product2, null);
        assortmentDetail2.Negoptim__Status__c = 'Validated';
        assortmentDetail2.Negoptim__Client_Status__c = 'New';
        assortmentDetail2.Negoptim__New_Client_WD_ClientBased__c = 22;
        assortmentDetail2.Negoptim__WD_Conso__c = false;
        
        Negoptim__Assortment_Detail__c assortmentDetail3 = TestDataFactoryExt.createAssortmentDetail(false, assortmentBU2.Id, product1, null);
        assortmentDetail3.Negoptim__Status__c = 'Validated';
        assortmentDetail3.Negoptim__Client_Status__c = 'New';
        assortmentDetail3.Negoptim__New_Client_WD_ClientBased__c = 33.23;
        assortmentDetail3.Negoptim__New_Client_WD_MarketBased__c = 33.23;
        assortmentDetail3.Negoptim__WD_Conso__c = false;
        assortmentDetail3.Negoptim__Movement_Date__c = Date.newInstance(year, month, Date.today().day());
        Negoptim__Assortment_Detail__c assortmentDetail4 = TestDataFactoryExt.createAssortmentDetail(false, assortmentBU2.Id, product2, null);
        assortmentDetail4.Negoptim__Status__c = 'Validated';
        assortmentDetail4.Negoptim__Client_Status__c = 'New';
        assortmentDetail4.Negoptim__New_Client_WD_ClientBased__c = 88;
        assortmentDetail4.Negoptim__WD_Conso__c = false;
        
        Negoptim__Assortment_Detail__c assortmentDetail5 = TestDataFactoryExt.createAssortmentDetail(false, assortmentBU3.Id, product1, null);
        assortmentDetail5.Negoptim__Status__c = 'Validated';
        assortmentDetail5.Negoptim__Client_Status__c = 'New';
        assortmentDetail5.Negoptim__New_Client_WD_ClientBased__c = 6;
        assortmentDetail5.Negoptim__WD_Conso__c = false;
        Negoptim__Assortment_Detail__c assortmentDetail6 = TestDataFactoryExt.createAssortmentDetail(false, assortmentBU3.Id, product2, null);
        assortmentDetail6.Negoptim__Status__c = 'Validated';
        assortmentDetail6.Negoptim__Client_Status__c = 'New';
        assortmentDetail6.Negoptim__New_Client_WD_ClientBased__c = 7;
        assortmentDetail6.Negoptim__WD_Conso__c = false;
        insert new List<Negoptim__Assortment_Detail__c>{parentAssortmentDetail1,assortmentDetail1,assortmentDetail2,assortmentDetail3,assortmentDetail4,assortmentDetail5,assortmentDetail6};
        
        // case Status='Request for Approval' and Last_History.Status='Validated'
        assortmentDetail1.Negoptim__New_Client_WD_MarketBased__c = 0;
        assortmentDetail3.Negoptim__New_Client_WD_MarketBased__c = 0;
        update new List<Negoptim__Assortment_Detail__c>{assortmentDetail1,assortmentDetail3};
        assortmentDetail1.Negoptim__Status__c = 'Request for Approval';
        assortmentDetail3.Negoptim__Status__c = 'Request for Approval';
        update new List<Negoptim__Assortment_Detail__c>{assortmentDetail1,assortmentDetail3};
        
        Database.executeBatch(new ConsolidateAssortmentBatchExt('ConsolidateAssortmentBatchExtTest', null, new Set<Id>{masterBU.Id}, new Set<Id>{department.Id},
                                                             new Set<Id>{product1.Id,product2.Id}, new Set<Integer>{year}));
        Test.stopTest();
        Negoptim__Assortment_Detail__c assortmentDetailConso1 = [SELECT Negoptim__New_Client_WD_ClientBased__c, Negoptim__Ref_Client_Assortment__c, Negoptim__Movement_Date__c, Negoptim__New_Client_LM__c FROM Negoptim__Assortment_Detail__c
                                                       WHERE Negoptim__Product__c = :product1.Id AND Negoptim__Assortment_BU__r.Negoptim__BU_Target__c = :buConsoHMSM.Id
                                                       AND Negoptim__Assortment_BU__r.RecordType.DeveloperName = 'Conso_Simulation' AND Negoptim__Year__c = :year];
        Negoptim__Assortment_Detail__c assortmentDetailConso2 = [SELECT Negoptim__New_Client_WD_ClientBased__c, Negoptim__New_Client_LM__c FROM Negoptim__Assortment_Detail__c
                                                       WHERE Negoptim__Product__c = :product2.Id AND Negoptim__Assortment_BU__r.Negoptim__BU_Target__c = :buConsoHMSM.Id
                                                       AND Negoptim__Assortment_BU__r.RecordType.DeveloperName = 'Conso_Simulation' AND Negoptim__Year__c = :year];
        Negoptim__Assortment_Detail__c assortmentDetailConso3 = [SELECT Negoptim__New_Client_WD_ClientBased__c, Negoptim__New_Client_LM__c FROM Negoptim__Assortment_Detail__c 
                                                       WHERE Negoptim__Product__c = :product1.Id AND Negoptim__Assortment_BU__r.Negoptim__BU_Target__c = :buConsoDrive.Id
                                                       AND Negoptim__Assortment_BU__r.RecordType.DeveloperName = 'Conso_Simulation' AND Negoptim__Year__c = :year];
        System.assertEquals(3, [SELECT COUNT() FROM Negoptim__Assortment_BU__c WHERE RecordType.DeveloperName = 'Conso_Simulation']);
        System.assertEquals(parentAssortmentDetail1.Id, assortmentDetailConso1.Negoptim__Ref_Client_Assortment__c);
        System.assertEquals(2, assortmentDetailConso1.Negoptim__New_Client_LM__c);
        System.assertEquals(2, assortmentDetailConso2.Negoptim__New_Client_LM__c);
        System.assertEquals(1, assortmentDetailConso3.Negoptim__New_Client_LM__c);
        Decimal weightedDistributionManual_HMSM = 50, weightedDistributionManual_Drive = 60;
        // case Conso HM/SM
        Decimal DV1 = 11.27*10/weightedDistributionManual_HMSM, DV2 = 33.23*20/weightedDistributionManual_HMSM;
        Decimal DVTotal = DV1 + DV2;
        System.assertEquals(/*15.6*/ DVTotal.setScale(1, System.RoundingMode.HALF_DOWN), assortmentDetailConso1.Negoptim__New_Client_WD_ClientBased__c);
        DV1 = 22*10/weightedDistributionManual_HMSM;
        DV2 = 88*20/weightedDistributionManual_HMSM;
        DVTotal = DV1 + DV2;
        System.assertEquals(DVTotal.setScale(1, System.RoundingMode.HALF_DOWN), assortmentDetailConso2.Negoptim__New_Client_WD_ClientBased__c);
        // case Conso Drive
        DV1 = 6*30/weightedDistributionManual_Drive;
        System.assertEquals(DV1.setScale(1, System.RoundingMode.HALF_DOWN), assortmentDetailConso3.Negoptim__New_Client_WD_ClientBased__c);
        System.assertEquals(Date.newInstance(year, month, Date.today().day()), assortmentDetailConso1.Negoptim__Movement_Date__c);
        assortmentDetail5 = [SELECT Id, Negoptim__WD_Conso__c FROM Negoptim__Assortment_Detail__c WHERE Id = :assortmentDetail5.Id];
        System.assertEquals(true, assortmentDetail5.Negoptim__WD_Conso__c);
    }
    
    @isTest static void case2_reset() {
        init();
        Test.startTest();
        // insert assortment_BU
        Negoptim__Assortment_BU__c assortmentBU1 = TestDataFactoryExt.createAssortmentBU(false, masterBU, buBannerHM, department);
        assortmentBU1.Negoptim__Status__c = 'Validated';
        Negoptim__Assortment_BU__c assortmentBU2 = TestDataFactoryExt.createAssortmentBU(false, masterBU, buBannerSM, department);
        assortmentBU2.Negoptim__Status__c = 'Validated';
        Negoptim__Assortment_BU__c assortmentBU3 = TestDataFactoryExt.createAssortmentBU(false, masterBU, buBannerDrive, department);
        assortmentBU3.Negoptim__Status__c = 'Validated';
        // insert assortment_BU Conso
        Negoptim__Assortment_BU__c assortmentBUConso1 = TestDataFactoryExt.createAssortmentBU(false, masterBU, buConsoHMSM, department);
        assortmentBUConso1.RecordTypeId = Negoptim.NegoptimHelper.getObjectRecordTypeId(Negoptim__Assortment_BU__c.SObjectType, 'Conso');
        assortmentBUConso1.Negoptim__Status__c = 'Validated';
        Negoptim__Assortment_BU__c assortmentBUConso2 = TestDataFactoryExt.createAssortmentBU(false, masterBU, buConsoDrive, department);
        assortmentBUConso2.RecordTypeId = Negoptim.NegoptimHelper.getObjectRecordTypeId(Negoptim__Assortment_BU__c.SObjectType, 'Conso');
        assortmentBUConso2.Negoptim__Status__c = 'Validated';
        insert new List<Negoptim__Assortment_BU__c>{assortmentBU1,assortmentBU2,assortmentBU3,assortmentBUConso1,assortmentBUConso2};
       
        // insert Assortment_Detail__c Linked to HMSM
        Negoptim__Assortment_Detail__c assortmentDetail1 = TestDataFactoryExt.createAssortmentDetail(false, assortmentBU1.Id, product1, null);
        assortmentDetail1.Negoptim__Status__c = 'Validated';
        assortmentDetail1.Negoptim__Client_Status__c = 'New';
        assortmentDetail1.Negoptim__New_Client_WD_ClientBased__c = 11;
        assortmentDetail1.Negoptim__WD_Conso__c = true;
        assortmentDetail1.Negoptim__Movement_Date__c = Date.newInstance(year - 1, month, Date.today().day());
        // insert Assortment_Detail__c Linked to HMSM
        Negoptim__Assortment_Detail__c assortmentDetail2 = TestDataFactoryExt.createAssortmentDetail(false, assortmentBU2.Id, product1, null);
        assortmentDetail2.Negoptim__Status__c = 'Validated';
        assortmentDetail2.Negoptim__Client_Status__c = 'New';
        assortmentDetail2.Negoptim__New_Client_WD_ClientBased__c = 33;
        assortmentDetail2.Negoptim__WD_Conso__c = true;
        assortmentDetail2.Negoptim__Movement_Date__c = Date.newInstance(year + 1, month, Date.today().day());
        // insert Assortment_Detail__c Linked to Drive
        Negoptim__Assortment_Detail__c assortmentDetail3 = TestDataFactoryExt.createAssortmentDetail(false, assortmentBU3.Id, product1, null);
        assortmentDetail3.Negoptim__Status__c = 'Validated';
        assortmentDetail3.Negoptim__Client_Status__c = 'New';
        assortmentDetail3.Negoptim__New_Client_WD_ClientBased__c = 6;
        assortmentDetail3.Negoptim__WD_Conso__c = true;
        // insert Assortment_Detail__c Conso Linked to HMSM
        Negoptim__Assortment_Detail__c assortmentDetailConsoHMSM = TestDataFactoryExt.createAssortmentDetail(false, assortmentBUConso1.Id, product1, null);
        assortmentDetailConsoHMSM.Negoptim__Status__c = 'Validated';
        assortmentDetailConsoHMSM.Negoptim__Client_Status__c = 'New';
        assortmentDetailConsoHMSM.Negoptim__New_Client_WD_ClientBased__c = 44;
        assortmentDetailConsoHMSM.Negoptim__Movement_Date__c = Date.newInstance(year + 1, month, Date.today().day());
        // insert Assortment_Detail__c Conso inked to Drive
        Negoptim__Assortment_Detail__c assortmentDetailConsoDrive = TestDataFactoryExt.createAssortmentDetail(false, assortmentBUConso2.Id, product1, null);
        assortmentDetailConsoDrive.Negoptim__Status__c = 'Validated';
        assortmentDetailConsoDrive.Negoptim__Client_Status__c = 'New';
        assortmentDetailConsoDrive.Negoptim__New_Client_WD_ClientBased__c = 6;
        insert new List<Negoptim__Assortment_Detail__c>{assortmentDetail1,assortmentDetail2,assortmentDetail3,assortmentDetailConsoHMSM,assortmentDetailConsoDrive};
        // update Assortment_Detail__c Linked to HMSM
        assortmentDetail1.Negoptim__Status__c = null;
        assortmentDetail2.Negoptim__New_Client_WD_ClientBased__c = 12;
        assortmentDetail3.Negoptim__New_Client_WD_ClientBased__c = 7;
        update new List<Negoptim__Assortment_Detail__c>{assortmentDetail1, assortmentDetail2, assortmentDetail3};
        Test.stopTest();
        assortmentDetailConsoHMSM = [SELECT Negoptim__New_Client_WD_ClientBased__c, Negoptim__Movement_Date__c FROM Negoptim__Assortment_Detail__c WHERE Id = :assortmentDetailConsoHMSM.Id];
        assortmentDetailConsoDrive = [SELECT Negoptim__New_Client_WD_ClientBased__c, Negoptim__Movement_Date__c FROM Negoptim__Assortment_Detail__c WHERE Id = :assortmentDetailConsoDrive.Id];
        Decimal weightedDistributionManual_HMSM = 50, weightedDistributionManual_Drive = 60;
        // case Conso HM/SM
        Decimal DV1 = 12*20/weightedDistributionManual_HMSM;
        System.assertEquals(DV1.setScale(1, System.RoundingMode.HALF_DOWN), assortmentDetailConsoHMSM.Negoptim__New_Client_WD_ClientBased__c);
        // case Conso Drive
        DV1 = 7*30/weightedDistributionManual_Drive;
        System.assertEquals(DV1.setScale(1, System.RoundingMode.HALF_DOWN), assortmentDetailConsoDrive.Negoptim__New_Client_WD_ClientBased__c);
        assortmentDetail1 = [SELECT Negoptim__WD_Conso__c FROM Negoptim__Assortment_Detail__c WHERE Id = :assortmentDetail1.Id];
        System.assertEquals(false, assortmentDetail1.Negoptim__WD_Conso__c);
        System.assertEquals(Date.newInstance(year + 1, month, Date.today().day()), assortmentDetailConsoHMSM.Negoptim__Movement_Date__c);
        System.assertEquals(Date.today(), assortmentDetailConsoDrive.Negoptim__Movement_Date__c);
    }
    
    @isTest static void case3_switch() {
        init();
        Test.startTest();
        // insert assortment_BU
        Negoptim__Assortment_BU__c assortmentBU1 = TestDataFactoryExt.createAssortmentBU(false, masterBU, buBannerHM, department);
        assortmentBU1.Negoptim__Status__c = 'Validated';
        /*Assortment_BU__c assortmentBU2 = TestDataFactoryExt.createAssortmentBU(false, masterBU, buBannerSM, department);
        assortmentBU2.Status__c = 'Validated';*/
        // insert assortment_BU Conso
        Negoptim__Assortment_BU__c assortmentBUConso1 = TestDataFactoryExt.createAssortmentBU(false, masterBU, buConsoHMSM, department);
        assortmentBUConso1.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Negoptim__Assortment_BU__c.SObjectType, 'Conso');
        assortmentBUConso1.Negoptim__Status__c = 'Validated';
        insert new List<Negoptim__Assortment_BU__c>{assortmentBU1,assortmentBUConso1};
        // insert Assortment_Detail__c Linked to HMSM
        Negoptim__Assortment_Detail__c assortmentDetail1 = TestDataFactoryExt.createAssortmentDetail(false, assortmentBU1.Id, product1, null);
        assortmentDetail1.Negoptim__Status__c = 'Validated';
        assortmentDetail1.Negoptim__Client_Status__c = 'New';
        assortmentDetail1.Negoptim__New_Client_WD_ClientBased__c = 11;
        assortmentDetail1.Negoptim__WD_Conso__c = true;
        // insert Assortment_Detail__c Linked to HMSM
        /*Assortment_Detail__c assortmentDetail2 = TestDataFactoryExt.createAssortmentDetail(false, assortmentBU2.Id, product1, null);
        assortmentDetail2.Status__c = 'Validated';
        assortmentDetail2.Client_Status__c = 'New';
        assortmentDetail2.New_Client_WD_ClientBased__c = 33;
        assortmentDetail2.WD_Conso__c = true;*/
        // insert Assortment_Detail__c Conso Linked to HMSM
        Negoptim__Assortment_Detail__c assortmentDetailConsoHMSM = TestDataFactoryExt.createAssortmentDetail(false, assortmentBUConso1.Id, product1, null);
        assortmentDetailConsoHMSM.Negoptim__Status__c = 'Validated';
        assortmentDetailConsoHMSM.Negoptim__Client_Status__c = 'New';
        assortmentDetailConsoHMSM.Negoptim__New_Client_WD_ClientBased__c = 44;
        insert new List<Negoptim__Assortment_Detail__c>{assortmentDetail1,assortmentDetailConsoHMSM};
        // switch product
        Product2 newProduct = TestDataFactoryExt.createProduct(false, section.Id, null);
        newProduct.Name = 'new Product';
        newProduct.Negoptim__Ext_id__c = '3';
        insert newProduct;
        assortmentDetail1.Negoptim__Product__c = newProduct.Id;
        assortmentDetail1.Negoptim__New_Client_WD_ClientBased__c = 22;
        update assortmentDetail1;
        /*assortmentDetail1.Status__c = 'In preparation';
        update assortmentDetail1;
        assortmentDetail1.Status__c = 'Validated';
        update assortmentDetail1;*/
        Test.stopTest();
        // Validation
        assortmentDetailConsoHMSM = [SELECT Negoptim__New_Client_WD_ClientBased__c FROM Negoptim__Assortment_Detail__c WHERE Id = :assortmentDetailConsoHMSM.Id];
        Decimal weightedDistributionManual_HMSM = 50, weightedDistributionManual_Drive = 60;
        // case Conso HM/SM
        Decimal DV1 = 33*20/weightedDistributionManual_HMSM, DV2 = 11*10/weightedDistributionManual_HMSM; // DV2 : ASD1 PRV Validated + Substitute
        ////DV1 = DV1.setScale(1, System.RoundingMode.HALF_DOWN);
        Decimal DVTotal = DV2;
        System.assertEquals(DVTotal.setScale(1, System.RoundingMode.HALF_DOWN), assortmentDetailConsoHMSM.Negoptim__New_Client_WD_ClientBased__c);
        /*Assortment_Detail__c assortmentDetailConsoHMSM_switch = [SELECT New_Client_WD_ClientBased__c FROM Assortment_Detail__c
                                                                 WHERE Product__c = :newProduct.Id
                                                                 AND Assortment_BU__r.RecordType.DeveloperName = 'Conso'];
        DV1 = 22*10/weightedDistributionManual_HMSM;
        System.assertEquals(DV1.setScale(1, System.RoundingMode.HALF_DOWN), assortmentDetailConsoHMSM_switch.New_Client_WD_ClientBased__c);*/
    }
}