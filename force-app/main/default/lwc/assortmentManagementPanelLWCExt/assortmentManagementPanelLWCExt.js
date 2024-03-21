import { LightningElement, track, wire } from "lwc";
import { getPicklistValues } from "lightning/uiObjectInfoApi";
import { loadStyle } from "lightning/platformResourceLoader";

import ASSORTMENT_TYPE from "@salesforce/schema/Negoptim__Assortment_BU__c.Negoptim__Assortment_type__c";
import STATUS from "@salesforce/schema/Negoptim__Assortment_BU__c.Negoptim__Status__c";
import TARGETBU from "@salesforce/schema/Negoptim__Assortment_BU__c.Negoptim__BU_Target__c";
import TARGETLOGO from "@salesforce/schema/Negoptim__Orga_BU__c.Negoptim__Logo__c";

import loadData from '@salesforce/apex/AssortmentManagementPanelCtrlExt.loadData';

import staticRsStyles from '@salesforce/resourceUrl/assPanelStyles';

import LBL_No_Item_To_Display from "@salesforce/label/Negoptim.LBL_No_Item_To_Display";
import LBL_Filter from "@salesforce/label/Negoptim.LBL_Filter";
import LBL_Search from "@salesforce/label/Negoptim.LBL_Search";
import LBL_Reset from "@salesforce/label/Negoptim.LBL_Reset";
import LBL_Save from "@salesforce/label/Negoptim.LBL_Save";
import LBL_Cancel from "@salesforce/label/Negoptim.LBL_Cancel";
export default class AssortmentManagementPanelLWCExt extends LightningElement {

    resultW = '';
    filterParameter = {
        typeAssParam: '',
        yearParam: 2024,
        clientParam: ''
    }
    typeAssPicklistOptions;
    @track assortmentJSW = [];
    @track displayedFields = [];
    @track loadingData = true;
    @track isFilterOpen = false;
    @track label = {
        LBL_No_Item_To_Display,
        LBL_Filter,
        LBL_Search,
        LBL_Reset,
        LBL_Save,
        LBL_Cancel,
    }
    get isEmptyData() {
        return this.assortmentJSW.length == 0;
    };

    @wire(getPicklistValues, { recordTypeId: "012000000000000AAA", fieldApiName: ASSORTMENT_TYPE })
    picklistResults({ error, data }) {
        if (data) {
            this.typeAssPicklistOptions = data.values;
            console.log('typeAssPicklistOptions: ' + this.typeAssPicklistOptions)
        } else if (error) {
            this.typeAssPicklistOptions = undefined;
        }
    }

    connectedCallback() {
        this.loadData();
        Promise.all([
            loadStyle(this, staticRsStyles)
        ]).then(() => {
            console.log('loading style success')
        }).catch(error => {
            console.log('error loading style')
        });
        
        const whiteIconStyle = document.createElement('style');
        whiteIconStyle.innerText = '.sort-icon { --slds-c-icon-color-foreground-default:#FFFFFF;--slds-c-icon-color-background:#FFFFFF; }';
        document.body.appendChild(whiteIconStyle);
    }
    //load data 
    loadData() {
        this.loadingData = true;
        this.assortmentJSW = [];
        loadData({ FilterParameterJSON: JSON.stringify(this.filterParameter) }).then((result) => {
            console.log(result);
            this.resultW = JSON.parse(result);
            this.displayedFields = this.resultW.displayedFields.map(field => {
                let tempield = { fieldLabel: field.fieldLabel,
                    fieldApiName: field.fieldApiName,
                    isSortable: false,
                    ascSortDirection: false
                }
                if(field.fieldApiName == 'Name' || field.fieldApiName == STATUS.fieldApiName){
                    tempield.isSortable = true;
                    tempield.ascSortDirection = true;
                }
                return tempield;
            })
            console.log('this.displayedFields: ' + JSON.stringify(this.displayedFields))
            this.buildData();
            this.loadingData = false;
        }).catch(error => {
            this.loadingData = false;
            console.log('error get Data >> ' + error.message);
            console.error(error);
        });
    }
    buildData() {
        this.assortmentJSW = []
        for (let assbu of this.resultW.assortmentBuStringify) {
            let assortmentBuW = {
                id: assbu.Id,
                matrixUrl: '/apex/AssortmentBUMatrixExt?id=' + assbu.Id + '&&showSubtotal=true',
                fields: [],
                record : assbu
            }
            if(assbu.RecordType?.DeveloperName == 'Budget') {
                assortmentBuW.matrixUrl = '/apex/Negoptim__AssortmentBudgetSimulation?id=' + assbu.Id ;
            } else if(assbu.RecordType?.DeveloperName == 'Target') {
                assortmentBuW.matrixUrl = '/apex/AssortmentBUMatrixExt?id=' + assbu.Id + '&&layout=AssortmentMatrixTargetKercadelac';
            }
            assortmentBuW.fields = this.buildFieldsW(assbu);
            this.assortmentJSW.push(assortmentBuW);
        }
        console.log('this.assortmentJSW: ' + JSON.stringify(this.assortmentJSW))
    }
    buildFieldsW(assortmentBu) {
        let fieldsWList = []
        for (let field of this.resultW.displayedFields) {
            let fieldW = {
                fieldLabel: field.fieldLabel,
                fieldValue: assortmentBu[field.fieldApiName],
                isAssBu: field.fieldApiName == 'Name' ? true : false,
                link: '/' + assortmentBu.Id,
                isDouble : false,
                isImg : false,
                isString : true,
                fieldStyle : ''
            }
            switch (field.fieldType) {
                case "REFERENCE":
                    fieldW.fieldValue = assortmentBu[field.fieldApiName.replace("__c", "__r")]?.Name;
                    break;
                case "DOUBLE":
                    fieldW.isDouble = true;
                    fieldW.isString = false;
                    // fieldW.fieldStyle += 'display: flex;justify-content: right;'
                    break;
            }
            if(field.fieldApiName == STATUS.fieldApiName && assortmentBu[field.fieldApiName].startsWith('Valid')){
                fieldW.fieldStyle = 'background-color: #75e7758c;'
            } else if(field.fieldApiName == STATUS.fieldApiName && assortmentBu[field.fieldApiName].startsWith('Pre')){
                fieldW.fieldStyle = 'background-color: #e9f772;'
            }
            if(field.fieldApiName == TARGETBU.fieldApiName){
                fieldW.isImg = true;
                fieldW.isString = false;
                fieldW.fieldValue = assortmentBu[field.fieldApiName.replace("__c", "__r")]?.[TARGETLOGO.fieldApiName];
            }
            fieldsWList.push(fieldW);
        }
        return fieldsWList;
    }
    changeSortDirection(event) {
        console.log('changeSortDirection')
        let sortedField = event.target.dataset.id;
        console.log('sortedField: ' + JSON.stringify(sortedField))
        let sortDirection = event.target.dataset.sortDirection == 'true';
        if (sortDirection) {
            this.assortmentJSW.sort((a, b) => (a.record[sortedField] > b.record[sortedField]) ? 1 : ((b.record[sortedField] > a.record[sortedField]) ? -1 : 0));
        } else {
            this.assortmentJSW.sort((a, b) => (a.record[sortedField] < b.record[sortedField]) ? 1 : ((b.record[sortedField] < a.record[sortedField]) ? -1 : 0));
        }
        console.log('this.assortmentJSW: ' + JSON.stringify(this.assortmentJSW))
        this.displayedFields.forEach(f => {
            if (f.fieldApiName == sortedField) {
                f.ascSortDirection = !sortDirection
            }
        });

    }
    shareExcelFile() {

    }

    toggleFilter() {
        this.isFilterOpen = !this.isFilterOpen;
    }
    fillFilter(event) {
        let value = event.target.value;
        let typeParam = event.target.dataset.typeParam;
        this.filterParameter[typeParam] = value;
        console.log('this.filterParameter: ' + JSON.stringify(this.filterParameter))
    }
    handleReset() {
        this.filterParameter = {
            typeAssParam: '',
            yearParam: 2024,
            clientParam: ''
        }
        this.loadData();
    }
    refreshData() {
        this.loadData();
    }
}