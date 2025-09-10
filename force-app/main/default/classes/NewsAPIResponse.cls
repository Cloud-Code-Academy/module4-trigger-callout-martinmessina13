/**
 * Wrapper class for parsing the NewsAPI response
 */
public with sharing class NewsAPIResponse {
    private static final Integer LONG_TEXT_LENGTH = 131072;

    public String status { get; set; }
    public Integer totalResults { get; set; }
    public List<Article> articles { get; set; }
    
    /**
     * Inner class representing a news article
     */
    public class Article {
        public String description {get; set;}
		public String url {get; set;}
		public String urlToImage {get; set;}
		public String title {get; set;}
		public String publishedAt {get; set;}
		public String author {get;set;}
		public String content {get; set;}
		public source source {get; set;}
    }
    
    /**
     * Inner class representing a news source
     */
    public class Source {
        public String id {get; set;}
        public String name {get; set;}
    }
    
    /**
     * Static method to convert an API article to a Salesforce Article__c record
     * @param apiArticle The API article to convert
     * @return Article__c The Salesforce record
     */
    public static Article__c convertToSObject(Article apiArticle) {
        // - Generating a unique record name via auto number name field
        Article__c article = new Article__c();
        // - Setting article fields from the API response
        article.url__c = apiArticle.url;
        article.Title__c = apiArticle.title;
        article.Source__c = apiArticle.source == null ? null : apiArticle.source.name;
        article.Description__c = apiArticle.description;
        article.Author__c = apiArticle.author;
        // - Handling content length limits if needed
        article.Content__c = apiArticle.content == null ? null : apiArticle.content.substring(0, LONG_TEXT_LENGTH);
        // - Handling date conversion
        String datetimeString = apiArticle.publishedAt == null ? null : apiArticle.publishedAt.replace('T', ' ').replace('Z', '');
        article.Published_At__c = Datetime.valueOfGmt(datetimeString); // datetimeString is UTC input
        
        return article;
    }
}