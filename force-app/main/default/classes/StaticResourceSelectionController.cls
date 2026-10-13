public with sharing class StaticResourceSelectionController {

    // Only returns what the picker can use: images, videos and zips
    @AuraEnabled(cacheable=true)
    public static List<StaticResource> getStaticResources() {
        return [
            SELECT Name, NamespacePrefix, ContentType
            FROM StaticResource
            WHERE ContentType LIKE 'image/%'
               OR ContentType LIKE 'video/%'
               OR ContentType LIKE '%zip%'
            ORDER BY Name
        ];
    }
}