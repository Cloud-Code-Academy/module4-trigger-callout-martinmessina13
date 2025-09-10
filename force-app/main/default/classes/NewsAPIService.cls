/**
 * Service class to interact with the NewsAPI for fetching top headlines
 */
public with sharing class NewsAPIService {
    private static final String API_NAMED_CREDENTIAL = 'callout:NewsAPI'; //https://newsapi.org/v2
    private static final String API_HEADLINES_ENDPOINT = '/top-headlines';
    private static final String API_SEARCH_ENDPOINT = '/everything';
    
    public static final Integer PAGE_SIZE = 20; 
    public static final Set<String> NEWS_CATEGORIES = new Set<String>{'business', 'entertainment', 'general', 'health', 'science', 'sports', 'technology'};
    
    /**
     * Fetches top headlines for a specified category with pagination support
     * @param category The news category (business, entertainment, general, health, science, sports, technology)
     * @param page Page number for pagination
     * @param search Keywords or phrase to search for
     * @param sources News sources or identifiers you want news from, NOTE: If provided category is ignored
     * @return NewsAPIResponse The wrapper object containing the API response
     */
    public static NewsAPIResponse getTopHeadlinesByCategory(String category, Integer page, String search, String sources) {
        try{
            // - Validate parameters
            if(!NEWS_CATEGORIES.contains(category.toLowerCase())){
                throw new NewsAPIException('Invalid news category');
            }
            if(page < 1){
                page = 1;
            }
            // - Build the request URL with fixed page size
            Map<String, Object> paramsMap = new Map<String, Object>{
                'pageSize' => PAGE_SIZE,
                'category' => category,
                'sources' => sources,
                'q' => search,
                'page' => page
            };

            if(paramsMap.get('sources') != null){
                // If source parameter is provided, the category is ignored
                paramsMap.remove('category');
            }
            else{
                paramsMap.remove('sources');
            }

            if(paramsMap.get('q') == null){
                // If search parameter is not provided, remove it from parameter map
                paramsMap.remove('q');
            }

            List<String> paramsList = new List<String>();

            for(String key:paramsMap.keySet()){
                String paramsComb = key == null ? '' : key + '=' + paramsMap.get(key);
                paramsList.add(paramsComb);
            }

            String params = '?' + String.join(paramsList,'&');
            // - Generate the endpoint including its parameters
            String endpoint = API_NAMED_CREDENTIAL + API_HEADLINES_ENDPOINT + params;

            // - Make the callout
            HttpResponse response = makeCallout(endpoint);

            if(response.getStatusCode() == 200){
                // - Parse and return the response
                CustomLogger.insertLog('Successful callout to endpoint: ' + endpoint, 'INFO');
                NewsAPIResponse apiResponse = parseResponse(response.getBody());
                return apiResponse;
            }
            throw new NewsAPIException(response.getStatus());
        }
        catch(Exception e){
            // - Handle exceptions
            CustomLogger.insertLog(e, 'ERROR');
            throw e;
        }
        
    }
    
    /**
     * Helper method to make the HTTP callout
     * @param endpoint The full URL with parameters
     * @return HttpResponse The HTTP response
     */
    private static HttpResponse makeCallout(String endpoint) {
        // - Create and configure HTTP request
        HttpRequest request = new HttpRequest();
        request.setEndpoint(endpoint);
        request.setMethod('GET');
        // - Make the callout
        Http http = new Http();
        HttpResponse response = http.send(request);
        return response;
    }
    
    /**
     * Helper method to parse the JSON response
     * @param jsonResponse The JSON response string
     * @return NewsAPIResponse The parsed response object
     */
    private static NewsAPIResponse parseResponse(String jsonResponse) {
        // TODO: Implement JSON parsing
        // - Deserialize JSON to NewsAPIResponse
        try{
            return (NewsAPIResponse)JSON.deserialize(jsonResponse, NewsAPIResponse.class);
        }
        catch(Exception e){
            // - Handle exceptions
            CustomLogger.insertLog(e, 'Error');
            throw e;
        }
    }
    
    /**
     * Custom exception class for NewsAPI errors
     */
    public class NewsAPIException extends Exception {}
}