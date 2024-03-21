/**
 * @author ULiT
 * @Description Class used in unit test to create common data
 * @date 7/9/2023
 **/
@isTest
public class TestDataFactoryExt {
    
    private static Integer randomNumber;
    public static final Integer year = System.Today().year();
    public static final String currencyIsoCode = Negoptim.NegoptimHelper.getCorporateCurrency();
    public static final Map<String, Id> assortmentRTIds = Negoptim.NegoptimHelper.getObjectRecordTypeMapIds(Negoptim__Assortment_BU__c.SObjectType);
    public static final Map<String, Id> buRTIds = Negoptim.NegoptimHelper.getObjectRecordTypeMapIds(Negoptim__Orga_BU__c.SObjectType);
    
    // Method to increment randomNumber
    private static Integer getRandomNumber() {
        if (randomNumber == null)
            randomNumber = (Integer)(Math.random()*9999);
        return randomNumber++;
    }
    /* BUSINESS UNIT */
    // Country List creation.
    public static Negoptim__Country_List__c createCountry(Boolean doInsert, String name, String code) {
        Negoptim__Country_List__c myCountry = new Negoptim__Country_List__c(Name = name, Negoptim__Country_Code__c = code);
        if (doInsert) insert myCountry;
        System.assert(true);
        return myCountry;
    }
    // Region creation.
    public static Negoptim__Orga_BU__c createBURegion(Boolean doInsert, String name) {
        Negoptim__Orga_BU__c region = new Negoptim__Orga_BU__c(Name = name, Negoptim__BU_Code__c = name, Negoptim__BU_ODate__c = date.newInstance(year, 1, 1), Negoptim__Status__c = 'Open',
                                                               Negoptim__Set_Assortment_Budget_BU_Source__c = true,
                                                               Negoptim__Set_Assortment_Budget_BU_Target__c = true,
                                                               Negoptim__Set_Assortment_Nego_BU_Source__c = true,
                                                               Negoptim__Set_Assortment_Nego_BU_Target__c = true,
                                                               Negoptim__Set_Assortment_Target_BU_Source__c = true,
                                                               Negoptim__Set_Assortment_Target_BU_Target__c = true,
                                                               Negoptim__Set_BU_List_Entity__c = true,
                                                               CurrencyIsoCode = currencyIsoCode);
        region.RecordTypeId = buRTIds.get('Region');
        if (doInsert) insert region;
        System.assert(true);
        return region;
    }
    // Country creation.
    public static Negoptim__Orga_BU__c createBUCountry(Boolean doInsert, Negoptim__Country_List__c c, Id regionId) {
        Negoptim__Orga_BU__c country = new Negoptim__Orga_BU__c(Name = c.Name, Negoptim__BU_Code__c = c.Negoptim__Country_Code__c + getRandomNumber(),
                                                                Negoptim__ISO_Country_Code__c = c.Negoptim__Country_Code__c,
                                                                Negoptim__Country__c = c.Name, Negoptim__Country_Zone_origin__c = regionId, Negoptim__Status__c = 'Open',
                                                                Negoptim__BU_ODate__c = date.newInstance(year, 1, 1),
                                                                Negoptim__Set_Assortment_Budget_BU_Source__c = true,
                                                                Negoptim__Set_Assortment_Budget_BU_Target__c = true,
                                                                Negoptim__Set_Assortment_Nego_BU_Source__c = true,
                                                                Negoptim__Set_Assortment_Nego_BU_Target__c = true,
                                                                Negoptim__Set_Assortment_Target_BU_Source__c = true,
                                                                Negoptim__Set_Assortment_Target_BU_Target__c = true,
                                                                Negoptim__Set_BU_List_Entity__c = true,
                                                                CurrencyIsoCode = currencyIsoCode);
        country.RecordTypeId = buRTIds.get('Country');
        if (doInsert) insert country;
        System.assert(true);
        return country;
    }
    // Banner creation.
    public static Negoptim__Orga_BU__c createBUBanner(Boolean doInsert, Negoptim__Orga_BU__c country) {
        String rdm = String.valueOf(getRandomNumber());
        Negoptim__Orga_BU__c banner = new Negoptim__Orga_BU__c(Name = 'Banner ' + rdm, Negoptim__BU_Code__c = 'B' + rdm, Negoptim__Country__c = country.Name, Negoptim__Country_origin__c = country.Id,
                                                               Negoptim__Status__c = 'Open', Negoptim__Format_Origin__c = 'HM', Negoptim__BU_ODate__c = date.newInstance(year, 1, 1),
                                                               Negoptim__Set_Assortment_Budget_BU_Source__c = true,
                                                               Negoptim__Set_Assortment_Budget_BU_Target__c = true,
                                                               Negoptim__Set_Assortment_Nego_BU_Source__c = true,
                                                               Negoptim__Set_Assortment_Nego_BU_Target__c = true,
                                                               Negoptim__Set_Assortment_Target_BU_Source__c = true,
                                                               Negoptim__Set_Assortment_Target_BU_Target__c = true,
                                                               Negoptim__Set_BU_List_Entity__c = true,
                                                               CurrencyIsoCode = currencyIsoCode);
        banner.RecordTypeId = buRTIds.get('Banner');
        if (doInsert) insert banner;
        System.assert(true);
        return banner;
    }
    // Channel creation.
    public static Negoptim__Orga_BU__c createBUChannel(Boolean doInsert, Negoptim__Orga_BU__c country) {
        String rdm = String.valueOf(getRandomNumber());
        Negoptim__Orga_BU__c channel = new Negoptim__Orga_BU__c(Name = 'Channel ' + rdm, Negoptim__BU_Code__c = 'B' + rdm, Negoptim__Country__c = country.Name, Negoptim__Country_origin__c = country.Id,
                                                                Negoptim__Status__c = 'Open', Negoptim__Format_Origin__c = 'HM', Negoptim__BU_ODate__c = date.newInstance(year, 1, 1),
                                                                Negoptim__Set_Assortment_Budget_BU_Source__c = true,
                                                                Negoptim__Set_Assortment_Budget_BU_Target__c = true,
                                                                Negoptim__Set_Assortment_Nego_BU_Source__c = true,
                                                                Negoptim__Set_Assortment_Nego_BU_Target__c = true,
                                                                Negoptim__Set_Assortment_Target_BU_Source__c = true,
                                                                Negoptim__Set_Assortment_Target_BU_Target__c = true,
                                                                Negoptim__Set_BU_List_Entity__c = true,
                                                                CurrencyIsoCode = currencyIsoCode);
        channel.RecordTypeId = buRTIds.get('Channel');
        if (doInsert) insert channel;
        System.assert(true);
        return channel;
    }
    // Assortment Cluster creation.
    public static Negoptim__Orga_BU__c createBUAssortCluster(Boolean doInsert, Id countryId, String strat) {
    	String rdm = String.valueOf(getRandomNumber());
        Negoptim__Orga_BU__c assort = new Negoptim__Orga_BU__c(Name = 'Assort Cluster' + rdm, Negoptim__BU_Code__c = rdm, Negoptim__Country_origin__c = countryId,
                                           Negoptim__Status__c = 'Open', Negoptim__Assortment_Strat__c = strat,
                                           Negoptim__Set_Assortment_Budget_BU_Source__c = true,
                                           Negoptim__Set_Assortment_Budget_BU_Target__c = true,
                                           Negoptim__Set_Assortment_Nego_BU_Source__c = true,
                                           Negoptim__Set_Assortment_Nego_BU_Target__c = true,
                                           Negoptim__Set_Assortment_Target_BU_Source__c = true,
                                           Negoptim__Set_Assortment_Target_BU_Target__c = true,
                                           Negoptim__Set_BU_List_Entity__c = true);
        assort.RecordTypeId = buRTIds.get('Assortment_Cluster');
        if (doInsert) insert assort;
        System.assert(true);
        return assort;
    }
    /* SUPPLIER + NEGOSCOPE */
    // Supplier creation.
    public static Negoptim__Supplier__c createSupplier(Boolean doInsert, Negoptim__Orga_BU__c country, Boolean withNS) {
        String rdm = String.valueOf(getRandomNumber());
        Negoptim__Supplier__c supplier = new Negoptim__Supplier__c(Name = 'SUP ' + rdm, Negoptim__Code__c = rdm,
                                                                   Negoptim__Country_origin__c = country.Id,
                                                                   Negoptim__Acc_Country__c = country.Name,
                                                                   Negoptim__Status__c = 'Active',
                                                                   CurrencyIsoCode = currencyIsoCode);
        if (doInsert) insert supplier;
        System.assert(true);
        return supplier;
    }
    
   	/* HIERARCHY ELEMENT + BRAND + PRODUCT + SELL IN */
    // Department creation.
    public static Negoptim__Orga_HE__c createDepartment(Boolean doInsert, Id parentId) {
        String rdm = String.valueOf(getRandomNumber());
        Negoptim__Orga_HE__c department = new Negoptim__Orga_HE__c(Name = 'DPT ' + rdm, Negoptim__Elt_Code__c = 'D' + rdm, Negoptim__Parent_Element__c = parentId, Negoptim__Level__c = 1,
                                                                   Negoptim__Set_Assortment_nego_level__c = true, Negoptim__Status_BDate__c = date.newInstance(year, 1, 1), Negoptim__Status__c = 'Active', Negoptim__Set_Assortment_Cluster_level__c = true);
        if (doInsert) insert department;
        System.assert(true);
        return department;
    }
    // Section creation.
    public static Negoptim__Orga_HE__c createSection(Boolean doInsert, Id parentId) {
        String rdm = String.valueOf(getRandomNumber());
        Negoptim__Orga_HE__c section = new Negoptim__Orga_HE__c(Name = 'SEC ' + rdm, Negoptim__Elt_Code__c = 'S' + rdm, Negoptim__Parent_Element__c = parentId, Negoptim__Level__c = 2,
                                                                Negoptim__Status_BDate__c = date.newInstance(year, 1, 1), Negoptim__Status__c = 'Active', Negoptim__Set_Product_link_level__c = true);
        if (doInsert) insert section;
        System.assert(true);
        return section;
    }
    
    
    /**
     * @description creates an Element Heirarchy Tree starting from the root
     * Note: the method executes (2 + depth) DMLs
     * @param depth the pepth of the tree
     * @param elementsPerLevel how many elements per level
     **/
    public static List<Negoptim__Orga_HE__c> createElementHierarchy(Integer depth, Integer elementsPerLevel) {
        Id rootId = Negoptim.NegoptimHelper.getRootIdByRT('Product');
        Negoptim__Orga_HE__c root = [SELECT Id, Negoptim__Level__c FROM Negoptim__Orga_HE__c WHERE Id = :rootId];
        Integer currentLevel = 1;
        List<Negoptim__Orga_HE__c> tempList = new List<Negoptim__Orga_HE__c>();
        List<Negoptim__Orga_HE__c> orgaHEList = new List<Negoptim__Orga_HE__c> {root};
            
            for (currentLevel = 1; currentLevel <= depth; currentLevel++) {
                for (Negoptim__Orga_HE__c parent : orgaHEList) {
                    if (parent.Negoptim__Level__c == currentLevel - 1) {
                        for (Integer index = 0; index < elementsPerLevel; index++) {
                            Negoptim__Orga_HE__c element = createDepartment(false, parent.Id);
                            element.Negoptim__Level__c = currentLevel;
                            element.Negoptim__Set_Product_link_level__c = true;
                            element.Negoptim__Set_Assortment_Cluster_Level__c = true;
                            tempList.add(element);
                        }
                    }
                }
                insert tempList;
                orgaHEList.addAll(tempList);
                tempList.clear();
            }
        return orgaHEList;
    }
    // Brand creation.
    public static Negoptim__Brand__c createBrand(Boolean doInsert, Id supplierId) {
        String rdm = String.valueOf(getRandomNumber());
        String name = 'BRAND ' + rdm;
        Negoptim__Brand__c brand = new Negoptim__Brand__c(Name = name, Negoptim__Brand_Owner__c = supplierId, Negoptim__Status_BDate__c = date.newInstance(year, 1, 1));
        if (doInsert) insert brand;
        System.assert(true);
        return brand;
    }
    // Product creation.
    public static Product2 createProduct(Boolean doInsert, Id sectionId, Id supplierId) {
        String rdm = String.valueOf(getRandomNumber());
        Product2 product = new Product2(Name = 'PRD ' + rdm, ProductCode = 'P' + rdm, Negoptim__Product_EAN__c = '10000' + rdm,
                                        Negoptim__Category__c = sectionId, Negoptim__Product_MasterSupplier__c = supplierId, IsActive = true,
                                        Negoptim__Ext_Id__c = '10000' + rdm + '_' + 'P' + rdm);
        if (doInsert) insert product;
        System.assert(true);
        return product;
    }
    
    // Create assortment BU with default record type = Nego
    public static Negoptim__Assortment_BU__c createAssortmentBU(Boolean doInsert, Negoptim__Orga_BU__c buSource, Negoptim__Orga_BU__c buTarget, Negoptim__Orga_HE__c category) {
        String rdm = String.valueOf(getRandomNumber());
        Negoptim__Assortment_BU__c assortment = new Negoptim__Assortment_BU__c(Name = rdm, Negoptim__Assortment_type__c = 'Out', Negoptim__BU_Source__c = buSource.Id, Negoptim__BU_Target__c = buTarget.Id,
                                                                               Negoptim__Orga_HE__c = category.Id, Negoptim__Assortment__c = 'Deal', Negoptim__Status__c = 'Open (in bulding process)',
                                                                               CurrencyIsoCode = currencyIsoCode, Negoptim__Ass_BDate__c = Date.newInstance(year, 1, 1),
                                                                               Negoptim__Ass_EDate__c = Date.newInstance(year, 12, 31), Negoptim__Year__c = year);
        assortment.RecordTypeId = assortmentRTIds.get('Nego');
        if (doInsert) {
            insert assortment;
        }
        return assortment;
    }
    
    // Assortment Detail creation.
    public static Negoptim__Assortment_Detail__c createAssortmentDetail(Boolean doInsert, Id assortmentBUId, Product2 product, Id clusterId) {
        Negoptim__Assortment_Detail__c assortmentDetail = new Negoptim__Assortment_Detail__c(Negoptim__Assortment_BU__c = assortmentBUId, Negoptim__Product__c = product.Id, Negoptim__Category__c = product.Negoptim__Category__c,
                                                                                             Negoptim__Movement_Date__c = Date.today(), Negoptim__Record_date__c = Date.today(), Negoptim__Client_Status__c = 'New',
                                                                                             Negoptim__Ass_BU_Cluster__c = clusterId, Negoptim__Status__c = 'In preparation');
        if (doInsert) Database.insert(assortmentDetail);
        System.assert(true);
        return assortmentDetail;
    }
}