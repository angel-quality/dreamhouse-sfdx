trigger issueLinkToUserStory on QCloudsSaaS__QCIssue__c (before insert) {
    QCloudsSaaS__QCIssue__c issue = Trigger.new[0];
    String idUserStory = null;
    QCloudsSaaS__Scann__c scan = [SELECT Id, QCloudsSaaS__Branch_Name__c, QCloudsSaaS__Date__c, QCloudsSaaS__Scan_Type__c, QCloudsSaaS__Instance__c  FROM QCloudsSaaS__Scann__c WHERE Id = :issue.QCloudsSaaS__Scan__c ORDER BY CreatedDate DESC ];
    if ([SELECT Count() FROM QCloudsSaaS__Scann__c WHERE QCloudsSaaS__Instance__c = :scan.QCloudsSaaS__Instance__c AND QCloudsSaaS__Branch_Name__c = :scan.QCloudsSaaS__Branch_Name__c AND QCloudsSaaS__Date__c > :scan.QCloudsSaaS__Date__c ] == 0 && scan.QCloudsSaaS__Scan_Type__c == 'feature-branch-scan' ){
        //copado__Git_Repository__c Git = [SELECT copado__URI__c FROM copado__Git_Repository__c WHERE Id = :repoID]
        
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
            List<QCloudsSaaS__QCIssue__c> isuelist = [SELECT Id, User_Story__c FROM QCloudsSaaS__QCIssue__c WHERE User_Story__c = :idUserStory AND QCloudsSaaS__Scan__c != :issue.QCloudsSaaS__Scan__c ];
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

    for (QCloudsSaaS__QCIssue__c issue2 : Trigger.new) {
        issue2.User_Story__c = idUserStory;
    }

}