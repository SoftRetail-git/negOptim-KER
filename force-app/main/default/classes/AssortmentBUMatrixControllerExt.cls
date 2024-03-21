/**
 * @author ULiT
 * @date 11/6/2018
 * @description Custom controller that uses the standard Assortment_BU__c controller
 * and includes the Assortment BU Matrix logic for the corresponding view.
 * It provides the following initial functionalities:
 * 1- Display all assortment details for all assortment head + Filter.
 * 2- Display the assorment details for a single assortment head + Filter.
 * 3- GOAL: Optimising the ASSORTMENT of PRODUCTS you plan to stock &
 * then ARRANGING those products on the shelves for MAXIMUM impact.
 **/

 public with sharing class AssortmentBUMatrixControllerExt extends NegoptimBaseController {

    private final Integer DEFAULT_PAGE_SIZE = 50;
    private Boolean refreshData = false;
    private Boolean isFirstLoad = true;
    private Boolean isTargetMatrix = false;
    private Integer nbClientClusterFields = Negoptim.NegoptimHelper.getNbClientClusterFields();
    private String detailRecordType = CommonConstants.RT_ASSORTMENT_DETAIL_REGULAR;
    private Id ASD_Higer_Level_Packagin_RT_Id = Negoptim.NegoptimHelper.getObjectRecordTypeId(Negoptim__Assortment_Detail__c.SObjectType, CommonConstants.RT_ASSORTMENT_DETAIL_HIGHER_LEVEL_PACKAGING);

    // grid settings name
    public String assortmentMatrixGridLayout {get; set;}
     // grid settings name
    public Integer categIndex {get; set;}
    // product color indicators for introduction / stop dates
    public String INNO_INTRO_DATE_LESS_N {
        get {
            return NegoptimHelper.INNO_INTRO_DATE_LESS_N;
        }
    }
    public String INNO_INTRO_DATE_GREATER_N {
        get {
            return NegoptimHelper.INNO_INTRO_DATE_GREATER_N;
        }
    }
    public String STOP_DATE_LESS_N {
        get {
            return NegoptimHelper.STOP_DATE_LESS_N;
        }
    }
    public String STOP_DATE_GREATER_N {
        get {
            return NegoptimHelper.STOP_DATE_GREATER_N;
        }
    }
    // map of active statement Taxes
    public Map<Integer, StatementWrapper> statementActiveTaxesMap {get; private set;}
    // map of active statement Price Discounts
    public Map<Integer, StatementWrapper> statementActiveDiscountsMap {get; private set;}
    //map of active contract Taxes
    public Map<Integer, StatementWrapper> contractActiveTaxesMap {get; private set;}
    // map of active contract Price Discounts
    public Map<Integer, StatementWrapper> contractActiveDiscountsMap {get; private set;}

    public String statementActiveTaxDisplayOrder_str {
        get {
            return '[-' + String.join(new List<Integer>(this.statementActiveTaxesMap.keySet()), '-') + '-]';
        }
        private set;
    }
    public String statementActiveDiscountDisplayOrder_str {
        get {
            return '[-' + String.join(new List<Integer>(this.statementActiveDiscountsMap.keySet()), '-') + '-]';
        }
    }
    public String contractActiveTaxDisplayOrder_str {
        get {
            return '[-' + String.join(new List<Integer>(this.contractActiveTaxesMap.keySet()), '-') + '-]';
        }
        private set;
    }
    public String contractActiveDiscountDisplayOrder_str {
        get {
            return '[-' + String.join(new List<Integer>(this.contractActiveDiscountsMap.keySet()), '-') + '-]';
        }
    }
    public GridSettingsManager gridSettingsManager {get; set;}
    private List<String> dynamicFields;
    public String assortmentMatrixTargetGridLayout {get; set;}
    public String gridFields_serialized {get; set;}
    public List<GridSettingsManager.FieldWrapper> displayedFields {get; set;}
    public List<GridSettingsManager.FieldWrapper> totalFields {get; set;} // total fields ordered as loaded
    public String totalFields_serialized {get; set;}
    public String fieldsToCountList_serialized {get; set;}
    public String fieldsToSumList_serialized {get; set;}
    public String formulasFieldsList_serialized {get; set;}
    public String picklistValuesMap_serialized {get; set;}

    public String recordId {get; set;} // Assortment BU Id: used in excel methods
    private String assortmentBUName; // Assortment BU Name: used in excel methods
    public Boolean readOnly {get; set;}
    // the number of ASD that have status__c = In preparation to control when the validate button is disabled
    public Integer nbASDinPreparation {get; set;}
    public Integer nbASDRequestApproval {get; set;}

    public List<SelectOption> clientStatusesPickList {get; set;}

    Map<Id, CategoryWrapper> categoryWrapperMap {get; set;} // categoryId => all assortment details under that category

    public Product2 product {get;set;} // to filter categories -- todo remove when we use categoryLookup
    public Boolean isStopProducts {get; set;}
    public String productReferenceType {get; set;}
    public String productSearch {get; set;} // search key word to filter products
    public String clientStatus {get; set;} // filter to client_status
    public Boolean hasDetails {get; set;} // indicates if the assortment bu has details

    public Boolean popupGenerateExcel {get; set;}
    public String emailTo {get; set;}
    public String emailCc {get; set;}
    public String emailBcc {get; set;}
    public String emailSubject {get; set;}
    public String emailBody {get; set;}
    public String xmlheader {get { return '<?xml version="1.0"?><?mso-application progid="Excel.Sheet"?>'; } }

    public Boolean openPagesFilterSectionByDefault {get; set;}
    public Boolean manageAssortByPersonalizedCategory {get; set;}
    public Boolean isShowHistory {get; set;} // flag to filter history detail records or not
    public Boolean includeStores {get; set;}
    public Boolean includeAllStatus {get; set;}
    private Boolean oldIncludeAllStatus;
    public Boolean hideBlankStatus {get; set;}
    public Boolean showIntroProducts {get; set;} // flag to show intro products even if client status is null
    public Boolean onlyShowIntroProducts {get; set;} // if set to true then the matrix will only display unit_needs and products introduced the same year as the assortment
    //public Boolean hideUnitCostGap {get; set;}
    //public Boolean hideNetPriceGap {get; set;}

    // popup switchProduct fields
    public Boolean popupSwitchProduct {get; set;}
    public Id assortmentDetailId {get; set;}
    public Id assortmentDetailCategory {get; set;}
    public String productName {get; set;}
    public List<SwitchProductWrapper> switchProductsList {get; set;}
    public Integer productSwitchCount {get; set;}
    public Boolean singleProductAction {get; set;}
    public String popupTitle {get; set;}
    private List<Schema.PicklistEntry> productReferenceTypePicklistValues {
        get {
            List<Schema.PicklistEntry> picklistEntriesList = productReferenceTypePicklistValues != null ? productReferenceTypePicklistValues : Product2.fields.Negoptim__Product_Reference_Type__c.getDescribe().getPicklistValues();
            return picklistEntriesList;
        }
    }
    // popup SelectHigherLevelPackaging fields
    public Boolean popupSelectHigherLevelPackaging {get; set;}
    public Id productToSelectedHigherLevelPackaging {get; set;}
    public Negoptim__Assortment_Detail__c higherLevelPackagingMasterDetail {get; set;}
    public List<HigherLevelPackagingWrapper> higherLevelPackagingWrapperList {get; set;}
    public Map<Id, boolean> hasHigherLevelPackagingMap {get; set;}
    public String hasHigherLevelPackagingMapKeySet_serialized {
        get {
            return hasHigherLevelPackagingMap == null ? '' : JSON.serialize(hasHigherLevelPackagingMap.keySet());
        }
    }

    public String clientStatus_serialized {get; set;}
    /*public Map<String, Map<Integer, Orga_BU__c>> buClustersMap {get; set;}*/
    public Map<Id, List<BUClusterWrapper>> categoryBUClustersMap {get; set;} // categoryId => list of clusters
    public Map<Id, List<BUClusterWrapper>> categoryBUCpltMap {get; set;} // categoryId => list of complements
    public Map<Id, List<BUClusterWrapper>> categoryBUClustersRefMap {get; set;}
    public Map<Id, List<BUClusterWrapper>> categoryBUCpltRefMap {get; set;}
    public String categoryBUClustersMap_serialized {get; set;}
    public String stratsMap_serialized {get; set;}
    public String cpltMap_serialized {get; set;}

    public Integer maxClusterCount {get;set;}
    public String maxClusterCategory {get; set;}
    public String maxCpltCategory {get; set;}
    private Integer clusterNameLength;

    public Negoptim__Assortment_BU__c assortmentBU {get; set;}
    public ApexPages.StandardSetController assortmentDetailStdSetCtrl { get; set;}
    public Map<Id, String> categoryNamesMap {get; set;}
    public String categoryNamesMapKeySet_SerialisedJSON {
        get{
            return categoryNamesMap != null ? JSON.serialize(categoryNamesMap.keySet()) : '';
        } set;
    }

    // map of strat ids for each assortment_bu
    private Map<Id, Negoptim__Assortment_Detail__c> assortmentDetailsUpdatedMap {get; set;}
    public Map<Id, Negoptim__Assortment_Detail__c> initialAssortmentDetailsMap {get; set;}
    public List<CategoryWrapper> wAssortmentDetailList {get; set;} // iterated in view to display records
    public Map<Id, Map<String, Integer>> counts {get; set;}
    public Map<Id, Map<String, Decimal>> sums {get; set;}
    private List<String> fieldsToCountList;
    private List<String> fieldsToSumList;
    private List<String> formulaFieldsList;
    private Id hlpProductRecordType;
    /* Pagination */
    public Integer pageSize {get; set;} // pagination size
    public Integer noOfRecords {get; set;} // total number of records
    private List<Integer> pageSizesOptions = new List<Integer> {5, 10, 25, 50, 75, 100};
    public List<SelectOption> pageSizes {
        get {
            List<SelectOption> newpageSizes = new List<SelectOption>();
            for (Integer pagesizeItem : pageSizesOptions) {
                 newpageSizes.add(new SelectOption(String.valueOf(pagesizeItem), String.valueOf(pagesizeItem)));
            }
            return newpageSizes;
        }
        set;
    }
    public String jsonCategoryTree {get; set;}
    private DateTime lastModifiedDate {get; set;}

    public Boolean multipleComplementary {get; set;}
    public Boolean isOrgCPG {get; set;}
    public Boolean showSubtotal {get; set;}
    private HierarchyElementTree het;

    //Filter on Mvt Date
    public List<SelectOption> operatorsOptions {
        get {
            List<SelectOption> options = new List<SelectOption>();
            options.add(new SelectOption('', ''));
            options.add(new SelectOption('=', '='));
            options.add(new SelectOption('>', '>'));
            options.add(new SelectOption('>=', '>='));
            options.add(new SelectOption('<', '<'));
            options.add(new SelectOption('<=', '<='));
            return options;
        } set;}

    public String selectedOperator {get; set;}
    public Negoptim__Assortment_Detail__c filterDetail {get; set;}
    // Check change on ASD list
    public String assortmentDetailChangesList {get; set;}
    private Set<Id> updatedAssortmentDetailIds;

    /** Constructor. */
    public AssortmentBUMatrixControllerExt(ApexPages.StandardController stdController) {
        this.categIndex = 0;
        this.pageSize = DEFAULT_PAGE_SIZE;
        this.selectedOperator = '';
        this.filterDetail = new Negoptim__Assortment_Detail__c(Negoptim__Movement_Date__c = System.today());
        this.auraPrefix = null;
        this.log = null;
        this.assortmentDetailChangesList = '[]';
        this.updatedAssortmentDetailIds = new Set<Id>();
        // load custom settings
		NegoptimSettings settings = (NegoptimSettings) JSON.deserialize(Negoptim.GlobalSettingsManager.loadGlobalSettingsSerialized(), NegoptimSettings.class);
        if (!System.Test.isRunningTest() && (settings.sBusinessType == null || settings.sBusinessType == '')) {
            ApexPages.addMessage(new ApexPages.Message(ApexPAges.Severity.ERROR, Label.Negoptim.MSG_Business_Type_Empty));
            return;
        }
        this.isOrgCPG = settings.sBusinessType != null && settings.sBusinessType.equals('CPG');
        // add fields to standard controller to be used in excel files
        List<String> fieldNames = new List<String> {
            SObjectType.Negoptim__Assortment_BU__c.fields.Name.Name,
            SObjectType.Negoptim__Assortment_BU__c.fields.Negoptim__New_Client_WD_MarketBased__c.Name,
            SObjectType.Negoptim__Assortment_BU__c.fields.Negoptim__BU_Target__c.Name,
            SObjectType.Negoptim__Assortment_BU__c.fields.Negoptim__Orga_HE__c.Name,
            SObjectType.Negoptim__Assortment_BU__c.fields.Negoptim__Ass_BDate__c.Name,
            SObjectType.Negoptim__Assortment_BU__c.fields.Negoptim__Ass_EDate__c.Name,
            SObjectType.Negoptim__Assortment_BU__c.fields.Negoptim__Status__c.Name,
            SObjectType.Negoptim__Assortment_BU__c.fields.Negoptim__Year__c.Name,
            SObjectType.Negoptim__Assortment_BU__c.fields.Negoptim__Assortment_parent__c.Name
        };
        // add fields only if test is not running
        if (!System.Test.isRunningTest()) {
            stdController.addFields(fieldNames);
        }
		// check if a record type parameter is passed in the URL
        this.detailRecordType = ApexPages.currentPage().getParameters().containsKey('recordType') ? ApexPages.currentPage().getParameters().get('recordType') : detailRecordType;
        this.showSubtotal = ApexPages.currentPage().getParameters().containsKey('showSubtotal') ? Boolean.valueOf(ApexPages.currentPage().getParameters().get('showSubtotal')) : false;
        // Get record Id
        String assortmentBUId = stdController.getId();
        if(String.isNotBlank(assortmentBUId)) {
            try {
                this.assortmentBU = (Negoptim__Assortment_BU__c)stdController.getRecord();
                // fill active taxes and active discounts from JSON text in Assortment BU fields
                this.contractActiveTaxesMap = new Map<Integer, StatementWrapper>();
                this.contractActiveDiscountsMap = new Map<Integer, StatementWrapper>();
                this.statementActiveTaxesMap = new Map<Integer, StatementWrapper>();
                this.statementActiveDiscountsMap = new Map<Integer, StatementWrapper>();

                Map<String, Map<Integer, Negoptim__Orga_BU__c>> clustersMap = new Map<String, Map<Integer, Negoptim__Orga_BU__c>>();
                String[] orgaBUFields = new String[] {
                    SObjectType.Negoptim__Orga_BU__c.fields.Name.Name,
                    SObjectType.Negoptim__Orga_BU__c.fields.Negoptim__Country_Origin__c.Name,
                    SObjectType.Negoptim__Orga_BU__c.fields.Negoptim__Category__c.Name,
                    SObjectType.Negoptim__Orga_BU__c.fields.Negoptim__Status__c.Name,
                    SObjectType.Negoptim__Orga_BU__c.fields.Negoptim__Assortment_Strat__c.Name,
                    SObjectType.Negoptim__Orga_BU__c.fields.Negoptim__Multiple_Complementary__c.Name,
                    SObjectType.Negoptim__Orga_BU__c.fields.RecordTypeId.Name
                };
                if (checkAccessibility(Negoptim__Orga_BU__c.SObjectType, orgaBUFields)) {
                    Negoptim__Orga_BU__c targetBU = [SELECT Id, Negoptim__Multiple_Complementary__c FROM Negoptim__Orga_BU__c WHERE Id = :this.assortmentBU.Negoptim__BU_Target__c];
                    if(targetBU != null) {
                        this.multipleComplementary = targetBU.Negoptim__Multiple_Complementary__c != null ? targetBU.Negoptim__Multiple_Complementary__c : false;
                    }
                    // CHECK 1: IF THERE ARE MORE REF CLUSTERS THAN CLUSTERS
                    // CHECK 2: IF THERE ARE MORE CLUSTERS THAN CLUSTER FIELDS
                    // get Assortment_Detail__c Object Fields
                    Map<String, SObjectField> assortmentDetailsFields = SObjectType.Negoptim__Assortment_Detail__c.fields.getMap();
                    // get the count of fields for each set of clusters: Client_Clusters, Ref_Client_Clusters, Client_Cluster_Cplts, Ref_Client_Cluster_Cplts
                    Integer nbStratClustersFields = 0;
                    Integer nbCpltClustersFields = 0;
                    Integer nbRefStratClustersFields = 0;
                    Integer nbRefCpltClustersFields = 0;

                    String stratFieldName = Negoptim.NegoptimHelper.normalizeAPIName('Client_Clust');
                    String cpltFieldName = Negoptim.NegoptimHelper.normalizeAPIName('Client_Clust_Cplt');
                    String refStratFieldName = Negoptim.NegoptimHelper.normalizeAPIName('Ref_Client_Clust');
                    String refCpltFieldName = Negoptim.NegoptimHelper.normalizeAPIName('Ref_Client_Clust_Cplt');

                    Set<String> assortmentDetailsFieldsSet = assortmentDetailsFields.keySet();

                    for (String fieldName : assortmentDetailsFieldsSet) {
                        if (fieldName.startsWithIgnoreCase(stratFieldName) && !fieldName.containsIgnoreCase('Cplt') && fieldName.endsWithIgnoreCase('__c')) {
                            nbStratClustersFields++;
                        } else if (fieldName.startsWithIgnoreCase(cpltFieldName) && fieldName.endsWithIgnoreCase('__c')) {
                            nbCpltClustersFields++;
                        } else if (fieldName.startsWithIgnoreCase(refStratFieldName) && !fieldName.containsIgnoreCase('Cplt') && fieldName.endsWithIgnoreCase('__c')) {
                            nbRefStratClustersFields++;
                        } else if (fieldName.startsWithIgnoreCase(refCpltFieldName) && fieldName.endsWithIgnoreCase('__c')) {
                            nbRefCpltClustersFields++;
                        }
                    }
                    // CHECK 1
                    if (nbStratClustersFields != nbRefStratClustersFields || nbCpltClustersFields != nbRefCpltClustersFields) {
                        String message = 'There are more clusters than ref clusters';
                        ApexPages.addMessage(new ApexPages.Message(ApexPAges.Severity.ERROR, message));
                        return;
                    }
                    // CHECK 2
                    // query the available clusters for this assortment
                    // LEVEL ASSORTMENT ONLY
                    // TODO: MAKE IT COMPATIBLE WITH MULTI LEVEL CLUSTERS
                    // item.BU_ODate__c != null && item.BU_ODate__c.year() <= clusterYear && (item.BU_CDate__c == null || item.BU_CDate__c.year() >= clusterYear
                    Integer year = Integer.valueOf(this.assortmentBU.Negoptim__Year__c);
                    List<Negoptim__Orga_BU__c> assortmentClusters = [SELECT Name, Negoptim__Assortment_Strat__c FROM Negoptim__Orga_BU__c
                                                           WHERE Negoptim__Country_Origin__c = :this.assortmentBU.Negoptim__BU_Target__c
                                                           AND Negoptim__Category__c = :this.assortmentBU.Negoptim__Orga_HE__c
                                                           AND recordType.DeveloperName = :CommonConstants.RT_ORGA_BU_ASSORTMENT_CLUSTER
                                                           AND (Negoptim__BU_ODate__c <> NULL AND CALENDAR_YEAR(Negoptim__BU_ODate__c) <= :year AND (Negoptim__BU_CDate__c = NULL OR CALENDAR_YEAR(Negoptim__BU_CDate__c) >= :year))
                                                           ORDER BY Negoptim__Assortment_Strat__c];
                    for(Negoptim__Orga_BU__c item : assortmentClusters) {
                        Integer clusterIndex = Integer.valueOf(item.Negoptim__Assortment_Strat__c.right(1));
                        // check if strat index is greater than (min(nbStratClustersFields, nbRefStratClustersFields) - 1)
                        // if strat index is greater than (min(nbStratClustersFields, nbRefStratClustersFields) - 1) then alert the user
                        // clusters must have a strat index between 0 and (min(nbStratClustersFields, nbRefStratClustersFields) - 1)
                        // clusters with strat index greatear than (min(nbStratClustersFields, nbRefStratClustersFields) - 1) are not yet supoorted
                        // and do a similar check for cplt strats and (min(nbCpltClustersFields, nbRefCpltClustersFields) - 1)
                        if ((item.Negoptim__Assortment_Strat__c.startsWithIgnoreCase('Strat') && clusterIndex > (Math.min(nbStratClustersFields, nbRefStratClustersFields) - 1))
                            || (item.Negoptim__Assortment_Strat__c.startsWithIgnoreCase('Cplt') && clusterIndex > (Math.min(nbCpltClustersFields, nbRefCpltClustersFields) - 1)))
                        {
                            List<Object> arguments = new List<Object>();
                            arguments.add(item.Name);
                            arguments.add(item.Id);
                            arguments.add(clusterIndex);
                            String message = String.format('{0} [{1}] has an strat index of {2}. such index is not yet supported', arguments);
                            ApexPages.addMessage(new ApexPages.Message(ApexPAges.Severity.ERROR, message));
                            // set json variables to empty objects so that the javascript doesn't break;
                            gridFields_serialized = '{}';
                            fieldsToCountList_serialized = '{}';
                            fieldsToSumList_serialized = '{}';
                            formulasFieldsList_serialized = '{}';
                            picklistValuesMap_serialized = '{}';
                            return;
                        }
                        if(item.Negoptim__Assortment_Strat__c.startsWithIgnoreCase('Strat')) {
                            if(!clustersMap.containsKey('Strat')) {
                                clustersMap.put('Strat', new Map<Integer, Negoptim__Orga_BU__c>());
                            }
                            clustersMap.get('Strat').put(clusterIndex, item);
                        } else if(item.Negoptim__Assortment_Strat__c.startsWithIgnoreCase('Cplt')) {
                            if(!clustersMap.containsKey('Cplt')) {
                                clustersMap.put('Cplt', new Map<Integer, Negoptim__Orga_BU__c>());
                            }
                            clustersMap.get('Cplt').put(clusterIndex, item);
                        }
                    }
                    this.categoryNamesMap = new Map<Id, String>();
                    // To display apex message when validate assortment after page redirect:
                    String message = ApexPages.CurrentPage().getParameters().get('messages');
                    if(String.isNotBlank(message)) {
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, message));
                    }
                    this.assortmentMatrixTargetGridLayout = settings.assortmentMatrixTargetGridLayout;
                    // load matrix grid layout from custom settings
                    this.assortmentMatrixGridLayout = settings.assortmentMatrixGridLayout;
                    String layoutParam = ApexPages.currentPage().getParameters().get('layout');
                    this.assortmentMatrixGridLayout = String.isBlank(layoutParam) ? this.assortmentMatrixGridLayout : layoutParam;
                    isTargetMatrix = this.assortmentMatrixGridLayout == this.assortmentMatrixTargetGridLayout;

                    //get higher level packeging record type from global settings
                    this.hlpProductRecordType = settings.higherLevelPackagingRecordTypeId;
                    if (hlpProductRecordType == null) {
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Higher Level Type Is Not Set'));
                        return;
                    }
                    List<String> staticFieldsList = new List<String> {
                        'RecordType.DeveloperName',
                        SObjectType.Negoptim__Assortment_Detail__c.fields.Name.Name,
                        SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__Category__c.Name,
                        SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__Client_Category__c.Name,
                        SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__Force_Update__c.Name,
                        SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__Product__c.Name,
                        SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__Movement_Date__c.Name,
                        SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__Client_Status__c.Name,
                        SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__Status__c.Name,
                        SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__Assortment_BU__c.Name,
                        SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__Record_date__c.Name,
                        SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__Version__c.Name,
                        SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__New_Client_WD_ClientBased__c.Name,
                        SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__New_Client_WD_MarketBased__c.Name,
                        SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__Year__c.Name,
                        SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__Ass_BU_Cluster__c.Name,

                        Negoptim.NegoptimHelper.getFieldNameAsRelation(SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__Category__c.Name) + '.' + SObjectType.Negoptim__Orga_HE__c.fields.Name.Name,
                        Negoptim.NegoptimHelper.getFieldNameAsRelation(SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__Category__c.Name) + '.' + SObjectType.Negoptim__Orga_HE__c.fields.Negoptim__Parent_Element__c.Name,
                        Negoptim.NegoptimHelper.getFieldNameAsRelation(SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__Category__c.Name) + '.' + SObjectType.Negoptim__Orga_HE__c.fields.Negoptim__Level__c.Name,
                        Negoptim.NegoptimHelper.getFieldNameAsRelation(SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__Category__c.Name) + '.' + SObjectType.Negoptim__Orga_HE__c.fields.Negoptim__Path__c.Name,
                        Negoptim.NegoptimHelper.getFieldNameAsRelation(SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__Category__c.Name) + '.' + SObjectType.Negoptim__Orga_HE__c.fields.Negoptim__Long_Name_1__c.Name,
                        Negoptim.NegoptimHelper.getFieldNameAsRelation(SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__Category__c.Name) + '.' + SObjectType.Negoptim__Orga_HE__c.fields.Negoptim__Long_Name__c.Name,
                        Negoptim.NegoptimHelper.getFieldNameAsRelation(SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__Category__c.Name) + '.' + Negoptim.NegoptimHelper.getFieldNameAsRelation(SObjectType.Negoptim__Orga_HE__c.fields.Negoptim__Parent_Element__c.Name) + '.' + SObjectType.Negoptim__Orga_HE__c.fields.Name.Name,
                        Negoptim.NegoptimHelper.getFieldNameAsRelation(SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__Category__c.Name) + '.' + Negoptim.NegoptimHelper.getFieldNameAsRelation(SObjectType.Negoptim__Orga_HE__c.fields.Negoptim__Parent_Element__c.Name) + '.' + SObjectType.Negoptim__Orga_HE__c.fields.Negoptim__Long_Name_1__c.Name,
                        Negoptim.NegoptimHelper.getFieldNameAsRelation(SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__Category__c.Name) + '.' + Negoptim.NegoptimHelper.getFieldNameAsRelation(SObjectType.Negoptim__Orga_HE__c.fields.Negoptim__Parent_Element__c.Name) + '.' + SObjectType.Negoptim__Orga_HE__c.fields.Negoptim__Long_Name__c.Name,
                        Negoptim.NegoptimHelper.getFieldNameAsRelation(SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__Category__c.Name) + '.' + Negoptim.NegoptimHelper.getFieldNameAsRelation(SObjectType.Negoptim__Orga_HE__c.fields.Negoptim__Parent_Element__c.Name)
                            + '.' + Negoptim.NegoptimHelper.getFieldNameAsRelation(SObjectType.Negoptim__Orga_HE__c.fields.Negoptim__Parent_Element__c.Name)
                            + '.' + SObjectType.Negoptim__Orga_HE__c.fields.Name.Name,
                        Negoptim.NegoptimHelper.getFieldNameAsRelation(SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__Category__c.Name) + '.' + Negoptim.NegoptimHelper.getFieldNameAsRelation(SObjectType.Negoptim__Orga_HE__c.fields.Negoptim__Parent_Element__c.Name)
                            + '.' + Negoptim.NegoptimHelper.getFieldNameAsRelation(SObjectType.Negoptim__Orga_HE__c.fields.Negoptim__Parent_Element__c.Name)
                            + '.' + SObjectType.Negoptim__Orga_HE__c.fields.Negoptim__Long_Name_1__c.Name,
                        Negoptim.NegoptimHelper.getFieldNameAsRelation(SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__Category__c.Name) + '.' + Negoptim.NegoptimHelper.getFieldNameAsRelation(SObjectType.Negoptim__Orga_HE__c.fields.Negoptim__Parent_Element__c.Name)
                            + '.' + Negoptim.NegoptimHelper.getFieldNameAsRelation(SObjectType.Negoptim__Orga_HE__c.fields.Negoptim__Parent_Element__c.Name)
                            + '.' + SObjectType.Negoptim__Orga_HE__c.fields.Negoptim__Long_Name__c.Name,
                        Negoptim.NegoptimHelper.getFieldNameAsRelation(SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__Category__c.Name) + '.' + Negoptim.NegoptimHelper.getFieldNameAsRelation(SObjectType.Negoptim__Orga_HE__c.fields.Negoptim__Parent_Element__c.Name)
                            + '.' + Negoptim.NegoptimHelper.getFieldNameAsRelation(SObjectType.Negoptim__Orga_HE__c.fields.Negoptim__Parent_Element__c.Name)
                            + '.' + SObjectType.Negoptim__Orga_HE__c.fields.Negoptim__Path__c.Name,
                        Negoptim.NegoptimHelper.getFieldNameAsRelation(SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__Category__c.Name) + '.' + Negoptim.NegoptimHelper.getFieldNameAsRelation(SObjectType.Negoptim__Orga_HE__c.fields.Negoptim__Parent_Element__c.Name)
                            + '.' + Negoptim.NegoptimHelper.getFieldNameAsRelation(SObjectType.Negoptim__Orga_HE__c.fields.Negoptim__Parent_Element__c.Name)
                            + '.' + SObjectType.Negoptim__Orga_HE__c.fields.Negoptim__Level__c.Name,
                        Negoptim.NegoptimHelper.getFieldNameAsRelation(SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__Category__c.Name) + '.' + Negoptim.NegoptimHelper.getFieldNameAsRelation(SObjectType.Negoptim__Orga_HE__c.fields.Negoptim__Parent_Element__c.Name)
                            + '.' + SObjectType.Negoptim__Orga_HE__c.fields.Negoptim__Parent_Element__c.Name,

                        Negoptim.NegoptimHelper.getFieldNameAsRelation(SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__Client_Category__c.Name) + '.' + SObjectType.Negoptim__Orga_HE__c.fields.Name.Name,
                        Negoptim.NegoptimHelper.getFieldNameAsRelation(SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__Client_Category__c.Name) + '.' + SObjectType.Negoptim__Orga_HE__c.fields.Negoptim__Parent_Element__c.Name,
                        Negoptim.NegoptimHelper.getFieldNameAsRelation(SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__Client_Category__c.Name) + '.' + SObjectType.Negoptim__Orga_HE__c.fields.Negoptim__Level__c.Name,
                        Negoptim.NegoptimHelper.getFieldNameAsRelation(SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__Client_Category__c.Name) + '.' + SObjectType.Negoptim__Orga_HE__c.fields.Negoptim__Path__c.Name,
                        Negoptim.NegoptimHelper.getFieldNameAsRelation(SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__Client_Category__c.Name) + '.' + SObjectType.Negoptim__Orga_HE__c.fields.Negoptim__Long_Name_1__c.Name,
                        Negoptim.NegoptimHelper.getFieldNameAsRelation(SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__Client_Category__c.Name) + '.' + SObjectType.Negoptim__Orga_HE__c.fields.Negoptim__Long_Name__c.Name,
                        Negoptim.NegoptimHelper.getFieldNameAsRelation(SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__Client_Category__c.Name) + '.' + Negoptim.NegoptimHelper.getFieldNameAsRelation(SObjectType.Negoptim__Orga_HE__c.fields.Negoptim__Parent_Element__c.Name)
                            + '.' + Negoptim.NegoptimHelper.getFieldNameAsRelation(SObjectType.Negoptim__Orga_HE__c.fields.Negoptim__Parent_Element__c.Name)
                            + '.' + SObjectType.Negoptim__Orga_HE__c.fields.Name.Name,
                        Negoptim.NegoptimHelper.getFieldNameAsRelation(SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__Client_Category__c.Name) + '.' + Negoptim.NegoptimHelper.getFieldNameAsRelation(SObjectType.Negoptim__Orga_HE__c.fields.Negoptim__Parent_Element__c.Name)
                            + '.' + Negoptim.NegoptimHelper.getFieldNameAsRelation(SObjectType.Negoptim__Orga_HE__c.fields.Negoptim__Parent_Element__c.Name)
                            + '.' + SObjectType.Negoptim__Orga_HE__c.fields.Negoptim__Long_Name_1__c.Name,
                        Negoptim.NegoptimHelper.getFieldNameAsRelation(SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__Client_Category__c.Name) + '.' + Negoptim.NegoptimHelper.getFieldNameAsRelation(SObjectType.Negoptim__Orga_HE__c.fields.Negoptim__Parent_Element__c.Name)
                            + '.' + Negoptim.NegoptimHelper.getFieldNameAsRelation(SObjectType.Negoptim__Orga_HE__c.fields.Negoptim__Parent_Element__c.Name)
                            + '.' + SObjectType.Negoptim__Orga_HE__c.fields.Negoptim__Long_Name__c.Name,
                        Negoptim.NegoptimHelper.getFieldNameAsRelation(SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__Client_Category__c.Name) + '.' + Negoptim.NegoptimHelper.getFieldNameAsRelation(SObjectType.Negoptim__Orga_HE__c.fields.Negoptim__Parent_Element__c.Name)
                            + '.' + Negoptim.NegoptimHelper.getFieldNameAsRelation(SObjectType.Negoptim__Orga_HE__c.fields.Negoptim__Parent_Element__c.Name)
                            + '.' + SObjectType.Negoptim__Orga_HE__c.fields.Negoptim__Path__c.Name,
                        Negoptim.NegoptimHelper.getFieldNameAsRelation(SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__Client_Category__c.Name) + '.' + Negoptim.NegoptimHelper.getFieldNameAsRelation(SObjectType.Negoptim__Orga_HE__c.fields.Negoptim__Parent_Element__c.Name)
                            + '.' + Negoptim.NegoptimHelper.getFieldNameAsRelation(SObjectType.Negoptim__Orga_HE__c.fields.Negoptim__Parent_Element__c.Name)
                            + '.' + SObjectType.Negoptim__Orga_HE__c.fields.Negoptim__Level__c.Name,
                        Negoptim.NegoptimHelper.getFieldNameAsRelation(SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__Client_Category__c.Name) + '.' + Negoptim.NegoptimHelper.getFieldNameAsRelation(SObjectType.Negoptim__Orga_HE__c.fields.Negoptim__Parent_Element__c.Name)
                            + '.' + SObjectType.Negoptim__Orga_HE__c.fields.Negoptim__Parent_Element__c.Name,

                        Negoptim.NegoptimHelper.getFieldNameAsRelation(SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__Assortment_BU__c.Name) + '.' + SObjectType.Negoptim__Assortment_BU__c.fields.Negoptim__BU_Target__c.Name,
                        Negoptim.NegoptimHelper.getFieldNameAsRelation(SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__Assortment_BU__c.Name) + '.' + SObjectType.Negoptim__Assortment_BU__c.fields.Negoptim__Ass_BDate__c.Name,
                        Negoptim.NegoptimHelper.getFieldNameAsRelation(SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__Assortment_BU__c.Name) + '.' + SObjectType.Negoptim__Assortment_BU__c.fields.Negoptim__Ass_EDate__c.Name,
                        Negoptim.NegoptimHelper.getFieldNameAsRelation(SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__Assortment_BU__c.Name) + '.' + SObjectType.Negoptim__Assortment_BU__c.fields.Negoptim__Orga_HE__c.Name,
                        Negoptim.NegoptimHelper.getFieldNameAsRelation(SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__Assortment_BU__c.Name) + '.' + SObjectType.Negoptim__Assortment_BU__c.fields.Negoptim__Year__c.Name,
                        Negoptim.NegoptimHelper.getFieldNameAsRelation(SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__Assortment_BU__c.Name) + '.' + SObjectType.Negoptim__Assortment_BU__c.fields.LastModifiedDate.Name,
                        Negoptim.NegoptimHelper.getFieldNameAsRelation(SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__Assortment_BU__c.Name) + '.' + SObjectType.Negoptim__Assortment_BU__c.fields.Negoptim__Assortment_parent__c.Name,
                        Negoptim.NegoptimHelper.getFieldNameAsRelation(SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__Assortment_BU__c.Name) + '.' + Negoptim.NegoptimHelper.getFieldNameAsRelation(SObjectType.Negoptim__Assortment_BU__c.fields.Negoptim__Assortment_parent__c.Name)
                            + '.' + SObjectType.Negoptim__Assortment_BU__c.fields.Negoptim__Ass_BDate__c.Name,
                        Negoptim.NegoptimHelper.getFieldNameAsRelation(SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__Assortment_BU__c.Name) + '.' + Negoptim.NegoptimHelper.getFieldNameAsRelation(SObjectType.Negoptim__Assortment_BU__c.fields.Negoptim__Assortment_parent__c.Name)
                            + '.' + SObjectType.Negoptim__Assortment_BU__c.fields.Negoptim__Ass_EDate__c.Name,
                        Negoptim.NegoptimHelper.getFieldNameAsRelation(SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__Assortment_BU__c.Name) + '.' + Negoptim.NegoptimHelper.getFieldNameAsRelation(SObjectType.Negoptim__Assortment_BU__c.fields.Negoptim__Orga_HE__c.Name)
                            + '.' + SObjectType.Negoptim__Orga_HE__c.fields.Name.Name,
                        Negoptim.NegoptimHelper.getFieldNameAsRelation(SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__Last_History__c.Name) + '.' + SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__Ass_BU_Cluster__c.Name,
                        Negoptim.NegoptimHelper.getFieldNameAsRelation(SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__Last_History__c.Name) + '.' + Negoptim.NegoptimHelper.getFieldNameAsRelation(SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__Ass_BU_Cluster__c.Name)
                            + '.' + SObjectType.Negoptim__Orga_BU__c.fields.Negoptim__Assortment_Strat__c.Name,
                        Negoptim.NegoptimHelper.getFieldNameAsRelation(SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__Ref_Client_Assortment__c.Name) + '.' + SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__Ass_BU_Cluster__c.Name,
                        Negoptim.NegoptimHelper.getFieldNameAsRelation(SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__Ref_Client_Assortment__c.Name) + '.' + Negoptim.NegoptimHelper.getFieldNameAsRelation(SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__Ass_BU_Cluster__c.Name)
                            + '.' + SObjectType.Negoptim__Orga_BU__c.fields.Negoptim__Assortment_Strat__c.Name,

                        Negoptim.NegoptimHelper.getFieldNameAsRelation(SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__Ass_BU_Cluster__c.Name) + '.' + SObjectType.Negoptim__Orga_BU__c.fields.Negoptim__Assortment_Strat__c.Name,

                        Negoptim.NegoptimHelper.getFieldNameAsRelation(SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__Product__c.Name) + '.' + SObjectType.Product2.fields.Negoptim__Product_Reference_Type__c.Name,
                        Negoptim.NegoptimHelper.getFieldNameAsRelation(SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__Product__c.Name) + '.' + SObjectType.Product2.fields.Negoptim__Market_End_of_Life_Date__c.Name,
                        Negoptim.NegoptimHelper.getFieldNameAsRelation(SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__Product__c.Name) + '.' + SObjectType.Product2.fields.Negoptim__Market_Introduction_Date__c.Name,
                        Negoptim.NegoptimHelper.getFieldNameAsRelation(SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__Product__c.Name) + '.' + SObjectType.Product2.fields.Negoptim__IsRenovation__c.Name,
                        Negoptim.NegoptimHelper.getFieldNameAsRelation(SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__Product__c.Name) + '.' + SObjectType.Product2.fields.Negoptim__IsInnovation__c.Name,
                        Negoptim.NegoptimHelper.getFieldNameAsRelation(SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__Product__c.Name) + '.' + SObjectType.Product2.fields.Name.Name,

                        Negoptim.NegoptimHelper.getFieldNameAsRelation(SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__Product__c.Name) + '.RecordType.' + SObjectType.RecordType.fields.DeveloperName.Name,

                        Negoptim.NegoptimHelper.getFieldNameAsRelation(SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__Last_History__c.Name) + '.' + SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__Client_Status__c.Name,
                        Negoptim.NegoptimHelper.getFieldNameAsRelation(SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__Last_History__c.Name) + '.' + SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__Product__c.Name,

                        Negoptim.NegoptimHelper.getFieldNameAsRelation(SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__Ref_Client_Assortment__c.Name) + '.' + SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__Client_Status__c.Name,
                        Negoptim.NegoptimHelper.getFieldNameAsRelation(SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__Ref_Client_Assortment__c.Name) + '.' + SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__Year__c.Name,
                        Negoptim.NegoptimHelper.getFieldNameAsRelation(SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__Ref_Client_Assortment__c.Name) + '.' + SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__Status__c.Name,

                        Negoptim.NegoptimHelper.getFieldNameAsRelation(SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__Assortment_BU__c.Name) + '.' + Negoptim.NegoptimHelper.getFieldNameAsRelation(SObjectType.Negoptim__Assortment_BU__c.fields.Negoptim__Orga_HE__c.Name) + '.' + SObjectType.Negoptim__Orga_HE__c.fields.Negoptim__Path__c.Name
                    };
                    for (Integer i = 1; i <= nbClientClusterFields; i++) {
                        // Last_History clusters
                        String clusterField = Negoptim.NegoptimHelper.normalizeAPIName('Client_Clust' + i + '__c');
                        if (assortmentDetailsFields.containsKey(clusterField.toLowerCase())) {
                            staticFieldsList.add(Negoptim.NegoptimHelper.getFieldNameAsRelation(SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__Last_History__c.Name) + '.' + clusterField);
                            staticFieldsList.add(Negoptim.NegoptimHelper.getFieldNameAsRelation(SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__Ref_Client_Assortment__c.Name) + '.' + clusterField);
                            staticFieldsList.add(clusterField);
                        }
                        // ref clusters
                        clusterField = Negoptim.NegoptimHelper.normalizeAPIName('Ref_Client_Clust' + i + '__c');
                        if (assortmentDetailsFields.containsKey(clusterField.toLowerCase())) {
                            staticFieldsList.add(clusterField);
                        }
                        // cplt clusters
                        clusterField = Negoptim.NegoptimHelper.normalizeAPIName('Client_Clust_Cplt' + i + '__c');
                        if (assortmentDetailsFields.containsKey(clusterField.toLowerCase())) {
                            staticFieldsList.add(clusterField);
                        }
                        // ref cplt clusters
                        clusterField = Negoptim.NegoptimHelper.normalizeAPIName('Ref_Client_Clust_Cplt' + i + '__c');
                        if (assortmentDetailsFields.containsKey(clusterField.toLowerCase())) {
                            staticFieldsList.add(clusterField);
                        }
                    }
                    String staticFields = String.join(staticFieldsList, ',');
                    String masterStaticFields = String.join(fieldNames, ',');
                    this.gridSettingsManager = new GridSettingsManager(Negoptim.NegoptimHelper.normalizeAPIName('Assortment_BU__c'), '', masterStaticFields, Negoptim.NegoptimHelper.normalizeAPIName('Assortment_Detail__c'), '', staticFields, assortmentMatrixGridLayout);
                    this.picklistValuesMap_serialized = JSON.serialize(this.gridSettingsManager.picklistValuesMap);
                    String itemsPerPageString = ApexPages.CurrentPage().getParameters().get('pageSize');
                    if (String.isNotBlank(itemsPerPageString)) {
                        try {
                            this.pageSize = Integer.valueOf(itemsPerPageString);
                        } catch(Exception ex) {
                            this.pageSize = DEFAULT_PAGE_SIZE;
                        }
                    } else if (this.gridSettingsManager.Default_Page_Size != null && this.pageSizesOptions.contains(this.gridSettingsManager.Default_Page_Size)) {
                        this.pageSize = this.gridSettingsManager.Default_Page_Size;
                    }
                    // init fields related to totals
                    this.dynamicFields = new List<String>();
                    this.fieldsToCountList = new List<String>();
                    this.fieldsToSumList = new List<String>();
                    this.formulaFieldsList = new List<String>();
                    this.totalFields = new List<GridSettingsManager.FieldWrapper>();
                    Map<String, GridSettingsManager.FieldWrapper> gridFieldsMap = new Map<String, GridSettingsManager.FieldWrapper>();
                    Integer sizeFields = this.gridSettingsManager.GRID_FIELDS.size();
                    for(Integer i = 0; i < sizeFields; i++) {
                        GridSettingsManager.FieldWrapper field = this.gridSettingsManager.GRID_FIELDS.get(i);
                        dynamicFields.add(field.fieldName);
                        gridFieldsMap.put(field.fieldName, field);
                        if (!field.isReference)
                        {
                            ////field.fieldLabel = field.fieldLabel.escapeHtml4().escapeEcmaScript(); // handling possible Stored XSS attack
                            if (field.fieldType == DisplayType.Boolean) {
                                fieldsToCountList.add(field.fieldName);
                                if (field.fieldName.startsWithIgnoreCase(Negoptim.NegoptimHelper.normalizeAPIName('Client_Clust')) && field.fieldName.endsWithIgnoreCase('__c')
                                    && !field.fieldName.containsIgnoreCase('Cplt'))
                                {
                                    Integer clientClustIndex = Integer.valueOf(field.fieldName.replace(Negoptim.NegoptimHelper.normalizeAPIName('Client_Clust'), '').replace('__c', ''));
                                    if(clustersMap.containsKey('Strat') && clustersMap.get('Strat').containsKey(clientClustIndex - 1)) {
                                        field.fieldLabel = clustersMap.get('Strat').get(clientClustIndex - 1).Name;
                                    } else continue;
                                } else if (field.fieldName.startsWithIgnoreCase(Negoptim.NegoptimHelper.normalizeAPIName('Ref_Client_Clust')) && field.fieldName.endsWithIgnoreCase('__c')
                                           && !field.fieldName.containsIgnoreCase('Cplt'))
                                {
                                    Integer clientClustIndex = Integer.valueOf(field.fieldName.replace(Negoptim.NegoptimHelper.normalizeAPIName('Ref_Client_Clust'), '').replace('__c', ''));
                                    if(clustersMap.containsKey('Strat') && clustersMap.get('Strat').containsKey(clientClustIndex - 1)) {
                                        field.fieldLabel = clustersMap.get('Strat').get(clientClustIndex - 1).Name;
                                    } else continue;
                                } else if (field.fieldName.startsWithIgnoreCase(Negoptim.NegoptimHelper.normalizeAPIName('Client_Clust_Cplt')) && field.fieldName.endsWithIgnoreCase('__c')) {
                                    Integer clientClustIndex = Integer.valueOf(field.fieldName.replace(Negoptim.NegoptimHelper.normalizeAPIName('Client_Clust_Cplt'), '').replace('__c', ''));
                                    if(clustersMap.containsKey('Cplt') && clustersMap.get('Cplt').containsKey(clientClustIndex - 1)) {
                                        field.fieldLabel = clustersMap.get('Cplt').get(clientClustIndex - 1).Name;
                                    } else continue;
                                } else continue;
                            } else if (field.fieldType == DisplayType.Currency
                                       || field.fieldType == DisplayType.Double
                                       || field.fieldType == DisplayType.Integer
                                       || field.fieldType == DisplayType.Percent)
                            {
                                if (displayField(field.fieldName)) { // check if field should be added to the totals tree
                                    fieldsToSumList.add(field.fieldName);
                                    if (this.assortmentBU.Negoptim__Assortment_parent__c != NULL || !field.fieldName.startsWithIgnoreCase(Negoptim.NegoptimHelper.normalizeAPIName('Ref_Client_Clust')))
                                        this.totalFields.add(field);
                                } else {
                                    //go to the next iteration if the field is not added to the Sum List, this field is not needed in the total fields list to add
                                    continue;
                                }
                            } else if (field.isCalculated) {
                                formulaFieldsList.add(field.fieldName);
                            }
                        }
                    }
                    try {
                        if (checkAccessibility(Negoptim__Assortment_BU__c.SObjectType, fieldNames)) {
                            // add where clause
                            List<String> assortmentBuClause = new List<String>();
                            assortmentBuClause.add('Id = \''+assortmentBUId+'\'');
                            String assortmentBuQuery = this.gridSettingsManager.buildBannerQuery(assortmentBuClause);

                            List<Negoptim__Assortment_BU__c> assortmentBuList = Database.query(assortmentBuQuery);
                            if(assortmentBuList != null && !assortmentBuList.isEmpty()) {
                                this.assortmentBU = assortmentBuList[0];
                                // page rules for read only
                                // check user profile against custom settings
                                List<String> matrixProfiles = assortmentMatrixGridLayout == this.assortmentMatrixTargetGridLayout ?  settings.assortmentMatrixTargetProfile : settings.assortmentMatrixProfile;
                                String userProfile = UserInfo.getProfileId();
                                Boolean readOnlyUser = matrixProfiles == null || matrixProfiles.isEmpty() || !matrixProfiles.contains(userProfile);

                                this.readOnly = readOnlyUser
                                    || (this.assortmentBU.Negoptim__Ass_EDate__c < Date.today() && this.assortmentBU.Negoptim__Status__c == CommonConstants.PLV_ASSORTMENT_BU_STATUS_CLOSED);
                                this.gridSettingsManager.refreshGridFieldBaseOnReadOnlyCriteria(this.assortmentBU);
                                // grid settings read only rules
                                this.readOnly = this.readOnly || this.gridSettingsManager.isReadOnly;
                            }
                        }
                    } catch(Exception e) {
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, e.getMessage() + ' - ' + e.getLineNumber()));
                    }
                    this.gridFields_serialized = JSON.serialize(gridFieldsMap);
                    this.totalFields_serialized = JSON.serialize(this.totalFields);
                    this.fieldsToCountList_serialized = JSON.serialize(this.fieldsToCountList);
                    this.fieldsToSumList_serialized = JSON.serialize(this.fieldsToSumList);
                    this.formulasFieldsList_serialized = JSON.serialize(this.formulaFieldsList);
                    //
                    this.recordId = Id.valueOf(assortmentBUId);
                    this.product = new Product2();
                    this.isStopProducts = false;
                    this.productReferenceType = '';
                    this.hasDetails = false;
                    this.clientStatusesPickList = new List<SelectOption>();// 'null' because of use in javascript
                    if(isOrgCPG) {
                        this.clientStatusesPickList.add(new SelectOption('null', Label.Negoptim.Blank));
                        for (Schema.PicklistEntry pickListVal : Negoptim__Assortment_Detail__c.Negoptim__Client_Status__c.getDescribe().getPicklistValues()) {
                            this.clientStatusesPickList.add(new SelectOption(pickListVal.getValue().remove(' '), pickListVal.getLabel()));
                        }
                    }
                    this.clientStatus = '';
                    this.popupGenerateExcel = false;
                    this.assortmentDetailsUpdatedMap = new Map<Id, Negoptim__Assortment_Detail__c>();
                    this.wAssortmentDetailList = new List<CategoryWrapper>();
                    this.initialAssortmentDetailsMap = new Map<Id, Negoptim__Assortment_Detail__c>();
                    this.counts = new Map<Id, Map<String, Integer>>();
                    this.sums = new Map<Id, Map<String, Decimal>>();
                    this.popupSwitchProduct = false;
                    this.singleProductAction = false;
                    this.switchProductsList = new List<SwitchProductWrapper>();
                    this.popupSelectHigherLevelPackaging = false;
                    this.higherLevelPackagingWrapperList = new List<HigherLevelPackagingWrapper>();
                    this.hasHigherLevelPackagingMap = new Map<Id, boolean>();
                    this.assortmentBU.Negoptim__Year__c = this.assortmentBU.Negoptim__Year__c != null ? this.assortmentBU.Negoptim__Year__c : (this.assortmentBU.Negoptim__Ass_EDate__c != null ? this.assortmentBU.Negoptim__Ass_EDate__c.year() : null);
                    this.assortmentBUName = this.assortmentBU.Name;
                    Id assortmentCategoryId = this.assortmentBU.Negoptim__Orga_HE__c == null ? Negoptim.NegoptimHelper.getRootIdByRT('Product') : this.assortmentBU.Negoptim__Orga_HE__c;
                    this.het = new HierarchyElementTree(new Set<Id>{assortmentCategoryId});

                    this.openPagesFilterSectionByDefault = settings != null ? settings.openPagesFilterSectionByDefault : false;
                    this.manageAssortByPersonalizedCategory = settings != null ? settings.manageAssortByPersonalizedCategory : false;
                    /*this.isShowHistory = false;
                    this.includeStores = false;
                    this.includeAllStatus = false;
                    this.oldIncludeAllStatus = false;
                    this.hideBlankStatus =  false;
                    this.showIntroProducts = isTargetMatrix;
                    this.onlyShowIntroProducts = false;
                    this.hideUnitCostGap = !isOrgCPG;
                    this.hideNetPriceGap = !isOrgCPG;

                    /*this.buClustersMap = new Map<String, Map<Integer, Orga_BU__c>>();*/
                    // clustering by category
                    this.categoryBUClustersMap = new Map<Id, List<BUClusterWrapper>>();
                    this.categoryBUCpltMap = new Map<Id, List<BUClusterWrapper>>();
                    this.categoryBUClustersRefMap = new Map<Id, List<BUClusterWrapper>>();
                    this.categoryBUCpltRefMap = new Map<Id, List<BUClusterWrapper>>();

                    if (gridSettingsManager.ERRORS.isEmpty()) {
                        // 1- queries the number of assortment details that aren't validated to disable/enable the validate button
                        // 2- builds a query and initiates the standardSetController
                        // 3- calls fillCategoryTotals() that executes aggregate queries to get subTotals (sums and counts) [this method has to be called
                        //    before getHierarchies() to insure a well structured tree]
                        // 4- calls getHierarchies() that builds the total tree data
                        // 5- calls getAssortmentDetails that sets up the data to be displayed in the grid
                        // this.search();
                        // reset filters method inits all filters to default values and calls search method
                        resetFilters();
                    } else {
                        for (String errorMessage : gridSettingsManager.ERRORS) {
                            System.debug('ERROR>>>> ' + errorMessage);
                            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, errorMessage));
                        }
                    }
                }
            } catch (Exception e) {
                System.debug(e.getStackTraceString());
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
            }
        } else {
            String errorMessage = 'Assortment Id is Null';
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, errorMessage));
        }
        this.isFirstLoad = false;
    }

    /**
     * 
     * @description constructs a query to fetch assortment details based on filters
     * @return String the query
    */
    private String buildAssortmentDetailQuery() {
        List<String> conditions = this.getConditions();
        if (!this.isShowHistory) {
            conditions.add('Negoptim__Version__c = NULL');
        }
        String orderBy = 'Negoptim__Category__r.Negoptim__Path__c, Negoptim__Version__c DESC, Negoptim__Product__r.Name ASC';
        String query = this.gridSettingsManager.buildQuery(null, conditions, orderBy);
        return query;
    }

    /**
     * @param conditions
     * @description constructs the where clause of an SOQL query by returning 'WHERE' followed by each condition in conditions seperated by 'AND'
     * @return String a well structured WHERE clause
    */
    private String buildWhere(List<String> conditions) {
        return ' WHERE ' + String.join(conditions, ' AND ');
    }

    private List<String> getConditions() {
        Id assortmentCategoryId = this.assortmentBU.Negoptim__Orga_HE__c == null ? Negoptim.NegoptimHelper.getRootIdByRT('Product') : this.assortmentBU.Negoptim__Orga_HE__c;
        // Check if het is null because we put it null in getHiearrchies method to reduce the view state
        if (het == null) {
            het = new HierarchyElementTree(new Set<Id>{assortmentCategoryId});
        }
        List<String> conditions = new List<String>();
        conditions.add('RecordType.DeveloperName = \'' + detailRecordType + '\'');
        conditions.add(manageAssortByPersonalizedCategory ? 'Negoptim__Client_Category__c <> null' : 'Negoptim__Category__c <> null');
        if (String.isNotBlank(this.recordId))
            conditions.add('Negoptim__Assortment_BU__c = \'' + String.escapeSingleQuotes(recordId) + '\'');
        if (String.isNotBlank(product.Negoptim__Category__c)) {
            String condition;
            if (het.isAncestor(assortmentCategoryId, product.Negoptim__Category__c)) {
                Negoptim__Orga_HE__c filterCategory = het.allElementsWithParentsMap.get(product.Negoptim__Category__c);
                condition = 'Negoptim__Category__r.Negoptim__Path__c LIKE \'' + String.escapeSingleQuotes(filterCategory.Negoptim__Path__c) + '%\'';
            } else {
                condition = 'Negoptim__Category__c = \'' + String.escapeSingleQuotes(product.Negoptim__Category__c) + '\'';
            }
            conditions.add(condition);
        }
        if (String.isNotBlank(productSearch)) {
            String searchString = String.escapeSingleQuotes(productSearch);
            String condition = '(Negoptim__Product__r.Name LIKE \'%' + searchString + '%\'';
            condition += ' OR Negoptim__Product__r.ProductCode LIKE \'%' + searchString + '%\'';
            if (SObjectType.Product2.fields.Negoptim__Product_EAN__c.isFilterable()) {
                if (!SObjectType.Product2.fields.Negoptim__Product_EAN__c.isEncrypted()) {
                    condition += ' OR Negoptim__Product__r.Negoptim__Product_EAN__c LIKE \'%' + String.escapeSingleQuotes(searchString) + '%\'';
                } else {
                    condition += ' OR Negoptim__Product__r.Negoptim__Product_EAN__c = \'' + String.escapeSingleQuotes(searchString) + '\'';
                }
            }
            condition += ' OR Negoptim__Product__r.Negoptim__VIP__c LIKE \'%' + searchString + '%\'';
            condition += ' OR Negoptim__Category__r.Name LIKE \'%' + searchString + '%\')';
            conditions.add(condition);
        }
        if (String.isNotBlank(clientStatus)) {
            String separator = '-';
            clientStatus = clientStatus.removeStart(separator);
            String str = clientStatus.toLowerCase().replace('probablydeleted', 'probably deleted');
            List<String> filterStatus = new List<String>();
            if (String.isNotBlank(str))
                filterStatus = str.split(separator);
            String condition = '';
            if (filterStatus.contains('null')) {
                condition = 'Negoptim__Client_Status__c = NULL';
                filterStatus.remove(filterStatus.indexOf('null'));
            }
            if (!filterStatus.isEmpty()) {
                List<String> filterStatus_escaped = new List<String>();
                for (String status : filterStatus) {
                    filterStatus_escaped.add(String.escapeSingleQuotes(status));
                }
                if (String.isNotBlank(condition)) {
                    condition = '(' + condition + ' OR Negoptim__Client_Status__c IN (\'' + String.join(filterStatus_escaped, '\',\'') + '\')' + ')';
                } else if (String.isBlank(condition)) {
                    condition = 'Negoptim__Client_Status__c IN (\'' + String.join(filterStatus_escaped, '\',\'') + '\')';
                }
            }
            if (String.isNotBlank(condition))
                conditions.add(condition);
        }
        if (String.isNotBlank(this.productReferenceType) || this.isStopProducts) {
            String productReferenceType_escaped = String.escapeSingleQuotes(this.productReferenceType);
            List<String> selectedReferenceTypesList = new List<String>();
            String productReferenceTypeCondition = '';
            String condition = '';
            String stopProductConditions = '';
            if (String.isNotBlank(productReferenceType_escaped)) {
                for (String str : productReferenceType_escaped.split('-')) {
                    if (str.equals(CommonConstants.PLV_PRODUCT2_PRODUCT_REFERENCE_TYPE_SWITCH) || str.equals(CommonConstants.PLV_PRODUCT2_PRODUCT_REFERENCE_TYPE_RENO)) {
                        selectedReferenceTypesList.add(str);
                    }
                }
            }
            if (!selectedReferenceTypesList.isEmpty()) {
                productReferenceTypeCondition = '(Negoptim__Product__r.Negoptim__Market_End_of_Life_Date__c = NULL OR CALENDAR_YEAR(Negoptim__Product__r.Negoptim__Market_End_of_Life_Date__c) > ' + this.assortmentBU.Negoptim__Year__c + ')';
                productReferenceTypeCondition += ' AND Negoptim__Product__r.Negoptim__Product_Reference_Type__c IN (\'' + String.join(selectedReferenceTypesList, '\',\'') + '\')';
            }
            if(this.isStopProducts) {
                stopProductConditions = 'CALENDAR_YEAR(Negoptim__Product__r.Negoptim__Market_End_of_Life_Date__c) <= ' + this.assortmentBU.Negoptim__Year__c;
            }
            if (!selectedReferenceTypesList.isEmpty() && this.isStopProducts) {
                condition = '((' + productReferenceTypeCondition + ') OR (' + stopProductConditions + '))';
            } else {
                condition = !selectedReferenceTypesList.isEmpty() ? productReferenceTypeCondition : stopProductConditions;
            }
            condition += ' AND Negoptim__Version__c = NULL';
            conditions.add(condition);
        }
        if (this.hideBlankStatus) {
            if (this.showIntroProducts) {
                conditions.add('(Negoptim__Product__r.Negoptim__IsInnovation__c = TRUE OR Negoptim__Product__r.RecordType.DeveloperName = \'' + CommonConstants.RT_PRODUCT2_UNIT_NEED + '\' OR (Negoptim__Client_Status__c != NULL AND Negoptim__Product__r.Negoptim__IsInnovation__c = FALSE AND Negoptim__Product__r.RecordType.developerName <> \'' + CommonConstants.RT_PRODUCT2_UNIT_NEED + '\'))');
            } else {
                conditions.add('Negoptim__Client_Status__c != NULL');
            }
        }
        if (this.onlyShowIntroProducts) {
            conditions.add('(Negoptim__Product__r.RecordType.DeveloperName = \'' + CommonConstants.RT_PRODUCT2_UNIT_NEED + '\' OR CALENDAR_YEAR(Negoptim__Product__r.Negoptim__Market_Introduction_Date__c) = ' + this.assortmentBU.Negoptim__Year__c + ')');
        }
        List<String> gapConditions = new List<String>();
        if(!gapConditions.isEmpty()){
            conditions.add('(' + String.join(gapConditions, ' OR ') + ')');
        }
        if (String.isNotBlank(selectedOperator) && String.isNotBlank(String.valueof(filterDetail.Negoptim__Movement_Date__c))) {
            Date selctedMvtDate = filterDetail.Negoptim__Movement_Date__c;
            conditions.add('Movement_Date__c ' + selectedOperator + ' ' + DateTime.newInstance(selctedMvtDate.year(), selctedMvtDate.month(), selctedMvtDate.day()).format('yyyy-MM-dd'));
        }
        return conditions;
    }

    public void getAssortmentDetails() {
        Set<Id> categoryIds = new Set<Id>();
        this.wAssortmentDetailList = new List<CategoryWrapper>();
        this.initialAssortmentDetailsMap = new Map<Id, Negoptim__Assortment_Detail__c>();
        this.categoryWrapperMap = new Map<Id, CategoryWrapper>();
        Map<Id, ClientStatusWrapper> clientStatusWrapperMap = new Map<Id, ClientStatusWrapper>(); // to serialize
        Integer clusterCount = 0, cpltCount = 0;
        List<Negoptim__Assortment_Detail__c> assortmentDetailsList = (List<Negoptim__Assortment_Detail__c>) this.assortmentDetailStdSetCtrl.getRecords();
        Set<Id> productsIdSet = new Set<Id>();
        if (!assortmentDetailsList.isEmpty()) {
            Map<String, AssortmentDetailWrapper> adwMap = new Map<String, AssortmentDetailWrapper>();
            String key;
            if (isShowHistory) {
                Map<String, List<AssortmentDetailWrapper>> switchHistoMap = new Map<String, List<AssortmentDetailWrapper>>();
                for (Negoptim__Assortment_Detail__c detail : assortmentDetailsList) {
                    key = detail.Negoptim__Product__c + '';
                    if (detail.Negoptim__Version__c == null) {
                        adwMap.put(key, new AssortmentDetailWrapper(detail));
                    } else {
                        if (adwMap.containsKey(key)) {
                            AssortmentDetailWrapper adw = adwMap.get(key);
                            adw.historyList.add(new AssortmentDetailWrapper(detail));
                        } else {
                            if (!switchHistoMap.containsKey(key)) {
                                switchHistoMap.put(key, new List<AssortmentDetailWrapper>());
                            }
                            switchHistoMap.get(key).add(new AssortmentDetailWrapper(detail));
                        }
                    }
                }
                for (AssortmentDetailWrapper adw : adwMap.values()) {
                    adw.sort();
                    Id lastHistoryProductId = adw.detail.Negoptim__Last_History__r.Negoptim__Product__c;
                    if (!adw.historyList.isEmpty()) {
                        lastHistoryProductId = adw.historyList.get(adw.historyList.size() - 1).detail.Negoptim__Last_History__r.Negoptim__Product__c;
                    }
                    key = lastHistoryProductId + '';
                    if (switchHistoMap.containsKey(key)) {
                        adw.switchHistoryList = switchHistoMap.get(key);
                        adw.sort();
                    }
                }
                List<AssortmentDetailWrapper> asdWrapperList = adwMap.values();
            }
            for (Negoptim__Assortment_Detail__c item : assortmentDetailsList) {
                // fill productsIdSet to query HigherLevelPackaging products
                if (this.detailRecordType == CommonConstants.RT_ASSORTMENT_DETAIL_REGULAR && item.Negoptim__Version__c == null) {
                    productsIdSet.add(item.Negoptim__Product__c);
                }
                this.lastModifiedDate = item.Negoptim__Assortment_BU__r.LastModifiedDate;
                categoryIds.add(manageAssortByPersonalizedCategory ? item.Negoptim__Client_Category__c : item.Negoptim__Category__c);
                Negoptim__Assortment_Detail__c initialAssortmentDetail = item.Clone(true);
                if (initialAssortmentDetail.Negoptim__Version__c == null) {
                    initialAssortmentDetail.Negoptim__Movement_Date__c = initialAssortmentDetail.Negoptim__Movement_Date__c == NULL ? Date.today() : initialAssortmentDetail.Negoptim__Movement_Date__c;
                    initialAssortmentDetail.Negoptim__Record_Date__c = initialAssortmentDetail.Negoptim__Record_Date__c == NULL ? initialAssortmentDetail.Negoptim__Movement_Date__c  : initialAssortmentDetail.Negoptim__Record_Date__c;
                }
                CategoryWrapper wAssortmentDetail;
                // fill category wrapper
                initialAssortmentDetail = fillAssortmentDetail(initialAssortmentDetail);
                if (initialAssortmentDetail.Negoptim__Version__c == null) {
                    if(!categoryWrapperMap.containsKey(manageAssortByPersonalizedCategory ? initialAssortmentDetail.Negoptim__Client_Category__c : initialAssortmentDetail.Negoptim__Category__c)) {
                        wAssortmentDetail = new CategoryWrapper(manageAssortByPersonalizedCategory ? initialAssortmentDetail.Negoptim__Client_Category__c : initialAssortmentDetail.Negoptim__Category__c, manageAssortByPersonalizedCategory ? initialAssortmentDetail.Negoptim__Client_Category__r.Name : initialAssortmentDetail.Negoptim__category__r.Name, initialAssortmentDetail);
                    } else {
                        wAssortmentDetail = categoryWrapperMap.get(manageAssortByPersonalizedCategory ? initialAssortmentDetail.Negoptim__Client_Category__c : initialAssortmentDetail.Negoptim__Category__c);
                        wAssortmentDetail.assortmentDetails.add(initialAssortmentDetail);
                    }
                    key = initialAssortmentDetail.Negoptim__Product__c + '';
                    if (adwMap.containsKey(key)) {
                        AssortmentDetailWrapper adw = adwMap.get(key);
                        wAssortmentDetail.assortmentDetails.addAll(adw.getAllHistory());
                    }
                }
                this.initialAssortmentDetailsMap.put(item.Id, item);
                if (wAssortmentDetail == null) {
                    wAssortmentDetail = new CategoryWrapper(manageAssortByPersonalizedCategory ? initialAssortmentDetail.Negoptim__Client_Category__c : initialAssortmentDetail.Negoptim__Category__c, manageAssortByPersonalizedCategory ? initialAssortmentDetail.Negoptim__Client_Category__r.Name : initialAssortmentDetail.Negoptim__category__r.Name);
                }
                if (!categoryWrapperMap.containsKey(manageAssortByPersonalizedCategory ? initialAssortmentDetail.Negoptim__Client_Category__c : initialAssortmentDetail.Negoptim__Category__c)) {
                    categoryWrapperMap.put(manageAssortByPersonalizedCategory ? initialAssortmentDetail.Negoptim__Client_Category__c : initialAssortmentDetail.Negoptim__Category__c, wAssortmentDetail);
                }
                if (!this.categoryNamesMap.containsKey(manageAssortByPersonalizedCategory ? item.Negoptim__Client_Category__c : item.Negoptim__Category__c)) {
                    if (!manageAssortByPersonalizedCategory) {
                        if(item.Negoptim__Category__r.Negoptim__Long_Name_1__c == null || String.isBlank(item.Negoptim__Category__r.Negoptim__Long_Name_1__c)) {
                            if(item.Negoptim__Category__r.Negoptim__Long_Name__c == null || String.isBlank(item.Negoptim__Category__r.Negoptim__Long_Name__c)) {
                                this.categoryNamesMap.put(manageAssortByPersonalizedCategory ? item.Negoptim__Client_Category__c : item.Negoptim__Category__c, item.Negoptim__Category__r.Negoptim__Parent_Element__r.Name);
                            } else {
                                this.categoryNamesMap.put(manageAssortByPersonalizedCategory ? item.Negoptim__Client_Category__c : item.Negoptim__Category__c, manageAssortByPersonalizedCategory ? item.Negoptim__Client_Category__r.Negoptim__Parent_Element__r.Negoptim__Long_Name__c : item.Negoptim__Category__r.Negoptim__Parent_Element__r.Negoptim__Long_Name__c);
                            }
                        } else {
                            this.categoryNamesMap.put(item.Negoptim__Category__c, item.Negoptim__Category__r.Negoptim__Parent_Element__r.Negoptim__Long_Name_1__c);
                        }
                    } else {
                        if(item.Negoptim__Client_Category__r.Negoptim__Long_Name_1__c == null || String.isBlank(item.Negoptim__Client_Category__r.Negoptim__Long_Name_1__c)) {
                            if(item.Negoptim__Client_Category__r.Negoptim__Long_Name__c == null || String.isBlank(item.Negoptim__Client_Category__r.Negoptim__Long_Name__c)) {
                                this.categoryNamesMap.put(manageAssortByPersonalizedCategory ? item.Negoptim__Client_Category__c : item.Negoptim__Category__c, item.Negoptim__Client_Category__r.Negoptim__Parent_Element__r.Name);
                            } else {
                                this.categoryNamesMap.put(manageAssortByPersonalizedCategory ? item.Negoptim__Client_Category__c : item.Negoptim__Category__c, manageAssortByPersonalizedCategory ? item.Negoptim__Client_Category__r.Negoptim__Parent_Element__r.Negoptim__Long_Name__c : item.Negoptim__Client_Category__r.Negoptim__Parent_Element__r.Negoptim__Long_Name__c);
                            }
                        } else {
                            this.categoryNamesMap.put(item.Negoptim__Client_Category__c, item.Negoptim__Client_Category__r.Negoptim__Parent_Element__r.Negoptim__Long_Name_1__c);
                        }
                    }
                }
                if(!this.counts.containsKey(manageAssortByPersonalizedCategory ? item.Negoptim__Client_Category__c : item.Negoptim__Category__c))
                    initTotals(manageAssortByPersonalizedCategory ? item.Negoptim__Client_Category__c : item.Negoptim__Category__c);
            }
            // get Assortment Clusters using NegoptimHelper.getAssortmentBUClustersMap
            AssortmentServices assortmentServices = new AssortmentServices(assortmentDetailsList);
            AssortmentServices.ResultWrapper rw = assortmentServices.getResultWrapperForAssortment(this.assortmentBU.Negoptim__BU_Target__c);
            Map<Id, Map<Integer, Negoptim__Orga_BU__c>> assortmentBUClustersMap = rw.categoryStratMap;
            Map<Id, Map<Integer, Negoptim__Orga_BU__c>> assortmentBUClustersCpltMap = rw.categoryCpltMap;
            Map<Id, Map<Integer, Negoptim__Orga_BU__c>> assortmentBUClustersRefMap = rw.categoryStratRefMap;

            Map<Id, Map<Integer, Negoptim__Orga_BU__c>> assortmentBUClustersCpltRefMap = rw.categoryCpltRefMap;
            Map<Id, Map<Integer, Negoptim__Orga_BU__c>> assortmentBUClosedClustersMap = rw.closedCategoryStratMap;
            Map<Id, Map<Integer, Negoptim__Orga_BU__c>> assortmentBUClosedClustersCpltMap = rw.closedCategoryCpltMap;
            this.clusterNameLength = 0;
            this.maxClusterCount = 0;
            Integer maxCpltCount = 0;
            this.maxClusterCategory = '';
            this.maxCpltCategory = '';
            this.categoryBUClustersMap.clear();
            this.categoryBUCpltMap.clear();
            this.categoryBUClustersRefMap.clear();
            this.categoryBUCpltRefMap.clear();
            Map<Id, List<Integer>> stratsMap = new Map<Id, List<Integer>>();
            Map<Id, List<Integer>> cpltMap = new Map<Id, List<Integer>>();
            Set<Id> categoryIdsSet = new Set<Id>();
            categoryIdsSet.addAll(assortmentBUClustersMap.keySet());
            categoryIdsSet.addAll(assortmentBUClustersRefMap.keySet());
            for (Id categoryId : categoryIdsSet) {
                this.categoryBUClustersMap.put(categoryId, new List<BUClusterWrapper>());
                this.categoryBUCpltMap.put(categoryId, new List<BUClusterWrapper>());
                this.categoryBUClustersRefMap.put(categoryId, new List<BUClusterWrapper>());
                this.categoryBUCpltRefMap.put(categoryId, new List<BUClusterWrapper>());
                stratsMap.put(categoryId, new List<Integer>());
                cpltMap.put(categoryId, new List<Integer>());

                if (assortmentBUClustersMap.get(categoryId) != null) {
                    if (assortmentBUClustersMap.get(categoryId).size() > maxClusterCount) {
                        maxClusterCount = assortmentBUClustersMap.get(categoryId).size();
                        maxClusterCategory = categoryId;
                    }
                    for (Negoptim__Orga_BU__c cluster : assortmentBUClustersMap.get(categoryId).values()) {
                        this.categoryBUClustersMap.get(categoryId).add(new BUClusterWrapper(cluster));
                        stratsMap.get(categoryId).add(Integer.valueOf(cluster.Negoptim__Assortment_Strat__c.right(1)));
                        this.clusterNameLength = cluster.Name.length() > clusterNameLength ? cluster.Name.length() : this.clusterNameLength;
                    }
                }
                if (assortmentBUClosedClustersMap.get(categoryId) != null) {
                    for (Negoptim__Orga_BU__c cluster : assortmentBUClosedClustersMap.get(categoryId).values()) {
                        this.categoryBUClustersMap.get(categoryId).add(new BUClusterWrapper(cluster));
                        this.clusterNameLength = cluster.Name.length() > clusterNameLength ? cluster.Name.length() : this.clusterNameLength;
                    }
                }
                if(assortmentBUClustersRefMap.get(categoryId) != null) {
                    for (Negoptim__Orga_BU__c cluster : assortmentBUClustersRefMap.get(categoryId).values()) {
                        this.categoryBUClustersRefMap.get(categoryId).add(new BUClusterWrapper(cluster));
                    }
                }
                if (assortmentBUClustersCpltMap.get(categoryId) != null) {
                    if (assortmentBUClustersCpltMap.get(categoryId).size() > maxCpltCount) {
                        maxCpltCount = assortmentBUClustersCpltMap.get(categoryId).size();
                        maxCpltCategory = categoryId;
                    }
                    for (Negoptim__Orga_BU__c cluster : assortmentBUClustersCpltMap.get(categoryId).values()) {
                        this.categoryBUCpltMap.get(categoryId).add(new BUClusterWrapper(cluster));
                        cpltMap.get(categoryId).add(Integer.valueOf(cluster.Negoptim__Assortment_Strat__c.right(1)));
                    }
                }
                if (assortmentBUClosedClustersCpltMap.get(categoryId) != null) {
                    for (Negoptim__Orga_BU__c cluster : assortmentBUClosedClustersCpltMap.get(categoryId).values()) {
                        this.categoryBUCpltMap.get(categoryId).add(new BUClusterWrapper(cluster));
                        cpltMap.get(categoryId).add(Integer.valueOf(cluster.Negoptim__Assortment_Strat__c.right(1)));
                    }
                }
                if(assortmentBUClustersCpltRefMap.get(categoryId) != null) {
                    for (Negoptim__Orga_BU__c cluster : assortmentBUClustersCpltRefMap.get(categoryId).values()) {
                        this.categoryBUCpltRefMap.get(categoryId).add(new BUClusterWrapper(cluster));
                    }
                }
            }
            // make sure all categories are included in the make
            // make sure all categories have the same number of elements in the lists
            for (Negoptim__Assortment_Detail__c detail : assortmentDetailsList) {
                Date comaprableDate = Date.today().year() == detail.Negoptim__Assortment_BU__r.Negoptim__Year__c ? Date.today() : detail.Negoptim__Assortment_BU__r.Negoptim__Ass_EDate__c;
                if (!this.categoryBUClustersMap.containskey(manageAssortByPersonalizedCategory ? detail.Negoptim__Client_Category__c : detail.Negoptim__Category__c)) {
                    this.categoryBUClustersMap.put(manageAssortByPersonalizedCategory ? detail.Negoptim__Client_Category__c : detail.Negoptim__Category__c, new List<BUClusterWrapper>());
                    this.categoryBUClustersRefMap.put(manageAssortByPersonalizedCategory ? detail.Negoptim__Client_Category__c : detail.Negoptim__Category__c, new List<BUClusterWrapper>());
                    stratsMap.put(manageAssortByPersonalizedCategory ? detail.Negoptim__Client_Category__c : detail.Negoptim__Category__c, new List<Integer>());
                } else {
                    if (this.categoryBUClustersMap.get(manageAssortByPersonalizedCategory ? detail.Negoptim__Client_Category__c : detail.Negoptim__Category__c).size() < maxClusterCount) {
                        for (Integer i = this.categoryBUClustersMap.get(manageAssortByPersonalizedCategory ? detail.Negoptim__Client_Category__c : detail.Negoptim__Category__c).size(); i < maxClusterCount; i++) {
                            this.categoryBUClustersMap.get(manageAssortByPersonalizedCategory ? detail.Negoptim__Client_Category__c : detail.Negoptim__Category__c).add(new BUClusterWrapper(null));
                            this.categoryBUClustersRefMap.get(manageAssortByPersonalizedCategory ? detail.Negoptim__Client_Category__c : detail.Negoptim__Category__c).add(new BUClusterWrapper(null));
                        }
                    }
                    for(BUClusterWrapper buWrapper : this.categoryBUClustersMap.get(manageAssortByPersonalizedCategory ? detail.Negoptim__Client_Category__c : detail.Negoptim__Category__c)) {
                        if (buWrapper.orgaBU.Negoptim__BU_CDate__c != null && buWrapper.orgaBU.Negoptim__BU_CDate__c > detail.Negoptim__Assortment_BU__r.Negoptim__Ass_BDate__c
                            && buWrapper.orgaBU.Negoptim__BU_CDate__c < detail.Negoptim__Assortment_BU__r.Negoptim__Ass_EDate__c && buWrapper.orgaBU.Negoptim__BU_CDate__c < comaprableDate) {
                                buWrapper.isDisabled = true;
                            } else {
                                buWrapper.isDisabled = false;

                            }
                        if (buWrapper.orgaBU.Negoptim__BU_CDate__c == null
                            || buWrapper.orgaBU.Negoptim__BU_CDate__c != null/* && detail.Movement_Date__c < buWrapper.orgaBU.BU_CDate__c && detail.Movement_Date__c > buWrapper.orgaBU.BU_ODate__c*/) {
                                buWrapper.hasHistory = true;
                            } else {
                                buWrapper.hasHistory = false;
                            }
                    }
                }
                if (!this.categoryBUCpltMap.containskey(manageAssortByPersonalizedCategory ? detail.Negoptim__Client_Category__c : detail.Negoptim__Category__c)) {
                    this.categoryBUCpltMap.put(manageAssortByPersonalizedCategory ? detail.Negoptim__Client_Category__c : detail.Negoptim__Category__c, new List<BUClusterWrapper>());
                    this.categoryBUCpltRefMap.put(manageAssortByPersonalizedCategory ? detail.Negoptim__Client_Category__c : detail.Negoptim__Category__c, new List<BUClusterWrapper>());
                    cpltMap.put(manageAssortByPersonalizedCategory ? detail.Negoptim__Client_Category__c : detail.Negoptim__Category__c, new List<Integer>());
                } else {
                    if (this.categoryBUCpltMap.get(manageAssortByPersonalizedCategory ? detail.Negoptim__Client_Category__c : detail.Negoptim__Category__c).size() < maxCpltCount) {
                        for (Integer i = this.categoryBUCpltMap.get(manageAssortByPersonalizedCategory ? detail.Negoptim__Client_Category__c : detail.Negoptim__Category__c).size(); i < maxCpltCount; i++) {
                            this.categoryBUCpltMap.get(manageAssortByPersonalizedCategory ? detail.Negoptim__Client_Category__c : detail.Negoptim__Category__c).add(new BUClusterWrapper(null));
                            this.categoryBUCpltRefMap.get(manageAssortByPersonalizedCategory ? detail.Negoptim__Client_Category__c : detail.Negoptim__Category__c).add(new BUClusterWrapper(null));
                        }
                    }
                    for(BUClusterWrapper buWrapper : this.categoryBUCpltMap.get(manageAssortByPersonalizedCategory ? detail.Negoptim__Client_Category__c : detail.Negoptim__Category__c)) {
                        if (buWrapper.orgaBU.Negoptim__BU_CDate__c != null && buWrapper.orgaBU.Negoptim__BU_CDate__c > detail.Negoptim__Assortment_BU__r.Negoptim__Ass_BDate__c
                            && buWrapper.orgaBU.Negoptim__BU_CDate__c < detail.Negoptim__Assortment_BU__r.Negoptim__Ass_EDate__c && buWrapper.orgaBU.Negoptim__BU_CDate__c < comaprableDate) {
                                buWrapper.isDisabled = true;
                            } else {
                                buWrapper.isDisabled = false;
                            }
                        if (buWrapper.orgaBU.Negoptim__BU_CDate__c == null
                            || buWrapper.orgaBU.Negoptim__BU_CDate__c != null /* && detail.Movement_Date__c < buWrapper.orgaBU.BU_CDate__c && detail.Movement_Date__c > buWrapper.orgaBU.BU_ODate__c*/) {
                                buWrapper.hasHistory = true;
                            } else {
                                buWrapper.hasHistory = false;
                            }
                    }
                }
                // fill clientStatusWrapperMap
                clientStatusWrapperMap.put(detail.Id, new ClientStatusWrapper(detail, stratsMap, cpltMap, this.dynamicFields, manageAssortByPersonalizedCategory));
            }

            this.clientStatus_serialized = JSON.serialize(clientStatusWrapperMap);
            this.stratsMap_serialized = JSON.serialize(stratsMap);
            this.cpltMap_serialized = JSON.serialize(cpltMap);
            this.wAssortmentDetailList = categoryWrapperMap.values();
        }
        this.categoryBUClustersMap_serialized = JSON.serialize(this.categoryBUClustersMap);
        this.hasDetails = this.wAssortmentDetailList.size() > 0;

        if (!productsIdSet.isEmpty() && isOrgCPG) { // just apply when org not retailer
            List<AggregateResult> results = [SELECT Count(Id) counts, Negoptim__Consumer_Trade_Item__c Consumer_Trade_Item__c
                                            FROM Product2
                                            WHERE  Negoptim__Consumer_Trade_Item__c IN :productsIdSet
                                            AND RecordTypeId = :hlpProductRecordType
                                            GROUP BY Negoptim__Consumer_Trade_Item__c];
            for (AggregateResult result : results) {
                hasHigherLevelPackagingMap.put(String.valueOf(result.get('Consumer_Trade_Item__c')), Integer.valueOf(String.valueOf(result.get('counts'))) > 0);
            }
        }

    }

    /**
     * @description builds the assortment detail grid including headers and totals
    */
    public Component.Apex.PageBlockTable getDynamicPageBlockTable() {
        if (recordId == null) return null;
        if (wAssortmentDetailList.isEmpty()) return null;
        Component.Apex.PageBlockTable dynamicBlockTable = new Component.Apex.PageBlockTable();
        this.displayedFields = new List<GridSettingsManager.FieldWrapper>();
        dynamicBlockTable.expressions.value = '{!group.assortmentDetails}';
        dynamicBlockTable.var = 'item';
        dynamicBlockTable.styleClass = 'slds-table slds-table_cell-buffer slds-no-row-hover slds-table_bordered inner-table';
        for (GridSettingsManager.FieldWrapper fieldWrapper : this.gridSettingsManager.GRID_FIELDS) {
            ColumnWrapper matrixCol = new ColumnWrapper();
            if (fieldWrapper.fieldName.equalsIgnoreCase(Negoptim.NegoptimHelper.normalizeAPIName('Ref_Client_Clust1__c'))) {
                dynamicBlockTable.childComponents.add(matrixCol.getClientClusters('ref', clusterNameLength));
            } else if (fieldWrapper.fieldName.equalsIgnoreCase(Negoptim.NegoptimHelper.normalizeAPIName('Client_Clust1__c'))) {
                dynamicBlockTable.childComponents.add(matrixCol.getClientClusters('new', clusterNameLength));
            } else if (fieldWrapper.fieldName.equalsIgnoreCase(Negoptim.NegoptimHelper.normalizeAPIName('Ref_Client_Clust_Cplt1__c'))) {
                dynamicBlockTable.childComponents.add(matrixCol.getClientCplt('ref', 1));
            } else if (fieldWrapper.fieldName.equalsIgnoreCase(Negoptim.NegoptimHelper.normalizeAPIName('Client_Clust_Cplt1__c'))) {
                dynamicBlockTable.childComponents.add(matrixCol.getClientCplt('new', 1));
            } else if ((fieldWrapper.fieldName.startsWithIgnoreCase(Negoptim.NegoptimHelper.normalizeAPIName('Client_Clust')) || fieldWrapper.fieldName.startsWithIgnoreCase(Negoptim.NegoptimHelper.normalizeAPIName('Ref_Client_Clust')))
                     && fieldWrapper.fieldName.endsWithIgnoreCase('__c'))
            {
                continue;
            } else if(displayField(fieldWrapper.fieldName)) { // check if field should be displayed in grid
                Component.Apex.Column col = matrixCol.getColumn(fieldWrapper, fieldsToSumList.contains(fieldWrapper.fieldName) || fieldsToCountList.contains(fieldWrapper.fieldName));
                if (col != null) {
                    dynamicBlockTable.childComponents.add(col);
                }
            }
        }
        return dynamicBlockTable;
    }

    /**
     * @description resets search filters
    */
    public PageReference resetFilters() {
        this.product.Negoptim__Category__c = null;
        this.productReferenceType = null;
        this.product.Negoptim__IsRenovation__c = false;
        this.isStopProducts = false;
        this.productSearch = '';
        this.isShowHistory = false;
        this.clientStatus = '';
        this.hideBlankStatus = false;
        this.showIntroProducts = isTargetMatrix;
        this.onlyShowIntroProducts = false;
        //this.hideUnitCostGap = !isOrgCPG;
        //this.hideNetPriceGap = !isOrgCPG;
        this.includeStores = false;
        this.includeAllStatus = false;
        this.filterDetail.Negoptim__Movement_Date__c = System.today();
        this.selectedOperator = '';
        return this.search();
    }

    public void first() {
        this.processAfterUpdate(this.processBeforeUpdate().values());
        this.assortmentDetailStdSetCtrl.first();
        this.getAssortmentDetails();
    }

    public void previous() {
        this.processAfterUpdate(this.processBeforeUpdate().values());
        this.assortmentDetailStdSetCtrl.previous();
        this.getAssortmentDetails();
    }

    public void next() {
        this.processAfterUpdate(this.processBeforeUpdate().values());
        this.assortmentDetailStdSetCtrl.next();
        this.getAssortmentDetails();
    }

    public void last() {
        this.processAfterUpdate(this.processBeforeUpdate().values());
        this.assortmentDetailStdSetCtrl.last();
        this.getAssortmentDetails();
    }

    public void refreshPageSize() {
        this.processAfterUpdate(this.processBeforeUpdate().values());
        this.assortmentDetailStdSetCtrl.setPageSize(pageSize);
        this.getAssortmentDetails();
    }

    /**
     * @description checks if the record has changed since it has been loaded
     * by comparing it with it's clone created on load
     * */
    private boolean hasChanged(Negoptim__Assortment_Detail__c originalRecord, Negoptim__Assortment_Detail__c recordOnPage) {
        Map<String, Object> oldValues = originalRecord.getPopulatedFieldsAsMap();
        Map<String, Object> newValues = recordOnPage.getPopulatedFieldsAsMap();
        for(String key: newValues.keySet()) {
            if(newValues.get(key) != oldValues.get(key)
               && ((newValues.get(key) != null && String.isNotBlank(String.valueOf(newValues.get(key))))
                   || (oldValues.get(key) != null && String.isNotBlank(String.valueOf(oldValues.get(key))))))
            {
                return true;
            }
        }
        return false;
    }

    private Map<Id, Negoptim__Assortment_Detail__c> processBeforeUpdate() {
        this.fillAssortmentDetailChanges();
        Map<Id, Negoptim__Assortment_Detail__c> updatedResultsMap = new Map<Id, Negoptim__Assortment_Detail__c>();
        for (CategoryWrapper item : this.wAssortmentDetailList) {
            for(Negoptim__Assortment_Detail__c asd : item.assortmentDetails) {
                if(!this.updatedAssortmentDetailIds.contains(asd.Id)) continue;
                Negoptim__Assortment_Detail__c initialAssortmentDetail;
                if(this.assortmentDetailsUpdatedMap.containsKey(asd.Id)) {
                    initialAssortmentDetail = this.assortmentDetailsUpdatedMap.get(asd.Id);
                } else {
                    initialAssortmentDetail = this.initialAssortmentDetailsMap.get(asd.Id);
                }
                // fill updated assortment details
                if(hasChanged(initialAssortmentDetail, asd) && asd.Negoptim__Version__c == null) {
                    updatedResultsMap.put(asd.Id, asd);
                }
            }
        }
        return updatedResultsMap;
    }

    private void processAfterUpdate(List<Negoptim__Assortment_Detail__c> updatedResults) {
        if (!updatedResults.isEmpty()) {
            Map<Id, Negoptim__Assortment_Detail__c> updatedResultsMap = new Map<Id, Negoptim__Assortment_Detail__c>();
            for (Negoptim__Assortment_Detail__c item : updatedResults) {
                updatedResultsMap.put(item.Id, item);
            }
            // fill total after update formula
            for (CategoryWrapper item : this.wAssortmentDetailList) {
                Id categoryId = item.categoryId;
                Map<String, Integer> categoryCountMap = this.counts.get(categoryId);
                Map<String, Decimal> categorySumMap = this.sums.get(categoryId);
                for(Negoptim__Assortment_Detail__c asd : item.assortmentDetails) {
                    Negoptim__Assortment_Detail__c currentAssortmentDetail, oldAssortmentDetail;
                    if(updatedResultsMap.containsKey(asd.Id)) {
                        currentAssortmentDetail = updatedResultsMap.get(asd.Id);
                        if(this.assortmentDetailsUpdatedMap.containsKey(asd.Id)) {
                            oldAssortmentDetail = this.assortmentDetailsUpdatedMap.get(asd.Id);
                        } else {
                            oldAssortmentDetail = this.initialAssortmentDetailsMap.get(asd.Id);
                        }
                        // add record to map
                        Negoptim__Assortment_Detail__c clonedItem = currentAssortmentDetail.clone(true, true, true, true);
                        this.assortmentDetailsUpdatedMap.put(currentAssortmentDetail.Id, clonedItem);
                    }
                }
            }
        }
    }
    private void fillAssortmentDetailChanges() {
        if(String.isNotBlank(this.assortmentDetailChangesList)) {
            this.updatedAssortmentDetailIds.addAll((Set<Id>)JSON.deserialize(this.assortmentDetailChangesList, Set<Id>.class));
        }
    }

    public PageReference save() {
        this.isFirstLoad = true;
        this.processAfterUpdate(this.processBeforeUpdate().values());
        Map<Id, Negoptim__Assortment_Detail__c> updatedResultsMap = this.assortmentDetailsUpdatedMap;
        Savepoint sp = Database.setSavepoint();
        try {
            if (!updatedResultsMap.isEmpty() || includeAllStatus || (oldIncludeAllStatus != null && oldIncludeAllStatus != includeAllStatus)) {
                // check if another users modified same records
                Negoptim__Assortment_BU__c assortmentBU = [SELECT LastModifiedDate FROM Negoptim__Assortment_BU__c WHERE Id = :this.recordId];
                if(this.lastModifiedDate != assortmentBU.LastModifiedDate) {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.Negoptim.MSG_Record_Modified_By_Another_User));
                    return null;
                }
                // Check Assortment_Detail__c upsert field security
                String[] assortmentDetailFields = new List<String>();
                for (GridSettingsManager.FieldWrapper fieldWrapper : this.gridSettingsManager.GRID_FIELDS) {
                    if(fieldWrapper.isInputField && !fieldWrapper.isCalculated && !fieldWrapper.fieldName.contains('.')) assortmentDetailFields.add(getFieldName(fieldWrapper.fieldName));
                }
                if(!updatedResultsMap.isEmpty() && checkCreatibility(Negoptim__Assortment_Detail__c.SObjectType, assortmentDetailFields)
                   && checkUpdatibility(Negoptim__Assortment_Detail__c.SObjectType, assortmentDetailFields))
                {
                    List<Database.SaveResult> results = Database.update(updatedResultsMap.values(), false);
                    for (Integer i = 0; i < results.size(); i++) {
                        Database.SaveResult result = results.get(i);
                        Negoptim__Assortment_Detail__c assortmentDetail = updatedResultsMap.values().get(i);
                        if (!result.isSuccess()) {
                            String errorMessage = assortmentDetail.Negoptim__Product__r.Name + ' : ';
                            Database.Error[] errors = result.getErrors();
                            for (Database.Error err : errors) {
                                String msg = '' + err.getStatusCode();
                                if (msg.contains('FIELD_CUSTOM_VALIDATION_EXCEPTION')) {
                                    errorMessage += err.getMessage();
                                } else {
                                    errorMessage += err.getFields() + ' : ' + err.getStatusCode() + ' - ' + err.getMessage() + '\n';
                                }
                            }
                            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, errorMessage));
                        }
                    }
                    oldIncludeAllStatus = includeAllStatus;
                    // exist the method if there are any messages added to the list -- on runtime any messages is this case will be an error message
                    if (!ApexPages.getMessages().isEmpty()) {
                        return null;
                    }
                    // get updated record
                    this.assortmentDetailsUpdatedMap.clear();
                    this.refreshData = true;
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, Label.Negoptim.MSG_Modifications_Saved_SF_And_Sequences_Generated));
                }
                this.assortmentDetailChangesList = '';
                this.updatedAssortmentDetailIds.clear();
                this.search();
            } else {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, Label.Negoptim.MSG_Nothing_To_Update));
            }
        } catch (DmlException ex) {
            Database.rollback(sp);
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 'Error:' + ex.getMessage()));
        } catch (Exception ex) {
            Database.rollback(sp);
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 'Error:' + ex.getMessage()));
        }
        this.isFirstLoad = false;
        oldIncludeAllStatus = includeAllStatus;
        return null;
    }

    public PageReference validateAssortment() {
        try {
            //set status of parent and detail
            this.setStatus('Validated');
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, Label.Negoptim.MSG_Assortment_Validated));
            return null;
        } catch(DmlException ex) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getDMLMessage(0)));
            return null;
        } catch(Exception ex) {
            return null;
        }
    }

    public PageReference requestForApproval() {
        try {
            //set status of parent and detail
            this.setStatus('Request for Approval');
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, Label.Negoptim.MSG_Confirm_Request_For_Approval));
            return null;
        } catch(DmlException ex) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getDMLMessage(0)));
            return null;
        } catch(Exception ex) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
            return null;
        }
    }

    // Set Status of Assortment Parent/Details to RFA or Validated
    private void setStatus(String status) {
        Boolean isDataModified = false; // indicates that an update was executed on the assortment bu or details
        // Do not update status to RFA if it's already Validated
        if (this.assortmentBU.Negoptim__Status__c != status && (status == 'Validated' || (status == 'Request for Approval' && this.assortmentBU.Negoptim__Status__c != 'Validated'))) {
            this.assortmentBU.Negoptim__Status__c = status;
            if(checkUpdatibility(Negoptim__Assortment_BU__c.SObjectType, new List<String>{SObjectType.Negoptim__Assortment_BU__c.fields.Negoptim__Status__c.Name})) {
                update this.assortmentBU;
                isDataModified = true;
            }
        } else {
            List<String> statuses = new List<String>{status};
            if (status == 'Request for Approval')
                statuses.add('Validated');
            // Check Assortment_Detail__c field security
            String[] assortmentDetailFields = new String[] {
                SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__Version__c.Name,
                SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__Status__c.Name,
                SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__Category__c.Name,
                SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__Client_Status__c.Name,
                SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__Movement_Date__c.Name,
                SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__Assortment_BU__c.Name
            };
            if (checkAccessibility(Negoptim__Assortment_Detail__c.SObjectType, assortmentDetailFields)) {
                List<Negoptim__Assortment_Detail__c> asds = [SELECT Id
                                                   FROM Negoptim__Assortment_Detail__c
                                                   WHERE Negoptim__Version__c = NULL
                                                   AND Negoptim__Status__c NOT IN :statuses
                                                   AND Negoptim__Category__c <> NULL
                                                   AND Negoptim__Client_Status__c <> NULL
                                                   AND Negoptim__Movement_Date__c <> NULL
                                                   AND Negoptim__Assortment_BU__c = :recordId];
                for (Negoptim__Assortment_Detail__c item : asds) {
                    item.Negoptim__Status__c = status;
                }
                if (!asds.isEmpty()) {
                    if (checkUpdatibility(Negoptim__Assortment_Detail__c.SObjectType, new List<String>{SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__Status__c.Name})) {
                        update asds;
                        isDataModified = true;
                    }
                }
            }
        }
        // refresh data only if there has been a modification in the database
        if (isDataModified) {
            //get the new data
            this.refreshData = true;
            this.search();
        }
    }

    private Negoptim__Assortment_Detail__c fillAssortmentDetail(Negoptim__Assortment_Detail__c item) {
        // check if assortment detail already updated
        if(this.assortmentDetailsUpdatedMap.containsKey(item.Id)) {
            Negoptim__Assortment_Detail__c updatedAssortmentDetail = this.assortmentDetailsUpdatedMap.get(item.Id);
            item = updatedAssortmentDetail.clone(true);
        }
        return item;
    }

    public PageReference search() {
        if (!this.refreshData) {
            this.processAfterUpdate(this.processBeforeUpdate().values());
        } else {
            refreshData = false;
        }
        // Check Assortment_Detail__c field security
        String[] assortmentDetailFields = new String[] {
            SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__Version__c.Name,
            SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__Status__c.Name,
            SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__Category__c.Name,
            SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__Client_Status__c.Name,
            SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__Movement_Date__c.Name,
            SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__Assortment_BU__c.Name
        };
        for(String field : this.gridSettingsManager.ALL_FIELDS) {
            if(!field.contains('.')) assortmentDetailFields.add(getFieldName(field));
        }
        // Check Product2 field security
        String[] productFields = new String[] {
            SObjectType.Product2.fields.Name.Name,
            SObjectType.Product2.fields.Negoptim__Product_Reference_Type__c.Name,
            SObjectType.Product2.fields.Negoptim__IsRenovation__c.Name,
            SObjectType.Product2.fields.ProductCode.Name,
            SObjectType.Product2.fields.Negoptim__Product_EAN__c.Name,
            SObjectType.Product2.fields.Negoptim__VIP__c.Name,
            SObjectType.Product2.fields.Negoptim__Market_End_of_Life_Date__c.Name
        };
        // Check Orga_HE__c field security
        String[] orgaHEFields = new String[] {
            SObjectType.Negoptim__Orga_HE__c.fields.Name.Name,
            SObjectType.Negoptim__Orga_HE__c.fields.Negoptim__Path__c.Name
        };
        this.assortmentDetailStdSetCtrl = new ApexPages.StandardSetController(new List<Negoptim__Assortment_Detail__c>());
        if(checkAccessibility(Negoptim__Assortment_Detail__c.SObjectType, assortmentDetailFields)
           && checkAccessibility(Product2.SObjectType, productFields)
           && checkAccessibility(Negoptim__Orga_HE__c.SObjectType, orgaHEFields))
        {
            // get the number of assortment details that are in preparation
            this.nbASDinPreparation = [SELECT COUNT() FROM Negoptim__Assortment_Detail__c
                                       WHERE Negoptim__Version__c = NULL
                                       AND Negoptim__Category__c <> NULL
                                       AND Negoptim__Client_Status__c <> NULL
                                       AND Negoptim__Status__c = :CommonConstants.PLV_ASSORTMENT_DETAIL_STATUS_IN_PREPARATION
                                       AND Negoptim__Assortment_BU__c = :recordId];
            this.nbASDRequestApproval = [SELECT COUNT() FROM Negoptim__Assortment_Detail__c
                                         WHERE Negoptim__Version__c = NULL
                                         AND Negoptim__Category__c <> NULL
                                         AND Negoptim__Client_Status__c <> NULL
                                         AND Negoptim__Movement_Date__c <> NULL
                                         AND Negoptim__Status__c = :CommonConstants.PLV_ASSORTMENT_DETAIL_STATUS_REQUEST_FOR_APPROVAL
                                         AND Negoptim__Assortment_BU__c = :recordId];


            String query = this.buildAssortmentDetailQuery();
            this.assortmentDetailStdSetCtrl = new ApexPages.StandardSetController(Database.getQueryLocator(query));
            // get switch products count
            String countQuery = 'SELECT Count()';
            countQuery += ' FROM Negoptim__Assortment_Detail__c';
            List<String> conditions = this.getConditions();
            conditions.add('Negoptim__Product__r.Negoptim__Product_Reference_Type__c = \'' + CommonConstants.PLV_PRODUCT2_PRODUCT_REFERENCE_TYPE_SWITCH + '\'');
            conditions.add('Negoptim__Product__r.Negoptim__IsRenovation__c = FALSE');
            conditions.add('Negoptim__Version__c = NULL');
            countQuery += this.buildWhere(conditions);
            productSwitchCount = Database.countQuery(countQuery);
            /*String message = String.format(System.Label.MSG_Product_Waiting_For_Switch, new List<String>{String.valueOf(productSwitchCount)});
            message += '<button class="switchAllBtn" onclick="showMultipleSwitchPopup();">' + Label.Switch_All + '</button>';
            if (productSwitchCount > 0) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, message));
            }*/
        }
        this.noOfRecords = assortmentDetailStdSetCtrl.getResultSize();
        assortmentDetailStdSetCtrl.setPageSize(this.pageSize);

        this.fillCategoryTotals();
        if (this.isFirstLoad) {
            this.getHierarchies();
        }
        this.getAssortmentDetails();
        return null;
    }

    private List<AggregateResult> getCountByCategory(String fieldName) {
        // Check Assortment_Detail__c field security
        String[] assortmentDetailFields = new String[] {
            fieldName,
            SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__Product__c.Name,
            SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__Category__c.Name,
            SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__Version__c.Name,
            SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__Client_Status__c.Name,
            SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__Assortment_BU__c.Name
        };
        // Check Product2 field security
        String[] productFields = new String[] {
            SObjectType.Product2.fields.Name.Name,
                SObjectType.Product2.fields.Negoptim__Product_Reference_Type__c.Name,
                SObjectType.Product2.fields.Negoptim__IsRenovation__c.Name,
                SObjectType.Product2.fields.ProductCode.Name,
                SObjectType.Product2.fields.Negoptim__Product_EAN__c.Name,
                SObjectType.Product2.fields.Negoptim__VIP__c.Name,
                SObjectType.Product2.fields.Negoptim__Market_End_of_Life_Date__c.Name
                };
        // Check Orga_HE__c field security
        String[] orgaHEFields = new String[] {
            SObjectType.Negoptim__Orga_HE__c.fields.Name.Name,
                SObjectType.Negoptim__Orga_HE__c.fields.Negoptim__Path__c.Name
        };
        if (checkAccessibility(Negoptim__Assortment_Detail__c.SObjectType, assortmentDetailFields)
           && checkAccessibility(Product2.SObjectType, productFields)
           && checkAccessibility(Negoptim__Orga_HE__c.SObjectType, orgaHEFields))
        {
            String fieldName_escaped = String.escapeSingleQuotes(fieldName);
            String query = 'SELECT ' + (manageAssortByPersonalizedCategory ? 'Negoptim__Client_Category__c Negoptim__Client_Category__c' : 'Negoptim__Category__c Negoptim__Category__c') + ' , COUNT(Id) ' + fieldName_escaped + ' FROM Negoptim__Assortment_Detail__c ';
            List<String> conditions = this.getConditions();
            conditions.add(fieldName_escaped + ' = TRUE');
            conditions.add('Negoptim__Version__c = NULL');
            if (!this.includeAllStatus) {
                String condition = 'Negoptim__Client_Status__c NOT IN (NULL, \'' + CommonConstants.PLV_ASSORTMENT_DETAIL_CLIENT_STATUS_OPPORTUNITY + '\', \'' + CommonConstants.PLV_ASSORTMENT_DETAIL_CLIENT_STATUS_PROBABLY_DELETED + '\')';
                conditions.add(condition);
            }
            query += this.buildWhere(conditions);
            query += manageAssortByPersonalizedCategory ? ' Group BY Negoptim__Client_Category__c' : ' Group BY Negoptim__Category__c';
            return Database.query(query);
        } else {
            return null;
        }
    }

    private void fillCategoryTotals() {
        this.counts.clear();
        this.sums.clear();
        this.categoryNamesMap.clear();
        // Check Assortment_Detail__c field security
        String[] assortmentDetailFields = new String[] {
            SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__Product__c.Name,
            SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__Category__c.Name,
            SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__Version__c.Name,
            SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__Client_Status__c.Name,
            SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__Assortment_BU__c.Name
        };
        // Check Product2 field security
        String[] productFields = new String[] {
            SObjectType.Product2.fields.Name.Name,
            SObjectType.Product2.fields.Negoptim__Product_Reference_Type__c.Name,
            SObjectType.Product2.fields.Negoptim__IsRenovation__c.Name,
            SObjectType.Product2.fields.ProductCode.Name,
            SObjectType.Product2.fields.Negoptim__Product_EAN__c.Name,
            SObjectType.Product2.fields.Negoptim__VIP__c.Name,
            SObjectType.Product2.fields.Negoptim__Market_End_of_Life_Date__c.Name
        };
        // Check Orga_HE__c field security
        String[] orgaHEFields = new String[] {
            SObjectType.Negoptim__Orga_HE__c.fields.Name.Name,
            SObjectType.Negoptim__Orga_HE__c.fields.Negoptim__Path__c.Name
        };
        List<String> sumAggregations = new List<String>();
        for (String field : this.fieldsToSumList) {
            String field_escaped = String.escapeSingleQuotes(field);
            sumAggregations.add('SUM(' + field_escaped + ') ' + field_escaped);
            assortmentDetailFields.add(field_escaped);
        }
        String aggregateQuery = 'SELECT ' + (manageAssortByPersonalizedCategory ? 'Negoptim__Client_Category__c Negoptim__Client_Category__c' : 'Negoptim__Category__c Negoptim__Category__c');
        if (!sumAggregations.isEmpty()) aggregateQuery += ',' + String.join(sumAggregations, ',');
        aggregateQuery += ' FROM Negoptim__Assortment_Detail__c';
        List<String> conditions = this.getConditions();
        conditions.add('Negoptim__Version__c = NULL');
        if (!this.includeAllStatus) {
            String condition = 'Negoptim__Client_Status__c NOT IN (NULL, \'' + CommonConstants.PLV_ASSORTMENT_DETAIL_CLIENT_STATUS_OPPORTUNITY + '\', \'' + CommonConstants.PLV_ASSORTMENT_DETAIL_CLIENT_STATUS_PROBABLY_DELETED + '\')';
            conditions.add(condition);
        }
        aggregateQuery += this.buildWhere(conditions);
        aggregateQuery += manageAssortByPersonalizedCategory ? ' Group BY Negoptim__Client_Category__c' : ' Group BY Negoptim__Category__c';
        // to garantee that all categories are in counts and sums maps
        if (checkAccessibility(Negoptim__Assortment_Detail__c.SObjectType, assortmentDetailFields)
           && checkAccessibility(Product2.SObjectType, productFields)
           && checkAccessibility(Negoptim__Orga_HE__c.SObjectType, orgaHEFields))
        {
            for (AggregateResult item : Database.query(aggregateQuery)) {
                Id categoryId = (Id) item.get(manageAssortByPersonalizedCategory ? 'Negoptim__Client_Category__c' : 'Negoptim__Category__c');
                initTotals(categoryId);
                Map<String, Decimal> categorySumMap = this.sums.get(categoryId);
                if (categorySumMap != null) {
                    for (String fieldname : categorySumMap.keySet()) {
                        Decimal value = item.get(fieldname) != null ? Decimal.valueOf(String.valueOf((item.get(fieldname)))) : 0;
                        categorySumMap.put(fieldname, value);
                    }
                }
            }
            // fill counts by category
            // querying counts -- it could be up to 6 * nbClientClusterFields queries
            List<Map<String, List<AggregateResult>>> aggregateMapList = new List<Map<String, List<AggregateResult>>>();
            String key;
            List<AggregateResult> value;

            for (String field : this.fieldsToCountList) {
                value = this.getCountByCategory(field);
                aggregateMapList.add(new Map<String, List<AggregateResult>> {field => value});
            }

            for (Map<String, List<AggregateResult>> item : aggregateMapList) {
                for (String fieldname : item.keySet()) {
                    for (AggregateResult ar : item.get(fieldname)) {
                        Id categoryId = (Id) String.valueOf(ar.get(manageAssortByPersonalizedCategory ? 'Negoptim__Client_Category__c' : 'Negoptim__Category__c'));
                        Map<String, Integer> categoryCountMap = this.counts.get(categoryId);
                        Integer count = ar.get(fieldname) != null ? Integer.valueOf(String.valueOf(ar.get(fieldname))) : 0;
                        categoryCountMap.put(fieldname, count);
                    }
                }
            }
        }
    }

    private void initTotals (Id categoryId) {
        Map<String, Integer> categoryCountMap = new Map<String, Integer>();
        Map<String, Decimal> categorySumMap = new Map<String, Decimal>();
        // initial Count fields
        for(String str : this.fieldsToCountList) {
            categoryCountMap.put(str, 0);
        }
        // initial Sums fields
        for(String str : this.fieldsToSumList) {
            categorySumMap.put(str, 0);
        }
        this.counts.put(categoryId, categoryCountMap);
        this.sums.put(categoryId, categorySumMap);
    }

    // Get category hierarchies
    public void getHierarchies() {
        Map<Id, CategoryTreeWrapper> categoryTreeMap = new Map<Id, CategoryTreeWrapper>();
        Map<Id, CategoryTreeWrapper> hierarchyTree = new Map<Id, CategoryTreeWrapper>();
        if (!het.allElementsList.isEmpty()) {
            for (Negoptim__Orga_HE__c item : het.allElementsList) {
                fillParentCategoriesTotal(item.Negoptim__Parent_Element__c, item.Id);
            }
            // navigate inversely from top level
            Integer rootLevel = (Integer) het.allElementsList[het.allElementsList.size() - 1].Negoptim__Level__c;
            for (Integer i = het.allElementsList.size() - 1; i >= 0; i--) {
                Negoptim__Orga_HE__c item = het.allElementsList.get(i);
                item.Name = item.Name.escapeHtml4().escapeEcmaScript(); // handling possible Stored XSS attack
                CategoryTreeWrapper node = new CategoryTreeWrapper();
                CategoryTreeWrapper parentNode = hierarchyTree.get(item.Negoptim__Parent_Element__c);
                node.title = item.Negoptim__Level__c == rootLevel ? 'TOTAL' : item.Name;
                node.key = item.Id;
                node.folder = item.Negoptim__Level__c <= rootLevel + 1;
                node.counts = this.counts.get(item.Id);
                node.sums = this.sums.get(item.Id);
                if (parentNode != null) {
                    node.path = parentNode.path + '' + item.Id;
                    node.parentId = item.Negoptim__Parent_Element__c;
                } else {
                    node.path = item.Id;
                    categoryTreeMap.put(item.Id, node);
                }
                hierarchyTree.put(item.Id, node);
            }
            for (Negoptim__Orga_HE__c item : het.allElementsList) {
                if (hierarchyTree.containsKey(item.Negoptim__Parent_Element__c)) {
                    hierarchyTree.get(item.Negoptim__Parent_Element__c).children.add(hierarchyTree.get(item.Id));
                }
            }
        }
        this.jsonCategoryTree = JSON.serialize(categoryTreeMap.values());
        // put the het null to reduce the view state
        this.het = null;
    }

    private void fillParentCategoriesTotal(Id parentCategoryId, Id subCategoryId) {
        if(!this.counts.containsKey(parentCategoryId)) {
            initTotals(parentCategoryId);
        }
        if(!this.counts.containsKey(subCategoryId)) {
            initTotals(subCategoryId);
        }
        // fill total sum
        Map<String, Decimal> parentCategorySumMap = this.sums.get(parentCategoryId);
        Map<String, Decimal> subCategorySumMap = this.sums.get(subCategoryId);
        for (String fieldname : parentCategorySumMap.keySet()) {
            Decimal total = parentCategorySumMap.get(fieldname) != null ? parentCategorySumMap.get(fieldname) : 0;
            Decimal value = subCategorySumMap.get(fieldname) != null ? subCategorySumMap.get(fieldname) : 0;
            parentCategorySumMap.put(fieldname, total + value);
        }
        // fill total count
        Map<String, Integer> parentCategoryCountMap = this.counts.get(parentCategoryId);
        Map<String, Integer> subCategoryCountMap = this.counts.get(subCategoryId);
        for (String fieldname : parentCategoryCountMap.keySet()) {
            Integer total = parentCategoryCountMap.get(fieldname) != null ? parentCategoryCountMap.get(fieldname) : 0;
            total = total + (subCategoryCountMap.get(fieldname) != null ? subCategoryCountMap.get(fieldname) : 0);
            parentCategoryCountMap.put(fieldname, total);
        }
    }

    @RemoteAction
    public static Negoptim__Assortment_Detail__c evaluateAssortmentDetail(String evaluateAssortmentDetail_json, String fieldsToSum_serialized, String formulaFields_serialized) {
        List<String> fieldsToSum = (List<String>) JSON.deserialize(fieldsToSum_serialized, List<String>.class);
        List<String> formulaFields = (List<String>) JSON.deserialize(formulaFields_serialized, List<String>.class);
        Negoptim__Assortment_Detail__c evaluateAssortmentDetail = (Negoptim__Assortment_Detail__c) JSON.deserialize(evaluateAssortmentDetail_json, Negoptim__Assortment_Detail__c.class);
        SavePoint sp = Database.setSavepoint();
        evaluateAssortmentDetail.Negoptim__Force_Update__c = true;
        // check security on update Assortment_Detail__c
        String[] assortmentDetailFields = new String[] // include all possible updatable fields because of grid settings
        {
            SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__Force_Update__c.Name,
            SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__Client_Status__c.Name,
            SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__Client_Clust1__c.Name,
            SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__Client_Clust2__c.Name,
            SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__Client_Clust3__c.Name,
            SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__Client_Clust4__c.Name,
            SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__Client_Clust5__c.Name,
            SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__Client_Clust6__c.Name,
            SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__Ass_BU_Cluster__c.Name,
            SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__Movement_Date__c.Name,
            SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__Status__c.Name,
			SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__Key_Note__c.Name,
			SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__Record_date__c.Name,
			SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__Release_Date__c.Name,
            SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__New_Client_ProductNumber__c.Name
        };
        if(Negoptim.NegoptimHelper.checkUpdatibility(Negoptim__Assortment_Detail__c.SObjectType, assortmentDetailFields)) {
            try {
                update evaluateAssortmentDetail;
            } catch (DmlException ex) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 'Error:' + ex.getMessage() + ' - ' + ex.getLineNumber()));
            }
        }
        String query = 'SELECT Id, Negoptim__Product__c, Negoptim__Category__c, Negoptim__Assortment_BU__c';
        if (!fieldsToSum.isEmpty()) {
            query += ',' + String.join(fieldsToSum, ',');
        }
        if (!formulaFields.isEmpty()) {
            query += ',' + String.join(formulaFields, ',');
        }
        query += ' FROM Negoptim__Assortment_Detail__c';
        query += ' WHERE Id = \'' + evaluateAssortmentDetail.Id + '\'';
        String[] accessFields = new String[] {
            SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__Product__c.Name,
            SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__Category__c.Name,
            SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__Assortment_BU__c.Name
        };
        Negoptim__Assortment_Detail__c evaluationResults;
        if (Negoptim.NegoptimHelper.checkAccessibility(Negoptim__Assortment_Detail__c.SObjectType, accessFields)) {
            evaluationResults = Database.query(query);
        }
        Database.rollback(sp);
        return evaluationResults;
    }

    /**
     * @description switch single of multiple products
     * @return PageReference : Null
    */
    public void switchProduct() {
        List<Negoptim__Assortment_Detail__c> toUpdateList = new List<Negoptim__Assortment_Detail__c>();
        Map<Id, Id> newOldproductsMap = new Map<Id, Id>();
        for (SwitchProductWrapper item : switchProductsList) {
            if (item.isSelected) {
                newOldproductsMap.put(item.newProductId, item.assortmentDetail.Negoptim__Product__c);
                item.assortmentDetail.Negoptim__Product__c = item.newProductId;
                toUpdateList.add(item.assortmentDetail);
            }
        }
        try {
            // check security on update Assortment_Detail__c
            String[] assortmentDetailFields = new String[] {
                SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__Product__c.Name
            };
            if(checkUpdatibility(Negoptim__Assortment_Detail__c.SObjectType, assortmentDetailFields)) {
                update toUpdateList;
            }
            // To auto display history lines after switch product
            isShowHistory = true;
            // get updated record
            this.assortmentDetailsUpdatedMap.clear();
            this.refreshData = true;
            this.search();
        } catch (Exception ex) {
            for (SwitchProductWrapper item : switchProductsList) {
                if (item.isSelected) {
                    item.assortmentDetail.Negoptim__Product__c = newOldproductsMap.get(item.newProductId);
                }
            }
            ////ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
        }
    }

    /**
     * @description stop a product in the assortment
    */
    /*public void stopProducts() {
        List<Product_Assortment_Introduction_History__c> historyList = new List<Product_Assortment_Introduction_History__c>();
        for (StopProductWrapper item : stopProductsList) {
            if (item.isSelected) {
                item.history.Load_Status__c = CommonConstants.PLV_PRODUCT_ASSORTMENT_INTRODUCTION_HISTORY_LOAD_STATUS_YES;
                item.history.Application_Date__c = Date.today();
                historyList.add(item.history);
            }
        }
        try {
            // check security on update Product_Assortment_Introduction_History__c
            String[] productHistoryFields = new String[] {
                SObjectType.Product_Assortment_Introduction_History__c.fields.Load_Status__c.Name,
                SObjectType.Product_Assortment_Introduction_History__c.fields.Application_Date__c.Name
            };
            if(checkUpdatibility(Product_Assortment_Introduction_History__c.SObjectType, productHistoryFields)) {
                update historyList;
            }
            isShowHistory = true;
            // get updated record
            this.assortmentDetailsUpdatedMap.clear();
            this.refreshData = true;
            this.search();
        } catch (DMLException ex) {
        }
    }   */

    public PageReference showPopup() {
        if (this.popupSwitchProduct) {
            switchProductsList.clear();
            Map<Id, Negoptim__Assortment_Detail__c> productAssortmentMap = new Map<Id, Negoptim__Assortment_Detail__c>();
            if (!singleProductAction) {
                List<String> conditions = this.getConditions();
                conditions.add('Negoptim__Product__r.Negoptim__Product_Reference_Type__c = \'' + CommonConstants.PLV_PRODUCT2_PRODUCT_REFERENCE_TYPE_SWITCH + '\'');
                conditions.add('Negoptim__Version__c = NULL');
                String query = this.gridSettingsManager.buildQuery(null, conditions, null);
                /*
                String query = 'SELECT Product__c, Client_Status__c, Status__c, Movement_Date__c';
                query += ' FROM Assortment_Detail__c';
                List<String> conditions = this.getConditions();
                conditions.add('Product__r.Product_Reference_Type__c = \'Switch\'');
                conditions.add('Version__c = NULL');
                query += this.buildWhere(conditions);
                */
                // check security on access Assortment_Detail__c fields
                String[] assortmentDetailFields = new String[] {
                    SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__Product__c.Name,
                    SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__Version__c.Name
                };
                // check security on access product fields
                String[] productFields = new String[] {SObjectType.Product2.fields.Negoptim__Product_Reference_Type__c.Name};
                if(checkAccessibility(Negoptim__Assortment_Detail__c.SObjectType, assortmentDetailFields) && checkAccessibility(Product2.SObjectType, productFields)) {
                    for (Negoptim__Assortment_Detail__c assortmentDetail : Database.query(query)) {
                        productAssortmentMap.put(assortmentDetail.Negoptim__Product__c, assortmentDetail);
                    }
                }
            } else {
                if (!categoryWrapperMap.containsKey(assortmentDetailCategory)) return null;
                Negoptim__Assortment_Detail__c assortmentDetail;
                CategoryWrapper adw = categoryWrapperMap.get(assortmentDetailCategory);
                for (Negoptim__Assortment_Detail__c item : adw.assortmentDetails) {
                    if (item.Id == this.assortmentDetailId) {
                        assortmentDetail = item;
                        break;
                    }
                }
                productAssortmentMap.put(assortmentDetail.Negoptim__Product__c, assortmentDetail);
                for (Schema.PicklistEntry pe: this.productReferenceTypePicklistValues) {
                    if (pe.getValue().equals(assortmentDetail.Negoptim__Product__r.Negoptim__Product_Reference_Type__c)) {
                        this.popupTitle = pe.getLabel();
                    }
                }
            }
            // check security on access product fields
            String[] productFields = new String[] {
                SObjectType.Product2.fields.Name.Name,
                SObjectType.Product2.fields.Negoptim__Reference_Product__c.Name,
                SObjectType.Product2.fields.Negoptim__Category__c.Name
            };
            // check security on access Orga_HE__c fields
            String[] orgaHEFields = new String[] {
                SObjectType.Negoptim__Orga_HE__c.fields.Name.Name
            };
            if (checkAccessibility(Product2.SObjectType, productFields) && checkAccessibility(Negoptim__Orga_HE__c.SObjectType, orgaHEFields)) {
                for (Product2 item : [SELECT Name, Negoptim__Reference_Product__c, Negoptim__Reference_Product__r.Name
                                      FROM Product2
                                      WHERE Negoptim__Reference_Product__c IN :productAssortmentMap.keySet()
                                      ORDER BY Negoptim__Category__r.Name, Name ASC])
                    switchProductsList.add(new SwitchProductWrapper(item.Negoptim__Reference_Product__r.Name, item.Id, item.Name, productAssortmentMap.get(item.Negoptim__Reference_Product__c)));
            }
        }

        if (this.popupSelectHigherLevelPackaging) {
            if (String.isNotBlank(this.productToSelectedHigherLevelPackaging)) {
                Negoptim__Assortment_Detail__c asd;
                String[] productFields = new String[] {
                    SObjectType.Product2.fields.Id.Name,
                    SObjectType.Product2.fields.Name.Name,
                    SObjectType.Product2.fields.Negoptim__Product_EAN__c.Name,
                    SObjectType.Product2.fields.ProductCode.Name,
					SObjectType.Product2.fields.Negoptim__Element_nb__c.Name,
                    SObjectType.Product2.fields.Negoptim__IsMaster_Higher_Level_Packaging__c.Name
                };
                String[] assortmentDetailFields = new String[] {
                    SObjectType.Negoptim__Assortment_Detail__c.fields.Id.Name,
                    SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__Product__c.Name,
                    SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__Client_Status__c.Name,
                    SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__Ass_BU_Cluster__c.Name,
                    SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__Status__c.Name,
                    SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__Client_Ass__c.Name,
                    SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__IsMaster_Higher_Level_Packaging__c.Name
                };
                if (checkAccessibility(Negoptim__Assortment_Detail__c.SObjectType, assortmentDetailFields) && checkAccessibility(Product2.SObjectType, productFields)) {
                    // get the info of the assortment detail to clone
                    List<Negoptim__Assortment_Detail__c> asdList = [SELECT Id, Negoptim__Product__r.Name, Negoptim__Client_Status__c, Negoptim__Ass_BU_Cluster__c, Negoptim__Status__c, Negoptim__Client_Ass__c, Negoptim__Movement_Date__c,
                                                          Negoptim__Client_Clust1__c, Negoptim__Client_Clust2__c, Negoptim__Client_Clust3__c, Negoptim__Client_Clust4__c, Negoptim__Client_Clust5__c, Negoptim__Client_Clust6__c, Negoptim__Client_Clust7__c, Negoptim__Client_Clust8__c,
                                                          Negoptim__Client_Clust_Cplt1__c, Negoptim__Client_Clust_Cplt2__c, Negoptim__Client_Clust_Cplt3__c, Negoptim__Client_Clust_Cplt4__c, Negoptim__Client_Clust_Cplt5__c, Negoptim__Client_Clust_Cplt6__c, Negoptim__Client_Clust_Cplt7__c, Negoptim__Client_Clust_Cplt8__c,
                                                          Negoptim__Assortment_BU__c
                                                          FROM Negoptim__Assortment_Detail__c
                                                          WHERE Negoptim__Product__c = :this.productToSelectedHigherLevelPackaging
                                                          AND Negoptim__Assortment_BU__c = :this.recordId
                                                          AND Negoptim__Version__c = NULL
                                                          AND RecordType.DeveloperName = :CommonConstants.RT_ASSORTMENT_DETAIL_REGULAR
                                                          LIMIT 1];
                    if (!asdList.isEmpty()) {
                        this.higherLevelPackagingMasterDetail = asdList[0];
                        HigherLevelPackagingWrapper defaulHigherLevelPackagingWrapper = null;
                        for (Product2 higherLevelPackaging : [SELECT Id, Name, Negoptim__Product_EAN__c, ProductCode, Negoptim__IsMaster_Higher_Level_Packaging__c, Negoptim__Element_nb__c,
                                                              (SELECT Id, Negoptim__IsMaster_Higher_Level_Packaging__c FROM Negoptim__Assortment_BU_Details__r
                                                               WHERE Negoptim__Assortment_BU__c = :this.recordId
                                                               AND Negoptim__Version__c = NULL
                                                               AND RecordType.DeveloperName = :CommonConstants.RT_ASSORTMENT_DETAIL_HIGHER_LEVEL_PACKAGING
                                                               LIMIT 1)
                                                              FROM Product2
                                                              WHERE Negoptim__Consumer_Trade_Item__c = :this.productToSelectedHigherLevelPackaging
                                                              AND RecordTypeId = :hlpProductRecordType
                                                              ORDER BY Negoptim__IsMaster_Higher_Level_Packaging__c DESC, Name])
                        {
                            asd = higherLevelPackaging.Negoptim__Assortment_BU_Details__r.isEmpty() ? null : higherLevelPackaging.Negoptim__Assortment_BU_Details__r[0];
                            HigherLevelPackagingWrapper hlpw = new HigherLevelPackagingWrapper(higherLevelPackaging, asd);
                            this.higherLevelPackagingWrapperList.add(hlpw);
                            if (defaulHigherLevelPackagingWrapper == null && higherLevelPackaging.Negoptim__IsMaster_Higher_Level_Packaging__c) {
                                defaulHigherLevelPackagingWrapper = hlpw;
                            }
                        }
                        Boolean noneAreSelected = true;
                        for (HigherLevelPackagingWrapper item : this.higherLevelPackagingWrapperList) {
                            if (item.isSelected) {
                                noneAreSelected = false;
                                break;
                            }
                        }
                        if (noneAreSelected && defaulHigherLevelPackagingWrapper != null) {
                            defaulHigherLevelPackagingWrapper.isSelected = true;
                            defaulHigherLevelPackagingWrapper.isMasterHigherLevelPackagingDetail = true;
                        }
                    }
                }
            }
        }
        return null;
    }

    public void cancelPopup() {
        this.popupGenerateExcel = false;
        if (this.popupSelectHigherLevelPackaging) {
            this.popupSelectHigherLevelPackaging = false;
            this.higherLevelPackagingWrapperList.clear();
            this.productToSelectedHigherLevelPackaging = null;
            this.higherLevelPackagingMasterDetail = null;
        }
    }

    /**
     * @description this method creates, updates or deletes Assortment Details of type Higher_Level_Packaging
     * related to a certain product
	*/
    public void saveHigherLevelPackagingSelection() {
        List<Negoptim__Assortment_Detail__c> detailsToUpsert = new List<Negoptim__Assortment_Detail__c>();
        List<Negoptim__Assortment_Detail__c> detailsToDelete = new List<Negoptim__Assortment_Detail__c>();
        for (HigherLevelPackagingWrapper item : higherLevelPackagingWrapperList) {
            if (item.isSelected
                && item.higherLevelPackagingDetail != null
                && item.isMasterHigherLevelPackagingDetail != item.higherLevelPackagingDetail.Negoptim__IsMaster_Higher_Level_Packaging__c)
            {
                // update detail
                item.higherLevelPackagingDetail.Negoptim__IsMaster_Higher_Level_Packaging__c = item.isMasterHigherLevelPackagingDetail;
                detailsToUpsert.add(item.higherLevelPackagingDetail);
            } else if (item.isSelected && item.higherLevelPackagingDetail == null) { // handle insert
                // create a new detail
                Negoptim__Assortment_Detail__c detail;
                if (item.isMasterHigherLevelPackagingDetail) {
                    detail = this.higherLevelPackagingMasterDetail.clone(false, true, false, false);
                } else {
                    detail = new Negoptim__Assortment_Detail__c(Negoptim__Assortment_BU__c = this.recordId);
                }
                detail.Negoptim__Product__c = item.higherLevelPackaging.Id;
                detail.RecordTypeId = ASD_Higer_Level_Packagin_RT_Id;
                detail.Negoptim__IsMaster_Higher_Level_Packaging__c = item.isMasterHigherLevelPackagingDetail;
                detail.Negoptim__Movement_Date__c = this.assortmentBU.Negoptim__Ass_BDate__c;
                detailsToUpsert.add(detail);
            } else if (!item.isSelected && item.higherLevelPackagingDetail != null) { // handle delete
                // delete detail
                detailsToDelete.add(item.higherLevelPackagingDetail);
            }
        }
        if (!detailsToDelete.isEmpty()) {
            if (checkDeletibility(Negoptim__Assortment_Detail__c.SObjectType)) {
                delete detailsToDelete;
            }
        }
        if (!detailsToUpsert.isEmpty()) {
            if (checkCreatibility(Negoptim__Assortment_Detail__c.SObjectType, new List<String>()) && checkUpdatibility(Negoptim__Assortment_Detail__c.SObjectType, new List<String>())) {
                upsert detailsToUpsert;
            }
        }
        this.cancelPopup();
    }

    public PageReference send() {
        String[] toList = getEmailAddresses(emailTo);
        String[] ccList = getEmailAddresses(emailCc);
        String[] bccList = getEmailAddresses(emailBcc);
        List<Messaging.EmailFileAttachment> emailAttachments = new List<Messaging.EmailFileAttachment>();
        Messaging.EmailFileAttachment email_att = new Messaging.EmailFileAttachment();
        Integer oldPageSize = this.pageSize;
        Integer oldPageNumber = assortmentDetailStdSetCtrl.getPageNumber();
        PageReference pageRef = this.generateExcel();
        if (pageRef != null) {
            // save attachement
            String descriptionText = 'Email\nto :' + String.join(toList, ';') + '\n';
            descriptionText += 'cc :' + String.join(ccList, ';') + '\n';
            descriptionText += 'bcc :' + String.join(bccList, ';') + '\n';
            descriptionText += 'subject :' + emailSubject + '\n';
            descriptionText += 'body :' + emailBody + '\n';
            Blob contentBody = Blob.valueOf('This is a test body');
            if (!System.Test.isRunningTest()) {
                contentBody = pageRef.getContent();
            }
            Attachment attachmentExcel = new Attachment(ParentId = recordId, Name = this.assortmentBUName + '_'+ system.now() + '.xls',
                                                        ContentType = 'application/vnd.ms-excel', Body = contentBody,
                                                        Description = descriptionText);
            // check security on insert attachment fields
            String[] attachmentCreateFields = new String[]{
                SObjectType.Attachment.fields.Name.Name,
                SObjectType.Attachment.fields.Body.Name,
                SObjectType.Attachment.fields.ParentId.Name,
                SObjectType.Attachment.fields.ContentType.Name,
                SObjectType.Attachment.fields.Description.Name
            };
            if(checkCreatibility(Attachment.SObjectType, attachmentCreateFields)) {
                Database.insert(attachmentExcel);
            }

            email_att.setBody(contentBody);
            email_att.setContentType('application/vnd.ms-excel');
            email_att.setFileName(assortmentBUName + '_'+ system.now() + '.xls');
            email_att.setinline(false);
            emailAttachments.add(email_att);

            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setSenderDisplayName('NegOptim');
            email.setToAddresses(toList);
            email.setCcAddresses(ccList);
            email.setBccAddresses(bccList);
            email.setFileAttachments(emailAttachments);
            email.setSubject(emailSubject);
            email.setHtmlBody(emailBody);

            if(Limits.getEmailInvocations() >= Limits.getLimitEmailInvocations()) {
                this.popupGenerateExcel = false;
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error,'Single Email Limit Exceeded. Cannot send this email'));
                return null;
            }
            try {
                Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email});
            } catch (System.EmailException ex) {
                this.popupGenerateExcel = false;
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error,'Single Email Limit Exceeded. Cannot send this email'));
                return null;
            }
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, 'Successfully Send Email.'));
            this.popupGenerateExcel = false;
        }
        this.pageSize = oldPageSize;
        assortmentDetailStdSetCtrl.setPageSize(this.pageSize);
        assortmentDetailStdSetCtrl.setPageNumber(oldPageNumber);
        getAssortmentDetails();
        return null;
    }

   /**
    * allow user to enter multiple email addresses seperated by ',' or ';'
    */
    private String[] getEmailAddresses(String source) {
        if (source == null || String.isEmpty(source)) {
            return new String[]{};
        }
        source = source.remove(' ');
        source = source.replaceAll(',', ';');
        return source.split(';');
    }

    // generate Excel
    public PageReference generateExcel() {
        try {
            if(recordId == null) return null;
            PageReference pageRef = Page.AssortmentBUMatrixExcelExt;
            pageRef.setRedirect(false);
            this.pageSize = this.noOfRecords;
            this.isFirstLoad = true;
            refreshData = true;
            this.search();
            this.isFirstLoad = false;
            refreshData = false;
            return pageRef;
        } catch (Exception ex) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 'Error:' + ex.getMessage()));
            return null;
        }
    }
    /**
     * @description checks if a field should be added to the main grid and the totals tree
     * rules are:
     * 1- field is a tax field and the tax is active
     * 2- field is a discount field and discount is active
     * 3- field is neither a tax field nor a discount field
     *
     * @param String the name of the SObject field
    */
    private Boolean displayField(String fieldName) {
        // check if field represents a contract tax
        Boolean isContractTaxField = fieldName.startsWithIgnoreCase(this.prefix + 'Contract_nego_Tax_');
        Integer contractTaxOrder = isContractTaxField ? Integer.valueOf(fieldName.replace(this.prefix + 'Contract_nego_Tax_', '').replace('__c', '')) : -1;
        Boolean isContractTaxActive = this.contractActiveTaxesMap.containsKey(contractTaxOrder);
        // check if field represents a contract discount
        Boolean isContractDiscField = fieldName.startsWithIgnoreCase(this.prefix + 'Contract_nego_Disc_');
        Integer contractDiscOrder = isContractDiscField ? Integer.valueOf(fieldName.replace(this.prefix + 'Contract_nego_Disc_', '').left(1)) : -1;
        Boolean isContractDiscActive = this.contractActiveDiscountsMap.containsKey(contractDiscOrder);
        // check if field represents a statement tax
        Boolean isStatementTaxField = fieldName.startsWithIgnoreCase(this.prefix + 'Statement_Tax_');
        Integer statementTaxOrder = isStatementTaxField ? Integer.valueOf(fieldName.replace(this.prefix + 'Statement_Tax_', '').replace('__c', '')) : -1;
        Boolean isStatementTaxActive = this.statementActiveTaxesMap.containsKey(statementTaxOrder);
        // check if field represents a statement discount
        Boolean isStatementDiscField = fieldName.startsWithIgnoreCase(this.prefix + 'Statement_Disc_');
        Integer statementDiscOrder = isStatementDiscField ? Integer.valueOf(fieldName.replace(this.prefix + 'Statement_Disc_', '').left(1)) : -1;
        Boolean isStatementDiscActive = this.statementActiveDiscountsMap.containsKey(statementDiscOrder);

        Boolean displayField = false;
        if(!isStatementTaxField && !isStatementDiscField && !isContractTaxField && !isContractDiscField && String.isNotBlank(fieldName)) {
            displayField = true;
        } else if((isStatementTaxField && isStatementTaxActive) || (isContractTaxField && isContractTaxActive)) {
            displayField = true;
        } else if (isStatementDiscField
                   && isStatementDiscActive
                   && ((fieldName.equalsIgnoreCase(this.prefix + 'Statement_Disc_' + statementDiscOrder + '__c')
                        && this.statementActiveDiscountsMap.get(statementDiscOrder).conditionMode.contains('%'))
                       || ((fieldName.equalsIgnoreCase(this.prefix + 'Statement_Disc_' + statementDiscOrder + '_U__c')
                            || fieldName.equalsIgnoreCase(this.prefix + 'Statement_Disc_' + statementDiscOrder + '_UType__c'))
                           && this.statementActiveDiscountsMap.get(statementDiscOrder).conditionMode.contains('U'))
                       || (!fieldName.equalsIgnoreCase(this.prefix + 'Statement_Disc_' + statementDiscOrder + '__c')
                           && !fieldName.equalsIgnoreCase(this.prefix + 'Statement_Disc_' + statementDiscOrder + '_U__c')
                           && !fieldName.equalsIgnoreCase(this.prefix + 'Statement_Disc_' + statementDiscOrder + '_UType__c'))))
        {
            displayField = true;
        } else if (isContractDiscField
                   && isContractDiscActive
                   && ((fieldName.equalsIgnoreCase(this.prefix + 'Contract_nego_Disc_' + contractDiscOrder + '__c')
                        && this.contractActiveDiscountsMap.get(contractDiscOrder).conditionMode.contains('%'))
                       || ((fieldName.equalsIgnoreCase(this.prefix + 'Contract_nego_Disc_' + contractDiscOrder + '_U__c')
                            || fieldName.equalsIgnoreCase(this.prefix + 'Contract_nego_Disc_' + contractDiscOrder + '_UType__c'))
                           && this.contractActiveDiscountsMap.get(contractDiscOrder).conditionMode.contains('U'))
                       || (!fieldName.equalsIgnoreCase(this.prefix + 'Contract_nego_Disc_' + contractDiscOrder + '__c')
                           && !fieldName.equalsIgnoreCase(this.prefix + 'Contract_nego_Disc_' + contractDiscOrder + '_U__c')
                           && !fieldName.equalsIgnoreCase(this.prefix + 'Contract_nego_Disc_' + contractDiscOrder + '_UType__c'))))
        {
            displayField = true;
        }
        return displayField;
    }


    /** Wrapper class for Category Tree. */
    public class CategoryTreeWrapper {
        private String title;
        private String key;
        private boolean folder;
        private String path;
        private String parentId {get; set;}
        private List<CategoryTreeWrapper> children {get; set;}
        private Map<String, Integer> counts {get; set;}
        private Map<String, Decimal> sums {get; set;}

        public CategoryTreeWrapper() {
            this.children = new List<CategoryTreeWrapper>();
            this.counts = new Map<String, Integer>();
            this.sums = new Map<String, Decimal>();
        }
    }

    /** Wrapper class for Assortment Detail. */
    public class CategoryWrapper {
        public Id categoryId {get; set;}
        public String categoryName {get; set;}
        public List<Negoptim__Assortment_Detail__c> assortmentDetails {get; set;}

        public CategoryWrapper(Id categoryId, String categoryName, Negoptim__Assortment_Detail__c item) {
            this.categoryId = categoryId;
            this.categoryName = categoryName;
            if (item.Negoptim__record_date__c == null) item.Negoptim__record_date__c = Date.valueOf(item.CreatedDate);
            this.assortmentDetails = new List<Negoptim__Assortment_Detail__c>{item};
        }

        public CategoryWrapper(Id categoryId, String categoryName) {
            this.categoryId = categoryId;
            this.categoryName = categoryName;
            this.assortmentDetails = new List<Negoptim__Assortment_Detail__c>();
        }
    }

    public class AssortmentDetailWrapper implements Comparable {
        public Negoptim__Assortment_Detail__c detail {get; set;}
        public List<AssortmentDetailWrapper> historyList {get; set;}
        public List<AssortmentDetailWrapper> switchHistoryList {get; set;}

        public AssortmentDetailWrapper (Negoptim__Assortment_Detail__c detail) {
            this.detail = detail;
            historyList = new List<AssortmentDetailWrapper>();
            switchHistoryList = new List<AssortmentDetailWrapper>();
        }

        public void sort() {
            historyList.sort();
            switchHistoryList.sort();
        }

        public List<Negoptim__Assortment_Detail__c> getAllHistory() {
            List<Negoptim__Assortment_Detail__c> result = new List<Negoptim__Assortment_Detail__c>();
            for (AssortmentDetailWrapper item : historyList) {
                result.add(item.detail);
            }
            for (AssortmentDetailWrapper item : switchHistoryList) {
                result.add(item.detail);
            }
            return result;
        }

        public Integer compareTo(Object o) {
            AssortmentDetailWrapper adw = (AssortmentDetailWrapper) o;
            if (this.detail.Negoptim__Product__r.Name > adw.detail.Negoptim__Product__r.Name) {
                return 1;
            } else if (this.detail.Negoptim__Product__r.Name < adw.detail.Negoptim__Product__r.Name) {
                return -1;
            } else {
                if (this.detail.Negoptim__Version__c == null || this.detail.Negoptim__Version__c < adw.detail.Negoptim__Version__c) {
                    return 1;
                } else if (this.detail.Negoptim__Version__c > adw.detail.Negoptim__Version__c) {
                    return -1;
                } else {
                    return 0;
                }
            }
        }
    }

    public class SwitchProductWrapper {
        public String currentProduct {get; set;}
        private Id newProductId;
        public String newProduct {get; set;}
        public Negoptim__Assortment_Detail__c assortmentDetail {get; set;}
        public Boolean isSelected {get; set;}

        public SwitchProductWrapper(String currentProduct, Id newProductId, String newProduct, Negoptim__Assortment_Detail__c assortmentDetail) {
            this.currentProduct = currentProduct;
            this.newProductId = newProductId;
            this.newProduct = newProduct;
            this.assortmentDetail = assortmentDetail;
            this.isSelected = true;
        }
    }

    /*public class StopProductWrapper {
        public Product_Assortment_Introduction_History__c history {get; set;}
        public Boolean isSelected {get; set;}

        public StopProductWrapper(Product_Assortment_Introduction_History__c history) {
            this.history = history;
            this.isSelected = true;
        }
    }*/

    public class HigherLevelPackagingWrapper {
        public Product2 higherLevelPackaging {get; set;}
        public Negoptim__Assortment_Detail__c higherLevelPackagingDetail {get; set;}
        public Boolean isSelected {get; set;}
        public Boolean isMasterHigherLevelPackagingDetail {get; set;}

        public HigherLevelPackagingWrapper(Product2 higherLevelPackaging, Negoptim__Assortment_Detail__c higherLevelPackagingDetail) {
            this.higherLevelPackaging = higherLevelPackaging;
            this.higherLevelPackagingDetail = higherLevelPackagingDetail;
            this.isSelected = this.higherLevelPackagingDetail != null;
            this.isMasterHigherLevelPackagingDetail = this.higherLevelPackagingDetail != null && this.higherLevelPackagingDetail.Negoptim__IsMaster_Higher_Level_Packaging__c;
        }
    }

    public class ClientStatusWrapper {
        public Id assortmentBUId {get; set;}
        public Id assortmentDetailId {get; set;}
        public Id categoryId {get; set;}
        public Decimal version {get; set;}
        public String clientStatus {get; set;}
        public Boolean clientAssortment {get; set;}
        public Boolean[] clientClusters {get; set;}
        public Boolean[] corpClusters {get; set;}
        public Boolean[] clientClustersCplt {get; set;}
        public Integer strat {get; set;}
        public Integer cpltIndex {get; set;}
        public Integer selectedClustCpltIndex {get; set;}
        //last history
        public Boolean hasLastHistory {get; set;}
        // last valid
        public Boolean isValidDetail {get; set;}
        public String lastValidClientStatus {get; set;}
        public Integer lastValidStratCount {get; set;}
        public Integer lastValidStratIndex {get; set;}

        public ClientStatusWrapper(Negoptim__Assortment_Detail__c assortmentDetail, Map<Id, List<Integer>> stratsMap, Map<Id, List<Integer>> cpltMap, List<String> gridFields, Boolean manageAssortByPersonalizedCategory) {
            this.assortmentBUId = assortmentDetail.Negoptim__Assortment_BU__c;
            this.assortmentDetailId = assortmentDetail.Id;
            this.categoryId = manageAssortByPersonalizedCategory ? assortmentDetail.Negoptim__Client_Category__c : assortmentDetail.Negoptim__Category__c;
            this.version = assortmentDetail.Negoptim__Version__c;
            //// this.clientStatus = gridFields.contains(NegoptimHelper.normalizeApiName('Client_Status__c')) ? assortmentDetail.Client_Status__c : '';
            this.clientStatus = assortmentDetail.Negoptim__Client_Status__c;
            this.clientAssortment = gridFields.contains(Negoptim.NegoptimHelper.normalizeApiName('Client_Ass__c')) ? assortmentDetail.Negoptim__Client_Ass__c : false;

            this.clientClusters = new List<Boolean>();
            this.corpClusters = new List<Boolean>();
            this.clientClustersCplt = new List<Boolean>();
            this.strat = 0;
            this.cpltIndex = 0;

            Boolean clientCluster, clientClusterCplt;
            Negoptim__Assortment_Detail__c lastHistory = String.isNotBlank(assortmentDetail.Negoptim__Last_History__c) ? assortmentDetail.Negoptim__Last_History__r : assortmentDetail.Negoptim__Ref_Client_Assortment__r;
            this.hasLastHistory = String.isNotBlank(assortmentDetail.Negoptim__Last_History__c) || String.isNotBlank(assortmentDetail.Negoptim__Ref_Client_Assortment__c);
            this.lastValidStratCount = 0;
            Boolean isAssBUClusterStrat = assortmentDetail.Negoptim__Status__c == 'Validated' ?
                (assortmentDetail.Negoptim__Ass_BU_Cluster__r != null && assortmentDetail.Negoptim__Ass_BU_Cluster__r.Negoptim__Assortment_Strat__c.startsWithIgnoreCase('Strat')) : this.hasLastHistory ?
                    (lastHistory.Negoptim__Ass_BU_Cluster__r != null && lastHistory.Negoptim__Ass_BU_Cluster__r.Negoptim__Assortment_Strat__c.startsWithIgnoreCase('Strat')) : false;
            this.lastValidStratIndex = (isAssBUClusterStrat && assortmentDetail.Negoptim__Status__c == 'Validated') ?
                Integer.valueOf(assortmentDetail.Negoptim__Ass_BU_Cluster__r.Negoptim__Assortment_Strat__c.right(1)) + 1 : (isAssBUClusterStrat && this.hasLastHistory) ?
                    Integer.valueOf(lastHistory.Negoptim__Ass_BU_Cluster__r.Negoptim__Assortment_Strat__c.right(1)) + 1 : -1;

            if(stratsMap.containsKey(this.categoryId)) {
                for(Integer stratIndex : stratsMap.get(this.categoryId)) {
                    clientCluster = gridFields.contains(Negoptim.NegoptimHelper.normalizeApiName('Client_Clust' + (stratIndex + 1) + '__c')) ? (Boolean) assortmentDetail.get(Negoptim.NegoptimHelper.normalizeApiName('Client_Clust' + (stratIndex + 1) + '__c')) : false;
                    this.clientClusters.add(clientCluster);
                    if (this.strat == 0 && clientCluster) {
                        this.strat = stratIndex + 1;
                    }
                    if (assortmentDetail.Negoptim__Status__c == CommonConstants.PLV_ASSORTMENT_DETAIL_STATUS_VALIDATED) {
                        this.lastValidStratCount += (Boolean) assortmentDetail.get(Negoptim.NegoptimHelper.normalizeApiName('Client_Clust' + (stratIndex + 1) + '__c')) ? 1 : 0;
                    } else if (this.hasLastHistory) {
                        this.lastValidStratCount += (Boolean) lastHistory.get('Negoptim__Client_Clust' + (stratIndex + 1) + '__c') ? 1 : 0;
                    }
                }
            }
            if(cpltMap.containsKey(this.categoryId)) {
                for(Integer cpltIndex : cpltMap.get(this.categoryId)) {
                    clientClusterCplt = gridFields.contains(Negoptim.NegoptimHelper.normalizeApiName('Client_Clust_Cplt' + (cpltIndex + 1) + '__c')) ? (Boolean) assortmentDetail.get(Negoptim.NegoptimHelper.normalizeApiName('Client_Clust_Cplt' + (cpltIndex + 1) + '__c')) : false;
                    this.clientClustersCplt.add(clientClusterCplt);
                    if (clientClusterCplt) {
                        this.cpltIndex = cpltIndex + 1;
                    }
                }
            }
            for (Integer i = 1; i <= Negoptim.NegoptimHelper.getNbClientClusterFields(); i++) {
                Boolean corpCluster = gridFields.contains(Negoptim.NegoptimHelper.normalizeApiName('Corp_Clust' + i + '__c')) ? (Boolean) assortmentDetail.get(Negoptim.NegoptimHelper.normalizeApiName('Corp_Clust' + i + '__c')) : false;
                this.corpClusters.add(corpCluster);
            }
            if (assortmentDetail.Negoptim__Status__c == CommonConstants.PLV_ASSORTMENT_DETAIL_STATUS_VALIDATED) {
                this.lastValidClientStatus = assortmentDetail.Negoptim__Client_Status__c;
            } else if (this.hasLastHistory) {
                this.lastValidClientStatus = lastHistory.Negoptim__Client_Status__c;
            }
            this.isValidDetail = assortmentDetail.Negoptim__Status__c == CommonConstants.PLV_ASSORTMENT_DETAIL_STATUS_VALIDATED;
            if(assortmentDetail.Negoptim__Client_Status__c == CommonConstants.PLV_ASSORTMENT_DETAIL_CLIENT_STATUS_CPLT && assortmentDetail.Negoptim__Ass_BU_Cluster__c != null) {
                this.selectedClustCpltIndex = Integer.valueOf(assortmentDetail.Negoptim__Ass_BU_Cluster__r.Negoptim__Assortment_Strat__c.right(1));
            }
        }
    }

    public class BUClusterWrapper {
        public Negoptim__Orga_BU__c orgaBU {get; set;}
        public Integer stratIndex {get; set;}
        // Specified for the strat and cplt that's closed
		public Boolean isDisabled {get; set;}
        public Boolean hasHistory {get; set;}

        public BUClusterWrapper (Negoptim__Orga_BU__c orgaBU) {
            this.orgaBU = orgaBU;
            this.stratIndex = orgaBU == null ? 0 : Integer.valueOf(orgaBU.Negoptim__Assortment_Strat__c.right(1));
        }
    }

    public enum ClusterType {REF_CLIENT, NEW_CLIENT} // TODO: When nessecary add REF_CORP, NEW_CORP

    public class ColumnWrapper {

        public Component.Apex.Column getColumn(GridSettingsManager.FieldWrapper fieldWrapper, Boolean hasFooter) {

            Component.Apex.Column column = new Component.Apex.Column();
            column.headerClass = 'text-center slds-truncate inner-header';
            column.expressions.styleClass = 'text-center slds-truncate {!IF(item["Negoptim__Version__c"] != NULL, "history", "")}';
            column.headerValue = fieldWrapper.fieldLabel;
            String columnStyle = '';
            if (String.isNotBlank(fieldWrapper.bgColor) && !fieldWrapper.fieldName.equalsIgnoreCase(Negoptim.NegoptimHelper.normalizeAPIName('New_Client_ProductNumber__c')) && !fieldWrapper.fieldName.equalsIgnoreCase(Negoptim.NegoptimHelper.normalizeAPIName('Client_Status__c'))) {
                columnStyle += 'background-color: ' + fieldWrapper.bgColor + ' !important;';
            }
            if ( fieldWrapper.stringFieldType == 'REFERENCE' ) {
                columnStyle += ' min-width: 205px !important; ';
            }
            if(String.isNotBlank(fieldWrapper.nonConditional?.widthStyle)) {
                columnStyle += fieldWrapper.nonConditional?.widthStyle;
            } else {
                column.expressions.styleClass += ' limit-width-130px ';
            }
            if (fieldWrapper.isBorderColumn) {
                columnStyle += 'border-left: 5px solid ' + fieldWrapper.borderColor + '!important;';
            }
            if (String.isNotBlank(columnStyle)) {
                column.style = columnStyle;
            }
            // case product__c
            if (fieldWrapper.fieldName.equalsIgnoreCase(Negoptim.NegoptimHelper.normalizeAPIName('product__c'))
                || fieldWrapper.fieldName.equalsIgnoreCase(Negoptim.NegoptimHelper.getFieldNameAsRelation(SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__Product__c.Name) + '.' + SObjectType.Product2.fields.Negoptim__Product_Name__c.Name))
            {
                column.headerClass += ' productName';
                column.expressions.styleClass += ' productName';

                Component.Apex.OutputText versionText = new Component.Apex.OutputText();
                //commented because it's replaced by the label comming from the Class NegoptimLabels
                ////versionText.expressions.value ='{!$Label.' + NegoptimHelper.getPackagePrefix(true) + 'Version}{!item["Version__c"]}: ';
                versionText.expressions.value = System.Label.Negoptim.Version +'{!item["Negoptim__Version__c"]}: ';
                versionText.expressions.rendered = '{!!ISNULL(item["Negoptim__Version__c"])}';
                // product name color depending if intro or stop
                column.expressions.styleClass += '{!IF(AND(OR(item.Negoptim__Product__r.Negoptim__IsInnovation__c, item.Negoptim__Product__r.recordType.developerName == "' + CommonConstants.RT_PRODUCT2_UNIT_NEED + '"), item.Negoptim__Product__r.Negoptim__Market_Introduction_Date__c!=null, YEAR(item.Negoptim__Product__r.Negoptim__Market_Introduction_Date__c) < Negoptim__Assortment_BU__c.Negoptim__Year__c), " INNO_INTRO_DATE_LESS_N", "")}';
                column.expressions.styleClass += '{!IF(AND(OR(item.Negoptim__Product__r.Negoptim__IsInnovation__c, item.Negoptim__Product__r.recordType.developerName == "' + CommonConstants.RT_PRODUCT2_UNIT_NEED + '"), item.Negoptim__Product__r.Negoptim__Market_Introduction_Date__c!=null, YEAR(item.Negoptim__Product__r.Negoptim__Market_Introduction_Date__c) >= Negoptim__Assortment_BU__c.Negoptim__Year__c), " INNO_INTRO_DATE_GREATER_N", "")}';
                column.expressions.styleClass += '{!IF(AND(item.Negoptim__Product__r.Negoptim__Market_End_of_Life_Date__c!=null, YEAR(item.Negoptim__Product__r.Negoptim__Market_End_of_Life_Date__c) < Negoptim__Assortment_BU__c.Negoptim__Year__c), " STOP_DATE_LESS_N", "")}';
                column.expressions.styleClass += '{!IF(AND(item.Negoptim__Product__r.Negoptim__Market_End_of_Life_Date__c!=null, YEAR(item.Negoptim__Product__r.Negoptim__Market_End_of_Life_Date__c) >= Negoptim__Assortment_BU__c.Negoptim__Year__c), " STOP_DATE_GREATER_N", "")}';

                Component.Apex.OutputField output = new Component.Apex.OutputField();
                Component.Apex.OutputLink outputlink = new Component.Apex.OutputLink();
                if(fieldWrapper.fieldName.equalsIgnoreCase(Negoptim.NegoptimHelper.normalizeAPIName('product__c'))) {
                    output.expressions.value = '{!item.' + fieldWrapper.fieldName + '}';
                } else {
                    outputlink.expressions.value = '/{!item.' + Negoptim.NegoptimHelper.normalizeAPIName('product__c') + '}';
                    Component.Apex.OutputText prodNameText = new Component.Apex.OutputText();
                    prodNameText.expressions.value = '{!item.' + fieldWrapper.fieldName + '}';
                    outputlink.childComponents.add(prodNameText);
                }

                // conponent for switchIcon
                Component.Apex.OutputLink switchIcon = new Component.Apex.OutputLink();
                List<String> renderConditions = new List<String> {'initialAssortmentDetailsMap[item.Id]["Negoptim__Product__r"]["Negoptim__Product_Reference_Type__c"] == "Switch"',
                    'OR(ISNULL(initialAssortmentDetailsMap[item.Id]["Negoptim__Product__r"]["Negoptim__Market_End_of_Life_Date__c"]), YEAR(initialAssortmentDetailsMap[item.Id]["Negoptim__Product__r"]["Negoptim__Market_End_of_Life_Date__c"]) > Negoptim__Assortment_BU__c.Negoptim__Year__c)',
                    'ISNULL(item["Negoptim__Version__c"])', 'isOrgCPG'
                    };
                        switchIcon.expressions.rendered = '{!AND(' + String.join(renderConditions, ',') + ')}';
                switchIcon.expressions.onclick = 'showSingleSwitchPopup(true, "{!item.Id}", "{!item.Negoptim__Category__c}", true); return false;';
                Component.Apex.OutputText switchIconText = new Component.Apex.OutputText();
                switchIcon.title = Label.Negoptim.LBL_Switch_Helptext;
                switchIconText.value = '<span class="switchIcon">';
                switchIconText.value += '</span>';
                switchIconText.escape = false;
                // conponent for stopIcon
                Component.Apex.OutputLink stopIcon = new Component.Apex.OutputLink();
                renderConditions = new List<String> {'!ISNULL(initialAssortmentDetailsMap[item.Id]["Negoptim__Product__r"]["Negoptim__Market_End_of_Life_Date__c"])',
                    'YEAR(initialAssortmentDetailsMap[item.Id]["Negoptim__Product__r"]["Negoptim__Market_End_of_Life_Date__c"]) <= Negoptim__Assortment_BU__c.Negoptim__Year__c',
                    'ISNULL(item["Negoptim__Version__c"])', 'isOrgCPG'
                    };
                        stopIcon.title = Label.Negoptim.LBL_Stop_Helptext;
                stopIcon.expressions.rendered = '{!AND(' + String.join(renderConditions, ',') + ')}';
                stopIcon.onclick = 'return false;';
                Component.Apex.OutputText stopIconText = new Component.Apex.OutputText();
                stopIconText.value = '<span class="stopIcon">';
                stopIconText.value += '</span>';
                stopIconText.escape = false;
                // conponent for renoIcon
                Component.Apex.OutputLink renoIcon = new Component.Apex.OutputLink();
                renderConditions = new List<String> {'initialAssortmentDetailsMap[item.Id]["Negoptim__Product__r"]["Negoptim__Product_Reference_Type__c"] == "Reno"',
                    'OR(ISNULL(initialAssortmentDetailsMap[item.Id]["Negoptim__Product__r"]["Negoptim__Market_End_of_Life_Date__c"]), YEAR(initialAssortmentDetailsMap[item.Id]["Negoptim__Product__r"]["Negoptim__Market_End_of_Life_Date__c"]) > Negoptim__Assortment_BU__c.Negoptim__Year__c)',
                    'ISNULL(item["Negoptim__Version__c"])', 'isOrgCPG'
                    };
                        renoIcon.title = Label.Negoptim.LBL_Reno_Helptext;
                renoIcon.expressions.rendered = '{!AND(' + String.join(renderConditions, ',') + ')}';
                renoIcon.expressions.onclick = 'showSingleSwitchPopup(true, "{!item.Id}", "{!item.Negoptim__Category__c}", true); return false;';
                Component.Apex.OutputText renoIconText = new Component.Apex.OutputText();
                renoIconText.value = '<span class="renoIcon">';
                renoIconText.value += '</span>';
                renoIconText.escape = false;

                Component.Apex.OutputLink selectHigherLevelPackagingIcon = new Component.Apex.OutputLink();
                selectHigherLevelPackagingIcon.title = Label.Negoptim.LBL_HLP_Helptext;
                selectHigherLevelPackagingIcon.expressions.rendered = '{!AND(CONTAINS(hasHigherLevelPackagingMapKeySet_serialized, item["Negoptim__Product__c"]), hasHigherLevelPackagingMap[item.Negoptim__Product__c], item.Negoptim__Version__c == NULL, item["RecordType"]["DeveloperName"] == "' + CommonConstants.RT_ASSORTMENT_DETAIL_REGULAR + '", isOrgCPG)}';
                selectHigherLevelPackagingIcon.expressions.onclick = 'showSelectHigherLevelPackagingPopup("{!item.Negoptim__Product__c}"); return false;';
                Component.Apex.OutputText selectHigherLevelPackagingIconText = new Component.Apex.OutputText();
                selectHigherLevelPackagingIconText.value = '<span class="selectHigherLevelPackagingIcon">';
                selectHigherLevelPackagingIconText.value += '</span>';
                selectHigherLevelPackagingIconText.escape = false;

                switchIcon.childComponents.add(switchIconText);
                stopIcon.childComponents.add(stopIconText);
                renoIcon.childComponents.add(renoIconText);
                selectHigherLevelPackagingIcon.childComponents.add(selectHigherLevelPackagingIconText);

                column.childComponents.add(versionText);
                if (fieldWrapper.fieldName.equalsIgnoreCase(Negoptim.NegoptimHelper.getFieldNameAsRelation(SObjectType.Negoptim__Assortment_Detail__c.fields.Negoptim__Product__c.Name) + '.' + SObjectType.Product2.fields.Negoptim__Product_Name__c.Name)) {
                    column.childComponents.add(outputlink);
                } else {
                    column.childComponents.add(output);
                }
                column.childComponents.add(renoIcon);
                column.childComponents.add(switchIcon);
                column.childComponents.add(stopIcon);
                column.childComponents.add(selectHigherLevelPackagingIcon);
            }
            // case product__r.field__c TODO: remove this case and make use of field Describe to get field parent SObject
            else if (fieldWrapper.fieldName.containsIgnoreCase('Negoptim__product__r')) {
                String fieldName = fieldWrapper.fieldName.split('\\.')[1];
                column.headerClass += fieldWrapper.fieldName.containsIgnoreCase('Negoptim__product_ean__c') ? ' productEAN' : '';
                column.expressions.value = '{!item.Negoptim__Product__r.' + fieldName + '}';
            }
            // all other cases
            else {
                //column.headerClass += ' col';
                Component.Apex.InputField input = new Component.Apex.InputField();
                Component.Apex.InputTextArea inputTextArea = new Component.Apex.InputTextArea();
                Component.Apex.OutputField output = new Component.Apex.OutputField();
                Component.Apex.OutputPanel outputPanel = new Component.Apex.OutputPanel();
                // formula fields are rendered as span without the class attribute
                // using an outputText in case field insures the class attribute is rendered
                Component.Apex.OutputText outputFormula = new Component.Apex.OutputText();
                outputFormula.escape = false;
                // adding border class to column headerClass and column styleClass
                // // if (fieldWrapper.isBorderColumn) {
                // //     column.headerClass += ' border-col';
                // //     column.expressions.styleClass += ' border-col';
                // // }

                input.expressions.value = '{!item.' + fieldWrapper.fieldName + '}';
                inputTextArea.expressions.value = '{!item.' + fieldWrapper.fieldName + '}';
                inputTextArea.rows = 1;
                input.expressions.styleClass = 'ASD_{!item.Id} inputNoEnter {!item.Id}_' + fieldWrapper.fieldName;
                inputTextArea.expressions.styleClass = 'ASD_{!item.Id} inputNoEnter {!item.Id}_' + fieldWrapper.fieldName;
                if (fieldWrapper.fieldType == DisplayType.Double || fieldWrapper.fieldType == DisplayType.Integer || fieldWrapper.fieldType == DisplayType.Long
                    || fieldWrapper.fieldType == DisplayType.Percent || fieldWrapper.fieldType == DisplayType.Currency)
                    input.style = 'text-align: right;';
                input.expressions.rendered = '{!AND('+ (fieldWrapper.isInputField == true) + ', item["Negoptim__Version__c"] == NULL , !readOnly)}';
                inputTextArea.expressions.rendered = '{!AND('+ (fieldWrapper.isInputField == true) + ', item["Negoptim__Version__c"] == NULL , !readOnly)}';

                output.expressions.value = '{!item.' + fieldWrapper.fieldName + '}';
                if (fieldWrapper.fieldName.equalsIgnoreCase(Negoptim.NegoptimHelper.normalizeAPIName('Client_Status__c'))) {
                    outputPanel.expressions.rendered = '{!OR(' + (fieldWrapper.isNumberField != true && fieldWrapper.isInputField != true) + ', item["Negoptim__Version__c"] <> NULL, readOnly)}';
                    outputPanel.expressions.styleClass = ' {!item.Id}_' + fieldWrapper.fieldName;
                } else {
                    output.expressions.rendered = '{!OR(' + (fieldWrapper.isNumberField != true && fieldWrapper.isInputField != true) + ', item["Negoptim__Version__c"] <> NULL, readOnly)}';
                }

                if (fieldWrapper.fieldType == DisplayType.Double || fieldWrapper.fieldType == DisplayType.Integer || fieldWrapper.fieldType == DisplayType.Long
                    || fieldWrapper.fieldType == DisplayType.Percent || fieldWrapper.fieldType == DisplayType.Currency)
                    outputFormula.expressions.value = '{!ROUND(item.' + fieldWrapper.fieldName +' ,' + fieldWrapper.scale + ')}';
                else
                    outputFormula.expressions.value = '{!item.' + fieldWrapper.fieldName + '}';
                outputFormula.expressions.styleClass = ' {!item.Id}_' + fieldWrapper.fieldName;
                if (fieldWrapper.fieldType == DisplayType.Double || fieldWrapper.fieldType == DisplayType.Integer || fieldWrapper.fieldType == DisplayType.Long
                    || fieldWrapper.fieldType == DisplayType.Percent || fieldWrapper.fieldType == DisplayType.Currency)
                {
                    outputFormula.expressions.styleClass += ' formatNumber-' + fieldWrapper.fieldName;
                }
                outputFormula.expressions.rendered = '{!AND(' + (fieldWrapper.isNumberField == true || fieldWrapper.isInputField == true || fieldWrapper.fieldType == DisplayType.STRING) + ', item["Negoptim__Version__c"] == NULL, !readOnly)}';
                if (hasFooter) {
                    column.expressions.footerClass='text-center {!group.categoryId}' + fieldWrapper.fieldName;
                    if (fieldWrapper.fieldType == DisplayType.Boolean) {
                        column.expressions.footerValue = '{!categoryCountMap["' + fieldWrapper.fieldName + '"]}';
                        // register onchange event to recalculate totals
                        input.expressions.onchange = ' calculateTotal("' + fieldWrapper.fieldName + '","{!item.Id}", "{!group.categoryId}", "{!item.Negoptim__Assortment_BU__c}");';
                    } else {
                        Component.Apex.OutputText footerText = new Component.Apex.OutputText();
                        if (fieldWrapper.fieldType == DisplayType.Double || fieldWrapper.fieldType == DisplayType.Integer || fieldWrapper.fieldType == DisplayType.Long
                            || fieldWrapper.fieldType == DisplayType.Percent || fieldWrapper.fieldType == DisplayType.Currency)
                        {
                            footerText.expressions.value = '{!ROUND(categorySumMap["' + fieldWrapper.fieldName + '"]' +' ,' + fieldWrapper.scale + ')}';
                            footerText.styleClass = 'formatNumber-' + fieldWrapper.fieldName;
                        }
                        column.facets.footer = footerText;
                        input.expressions.styleClass += ' numberInput';
                        // different than checkbox method
                        input.expressions.onchange = 'calculateTotal("' + fieldWrapper.fieldName + '","{!item.Id}", "{!group.categoryId}", "{!item.Negoptim__Assortment_BU__c}");';
                        // add hidden input to keep first loaded value
                        Component.Apex.OutputText hidden = new Component.Apex.OutputText();
                        hidden.expressions.styleClass = '{!item.Id}initial' + fieldWrapper.fieldName;
                        hidden.expressions.value = '{!IF(item["' + fieldWrapper.fieldName + '"] == null, 0, item["' + fieldWrapper.fieldName + '"])}';
                        hidden.style = 'display:none';
                        column.childComponents.add(hidden);
                    }
                }

                // adding item Id as a class for fields with color highlight
                if (fieldWrapper.fieldName.equalsIgnoreCase(Negoptim.NegoptimHelper.normalizeAPIName('Ref_Client_Ass__c'))
                    || fieldWrapper.fieldName.equalsIgnoreCase(Negoptim.NegoptimHelper.normalizeAPIName('Client_Ass__c'))
                    || fieldWrapper.fieldName.equalsIgnoreCase(Negoptim.NegoptimHelper.normalizeAPIName('Ref_Client_ProductNumber__c'))
                    || fieldWrapper.fieldName.equalsIgnoreCase(Negoptim.NegoptimHelper.normalizeAPIName('New_Client_ProductNumber__c'))
                    || fieldWrapper.fieldName.equalsIgnoreCase(Negoptim.NegoptimHelper.normalizeAPIName('Client_status__c'))
                    || fieldWrapper.fieldName.equalsIgnoreCase(Negoptim.NegoptimHelper.normalizeAPIName('Key_Note__c'))
                    || fieldWrapper.fieldName.equalsIgnoreCase(Negoptim.NegoptimHelper.normalizeAPIName('Movement_Date__c')))
                {
                    column.expressions.styleClass += ' {!item.Id} highlight-{!item.Negoptim__Client_Status__c}';
                    //column.style = '';
                }
                if (fieldWrapper.fieldName.equalsIgnoreCase(Negoptim.NegoptimHelper.normalizeAPIName('Ref_Client_Ass__c'))
                    || fieldWrapper.fieldName.equalsIgnoreCase(Negoptim.NegoptimHelper.normalizeAPIName('Ref_Client_ProductNumber__c')))
                {
                    column.expressions.styleClass = 'text-center highlight-ref {!IF(item["Negoptim__Version__c"] != NULL, "history", "")}';
                }

                // case mouvement date - add Id and register onchange event to update release date
                if (fieldWrapper.fieldName.equalsIgnoreCase(Negoptim.NegoptimHelper.normalizeAPIName('Movement_Date__c'))) {
                    input.id = 'movementDateField';
                    input.expressions.onchange = 'setReleaseDate(this);calculateTotal("' + fieldWrapper.fieldName + '","{!item.Id}", "{!group.categoryId}", "{!item.Negoptim__Assortment_BU__c}");';
                }
                // case release date - add Id
                if (fieldWrapper.fieldName.equalsIgnoreCase(Negoptim.NegoptimHelper.normalizeAPIName('Release_Date__c'))) {
                    input.id = 'release-date';
                }
                // case client status
                if (fieldWrapper.fieldName.equalsIgnoreCase(Negoptim.NegoptimHelper.normalizeAPIName('Client_Status__c'))) {
                    column.expressions.styleClass += ' clientStatus_col {!item.Id}_Client_Status__col';
                    input.expressions.styleClass += ' clientStatus';
                    input.expressions.onchange = ' toggleCheckboxes(this, "{!item.Id}", "clientStatus", undefined, "{!group.categoryId}"); handleClientStatusColors("{!item.Id}_Client_Status__col");';
                }
                // case client ass
                if (fieldWrapper.fieldName.equalsIgnoreCase(Negoptim.NegoptimHelper.normalizeAPIName('Client_Ass__c'))) {
                    input.expressions.onchange += ' toggleCheckboxes(this, "{!item.Id}","clientAss", undefined, "{!group.categoryId}");';
                }
                if (fieldWrapper.fieldName.startsWithIgnoreCase(Negoptim.NegoptimHelper.normalizeAPIName('Corp_Clust'))) {
                    Integer index = Integer.valueOf(fieldWrapper.fieldName.removeEnd('__c').removeStartIgnoreCase(Negoptim.NegoptimHelper.normalizeAPIName('Corp_Clust')));
                    input.expressions.onchange += ' toggleCheckboxes(this, "{!item.Id}", "corpClust", ' + index + ', "{!group.categoryId}");';
                }
                if ((fieldWrapper.isCalculated && fieldWrapper.fieldType != DisplayType.Boolean)
                    || (!fieldWrapper.isInputField && fieldWrapper.fieldType != DisplayType.Boolean))
                {
                    outputFormula.expressions.styleClass += ' {!item.Id}_' + fieldWrapper.fieldName;
                    column.childComponents.add(outputFormula);
                } else if ((fieldWrapper.isCalculated && fieldWrapper.fieldType == DisplayType.Boolean) || fieldWrapper.isInputField) {
                    if (fieldWrapper.fieldType == DisplayType.TextArea) {
                        column.childComponents.add(inputTextArea);
                    } else {
                        column.childComponents.add(input);
                    }
                }
                if (fieldWrapper.fieldName.equalsIgnoreCase(Negoptim.NegoptimHelper.normalizeAPIName('Client_Status__c'))) {
                    outputPanel.childComponents.add(output);
                    column.childComponents.add(outputPanel);
                } else if (!fieldWrapper.isCalculated){
                    column.childComponents.add(output);
                }
                // case contract tax field
                if(fieldWrapper.fieldName.startsWith(Negoptim.NegoptimHelper.normalizeAPIName('Contract_nego_Tax_'))) {
                    Integer contractTaxOrder = Integer.valueOf(fieldWrapper.fieldName.replace(Negoptim.NegoptimHelper.normalizeAPIName('Contract_nego_Tax_'), '').replace('__c', ''));
                    Component.Apex.OutputLink header = new Component.Apex.OutputLink();
                    header.expressions.value = '/{!contractActiveTaxesMap[' + contractTaxOrder + '].recordId}';
                    header.target = '_blank';
                    Component.Apex.OutputText headerText = new Component.Apex.OutputText();
                    headerText.expressions.value = '{!contractActiveTaxesMap[' + contractTaxOrder + '].Name}';
                    header.childComponents.add(headerText);
                    column.facets.header = header;
                }
                // case contract discount field
                if(fieldWrapper.fieldName.startsWith(Negoptim.NegoptimHelper.normalizeAPIName('Contract_nego_Disc_'))) {
                    Integer contractDiscOrder = Integer.valueOf(fieldWrapper.fieldName.replace(Negoptim.NegoptimHelper.normalizeAPIName('Contract_nego_Disc_'), '').left(1));
                    Component.Apex.OutputLink header = new Component.Apex.OutputLink();
                    header.expressions.value = '/{!contractActiveDiscountsMap[' + contractDiscOrder + '].recordId}';
                    header.target = '_blank';
                    Component.Apex.OutputText headerText = new Component.Apex.OutputText();
                    String fieldSuffix;
                    if (fieldWrapper.fieldLabel.contains('Rem' + contractDiscOrder)) {
                        fieldSuffix = fieldWrapper.fieldLabel.replace('Rem' + contractDiscOrder, '');
                    } else {
                        fieldSuffix = fieldWrapper.fieldName
                        .removeStartIgnoreCase(Negoptim.NegoptimHelper.normalizeAPIName('Contract_nego_Disc_') + contractDiscOrder)
                        .removeEndIgnoreCase('__c')
                        .remove('_');
                    }
                    headerText.expressions.value = '{!contractActiveDiscountsMap[' + contractDiscOrder + '].Name} ' + fieldSuffix;
                    header.childComponents.add(headerText);
                    column.facets.header = header;
                }
                // case statement tax field
                if(fieldWrapper.fieldName.startsWith(Negoptim.NegoptimHelper.normalizeAPIName('Statement_Tax_'))) {
                    Integer statementTaxOrder = Integer.valueOf(fieldWrapper.fieldName.replace(Negoptim.NegoptimHelper.normalizeAPIName('Statement_Tax_'), '').replace('__c', ''));
                    Component.Apex.OutputLink header = new Component.Apex.OutputLink();
                    header.expressions.value = '/{!statementActiveTaxesMap[' + statementTaxOrder + '].recordId}';
                    header.target = '_blank';
                    Component.Apex.OutputText headerText = new Component.Apex.OutputText();
                    headerText.expressions.value = 'Four-' + '{!statementActiveTaxesMap[' + statementTaxOrder + '].Name}';
                    header.childComponents.add(headerText);
                    column.facets.header = header;
                }
                // case statement discount field
                if(fieldWrapper.fieldName.startsWith(Negoptim.NegoptimHelper.normalizeAPIName('Statement_Disc_'))) {
                    Integer statementDiscOrder = Integer.valueOf(fieldWrapper.fieldName.replace(Negoptim.NegoptimHelper.normalizeAPIName('Statement_Disc_'), '').left(1));
                    Component.Apex.OutputLink header = new Component.Apex.OutputLink();
                    header.expressions.value = '/{!statementActiveDiscountsMap[' + statementDiscOrder + '].recordId}';
                    header.target = '_blank';
                    Component.Apex.OutputText headerText = new Component.Apex.OutputText();
                    String fieldSuffix;
                    if (fieldWrapper.fieldLabel.contains('Four-Rem' + statementDiscOrder)) {
                        fieldSuffix = fieldWrapper.fieldLabel.replace('Four-Rem' + statementDiscOrder, '');
                    } else {
                    fieldSuffix = fieldWrapper.fieldName
                        .removeStartIgnoreCase(Negoptim.NegoptimHelper.normalizeAPIName('Statement_Disc_') + statementDiscOrder)
                        .removeEndIgnoreCase('__c')
                        .remove('_');
                    }
                    headerText.expressions.value = 'Four-' + '{!statementActiveDiscountsMap[' + statementDiscOrder + '].Name} ' + fieldSuffix;
                    header.childComponents.add(headerText);
                    column.facets.header = header;
                }
            }
            if (String.isBlank(fieldWrapper.nonConditional?.widthStyle)) {
                column.headerClass += ' limit-width-130px ';
            }
            return column;
        }

        public Component.Apex.Repeat getClientClusters(String clusterType, Integer clusterNameLength) {

            Component.Apex.Repeat clientClustersRepeat = new Component.Apex.repeat();
            clientClustersRepeat.expressions.value = clusterType.equals('new') ? '{!categoryBUClustersMap[group.categoryId]}' : '{!categoryBUClustersRefMap[group.categoryId]}';
            clientClustersRepeat.var = 'buCluster';
            Component.Apex.Column column = new Component.Apex.Column();
            column.expressions.styleClass = 'text-center {!item.id} {!IF(item["Negoptim__Version__c"] != NULL, "history", "")}';
            column.headerClass = 'text-center checkbox inner-header';
            column.style = 'min-width: 30px';
            // column.style = 'min-width:'+ (clusterNameLength * 6) + 'px';

            Component.Apex.OutputLink header = new Component.Apex.OutputLink();
            header.expressions.value = '/{!buCluster.orgaBU.Id}';
            header.target = '_blank';
            header.expressions.rendered = '{!buCluster.orgaBU != null}';
            Component.Apex.OutputText headerText = new Component.Apex.OutputText();
            headerText.expressions.value = '{!buCluster.orgaBU.Name}';
            header.childComponents.add(headerText);
            column.facets.header = header;

            if (clusterType.equals('new')) {
                String fieldName = Negoptim.NegoptimHelper.normalizeAPIName('Client_Clust');
                column.expressions.styleClass += ' highlight-{!item.Negoptim__Client_Status__c}';
                column.footerClass = 'text-center';
                Component.Apex.OutputPanel panel = new Component.Apex.OutputPanel();
                panel.expressions.rendered = '{!AND(buCluster.orgaBU != null, CONTAINS(fieldsToCountList_serialized, \'"' + fieldName + '\'&TEXT(buCluster.stratIndex+1) + \'__c"\'), buCluster.isDisabled == false)}';
                Component.Apex.OutputText hiddenText = new Component.Apex.OutputText();
                hiddenText.style = 'display: none;';
                hiddenText.expressions.styleClass = '{!IF(ISBLANK(buCluster.orgaBU.Name),"", group.categoryId + "' + fieldName + '"&TEXT(buCluster.stratIndex+1) + "__c")}';
                hiddenText.expressions.value = '{!categoryCountMap["' + fieldName + '"& TEXT(buCluster.stratIndex+1) &"__c"]}';
                Component.Apex.OutputText visibleText = new Component.Apex.OutputText();
                visibleText.expressions.styleClass = '{!IF(ISBLANK(buCluster.orgaBU.Name),"","text-center visible_" + group.categoryId + "' + fieldName + '"&TEXT(buCluster.stratIndex+1) + "__c")}';
                visibleText.value = '0';
                panel.childComponents.add(hiddenText);
                panel.childComponents.add(visibleText);
                column.facets.footer = panel;

                Component.Apex.InputField input = new Component.Apex.InputField();
                input.expressions.value = '{!item["Negoptim__Client_Clust"& TEXT(buCluster.stratIndex+1) &"__c"]}';
                input.expressions.styleClass = 'ASD_{!item.Id} inputNoEnter {!item.Id}_' + fieldName + '{!(buCluster.stratIndex+1)}__c';
                input.expressions.rendered = '{!AND(item["Negoptim__Version__c"] == NULL, buCluster.orgaBU != null, !readOnly, buCluster.isDisabled == false)}';
                input.expressions.onchange = 'toggleCheckboxes(this, "{!item.Id}", "clientClust", {!TEXT(buCluster.stratIndex+1)}, "{!group.categoryId}");';
                Component.Apex.OutputField output = new Component.Apex.OutputField();
                output.expressions.value= '{!item["Negoptim__Client_Clust"& TEXT(buCluster.stratIndex+1) &"__c"]}';
                output.expressions.rendered = '{!OR(AND(OR(item["Negoptim__Version__c"] <> NULL, readOnly), buCluster.orgaBU != null), AND(item["Negoptim__Version__c"] <> NULL, buCluster.isDisabled == true), AND(item["Negoptim__Version__c"] <> NULL, buCluster.hasHistory == true))}';

                column.childComponents.add(input);
                column.childComponents.add(output);
            }
            else if (clusterType.equals('ref')) {

                String fieldName = Negoptim.NegoptimHelper.normalizeAPIName('Ref_Client_Clust');
                column.expressions.styleClass = 'text-center highlight-ref {!IF(item["Negoptim__Version__c"] != NULL, "history", "")}';
                column.footerClass = 'text-center';
                Component.Apex.OutputPanel panel = new Component.Apex.OutputPanel();
                panel.expressions.rendered = '{!AND(buCluster.orgaBU != null, CONTAINS(fieldsToCountList_serialized, \'"' + fieldName + '\'&TEXT(buCluster.stratIndex+1) + \'__c"\'))}';
                Component.Apex.OutputText hiddenText = new Component.Apex.OutputText();
                hiddenText.style = 'display: none;';
                hiddenText.expressions.styleClass = '{!IF(ISBLANK(buCluster.orgaBU.Name),"", group.categoryId + "' + fieldName + '"&TEXT(buCluster.stratIndex+1) + "__c")}';
                hiddenText.expressions.value = '{!categoryCountMap["' + fieldName + '"& TEXT(buCluster.stratIndex+1) &"__c"]}';
                Component.Apex.OutputText visibleText = new Component.Apex.OutputText();
                visibleText.expressions.styleClass = '{!IF(ISBLANK(buCluster.orgaBU.Name),"","text-center visible_" + group.categoryId + "' + fieldName + '"&TEXT(buCluster.stratIndex+1) + "__c")}';
                visibleText.value = '0';
                panel.childComponents.add(hiddenText);
                panel.childComponents.add(visibleText);
                column.facets.footer = panel;
                Component.Apex.OutputField output = new Component.Apex.OutputField();
                output.expressions.value= '{!item["Negoptim__Ref_Client_Clust"& TEXT(buCluster.stratIndex+1) &"__c"]}';
                output.expressions.rendered = '{!buCluster.orgaBU != null}';
                column.childComponents.add(output);
            }
            clientClustersRepeat.childComponents.add(column);
            return clientClustersRepeat;
        }

        public Component.Apex.Repeat getClientCplt(String clusterType, Integer clusterNameLength) {
            Component.Apex.Repeat clientClustersRepeat = new Component.Apex.repeat();
            clientClustersRepeat.expressions.value = clusterType.equals('new') ? '{!categoryBUCpltMap[group.categoryId]}' : '{!categoryBUCpltRefMap[group.categoryId]}';
            clientClustersRepeat.var = 'buCluster';
            Component.Apex.Column column = new Component.Apex.Column();
            column.expressions.styleClass = 'text-center {!IF(item["Negoptim__Version__c"] != NULL, "history", "")}';
            column.headerClass = 'text-center checkbox inner-header';
            column.style = 'min-width:'+ (clusterNameLength * 6) + 'px';

            Component.Apex.OutputLink header = new Component.Apex.OutputLink();
            header.expressions.value = '/{!buCluster.orgaBU.Id}';
            header.target = '_blank';
            header.expressions.rendered = '{!buCluster.orgaBU != null}';
            Component.Apex.OutputText headerText = new Component.Apex.OutputText();
            headerText.expressions.value = '{!buCluster.orgaBU.Name}';
            header.childComponents.add(headerText);
            column.facets.header = header;

            if (clusterType.equals('new')) {
                String fieldName = Negoptim.NegoptimHelper.normalizeAPIName('Client_Clust_Cplt');
                column.footerClass = 'text-center';
                Component.Apex.OutputPanel panel = new Component.Apex.OutputPanel();
                panel.expressions.rendered = '{!AND(buCluster.orgaBU != null, CONTAINS(fieldsToCountList_serialized, \'"' + fieldName + '\'&TEXT(buCluster.stratIndex+1) + \'__c"\'), buCluster.isDisabled == false)}';
                Component.Apex.OutputText hiddenText = new Component.Apex.OutputText();
                hiddenText.style = 'display: none;';
                hiddenText.expressions.styleClass = '{!IF(ISBLANK(buCluster.orgaBU.Name),"", group.categoryId + "' + fieldName + '"&TEXT(buCluster.stratIndex+1) + "__c")}';
                hiddenText.expressions.value = '{!categoryCountMap["' + fieldName + '"& TEXT(buCluster.stratIndex+1) &"__c"]}';
                Component.Apex.OutputText visibleText = new Component.Apex.OutputText();
                visibleText.expressions.styleClass = '{!IF(ISBLANK(buCluster.orgaBU.Name),"","text-center visible_" + group.categoryId + "' + fieldName + '"&TEXT(buCluster.stratIndex+1) + "__c")}';
                visibleText.value = '0';
                panel.childComponents.add(hiddenText);
                panel.childComponents.add(visibleText);
                column.facets.footer = panel;

                Component.Apex.InputField input = new Component.Apex.InputField();
                input.expressions.value = '{!item["Negoptim__Client_Clust_Cplt"& TEXT(buCluster.stratIndex+1) &"__c"]}';
                input.expressions.styleClass = 'ASD_{!item.Id} inputNoEnter {!item.Id}_' + fieldName + '{!(buCluster.stratIndex+1)}__c';
                input.expressions.rendered = '{!AND(item["Negoptim__Version__c"] == NULL, buCluster.orgaBU != null, !readOnly, buCluster.isDisabled == false)}';
                ///input.expressions.onchange = 'toggleCmplt(this, "{!item.Id}", );';
                input.expressions.onchange = ' toggleCheckboxes(this, "{!item.Id}", "clientClusterCplt", {!TEXT(buCluster.stratIndex+1)}, "{!group.categoryId}"); handleClientStatusColors("{!item.Id}_Client_Status__col");';
                Component.Apex.OutputField output = new Component.Apex.OutputField();
                output.expressions.value= '{!item["Negoptim__Client_Clust_Cplt"& TEXT(buCluster.stratIndex+1) &"__c"]}';
                output.expressions.rendered = '{!OR(AND(OR(item["Negoptim__Version__c"] <> NULL, readOnly), buCluster.orgaBU != null), AND(item["Negoptim__Version__c"] <> NULL, buCluster.isDisabled == true), AND(item["Negoptim__Version__c"] <> NULL, buCluster.hasHistory == true))}';

                column.childComponents.add(input);
                column.childComponents.add(output);
                /*column.footerClass = 'text-center';
                Component.Apex.OutputPanel panel = new Component.Apex.OutputPanel();
                panel.expressions.rendered = '{!buCluster.orgaBU != null}';
                Component.Apex.OutputText hiddenText = new Component.Apex.OutputText();
                hiddenText.style = 'display: none;';
                hiddenText.expressions.styleClass = '{!IF(ISBLANK(buCluster.orgaBU.Name),"", group.categoryId + "Client_ClustCplt__c")}';
                hiddenText.expressions.value = '{!categoryCountMap["Client_ClustCplt__c"]}';
                Component.Apex.OutputText visibleText = new Component.Apex.OutputText();
                visibleText.expressions.styleClass = '{!IF(ISBLANK(buCluster.orgaBU.Name),"","text-center visible_" + group.categoryId + "Client_ClustCplt__c")}';
                visibleText.value = '0';
                panel.childComponents.add(hiddenText);
                panel.childComponents.add(visibleText);
                column.facets.footer = panel;

                Component.Apex.InputField input = new Component.Apex.InputField();
                input.expressions.value = '{!item["Client_ClustCplt__c"]}';
                input.expressions.styleClass = '{!item.Id}_Client_ClustCplt__c';
                input.expressions.rendered = '{!AND(item["Version__c"] == NULL, buCluster.orgaBU != null, !readOnly)}';
                ////input.expressions.onchange = 'selectCplt(this, "{!item.Id}");';
                input.expressions.onchange = 'calculateTotal("Client_ClustCplt__c","{!item.Id}", "{!group.categoryId}", "{!item.Assortment_BU__c}");';
                Component.Apex.OutputField output = new Component.Apex.OutputField();
                output.expressions.value= '{!item["Client_ClustCplt__c"]}';
                output.expressions.rendered = '{!AND(OR(item["Version__c"] <> NULL, readOnly), buCluster.orgaBU != null)}';

                column.childComponents.add(input);
                column.childComponents.add(output);*/
            } else if (clusterType.equals('ref')) {
                String fieldName = Negoptim.NegoptimHelper.normalizeAPIName('Ref_Client_Clust_Cplt');
                column.expressions.styleClass = 'text-center highlight-ref {!IF(item["Negoptim__Version__c"] != NULL, "history", "")}';
                column.footerClass = 'text-center';
                Component.Apex.OutputPanel panel = new Component.Apex.OutputPanel();
                panel.expressions.rendered = '{!buCluster.orgaBU != null}';
                Component.Apex.OutputText hiddenText = new Component.Apex.OutputText();
                hiddenText.style = 'display: none;';
                hiddenText.expressions.styleClass = '{!IF(ISBLANK(buCluster.orgaBU.Name),"", group.categoryId + "' + fieldName + '"&TEXT(buCluster.stratIndex+1) + "__c")}';
                hiddenText.expressions.value = '{!categoryCountMap["' + fieldName + '"& TEXT(buCluster.stratIndex+1) &"__c"]}';
                Component.Apex.OutputText visibleText = new Component.Apex.OutputText();
                visibleText.expressions.styleClass = '{!IF(ISBLANK(buCluster.orgaBU.Name),"","text-center visible_" + group.categoryId + "' + fieldName + '"&TEXT(buCluster.stratIndex+1) + "__c")}';
                visibleText.value = '0';
                panel.childComponents.add(hiddenText);
                panel.childComponents.add(visibleText);
                column.facets.footer = panel;
                Component.Apex.OutputField output = new Component.Apex.OutputField();
                output.expressions.value= '{!item["Negoptim__Ref_Client_Clust_Cplt"& TEXT(buCluster.stratIndex+1) &"__c"]}';
                output.expressions.rendered = '{!AND(buCluster.orgaBU != null, CONTAINS(fieldsToCountList_serialized, \'"' + fieldName + '\'&TEXT(buCluster.stratIndex+1) + \'__c"\'))}';
                column.childComponents.add(output);
                /* column.expressions.styleClass = 'text-center highlight-ref {!IF(item["Version__c"] != NULL, "history", "")}';
                column.footerClass = 'text-center';
                Component.Apex.OutputPanel panel = new Component.Apex.OutputPanel();
                panel.expressions.rendered = '{!buCluster.orgaBU != null}';
                Component.Apex.OutputText hiddenText = new Component.Apex.OutputText();
                hiddenText.style = 'display: none;';
                hiddenText.expressions.styleClass = '{!IF(ISBLANK(buCluster.orgaBU.Name),"", group.categoryId + "Ref_Client_ClustCplt__c")}';
                hiddenText.expressions.value = '{!categoryCountMap["Ref_Client_ClustCplt__c"]}';
                Component.Apex.OutputText visibleText = new Component.Apex.OutputText();
                visibleText.expressions.styleClass = '{!IF(ISBLANK(buCluster.orgaBU.Name),"","text-center visible_" + group.categoryId + "Ref_Client_ClustCplt__c")}';
                visibleText.value = '0';
                panel.childComponents.add(hiddenText);
                panel.childComponents.add(visibleText);
                column.facets.footer = panel;
                Component.Apex.OutputField output = new Component.Apex.OutputField();
                output.expressions.value= '{!item["Ref_Client_ClustCplt__c"]}';
                output.expressions.rendered = '{!buCluster.orgaBU != null}';
                column.childComponents.add(output);*/
            }
            clientClustersRepeat.childComponents.add(column);
            return clientClustersRepeat;
        }
    }

    /**
     * @author ULiT
     * @date 15 June 2021
     * @description wrapper class used to serialize and deserialize active taxes on the level of Assortment BUs/Net Price Statement
    */
    public class StatementWrapper {
        // the Id of the Orga_Taxes__c record or the Pol_Com_Condition__c record
        public Id recordId {get; set;}
        // the name of the Orga_Taxes__c record or the Pol_Com_Condition__c record
        public String Name {get; set;}
        // the display order of the statement: 1-20 for Orga_Taxes__c / 1-9 for Pol_Com_Condition__c
        public Integer displayOrder {get; set;}
        // statement type for discont statements (U, %)
        public String conditionMode {get; set;}

        public StatementWrapper(Id recordId, String Name, Integer displayOrder, String conditionMode) {
            this.recordId = recordId;
            this.Name = Name;
            this.displayOrder = displayOrder;
            this.conditionMode = conditionMode;
        }

        public StatementWrapper(Id recordId, String Name, Integer displayOrder) {
            this(recordId, Name, displayOrder, '');
        }
    }

	public class NegoptimSettings {
        public String sBusinessType {get; set;}
        // Grid Settings
        public String assortmentMatrixGridLayout {get; set;}
        public String assortmentMatrixTargetGridLayout {get; set;}
      
        // Grid Settings Profiles
        public String[] assortmentMatrixProfile {get; set;}
        public String[] assortmentMatrixTargetProfile {get; set;}
        
        // Page Settings
        public Boolean openPagesFilterSectionByDefault {get; set;} // controls if the filter section is open or closed by default in all pages and components of the app
        public Boolean manageAssortByPersonalizedCategory {get; set;}
        // higer level packaging Id
        public Id higherLevelPackagingRecordTypeId {get; set;}
    }
}