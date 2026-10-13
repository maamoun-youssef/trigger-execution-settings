/**
 * Schedulable class used to run the refresh file directory sharing
 * Run the batch (FileDirectorySharingBatch)
 * @author ULiT
 * @date 03-06-2025
 **/
public class FileDirectorySharingSchedulable implements Schedulable{
    
    private String startedFrom;
    private Set<Id> fileDirectoryIdSet;
    private Set<Id> negoScopeIdSet;
    private Set<Id> supplierIdSet;
    private Set<Id> contactIdSet;
    private Set<String> subTypeSet;
    private Boolean isGenerateContentDocumentLink;
    private Boolean updateFileDirectorySharing;
    private Integer batchSize;
    
    public FileDirectorySharingSchedulable(String startedFrom, Set<Id> fileDirectoryIdSet, Set<Id> negoScopeIdSet, Set<Id> supplierIdSet,
    Set<Id> contactIdSet, Set<String> subTypeSet, Boolean isGenerateContentDocumentLink, Boolean updateFileDirectorySharing, Integer batchSize)
    {
        this.startedFrom = startedFrom;
        this.fileDirectoryIdSet = fileDirectoryIdSet;
        this.negoScopeIdSet = negoScopeIdSet;
        this.contactIdSet = contactIdSet;
        this.subTypeSet = subTypeSet;
        this.isGenerateContentDocumentLink = isGenerateContentDocumentLink;
        this.updateFileDirectorySharing = updateFileDirectorySharing;
        this.batchSize = batchSize;
    }
    
    public void execute(SchedulableContext sc) {
        Map<String, Object> paramsMap = new Map<String, Object>{
            'startedFrom' => FileDirectorySharingSchedulable.class.getName(),
            'fileDirectoryIdSet' => fileDirectoryIdSet,
            'negoScopeIdSet' => negoScopeIdSet,
            'supplierIdSet' => supplierIdSet,
            'contactIdSet' => contactIdSet,
            'subTypeSet' => subTypeSet,
            'isGenerateContentDocumentLink' => isGenerateContentDocumentLink,
            'updateFileDirectorySharing' => updateFileDirectorySharing
        };
        NegoptimBatch.executeBatch('FileDirectorySharingBatch', paramsMap, batchSize);
    }
    
    public void finish(SchedulableContext sc) {
    }
}