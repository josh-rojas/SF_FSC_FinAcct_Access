/**
 * @description Service class to handle sharing rules for financial accounts
 * This class creates, updates, and deletes sharing records based on permission sets and employee flags
 * @author Your Name
 * @date Current Date
 */
public with sharing class FinancialAccountSharingService {
    
    /**
     * @description Create sharing rules for a financial account
     * @param accountId The ID of the financial account to create sharing for
     */
    public static void createSharing(Id accountId) {
        try {
            // Get the financial account
            FinServ__FinancialAccount__c account = [
                SELECT Id, FinServ__PrimaryOwner__c, FinServ__PrimaryOwner__r.Is_Employee_Account__c
                FROM FinServ__FinancialAccount__c
                WHERE Id = :accountId
                WITH SECURITY_ENFORCED
                LIMIT 1
            ];
            
            // Only need special sharing for employee accounts
            if (!account.FinServ__PrimaryOwner__r.Is_Employee_Account__c) {
                return;
            }
            
            // Get users with admin access
            List<User> adminUsers = getUsersWithPermissionSet('FinancialAccount_Admin_Access');
            
            // Get mid-level users who should have access (managers of the owner, or role hierarchy superiors)
            List<User> midLevelUsers = getMidLevelUsersWithAccess(account);
            
            // Create sharing records
            List<FinServ__FinancialAccountShare> sharingRecords = new List<FinServ__FinancialAccountShare>();
            
            // Share with admin users
            for (User adminUser : adminUsers) {
                // Skip if user is the owner
                if (adminUser.Id == account.FinServ__PrimaryOwner__c) {
                    continue;
                }
                
                FinServ__FinancialAccountShare share = new FinServ__FinancialAccountShare(
                    ParentId = accountId,
                    UserOrGroupId = adminUser.Id,
                    AccessLevel = 'Edit',
                    RowCause = Schema.FinServ__FinancialAccountShare.RowCause.Manual
                );
                sharingRecords.add(share);
            }
            
            // Share with mid-level users who have access through management or role hierarchy
            for (User midUser : midLevelUsers) {
                // Skip if user is the owner
                if (midUser.Id == account.FinServ__PrimaryOwner__c) {
                    continue;
                }
                
                FinServ__FinancialAccountShare share = new FinServ__FinancialAccountShare(
                    ParentId = accountId,
                    UserOrGroupId = midUser.Id,
                    AccessLevel = 'Read',
                    RowCause = Schema.FinServ__FinancialAccountShare.RowCause.Manual
                );
                sharingRecords.add(share);
            }
            
            // Insert sharing records if there are any
            if (!sharingRecords.isEmpty()) {
                Database.SaveResult[] results = Database.insert(sharingRecords, false);
                
                // Log any errors
                for (Integer i = 0; i < results.size(); i++) {
                    if (!results[i].isSuccess()) {
                        System.debug('Error creating sharing record: ' + results[i].getErrors()[0].getMessage());
                    }
                }
            }
            
        } catch (Exception e) {
            System.debug('Error creating sharing: ' + e.getMessage());
            LoggingService.logError('FinancialAccountSharingService.createSharing', e.getMessage(), e.getStackTraceString());
        }
    }
    
    /**
     * @description Update sharing rules for a financial account
     * @param accountId The ID of the financial account to update sharing for
     */
    public static void updateSharing(Id accountId) {
        try {
            // Delete existing sharing
            deleteSharing(accountId);
            
            // Create new sharing
            createSharing(accountId);
            
        } catch (Exception e) {
            System.debug('Error updating sharing: ' + e.getMessage());
            LoggingService.logError('FinancialAccountSharingService.updateSharing', e.getMessage(), e.getStackTraceString());
        }
    }
    
    /**
     * @description Delete sharing rules for a financial account
     * @param accountId The ID of the financial account to delete sharing for
     */
    public static void deleteSharing(Id accountId) {
        try {
            // Get existing manual sharing records
            List<FinServ__FinancialAccountShare> existingShares = [
                SELECT Id 
                FROM FinServ__FinancialAccountShare 
                WHERE ParentId = :accountId
                AND RowCause = :Schema.FinServ__FinancialAccountShare.RowCause.Manual
                WITH SECURITY_ENFORCED
            ];
            
            if (!existingShares.isEmpty()) {
                delete existingShares;
            }
            
        } catch (Exception e) {
            System.debug('Error deleting sharing: ' + e.getMessage());
            LoggingService.logError('FinancialAccountSharingService.deleteSharing', e.getMessage(), e.getStackTraceString());
        }
    }
    
    /**
     * @description Process sharing updates for a list of financial accounts
     * @param accountIds List of financial account IDs to update sharing for
     */
    public static void processSharingUpdates(List<Id> accountIds) {
        if (accountIds == null || accountIds.isEmpty()) {
            return;
        }
        
        for (Id accountId : accountIds) {
            updateSharing(accountId);
        }
    }
    
    /**
     * @description Get users with a specific permission set
     * @param permissionSetName The API name of the permission set
     * @return List of users who have the permission set assigned
     */
    private static List<User> getUsersWithPermissionSet(String permissionSetName) {
        List<User> users = new List<User>();
        
        // Get the permission set ID
        PermissionSet ps = [
            SELECT Id FROM PermissionSet 
            WHERE Name = :permissionSetName
            WITH SECURITY_ENFORCED
            LIMIT 1
        ];
        
        // Get users assigned to this permission set
        for (PermissionSetAssignment psa : [
            SELECT AssigneeId 
            FROM PermissionSetAssignment 
            WHERE PermissionSetId = :ps.Id
            WITH SECURITY_ENFORCED
        ]) {
            users.add(new User(Id = psa.AssigneeId));
        }
        
        return users;
    }
    
    /**
     * @description Get mid-level users who should have access to an account based on management relationship or role hierarchy
     * @param account The financial account to get access for
     * @return List of users who should have access
     */
    private static List<User> getMidLevelUsersWithAccess(FinServ__FinancialAccount__c account) {
        Set<Id> userIdsWithAccess = new Set<Id>();
        
        // Get mid-level permission set ID
        PermissionSet midPS = [
            SELECT Id FROM PermissionSet 
            WHERE Name = 'FinancialAccount_Mid_Access'
            WITH SECURITY_ENFORCED
            LIMIT 1
        ];
        
        // Get all mid-level users
        List<User> midLevelUsers = new List<User>();
        for (PermissionSetAssignment psa : [
            SELECT AssigneeId, Assignee.ManagerId, Assignee.UserRoleId
            FROM PermissionSetAssignment 
            WHERE PermissionSetId = :midPS.Id
            WITH SECURITY_ENFORCED
        ]) {
            midLevelUsers.add(new User(
                Id = psa.AssigneeId,
                ManagerId = psa.Assignee.ManagerId,
                UserRoleId = psa.Assignee.UserRoleId
            ));
        }
        
        // Get the account owner
        User owner = [
            SELECT Id, ManagerId, UserRoleId
            FROM User
            WHERE Id = :account.FinServ__PrimaryOwner__c
            WITH SECURITY_ENFORCED
            LIMIT 1
        ];
        
        // Check for management relationship
        for (User midUser : midLevelUsers) {
            // If user is the manager of the owner, they get access
            if (midUser.Id == owner.ManagerId) {
                userIdsWithAccess.add(midUser.Id);
                continue;
            }
            
            // Check role hierarchy if both have roles
            if (midUser.UserRoleId != null && owner.UserRoleId != null) {
                if (isRoleAbove(midUser.UserRoleId, owner.UserRoleId)) {
                    userIdsWithAccess.add(midUser.Id);
                }
            }
        }
        
        // Get access overrides for this account
        List<FinancialAccountAccess__c> overrides = [
            SELECT User__c
            FROM FinancialAccountAccess__c
            WHERE FinancialAccount__c = :account.Id
            AND AccessType__c = 'Override'
            WITH SECURITY_ENFORCED
        ];
        
        for (FinancialAccountAccess__c override : overrides) {
            userIdsWithAccess.add(override.User__c);
        }
        
        // Convert set back to list of User objects
        List<User> result = new List<User>();
        for (Id userId : userIdsWithAccess) {
            result.add(new User(Id = userId));
        }
        
        return result;
    }
    
    /**
     * @description Check if one role is above another in the role hierarchy
     * @param higherRoleId The ID of the potentially higher role
     * @param lowerRoleId The ID of the potentially lower role
     * @return Boolean indicating whether higherRoleId is above lowerRoleId in the hierarchy
     */
    private static Boolean isRoleAbove(Id higherRoleId, Id lowerRoleId) {
        if (higherRoleId == lowerRoleId) {
            return false;
        }
        
        Map<Id, Id> roleToParentMap = new Map<Id, Id>();
        for (UserRole role : [SELECT Id, ParentRoleId FROM UserRole WITH SECURITY_ENFORCED]) {
            roleToParentMap.put(role.Id, role.ParentRoleId);
        }
        
        // Traverse up the hierarchy from the lower role
        Id currentRoleId = lowerRoleId;
        while (currentRoleId != null) {
            // If we find the higher role ID as we go up, return true
            if (roleToParentMap.get(currentRoleId) == higherRoleId) {
                return true;
            }
            currentRoleId = roleToParentMap.get(currentRoleId);
        }
        
        return false;
    }
    
    /**
     * @description Logging service to record errors
     * This is a placeholder for a more complete logging service implementation
     */
    private class LoggingService {
        public static void logError(String className, String message, String stackTrace) {
            System.debug('Error in ' + className + ': ' + message + '\n' + stackTrace);
            // In a full implementation, this would write to a custom object or external system
        }
    }
}
