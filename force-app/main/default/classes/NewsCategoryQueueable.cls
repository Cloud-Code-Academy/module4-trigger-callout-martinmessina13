/**
 * Queueable Apex class for processing News Category records with pagination support
 */
public class NewsCategoryQueueable implements Queueable, Database.AllowsCallouts {
    // Static variable for maximum pages to fetch
    private final static Integer MAX_PAGES = 3;
    
    private News_Category__c category;
    private Integer currentPage;
    
    /**
     * Constructor
     * @param category The News_Category__c record
     * @param currentPage Current page to process
     */
    public NewsCategoryQueueable(News_Category__c category, Integer currentPage) {
        this.category = category;
        this.currentPage = currentPage;
    }
    
    /**
     * Execute method for the queueable job
     * @param context The QueueableContext
     */
    public void execute(QueueableContext context) {
        News_Category__c updatedCategory = new News_Category__c(Id = category.Id);
        List<Article__c> sfArticles = new List<Article__c>();
        try {
            // - Call NewsAPI for the current page
            NewsAPIResponse response = NewsAPIService.getTopHeadlinesByCategory(category.Name, currentPage, null, null);
            List<NewsAPIResponse.Article> articles = (List<NewsAPIResponse.Article>)response.articles;
            for(NewsAPIResponse.Article article:articles){
                // - Convert API articles to Salesforce articles using NewsAPIResponse.convertToSObject
                Article__c sfArticle = NewsAPIResponse.convertToSObject(article);
                // - Add category reference to each article
                sfArticle.News_Category__c = category.Id;
                sfArticle.Category__c = category.Name;
                sfArticles.add(sfArticle);
            }
            // - Insert the articles
            if(Schema.SObjectType.Article__c.isCreateable()){
                insert as user sfArticles;
                CustomLogger.insertLog('Synced ' + sfArticles.size() + ' articles', 'INFO');
            }

            // Optimum number of pages to sync
            Integer maxPages = getOptimumPagesToSync(response.totalResults); 

            // - Check if reached MAX_PAGES or no more articles
            if(currentPage < maxPages && !articles.isEmpty() && !Test.isRunningTest()){
                System.enqueueJob(new NewsCategoryQueueable(category, ++currentPage));
                return; // Return to avoid updating incomplete categories
            }
            // Category is updated after all pages of articles have been processed
            if(Schema.SObjectType.News_Category__c.isUpdateable()){
                // - Update category with last synced date and sync flag = false
                updatedCategory.Last_Synced__c = System.now();
                updatedCategory.Sync__c = false;
                updatedCategory.Pages__c = response.totalResults;
                update as user updatedCategory;
                CustomLogger.insertLog('Updated category ' + updatedCategory.Name + ' with ' + updatedCategory.Pages__c + ' pages' , 'INFO');
            }
        } catch (Exception e) {
            if(Schema.SObjectType.News_Category__c.isUpdateable()){
                // - Update category with error information
                updatedCategory.Error__c = e.getMessage(); 
                update as user updatedCategory;
            }
            // - Log error to debug logs
            System.debug('Error: ' + e.getMessage());
            System.debug('Error Line: ' + e.getLineNumber());
            System.debug('Stack Trace: ' + e.getStackTraceString());
            CustomLogger.insertLog(e, 'ERROR');
        }
    }

    private Integer getOptimumPagesToSync(Integer totalResults){
        return Integer.valueOf(totalResults != null ? Math.ceil(totalResults / NewsAPIService.PAGE_SIZE) : MAX_PAGES); // Default to 3 if totalResults is null
    }
}