/**
* @author ULiT
* @description used to get selected bu in the flow dupliate assortment BU 
* @date 7/9/2023
* */
public with sharing class SelectedBU {
    
    @AuraEnabled public String selectedBUSource;
    @AuraEnabled public String selectedBUTarget;
    
	public SelectedBU() {}
    public SelectedBU(String buSource, String buTarget) {
        this.selectedBUSource = buSource;
        this.selectedBUTarget = buTarget;
    }
}