/**
 * Handler class for NewsCategoryTrigger
 */
public with sharing class NewsCategoryTriggerHandler {

    private static List<News_Category__c> categoriesToSync;
    
    /**
     * Handles after insert events for News_Category__c
     * Uses Queueable for callouts when Sync__c is true
     * @param newRecords List of newly inserted News_Category__c records
     */
    public static void handleInsert(List<News_Category__c> newRecords) {
        // TODO: Implement insert handler
        categoriesToSync = new List<News_Category__c>();
        // - Filter categories that need to be synced (Sync__c = true)
        for(News_Category__c newRecord:newRecords){
            if(newRecord.Sync__c){
                categoriesToSync.add(newRecord);
            }
        }
        // - Call queueable method for callouts
        syncCategoriesWithQueueable(categoriesToSync);
    }
    
    /**
     * Handles after update events for News_Category__c
     * Uses Queueable Apex for callouts when Sync__c is true
     * @param newRecords List of updated News_Category__c records
     * @param oldMap Map of old record states
     */
    public static void handleUpdate(List<News_Category__c> newRecords, Map<Id, News_Category__c> oldMap) {
        // TODO: Implement update handler
        categoriesToSync = new List<News_Category__c>();
        // - Filter categories that need to be synced (Sync__c changed from false to true)
        for(News_Category__c newRecord:newRecords){
            if(oldMap.get(newRecord.Id).Sync__c == false && newRecord.Sync__c){
                categoriesToSync.add(newRecord);
            }
        }
        // - Call queueable method for callouts
        syncCategoriesWithQueueable(categoriesToSync);
    }
    
    /**
     * Queueable method to sync categories using the NewsAPI
     * @param categoriesToSync List of News_Category__c records to sync
     */
    private static void syncCategoriesWithQueueable(List<News_Category__c> categoriesToSync) {
        // TODO: Implement queueable job enqueuing
        // - Create and enqueue NewsCategoryQueueable job for each newRecord
        for(News_Category__c category:categoriesToSync){
            if(Limits.getQueueableJobs() < Limits.getLimitQueueableJobs()){
                System.enqueueJob(new NewsCategoryQueueable(category, 1)); // Considering there are only 6 possible news categories, it's ok to queue the job within a loop as it won't hit the 50 queued jobs cap
            }
        }
    }
} 