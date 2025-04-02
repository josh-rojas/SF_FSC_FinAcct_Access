/**
 * @description Trigger for FinServ__FinancialAccount__c to handle access control
 * @author Your Name
 * @date Current Date
 */
trigger FinancialAccountTrigger on FinServ__FinancialAccount__c (after insert, after update, after delete) {
    // After insert: Create sharing rules for new financial accounts
    if (Trigger.isAfter && Trigger.isInsert) {
        List<Id> accountIds = new List<Id>();
        for (FinServ__FinancialAccount__c acc : Trigger.new) {
            accountIds.add(acc.Id);
        }
        
        // Call sharing service to process sharing updates
        if (!accountIds.isEmpty()) {
            FinancialAccountSharingService.processSharingUpdates(accountIds);
        }
    }
    
    // After update: Update sharing rules for changed financial accounts
    if (Trigger.isAfter && Trigger.isUpdate) {
        List<Id> accountIds = new List<Id>();
        for (FinServ__FinancialAccount__c acc : Trigger.new) {
            FinServ__FinancialAccount__c oldAcc = Trigger.oldMap.get(acc.Id);
            
            // Only process accounts where primary owner has changed
            if (acc.FinServ__PrimaryOwner__c != oldAcc.FinServ__PrimaryOwner__c) {
                accountIds.add(acc.Id);
            }
        }
        
        // Call sharing service to process sharing updates
        if (!accountIds.isEmpty()) {
            FinancialAccountSharingService.processSharingUpdates(accountIds);
        }
    }
    
    // After delete: Clean up sharing for deleted financial accounts
    if (Trigger.isAfter && Trigger.isDelete) {
        for (FinServ__FinancialAccount__c acc : Trigger.old) {
            // Delete any remaining sharing records
            FinancialAccountSharingService.deleteSharing(acc.Id);
        }
    }
}
