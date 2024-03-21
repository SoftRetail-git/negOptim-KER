/**
 * @author ULiT
 * @date 26-12-2019
 * @Description helper class that groups commun methods such as calculation for Assortment KPIs such as
 * DV and DN and fetching assortment bu clustes
 * note (Circuit-->Market)  (Enseigne-->Client)
*/
global with sharing class AssortmentServices {

    public List<Negoptim__Assortment_Detail__c> assortmentDetailsList; // a list of Negoptim__Assortment_Detail__c
    global Map<Id, ResultWrapper> resultWrapperMap; // a map of Negoptim__Assortment_BU__r.Negoptim__BU_Target__c => ResultWrapper
	private Boolean manageAssortByPersonalizedCategory;
    
    global AssortmentServices(List<Negoptim__Assortment_Detail__c> assortmentDetailsList) {
        // NegoptimSettings settings = GlobalSettingsManager.loadGlobalSettings();
        this.manageAssortByPersonalizedCategory = true;
        this.assortmentDetailsList = assortmentDetailsList;
        this.resultWrapperMap = this.getResultWrapperMap();
    }

    global AssortmentServices(Set<Id> assortmentDetailsIdSet) {
        this([SELECT Id, Negoptim__Category__c, Negoptim__Category__r.Negoptim__Path__c, Negoptim__Client_Category__c, Negoptim__Client_Category__r.Negoptim__Path__c, Negoptim__Assortment_BU__c, Negoptim__Assortment_BU__r.Negoptim__BU_Target__c,
              Negoptim__Assortment_BU__r.Negoptim__BU_Target__r.Negoptim__Multiple_Complementary__c, Negoptim__Assortment_BU__r.Negoptim__Orga_HE__c, Negoptim__Assortment_BU__r.Negoptim__Orga_HE__r.Negoptim__Path__c,Negoptim__Year__c,
              Negoptim__Assortment_BU__r.Negoptim__Ass_BDate__c, Negoptim__Assortment_BU__r.Negoptim__Ass_EDate__c, Negoptim__Last_History__c, Negoptim__Assortment_BU__r.Negoptim__Assortment_parent__c,
              Negoptim__Assortment_BU__r.Negoptim__Assortment_parent__r.Negoptim__Ass_BDate__c, Negoptim__Assortment_BU__r.Negoptim__Assortment_parent__r.Negoptim__Ass_EDate__c, Negoptim__Assortment_BU__r.Negoptim__Year__c
              FROM Negoptim__Assortment_Detail__c
              WHERE Id IN :assortmentDetailsIdSet]);
    }

    global ResultWrapper getResultWrapperForAssortment(Id buTargetId) {
        return this.resultWrapperMap.get(buTargetId);
    }

    /**
     * @param assortmentDetailsList list of Negoptim__Assortment_Detail__c that must have quiered fields Negoptim__Assortment_BU__c, Negoptim__Category__c, Negoptim__Category__r.Negoptim__Path__c,
     * Negoptim__Assortment_BU__r.Negoptim__Orga_HE__c, Negoptim__Assortment_BU__r.Negoptim__Orga_HE__r.Negoptim__Path__c, Negoptim__Assortment_BU__r.Negoptim__BU_Target__c
     * @return Map<Id, Map<Id, Map<Integer, Negoptim__Orga_BU__c>>>
     * @return NULL in case of SObjectException (fields aren't queried)
     * @description
     * 1- loops over assortmentDetailsList and collects BU Target Ids in Set assortmentsBUTargetIdSet
     * 2- query assortment clusters under the assortment bu targets using assortmentsBUTargetIdSet, and orders the query by assortement_Strat__c (strat index),
     *    Negoptim__Category__r.Negoptim__Level__c DESC, and Negoptim__Category__c, this priorities a cluster over another on the same start with a lower category level over a
     *    start with a null category
     * 3- for each detail, for each cluster
     *    if the cluster category is child of the assortmentDetail.AssortmentBU category, and the detail category is a child of the cluster category then
     *    the cluster is assigned to the detail
    */
    private Map<Id, ResultWrapper> getResultWrapperMap() {
        if (this.resultWrapperMap == null) {
            try {
                Set<Id> assortmentsBUTargetIdSet = new Set<Id>();
                Map<String, Negoptim__Assortment_Detail__c> detailsMap = new Map<String, Negoptim__Assortment_Detail__c>();
                // the result map to return
                Map<Id, Map<Id, Map<Integer, Negoptim__Orga_BU__c>>> result = new Map<Id, Map<Id, Map<Integer, Negoptim__Orga_BU__c>>>();
                Map<Id, ResultWrapper> resultWrapperMap = new Map<Id, ResultWrapper>();
                if(assortmentDetailsList != null && !assortmentDetailsList.isEmpty()) {
                    for (Negoptim__Assortment_Detail__c assortmentDetail : assortmentDetailsList) {
                        assortmentsBUTargetIdSet.add(assortmentDetail.Negoptim__Assortment_BU__r.Negoptim__BU_Target__c);
                        String key = (manageAssortByPersonalizedCategory ? assortmentDetail.Negoptim__Client_Category__c : assortmentDetail.Negoptim__Category__c) + '_' + assortmentDetail.Negoptim__Assortment_BU__c;
                        if (!detailsMap.containsKey(key) || (assortmentDetail.Negoptim__Last_History__c != null && detailsMap.get(key).Negoptim__Last_History__c == null)) {
                            detailsMap.put(key, assortmentDetail);
                        }
                    }
                    // get clusters corresponding to assortment details bu targets
                    List<Negoptim__Orga_BU__c> clustersList = [SELECT Id, Name, Negoptim__BU_Code__c, Negoptim__Assortment_Strat__c, Negoptim__Country_Origin__c,
                                                     Negoptim__Country_Origin__r.Negoptim__BU_Code__c, Negoptim__Category__c, Negoptim__Category__r.Negoptim__Path__c,
                                                     Negoptim__Weighted_Distribution_Manual__c, Negoptim__Weighted_Distribution_Manual_N1__c,
                                                     Negoptim__Weighted_Distribution_Manual_P1__c, Negoptim__Weighted_Distribution_Manual_P2__c,
                                                     Negoptim__SiteOfSales_Number__c, Negoptim__SiteOfSales_Number_N1__c, Negoptim__SiteOfSales_Number_P1__c,
                                                     Negoptim__SiteOfSales_Number_P2__c, Negoptim__Multiple_Complementary__c, Negoptim__BU_CDate__c, Negoptim__BU_ODate__c, Negoptim__Status__c
                                                     FROM Negoptim__Orga_BU__c
                                                     WHERE recordType.DeveloperName = 'Assortment_Cluster'
                                                     AND Negoptim__Country_Origin__c IN :assortmentsBUTargetIdSet
                                                     ORDER BY Negoptim__Assortment_Strat__c, Negoptim__Category__r.Negoptim__Level__c ASC, Negoptim__Category__c]; // lower level category has priority
                    // loop over assortment details to fill result map
                    for (Negoptim__Assortment_Detail__c detail : detailsMap.values()) {
                        Id categoryId = manageAssortByPersonalizedCategory ? detail.Negoptim__Client_Category__c : detail.Negoptim__Category__c;
                        Negoptim__Orga_HE__c categoryDetail = manageAssortByPersonalizedCategory ? detail.Negoptim__Client_Category__r : detail.Negoptim__Category__r;
                        if (!result.containsKey(detail.Negoptim__Assortment_BU__r.Negoptim__BU_Target__c)) {
                            result.put(detail.Negoptim__Assortment_BU__r.Negoptim__BU_Target__c, new Map<Id, Map<Integer, Negoptim__Orga_BU__c>>());
                            resultWrapperMap.put(detail.Negoptim__Assortment_BU__r.Negoptim__BU_Target__c, new ResultWrapper());
                        }
                        Date prospect_BDate = detail.Negoptim__Assortment_BU__r.Negoptim__Ass_BDate__c.addYears(1);
                        Date prospect_EDate = detail.Negoptim__Assortment_BU__r.Negoptim__Ass_EDate__c.addYears(1);
                        Date comparableDate = Date.today().year() == detail.Negoptim__Assortment_BU__r.Negoptim__Year__c ? Date.today() : detail.Negoptim__Assortment_BU__r.Negoptim__Ass_EDate__c;
                        Date assortmentBDate = detail.Negoptim__Assortment_BU__r.Negoptim__Ass_BDate__c;
                        Date assortmentEDate = detail.Negoptim__Assortment_BU__r.Negoptim__Ass_EDate__c;
                        Date assortmentParentBDate = detail.Negoptim__Assortment_BU__r.Negoptim__Assortment_parent__r?.Negoptim__Ass_BDate__c;
                        Date assortmentParentEDate = detail.Negoptim__Assortment_BU__r.Negoptim__Assortment_parent__r?.Negoptim__Ass_EDate__c;

                        for (Negoptim__Orga_BU__c cluster : clustersList) {
                            Boolean isClosed = comparableDate == Date.today() ? cluster.Negoptim__BU_CDate__c > comparableDate : cluster.Negoptim__BU_CDate__c < comparableDate;
                            if (cluster.Negoptim__Country_Origin__c == detail.Negoptim__Assortment_BU__r.Negoptim__BU_Target__c
                                && (cluster.Negoptim__Category__c == null
                                    || (categoryId != null && cluster.Negoptim__Category__c != null
                                        && categoryDetail != null
                                        && cluster.Negoptim__Category__r.Negoptim__Path__c != null && categoryDetail.Negoptim__Path__c != null
                                        && cluster.Negoptim__Category__r.Negoptim__Path__c.startsWith(detail.Negoptim__Assortment_BU__r.Negoptim__Orga_HE__r.Negoptim__Path__c)
                                        && categoryDetail.Negoptim__Path__c.startsWith(cluster.Negoptim__Category__r.Negoptim__Path__c))))
                            {
                                if (cluster.Negoptim__BU_ODate__c <= prospect_BDate && cluster.Negoptim__BU_CDate__c > prospect_BDate) {
                                    if (!resultWrapperMap.get(detail.Negoptim__Assortment_BU__r.Negoptim__BU_Target__c).categoryProspectStratMap.containsKey(categoryId)) {
                                        resultWrapperMap.get(detail.Negoptim__Assortment_BU__r.Negoptim__BU_Target__c).categoryProspectStratMap.put(categoryId, new Map<Integer, Negoptim__Orga_BU__c>());
                                        resultWrapperMap.get(detail.Negoptim__Assortment_BU__r.Negoptim__BU_Target__c).categoryProspectCpltMap.put(categoryId, new Map<Integer, Negoptim__Orga_BU__c>());
                                    }
                                    Integer cluster_index;
                                    if (cluster.Negoptim__Assortment_Strat__c.containsIgnoreCase('Strat')) {
                                        cluster_index = Integer.valueOf(cluster.Negoptim__Assortment_Strat__c.removeStartIgnoreCase('Strat'));
                                        resultWrapperMap.get(detail.Negoptim__Assortment_BU__r.Negoptim__BU_Target__c).categoryProspectStratMap.get(categoryId).put(Integer.valueOf(cluster_index), cluster);
                                    }
                                    if (cluster.Negoptim__Assortment_Strat__c.containsIgnoreCase('Cplt')) {
                                        cluster_index = Integer.valueOf(cluster.Negoptim__Assortment_Strat__c.removeStartIgnoreCase('Cplt'));
                                        resultWrapperMap.get(detail.Negoptim__Assortment_BU__r.Negoptim__BU_Target__c).categoryProspectCpltMap.get(categoryId).put(Integer.valueOf(cluster_index), cluster);
                                    }
                                }
                                if (cluster.Negoptim__BU_ODate__c <= assortmentBDate
                                    && (cluster.Negoptim__BU_CDate__c == null || (cluster.Negoptim__BU_CDate__c > assortmentBDate)
                                        && (cluster.Negoptim__BU_CDate__c >= assortmentEDate || (cluster.Negoptim__BU_CDate__c < assortmentEDate && isClosed)))
                                    || (cluster.Negoptim__BU_ODate__c > assortmentBDate && cluster.Negoptim__BU_ODate__c < assortmentEDate && cluster.Negoptim__BU_ODate__c <= comparableDate)
                                    || (cluster.Negoptim__BU_CDate__c > assortmentBDate && cluster.Negoptim__BU_CDate__c < assortmentEDate && detail.Negoptim__Last_History__c != null))
                                {
                                    if (!resultWrapperMap.get(detail.Negoptim__Assortment_BU__r.Negoptim__BU_Target__c).categoryStratMap.containsKey(categoryId)) {
                                        resultWrapperMap.get(detail.Negoptim__Assortment_BU__r.Negoptim__BU_Target__c).categoryStratMap.put(categoryId, new Map<Integer, Negoptim__Orga_BU__c>());
                                        resultWrapperMap.get(detail.Negoptim__Assortment_BU__r.Negoptim__BU_Target__c).categoryCpltMap.put(categoryId, new Map<Integer, Negoptim__Orga_BU__c>());
                                        resultWrapperMap.get(detail.Negoptim__Assortment_BU__r.Negoptim__BU_Target__c).closedCategoryStratMap.put(categoryId, new Map<Integer, Negoptim__Orga_BU__c>());
                                        resultWrapperMap.get(detail.Negoptim__Assortment_BU__r.Negoptim__BU_Target__c).closedCategoryCpltMap.put(categoryId, new Map<Integer, Negoptim__Orga_BU__c>());
                                    }
                                    Integer cluster_index;
                                    if (cluster.Negoptim__Assortment_Strat__c.containsIgnoreCase('Strat')) {
                                        cluster_index = Integer.valueOf(cluster.Negoptim__Assortment_Strat__c.removeStartIgnoreCase('Strat'));
                                        if (cluster.Negoptim__BU_CDate__c != null && cluster.Negoptim__BU_CDate__c > assortmentBDate
                                            && cluster.Negoptim__BU_CDate__c < assortmentEDate && cluster.Negoptim__BU_CDate__c <= comparableDate)
                                        {
                                            if(detail.Negoptim__Last_History__c != null)
                                                resultWrapperMap.get(detail.Negoptim__Assortment_BU__r.Negoptim__BU_Target__c).closedCategoryStratMap.get(categoryId).put(Integer.valueOf(cluster_index), cluster);
                                        } else {
                                            resultWrapperMap.get(detail.Negoptim__Assortment_BU__r.Negoptim__BU_Target__c).categoryStratMap.get(categoryId).put(Integer.valueOf(cluster_index), cluster);
                                        }
                                    }
                                    if (cluster.Negoptim__Assortment_Strat__c.containsIgnoreCase('Cplt')) {
                                        cluster_index = Integer.valueOf(cluster.Negoptim__Assortment_Strat__c.removeStartIgnoreCase('Cplt'));
                                        if (cluster.Negoptim__BU_CDate__c != null && cluster.Negoptim__BU_CDate__c > assortmentBDate
                                            && cluster.Negoptim__BU_CDate__c < assortmentEDate && cluster.Negoptim__BU_CDate__c <= comparableDate)
                                        {
                                            if(detail.Negoptim__Last_History__c != null)
                                                resultWrapperMap.get(detail.Negoptim__Assortment_BU__r.Negoptim__BU_Target__c).closedCategoryCpltMap.get(categoryId).put(Integer.valueOf(cluster_index), cluster);
                                        } else {
                                            resultWrapperMap.get(detail.Negoptim__Assortment_BU__r.Negoptim__BU_Target__c).categoryCpltMap.get(categoryId).put(Integer.valueOf(cluster_index), cluster);
                                        }
                                    }
                                }
                                if (detail.Negoptim__Assortment_BU__r.Negoptim__Assortment_parent__c != null) {
                                    if (cluster.Negoptim__BU_ODate__c <= assortmentParentBDate
                                        && (cluster.Negoptim__BU_CDate__c == null || (cluster.Negoptim__BU_CDate__c > assortmentParentBDate)
                                            && (cluster.Negoptim__BU_CDate__c >= assortmentParentEDate || (cluster.Negoptim__BU_CDate__c < assortmentParentEDate && isClosed)))
                                        || (cluster.Negoptim__BU_ODate__c > assortmentParentBDate && cluster.Negoptim__BU_ODate__c < assortmentParentEDate && cluster.Negoptim__BU_ODate__c <= comparableDate))
                                    {
                                        if (!resultWrapperMap.get(detail.Negoptim__Assortment_BU__r.Negoptim__BU_Target__c).categoryStratRefMap.containsKey(categoryId)) {
                                            resultWrapperMap.get(detail.Negoptim__Assortment_BU__r.Negoptim__BU_Target__c).categoryStratRefMap.put(categoryId, new Map<Integer, Negoptim__Orga_BU__c>());
                                            resultWrapperMap.get(detail.Negoptim__Assortment_BU__r.Negoptim__BU_Target__c).categoryCpltRefMap.put(categoryId, new Map<Integer, Negoptim__Orga_BU__c>());
                                        }
                                        Integer cluster_index;
                                        if (cluster.Negoptim__Assortment_Strat__c.containsIgnoreCase('Strat')) {
                                            cluster_index = Integer.valueOf(cluster.Negoptim__Assortment_Strat__c.removeStartIgnoreCase('Strat'));
                                            resultWrapperMap.get(detail.Negoptim__Assortment_BU__r.Negoptim__BU_Target__c).categoryStratRefMap.get(categoryId).put(Integer.valueOf(cluster_index), cluster);
                                        }
                                        if (cluster.Negoptim__Assortment_Strat__c.containsIgnoreCase('Cplt')) {
                                            cluster_index = Integer.valueOf(cluster.Negoptim__Assortment_Strat__c.removeStartIgnoreCase('Cplt'));
                                            resultWrapperMap.get(detail.Negoptim__Assortment_BU__r.Negoptim__BU_Target__c).categoryCpltRefMap.get(categoryId).put(Integer.valueOf(cluster_index), cluster);
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                return resultWrapperMap;
            } catch (System.SObjectException ex) {
                System.debug('Exception: >>>>>' + ex.getMessage() + ' - LINE: ' + ex.getLineNumber());
                System.debug(ex.getStackTraceString() + '<<<<<');
                
                return null;
            }
        } else {
            return this.resultWrapperMap;
        }
    }

    /**
     * @description this methods finds the most recent history of a product's movement. That is the most recent history of the asd with a cluster different than the
     * cluster of the current version
    */
    global Map<Id, Negoptim__Assortment_Detail__c> getLastMovementHistory() {
        Map<Id, Negoptim__Assortment_Detail__c> currentASDMap = new Map<Id, Negoptim__Assortment_Detail__c>(this.assortmentDetailsList);
        Set<Id> assortmentBUIdsSet = new Set<Id>();
        Set<Id> productIdsSet = new Set<Id>();
        //map to fill all the asd details last history for the product of Assortment bu (key = product + as bu, value = list of assortment detail history)
        Map<String, List<Negoptim__Assortment_Detail__c>> productLastHistoryListMap = new Map<String, List<Negoptim__Assortment_Detail__c>>();

        //map to fill all the asd details last history for its current validated assortment detail(key = assortment detail, value = list of assortment detail history)
        Map<Id, List<Negoptim__Assortment_Detail__c>> asdIdLastHistoryListMap = new Map<Id, List<Negoptim__Assortment_Detail__c>>();

        //map to fill the last changed clust er for each asd
        Map<Id, Negoptim__Assortment_Detail__c> asdLastHistoryCluster = new Map<Id, Negoptim__Assortment_Detail__c>();

        //get all assortment bu,products, switch products to search for the history
        for (Negoptim__Assortment_Detail__c asd : this.assortmentDetailsList) {
            assortmentBUIdsSet.add(asd.Negoptim__Assortment_BU__c);
            productIdsSet.add(asd.Negoptim__Product__c);
            if(asd.Negoptim__Product__r.Negoptim__Reference_Product__c != null) {
                productIdsSet.add(asd.Negoptim__Product__r.Negoptim__Reference_Product__c);
            }
        }
        //list of all asd history
        for(Negoptim__Assortment_Detail__c asd :  [SELECT Id, Negoptim__Ass_BU_Cluster__c, Negoptim__Version__c,
                                         Negoptim__Product__c, Negoptim__Assortment_BU__c,
                                         Negoptim__Ass_BU_Cluster__r.RecordtypeId,
                                         Negoptim__Ass_BU_Cluster__r.Recordtype.DeveloperName,
                                         Negoptim__Ass_BU_Cluster__r.Negoptim__Assortment_Strat__c
                                         FROM Negoptim__Assortment_Detail__c
                                         WHERE Negoptim__Assortment_BU__c IN :assortmentBUIdsSet
                                         AND Negoptim__Product__c IN :productIdsSet
                                         AND Negoptim__Status__c = 'Previously Validated'
                                         AND Negoptim__Version__c <> NULL
                                         ORDER By Negoptim__Assortment_BU__c, Negoptim__Product__c, Negoptim__Version__c])
        {
            String key = '' + asd.Negoptim__Product__c + asd.Negoptim__Assortment_BU__c;
            if(!productLastHistoryListMap.containsKey(key)) {
                productLastHistoryListMap.put(key, new List<Negoptim__Assortment_Detail__c>());
            }
            productLastHistoryListMap.get(key).add(asd);
        }
        //assign all the history of each assortment detail validated
        for(Negoptim__Assortment_Detail__c asd : this.assortmentDetailsList) {
            if(!asdIdLastHistoryListMap.containsKey(asd.Id)) {
                asdIdLastHistoryListMap.put(asd.Id, new List<Negoptim__Assortment_Detail__c>());
            }
            //check if the validated assortment detail have history for the current product
            String key = '' + asd.Negoptim__Product__c + asd.Negoptim__Assortment_BU__c;
            if(productLastHistoryListMap.containsKey(key)) {
                asdIdLastHistoryListMap.get(asd.Id).addAll(productLastHistoryListMap.get(key));
            }
            //check if the validated assortment detail have history for the switched product
            if(asd.Negoptim__Product__r.Negoptim__Reference_Product__c != null) {
                String keySwitch = '' + asd.Negoptim__Product__r.Negoptim__Reference_Product__c + asd.Negoptim__Assortment_BU__c;
                if(asdIdLastHistoryListMap.containsKey(asd.Id) && productLastHistoryListMap.containsKey(keySwitch)) {
                    asdIdLastHistoryListMap.get(asd.Id).addAll(productLastHistoryListMap.get(keySwitch));
                }
            }
        }
        // assign for each validated assrtment detail, the last history that the clusters have been changed
        for(Id asdId : asdIdLastHistoryListMap.keySet()) {
            Negoptim__Assortment_Detail__c currentASD = currentASDMap.get(asdId);
            for(Negoptim__Assortment_Detail__c asd: asdIdLastHistoryListMap.get(asdId)) {
                if(!asdLastHistoryCluster.containsKey(asdId)) {
                    asdLastHistoryCluster.put(asdId, asd);
                } else {
                    Negoptim__Assortment_Detail__c histoASD  =  asdLastHistoryCluster.get(asdId);
                    if(asd.Negoptim__Ass_BU_Cluster__c != currentASD.Negoptim__Ass_BU_Cluster__c && asd.Negoptim__Version__c > histoASD.Negoptim__Version__c){
                        asdLastHistoryCluster.put(asdId, asd);
                    }
                }
            }
        }
        return asdLastHistoryCluster;
    }

    /**
     * @description this method finds and returns a map of strat clusters for a specific assortment detail
     * it finds the strat clusters by BU Target and Category
     *
     * @param assortmentDetail the assortment detail to use to find strat clusters
     *
     * @return a map of clusterId => cluster
     */
    global Map<Id, Negoptim__Orga_BU__c> getStratClusters(Negoptim__Assortment_Detail__c assortmentDetail) {
        Map<Id, Negoptim__Orga_BU__c> clusterStratsMap = new Map<Id, Negoptim__Orga_BU__c>();
        // get the result wrapper corresponding to the BU target
        ResultWrapper rw = this.getResultWrapperForAssortment(assortmentDetail.Negoptim__Assortment_BU__r.Negoptim__BU_Target__c);
        // get the clusters corresponding to the category of the assortment detail
        Id categoryId = manageAssortByPersonalizedCategory ? assortmentDetail.Negoptim__Client_Category__c : assortmentDetail.Negoptim__Category__c;
        if (rw != null && rw.categoryStratMap.get(categoryId) != null) {
            clusterStratsMap = new Map<Id, Negoptim__Orga_BU__c>(rw.categoryStratMap.get(categoryId).values());
        }
        return clusterStratsMap;
    }

    /**
     * @description this method finds and returns a map of cplt clusters for a specific assortment detail
     * it finds the cplt clusters by BU Target and Category
     *
     * @param assortmentDetail the assortment detail to use to find cplt clusters
     *
     * @return a map of cluster index => cluster
     */
    global Map<Integer, Negoptim__Orga_BU__c> getCpltClusters(Negoptim__Assortment_Detail__c assortmentDetail) {
        Map<Integer, Negoptim__Orga_BU__c> clusterCpltsMap = new Map<Integer, Negoptim__Orga_BU__c>();
        // get the result wrapper corresponding to the BU target
        ResultWrapper rw = this.getResultWrapperForAssortment(assortmentDetail.Negoptim__Assortment_BU__r.Negoptim__BU_Target__c);
        // get the clusters corresponding to the category of the assortment detail
        Id categoryId = manageAssortByPersonalizedCategory ? assortmentDetail.Negoptim__Client_Category__c : assortmentDetail.Negoptim__Category__c;
        if (rw != null && rw.categoryCpltMap.get(categoryId) != null) {
            return rw.categoryCpltMap.get(categoryId);
        }
        return clusterCpltsMap;
    }

    private Boolean isCplt(Negoptim__Assortment_Detail__c assortmentDetail) {
        Boolean isCplt = false;
        for (Integer i = 1 ; i <= this.getCpltClusters(assortmentDetail).size(); i++) {
            if ((Boolean) assortmentDetail.get(Negoptim.NegoptimHelper.normalizeAPIName('Client_Clust_Cplt' + i + '__c'))) {
                isCplt = true;
                break;
            }
        }
        return isCplt;
    }

    /* ************************************************************ Calculations ************************************************************ */
    /**
     * @description calculates the sum of Weighted Distribution Manual of all clusters depending on gap value
     * the Weighted Distribution value could be read from:
     * Negoptim__Weighted_Distribution_Manual_N1__c if gap is greater than or equal to 1
     * Negoptim__Weighted_Distribution_Manual__c if gap is equal to 0
     * Negoptim__Weighted_Distribution_Manual_P1__c if gap is equal to -1
     * Negoptim__Weighted_Distribution_Manual_P2__c if gap is less than or equal to -2
     *
     * @param clusters a list of Orga BU clusters
     * @param gap the difference between assortmentDetail year and current Year
     *
     * @return the sum of the weighted Distribution of clusters depending on gap value
     * @return 0 in case of SObjectException (fields aren't queried)
    */
    private Decimal getSumDVClusters(List<Negoptim__Orga_BU__c> clusters, Integer gap) {
        try {
            Decimal sumDVClusters = 0;
            if (clusters != null && !clusters.isEmpty()) {
                for (Negoptim__Orga_BU__c cluster : clusters) {
                    if (gap >= 1)
                        sumDVClusters += cluster.Negoptim__Weighted_Distribution_Manual_N1__c != null ? cluster.Negoptim__Weighted_Distribution_Manual_N1__c : 0;
                    if (gap == 0)
                        sumDVClusters += cluster.Negoptim__Weighted_Distribution_Manual__c != null ? cluster.Negoptim__Weighted_Distribution_Manual__c : 0;
                    if (gap == -1)
                        sumDVClusters += cluster.Negoptim__Weighted_Distribution_Manual_P1__c != null ? cluster.Negoptim__Weighted_Distribution_Manual_P1__c : 0;
                    if (gap <= -2)
                        sumDVClusters += cluster.Negoptim__Weighted_Distribution_Manual_P2__c != null ? cluster.Negoptim__Weighted_Distribution_Manual_P2__c : 0;
                }
            }
            return sumDVClusters;
        } catch (System.SObjectException ex) {
            System.debug('Exception: >>>>>' + ex.getMessage() + ' - LINE: ' + ex.getLineNumber());
            System.debug(ex.getStackTraceString() + '<<<<<');
            return 0;
        }
    }

    /**
     * @description calculates the sum of the number of Site of Sales of all clusters depending on gap value
     * the Weighted Distribution value could be read from:
     * Negoptim__SiteOfSales_Number_N1__c if gap is greater than or equal to 1
     * Negoptim__SiteOfSales_Number__c if gap is equal to 0
     * Negoptim__SiteOfSales_Number_P1__c if gap is equal to -1
     * Negoptim__SiteOfSales_Number_P2__c if gap is less than or equal to -2
     *
     * @param clusters a list of Orga BU clusters
     * @param gap the difference between assortmentDetail year and current Year
     *
     * @return the sum of the number of Site of Sales of clusters depending on gap value
     * @return 0 in case of SObjectException (fields aren't queried)
    */
    private Decimal getSumSOSClusters(List<Negoptim__Orga_BU__c> clusters, Integer gap) {
        try {
            Decimal sumSOSClusters = 0;
            if (clusters != null && !clusters.isEmpty()) {
                for (Negoptim__Orga_BU__c cluster : clusters) {
                    if (gap >= 1)
                        sumSOSClusters += cluster.Negoptim__SiteOfSales_Number_N1__c != null ? cluster.Negoptim__SiteOfSales_Number_N1__c : 0;
                    if (gap == 0)
                        sumSOSClusters += cluster.Negoptim__SiteOfSales_Number__c != null ? cluster.Negoptim__SiteOfSales_Number__c : 0;
                    if (gap == -1)
                        sumSOSClusters += cluster.Negoptim__SiteOfSales_Number_P1__c != null ? cluster.Negoptim__SiteOfSales_Number_P1__c : 0;
                    if (gap <= -2)
                        sumSOSClusters += cluster.Negoptim__SiteOfSales_Number_P2__c != null ? cluster.Negoptim__SiteOfSales_Number_P2__c : 0;
                }
            }
            return sumSOSClusters;
        } catch (System.SObjectException ex) {
            System.debug('Exception: >>>>>' + ex.getMessage() + ' - LINE: ' + ex.getLineNumber());
            System.debug(ex.getStackTraceString() + '<<<<<');
            return 0;
        }
    }

    /**
     * @description gets and retuns the number of Site of Sales of the BU Source of the assortment detail depending on the gap value
     * the Weighted Distribution value could be read from:
     * Negoptim__SiteOfSales_Number_N1__c if gap is greater than or equal to 1
     * Negoptim__SiteOfSales_Number__c if gap is equal to 0
     * Negoptim__SiteOfSales_Number_P1__c if gap is equal to -1
     * Negoptim__SiteOfSales_Number_P2__c if gap is less than or equal to -2
     *
     * @param assortmentDetail the assortment detail for which the method will get and return the number od Site of Sales of the BU Source
     * @param gap the difference between assortmentDetail year and current Year
     *
     * @return the number of Site of Sales of assortmentDetail's BU Source
     * @return 0 in case of SObjectException (fields aren't queried)
     */
    /*private Decimal getSOSCircuit(Negoptim__Assortment_Detail__c assortmentDetail, Integer gap) {
        try {
            Decimal sumSOSCircuit = 0;
            if (gap >= 1)
                sumSOSCircuit = assortmentDetail.Negoptim__Assortment_BU__r.Negoptim__BU_Source__r.Negoptim__SiteOfSales_Number_N1__c != null ? assortmentDetail.Negoptim__Assortment_BU__r.Negoptim__BU_Source__r.Negoptim__SiteOfSales_Number_N1__c : 0;
            if (gap == 0)
                sumSOSCircuit = assortmentDetail.Negoptim__Assortment_BU__r.Negoptim__BU_Source__r.Negoptim__SiteOfSales_Number__c != null ? assortmentDetail.Negoptim__Assortment_BU__r.Negoptim__BU_Source__r.Negoptim__SiteOfSales_Number__c : 0;
            if (gap == -1)
                sumSOSCircuit = assortmentDetail.Negoptim__Assortment_BU__r.Negoptim__BU_Source__r.Negoptim__SiteOfSales_Number_P1__c != null ? assortmentDetail.Negoptim__Assortment_BU__r.Negoptim__BU_Source__r.Negoptim__SiteOfSales_Number_P1__c : 0;
            if (gap <= -2)
                sumSOSCircuit = assortmentDetail.Negoptim__Assortment_BU__r.Negoptim__BU_Source__r.Negoptim__SiteOfSales_Number_P2__c != null ? assortmentDetail.Negoptim__Assortment_BU__r.Negoptim__BU_Source__r.Negoptim__SiteOfSales_Number_P2__c : 0;
            return sumSOSCircuit;
        } catch (System.SObjectException ex) {
            System.debug('Exception: >>>>>' + ex.getMessage() + ' - LINE: ' + ex.getLineNumber());
            System.debug(ex.getStackTraceString() + '<<<<<');
            return 0;
        }
    }*/

    /**
     * @return the WeightedDistribution of the BU Target depending of the gap
     */
    private Decimal getBUTargetWD(Negoptim__Assortment_Detail__c assortmentDetail, Integer gap) {
        Decimal bannerWD = 0;
        if (gap >= 1 && assortmentDetail.Negoptim__Assortment_BU__r.Negoptim__BU_Target__r.Negoptim__Weighted_Distribution_Manual_N1__c != null) {
            bannerWD = assortmentDetail.Negoptim__Assortment_BU__r.Negoptim__BU_Target__r.Negoptim__Weighted_Distribution_Manual_N1__c;
        } else if (gap == 0 && assortmentDetail.Negoptim__Assortment_BU__r.Negoptim__BU_Target__r.Negoptim__Weighted_Distribution_Manual__c != null) {
            bannerWD = assortmentDetail.Negoptim__Assortment_BU__r.Negoptim__BU_Target__r.Negoptim__Weighted_Distribution_Manual__c;
        } else if (gap == -1 && assortmentDetail.Negoptim__Assortment_BU__r.Negoptim__BU_Target__r.Negoptim__Weighted_Distribution_Manual_P1__c != null) {
            bannerWD = assortmentDetail.Negoptim__Assortment_BU__r.Negoptim__BU_Target__r.Negoptim__Weighted_Distribution_Manual_P1__c;
        } else if (gap <= -2 && assortmentDetail.Negoptim__Assortment_BU__r.Negoptim__BU_Target__r.Negoptim__Weighted_Distribution_Manual_P2__c != null) {
            bannerWD = assortmentDetail.Negoptim__Assortment_BU__r.Negoptim__BU_Target__r.Negoptim__Weighted_Distribution_Manual_P2__c;
        }
        return bannerWD;
    }

   /**
     * @return the SiteOfSalesNumber of the BU Target depending of the gap
     */
    private Decimal getBUTargetSOS(Negoptim__Assortment_Detail__c assortmentDetail, Integer gap) {
        Decimal bannerSOS = 0;
        if (gap >= 1 && assortmentDetail.Negoptim__Assortment_BU__r.Negoptim__BU_Target__r.Negoptim__SiteOfSales_Number_N1__c != null) {
            bannerSOS = assortmentDetail.Negoptim__Assortment_BU__r.Negoptim__BU_Target__r.Negoptim__SiteOfSales_Number_N1__c;
        } else if (gap == 0 && assortmentDetail.Negoptim__Assortment_BU__r.Negoptim__BU_Target__r.Negoptim__SiteOfSales_Number__c != null) {
            bannerSOS = assortmentDetail.Negoptim__Assortment_BU__r.Negoptim__BU_Target__r.Negoptim__SiteOfSales_Number__c;
        } else if (gap == -1 && assortmentDetail.Negoptim__Assortment_BU__r.Negoptim__BU_Target__r.Negoptim__SiteOfSales_Number_P1__c != null) {
            bannerSOS = assortmentDetail.Negoptim__Assortment_BU__r.Negoptim__BU_Target__r.Negoptim__SiteOfSales_Number_P1__c;
        } else if (gap <= -2 && assortmentDetail.Negoptim__Assortment_BU__r.Negoptim__BU_Target__r.Negoptim__SiteOfSales_Number_P2__c != null) {
            bannerSOS = assortmentDetail.Negoptim__Assortment_BU__r.Negoptim__BU_Target__r.Negoptim__SiteOfSales_Number_P2__c;
        }
        return bannerSOS;
    }

    /**
     * @description calculates Negoptim__New_Client_WD_MarketBased__c depending on the gap in years
     * @parameter assortmentDetail must query fields for calculation are Negoptim__Ass_BU_Cluster__c and Negoptim__Year__c
     * @parameter gap is the difference between the current year and the year of the assortment detail
     * @return decimal value of assortmentDetail Negoptim__New_Client_WD_MarketBased__c
     * @return NULL in case of SObjectException (fields aren't queried)
    */
    private Decimal getWDMarketBased(Negoptim__Assortment_Detail__c assortmentDetail, Integer gap) {
        Decimal WDMarketBased = 0;
        Map<Id, Negoptim__Orga_BU__c> clusterStratsMap = getStratClusters(assortmentDetail);
        Map<Integer, Negoptim__Orga_BU__c> clusterCpltsMap = getCpltClusters(assortmentDetail);
        try {
            Boolean next = false;
            if(clusterStratsMap != null && !clusterStratsMap.isEmpty() && clusterStratsMap.containsKey(assortmentDetail.Negoptim__Ass_BU_Cluster__c)) {
                for (Negoptim__Orga_BU__c cluster : clusterStratsMap.values()) {
                    if (cluster.Id == assortmentDetail.Negoptim__Ass_BU_Cluster__c || next) {
                        if (gap >= 1)
                            WDMarketBased += cluster.Negoptim__Weighted_Distribution_Manual_N1__c != null ? cluster.Negoptim__Weighted_Distribution_Manual_N1__c : 0;
                        if (gap == 0)
                            WDMarketBased += cluster.Negoptim__Weighted_Distribution_Manual__c != null ? cluster.Negoptim__Weighted_Distribution_Manual__c : 0;
                        if (gap == -1)
                            WDMarketBased += cluster.Negoptim__Weighted_Distribution_Manual_P1__c != null ? cluster.Negoptim__Weighted_Distribution_Manual_P1__c : 0;
                        if (gap <= -2)
                            WDMarketBased += cluster.Negoptim__Weighted_Distribution_Manual_P2__c != null ? cluster.Negoptim__Weighted_Distribution_Manual_P2__c : 0;
                        next = true;
                    }
                }
            } else if(clusterCpltsMap != null && !clusterCpltsMap.isEmpty()) {
                for (Integer i = 1; i <= clusterCpltsMap.size(); i++) {
                    if ((Boolean) assortmentDetail.get('Client_Clust_Cplt' + i + '__c') && clusterCpltsMap.containsKey(i - 1)) {
                        Negoptim__Orga_BU__c cluster = clusterCpltsMap.get(i - 1);
                        if (gap >= 1)
                            WDMarketBased += cluster.Negoptim__Weighted_Distribution_Manual_N1__c != null ? cluster.Negoptim__Weighted_Distribution_Manual_N1__c : 0;
                        if (gap == 0)
                            WDMarketBased += cluster.Negoptim__Weighted_Distribution_Manual__c != null ? cluster.Negoptim__Weighted_Distribution_Manual__c : 0;
                        if (gap == -1)
                            WDMarketBased += cluster.Negoptim__Weighted_Distribution_Manual_P1__c != null ? cluster.Negoptim__Weighted_Distribution_Manual_P1__c : 0;
                        if (gap <= -2)
                            WDMarketBased += cluster.Negoptim__Weighted_Distribution_Manual_P2__c != null ? cluster.Negoptim__Weighted_Distribution_Manual_P2__c : 0;
                    }
                }
            }
        } catch (System.SObjectException ex) {
            System.debug('Exception: >>>>>' + ex.getMessage() + ' - LINE: ' + ex.getLineNumber());
            System.debug(ex.getStackTraceString() + '<<<<<');
        }
        return WDMarketBased;
    }

    /**
     * @description calculates Negoptim__New_Client_WD_MarketBased__c of the year of the assortment detail
    */
    public Decimal getWDMarketBased(Negoptim__Assortment_Detail__c assortmentDetail) {
        Integer gap = assortmentDetail.Negoptim__Year__c != null ? (Integer) assortmentDetail.Negoptim__Year__c - Date.today().year() : 1;
        return getWDMarketBased(assortmentDetail, gap);
    }

    /**
     * @description calculater of the year after the year of the assortment detail (Like for Like)
    */
    public Decimal getL4LWDMarketBased(Negoptim__Assortment_Detail__c assortmentDetail) {
        Integer gap = assortmentDetail.Negoptim__Year__c != null ? (Integer) assortmentDetail.Negoptim__Year__c - Date.today().year()  + 1 : 1;
        return getWDMarketBased(assortmentDetail, gap);
    }

    /**
     * @description calculates Negoptim__New_Client_WD_ClientBased__c depending on the gap in years
     * @parameter assortmentDetail must query fields for calculation Negoptim__Ass_BU_Cluster__c and Negoptim__Year__c
     * @parameter gap is the difference between the current year and the year of the assortment detail
     * @return decimal value of assortmentDetail Negoptim__New_Client_WD_ClientBased__c
     * @return NULL in case of SObjectException (fields aren't queried)
    */
    private Decimal getWDClientBased(Negoptim__Assortment_Detail__c assortmentDetail, Integer gap) {
        Decimal WDClientBased = 0;
        Map<Id, Negoptim__Orga_BU__c> clusterStratsMap = getStratClusters(assortmentDetail);
        Map<Integer, Negoptim__Orga_BU__c> clusterCpltsMap = getCpltClusters(assortmentDetail);
        try {
            // get WDMarketBased to use in calculation of WDClientBased
            Decimal WDMarketBased = getWDMarketBased(assortmentDetail, gap);
            if(clusterStratsMap != null && !clusterStratsMap.isEmpty() && clusterStratsMap.containsKey(assortmentDetail.Negoptim__Ass_BU_Cluster__c)) {
                Decimal sumDVClusters = getSumDVClusters(clusterStratsMap.values(), gap);
                WDClientBased = sumDVClusters == 0 ? null : (WDMarketBased / sumDVClusters) * 100;
            } else if(clusterCpltsMap != null && !clusterCpltsMap.isEmpty() && this.isCplt(assortmentDetail)) {
                Decimal buTargetWD = getBUTargetWD(assortmentDetail, gap);
                WDClientBased = buTargetWD == 0 ? null : (WDMarketBased / buTargetWD) * 100;
            }
        } catch (System.SObjectException ex) {
            System.debug('Exception: >>>>>' + ex.getMessage() + ' - LINE: ' + ex.getLineNumber());
            System.debug(ex.getStackTraceString() + '<<<<<');
        }
        return WDClientBased;
    }

    /**
     * @description calculates Negoptim__New_Client_WD_ClientBased__c of the year of the assortment detail
    */
    public Decimal getWDClientBased(Negoptim__Assortment_Detail__c assortmentDetail) {
        Integer gap = assortmentDetail.Negoptim__Year__c != null ? (Integer) assortmentDetail.Negoptim__Year__c - Date.today().year() : 1;
        return getWDClientBased(assortmentDetail, gap);
    }

    /**
     * @description calculates Negoptim__New_Client_WD_ClientBased__c of the year after the year of the assortment detail
	*/
    public Decimal getL4LWDClientBased(Negoptim__Assortment_Detail__c assortmentDetail) {
        Integer gap = assortmentDetail.Negoptim__Year__c != null ? (Integer) assortmentDetail.Negoptim__Year__c - Date.today().year() + 1 : 1;
        return getWDClientBased(assortmentDetail, gap);
    }

    /**
     * @description calculates the sum of the site of sales in a certain year depending on gap
     * @parameter assortmentDetail
     * @parameter gap the difference between assortmentDetail year and current Year
     * @return NULL in case of SObjectException (fields aren't queried)
	*/
    private Decimal getOffsetCumul(Negoptim__Assortment_Detail__c assortmentDetail, Integer gap) {
        Decimal offsetCumul = 0;
        Map<Id, Negoptim__Orga_BU__c> clusterStratsMap = getStratClusters(assortmentDetail);
        Map<Integer, Negoptim__Orga_BU__c> clusterCpltsMap = getCpltClusters(assortmentDetail);
        try {
            Boolean next = false;
            if(clusterStratsMap != null && !clusterStratsMap.isEmpty() && clusterStratsMap.containsKey(assortmentDetail.Negoptim__Ass_BU_Cluster__c)) {
                for (Negoptim__Orga_BU__c cluster : clusterStratsMap.values()) {
                    if (cluster.Id == assortmentDetail.Negoptim__Ass_BU_Cluster__c || next) {
                        if (gap >= 1)
                            offsetCumul += cluster.Negoptim__SiteOfSales_Number_N1__c != null ? cluster.Negoptim__SiteOfSales_Number_N1__c : 0;
                        if (gap == 0)
                            offsetCumul += cluster.Negoptim__SiteOfSales_Number__c != null ? cluster.Negoptim__SiteOfSales_Number__c : 0;
                        if (gap == -1)
                            offsetCumul += cluster.Negoptim__SiteOfSales_Number_P1__c != null ? cluster.Negoptim__SiteOfSales_Number_P1__c : 0;
                        if (gap <= -2)
                            offsetCumul += cluster.Negoptim__SiteOfSales_Number_P2__c != null ? cluster.Negoptim__SiteOfSales_Number_P2__c : 0;
                        next = true;
                    }
                }
            } else if(clusterCpltsMap != null && !clusterCpltsMap.isEmpty()) {
                for (Integer i = 1; i <= clusterCpltsMap.size(); i++) {
                    if ((Boolean) assortmentDetail.get('Client_Clust_Cplt' + i + '__c') && clusterCpltsMap.containsKey(i - 1)) {
                        Negoptim__Orga_BU__c cluster = clusterCpltsMap.get(i - 1);
                        if (gap >= 1)
                            offsetCumul += cluster.Negoptim__SiteOfSales_Number_N1__c != null ? cluster.Negoptim__SiteOfSales_Number_N1__c : 0;
                        if (gap == 0)
                            offsetCumul += cluster.Negoptim__SiteOfSales_Number__c != null ? cluster.Negoptim__SiteOfSales_Number__c : 0;
                        if (gap == -1)
                            offsetCumul += cluster.Negoptim__SiteOfSales_Number_P1__c != null ? cluster.Negoptim__SiteOfSales_Number_P1__c : 0;
                        if (gap <= -2)
                            offsetCumul += cluster.Negoptim__SiteOfSales_Number_P2__c != null ? cluster.Negoptim__SiteOfSales_Number_P2__c : 0;
                    }
                }
            }
        } catch (System.SObjectException ex) {
            System.debug('Exception: >>>>>' + ex.getMessage() + ' - LINE: ' + ex.getLineNumber());
            System.debug(ex.getStackTraceString() + '<<<<<');
        }
        return offsetCumul;
    }

    /**
     * @description calculates the sum of the site of sales of the year of the assortment detail
	*/
    public Decimal getOffsetCumul(Negoptim__Assortment_Detail__c assortmentDetail) {
        Integer gap = assortmentDetail.Negoptim__Year__c != null ? (Integer) assortmentDetail.Negoptim__Year__c - Date.today().year() : 1;
        return getOffsetCumul(assortmentDetail, gap);
    }

    /**
     * @description calculates the sum of the site of sales of the year after the year of the assortment detail
	*/
    public Decimal getL4LOffsetCumul(Negoptim__Assortment_Detail__c assortmentDetail) {
        Integer gap = assortmentDetail.Negoptim__Year__c != null ? (Integer) assortmentDetail.Negoptim__Year__c - Date.today().year() + 1 : 1;
        return getOffsetCumul(assortmentDetail, gap);
    }

    private Decimal getNDClientBased(Negoptim__Assortment_Detail__c assortmentDetail, Integer gap) {
        Decimal NDClientBased = 0;
        Map<Id, Negoptim__Orga_BU__c> clusterStratsMap = getStratClusters(assortmentDetail);
        Map<Integer, Negoptim__Orga_BU__c> clusterCpltsMap = getCpltClusters(assortmentDetail);
        try {
            Decimal offsetCumul = getOffsetCumul(assortmentDetail, gap);
            if(clusterStratsMap != null && !clusterStratsMap.isEmpty() && clusterStratsMap.containsKey(assortmentDetail.Negoptim__Ass_BU_Cluster__c)) {
                Decimal sumSOSClusters = getSumSOSClusters(clusterStratsMap.values(), gap);
                NDClientBased = sumSOSClusters == 0 ? null : (offsetCumul / sumSOSClusters) * 100;
            } else if(clusterCpltsMap != null && !clusterCpltsMap.isEmpty() && this.isCplt(assortmentDetail)) {
                Decimal buTargetSOS = getBUTargetSOS(assortmentDetail, gap);
                NDClientBased = buTargetSOS == 0 ? null : (offsetCumul / buTargetSOS) * 100;
            }
        } catch (System.SObjectException ex) {
            System.debug('Exception: >>>>>' + ex.getMessage() + ' - LINE: ' + ex.getLineNumber());
            System.debug(ex.getStackTraceString() + '<<<<<');
        }
        return NDClientBased;
    }

    public Decimal getNDClientBased(Negoptim__Assortment_Detail__c assortmentDetail) {
        Integer gap = assortmentDetail.Negoptim__Year__c != null ? (Integer) assortmentDetail.Negoptim__Year__c - Date.today().year() : 1;
        return getNDClientBased(assortmentDetail, gap);
    }

    public Decimal getL4LNDClientBased(Negoptim__Assortment_Detail__c assortmentDetail) {
        Integer gap = assortmentDetail.Negoptim__Year__c != null ? (Integer) assortmentDetail.Negoptim__Year__c - Date.today().year() + 1 : 1;
        return getNDClientBased(assortmentDetail, gap);
    }

    private Decimal getNDMarketBased(Negoptim__Assortment_Detail__c assortmentDetail, Integer gap) {
        Decimal NDMarketBased = 0;
        Map<Id, Negoptim__Orga_BU__c> clusterStratsMap = getStratClusters(assortmentDetail);
        Map<Integer, Negoptim__Orga_BU__c> clusterCpltsMap = getCpltClusters(assortmentDetail);
        try {
            Decimal offsetCumul = getOffsetCumul(assortmentDetail, gap);
            return offsetCumul;
            /*if(clusterStratsMap != null && !clusterStratsMap.isEmpty() && clusterStratsMap.containsKey(assortmentDetail.Negoptim__Ass_BU_Cluster__c)) {
                Decimal SOSCircuit = getSOSCircuit(assortmentDetail, gap);
                NDMarketBased = SOSCircuit == 0 ? null : offsetCumul / SOSCircuit * 100;
            } else if(clusterCpltsMap != null && !clusterCpltsMap.isEmpty() && this.isCplt(assortmentDetail)) {
                Decimal buTargetSOS = getBUTargetSOS(assortmentDetail, gap);
                NDMarketBased = buTargetSOS == 0 ? null : (offsetCumul / buTargetSOS) * 100;
            }*/
        } catch (System.SObjectException ex) {
            System.debug('Exception: >>>>>' + ex.getMessage() + ' - LINE: ' + ex.getLineNumber());
            System.debug(ex.getStackTraceString() + '<<<<<');
        }
        return NDMarketBased;
    }

    public Decimal getNDMarketBased(Negoptim__Assortment_Detail__c assortmentDetail) {
        Integer gap = assortmentDetail.Negoptim__Year__c != null ? (Integer) assortmentDetail.Negoptim__Year__c - Date.today().year() : 1;
        return getNDMarketBased(assortmentDetail, gap);
    }

    public Decimal getL4LNDMarketBased(Negoptim__Assortment_Detail__c assortmentDetail) {
        Integer gap = assortmentDetail.Negoptim__Year__c != null ? (Integer) assortmentDetail.Negoptim__Year__c - Date.today().year() + 1 : 1;
        return getNDMarketBased(assortmentDetail, gap);
    }

    /**
     * @description
    */
    private Decimal getNewClientQuantityYE(Negoptim__Assortment_Detail__c assortmentDetail) {
        Decimal avgWeeklySalesExt = 0, newClientProductNumber, refClientProductNumber = 0, remainingWeeks = 0;
        if (assortmentDetail.Negoptim__Avg_Weekly_Sales_Ext_ClientBased__c != null && assortmentDetail.Negoptim__Avg_Weekly_Sales_Ext_ClientBased__c != 0) {
            avgWeeklySalesExt = assortmentDetail.Negoptim__Avg_Weekly_Sales_Ext_ClientBased__c;
        } else if (assortmentDetail.Negoptim__Avg_Weekly_Sales_Ext_MarketBased__c != null && assortmentDetail.Negoptim__Avg_Weekly_Sales_Ext_MarketBased__c != 0) {
            avgWeeklySalesExt = assortmentDetail.Negoptim__Avg_Weekly_Sales_Ext_MarketBased__c;
        } else {
            return 0;
        }
        if (assortmentDetail.Negoptim__Movement_Date__c != null && assortmentDetail.Negoptim__Movement_Date__c <= assortmentDetail.Negoptim__Assortment_BU__r.Negoptim__Ass_EDate__c) {
            // find the max date between mvt date and assort begin date
            Date d0 = assortmentDetail.Negoptim__Assortment_BU__r.Negoptim__Ass_BDate__c >= assortmentDetail.Negoptim__Movement_Date__c ?
                assortmentDetail.Negoptim__Assortment_BU__r.Negoptim__Ass_BDate__c : assortmentDetail.Negoptim__Movement_Date__c;
            // find the difference in weeks between the max date and the min date
            Integer remainingDays = d0.daysBetween(assortmentDetail.Negoptim__Assortment_BU__r.Negoptim__Ass_EDate__c);
            // add 1 to the remainingWeeks if the division isn't perfect
            remainingWeeks = remainingDays / 7 + (Math.mod(remainingDays, 7) == 0 ? 0 : 1);
            if (assortmentDetail.Negoptim__Client_Status__c == 'New' || assortmentDetail.Negoptim__Client_Status__c == 'Cplt') {
                remainingWeeks += 4;
                // remainingWeeks can't exceed 56 (52 + 4)
                remainingWeeks = Math.min(remainingWeeks, 56);
            } else {
                // remainingWeeks can't exceed 52
                remainingWeeks = Math.max(1, Math.min(remainingWeeks, 52));
            }
        } else {
            return 0;
        }
        newClientProductNumber = getOffsetCumul(assortmentDetail);
        if (assortmentDetail.Negoptim__Last_History__c == null) {
            refClientProductNumber = assortmentDetail.Negoptim__Ref_Client_ProductNumber__c != null ? assortmentDetail.Negoptim__Ref_Client_ProductNumber__c : 0;
        } else if(assortmentDetail.Negoptim__Last_History__r.Negoptim__New_Client_ProductNumber__c != null) {
            refClientProductNumber = assortmentDetail.Negoptim__Last_History__r.Negoptim__New_Client_ProductNumber__c;
        }
        return avgWeeklySalesExt * (newClientProductNumber - refClientProductNumber) * remainingWeeks;
    }

    /**
     * @description calulates and assigns Negoptim__New_Client_WD_MarketBased__c, Negoptim__New_Client_WD_ClientBased__c, Negoptim__New_Corp_WD_MarketBased__c,
     * Negoptim__New_Corp_WD_ClientBased__c, Negoptim__New_Client_ND_MarketBased__c, Negoptim__New_Client_ND_ClientBased__c, Negoptim__New_Corp_ND_MarketBased__c, Negoptim__New_Corp_ND_ClientBased__c,
     * and Negoptim__New_Client_ProductNumber__c to assortmentDetail record
     * @parameter assortmentDetail must query fields for calculation are Negoptim__Ass_BU_Cluster__c and Negoptim__Year__c
     * @parameter clusters a list of Negoptim__Orga_BU__c of record type Assortment_Cluster that must have queried fields Negoptim__Weighted_Distribution_Manual_N1__c,
     * Negoptim__Weighted_Distribution_Manual__c, Negoptim__Weighted_Distribution_Manual_P1__c, Negoptim__Weighted_Distribution_Manual_P2__c
    */
    public void assignKPI(List<Negoptim__Assortment_Detail__c> assortmentDetailIdList) {
        try {
            for (Negoptim__Assortment_Detail__c assortmentDetail : assortmentDetailIdList) {
                Decimal WDMarketBased = getWDMarketBased(assortmentDetail);
                Decimal WDClientBased = getWDClientBased(assortmentDetail);
                Decimal NDMarketBased = getNDMarketBased(assortmentDetail);
                Decimal NDClientBased = getNDClientBased(assortmentDetail);
                Decimal offsetCumul = getOffsetCumul(assortmentDetail);
                // L4L
                Decimal L4LWDMarketBased = getL4LWDMarketBased(assortmentDetail);
                Decimal L4LWDClientBased = getL4LWDClientBased(assortmentDetail);
                Decimal L4LNDMarketBased = getL4LNDMarketBased(assortmentDetail);
                Decimal L4LNDClientBased = getL4LNDClientBased(assortmentDetail);
                Decimal L4LOffsetCumul = getL4LOffsetCumul(assortmentDetail);

                // New Client Quantity YE
                Decimal newClientQuantityYE = getNewClientQuantityYE(assortmentDetail);

                // assignment
                assortmentDetail.Negoptim__New_Client_WD_MarketBased__c = WDMarketBased;
                assortmentDetail.Negoptim__New_Client_WD_ClientBased__c = WDClientBased;
                assortmentDetail.Negoptim__New_Corp_WD_MarketBased__c = WDMarketBased;
                assortmentDetail.Negoptim__New_Corp_WD_ClientBased__c = WDClientBased;
                assortmentDetail.Negoptim__New_Client_ND_MarketBased__c = NDMarketBased;
                assortmentDetail.Negoptim__New_Client_ND_ClientBased__c = NDClientBased;
                assortmentDetail.Negoptim__New_Corp_ND_MarketBased__c = NDMarketBased;
                assortmentDetail.Negoptim__New_Corp_ND_ClientBased__c = NDClientBased;
                assortmentDetail.Negoptim__New_Client_ProductNumber__c = offsetCumul;

                assortmentDetail.Negoptim__L4L_Client_WD_MarketBased__c = L4LWDMarketBased;
                assortmentDetail.Negoptim__L4L_Client_WD_ClientBased__c = L4LWDClientBased;
                assortmentDetail.Negoptim__L4L_Client_ND_MarketBased__c = L4LNDMarketBased;
                assortmentDetail.Negoptim__L4L_Client_ND_ClientBased__c = L4LNDClientBased;
                assortmentDetail.Negoptim__L4L_Client_ProductNumber__c = L4LOffsetCumul;

                assortmentDetail.Negoptim__New_Client_Quantity_YE__c = newClientQuantityYE;
            }
        } catch (System.SObjectException ex) {
            System.debug('Exception: >>>>>' + ex.getMessage() + ' - LINE: ' + ex.getLineNumber());
            System.debug(ex.getStackTraceString() + '<<<<<');
        }
    }

    global class ResultWrapper {
        global Map<Id, Map<Integer, Negoptim__Orga_BU__c>> categoryStratMap {get;set;}
        public Map<Id, Map<Integer, Negoptim__Orga_BU__c>> categoryStratRefMap {get;set;}

        global Map<Id, Map<Integer, Negoptim__Orga_BU__c>> categoryCpltMap {get;set;}
        public Map<Id, Map<Integer, Negoptim__Orga_BU__c>> categoryCpltRefMap {get;set;}

        public Map<Id, Map<Integer, Negoptim__Orga_BU__c>> closedCategoryStratMap {get;set;}
        public Map<Id, Map<Integer, Negoptim__Orga_BU__c>> closedCategoryCpltMap {get;set;}

        public Map<Id, Map<Integer, Negoptim__Orga_BU__c>> categoryProspectStratMap {get;set;}
        public Map<Id, Map<Integer, Negoptim__Orga_BU__c>> categoryProspectCpltMap {get;set;}

        public ResultWrapper() {
            this.categoryStratMap = new Map<Id, Map<Integer, Negoptim__Orga_BU__c>>();
            this.categoryStratRefMap = new Map<Id, Map<Integer, Negoptim__Orga_BU__c>>();

            this.categoryCpltMap = new Map<Id, Map<Integer, Negoptim__Orga_BU__c>>();
            this.categoryCpltRefMap = new Map<Id, Map<Integer, Negoptim__Orga_BU__c>>();

            this.closedCategoryStratMap = new Map<Id, Map<Integer, Negoptim__Orga_BU__c>>();
            this.closedCategoryCpltMap = new Map<Id, Map<Integer, Negoptim__Orga_BU__c>>();

            this.categoryProspectStratMap = new Map<Id, Map<Integer, Negoptim__Orga_BU__c>>();
            this.categoryProspectCpltMap = new Map<Id, Map<Integer, Negoptim__Orga_BU__c>>();
        }
    }
}