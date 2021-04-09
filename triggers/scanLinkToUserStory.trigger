trigger scanLinkToUserStory on QCloudsSaaS__Scann__c (before update) {
    for (QCloudsSaaS__Scann__c scan : Trigger.new) {
        if ([SELECT Count() FROM QCloudsSaaS__Scann__c WHERE QCloudsSaaS__Instance__c = :scan.QCloudsSaaS__Instance__c AND QCloudsSaaS__Branch_Name__c = :scan.QCloudsSaaS__Branch_Name__c AND QCloudsSaaS__Date__c > :scan.QCloudsSaaS__Date__c ] == 0 && scan.QCloudsSaaS__Scan_Type__c == 'feature-branch-scan' ){
            //copado__Git_Repository__c Git = [SELECT copado__URI__c FROM copado__Git_Repository__c WHERE Id = :repoID]
            String idUserStory = null;
            String branch = scan.QCloudsSaaS__Branch_Name__c.substringAfter('/');

            for (copado__User_Story__c userStory : [SELECT Id, copado__Project__c FROM copado__User_Story__c WHERE Name = :branch]) {
                String projectId = userStory.copado__Project__c;

                String pipeId = [SELECT copado__Deployment_Flow__c FROM copado__Project__c WHERE Id = :projectId].copado__Deployment_Flow__c;

                String repoID = [SELECT copado__Git_Repository__c FROM copado__Deployment_Flow__c WHERE Id = :pipeId].copado__Git_Repository__c;

                String repoURL = [SELECT copado__URI__c FROM copado__Git_Repository__c WHERE Id = :repoID].copado__URI__c;

                repoURL = '%' + repoURL.replace('https://github.com/','').replace('git@github.com:','');

                String instance_id = [SELECT  Id FROM QCloudsSaaS__Instance__c WHERE QCloudsSaaS__url__c LIKE :repoURL ORDER BY CreatedDate DESC LIMIT 1].Id;
                if (scan.QCloudsSaaS__Instance__c == instance_id){
                    idUserStory = userStory.Id;
                }
            }

            if ( ! String.isBlank(idUserStory)){
                List<QCloudsSaaS__Scann__c> scanlist = [SELECT Id, User_Story__c FROM QCloudsSaaS__Scann__c WHERE User_Story__c = :idUserStory AND Id != :scan.Id];
                for(QCloudsSaaS__Scann__c scanl : scanlist )
                {
                    scanl.User_Story__c = null;
                }
                if(scanlist.size() > 0)
                {
                    update scanlist;
                }
                if (scan.QCloudsSaaS__State__c != 'SUCCESS' || Test.isRunningTest() ){
                
                    List<QCloudsSaaS__QCIssue__c> isuelist = [SELECT Id, User_Story__c FROM QCloudsSaaS__QCIssue__c WHERE User_Story__c = :idUserStory];
                    for(QCloudsSaaS__QCIssue__c isue : isuelist )
                    {
                        isue.User_Story__c = null;
                    }
                    if(isuelist.size() > 0)
                    {
                        update isuelist;
                    }
                
                }
            }
            scan.User_Story__c = idUserStory;

        }
    }

}