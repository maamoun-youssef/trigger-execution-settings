import { Assortment__c, ASD_API_NAMES, BU_API_NAMES, AS_API_NAMES, PROD_API_NAMES } from './properties.js';

//START
// assortment detail NDs and WDs helper methods
const getOffsetCumulWithGap = (assortmentDetail, gap, stratCalc, cpltCalc, self) => {
    let offsetCumul = 0;
    let key = assortmentDetail[ASD_API_NAMES.Hierarchy__c] + assortmentDetail[ASD_API_NAMES.ClientCategory__c];
    let key2 = assortmentDetail[ASD_API_NAMES.Hierarchy__c] + null;
    let clusterStratsList = self.categoryBUClustersMap.hasOwnProperty(key) ? self.categoryBUClustersMap[key] : [];
    if (clusterStratsList.length == 0) {
        clusterStratsList = self.categoryBUClustersMap.hasOwnProperty(key2) ? self.categoryBUClustersMap[key2] : [];
    }
    let clusterCpltsList = self.categoryBUCpltMap.hasOwnProperty(key) ? self.categoryBUCpltMap[key] : [];
    if (clusterCpltsList.length == 0) {
        clusterCpltsList = self.categoryBUCpltMap.hasOwnProperty(key2) ? self.categoryBUCpltMap[key2] : [];
    }
    try {
        let productClusterMap = assortmentDetail[ASD_API_NAMES.ProductCluster__c] ? JSON.parse(assortmentDetail[ASD_API_NAMES.ProductCluster__c]) : {};
        let productClusterStrat = productClusterMap['Strat'] || [];
        let productClusterCplt = productClusterMap['Cplt'] || [];
        let isStrat = productClusterStrat.filter(strat => strat.value).length > 0;
        let isCplt = productClusterCplt.filter(cplt => cplt.value).length > 0;
        let selectedMap = {};
        productClusterStrat.forEach(strat => {
            selectedMap['Strat' + strat.index] = strat.value;
        });
        productClusterCplt.forEach(cplt => {
            selectedMap['Cplt' + cplt.index] = cplt.value;
        });
        if (stratCalc && clusterStratsList && clusterStratsList.length > 0 && isStrat) {
            for (let item of clusterStratsList) {
                if (selectedMap.hasOwnProperty('Strat' + item.index) && selectedMap['Strat' + item.index]) {
                    if (gap >= 1)
                        offsetCumul += item.cluster[BU_API_NAMES.SiteOfSalesNumberN1__c] ?? 0;
                    if (gap == 0)
                        offsetCumul += item.cluster[BU_API_NAMES.SiteOfSalesNumber__c] ?? 0;
                    if (gap == -1)
                        offsetCumul += item.cluster[BU_API_NAMES.SiteOfSalesNumberP1__c] ?? 0;
                    if (gap <= -2)
                        offsetCumul += item.cluster[BU_API_NAMES.SiteOfSalesNumberP2__c] ?? 0;
                }
            }
        }
        if (cpltCalc && clusterCpltsList && clusterCpltsList.length > 0 && isCplt) {
            for (let item of clusterCpltsList) {
                if (selectedMap.hasOwnProperty('Cplt' + item.index) && selectedMap['Cplt' + item.index]) {
                    if (gap >= 1)
                        offsetCumul += item.cluster[BU_API_NAMES.SiteOfSalesNumberN1__c] ?? 0;
                    if (gap == 0)
                        offsetCumul += item.cluster[BU_API_NAMES.SiteOfSalesNumber__c] ?? 0;
                    if (gap == -1)
                        offsetCumul += item.cluster[BU_API_NAMES.SiteOfSalesNumberP1__c] ?? 0;
                    if (gap <= -2)
                        offsetCumul += item.cluster[BU_API_NAMES.SiteOfSalesNumberP2__c] ?? 0;
                }
            }
        }
    } catch (ex) {
        console.log('Exception: >>>>>' + ex.message);
        console.log(ex.stack + '<<<<<');
    }
    return offsetCumul;
}

const getSumSOSClusters = (clusters, gap) => {
    try {
        let sumSOSClusters = 0;
        if (clusters && clusters.length > 0) {
            clusters.forEach(item => {
                if (gap >= 1)
                    sumSOSClusters += item.cluster[BU_API_NAMES.SiteOfSalesNumberN1__c] ?? 0;
                if (gap == 0)
                    sumSOSClusters += item.cluster[BU_API_NAMES.SiteOfSalesNumber__c] ?? 0;
                if (gap == -1)
                    sumSOSClusters += item.cluster[BU_API_NAMES.SiteOfSalesNumberP1__c] ?? 0;
                if (gap <= -2)
                    sumSOSClusters += item.cluster[BU_API_NAMES.SiteOfSalesNumberP2__c] ?? 0;
            });
        }
        return sumSOSClusters;
    } catch (ex) {
        console.log('Exception: >>>>>' + ex.message);
        console.log(ex.stack + '<<<<<');
        return 0;
    }
}

const getBUTargetSOS = (assortmentDetail, gap) => {
    let bannerSOS = 0;
    if (assortmentDetail[ASD_API_NAMES.Assortment__c.replace('__c', '__r')] && assortmentDetail[ASD_API_NAMES.Assortment__c.replace('__c', '__r')][AS_API_NAMES.BusinessUnitTarget__c.replace('__c', '__r')]) {
        if (gap >= 1) {
            bannerSOS = assortmentDetail[ASD_API_NAMES.Assortment__c.replace('__c', '__r')][AS_API_NAMES.BusinessUnitTarget__c.replace('__c', '__r')][BU_API_NAMES.SiteOfSalesNumberN1__c] ?? 0;
        } else if (gap == 0) {
            bannerSOS = assortmentDetail[ASD_API_NAMES.Assortment__c.replace('__c', '__r')][AS_API_NAMES.BusinessUnitTarget__c.replace('__c', '__r')][BU_API_NAMES.SiteOfSalesNumber__c] ?? 0;
        } else if (gap == -1) {
            bannerSOS = assortmentDetail[ASD_API_NAMES.Assortment__c.replace('__c', '__r')][AS_API_NAMES.BusinessUnitTarget__c.replace('__c', '__r')][BU_API_NAMES.SiteOfSalesNumberP1__c] ?? 0;
        } else if (gap <= -2) {
            bannerSOS = assortmentDetail[ASD_API_NAMES.Assortment__c.replace('__c', '__r')][AS_API_NAMES.BusinessUnitTarget__c.replace('__c', '__r')][BU_API_NAMES.SiteOfSalesNumberP2__c] ?? 0;
        }
    }

    return bannerSOS;
}

const getBUTargetWD = (assortmentDetail, gap) => {
    let bannerWD = 0;
    if (assortmentDetail[ASD_API_NAMES.Assortment__c.replace('__c', '__r')] && assortmentDetail[ASD_API_NAMES.Assortment__c.replace('__c', '__r')][AS_API_NAMES.BusinessUnitTarget__c.replace('__c', '__r')]) {
        if (gap >= 1) {
            bannerWD = assortmentDetail[ASD_API_NAMES.Assortment__c.replace('__c', '__r')][AS_API_NAMES.BusinessUnitTarget__c.replace('__c', '__r')][BU_API_NAMES.WeightedDistributionManualN1__c] ?? 0;
        } else if (gap == 0) {
            bannerWD = assortmentDetail[ASD_API_NAMES.Assortment__c.replace('__c', '__r')][AS_API_NAMES.BusinessUnitTarget__c.replace('__c', '__r')][BU_API_NAMES.WeightedDistributionManual__c] ?? 0;
        } else if (gap == -1) {
            bannerWD = assortmentDetail[ASD_API_NAMES.Assortment__c.replace('__c', '__r')][AS_API_NAMES.BusinessUnitTarget__c.replace('__c', '__r')][BU_API_NAMES.WeightedDistributionManualP1__c] ?? 0;
        } else if (gap <= -2) {
            bannerWD = assortmentDetail[ASD_API_NAMES.Assortment__c.replace('__c', '__r')][AS_API_NAMES.BusinessUnitTarget__c.replace('__c', '__r')][BU_API_NAMES.WeightedDistributionManualP2__c] ?? 0;
        }
    }
    return bannerWD;
}

const getSOSCircuit = (assortmentDetail, gap) => {
    let sumSOSCircuit = 0;
    if (assortmentDetail[ASD_API_NAMES.Assortment__c.replace('__c', '__r')] && assortmentDetail[ASD_API_NAMES.Assortment__c.replace('__c', '__r')][AS_API_NAMES.BusinessUnitSource__c.replace('__c', '__r')]) {
        if (gap >= 1) {
            sumSOSCircuit = assortmentDetail[ASD_API_NAMES.Assortment__c.replace('__c', '__r')][AS_API_NAMES.BusinessUnitSource__c.replace('__c', '__r')][BU_API_NAMES.SiteOfSalesNumberN1__c] ?? 0;
        } else if (gap == 0) {
            sumSOSCircuit = assortmentDetail[ASD_API_NAMES.Assortment__c.replace('__c', '__r')][AS_API_NAMES.BusinessUnitSource__c.replace('__c', '__r')][BU_API_NAMES.SiteOfSalesNumber__c] ?? 0;
        } else if (gap == -1) {
            sumSOSCircuit = assortmentDetail[ASD_API_NAMES.Assortment__c.replace('__c', '__r')][AS_API_NAMES.BusinessUnitSource__c.replace('__c', '__r')][BU_API_NAMES.SiteOfSalesNumberP1__c] ?? 0;
        } else if (gap <= -2) {
            sumSOSCircuit = assortmentDetail[ASD_API_NAMES.Assortment__c.replace('__c', '__r')][AS_API_NAMES.BusinessUnitSource__c.replace('__c', '__r')][BU_API_NAMES.SiteOfSalesNumberP2__c] ?? 0;
        }
    }
    return sumSOSCircuit;
}

const getSumDVClusters = (clusters, gap) => {
    try {
        let sumDVClusters = 0;
        if (clusters && clusters.length > 0) {
            clusters.forEach(item => {
                if (gap >= 1)
                    sumDVClusters += item.cluster[BU_API_NAMES.WeightedDistributionManualN1__c] ?? 0;
                if (gap == 0)
                    sumDVClusters += item.cluster[BU_API_NAMES.WeightedDistributionManual__c] ?? 0;
                if (gap == -1)
                    sumDVClusters += item.cluster[BU_API_NAMES.WeightedDistributionManualP1__c] ?? 0;
                if (gap <= -2)
                    sumDVClusters += item.cluster[BU_API_NAMES.WeightedDistributionManualP2__c] ?? 0;
            });
        }
        return sumDVClusters;
    } catch (ex) {
        console.error('Exception: >>>>>' + ex.message + ' - LINE: ' + ex.lineNumber);
        console.error(ex.stack + '<<<<<');
        return 0;
    }
}

const isCplt = (assortmentDetail) => {
    let productClusterMap = assortmentDetail[ASD_API_NAMES.ProductCluster__c] ? JSON.parse(assortmentDetail[ASD_API_NAMES.ProductCluster__c]) : {};
    let productClusterCplt = productClusterMap.Cplt || [];
    return productClusterCplt.filter(cplt => cplt.value).length > 0;
}
//NDClientBased
const getNDClientBasedWithGap = (assortmentDetail, gap, self) => {
    let NDClientBased = 0, NDClientBasedStrat = 0, NDClientBasedCplt = 0;
    let key = assortmentDetail[ASD_API_NAMES.Hierarchy__c] + assortmentDetail[ASD_API_NAMES.ClientCategory__c];
    let key2 = assortmentDetail[ASD_API_NAMES.Hierarchy__c] + null;
    let clusterStratsList = self.categoryBUClustersMap.hasOwnProperty(key) ? self.categoryBUClustersMap[key] : [];
    if (clusterStratsList.length == 0) {
        clusterStratsList = self.categoryBUClustersMap.hasOwnProperty(key2) ? self.categoryBUClustersMap[key2] : [];
    }
    let clusterCpltsList = self.categoryBUCpltMap.hasOwnProperty(key) ? self.categoryBUCpltMap[key] : [];
    if (clusterCpltsList.length == 0) {
        clusterCpltsList = self.categoryBUCpltMap.hasOwnProperty(key2) ? self.categoryBUCpltMap[key2] : [];
    }
    try {
        let productClusterMap = assortmentDetail[ASD_API_NAMES.ProductCluster__c] ? JSON.parse(assortmentDetail[ASD_API_NAMES.ProductCluster__c]) : {};
        let productClusterStrat = productClusterMap['Strat'] || [];
        let isStrat = productClusterStrat.filter(strat => strat.value).length > 0;
        let offsetCumulStrat = getOffsetCumulWithGap(assortmentDetail, gap, true, false, self);
        let offsetCumulCplt = getOffsetCumulWithGap(assortmentDetail, gap, false, true, self);
        if (clusterStratsList && clusterStratsList.length > 0 && isStrat) {
            let sumSOSClusters = getSumSOSClusters(clusterStratsList, gap);
            NDClientBasedStrat = sumSOSClusters == 0 ? 0 : (offsetCumulStrat / sumSOSClusters) * 100;
        }
        if (clusterCpltsList && clusterCpltsList.length > 0 && isCplt(assortmentDetail)) {
            let buTargetSOS = getBUTargetSOS(assortmentDetail, gap);
            NDClientBasedCplt = buTargetSOS == 0 ? 0 : (offsetCumulCplt / buTargetSOS) * 100;
        }
        NDClientBased = NDClientBasedStrat + NDClientBasedCplt;
    } catch (error) {
        console.error('Exception: >>>>>' + error.message + ' - LINE: ' + error.lineNumber);
        console.error(error.stack + '<<<<<');
    }
    return NDClientBased;
}

const getWDClientBasedWithGap = (assortmentDetail, gap, self) => {
    let WDClientBased = 0, WDClientBasedStrat = 0, WDClientBasedCplt = 0;
    let key = assortmentDetail[ASD_API_NAMES.Hierarchy__c] + assortmentDetail[ASD_API_NAMES.ClientCategory__c];
    let key2 = assortmentDetail[ASD_API_NAMES.Hierarchy__c] + null;
    let clusterStratsList = self.categoryBUClustersMap.hasOwnProperty(key) ? self.categoryBUClustersMap[key] : [];
    if (clusterStratsList.length == 0) {
        clusterStratsList = self.categoryBUClustersMap.hasOwnProperty(key2) ? self.categoryBUClustersMap[key2] : [];
    }
    let clusterCpltsList = self.categoryBUCpltMap.hasOwnProperty(key) ? self.categoryBUCpltMap[key] : [];
    if (clusterCpltsList.length == 0) {
        clusterCpltsList = self.categoryBUCpltMap.hasOwnProperty(key2) ? self.categoryBUCpltMap[key2] : [];
    }
    try {
        let productClusterMap = assortmentDetail[ASD_API_NAMES.ProductCluster__c] ? JSON.parse(assortmentDetail[ASD_API_NAMES.ProductCluster__c]) : {};
        let productClusterStrat = productClusterMap['Strat'] || [];
        let isStrat = productClusterStrat.filter(strat => strat.value).length > 0;
        let WDMarketBasedStrat = getWDMarketBasedWithGap(assortmentDetail, gap, true, false, self);
        let WDMarketBasedCplt = getWDMarketBasedWithGap(assortmentDetail, gap, false, true, self);
        if (clusterStratsList && clusterStratsList.length > 0 && isStrat) {
            let sumDVClusters = getSumDVClusters(clusterStratsList, gap);
            WDClientBasedStrat = sumDVClusters == 0 ? 0 : (WDMarketBasedStrat / sumDVClusters) * 100;
        }
        if (clusterCpltsList && clusterCpltsList.length > 0 && isCplt(assortmentDetail)) {
            let buTargetWD = getBUTargetWD(assortmentDetail, gap);
            WDClientBasedCplt = buTargetWD == 0 ? 0 : (WDMarketBasedCplt / buTargetWD) * 100;
        }
        WDClientBased = WDClientBasedStrat + WDClientBasedCplt;
    } catch (ex) {
        console.error('Exception: >>>>>' + ex.message + ' - LINE: ' + ex.lineNumber);
        console.error(ex.stack + '<<<<<');
    }
    return WDClientBased;
}

const getNDChannelBasedWithGap = (assortmentDetail, gap, self) => {
    let NDChannelBased = 0, NDChannelBasedStrat = 0, NDChannelBasedCplt = 0;
    let key = assortmentDetail[ASD_API_NAMES.Hierarchy__c] + assortmentDetail[ASD_API_NAMES.ClientCategory__c];
    let key2 = assortmentDetail[ASD_API_NAMES.Hierarchy__c] + null;
    let clusterStratsList = self.categoryBUClustersMap.hasOwnProperty(key) ? self.categoryBUClustersMap[key] : [];
    if (clusterStratsList.length == 0) {
        clusterStratsList = self.categoryBUClustersMap.hasOwnProperty(key2) ? self.categoryBUClustersMap[key2] : [];
    }
    let clusterCpltsList = self.categoryBUCpltMap.hasOwnProperty(key) ? self.categoryBUCpltMap[key] : [];
    if (clusterCpltsList.length == 0) {
        clusterCpltsList = self.categoryBUCpltMap.hasOwnProperty(key2) ? self.categoryBUCpltMap[key2] : [];
    }
    try {
        let productClusterMap = assortmentDetail[ASD_API_NAMES.ProductCluster__c] ? JSON.parse(assortmentDetail[ASD_API_NAMES.ProductCluster__c]) : {};
        let productClusterStrat = productClusterMap['Strat'] || [];
        let isStrat = productClusterStrat.filter(strat => strat.value).length > 0;
        let offsetCumulStrat = getOffsetCumulWithGap(assortmentDetail, gap, true, false, self);
        let offsetCumulCplt = getOffsetCumulWithGap(assortmentDetail, gap, false, true, self);
        if (clusterStratsList && clusterStratsList.length > 0 && isStrat) {
            let SOSCircuit = getSOSCircuit(assortmentDetail, gap);
            NDChannelBasedStrat = SOSCircuit == 0 ? 0 : (offsetCumulStrat / SOSCircuit) * 100;
        }
        if (clusterCpltsList && clusterCpltsList.length > 0 && isCplt(assortmentDetail)) {
            let buTargetSOS = getBUTargetSOS(assortmentDetail, gap);
            NDChannelBasedCplt = buTargetSOS == 0 ? 0 : (offsetCumulCplt / buTargetSOS) * 100;
        }
        NDChannelBased = NDChannelBasedStrat + NDChannelBasedCplt;
    } catch (ex) {
        console.error('Exception: >>>>>' + ex.message + ' - LINE: ' + ex.lineNumber);
        console.error(ex.stack + '<<<<<');
    }
    return NDChannelBased;
}

const getWDMarketBasedWithGap = (assortmentDetail, gap, stratCalc, cpltCalc, self) => {
    let WDMarketBased = 0;
    let key = assortmentDetail[ASD_API_NAMES.Hierarchy__c] + assortmentDetail[ASD_API_NAMES.ClientCategory__c];
    let key2 = assortmentDetail[ASD_API_NAMES.Hierarchy__c] + null;
    let clusterStratsList = self.categoryBUClustersMap.hasOwnProperty(key) ? self.categoryBUClustersMap[key] : [];
    if (clusterStratsList.length == 0) {
        clusterStratsList = self.categoryBUClustersMap.hasOwnProperty(key2) ? self.categoryBUClustersMap[key2] : [];
    }
    let clusterCpltsList = self.categoryBUCpltMap.hasOwnProperty(key) ? self.categoryBUCpltMap[key] : [];
    if (clusterCpltsList.length == 0) {
        clusterCpltsList = self.categoryBUCpltMap.hasOwnProperty(key2) ? self.categoryBUCpltMap[key2] : [];
    }
    try {
        let productClusterMap = assortmentDetail[ASD_API_NAMES.ProductCluster__c] ? JSON.parse(assortmentDetail[ASD_API_NAMES.ProductCluster__c]) : {};
        let productClusterStrat = productClusterMap['Strat'] || [];
        let productClusterCplt = productClusterMap['Cplt'] || [];
        let isStrat = productClusterStrat.filter(strat => strat.value).length > 0;
        let isCplt = productClusterCplt.filter(cplt => cplt.value).length > 0;
        let selectedMap = {};
        productClusterStrat.forEach(strat => {
            selectedMap['Strat' + strat.index] = strat.value;
        });
        productClusterCplt.forEach(cplt => {
            selectedMap['Cplt' + cplt.index] = cplt.value;
        });
        if (stratCalc && clusterStratsList && clusterStratsList.length > 0 && isStrat) {
            for (let item of clusterStratsList) {
                if (selectedMap.hasOwnProperty('Strat' + item.index) && selectedMap['Strat' + item.index]) {
                    if (gap >= 1)
                        WDMarketBased += item.cluster[BU_API_NAMES.WeightedDistributionManualN1__c] ?? 0;
                    if (gap == 0)
                        WDMarketBased += item.cluster[BU_API_NAMES.WeightedDistributionManual__c] ?? 0;
                    if (gap == -1)
                        WDMarketBased += item.cluster[BU_API_NAMES.WeightedDistributionManualP1__c] ?? 0;
                    if (gap <= -2)
                        WDMarketBased += item.cluster[BU_API_NAMES.WeightedDistributionManualP2__c] ?? 0;
                }
            }
        }
        if (cpltCalc && clusterCpltsList && clusterCpltsList.length > 0 && isCplt) {
            for (let item of clusterCpltsList) {
                if (selectedMap.hasOwnProperty('Cplt' + item.index) && selectedMap['Cplt' + item.index]) {
                    if (gap >= 1)
                        WDMarketBased += item.cluster[BU_API_NAMES.WeightedDistributionManualN1__c] ?? 0;
                    if (gap == 0)
                        WDMarketBased += item.cluster[BU_API_NAMES.WeightedDistributionManual__c] ?? 0;
                    if (gap == -1)
                        WDMarketBased += item.cluster[BU_API_NAMES.WeightedDistributionManualP1__c] ?? 0;
                    if (gap <= -2)
                        WDMarketBased += item.cluster[BU_API_NAMES.WeightedDistributionManualP2__c] ?? 0;
                }
            }
        }
    } catch (ex) {
        console.error('Exception: >>>>>' + ex.message + ' - LINE: ' + ex.lineNumber);
        console.error(ex.stack + '<<<<<');
    }
    return WDMarketBased;
}
const assignKPI = (assortmentDetail, self) => {
    try {
        let currentYear = new Date().getFullYear();
        let gap = assortmentDetail[ASD_API_NAMES.Assortment__c.replace('__c', '__r')] && assortmentDetail[ASD_API_NAMES.Assortment__c.replace('__c', '__r')][AS_API_NAMES.Year__c]
            ? parseInt(assortmentDetail[ASD_API_NAMES.Assortment__c.replace('__c', '__r')][AS_API_NAMES.Year__c]) - currentYear
            : 1;
        let L4Lgap = assortmentDetail[ASD_API_NAMES.Assortment__c.replace('__c', '__r')] && assortmentDetail[ASD_API_NAMES.Assortment__c.replace('__c', '__r')][AS_API_NAMES.Year__c]
            ? parseInt(assortmentDetail[ASD_API_NAMES.Assortment__c.replace('__c', '__r')][AS_API_NAMES.Year__c]) - new Date().getFullYear() + 1
            : 1;
        let WDMarketBased = getWDMarketBasedWithGap(assortmentDetail, gap, true, true, self);
        let WDClientBased = getWDClientBasedWithGap(assortmentDetail, gap, self);
        let NDChannelBased = getNDChannelBasedWithGap(assortmentDetail, gap, self);
        let NDChannelBasedL4L = getNDChannelBasedWithGap(assortmentDetail, L4Lgap, self);
        let NDClientBased = getNDClientBasedWithGap(assortmentDetail, gap, self);
        let NDClientBasedL4L = getNDClientBasedWithGap(assortmentDetail, L4Lgap, self);
        let offsetCumul = getOffsetCumulWithGap(assortmentDetail, gap, true, true, self);
        let L4LWDMarketBased = getWDMarketBasedWithGap(assortmentDetail, L4Lgap, true, true, self);
        let L4LWDClientBased = getWDClientBasedWithGap(assortmentDetail, L4Lgap, self);
        let L4LOffsetCumul = getOffsetCumulWithGap(assortmentDetail, L4Lgap, true, true, self);

        if (assortmentDetail[ASD_API_NAMES.Assortment__c.replace('__c', '__r')].RecordType.DeveloperName == 'Negotiation' || assortmentDetail[ASD_API_NAMES.Assortment__c.replace('__c', '__r')].RecordType.DeveloperName == 'Simulation') {
            assortmentDetail[ASD_API_NAMES.WDChannelBaseNego__c] = WDMarketBased ? +WDMarketBased.toFixed(self.ASDScaleMap[ASD_API_NAMES.WDChannelBaseNego__c]) : 0;
            assortmentDetail[ASD_API_NAMES.NDChannelBaseNego__c] = NDChannelBased ? +NDChannelBased.toFixed(self.ASDScaleMap[ASD_API_NAMES.NDChannelBaseNego__c]) : 0;
            assortmentDetail[ASD_API_NAMES.NDChannelBaseNegoL4L__c] = NDChannelBasedL4L ? +NDChannelBasedL4L.toFixed(self.ASDScaleMap[ASD_API_NAMES.NDChannelBaseNegoL4L__c]) : 0;
            assortmentDetail[ASD_API_NAMES.NDClientBaseNego__c] = NDClientBased ? +NDClientBased.toFixed(self.ASDScaleMap[ASD_API_NAMES.NDClientBaseNego__c]) : 0;
            assortmentDetail[ASD_API_NAMES.WDClientBaseNego__c] = WDClientBased ? +WDClientBased.toFixed(self.ASDScaleMap[ASD_API_NAMES.WDClientBaseNego__c]) : 0;
            assortmentDetail[ASD_API_NAMES.PNClientBaseNego__c] = WDClientBased ? +((WDClientBased / 100).toFixed(self.ASDScaleMap[ASD_API_NAMES.PNClientBaseNego__c])) : 0;
            assortmentDetail[ASD_API_NAMES.SOSNumberNego__c] = +offsetCumul.toFixed(self.ASDScaleMap[ASD_API_NAMES.SOSNumberNego__c]);
            assortmentDetail[ASD_API_NAMES.WDChannelBaseNegoL4L__c] = (assortmentDetail[ASD_API_NAMES.Status__c] == 'Validate' || assortmentDetail[ASD_API_NAMES.Status__c] == 'PreviouslyValidate' || assortmentDetail[ASD_API_NAMES.AssortmentDetailLHistory__c]) ? L4LWDMarketBased.toFixed(self.ASDScaleMap['PNChannelBaseNegoL4L__c']) : 0;
            assortmentDetail[ASD_API_NAMES.WDClientBaseNegoL4L__c] = (assortmentDetail[ASD_API_NAMES.Status__c] == 'Validate' || assortmentDetail[ASD_API_NAMES.Status__c] == 'PreviouslyValidate' || assortmentDetail[ASD_API_NAMES.AssortmentDetailLHistory__c]) ? L4LWDClientBased ? L4LWDClientBased.toFixed(self.ASDScaleMap[ASD_API_NAMES.WDClientBaseNegoL4L__c]) : 0 : 0;
            assortmentDetail[ASD_API_NAMES.PNClientBaseNegoL4L__c] = (assortmentDetail[ASD_API_NAMES.Status__c] == 'Validate' || assortmentDetail[ASD_API_NAMES.Status__c] == 'PreviouslyValidate' || assortmentDetail[ASD_API_NAMES.AssortmentDetailLHistory__c]) ? L4LWDClientBased ? (L4LWDClientBased / 100).toFixed(self.ASDScaleMap[ASD_API_NAMES.PNClientBaseNegoL4L__c]) : 0 : 0;
            assortmentDetail[ASD_API_NAMES.NDClientBaseNegoL4L__c] = (assortmentDetail[ASD_API_NAMES.Status__c] == 'Validate' || assortmentDetail[ASD_API_NAMES.Status__c] == 'PreviouslyValidate' || assortmentDetail[ASD_API_NAMES.AssortmentDetailLHistory__c]) ? NDClientBasedL4L ? NDClientBasedL4L.toFixed(self.ASDScaleMap[ASD_API_NAMES.NDClientBaseNegoL4L__c]) : 0 : 0;
            assortmentDetail[ASD_API_NAMES.SOSNumberNegoL4L__c] = (assortmentDetail[ASD_API_NAMES.Status__c] == 'Validate' || assortmentDetail[ASD_API_NAMES.Status__c] == 'PreviouslyValidate' || assortmentDetail[ASD_API_NAMES.AssortmentDetailLHistory__c]) ? L4LOffsetCumul ? L4LOffsetCumul.toFixed(self.ASDScaleMap[ASD_API_NAMES.SOSNumberNegoL4L__c]) : 0 : 0;
        }
        if (assortmentDetail[ASD_API_NAMES.Assortment__c.replace('__c', '__r')].RecordType.DeveloperName == 'Target') {
            assortmentDetail[ASD_API_NAMES.NDClientBaseTarget__c] = NDClientBased ? +NDClientBased.toFixed(self.ASDScaleMap[ASD_API_NAMES.NDClientBaseTarget__c]) : 0;
            assortmentDetail[ASD_API_NAMES.NDChannelBaseTarget__c] = NDChannelBased ? + NDChannelBased.toFixed(self.ASDScaleMap[ASD_API_NAMES.NDChannelBaseTarget__c]) : 0;
            assortmentDetail[ASD_API_NAMES.WDClientBaseTarget__c] = WDClientBased ? +WDClientBased.toFixed(self.ASDScaleMap[ASD_API_NAMES.WDClientBaseTarget__c]) : 0;
            assortmentDetail[ASD_API_NAMES.WDChannelBaseTarget__c] = WDMarketBased ? +WDMarketBased.toFixed(self.ASDScaleMap[ASD_API_NAMES.WDChannelBaseTarget__c]) : 0;
            assortmentDetail[ASD_API_NAMES.SOSNumberTarget__c] = offsetCumul ? +offsetCumul.toFixed(self.ASDScaleMap[ASD_API_NAMES.SOSNumberTarget__c]) : 0;
        }
    } catch (ex) {
        console.error('Exception: >>>>>' + ex.message + ' - LINE: ' + ex.lineNumber);
        console.error(ex.stack);
    }
}

const calculateFormulaFields = (assortmentDetail, fieldName, self) => {
    try {
        //1ST STEP
        recalculateAsdFormulaFields(assortmentDetail, self);
        // assortmentDetail[QtyNego__c.fieldApiName] = (assortmentDetail[SOSNumberNego_NegoL4LP1Gap__c.fieldApiName] ?? 0) * AWS * (52 - (assortmentDetail[StartDate_W__c.fieldApiName] ?? 0) + 1);
        assortmentDetail[ASD_API_NAMES.PNChannelBaseNegoL4L__c] = +(((assortmentDetail[ASD_API_NAMES.WDChannelBaseNegoL4L__c] ?? 0) / 100).toFixed(self.ASDScaleMap[ASD_API_NAMES.PNChannelBaseNegoL4L__c]));
        assortmentDetail[ASD_API_NAMES.PNChannelBaseNego__c] = +(((assortmentDetail[ASD_API_NAMES.WDChannelBaseNego__c] ?? 0) / 100).toFixed(self.ASDScaleMap[ASD_API_NAMES.PNChannelBaseNego__c]));
        assortmentDetail[ASD_API_NAMES.PNChannelBaseTarget__c] = +(((assortmentDetail[ASD_API_NAMES.WDChannelBaseTarget__c] ?? 0) / 100).toFixed(self.ASDScaleMap[ASD_API_NAMES.PNChannelBaseTarget__c]));
        assortmentDetail[ASD_API_NAMES.PNChannelBaseBudget__c] = +(((assortmentDetail[ASD_API_NAMES.WDchannelBasebudget__c] ?? 0) / 100).toFixed(self.ASDScaleMap[ASD_API_NAMES.PNChannelBaseBudget__c]));
        assortmentDetail[ASD_API_NAMES.PNClientBaseNegoL4L__c] = +(((assortmentDetail[ASD_API_NAMES.WDClientBaseNegoL4L__c] ?? 0) / 100).toFixed(self.ASDScaleMap[ASD_API_NAMES.PNClientBaseNegoL4L__c]));
        assortmentDetail[ASD_API_NAMES.PNClientBaseNego__c] = +(((assortmentDetail[ASD_API_NAMES.WDClientBaseNego__c] ?? 0) / 100).toFixed(self.ASDScaleMap[ASD_API_NAMES.PNClientBaseNego__c]));
        assortmentDetail[ASD_API_NAMES.PNClientBaseTarget__c] = +(((assortmentDetail[ASD_API_NAMES.WDClientBaseTarget__c] ?? 0) / 100).toFixed(self.ASDScaleMap[ASD_API_NAMES.PNClientBaseTarget__c]));
        assortmentDetail[ASD_API_NAMES.PNClientBaseTarget__c] = +(((assortmentDetail[ASD_API_NAMES.WDClientBaseTarget__c] ?? 0) / 100).toFixed(self.ASDScaleMap[ASD_API_NAMES.PNClientBaseTarget__c]));
        assortmentDetail[ASD_API_NAMES.WDChannelBaseBudget_NegoL4LP1Gap__c] = (assortmentDetail[ASD_API_NAMES.WDchannelBasebudget__c] ?? 0) - (assortmentDetail[ASD_API_NAMES.WDChannelBaseNegoL4L_P1__c] ?? 0);
        assortmentDetail[ASD_API_NAMES.NDChannelBaseBudget_NegoL4LP1Gap__c] = (assortmentDetail[ASD_API_NAMES.NDChannelBaseBudget__c] ?? 0) - (assortmentDetail[ASD_API_NAMES.NDChannelBaseNegoL4L_P1__c] ?? 0);
        if (assortmentDetail[ASD_API_NAMES.WDchannelBasebudget__c] && assortmentDetail[ASD_API_NAMES.WDchannelBasebudget__c] != 0) {
            assortmentDetail[ASD_API_NAMES.PNChannelBaseBudget_NegoL4LP1Gap__c] = (assortmentDetail[ASD_API_NAMES.PNChannelBaseBudget__c] ?? 0) - (assortmentDetail[ASD_API_NAMES.PNChannelBaseNegoL4L_P1__c] ?? 0);
        }
        let productTotalKW = assortmentDetail[ASD_API_NAMES.Product__c] && assortmentDetail[ASD_API_NAMES.Product__c.replace('__c', '__r')] && assortmentDetail[ASD_API_NAMES.Product__c.replace('__c', '__r')][PROD_API_NAMES.TotalKWeight__c] ? assortmentDetail[ASD_API_NAMES.Product__c.replace('__c', '__r')][PROD_API_NAMES.TotalKWeight__c] : 0;
        let AWS = assortmentDetail[ASD_API_NAMES.AvgWeeklySalesClient__c] != 0 && assortmentDetail[ASD_API_NAMES.AvgWeeklySalesClient__c] ? assortmentDetail[ASD_API_NAMES.AvgWeeklySalesClient__c] : (assortmentDetail[ASD_API_NAMES.AvgWeeklySalesChannel__c] ? assortmentDetail[ASD_API_NAMES.AvgWeeklySalesChannel__c] : 0);
        if (assortmentDetail[ASD_API_NAMES.Assortment__c] != null
            && (self.mainData.currentAssortment.RecordType.DeveloperName == 'Negotiation'
                || self.mainData.currentAssortment.RecordType.DeveloperName == 'Target'
                || self.mainData.currentAssortment.RecordType.DeveloperName == 'Simulation')) {
            if (self.mainData.applyCalcFullYearQty_P1) {
                assortmentDetail[ASD_API_NAMES.QtyNego_P1__c] = +(((assortmentDetail[ASD_API_NAMES.SOSNumberNegoL4L_P1__c] != null ? assortmentDetail[ASD_API_NAMES.SOSNumberNegoL4L_P1__c] : 0) * AWS * 52).toFixed(self.ASDScaleMap[ASD_API_NAMES.QtyNego_P1__c]));
                assortmentDetail[ASD_API_NAMES.KVolumeNego_P1__c] = +(((assortmentDetail[ASD_API_NAMES.QtyNego_P1__c] ?? 0) * productTotalKW).toFixed(self.ASDScaleMap[ASD_API_NAMES.KVolumeNego_P1__c]));
            }
        }
        //2ND STEP
        recalculateAsdFormulaFields(assortmentDetail, self);
        // calculation of QtyBudget, KVolumeBudget
        /*if (assortmentDetail[ASD_API_NAMES.Assortment__c] != null && self.mainData.currentAssortment.RecordType.DeveloperName == 'ChannelBudget') {
        if (!assortmentDetail[ASD_API_NAMES.IsAdditionalProduct__c]) {
        assortmentDetail[ASD_API_NAMES.QtyBudget__c] = +(((assortmentDetail[ASD_API_NAMES.QtyNego_P1__c] != null ? assortmentDetail[ASD_API_NAMES.QtyNego_P1__c] : 0) * (1 + (assortmentDetail[ASD_API_NAMES.WDChannelBaseNegoL4L_P1__c] != null && assortmentDetail[ASD_API_NAMES.WDChannelBaseNegoL4L_P1__c] != 0 ? ((assortmentDetail[ASD_API_NAMES.WDChannelBaseBudget_NegoL4LP1Gap__c] != null ? assortmentDetail[ASD_API_NAMES.WDChannelBaseBudget_NegoL4LP1Gap__c] : 0) / assortmentDetail[ASD_API_NAMES.WDChannelBaseNegoL4L_P1__c]) : 0))).toFixed(self.ASDScaleMap[ASD_API_NAMES.QtyBudget__c]));
        }
        assortmentDetail[ASD_API_NAMES.KVolumeBudget__c] = +(((assortmentDetail[ASD_API_NAMES.QtyBudget__c] != null ? assortmentDetail[ASD_API_NAMES.QtyBudget__c] : 0) * productTotalKW).toFixed(self.ASDScaleMap[ASD_API_NAMES.KVolumeBudget__c]));
        }*/

        // calculation of QtyTarget, KVolumeTarget
        if (assortmentDetail[ASD_API_NAMES.Assortment__c] && self.mainData.currentAssortment.RecordType.DeveloperName == 'Target') {
            assortmentDetail[ASD_API_NAMES.QtyTarget__c] = +((assortmentDetail[ASD_API_NAMES.QtyNego_P1__c] ? assortmentDetail[ASD_API_NAMES.QtyNego_P1__c] : 0) + ((assortmentDetail[ASD_API_NAMES.SOSNumberTarget_NegoL4LP1Gap__c] ? assortmentDetail[ASD_API_NAMES.SOSNumberTarget_NegoL4LP1Gap__c] : 0) * AWS * (52 - (parseInt(assortmentDetail[ASD_API_NAMES.StartDate_W__c]) ? parseInt(assortmentDetail[ASD_API_NAMES.StartDate_W__c]) : 0) + 1)).toFixed(0));
            assortmentDetail[ASD_API_NAMES.KVolumeTarget__c] = +(((assortmentDetail[ASD_API_NAMES.QtyTarget__c] ? assortmentDetail[ASD_API_NAMES.QtyTarget__c] : 0) * productTotalKW).toFixed(self.ASDScaleMap[ASD_API_NAMES.KVolumeTarget__c]));
        }
        // calculation of QtyNego, KVolumeNego
        if (assortmentDetail[ASD_API_NAMES.Assortment__c] && (self.mainData.currentAssortment.RecordType.DeveloperName == 'Negotiation' || self.mainData.currentAssortment.RecordType.DeveloperName == 'Simulation')) {
            assortmentDetail[ASD_API_NAMES.QtyNego__c] = +(assortmentDetail[ASD_API_NAMES.QtyNego_P1__c] ? +assortmentDetail[ASD_API_NAMES.QtyNego_P1__c] : 0) + +(((assortmentDetail[ASD_API_NAMES.SOSNumberNego_NegoL4LP1Gap__c] ? +assortmentDetail[ASD_API_NAMES.SOSNumberNego_NegoL4LP1Gap__c] : 0) * AWS * (52 - (parseInt(assortmentDetail[ASD_API_NAMES.StartDate_W__c]) ? parseInt(assortmentDetail[ASD_API_NAMES.StartDate_W__c]) : 0) + 1)).toFixed(0));
            assortmentDetail[ASD_API_NAMES.KVolumeNego__c] = +(((assortmentDetail[ASD_API_NAMES.QtyNego__c] ?? 0) * productTotalKW).toFixed(self.ASDScaleMap[ASD_API_NAMES.KVolumeNego__c]));
        }
        // calculation of KVolumePanel, KVolumefact
        assortmentDetail[ASD_API_NAMES.KVolumePanel__c] = +(((assortmentDetail[ASD_API_NAMES.QtyPanel__c] ? +assortmentDetail[ASD_API_NAMES.QtyPanel__c] : 0) * productTotalKW).toFixed(self.ASDScaleMap[ASD_API_NAMES.KVolumePanel__c]));
        assortmentDetail[ASD_API_NAMES.KVolumeFact__c] = +(((assortmentDetail[ASD_API_NAMES.QtyFact__c] ? +assortmentDetail[ASD_API_NAMES.QtyFact__c] : 0) * productTotalKW).toFixed(self.ASDScaleMap[ASD_API_NAMES.KVolumeFact__c]));
        // assortmentDetail[ASD_API_NAMES.DeadProfitPrice__c] = (assortmentDetail[ASD_API_NAMES.SPCCEP_GPUnitNegoUC__c] ? assortmentDetail[ASD_API_NAMES.SPCCEP_GPUnitNegoUC__c] : 0) * productTotalKW;
        if (assortmentDetail[ASD_API_NAMES.Assortment__c]) {
            let productVatRate = assortmentDetail[ASD_API_NAMES.Product__c] && assortmentDetail[ASD_API_NAMES.Product__c.replace('__c', '__r')] && assortmentDetail[ASD_API_NAMES.Product__c.replace('__c', '__r')][PROD_API_NAMES.VATRate__c] ? assortmentDetail[ASD_API_NAMES.Product__c.replace('__c', '__r')][PROD_API_NAMES.VATRate__c] / 100 : 0;
            let retailPriceHT = (assortmentDetail[ASD_API_NAMES.RetailPriceTarget__c] ? assortmentDetail[ASD_API_NAMES.RetailPriceTarget__c] : 0) / (1 + productVatRate);
            if (self.mainData.currentAssortment.RecordType.DeveloperName == 'Target') {
                assortmentDetail[ASD_API_NAMES.GPUnitTarget__c] = (assortmentDetail[ASD_API_NAMES.DeadProfitPrice__c] ? assortmentDetail[ASD_API_NAMES.DeadProfitPrice__c] : 0) - (assortmentDetail[ASD_API_NAMES.UnitCost__c] ? assortmentDetail[ASD_API_NAMES.UnitCost__c] : 0);
                assortmentDetail[ASD_API_NAMES.GPTarget__c] = (assortmentDetail[ASD_API_NAMES.GPUnitTarget__c] ? assortmentDetail[ASD_API_NAMES.GPUnitTarget__c] : 0) * (assortmentDetail[ASD_API_NAMES.QtyTarget__c] ? assortmentDetail[ASD_API_NAMES.QtyTarget__c] : 0);
                assortmentDetail[ASD_API_NAMES.SellInTarget__c] = (assortmentDetail[ASD_API_NAMES.NetPriceTradeBase__c] ? assortmentDetail[ASD_API_NAMES.NetPriceTradeBase__c] : 0) * (assortmentDetail[ASD_API_NAMES.QtyTarget__c] ? assortmentDetail[ASD_API_NAMES.QtyTarget__c] : 0);
                assortmentDetail[ASD_API_NAMES.SellOutTarget__c] = retailPriceHT * (assortmentDetail[ASD_API_NAMES.QtyTarget__c] ? assortmentDetail[ASD_API_NAMES.QtyTarget__c] : 0);
                assortmentDetail[ASD_API_NAMES.TMTarget__c] = (retailPriceHT - (assortmentDetail[ASD_API_NAMES.NegoPrice__c] ? assortmentDetail[ASD_API_NAMES.NegoPrice__c] : 0)) * (assortmentDetail[ASD_API_NAMES.QtyTarget__c] ? assortmentDetail[ASD_API_NAMES.QtyTarget__c] : 0);
            } else {
                assortmentDetail[ASD_API_NAMES.GPUnitNego__c] = (assortmentDetail[ASD_API_NAMES.DeadProfitPrice__c] ? assortmentDetail[ASD_API_NAMES.DeadProfitPrice__c] : 0) - (assortmentDetail[ASD_API_NAMES.UnitCost__c] ? assortmentDetail[ASD_API_NAMES.UnitCost__c] : 0);
                assortmentDetail[ASD_API_NAMES.GPNego__c] = (assortmentDetail[ASD_API_NAMES.GPUnitNego__c] ? assortmentDetail[ASD_API_NAMES.GPUnitNego__c] : 0) * (assortmentDetail[ASD_API_NAMES.QtyNego__c] ? assortmentDetail[ASD_API_NAMES.QtyNego__c] : 0);
                assortmentDetail[ASD_API_NAMES.SellInNego__c] = (assortmentDetail[ASD_API_NAMES.NetPriceTradeBase__c] ? assortmentDetail[ASD_API_NAMES.NetPriceTradeBase__c] : 0) * (assortmentDetail[ASD_API_NAMES.QtyNego__c] ? assortmentDetail[ASD_API_NAMES.QtyNego__c] : 0);
                assortmentDetail[ASD_API_NAMES.SellOutNego__c] = retailPriceHT * (assortmentDetail[ASD_API_NAMES.QtyNego__c] ? assortmentDetail[ASD_API_NAMES.QtyNego__c] : 0);
                assortmentDetail[ASD_API_NAMES.TMNego__c] = (retailPriceHT - (assortmentDetail[ASD_API_NAMES.NegoPrice__c] ? assortmentDetail[ASD_API_NAMES.NegoPrice__c] : 0)) * (assortmentDetail[ASD_API_NAMES.QtyNego__c] ? assortmentDetail[ASD_API_NAMES.QtyNego__c] : 0);
            }
        }
        //CALCULATE CORRECTION RATE
        //IF CORRECTION TYPE IS FILLED BUT CORRECTION RATE EMPTY
        // OR
        // CORRECTION TYPE HAS CHANGED
        if (((assortmentDetail[ASD_API_NAMES.SalesCannibalizationType__c] && !assortmentDetail[ASD_API_NAMES.SalesCannibalizationRate__c])
            || (fieldName == ASD_API_NAMES.SalesCannibalizationType__c)) && fieldName != ASD_API_NAMES.SalesCannibalizationRate__c) {
            if (assortmentDetail[ASD_API_NAMES.SalesCannibalizationType__c] && self.hypothesisReportMap.hasOwnProperty(assortmentDetail[ASD_API_NAMES.SalesCannibalizationType__c] + '' + assortmentDetail[ASD_API_NAMES.Assortment__c])) {
                assortmentDetail[ASD_API_NAMES.SalesCannibalizationRate__c] = self.hypothesisReportMap[assortmentDetail[ASD_API_NAMES.SalesCannibalizationType__c] + '' + assortmentDetail[ASD_API_NAMES.Assortment__c]];
            } else {
                assortmentDetail[ASD_API_NAMES.SalesCannibalizationRate__c] = null;
            }
        }
        recalculateAsdFormulaFields(assortmentDetail, self);
    } catch (ex) {
        console.error('Exception: >>>>>' + ex.message + ' - LINE: ' + ex.lineNumber);
        console.error(ex.stack);
    }
}

const buildFormulonVariablesMap = (assortmentDetail, self) => {
    try {
        let variablesMap = {};
        Object.keys(self.asdFieldsCalculationMap).forEach(referencedField => {
            // const formulaFieldList = self.asdFieldsCalculationMap[updatedField];
            // formulaFieldList.forEach(
            // referencedField => {
            if (!Object.keys(variablesMap).includes(referencedField)) {
                const fieldType = self.asdFieldsType[referencedField] ? self.asdFieldsType[referencedField] : 'text';
                let fieldNameParts = referencedField.split('.');
                let fieldValue = null;
                for (let index = 0; index < fieldNameParts.length; index++) {
                    let item = index == 0 ? assortmentDetail : fieldValue;
                    fieldValue = item[fieldNameParts[index]] ? item[fieldNameParts[index]] : false;
                }
                let variable = {
                    type: 'literal',
                    value: fieldValue,
                    dataType: 'text',
                    options: { values: [], scale: 0 }
                };
                switch (fieldType) {
                    case 'BOOLEAN':
                        variable.dataType = 'checkbox';
                        variable.value = Boolean(fieldValue);
                        break;
                    case 'DOUBLE': variable.dataType = 'number'; variable.options.scale = 50; variable.value = fieldValue ? parseFloat(fieldValue) : 0; break;
                    case 'INTEGER': variable.dataType = 'number'; variable.options.scale = 0; variable.value = fieldValue ? parseFloat(fieldValue) : 0; break;
                    case 'PERCENT': variable.dataType = 'number'; variable.options.scale = 50; variable.value = fieldValue ? parseFloat(fieldValue) / 100 : 0; break;
                    case 'CURRENCY':
                        variable.dataType = 'number';
                        variable.value = fieldValue ? parseFloat(fieldValue) : 0;
                        variable.options.scale = 50;
                        break;
                    case 'DATE':
                        variable.dataType = 'date';
                        variable.value = fieldValue ? new Date(fieldValue) : null; // Format as 'YYYY-MM-DD'
                        break;
                    case 'DATETIME':
                        variable.dataType = 'datetime';
                        variable.value = fieldValue ? new Date(fieldValue) : null;
                        break;
                    case 'TIME':
                        variable.dataType = 'time';
                        variable.value = fieldValue ? fieldValue : null;
                        break;
                    case 'PICKLIST':
                        variable.dataType = 'picklist';
                        variable.value = fieldValue ? fieldValue : '';
                        break;
                    default:
                        variable.value = fieldValue ? String(fieldValue) : '';
                }
                variablesMap[referencedField] = variable;
            }
            // }
            // );
        });
        return variablesMap;
    }
    catch (error) {
        console.error(error.message);
    }
}

const recalculateAsdFormulaFields = (assortmentDetail, self) => {
    self.executionFormulaFieldOrder.forEach(formulaField => {
        if (self.formulasMetadata.hasOwnProperty(formulaField)) {
            try{
                let variablesMap = buildFormulonVariablesMap(assortmentDetail, self);
                const res = formulon.parse(self.formulasMetadata[formulaField], variablesMap);
                assortmentDetail[formulaField] = res.value;
                // if (formulaField == 'SPCCEP_SelloutNegoReport__c') {
                // }
            } catch(e) {
                console.error(e.message);
            }
        }
    })
}

const recalculateTotalFormulaFields = (totalsMap, self, allStatus) => {
    self.executionFormulaFieldOrder.forEach(formulaField => {
        if (self.formulasMetadata.hasOwnProperty(formulaField) && self.totalRecalculateFormulaFields.includes(formulaField)) {
            let variablesMap = buildFormulonVariablesTotalMap(totalsMap, self, allStatus);
            const res = formulon.parse(self.formulasMetadata[formulaField], variablesMap);
            if (totalsMap[formulaField]) {
                if (!allStatus) {
                    totalsMap[formulaField].value = res.value;
                } else {
                    totalsMap[formulaField].valueofAllStatus = res.value;
                }
            }
        }
    })
    self.totalsList.forEach(total => {
        if (self.totalRecalculateFormulaFields.includes(total.fieldName)) {
            total.value = totalsMap[total.fieldName].value;
            total.valueofAllStatus = totalsMap[total.fieldName].valueofAllStatus;
        }
    })
}

const buildFormulonVariablesTotalMap = (totalsMap, self, allStatus) => {
    try {
        let variablesMap = {};
        Object.keys(self.asdFieldsCalculationMap).forEach(referencedField => {
            // const formulaFieldList = self.asdFieldsCalculationMap[updatedField];
            // formulaFieldList.forEach(-
            // referencedField => {
            if (!Object.keys(variablesMap).includes(referencedField)) {
                const fieldType = self.asdFieldsType[referencedField] ? self.asdFieldsType[referencedField] : 'text';
                let fieldValue;
                if (totalsMap[referencedField]) {
                    fieldValue = allStatus ? totalsMap[referencedField].valueofAllStatus : totalsMap[referencedField].value;
                } else {
                    fieldValue = false;
                }
                let variable = {
                    type: 'literal',
                    value: fieldValue,
                    dataType: 'text',
                    options: { values: [], scale: 0 }
                };
                switch (fieldType) {
                    case 'BOOLEAN':
                        variable.dataType = 'checkbox';
                        variable.value = fieldValue ? 'true' : 'false';
                        break;
                    case 'DOUBLE': variable.dataType = 'number'; variable.options.scale = 3; variable.value = fieldValue ? parseFloat(fieldValue) : 0; break;
                    case 'INTEGER': variable.dataType = 'number'; variable.options.scale = 0; variable.value = fieldValue ? parseFloat(fieldValue) : 0; break;
                    case 'CURRENCY':
                        variable.dataType = 'number';
                        variable.value = fieldValue ? parseFloat(fieldValue) : 0;
                        break;
                    case 'DATE':
                        variable.dataType = 'date';
                        variable.value = fieldValue ? new Date(fieldValue) : null; // Format as 'YYYY-MM-DD'
                        break;
                    case 'DATETIME':
                        variable.dataType = 'datetime';
                        variable.value = fieldValue ? new Date(fieldValue) : null;
                        break;
                    case 'TIME':
                        variable.dataType = 'time';
                        variable.value = fieldValue ? fieldValue : null;
                        break;
                    case 'PICKLIST':
                        variable.dataType = 'picklist';
                        variable.value = fieldValue ? fieldValue : '';
                        break;
                    default:
                        variable.value = fieldValue ? String(fieldValue) : '';
                }
                variablesMap[referencedField] = variable;
            }
            // }
            // );
        });
        return variablesMap;
    }
    catch (error) {
        console.error(error.message);
    }
}

const recalculateSubTotalFormulaFields = (subTotalsMap, self, allStatus, categIndex) => {
    let categoryId = self.records[categIndex].categoryId;
    self.executionFormulaFieldOrder.forEach(formulaField => {
        if (self.formulasMetadata.hasOwnProperty(formulaField) && self.totalRecalculateFormulaFields.includes(formulaField)) {
            let variablesMap = buildFormulonVariablesTotalMap(subTotalsMap[categoryId], self, allStatus);
            const res = formulon.parse(self.formulasMetadata[formulaField], variablesMap);
            if (subTotalsMap[categoryId][formulaField]) {
                if (!allStatus) {
                    subTotalsMap[categoryId][formulaField].value = res.value;
                } else {
                    subTotalsMap[categoryId][formulaField].valueofAllStatus = res.value;
                }
            }
        }
    })
    self.records[categIndex].subTotalList.forEach(subTotal => {
        if (self.totalRecalculateFormulaFields.includes(subTotal.fieldName)) {
            subTotal.value = subTotalsMap[categoryId][subTotal.fieldName].value;
            subTotal.valueofAllStatus = subTotalsMap[categoryId][subTotal.fieldName].valueofAllStatus;
        }
    })
}

const updateAsdOnClusterChange = (assortmentDetail, item, categIndex, rowIndex, fieldName, oldStatus, newStatus, self) => {
    assignKPI(assortmentDetail, self);
    calculateFormulaFields(assortmentDetail, fieldName, self);
    let fieldIndex = 0;
    let categoryId = self.records[categIndex].categoryId;
    item.values.forEach(field => {
        if (!field.fieldName.includes('.') && (field.isNumberField || field.isBoolean || self.executionFormulaFieldOrder.includes(field.fieldName))) {
            if (field.isNumberField || field.isBoolean) {
                if (field.showInTotal) {
                    self.recalculateSubtotals(categIndex, categoryId, fieldIndex, field.fieldName, field.fieldValue, oldStatus, '-', field.isNumberField ? field.scale : 0);
                }
            }
            field.fieldValue = assortmentDetail[field.fieldName];
            if (field.showInTotal) {
                self.recalculateSubtotals(categIndex, categoryId, fieldIndex, field.fieldName, field.fieldValue, newStatus, '+', field.isNumberField ? field.scale : 0);
            }
        }
        fieldIndex++;
    })
    recalculateSubTotalFormulaFields(self.subTotalsMap, self, true, categIndex);
    recalculateSubTotalFormulaFields(self.subTotalsMap, self, false, categIndex);
    recalculateTotalFormulaFields(self.totalsMap, self, true);
    recalculateTotalFormulaFields(self.totalsMap, self, false);
    // setTimeout(() => {
    let productRow = self.template.querySelector('[data-row="' + rowIndex + '"][data-category="' + categIndex + '"]');
    productRow.classList.toggle('newLoading');
    // }, 200);
}

// const toFixedNumber = (num, digits, base) => {
//     const pow = Math.pow(base ?? 10, digits);
//     return Math.round(num*pow) / pow;
// }

export { updateAsdOnClusterChange, recalculateTotalFormulaFields, recalculateSubTotalFormulaFields };