/*
Ce fichier est généré ne correspond pas au code source de cette
classe globale gérée.
Ce fichier en lecture seule affiche les constructeurs globaux,
les méthodes, les variables et les propriétés de la classe.
Pour activer le code à compiler, toutes les méthodes renvoient null.
*/
global class RetrieveMetadata {
    global static usf3.MetadataService.AsyncResult AsyncResult {
        get;
    }
    global static String MetadataFileData {
        get;
        set;
    }
    global static String MetadataFileName {
        get;
        set;
    }
    global static List<usf3.RetrieveMetadata.MetadataFile> MetadataFiles {
        get;
        set;
    }
    global static String MetaDataFolder {
        get;
        set;
    }
    global static String MetaDataItem {
        get;
        set;
    }
    global static List<System.SelectOption> MetaDataItems {
        get;
        set;
    }
    global static String MetaDataRetrieveZip {
        get;
    }
    global static String MetaDataType {
        get;
        set;
    }
    global static List<System.SelectOption> MetaDataTypes {
        get;
        set;
    }
    global RetrieveMetadata() {

    }
    @AuraEnabled
    global static String RetrieveMetadataItem(String metadataName) {
        return null;
    }
    @AuraEnabled
    global static String RetrieveMetadataItemV2(String metadataName, String metadataType) {
        return null;
    }
    @AuraEnabled
    global static String checkAsyncRequest(String jobId) {
        return null;
    }
    global static String escape(String unescapedString) {
        return null;
    }
    @AuraEnabled
    global static String getFileNames(String zipfile) {
        return null;
    }
    global static String getPackageXml(String flowName) {
        return null;
    }
    global static String unpackZipfile(String metadataZipfile) {
        return null;
    }
global class MetadataFile extends usf3.MetadataService.MetadataWithContent {
    global MetadataFile() {

    }
    global String getContent() {
        return null;
    }
    global String getFullname() {
        return null;
    }
}
global class ReturnValues {
    global ReturnValues() {

    }
}
}
