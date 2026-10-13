/**
 * Executive Summary for Simulation Contract
 * used in page and pdf
 * */
global class ExecutiveSummaryController {
    // public List<BudgetMaker_detail__c> poidsNS {get;set;}
    // public BudgetMaker_detail__c Total {get;set;}
    public String locale { get; set; }
    public String localeDecimalSeparator { get; set; }
    public Boolean isCPG {get; set;}
    // public ContractServices contractServiceNBInit {get; set;}
    public List<ContractServices.ContractIndexWrapper> contractNBIIndexList {get; set;}
    public List<ContractServices.ContractIndexWrapper> contractNBIndexList {get; set;}

    public List<String> errors {get; set;}
    public Boolean returnToNego {get; set;}
    public String backUrlParam {get; set;}
    public String contentType {get; set;} // content type used to render the pdf or html
    public String selectedMultiYearOption {get; set;}
    public Contract__c currentContract {get; set;} // TODO: override by topContract
    public Contract__c topContract {get; set;}
    public List<Contract_Discount__c> contractDiscounts {get; set;}
    public Contract__c safeContract {get; set;}
    public Contract__c refContract {get;set;}
    public Nego_Plan__c negoPlan {get; set;}
    public Contract__c negoBaseInitContract {get;set;}
    public List<Contract_Discount__c> refProgressiveConditions {get; set;}
    public List<Contract_Discount__c> newProgressiveConditions {get; set;}
    public List<Contract_Discount__c> safeProgressiveConditions {get; set;}
    public List<Contract_Discount__c> NegoBaseInitProgressiveConditions{get; set;}
    public Map<String, Id> contractRTIds {get; set;} // Map of contract record types ids, key: developer name, value: id
    public boolean displayPopup {get; set;}
    public String BaseIndexRef {get;set;}
    public String BaseIndexCur {get;set;}
    public String BaseIndexEvol {get;set;}
    public String refContractIndex1 {
        get {
            if (refContract.Id == null || refContract.Index1__c == null) return '0';
            return refContract.Index1__c != null ? (((negoBaseInitContract.Index1__c != null ? negoBaseInitContract.Index1__c :0) - refContract.Index1__c) / refContract.Index1__c * 100).setScale(2).format() : '0';
        }
        set;
    }
    public String refContractIndex2 {
        get {
            if (refContract.Id == null || refContract.Index2__c == null) return '0';
            return refContract.Index2__c != null ? (((negoBaseInitContract.Index2__c != null ? negoBaseInitContract.Index2__c :0) - refContract.Index2__c) / refContract.Index2__c * 100).setScale(2).format() : '0';
        }
        set;
    }
    public String refContractIndex3 {
        get {
            if (refContract.Id == null || refContract.Index3__c == null) return '0';
            return refContract.Index3__c != null ? (((negoBaseInitContract.Index3__c != null ? negoBaseInitContract.Index3__c :0) - refContract.Index3__c) / refContract.Index3__c * 100).setScale(2).format() : '0';
        }
        set;
    }
    public String refContractIndex4 {
        get {
            if (refContract.Id == null || refContract.Index4__c == null) return '0';
            return refContract.Index4__c != null ? (((negoBaseInitContract.Index4__c != null ? negoBaseInitContract.Index4__c :0) - refContract.Index4__c) / refContract.Index4__c * 100).setScale(2).format() : '0';
        }
        set;
    }
    public String refContractIndex5 {
        get {
            if (refContract.Id == null || refContract.Index5__c == null) return '0';
            return refContract.Index5__c != null ? (((negoBaseInitContract.Index5__c != null ? negoBaseInitContract.Index5__c :0) - refContract.Index5__c) / refContract.Index5__c * 100).setScale(2).format() : '0';
        }
        set;
    }
    public String refContractIndex6 {
        get {
            if (refContract.Id == null || refContract.Index6__c == null) return '0';
            return refContract.Index6__c != null ? (((negoBaseInitContract.Index6__c != null ? negoBaseInitContract.Index6__c :0) - refContract.Index6__c) / refContract.Index6__c * 100).setScale(2).format() : '0';
        }
        set;
    }
    public String refContractIndex7 {
        get {
            if (refContract.Id == null || refContract.Index7__c == null) return '0';
            return refContract.Index7__c != null ? (((negoBaseInitContract.Index7__c != null ? negoBaseInitContract.Index7__c :0) - refContract.Index7__c) / refContract.Index7__c * 100).setScale(2).format() : '0';
        }
        set;
    }
    public String refContractTotalTo {
        get {
            if (refContract.Id == null || refContract.Total_TO__c == null) return '0';
            return refContract.Total_TO__c!= null ? refContract.Total_TO__c.format().replaceAll('\u202F', ' ') : '0';
        }
        set;
    }

    public String negoBaseInitContractTotalTo {
        get {
            return negoBaseInitContract.Total_TO__c != null ? negoBaseInitContract.Total_TO__c.format().replaceAll('\u202F', ' ') : '0';
        }
        set;
    }
    public Decimal contractTotalToDiff {
        get {
            return (negoBaseInitContract.Total_TO__c != null ? negoBaseInitContract.Total_TO__c : 0) - ( refContract.Total_TO__c!= null ? refContract.Total_TO__c : 0);
        }
        set;
    }
    public String scontractTotalToDiff {
        get {
            Decimal contractTotalToDiff = (negoBaseInitContract.Total_TO__c != null ? negoBaseInitContract.Total_TO__c : 0) - (refContract.Total_TO__c != null ? refContract.Total_TO__c : 0);
            // Decimal contractTotalToDiffPer = contractTotalToDiff != 0 ? (contractTotalTO2NetDiff / contractTotalToDiff) * 100 : 0;

            Decimal contractTotalToDiffPer = (negoBaseInitContract.Total_TO__c != null && negoBaseInitContract.Total_TO__c != 0
                                              && refContract.Total_TO__c != null && refContract.Total_TO__c != 0 ?
                                              ((negoBaseInitContract.Total_TO__c / refContract.Total_TO__c) -1) * 100 : 0);
            return contractTotalToDiff != null ? contractTotalToDiff.format().replaceAll('\u202F', ' ') + ' (' + contractTotalToDiffPer.format().replaceAll('\u202F', ' ') +  '%)' : '0';
        }
        set;
    }
    //<!-- JIRA 428 & 4645 -->

    // public String refContractTotalTO4Net {
    //     get {
    //         return refContract.Total_TO_4Net_Nego_YE__c!= null ? refContract.Total_TO_4Net_Nego_YE__c.format().replaceAll('\u202F', ' ') : '0';
    //     }
    //     set;
    // }

    // public String negoBaseInitContractTotalTo4Net {get; set;}

    // public Decimal contractTotalTO4NetDiff {
    //     get {
    //         return (negoBaseInitContract.Total_TO_4Net_Nego_YE__c != null ? negoBaseInitContract.Total_TO_4Net_Nego_YE__c : 0) - ( refContract.Total_TO_4Net_Nego_YE__c!= null ? refContract.Total_TO_4Net_Nego_YE__c : 0);
    //     }
    //     set;
    // }
    // public String scontractTotalTO4NetDiff {
    //     get {
    //         Decimal contractTotalTO4NetDiff = (negoBaseInitContract.Total_TO_4Net_Nego_YE__c != null ? negoBaseInitContract.Total_TO_4Net_Nego_YE__c : 0) - ( refContract.Total_TO_4Net_Nego_YE__c!= null ? refContract.Total_TO_4Net_Nego_YE__c : 0);
    //         Decimal contractTotalTO4NetDiffPer = String.isNotBlank(refContractTotalTO4Net) &&  refContractTotalTO4Net != '0' ? (contractTotalTO4NetDiff / Decimal.valueOf(refContractTotalTO4Net.replace(' ', ''))) * 100 : 0;
    //         return contractTotalTO4NetDiff != null ? contractTotalTO4NetDiff.format().replaceAll('\u202F', ' ') + ' (' + contractTotalTO4NetDiffPer.format().replaceAll('\u202F', ' ') +  '%)' : '0';
    //     }
    //     set;
    // }
    // public String refContractTotalTO3Net {
    //     get {
    //         return refContract.Total_TO_3Net_Nego_YE__c!= null ? refContract.Total_TO_3Net_Nego_YE__c.format().replaceAll('\u202F', ' ') : '0';
    //     }
    //     set;
    // }

    // public String negoBaseInitContractTotalTo3Net {get; set;}
    /*public String negoBaseInitContractTotalTo3Net {
        get {
            return negoBaseInitContract.Total_TO_3Net_Nego_YE__c!= null ? negoBaseInitContract.Total_TO_3Net_Nego_YE__c.format().replaceAll('\u202F', ' ') : '0';
        }
        set;
    }*/
    // public Decimal contractTotalTO3NetDiff {
    //     get {
    //         return (negoBaseInitContract.Total_TO_3Net_Nego_YE__c != null ? negoBaseInitContract.Total_TO_3Net_Nego_YE__c : 0) - ( refContract.Total_TO_3Net_Nego_YE__c!= null ? refContract.Total_TO_3Net_Nego_YE__c : 0);
    //     }
    //     set;
    // }
    // public String scontractTotalTO3NetDiff {
    //     get {
    //         Decimal contractTotalTO3NetDiff = (negoBaseInitContract.Total_TO_3Net_Nego_YE__c != null ? negoBaseInitContract.Total_TO_3Net_Nego_YE__c : 0) - ( refContract.Total_TO_3Net_Nego_YE__c!= null ? refContract.Total_TO_3Net_Nego_YE__c : 0);
    //         Decimal contractTotalTO3NetDiffPer = String.isNotBlank(refContractTotalTO3Net) &&  refContractTotalTO3Net != '0' ? (contractTotalTO3NetDiff / Decimal.valueOf(refContractTotalTO3Net.replace(' ', ''))) * 100 : 0;
    //         return contractTotalTO3NetDiff != null ? contractTotalTO3NetDiff.format().replaceAll('\u202F', ' ') + ' (' + contractTotalTO3NetDiffPer.format().replaceAll('\u202F', ' ') +  '%)' : '0';
    //     }
    //     set;
    // }
    // public String refContractTotalTO2Net {
    //     get {
    //         return refContract.Total_TO_2Net_Nego_YE__c!= null ? refContract.Total_TO_2Net_Nego_YE__c.format().replaceAll('\u202F', ' ') : '0';
    //     }
    //     set;
    // }

    // public String negoBaseInitContractTotalTo2Net {get; set;}
    /*public String negoBaseInitContractTotalTo2Net {
        get {
            return negoBaseInitContract.Total_TO_2Net_Nego_YE__c!= null ? negoBaseInitContract.Total_TO_2Net_Nego_YE__c.format().replaceAll('\u202F', ' ') : '0';
        }
        set;
    }*/
    public Decimal contractTotalTO2NetDiff {
        get {
            return null;
            // return (negoBaseInitContract.Total_TO_2Net_Nego_YE__c != null ? negoBaseInitContract.Total_TO_2Net_Nego_YE__c : 0) - ( refContract.Total_TO_2Net_Nego_YE__c!= null ? refContract.Total_TO_2Net_Nego_YE__c : 0);
        }
        set;
    }
    // public String scontractTotalTO2NetDiff {
    //     get {
    //         Decimal contractTotalTO2NetDiff = (negoBaseInitContract.Total_TO_2Net_Nego_YE__c != null ? negoBaseInitContract.Total_TO_2Net_Nego_YE__c : 0) - ( refContract.Total_TO_2Net_Nego_YE__c!= null ? refContract.Total_TO_2Net_Nego_YE__c : 0);
    //         Decimal contractTotalTO2NetDiffPer = String.isNotBlank(refContractTotalTO2Net) &&  refContractTotalTO2Net != '0' ? (contractTotalTO2NetDiff / Decimal.valueOf(refContractTotalTO2Net.replace(' ', ''))) * 100 : 0;
    //         return contractTotalTO2NetDiff != null ? contractTotalTO2NetDiff.format().replaceAll('\u202F', ' ') + ' (' + contractTotalTO2NetDiffPer.format().replaceAll('\u202F', ' ') +  '%)' : '0';
    //     }
    //     set;
    // }
    public decimal Poids {get;set;}
    public String TargetSignatureDate {get;set;}
    public String TargetContractDate {get;set;}
    public String sPoids {
        get {
            return this.Poids != null ? this.Poids.format() : '0';
        }
        set;
    }
    //-----------------------------
     // ON negoBaseInit
    // Formula 1: Difference between index3_perc of nego base and on negoBaseInit contract (in %)
    public Decimal negoBaseInitFormula1 { get {
        Decimal negobase_index3 = this.refContract?.Id != null ? (this.refContract.Index3__c != null ? this.refContract.Index3__c : 0) : 0;
        Decimal negoBaseInit_index3 = this.negoBaseInitContract != null ? (this.negoBaseInitContract.Index3__c != null ? this.negoBaseInitContract.Index3__c : 0) : 0;
        return negobase_index3 != 0 ? ((negoBaseInit_index3 - negobase_index3) / negobase_index3) * 100 : 0;
    } set; }

     public String sNegoBaseInitFormula1 { get {
        return NegoptimHelper.formatPercentageValue(this.negoBaseInitFormula1, false) + '%';
    } set;}

    public Decimal negoBaseInit_valeurReelle_index4 {get; set;}
    public Decimal negoBaseInit_valeurReelle_index5 {get; set;}
    public Decimal ref_CA_index3 {get; set;}


    public String sNEGO_NegoIntro_5Net_Prog_val_Last { get {
        Decimal negoIntro5netProgLastVal = this.negoPlan != null && this.negoPlan.NEGO_NegoIntro_5Net_Prog_val_Last__c != null ? this.negoPlan.NEGO_NegoIntro_5Net_Prog_val_Last__c / 100 : 0;
        return negoIntro5netProgLastVal.setScale(0).format().replaceAll('\u202F', ' ');
    } set;}

    public String sNEGO_NegoIntro_4Net_Prog_val_Last { get {
        Decimal negoIntro4netProgLastVal = this.negoPlan != null && this.negoPlan.NEGO_NegoIntro_4Net_Prog_val_Last__c != null ? this.negoPlan.NEGO_NegoIntro_4Net_Prog_val_Last__c / 100 : 0;
        return negoIntro4netProgLastVal.setScale(0).format().replaceAll('\u202F', ' ');
    } set;}
    public String sPLAN_Target_Index4_Nego_val { get {
        Decimal planTargetIndex4NegoVal = this.negoPlan != null && this.negoPlan.PLAN_Target_Index4_Nego_val__c != null ? this.negoPlan.PLAN_Target_Index4_Nego_val__c : 0;
        return planTargetIndex4NegoVal.setScale(0).format().replaceAll('\u202F', ' ');
    } set;}
    public String sPLAN_Target_Index5_Nego_val { get {
        Decimal planTargetIndex5NegoVal = this.negoPlan != null && this.negoPlan.PLAN_Target_Index5_Nego_val__c != null ? this.negoPlan.PLAN_Target_Index5_Nego_val__c : 0;
        return planTargetIndex5NegoVal.setScale(0).format().replaceAll('\u202F', ' ');
    } set;}
    public Decimal negoBase_TotalTO { get {
        return this.refContract?.Id != null ? (this.refContract.Total_TO__c != null ? this.refContract.Total_TO__c : 0) : 0;
    } set; }
    public String sNegoBaseInit_valeurReelle_index4 { get {
        return this.negoBaseInit_valeurReelle_index4 != null ? this.negoBaseInit_valeurReelle_index4.format().replaceAll('\u202F', ' ') : '';
    } set;}
    public Decimal gap_4net {get {
        Decimal planTarget4prog = (this.negoPlan != null && this.negoPlan.PLAN_Target_Index4_Nego_val__c != null ? this.negoPlan.PLAN_Target_Index4_Nego_val__c : 0);
        return (this.negoBaseInit_valeurReelle_index4 != null ? this.negoBaseInit_valeurReelle_index4 : 0) - planTarget4prog;
    } set;}
     public Decimal gap_5net {get {
            Decimal planTarget5prog = (this.negoPlan != null && this.negoPlan.PLAN_Target_Index5_Nego_val__c != null ? this.negoPlan.PLAN_Target_Index5_Nego_val__c : 0);
            return (this.negoBaseInitFormula3 != null ? this.negoBaseInitFormula3 : 0) - planTarget5prog;
        } set;}
     public String sGap_4net {get {
            return gap_4net.setScale(0).format().replaceAll('\u202F', ' ');
        } set;}
    public Decimal gap_4net_perc {get {
        Decimal planTarget4prog = (this.negoPlan != null && this.negoPlan.PLAN_Target_Index4_Nego_val__c != null ? this.negoPlan.PLAN_Target_Index4_Nego_val__c : 0);
        return this.negoBase_TotalTO != 0 ? (this.gap_4net / this.negoBase_TotalTO) * 100 : 0;
    } set;}
    public String sGap_4net_perc { get {
        return NegoptimHelper.formatPercentageValue(this.gap_4net_perc, false) + '%';
    } set; }
    public Decimal gap_5net_perc {get {
        Decimal planTarget5prog = (this.negoPlan != null && this.negoPlan.PLAN_Target_Index5_Nego_val__c != null ? this.negoPlan.PLAN_Target_Index5_Nego_val__c : 0);
        return this.negoBase_TotalTO != 0 ? (gap_5net / this.negoBase_TotalTO) * 100 : 0;
    } set;}
    public String sGap_5net_perc { get {
        return NegoptimHelper.formatPercentageValue(this.gap_5net_perc, false) + '%';
    } set; }

    public String sGap_5net {get {
        return gap_5net.setScale(0).format().replaceAll('\u202F', ' ');
    } set;}
     public Decimal negoBaseInitFormula3 { get {
            return  this.negoBaseInit_valeurReelle_index5;
        } set; }
    public String sNegoBaseInitFormula3 { get {
        return this.negoBaseInitFormula3 != null ? this.negoBaseInitFormula3.format().replaceAll('\u202F', ' ') : '';
    } set;}

    // GAP between Target and on negoBaseInit formula1
    public Decimal gap_2_3net_perc {get {
        Decimal planTarget2_3prog = (this.negoPlan != null && this.negoPlan.PLAN_Target_2_3Net_Prog__c != null ? this.negoPlan.PLAN_Target_2_3Net_Prog__c : 0);
        return (this.negoBaseInitFormula1 - planTarget2_3prog);
    } set;}
    public Decimal gap_2_3_4net_perc {get {
        Decimal planTarget2_3_4prog = (this.negoPlan != null && this.negoPlan.PLAN_Target_2_3_4Net_Prog__c != null ? this.negoPlan.PLAN_Target_2_3_4Net_Prog__c : 0);
        // return (planTarget2_3_4prog - this.negoBaseInitFormula1);
        return (this.negoBaseInitFormula1 - planTarget2_3_4prog);
    } set;}
    public String sGap_2_3_4net_perc { get {
        return NegoptimHelper.formatPercentageValue(this.gap_2_3_4net_perc, false) + '%';
    } set; }
    public Decimal gap_2_3net {get {
         return this.gap_2_3net_perc * (this.ref_CA_index3 != null ? this.ref_CA_index3 : 0)  / 100;
        } set;}
    public String sGap_2_3net {get {
            return gap_2_3net.setScale(0).format().replaceAll('\u202F', ' ');
        } set;}
    public String sGap_2_3net_perc { get {
        return NegoptimHelper.formatPercentageValue(this.gap_2_3net_perc, false) + '%';
    } set; }

    public void closePopup() {
        displayPopup = false;
    }
    public void showPopup() {
        displayPopup = true;
    }
    public String safebalanceRTName {
        get {
            return NegoptimHelper.getObjectRecordTypeName(Contract__c.SobjectType, safeRecordTypeId);
        }
    }
    public final String negoBaseRecordTypeId {get { return contractRTIds.get('Nego_Base'); }}
    public final String negoBaseInitRecordTypeId {get { return contractRTIds.get('Nego_Base_Init'); }}
    public final String simulationRecordTypeId {get { return contractRTIds.get('Simulation'); }}
    public final String safeRecordTypeId {get { return contractRTIds.get('Safe_Balance'); }}
    public final String signedRecordTypeId {get { return contractRTIds.get('Signed'); }}
    public final String targetRecordTypeId {get { return contractRTIds.get('Target'); }}
    public static Map<String, String> indexesTranslationMap {get {
        Map<String, String> translationMap = PicklistHelper.getPicklistTranslationMap(Pol_Com_Condition__c.Index__c, true);
        return translationMap;
    } set;}
    public static Map<String, String> typesTranslationMap {get {
        Map<String, String> translationMap = PicklistHelper.getPicklistTranslationMap(Contract_Discount__c.Nego_Discount_Type__c, true);
        return translationMap;
    } set;}
    public ProcessInstance contractProcessInstance {get; set;}

    public Boolean showSendApprovalButton {
        get {
            return (!isCPG && topContract.RecordTypeId == simulationRecordTypeId
                    ? topContract.Status__c == 'In preparation'
                    : (topContract.Status__c == 'Updated wAddendum' || topContract.Status__c == 'Updated woAddendum'))
                   && (contractProcessInstance == null || contractProcessInstance.Status != 'Pending');
        }
        set;
    }
    public String formattedBeginDate {
        get {
            if(UserInfo.getLocale() == 'en_US'){
                return topContract.Contract_BDate__c.month() + '/' + topContract.Contract_BDate__c.day() + '/' + topContract.Contract_BDate__c.year();
            }
            else{
                return topContract.Contract_BDate__c.day() + '/' + topContract.Contract_BDate__c.month() + '/' + topContract.Contract_BDate__c.year();
            }
        }
        set;
    }

    public String formattedEndDate {
        get {
            if(UserInfo.getLocale() == 'en_US'){
                return topContract.Contract_EDate__c.month() + '/' + topContract.Contract_EDate__c.day() + '/' + topContract.Contract_EDate__c.year();
            }
            else{
                return topContract.Contract_EDate__c.day() + '/' + topContract.Contract_EDate__c.month() + '/' + topContract.Contract_EDate__c.year();
            }
        }
        set;
    }

    private Id approverId;
    public String backURL {get; set;}
    public String negotiateURL {
        get {
            String pageRef;
            pageRef ='/lightning/n/Negotiate?c__negoyear='+ String.valueOf(topContract.Reference_Year__c) +'&c__negoId=' + topContract.Supplier_Nego_Scope__c + '&c__supplier=' + topContract.Supplier__c + '&c__contractId=' +  topContract.Id;
            return pageRef;
            // return '#';
        }
        set;
    }
    public String negotiateFollowUpURL {
        get {
            String pageRef;
            pageRef ='/lightning/n/Negotiate_Followup?c__negoyear='+ String.valueOf(topContract.Reference_Year__c) +'&c__negoId=' + topContract.Supplier_Nego_Scope__c + '&c__supplier=' + topContract.Supplier__c + '&c__contractId=' +  topContract.Id;
            return pageRef;
            // return '#';
        }
        set;
    }

    public String back {
        get {
            if (backUrlParam != null) {
                return backUrlParam;
            }
            return '/' + this.topContract.Id;
        }
        set;
    }

    // Constructor
    public ExecutiveSummaryController() {
        try {
            localeDecimalSeparator = NegoptimHelper.getDecimalSeparator();
            locale = UserInfo.getLocale();
            NegoptimSettings negoSettings = loadGlobalSettings();
            this.isCPG = negoSettings.sBusinessType == 'CPG';
            contractRTIds = NegoptimHelper.getObjectRecordTypeMapIds(Contract__c.SObjectType);
            errors = new List<String>();
            String selectedContractId = ApexPages.currentPage().getParameters().get('id');
            if (selectedContractId == null || !NegoptimHelper.validateId(selectedContractId)) {
                errors.add(System.Label.MSG_Invalid_Contract_Id);
            }
            if (errors.size() == 0) {
                // render page as pdf or html
                contentType = ApexPages.currentPage().getParameters().get('contentType');
                backUrlParam = ApexPages.currentPage().getParameters().get('backUrl');
                returnToNego = ApexPages.currentPage().getParameters().get('returnToNego') != null ? Boolean.valueOf(ApexPages.currentPage().getParameters().get('returnToNego')) : true;
                if (contentType == null) {
                    contentType = 'pdf';
                }
                // check access Contract__c fields
                String[] contractFields = new String[] {
                    SObjectType.Contract__c.fields.Id.Name,
                    SObjectType.Contract__c.fields.Name.Name,
                    SObjectType.Contract__c.fields.Reference_Year__c.Name,
                    SObjectType.Contract__c.fields.Contract_EDate__c.Name,
                    SObjectType.Contract__c.fields.Contract_BDate__c.Name,
                    SObjectType.Contract__c.fields.BusinessUnitContract__c.Name,
                    SObjectType.Contract__c.fields.Status__c.Name,
                    SObjectType.Contract__c.fields.Supplier_Nego_Scope__c.Name,
                    SObjectType.Contract__c.fields.Supplier__c.Name,
                    SObjectType.Contract__c.fields.Parent_Contract__c.Name,
                    SObjectType.Contract__c.fields.createdDate.Name,
                    SObjectType.Contract__c.fields.CreatedById.Name,
                    SObjectType.Contract__c.fields.Rise_Rate_YE__c.Name,
                    SObjectType.Contract__c.fields.Depreciation_Rate_YE__c.Name,
                    SObjectType.Contract__c.fields.Is_OnTop_Simulation__c.Name,
                    SObjectType.Contract__c.fields.RecordTypeId.Name
                };

                 // check access User fields
                String[] userFields = new String[] {
                    SObjectType.User.fields.Id.Name,
                    SObjectType.User.fields.ManagerId.Name,
                    SObjectType.User.fields.Name.Name
                };
                String[] negoScopeFields = new String[] {
                    SObjectType.NegoScope__c.fields.Id.Name,
                    SObjectType.NegoScope__c.fields.Name.Name,
                    SObjectType.NegoScope__c.fields.NS_Code__c.Name,
                    SObjectType.NegoScope__c.fields.ManagePromoFlatPriceRate__c.Name

                };
                String[] orgaBUFields = new String[] {
                    SObjectType.BusinessUnit__c.fields.Id.Name,
                    SObjectType.BusinessUnit__c.fields.Name.Name
                };
                String[] supplierFields = new String[] {
                    SObjectType.Supplier__c.fields.Id.Name,
                    SObjectType.Supplier__c.fields.Name.Name
                };
                List<Contract__c> contracts = new List<Contract__c>();
                if (NegoptimHelper.checkAccessibility(Contract__c.SObjectType, contractFields)
                    && NegoptimHelper.checkAccessibility(User.SObjectType, userFields)
                    && NegoptimHelper.checkAccessibility(NegoScope__c.SObjectType, negoScopeFields)
                    && NegoptimHelper.checkAccessibility(BusinessUnit__c.SObjectType, orgaBUFields)
                    && NegoptimHelper.checkAccessibility(Supplier__c.SObjectType, supplierFields))
                {
                    this.approverId = [Select Id, ManagerId FROM User WHERE Id = :UserInfo.getUserId()]?.ManagerId;
                    contracts = [SELECT Id, Name, Reference_Year__c, Contract_BDate__c, Contract_EDate__c, BusinessUnitContract__c, BusinessUnitContract__r.Name, Status__c, CreatedBy.Name,
                                 Supplier_Nego_Scope__c, Supplier_Nego_Scope__r.Name, Supplier__c, Supplier__r.Name, Parent_Contract__c, createdDate, RecordTypeId, TO2__c,
                                 Rise_Rate__c, Depreciation_Rate__c, Rise_Rate_YE__c, Depreciation_Rate_YE__c, Is_OnTop_Simulation__c, Total_Qty__c,  Index1__c, Index2__c, Index3__c, Index4__c, Index5__c, Index6__c, Index7__c,
                                 Index1_v2__c, Index1_v2_perc__c, Index2_v2__c, Index2_v2_perc__c, Index3_v2__c, Index3_v2_perc__c, Index4_v2__c, Index4_v2_perc__c, Index5_v2__c, Index5_v2_perc__c, Index6_v2__c, Index6_v2_perc__c, Index7_v2__c, Index7_v2_perc__c,
                                 Index1_perc__c, Index2_perc__c, Index3_perc__c, Index4_perc__c, Index5_perc__c, Index6_perc__c, Index7_perc__c,
                                 Supplier_Nego_Scope__r.NS_Code__c, Supplier_Nego_Scope__r.OwnerId, Supplier_Nego_Scope__r.Owner.Name,
                                //  Supplier__r.Size__c,
                                //  Supplier__r.Retail_Federation__c,
                                 (SELECT Id, unit_amount__c, Unit_Amount_Type__c, Base_Quantity_Nego__c, Is_Conditional__c, index_v2__c, slab_calc_method__c FROM Contract_Discounts__r WHERE Parent_Discount__c = NULL AND Status__c <> 'Deleted')
                                 FROM Contract__c
                                 WHERE Id = :selectedContractId
                                 AND (RecordTypeId = :simulationRecordTypeId OR RecordTypeId = :signedRecordTypeId)];
                }
                if(contracts.size() > 0) {
                    topContract = contracts.get(0);
                    executiveSummary();
                    loadNegoPlan();
                    // Check if an approval already sent
                    contractProcessInstance = getContractProcessInstance();
                    if(contractProcessInstance != null && contractProcessInstance.Status == 'Pending') {
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, System.Label.MSG_APPROVAL_ALREADY_SENT));
                    }
                    contractDiscounts = [SELECT Id, Condition_Type__r.name, Condition_Type__r.Long_Name__c,
                                        Disc_BDate__c, Disc_EDate__c, Value_per__c, Value_amt__c,
                                        unit_amount__c, Unit_Amount_Type__c, Base_Quantity_Nego__c, Rank__c
                                        FROM Contract_Discount__c
                                        WHERE RecordType.DeveloperName = 'To_Be_Signed'
                                        AND Contract__c = :topContract.Id
                                        AND Status__c <> 'Deleted'];
                } else {
                    errors.add(System.Label.MSG_SIMULATION_CONTRACT_NOT_EXISTS);
                }
            }
            // Display error messages if any
            for(String error : errors) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, error));
            }
        } catch(Exception ex) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, ex.getMessage() + ' - ' + ex.getLineNumber()));
            System.debug('ERRORS  >>>> ' + ex.getLineNumber() + ' <<<< line'+ ex.getMessage() + ' - ' + ex.getStackTraceString());
        }
    }
    // Dispaly multi year radios if is the case submit Approval
    public List<SelectOption> getListMultiYear() {
        Integer max = currentContract.Secure_Multiyear__c.contains('2 years') ? 2 : currentContract.Secure_Multiyear__c.contains('3 years') ? 3 : 0;
        // Integer max = currentContract.Secure_Multiyear__c.contains('2') ? 2 : currentContract.Secure_Multiyear__c.contains('3') ? 3 :currentContract.Secure_Multiyear__c.contains('4') ? 4 :currentContract.Secure_Multiyear__c.contains('5') ? 5 : 0;
        List<SelectOption> options = new List<SelectOption>();
        for(Integer i = 1; i <= max; i++) {
            options.add(new SelectOption(i + ' years', 'Y+' + i));
        }
        if (options.size() > 1) {
            selectedMultiYearOption = options.get(0).getValue();
        }
        return options;
    }
    // Get Contract Approval Process Instance if exist
    public ProcessInstance getContractProcessInstance() {
        // check access ProcessInstance fields
        String[] processInstanceFields = new String[] {
            SObjectType.ProcessInstance.fields.TargetObjectId.Name,
            SObjectType.ProcessInstance.fields.SubmittedById.Name,
            SObjectType.ProcessInstance.fields.Status.Name,
            SObjectType.ProcessInstance.fields.ProcessDefinitionId.Name,
            SObjectType.ProcessInstance.fields.CreatedDate.Name,
            SObjectType.ProcessInstance.fields.CompletedDate.Name
        };
        List<ProcessInstance> processInstanceList = new List<ProcessInstance>();
        if (NegoptimHelper.checkAccessibility(ProcessInstance.SObjectType, processInstanceFields)) {
            processInstanceList = [SELECT TargetObjectId, SubmittedById, Status, ProcessDefinitionId, CreatedDate, CompletedDate
                                   FROM ProcessInstance
                                   WHERE TargetObjectId = :topContract.Id
                                   ORDER BY CreatedDate DESC];
        }
        if(processInstanceList != null && processInstanceList.size() > 0 ) {
            return processInstanceList.get(0);
        }
        else {
            return null;
        }
    }
    // Load the brief/notes corresponding to the selected year and negoscope
    public void loadNegoPlan() {
         // check access Nego_Plan__c fields
        String[] negoplanFields = new String[] {
            SObjectType.Nego_Plan__c.fields.Id.Name,
            SObjectType.Nego_Plan__c.fields.NEGO_MOM_RDV1__c.Name,
            SObjectType.Nego_Plan__c.fields.NEGO_MOM_RDV2__c.Name,
            SObjectType.Nego_Plan__c.fields.NEGO_MOM_RDV3__c.Name,
            SObjectType.Nego_Plan__c.fields.NEGO_Keynote_Marketing_Plan__c.Name,
            SObjectType.Nego_Plan__c.fields.Nego_Scope__c.Name,
            SObjectType.Nego_Plan__c.fields.Nego_Year__c.Name,
            SObjectType.Nego_Plan__c.fields.NEGO_Rise_Rate_Validated_YE__c.Name,
            SObjectType.Nego_Plan__c.fields.NEGO_Depreciation_Rate_Validated_YE__c.Name,
            SObjectType.Nego_Plan__c.fields.NEGO_Rise_Rate_Validated_Nb__c.Name,
            SObjectType.Nego_Plan__c.fields.NEGO_Depreciation_Rate_Validated_Nb__c.Name,
            SObjectType.Nego_Plan__c.fields.NEGO_Rise_Rate1_Validated__c.Name,
            SObjectType.Nego_Plan__c.fields.NEGO_Rise_Rate2_Validated__c.Name,
            SObjectType.Nego_Plan__c.fields.NEGO_Rise_Rate3_Validated__c.Name,
            SObjectType.Nego_Plan__c.fields.NEGO_Rise_Rate4_Validated__c.Name,
            SObjectType.Nego_Plan__c.fields.NEGO_Rise_Rate5_Validated__c.Name,
            SObjectType.Nego_Plan__c.fields.NEGO_Rise_Rate6_Validated__c.Name,
            SObjectType.Nego_Plan__c.fields.NEGO_Rise_Rate7_Validated__c.Name,
            SObjectType.Nego_Plan__c.fields.NEGO_Rise_Rate8_Validated__c.Name,
            SObjectType.Nego_Plan__c.fields.NEGO_Rise_Rate9_Validated__c.Name,
            SObjectType.Nego_Plan__c.fields.NEGO_Rise_Rate10_Validated__c.Name,
            SObjectType.Nego_Plan__c.fields.PLAN_Target_2_3_4Net_Prog__c.Name,
            SObjectType.Nego_Plan__c.fields.NEGO_Depreciation_Rate1_Validated__c.Name,
            SObjectType.Nego_Plan__c.fields.NEGO_Depreciation_Rate2_Validated__c.Name,
            SObjectType.Nego_Plan__c.fields.NEGO_Depreciation_Rate3_Validated__c.Name
        };
        List<Nego_Plan__c> negoplanList = new List<Nego_Plan__c>();
        if (NegoptimHelper.checkAccessibility(Nego_Plan__c.SObjectType, negoplanFields)) {
            negoplanList = [SELECT Id, NEGO_MOM_RDV1__c, NEGO_MOM_RDV2__c, NEGO_MOM_RDV3__c, NEGO_Keynote_Marketing_Plan__c, NEGO_NegoIntro_2_3Net_Prog_Last__c, PLAN_Target_2_3Net_Prog__c, NEGO_NegoIntro_4Net_Prog_val_Last__c, PLAN_Target_Index4_Nego_val__c, NEGO_NegoIntro_5Net_Prog_val_Last__c, PLAN_Target_Index5_Nego_val__c, NEGO_NegoIntro_Posted_Date_Last__c,
                            NEGO_Rise_Rate_Validated_YE__c, NEGO_Depreciation_Rate_Validated_YE__c, NEGO_Rise_Rate_Requested__c,
                            NEGO_Rise_Rate_Validated_Nb__c, NEGO_Depreciation_Rate_Validated_Nb__c, NEGO_Rise_Rate_Status__c,
                            NEGO_Rise_Rate1_Validated__c, NEGO_Rise_Rate2_Validated__c, NEGO_Rise_Rate3_Validated__c,
                            NEGO_Rise_Rate4_Validated__c, NEGO_Rise_Rate5_Validated__c, NEGO_Rise_Rate6_Validated__c,
                            NEGO_Rise_Rate7_Validated__c, NEGO_Rise_Rate8_Validated__c, NEGO_Rise_Rate9_Validated__c,
                            NEGO_Rise_Rate10_Validated__c, NEGO_Depreciation_Rate1_Validated__c, NEGO_Rise_Rate_Validated__c,
                            NEGO_Depreciation_Rate2_Validated__c, PLAN_Target_2_3_4Net_Prog__c, NEGO_Depreciation_Rate3_Validated__c
                            FROM Nego_Plan__c
                            WHERE Nego_Scope__c = :topContract.Supplier_Nego_Scope__c
                            AND Nego_Year__c = :topContract.Reference_Year__c];
        }
        if(negoplanList != null && negoplanList.size() > 0) {
            negoPlan = negoplanList.get(0);
        } else {
            negoPlan = new Nego_Plan__c();
            negoPlan.Nego_Scope__c = topContract.Supplier_Nego_Scope__c;
            negoPlan.Nego_Year__c = topContract.Reference_Year__c;
        }

      negoBaseInit_valeurReelle_index4 = (contractNBIIndexList.size() > 3 &&  contractNBIIndexList.get(3).Computed != null)
                                            ? contractNBIIndexList.get(3).Computed : 0;
        negoBaseInit_valeurReelle_index5 =  (contractNBIIndexList.size() > 4 &&  contractNBIIndexList.get(4).Computed != null)
                                            ? contractNBIIndexList.get(4).Computed : 0;
       ref_CA_index3 = (contractNBIndexList.size() > 2 && contractNBIndexList.get(2).TO != null)
                        ? contractNBIndexList.get(2).TO : 0;
    }
    // Generate executive summary
    public PageReference executiveSummary() {
        try {
            // check access Contract__c fields
            String[] contractFields = new String[] {
                SObjectType.Contract__c.fields.Id.Name,
                SObjectType.Contract__c.fields.Name.Name,
                SObjectType.Contract__c.fields.Parent_Contract__c.Name,
                SObjectType.Contract__c.fields.createdDate.Name,
                SObjectType.Contract__c.fields.RecordTypeId.Name,
                SObjectType.Contract__c.fields.Supplier__c.Name,
                SObjectType.Contract__c.fields.Supplier_Nego_Scope__c.Name,
                SObjectType.Contract__c.fields.Contract_BDate__c.Name,
                // SObjectType.Contract__c.fields.Total_TO_Fact__c.Name,
                SObjectType.Contract__c.fields.Total_TO__c.Name,
                // SObjectType.Contract__c.fields.Total_TO_Actu__c.Name,
                SObjectType.Contract__c.fields.Buying_Payment_Term_Abbrev__c.Name,
                SObjectType.Contract__c.fields.Services_Payment_Term_Abbrev__c.Name,
                SObjectType.Contract__c.fields.TO1__c.Name,
                SObjectType.Contract__c.fields.Index1_perc__c.Name,
                SObjectType.Contract__c.fields.Index2_perc__c.Name,
                SObjectType.Contract__c.fields.Index3_perc__c.Name,
                SObjectType.Contract__c.fields.Index4_perc__c.Name,
                SObjectType.Contract__c.fields.Index5_perc__c.Name,
                SObjectType.Contract__c.fields.Index1__c.Name, // indice 2 net
                SObjectType.Contract__c.fields.Index2__c.Name,// indice 3 net SRP
                SObjectType.Contract__c.fields.Index3__c.Name,// indice 3 net nego hors fid
                SObjectType.Contract__c.fields.Index4__c.Name,//indice 3 net nego fid
                SObjectType.Contract__c.fields.Index5__c.Name,// indice 4 net
                SObjectType.Contract__c.fields.Index6__c.Name,// indice 5 net
                SObjectType.Contract__c.fields.Index7__c.Name,//indice 6 net
                SObjectType.Contract__c.fields.Index1_v2__c.Name,
                SObjectType.Contract__c.fields.Index1_v2_perc__c.Name,
                SObjectType.Contract__c.fields.Index2_v2__c.Name,
                SObjectType.Contract__c.fields.Index2_v2_perc__c.Name,
                SObjectType.Contract__c.fields.Index3_v2__c.Name,
                SObjectType.Contract__c.fields.Index3_v2_perc__c.Name,
                SObjectType.Contract__c.fields.Index4_v2__c.Name,
                SObjectType.Contract__c.fields.Index4_v2_perc__c.Name,
                SObjectType.Contract__c.fields.Index5_v2__c.Name,
                SObjectType.Contract__c.fields.Index5_v2_perc__c.Name,
                SObjectType.Contract__c.fields.Index6_v2__c.Name,
                SObjectType.Contract__c.fields.Index6_v2_perc__c.Name,
                SObjectType.Contract__c.fields.Index7_v2__c.Name,
                SObjectType.Contract__c.fields.Index7_v2_perc__c.Name,
                SObjectType.Contract__c.fields.Rise_Rate_YE__c.Name, // tarif(base)
                SObjectType.Contract__c.fields.Secure_Multiyear__c.Name,
                SObjectType.Contract__c.fields.D_N__c.Name
            };
             // check access Supplier__c fields
            String[] supplierFields = new String[] {
                SObjectType.Supplier__c.fields.Name.Name
            };
            // check access NegoScope__c fields
            String[] negoScopeFields = new String[] {
                SObjectType.NegoScope__c.fields.Name.Name,
                SObjectType.NegoScope__c.fields.ManagePromoFlatPriceRate__c.Name
            };
            // check access BusinessUnit__c fields
            String[] orgaBUFields = new String[] {
                SObjectType.BusinessUnit__c.fields.Name.Name
            };
            // check access Contract_Discount__c fields
            String[] conditionFields = new String[] {
                SObjectType.Contract_Discount__c.fields.Condition_Type__c.Name,
                SObjectType.Contract_Discount__c.fields.Nego_Discount_Type__c.Name,
                SObjectType.Contract_Discount__c.fields.Contract__c.Name,
                SObjectType.Contract_Discount__c.fields.Value_per__c.Name,
                SObjectType.Contract_Discount__c.fields.Value_amt__c.Name,
                SObjectType.Contract_Discount__c.fields.Value_per_Y1__c.Name,
                SObjectType.Contract_Discount__c.fields.Value_amt_Y1__c.Name,
                SObjectType.Contract_Discount__c.fields.Value_per_Y2__c.Name,
                SObjectType.Contract_Discount__c.fields.Value_amt_Y2__c.Name,
                SObjectType.Contract_Discount__c.fields.Value_per_Y3__c.Name,
                SObjectType.Contract_Discount__c.fields.Value_amt_Y3__c.Name,
                SObjectType.Contract_Discount__c.fields.Value_per_Y4__c.Name,
                SObjectType.Contract_Discount__c.fields.Value_amt_Y4__c.Name,
                SObjectType.Contract_Discount__c.fields.Value_per_Y5__c.Name,
                SObjectType.Contract_Discount__c.fields.Value_amt_Y5__c.Name,
                // SObjectType.Contract_Discount__c.fields.Y_Actu__c.Name,
                SObjectType.Contract_Discount__c.fields.Product_Scope__c.Name,
                SObjectType.Contract_Discount__c.fields.Is_Conditional__c.Name,
                SObjectType.Contract_Discount__c.fields.slab_1__c.Name,
                SObjectType.Contract_Discount__c.fields.slab_per_1__c.Name,
                SObjectType.Contract_Discount__c.fields.slab_2__c.Name,
                SObjectType.Contract_Discount__c.fields.slab_per_2__c.Name,
                SObjectType.Contract_Discount__c.fields.slab_3__c.Name,
                SObjectType.Contract_Discount__c.fields.slab_per_3__c.Name,
                SObjectType.Contract_Discount__c.fields.slab_4__c.Name,
                SObjectType.Contract_Discount__c.fields.slab_per_4__c.Name,
                SObjectType.Contract_Discount__c.fields.slab_5__c.Name,
                SObjectType.Contract_Discount__c.fields.slab_per_5__c.Name,
                SObjectType.Contract_Discount__c.fields.slab_6__c.Name,
                SObjectType.Contract_Discount__c.fields.slab_per_6__c.Name,
                SObjectType.Contract_Discount__c.fields.index_v2__c.Name
            };
            // check access Pol_Sale_Condition__c fields
            String[] salesConditionFields = new String[] {
                SObjectType.Pol_Sale_Condition__c.fields.Merchandiser_Authorization__c.Name,
                SObjectType.Pol_Sale_Condition__c.fields.Return_Authorization1__c.Name
            };
            // check access Pol_Com_Condition__c fields
            String[] tarrifConditionFields = new String[] {
                SObjectType.Pol_Com_Condition__c.fields.Name.Name,
                SObjectType.Pol_Com_Condition__c.fields.Index__c.Name
            };

            List<NegoScope__c> negoScope = new List<NegoScope__c>();
            if (NegoptimHelper.checkAccessibility(NegoScope__c.SObjectType, negoScopeFields))
                {
                    // load negoScope
                    negoScope = [Select Id, ManagePromoFlatPriceRate__c FROM NegoScope__c ];
                }

            List<Contract__c> contracts = new List<Contract__c>();
            if (NegoptimHelper.checkAccessibility(Contract__c.SObjectType, contractFields)
                && NegoptimHelper.checkAccessibility(Supplier__c.SObjectType, supplierFields)
                && NegoptimHelper.checkAccessibility(NegoScope__c.SObjectType, negoScopeFields)
                && NegoptimHelper.checkAccessibility(BusinessUnit__c.SObjectType, orgaBUFields)
                && NegoptimHelper.checkAccessibility(Contract_Discount__c.SObjectType, conditionFields)
                && NegoptimHelper.checkAccessibility(Pol_Sale_Condition__c.SObjectType, salesConditionFields)
                && NegoptimHelper.checkAccessibility(Pol_Com_Condition__c.SObjectType, tarrifConditionFields)) {
                // load contracts
                contracts = [SELECT c.Id, c.Name, c.Supplier__c, c.Contract_BDate__c,
                            //  c.Total_TO_Fact__c,
                             c.RecordTypeId, c.RecordType.DeveloperName, c.Retention_Rate__c,c.Retention_Rate_Promo__c,c.Reference_year__c,
                             c.Total_TO__c,
                            //  c.Total_TO_Actu__c,
                             c.Buying_Payment_Term_Abbrev__c, c.Services_Payment_Term_Abbrev__c,
                             c.Total_TO_4Net_Nego_YE__c,
                             c.Total_TO_3Net_Nego_YE__c,
                             c.Supplier__r.Name, c.Supplier_Nego_Scope__r.Name, c.BusinessUnitContract__r.Name, c.TO1__c,c.TO2__c,c.TO3__c,c.TO4__c,c.TO5__c,c.TO6__c,c.TO7__c,c.TO8__c,c.TO9__c,c.TO10__c,c.TO11__c,c.TO12__c,
                             c.Default_Sales_Conditions__r.Merchandiser_Authorization__c, c.Default_Sales_Conditions__r.Return_Authorization1__c, Rise_Rate_YE__c, Depreciation_Rate_YE__c, Markdown_Rate_Break__c, Markdown_Rate_Promo__c, Markdown_Rate_Theft__c,
                             Index1_perc__c, Index2_perc__c, Index3_perc__c, Index4_perc__c, Index5_perc__c, Index6_perc__c, Index7_perc__c, Secure_Multiyear__c, Index1__c, Index2__c, Index3__c, Index4__c, Index5__c, Index6__c, Index7__c,
                             Supplier_Nego_Scope__r.NS_Code__c, Supplier_Nego_Scope__r.OwnerId, Supplier_Nego_Scope__r.Owner.Name,
                            //  Supplier__r.Size__c,
                            //  Supplier__r.Retail_Federation__c,
                             Supplier_Nego_Scope__r.ManagePromoFlatPriceRate__c,
                             Index1_v2__c, Index1_v2_perc__c, Index2_v2__c, Index2_v2_perc__c, Index3_v2__c, Index3_v2_perc__c, Index4_v2__c, Index4_v2_perc__c, Index5_v2__c, Index5_v2_perc__c, Index6_v2__c, Index6_v2_perc__c, Index7_v2__c, Index7_v2_perc__c,
                             Contract_EDate__c, Qty1__c, Qty2__c, Qty3__c, Qty4__c, Qty5__c, Qty6__c, Qty7__c,
                             Qty8__c, Qty9__c, Qty10__c, Qty11__c, Qty12__c, IsCalculatedIndexV2__c,
                             (SELECT Condition_Type__c, Condition_Type__r.Nego_Discount_Type__c, Condition_Type__r.Index__c, Condition_Type__r.Name, Nego_Discount_Type__c, Contract__c, Value_per__c, Value_amt__c, Rank__c, Is_Tariff_Condition__c,
                             Is_Excluded_To_NegoBase__c , Is_Excluded_To_Nego_Base_F__c, Is_Excluded_To_Nego_Base_U__c, Exclusion_to_Nego_Base_Value__c, Value_per_Y1__c, Value_amt_Y1__c, Value_per_Y2__c, Value_amt_Y2__c, Index_val__c, Index_perc__c,
                             unit_amount__c, Disc_EDate__c, Disc_BDate__c, BusinessUnitScope__c , Base_TO_Nego__c, Index__c, Value_per_Y3__c, Value_amt_Y3__c, Value_per_Y4__c, Value_amt_Y4__c, Value_per_Y5__c, Value_amt_Y5__c,
                             Unit_Amount_Type__c, Base_TO_Nego_YearBase__c, Status__c, Base_Quantity_Nego__c,
                            //  Y_Actu__c,
                             Product_Scope__c, Product_Scope__r.Name, Is_Conditional__c,
                             index_v2__c, slab_1__c, slab_per_1__c, slab_2__c, slab_per_2__c, slab_3__c, slab_per_3__c, slab_4__c,
                              Is_Yearly_Condition__c, slab_per_4__c, slab_5__c, slab_per_5__c, slab_6__c, slab_per_6__c, slab_calc_method__c,
                              Condition_Type__r.Capture_Discount_Product_Level__c
                              FROM Contract_Discounts__r
                              WHERE status__c != 'Deleted' AND Parent_discount__c = null
                              ORDER BY Condition_Type__r.Index__c ASC, Condition_Type__r.Name ASC),
                             (SELECT Merchandiser_Authorization__c, Return_Authorization1__c
                              FROM Sales_Conditions_Exception__r)
                             FROM Contract__c c
                             WHERE (Id = :topContract.Id
                                    OR (c.RecordTypeId = :negoBaseRecordTypeId AND CALENDAR_YEAR(Contract_BDate__c) = :(Integer.valueOf(topContract.Reference_Year__c) - 1) AND D_N__c = 'N')
                                    OR (c.RecordTypeId = :negoBaseInitRecordTypeId AND CALENDAR_YEAR(Contract_BDate__c) = :(Integer.valueOf(topContract.Reference_Year__c)))
                                    OR (c.RecordTypeId = :targetRecordTypeId AND Parent_Contract__c = :topContract.Parent_Contract__c)
                                    OR (c.RecordTypeId = :safeRecordTypeId AND c.createdDate < :topContract.createdDate AND CALENDAR_YEAR(Contract_BDate__c) = :(Integer.valueOf(topContract.Reference_Year__c))))
                             AND Supplier__c = :topContract.Supplier__c
                             AND Supplier_Nego_Scope__c = :topContract.Supplier_Nego_Scope__c
                             AND status__c != 'Deleted'
                             ORDER BY createdDate DESC];
            }
            NegoptimSettings negoSettings = loadGlobalSettings();
            Contract__c targetContract;
            for(Contract__c item : contracts) {
                if(item.RecordTypeId == negoBaseRecordTypeId) {
                    refContract = item;
                } else if(item.RecordTypeId == targetRecordTypeId) {
                    targetContract = item;

                } else if(item.RecordTypeId == safeRecordTypeId && safeContract == null && negoSettings.sBusinessType == 'CPG') {
                    safeContract = item;
                }else if(item.RecordTypeId == negoBaseInitRecordTypeId){
                    negoBaseInitContract = item ;
                } else  {
                    currentContract = item;

                }
            }
            if(refContract == null) {
                refContract = new Contract__c();
                ////ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.FATAL, 'Contract not exist with the selected Nego Scope for the year ' + (negoYear - 1));
                ////ApexPages.addMessage(myMsg);
                ////return null;
            }
            if( negoBaseInitContract == null){
                negoBaseInitContract = new Contract__c();
            }
            if(safeContract == null) {
                safeContract = new Contract__c();
                ////ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.FATAL, 'Contract not exist with the selected Nego Scope for the year ' + (negoYear - 1));
                ////ApexPages.addMessage(myMsg);
                ////return null;
            }
            if(currentContract == null) {
                ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.FATAL, System.Label.MSG_SIMULATION_CONTACT_NOT_EXISTS_WITH_SELECTED_NEGO_SCOPE_FOR_THE_YEAR + topContract.Reference_Year__c);
                ApexPages.addMessage(myMsg);
                return null;
            }
            ContractServices contractServiceRef = new ContractServices(refContract,refContract.Contract_Discounts__r);
            contractNBIndexList = contractServiceRef.calculateContractIndex(true);
            BaseIndexRef = NegoptimHelper.formatDecimalValue(contractServiceRef.getContractBaseIndex(), 2);

            ContractServices contractServiceCur = new ContractServices(currentContract,currentContract.Contract_Discounts__r);
            ContractServices contractServiceNBInit = new ContractServices(negoBaseInitContract,negoBaseInitContract.Contract_Discounts__r);
            contractNBIIndexList = contractServiceNBInit.calculateContractIndex(true);
            // for (ContractServices.ContractIndexWrapper wNbi : contractNBIIndexList) {
                //<!-- JIRA 428 & 4645 -->
                // if (wNbi.indexName == 'Index4') {
                //     negoBaseInitContractTotalTo4Net = wNbi.To != null? wNbi.To.format().replaceAll('\u202F', ' ') : '0';
                // }
                // if (wNbi.indexName == 'Index2') {
                //     negoBaseInitContractTotalTo2Net = wNbi.To != null? wNbi.To.format().replaceAll('\u202F', ' ') : '0';
                // }
                // if (wNbi.indexName == 'Index3') {
                //     negoBaseInitContractTotalTo3Net = wNbi.To != null? wNbi.To.format().replaceAll('\u202F', ' ') : '0';
                // }
            // }
            BaseIndexCur = NegoptimHelper.formatDecimalValue(contractServiceNBInit.getContractBaseIndex(), 2);
            Decimal baseDiff = contractServiceNBInit.getContractBaseIndex() != null ? ((contractServiceCur.getContractBaseIndex() - contractServiceNBInit.getContractBaseIndex()) / contractServiceNBInit.getContractBaseIndex() * 100) : 0;
            BaseIndexEvol =  NegoptimHelper.formatDecimalValue(baseDiff, 2);
            //refreshExecutiveSummary();
        } catch (Exception ex) {
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.FATAL, ex.getMessage());
            ApexPages.addMessage(myMsg);
            System.debug('ERRORS  >>>> ' + ex.getLineNumber() + ' <<<< line'+ ex.getMessage() + ' - ' + ex.getStackTraceString());
        }
        return null;
    }

    public PageReference changeYear() {
        //refreshExecutiveSummary();
        return null;
    }
    public PageReference submitApproval() {
        try {
            // if ((negoPlan == null || negoPlan.NEGO_Rise_Rate_Validated__c == null || negoPlan.NEGO_Rise_Rate_Status__c != 'Validated')) {
            //     ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, Label.MSG_RiseRate_Required));
            //     return null;
            // }
            // NEG-9600
            // Decimal riseRateYE = topContract.Rise_Rate_YE__c == 0 || topContract.Rise_Rate_YE__c == null ? 0 : topContract.Rise_Rate_YE__c;
            // NEG-9600
            Decimal riseRateYE = topContract.Rise_Rate_YE__c;
            // Decimal negoRiseRateYE = negoPlan.NEGO_Rise_Rate_Validated_YE__c == 0 || negoPlan.NEGO_Rise_Rate_Validated_YE__c == null ? 0 : negoPlan.NEGO_Rise_Rate_Validated_YE__c;
            Decimal negoRiseRateYE = negoPlan?.NEGO_Rise_Rate_Validated_YE__c;
            // Decimal depreciationRateYE = topContract.Depreciation_Rate_YE__c == 0 || topContract.Depreciation_Rate_YE__c == null ? 0 : topContract.Depreciation_Rate_YE__c;
            Decimal depreciationRateYE = topContract?.Depreciation_Rate_YE__c;
            // Decimal negoDepreciationRateYE = negoPlan.NEGO_Depreciation_Rate_Validated_YE__c == 0 || negoPlan.NEGO_Depreciation_Rate_Validated_YE__c == null ? 0 : negoPlan.NEGO_Depreciation_Rate_Validated_YE__c;
            Decimal negoDepreciationRateYE = negoPlan?.NEGO_Depreciation_Rate_Validated_YE__c;

            Integer riseRateNb = Integer.valueOf((negoPlan.NEGO_Rise_Rate_Validated_Nb__c > 0 && negoPlan.NEGO_Rise_Rate_Validated_Nb__c <= 10) ? negoPlan.NEGO_Rise_Rate_Validated_Nb__c : 1);
            Integer deprRateNb = Integer.valueOf((negoPlan.NEGO_Depreciation_Rate_Validated_Nb__c > 0 && negoPlan.NEGO_Depreciation_Rate_Validated_Nb__c <= 3) ? negoPlan.NEGO_Depreciation_Rate_Validated_Nb__c : 1);

            // NEG-9600
            // Decimal riseRate = topContract.Rise_Rate__c == 0 || topContract.Rise_Rate__c == null ? 0 : topContract.Rise_Rate__c;
            // NEG-9600
            Decimal riseRate = topContract.Rise_Rate__c;
            // Decimal negoRiseRate_i = negoPlan.get('NEGO_Rise_Rate' + riseRateNb + '_Validated__c') == null ? 0 : Decimal.valueOf(String.valueOf(negoPlan.get('NEGO_Rise_Rate' + riseRateNb + '_Validated__c')));
            Decimal negoRiseRate_i = (Decimal)negoPlan?.get('NEGO_Rise_Rate' + riseRateNb + '_Validated__c');
            // Decimal depreciationRate = topContract.Depreciation_Rate__c == 0 || topContract.Depreciation_Rate__c == null ? 0 : topContract.Depreciation_Rate__c;
            Decimal depreciationRate = topContract?.Depreciation_Rate__c;
            // Decimal negoDepreciationRate_i = negoPlan.get('NEGO_Depreciation_Rate' + deprRateNb + '_Validated__c') == null ? 0 : Decimal.valueOf(String.valueOf(negoPlan.get('NEGO_Depreciation_Rate' + deprRateNb + '_Validated__c')));
            Decimal negoDepreciationRate_i = (Decimal)negoPlan?.get('NEGO_Depreciation_Rate' + deprRateNb + '_Validated__c');

            // check quatity management
            Boolean quantityManagementRequired = false;
            Boolean quantityManagementLineLevelRequired = false;
            for (Contract_Discount__c item : topContract.Contract_Discounts__r) {
            if (topContract.Total_Qty__c == null || topContract.Total_Qty__c == 0) {
                    if ((item.unit_amount__c != null && item.unit_amount__c != 0 && (item.Unit_Amount_Type__c == 'UC' || item.Unit_Amount_Type__c == 'Piece')) || (item.Is_Conditional__c && (item.slab_calc_method__c == 'Qty'
                                                                                                                || item.slab_calc_method__c == 'Prog Qty'
                                                                                                                || item.slab_calc_method__c == 'Inc Qty'
                                                                                                                || item.slab_calc_method__c == 'Inc Prog Qty')))
                    {
                        quantityManagementRequired = true;
                    }
                }
                if (item.Base_Quantity_Nego__c == null || item.Base_Quantity_Nego__c == 0) {
                    if ((item.unit_amount__c != null && item.unit_amount__c != 0 && (item.Unit_Amount_Type__c == 'UC' || item.Unit_Amount_Type__c == 'Piece')) || (item.Is_Conditional__c && (item.slab_calc_method__c == 'Qty'
                                                                                                                || item.slab_calc_method__c == 'Prog Qty'
                                                                                                                || item.slab_calc_method__c == 'Inc Qty'
                                                                                                                || item.slab_calc_method__c == 'Inc Prog Qty')))
                    {
                        quantityManagementRequired = true;
                    }
                    if ((item.unit_amount__c != null && item.unit_amount__c != 0 && (item.Unit_Amount_Type__c != 'UC' && item.Unit_Amount_Type__c != 'Piece')))
                    {
                        quantityManagementLineLevelRequired = true;
                }
            }
            }
            if (topContract.Is_OnTop_Simulation__c == true && riseRateYE == negoRiseRateYE && depreciationRateYE == negoDepreciationRateYE && !quantityManagementRequired && !quantityManagementLineLevelRequired) {
                Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
                // pass object id
                req.setObjectId(topContract.Id);
                // set submitter
                req.setSubmitterId(UserInfo.getUserId());
                // set Next Approver Ids
                req.setNextApproverIds(new List<Id>{this.approverId != null ? this.approverId : UserInfo.getUserId()});
                // optional comment
                req.setComments(System.Label.MSG_Simulation_Approval_Comments);
                // submit the approval request for processing
                Approval.ProcessResult result = Approval.process(req);
                // fill the approval users Id
                List<Id> approversIdsList = new List<Id>();
                if (result.actorIds != null) {
                    for(Id uid : result.actorIds) {
                        if(uid != null ) { // skip the first item because it is null
                            approversIdsList.add(uid);
                        }
                    }
                }
                attachPdfToObjectAndEmail(approversIdsList);
                // check access Contract__c fields
                String[] contractFields = new String[] {
                    SObjectType.Contract__c.fields.Id.Name,
                    SObjectType.Contract__c.fields.Status__c.Name
                };
                // Reload Simulation Contract to get new status
                if (NegoptimHelper.checkAccessibility(Contract__c.SObjectType, contractFields)) {
                    topContract.Status__c = [SELECT Status__c FROM Contract__c WHERE Id = :topContract.Id].Status__c;
                }
                contractProcessInstance = getContractProcessInstance();
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, System.Label.MSG_APPROVAL_ALREADY_SENT));
            } else {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, System.Label.MSG_Contract_not_valid_for_approval_please_verify));
                if (!topContract.Is_OnTop_Simulation__c) {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, SObjectType.Contract__c.fields.Is_OnTop_Simulation__c.Label + ' = ' + Label.LBL_True));
                }
                if (riseRateYE != negoRiseRateYE) {
                    String taux = negoRiseRate_i != null ? negoRiseRate_i.format() + '%' : ' vide ';
                    String messageRiseRate = 'le dernier taux de la HMP du contrat doit être égal à ' + taux;
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, messageRiseRate));
                }
                if (depreciationRateYE != negoDepreciationRateYE) {
                    String taux = negoDepreciationRate_i != null ? negoDepreciationRate_i.format() + '%': ' vide ';
                    String messageDeprRate = 'le dernier taux de la BT/RSF du contrat doit être égal à ' + taux ;
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, messageDeprRate));
                }
                if (quantityManagementRequired) {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 'Attention vous n\'avez pas mis de volume dans mettre à jour l\'accord'));
                }
                if (quantityManagementLineLevelRequired) {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 'Attention vous n\'avez pas mis de volume dans saisie des conditions'));
                }
            }
        } catch(Exception ex) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, ex.getMessage()));
            System.debug('ERRORS  >>>> ' + ex.getLineNumber() + ' <<<< line'+ ex.getMessage() + ' - ' + ex.getStackTraceString());
        }
        return null;
    }
    public void attachPdfToObjectAndEmail(List<Id> approversIdsList) {
        PageReference pg =  currentContract.recordType.developerName == 'Simulation' ?  Page.ExecutiveSummaryPDF_Simulation : Page.ExecutiveSummaryPDF_Signed;
        pg.getParameters().put('id', '' + topContract.Id);
        pg.getParameters().put('contentType', '');
        Blob reportPdf;
        try {
            reportPdf = Test.isRunningTest() ? Blob.valueOf('UNIT.TEST') : pg.getContentAsPDF();
            // Insert new Attachment to the record
            Attachment attachmentPDF = new Attachment();
            attachmentPdf.parentId = topContract.Id;
            attachmentPdf.Name = topContract.Name + ' -'+ system.now() + '.pdf';
            attachmentPdf.ContentType = 'application/pdf';
            attachmentPdf.Body = reportPdf;
            // check security on insert attachment fields
            String[] attachmentFields = new String[] {
                SObjectType.Attachment.fields.Name.Name,
                SObjectType.Attachment.fields.Body.Name,
                SObjectType.Attachment.fields.ParentId.Name,
                SObjectType.Attachment.fields.ContentType.Name
            };
            if(NegoptimHelper.checkCreatibility(Attachment.SObjectType, attachmentFields)) {
                insert attachmentPDF;
            }
            // FOR NEG-6053
            //
            // Email
            // Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
            // message.toAddresses = approversIdsList; // we can add contact ids also
            // message.subject = 'Approval required for ' + topContract.Name /* + ' + Attachment' */;
            // // // Attach file to email
            // // Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
            // // efa.setContentType('application/pdf');
            // // efa.setFileName(attachmentPDF.Name);
            // // efa.setInline(false);
            // // efa.setBody(attachmentPDF.Body);
            // // message.setFileAttachments(new Messaging.EmailFileAttachment[] {efa});
            // // Set email body
            // String body = 'Good morning Dears,<br>';
            // body += topContract.CreatedBy.Name + ' has created the contract ' + topContract.Name + ' that requested validation<br><br>';
            // body += 'Please approve this contract.<br>';
            // body += 'by going to this link : ' + System.URL.getOrgDomainUrl().toExternalForm() + '/' + topContract.Id + '<br>';
            // body += 'Kind regards,<br>';
            // body += topContract.CreatedBy.Name + '<br>';
            // // body += Test.isRunningTest() ? 'UNIT.TEST' : pg.getContent().toString();
            // message.htmlBody = body;
            // Messaging.SingleEmailMessage[] messages = new List<Messaging.SingleEmailMessage> {message};
            // Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);
        } catch (VisualforceException ex) {
            reportPdf = Blob.valueOf('Some Text');
            System.debug('ERRORS  >>>> ' + ex.getLineNumber() + ' <<<< line'+ ex.getMessage() + ' - ' + ex.getStackTraceString());
        }/*  catch (System.EmailException ex){
            System.debug('ERRORS  >>>> ' + ex.getLineNumber() + ' <<<< line'+ ex.getMessage() + ' - ' + ex.getStackTraceString());
        } */ catch (Exception ex) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, ex.getMessage()));
            System.debug('ERRORS  >>>> ' + ex.getLineNumber() + ' <<<< line'+ ex.getMessage() + ' - ' + ex.getStackTraceString());
        }
    }

    public class NegoptimSettings {
        String sBusinessType;
    }
    public static NegoptimSettings loadGlobalSettings() {
        return (NegoptimSettings)JSON.deserialize(GlobalSettingsManager.loadGlobalSettingsSerialized(), NegoptimSettings.class);
    }
}