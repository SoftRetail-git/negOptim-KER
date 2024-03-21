/**
 * HierarchyElementTree
 * @author ULiT
 * */
global with sharing class HierarchyElementTree {

    public Set<Id> elementsId;
    public Set<String> elementsCode;
    public List<Negoptim__Orga_HE__c> allElementsList = new List<Negoptim__Orga_HE__c>();
    public List<Negoptim__Orga_HE__c> allParentsList;
    public List<Negoptim__Orga_HE__c> allElementsWithParentsList; // ordered from low level
    public Map<Id, Negoptim__Orga_HE__c> allElementsWithParentsMap;
    private Map<Id, Set<Negoptim__Orga_HE__c>> allTree;
    private Map<Id, Set<Negoptim__Orga_HE__c>> allTreeWithParent;
    private Set<String> parentsCodes;
    private Negoptim__Orga_HE__c rootElement;
    //
    public HierarchyElementTree(Set<Id> ids) {
        this.elementsId = ids;
        this.init();
    }
    public HierarchyElementTree(Set<String> codes) {
        this.elementsCode = codes;
        this.init();
    }

    private void getRoot() {
        // check security on Orga_HE__c fields
        String[] orgaHEFields = new String[] {
            SObjectType.Negoptim__Orga_HE__c.fields.Id.Name,
                SObjectType.Negoptim__Orga_HE__c.fields.Negoptim__Elt_Code__c.Name,
                SObjectType.Negoptim__Orga_HE__c.fields.Negoptim__Parent_Element__c.Name
                };
        if (Negoptim.NegoptimHelper.checkAccessibility(Negoptim__Orga_HE__c.SObjectType, orgaHEFields)) {
            this.rootElement = [SELECT Id, Negoptim__Elt_Code__c FROM Negoptim__Orga_HE__c WHERE Negoptim__Parent_Element__c = NULL];
        }
    }

    //
    private void init() {
        getRoot();
        List<Negoptim__Orga_HE__c> elements = this.queryData(this.elementsId, this.elementsCode, true);
        this.parentsCodes = new Set<String>();
        String[] eltCodes = new String[]{};
        for (Negoptim__Orga_HE__c item : elements) {
            // Load children only in case of init by elements Ids
            if (this.elementsId != null) {
                eltCodes.add(item.Negoptim__Elt_Code__c + '|');
            }
            // Prepare parents codes
            if (item.Negoptim__Path__c != null) {
                String[] codes = item.Negoptim__Path__c.split('\\|');
                for (Integer i = 0; i < codes.size() - 1; i++) {
                    parentsCodes.add(codes[i]);
                }
            }
        }
        // Load children
        if (!eltCodes.isEmpty()) {
            List<Negoptim__Orga_HE__c> elementsWithChildren = queryData(null, new Set<String>(eltCodes), true);
            this.allElementsList.addAll(elementsWithChildren);
        }
        this.allElementsList.addAll(elements);
        this.allElementsWithParentsList = new List<Negoptim__Orga_HE__c>(this.allElementsList);
        this.allElementsWithParentsMap = new Map<Id, Negoptim__Orga_HE__c>();
        for (Negoptim__Orga_HE__c item : this.allElementsList) {
            this.allElementsWithParentsMap.put(item.Id, item);
        }
        // Load parents
        if (!parentsCodes.isEmpty()) {
            this.allParentsList = queryData(null, parentsCodes, false);
            for (Negoptim__Orga_HE__c item : this.allParentsList) {
                if (!this.allElementsWithParentsMap.containsKey(item.Id)) {
                    this.allElementsWithParentsMap.put(item.Id, item);
                    this.allElementsWithParentsList.add(item);
                }
            }
        }
    }
    //
    private List<Negoptim__Orga_HE__c> queryData(Set<Id> ids, Set<String> codes, Boolean filterOnPaths) {
        // check security on Orga_HE__c fields
        String[] orgaHEFields = new String[] {
            SObjectType.Negoptim__Orga_HE__c.fields.Id.Name,
                SObjectType.Negoptim__Orga_HE__c.fields.Name.Name,
                SObjectType.Negoptim__Orga_HE__c.fields.Negoptim__Elt_Code__c.Name,
                SObjectType.Negoptim__Orga_HE__c.fields.Negoptim__Level__c.Name,
                SObjectType.Negoptim__Orga_HE__c.fields.Negoptim__Path__c.Name,
                SObjectType.Negoptim__Orga_HE__c.fields.Negoptim__Parent_Element__c.Name,
                SObjectType.Negoptim__Orga_HE__c.fields.Negoptim__Long_Name__c.Name,
                SObjectType.Negoptim__Orga_HE__c.fields.Negoptim__Status__c.Name
                };
        if (Negoptim.NegoptimHelper.checkAccessibility(Negoptim__Orga_HE__c.SObjectType, orgaHEFields)) {
            String query = 'SELECT Id, Name, Negoptim__Elt_Code__c, Negoptim__Level__c, Negoptim__Path__c, Negoptim__Parent_Element__c, Negoptim__Long_Name__c';
            query += ' FROM Negoptim__Orga_HE__c';
            query += ' WHERE Negoptim__Status__c = \'Active\'';
            if (ids != null && !ids.isEmpty()) {
                query += ' AND Id IN :ids';
            }
            if (codes != null && !codes.isEmpty()) {
                if (filterOnPaths) {
                    List<String> pathes = new List<String>();
                    for (String code : codes) {
                        if (code.equals(rootElement.Negoptim__Elt_Code__c + '|'))
                            pathes.add(String.format('%{0}%', new List<String>{String.escapeSingleQuotes(code)}));
                        else
                            pathes.add(String.format('%{0}%', new List<String>{'|' + String.escapeSingleQuotes(code)}));
                    }
                    query += ' AND Negoptim__Path__c LIKE :pathes';
                } else {
                    List<String> codes_escaped = new List<String>();
                    for (String str : codes) {
                        codes_escaped.add(String.escapeSingleQuotes(str));
                    }
                    query += ' AND Negoptim__Elt_Code__c IN (\'' + String.join(new List<String>(codes_escaped), '\',\'') +'\')';//:codes';
                }
            }
            query += ' ORDER BY Negoptim__Level__c DESC, Negoptim__Path__c ASC';
            query += ' LIMIT 1000';
            return Database.query(query);
        }
        return null;
    }
    //
    public Map<Id, Set<Negoptim__Orga_HE__c>> getAllTree() {
        if (this.allTree == null) {
            this.allTree = buildTreeMap(this.allElementsList);
        }
        return this.allTree;
    }
    //
    public Map<Id, Set<Negoptim__Orga_HE__c>> getAllTreeWithParent() {
        if (this.allTreeWithParent == null) {
            this.allTreeWithParent = buildTreeMap(this.allElementsWithParentsList);
        }
        return this.allTreeWithParent;
    }
    //
    private Map<Id, Set<Negoptim__Orga_HE__c>> buildTreeMap(List<Negoptim__Orga_HE__c> source) {
        Map<Id, Set<Negoptim__Orga_HE__c>> treeMap = new Map<Id, Set<Negoptim__Orga_HE__c>>();
        for (Negoptim__Orga_HE__c item : source) {
            if (!treeMap.containsKey(item.Id))
                treeMap.put(item.Id, new Set<Negoptim__Orga_HE__c>());
            if (!treeMap.containsKey(item.Negoptim__Parent_Element__c))
                treeMap.put(item.Negoptim__Parent_Element__c, new Set<Negoptim__Orga_HE__c>());
            treeMap.get(item.Negoptim__Parent_Element__c).add(item);
        }
        return treeMap;
    }
    //
    public Set<Negoptim__Orga_HE__c> getChildrenList(Id root) {
        Set<Negoptim__Orga_HE__c> children = new Set<Negoptim__Orga_HE__c>();
        if (this.getAllTreeWithParent().containsKey(root)) {
            Set<Negoptim__Orga_HE__c> entry = this.getAllTreeWithParent().get(root);
            for (Negoptim__Orga_HE__c item : entry) {
                children.add(item);
                children.addAll(getChildrenList(item.Id));
            }
        }
        return children;
    }
    //
    public Map<Id, Set<Id>> getParentChildrenListMap(Set<Id> elements) {
        Map<Id, Set<Id>> entry = new Map<Id, Set<Id>>();
        for (Id item : elements) {
            ////entry.put(item, getChildrenList(item));
        }
        return entry;
    }
    //
    public Map<Id, Set<Negoptim__Orga_HE__c>> getParentChildrenListMap() {
        Map<Id, Set<Negoptim__Orga_HE__c>> entry = new Map<Id, Set<Negoptim__Orga_HE__c>>();
        for (Negoptim__Orga_HE__c item : this.allElementsList) {
            entry.put(item.Id, getChildrenList(item.Id));
        }
        return entry;
    }
    //
    public Id getFirstParent(Set<Negoptim__Orga_HE__c> elements) {
        // TODO
        return '';
    }
    //
    public Set<Negoptim__Orga_HE__c> getParentsList(Id root) {
        Set<Negoptim__Orga_HE__c> parents = new Set<Negoptim__Orga_HE__c>();
        Negoptim__Orga_HE__c entry = this.allElementsWithParentsMap.get(root);
        if (/*entry.Parent_Element__c != null &&*/ this.allElementsWithParentsMap.containsKey(entry.Negoptim__Parent_Element__c)) {
            parents.add(this.allElementsWithParentsMap.get(entry.Negoptim__Parent_Element__c));
            ////if (this.allElementsWithParentsMap.get(entry.Parent_Element__c).Parent_Element__c != null)
            parents.addAll(getParentsList(entry.Negoptim__Parent_Element__c));
        }
        return parents;
    }

    /**
     * @description checks if the first element is an ancestor of the second element
     * @param Id possible ancestor Id
     * @param Id child element Id
     * @return Boolean
	*/
    public Boolean isAncestor(Id ancestorId, Id childId) {
        if (!allElementsWithParentsMap.containsKey(ancestorId) || !allElementsWithParentsMap.containsKey(childId))
            return false;
        if (ancestorId == rootElement.Id) return true;
        if (ancestorId == childId) return true;
        String ancestorPath = allElementsWithParentsMap.get(ancestorId).Negoptim__Path__c;
        String childPath = allElementsWithParentsMap.get(childId).Negoptim__Path__c;
        return childPath.startsWith(ancestorPath);
    }

}