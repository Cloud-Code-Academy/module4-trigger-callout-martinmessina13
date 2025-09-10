@IsTest
private class NewsAPIServiceTest {

    @testSetup 
    static void setup(){
        TestDataFactory.createUserWithPermissionSets(new List<String>{'Custom_Log_Read_Create'}); 
    }
    
    @IsTest
    static void testGetTopHeadlinesByCategorySuccess() {
        // Set up the mock
        Test.setMock(HttpCalloutMock.class, NewsAPIMock.createSuccessMock());
        
        User u = [SELECT Id FROM User WHERE Alias = 'testusr'];
        System.runAs(u){
            Test.startTest();
            // Test with valid parameters
            NewsAPIResponse response = NewsAPIService.getTopHeadlinesByCategory('technology', 1, null, null);
            Test.stopTest();

            // Verify the response
            Assert.areEqual('ok', response.status, 'Response status should be ok');
            Assert.areEqual(2, response.totalResults, 'Should have 2 articles');
            Assert.areEqual(2, response.articles.size(), 'Should have 2 articles');
        }
        
    }
    
    @IsTest
    static void testGetTopHeadlinesByCategoryWithInvalidParameters() {
        // Set up the mock
        Test.setMock(HttpCalloutMock.class, NewsAPIMock.createSuccessMock());
        
        User u = [SELECT Id FROM User WHERE Alias = 'testusr'];
        System.runAs(u){
            Test.startTest();
            
            // Test with invalid page (should use default of 1)
            NewsAPIResponse response = NewsAPIService.getTopHeadlinesByCategory('technology', 0, null, null);
            Test.stopTest();
            
            // Verify the response
            Assert.areEqual('ok', response.status, 'Response status should be ok');
            Assert.areEqual(2, response.totalResults, 'Should have 2 articles');
        }
    }
} 