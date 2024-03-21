@IsTest
public class AssortmentManagementPanelCtrlTestExt {
    
    private static final Map<String, Id> assortmentRTIds = Negoptim.NegoptimHelper.getObjectRecordTypeMapIds(Negoptim__Assortment_BU__c.SObjectType);
    private static Id rootId;
    private static Negoptim__Supplier__c supplier;
    private static Negoptim__Orga_HE__c department;
    private static Negoptim__Orga_HE__c section;
    private static Negoptim__Orga_HE__c section2;
    private static Product2 product;
    private static Product2 product2;
    private static Negoptim__Orga_BU__c buSource;
    private static Negoptim__Orga_BU__c buTarget;
    private static Negoptim__Assortment_BU__c assortmentBU;
    private static Negoptim__Assortment_BU__c assortmentBUBudget;
    private static Negoptim__Orga_BU__c country;
    private static Negoptim__Assortment_Detail__c assortmentDetail;
    private	static List<Negoptim__Orga_HE__c> heList1;
	private static List<Negoptim__Orga_HE__c> heList2;
    
    static void init() {
        // Root element Id.
        rootId = Negoptim.NegoptimHelper.getRootIdByRT('Product');
        // Insert Country List.
        Negoptim__Country_List__c myCountry = TestDataFactoryExt.createCountry(true, 'FRANCE', 'FR');
        // Insert Region.
        Negoptim__Orga_BU__c region = TestDataFactoryExt.createBURegion(true, 'EU');
        // Insert Country.
        country = TestDataFactoryExt.createBUCountry(false, myCountry, region.Id);
        country.Negoptim__IsMasterBU__c = true;
        insert country;
        // Create Supplier
        supplier = TestDataFactoryExt.createSupplier(false, country, true);
        insert supplier;
        // create HEs
        department = TestDataFactoryExt.createDepartment(false, rootId);
        department.Negoptim__Set_Product_link_level__c = true;
        insert department;
        section = TestDataFactoryExt.createSection(true, department.Id);
        section2 = TestDataFactoryExt.createSection(true, department.Id);
        //create Brand 
        Negoptim__Brand__c brand = TestDataFactoryExt.createBrand(true, supplier.Id);
		Negoptim__Brand__c brand2 = TestDataFactoryExt.createBrand(false, supplier.Id);
        brand2.Negoptim__Brand_Parent__c = brand.Id;
        insert brand2;
        // create Source BU Channel
        buSource = TestDataFactoryExt.createBUChannel(false, country);
        buSource.Negoptim__IsMasterBU__c = true;
        buSource.Negoptim__Set_Assortment_Budget_BU_Source__c = true;
        buSource.Negoptim__Layer_Nego_Conso__c = true;
        // create Target BU Banner
        buTarget = TestDataFactoryExt.createBUBanner(false, country);
        buTarget.Name = 'HMSM';
        buTarget.Negoptim__Category__c = department.Id;
        buTarget.Negoptim__Set_Assortment_Budget_BU_Target__c = true;
        buTarget.Negoptim__IsMasterBU__c = true;
        buTarget.Negoptim__Layer_Nego_Conso__c = true;
        insert new List<Negoptim__Orga_BU__c>{buTarget, buSource};
        // insert assortment_BU
        assortmentBU = TestDataFactoryExt.createAssortmentBU(false, buSource, buTarget, department);
        assortmentBU.Negoptim__Status__c = 'Validated';
        assortmentBU.Negoptim__Year__c = System.today().year();
        assortmentBU.RecordTypeId = assortmentRTIds.get('Simulation');
        assortmentBU.Negoptim__Assortment_type__c = 'In';
        insert assortmentBU;
        assortmentBUBudget = TestDataFactoryExt.createAssortmentBU(false, buSource, buTarget, department);
        assortmentBUBudget.Negoptim__Year__c = System.today().year();
        assortmentBUBudget.RecordTypeId = assortmentRTIds.get('Budget');
        assortmentBUBudget.Negoptim__Assortment_type__c = 'In';
        insert assortmentBUBudget;
               
        //init Orga HEs
		heList1 = TestDataFactoryExt.createElementHierarchy(4, 1);
		heList2 = TestDataFactoryExt.createElementHierarchy(4, 1);
        // Create Product.
		List<Product2> products = new List<Product2>();
		for (Integer i = 0; i < 2; i++) {
            product = TestDataFactoryExt.createProduct(false, section.Id, supplier.Id);
            product.Negoptim__Brand__c = brand.Id;
            product.Negoptim__Category__c = department.Id;
			products.add(product);
            product2 = TestDataFactoryExt.createProduct(false, section2.Id, supplier.Id);
            product2.Negoptim__Brand__c = brand2.Id;
            product2.Negoptim__Category__c = department.Id;
			products.add(product2);
		}
		insert products;
        List<Negoptim__Assortment_Detail__c> assortmentDetailsList = new List<Negoptim__Assortment_Detail__c>();
		for (Product2 product : products) {
			assortmentDetailsList.add(TestDataFactoryExt.createAssortmentDetail(false, assortmentBUBudget.Id, product, null));
			assortmentDetailsList.add(TestDataFactoryExt.createAssortmentDetail(false, assortmentBU.Id, product, null));
		}
		insert assortmentDetailsList;
    }
    static testmethod void AssortmentManagementPanel() {
        init();
        AssortmentManagementPanelCtrlExt.FilterParameter filterParam = new AssortmentManagementPanelCtrlExt.FilterParameter('', 0, '');
        String dataSerialized = AssortmentManagementPanelCtrlExt.loadData(JSON.serialize(filterParam)); 
    }
}