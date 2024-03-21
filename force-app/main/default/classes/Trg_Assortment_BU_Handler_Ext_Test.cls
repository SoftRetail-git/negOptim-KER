@isTest
public class Trg_Assortment_BU_Handler_Ext_Test {
	static List<Negoptim__Orga_HE__c> heList1;
	static List<Negoptim__Orga_HE__c> heList2;
	private static Negoptim__Assortment_BU__c assortment1;
	private static Negoptim__Assortment_BU__c assortment2;
	private static Negoptim__Orga_BU__c buSource;
    private static Negoptim__Orga_BU__c buTarget;
    private static Negoptim__Orga_BU__c country;

	static void init() {
		Negoptim__Orga_BU__c region = TestDataFactoryExt.CreateBURegion(true, 'region');
		Negoptim__Country_List__c countryList = TestDataFactoryExt.createCountry(true, 'France', 'FR');
		country = TestDataFactoryExt.createBUCountry(true, countryList, region.Id);
		buSource = TestDataFactoryExt.createBUChannel(false, country);
        buSource.Negoptim__Format_Origin__c = null;
		buSource.Negoptim__IsMasterBU__c = true;
		buTarget = TestDataFactoryExt.createBUBanner(false, country);
        buTarget.Negoptim__Format_Origin__c = null;
		buTarget.Negoptim__Mission__c = 'Offer';
		buTarget.Negoptim__IsMasterBU__c = false;
		insert new List<Negoptim__Orga_BU__c> {buSource, buTarget};
		//init Orga HEs
		heList1 = TestDataFactoryExt.createElementHierarchy(4, 1);
		heList2 = TestDataFactoryExt.createElementHierarchy(4, 1);
		assortment1 = TestDataFactoryExt.createAssortmentBU(false, buSource, buTarget, heList1[1]);
		assortment2 = TestDataFactoryExt.createAssortmentBU(false, buSource, buTarget, heList2[1]);
		insert new List<Negoptim__Assortment_BU__c> {assortment1, assortment2};
          List<Negoptim__Assortment_BU__c> listbu = [SELECT Name FROM Negoptim__Assortment_BU__c ];
        system.debug(JSON.serialize(listbu));
	}
	@isTest
	static void case1_after_Update() {
		init();
		assortment1.SPKERCADELACVersionforcompilation__c = true;
        update assortment1;
		Test.startTest();
		assortment2.SPKERCADELACVersionforcompilation__c = true;
        update assortment2;
		test.stopTest();
        assortment1 = [SELECT Id, SPKERCADELACVersionforcompilation__c FROM Negoptim__Assortment_BU__c WHERE Id = :assortment1.Id];
		System.assertEquals(false, assortment1.SPKERCADELACVersionforcompilation__c);
	}

}