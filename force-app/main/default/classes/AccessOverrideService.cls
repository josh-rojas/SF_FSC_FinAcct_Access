/**
 * @description Service class to manage access overrides for financial accounts
 * This class allows mid-level users to selectively grant access to employee accounts
 * @author Your Name
 * @date Current Date
 */
public with sharing class AccessOverrideService {
    
    /**
     * @description Check if a user has override access to a financial account
     * @param userId The ID of the user to check access for
     * @param accountId The ID of the financial account to check access for
     * @return Boolean indicating whether the user has override access
     */
    public static Boolean hasOverrideAccess(Id userId, Id accountId) {
        try {
            Integer count = [
                SELECT COUNT() 
                FROM FinancialAccountAccess__c 
                WHERE User__c = :userId 
                AND FinancialAccount__c = :accountId
                AND AccessType__c = 'Override'
                WITH SECURITY_ENFORCED
            ];
            
            return count > 0;
        } catch (Exception e) {
            System.debug('Error checking override access: ' + e.getMessage());
            return false;
        }
    }
    
    /**
     * @description Grant override access to a financial account for a user
     * @param userId The ID of the user to grant access to
     * @param accountId The ID of the financial account to grant access for
     * @return The created FinancialAccountAccess__c record
     */
    @AuraEnabled
    public static FinancialAccountAccess__c grantOverrideAccess(Id userId, Id accountId) {
        // Check if user has permission to create overrides
        String permissionLevel = PermissionUtility.getCurrentUserPermissionLevel();
        if (permissionLevel != 'Admin_Level' && permissionLevel != 'Mid_Level') {
            throw new AuraHandledException('You do not have permission to grant override access');
        }
        
        // Check if the account is an employee account (only employee accounts need override)
        Boolean isEmployeeAccount = EmployeeAccountFlagService.isEmployeeAccount(accountId);
        if (!isEmployeeAccount) {
            throw new AuraHandledException('Override access can only be granted for employee accounts');
        }
        
        // Check if an override already exists
        List<FinancialAccountAccess__c> existingOverrides = [
            SELECT Id 
            FROM FinancialAccountAccess__c 
            WHERE User__c = :userId 
            AND FinancialAccount__c = :accountId
            AND AccessType__c = 'Override'
            WITH SECURITY_ENFORCED
        ];
        
        if (!existingOverrides.isEmpty()) {
            return existingOverrides[0];
        }
        
        // Create a new override
        FinancialAccountAccess__c newAccess = new FinancialAccountAccess__c(
            User__c = userId,
            FinancialAccount__c = accountId,
            AccessType__c = 'Override'
        );
        
        try {
            insert newAccess;
            
            // Update sharing rules for the account
            FinancialAccountSharingService.updateSharing(accountId);
            
            return newAccess;
        } catch (Exception e) {
            System.debug('Error creating override access: ' + e.getMessage());
            throw new AuraHandledException('Failed to create override access: ' + e.getMessage());
        }
    }
    
    /**
     * @description Revoke override access to a financial account for a user
     * @param userId The ID of the user to revoke access from
     * @param accountId The ID of the financial account to revoke access for
     * @return Boolean indicating success
     */
    @AuraEnabled
    public static Boolean revokeOverrideAccess(Id userId, Id accountId) {
        // Check if user has permission to revoke overrides
        String permissionLevel = PermissionUtility.getCurrentUserPermissionLevel();
        if (permissionLevel != 'Admin_Level' && permissionLevel != 'Mid_Level') {
            throw new AuraHandledException('You do not have permission to revoke override access');
        }
        
        // Find and delete the override
        List<FinancialAccountAccess__c> overridesToDelete = [
            SELECT Id 
            FROM FinancialAccountAccess__c 
            WHERE User__c = :userId 
            AND FinancialAccount__c = :accountId
            AND AccessType__c = 'Override'
            WITH SECURITY_ENFORCED
        ];
        
        if (overridesToDelete.isEmpty()) {
            return false;
        }
        
        try {
            delete overridesToDelete;
            
            // Update sharing rules for the account
            FinancialAccountSharingService.updateSharing(accountId);
            
            return true;
        } catch (Exception e) {
            System.debug('Error revoking override access: ' + e.getMessage());
            throw new AuraHandledException('Failed to revoke override access: ' + e.getMessage());
        }
    }
    
    /**
     * @description Get all override access records for a financial account
     * @param accountId The ID of the financial account to get overrides for
     * @return List of override access records
     */
    @AuraEnabled(cacheable=true)
    public static List<OverrideAccessWrapper> getAccountOverrides(Id accountId) {
        List<OverrideAccessWrapper> result = new List<OverrideAccessWrapper>();
        
        List<FinancialAccountAccess__c> overrides = [
            SELECT Id, User__c, User__r.Name, FinancialAccount__c, 
                   FinancialAccount__r.Name, CreatedDate
            FROM FinancialAccountAccess__c 
            WHERE FinancialAccount__c = :accountId
            AND AccessType__c = 'Override'
            WITH SECURITY_ENFORCED
            ORDER BY CreatedDate DESC
        ];
        
        for (FinancialAccountAccess__c override : overrides) {
            result.add(new OverrideAccessWrapper(override));
        }
        
        return result;
    }
    
    /**
     * @description Get all override access records for a user
     * @param userId The ID of the user to get overrides for
     * @return List of override access records
     */
    @AuraEnabled(cacheable=true)
    public static List<OverrideAccessWrapper> getUserOverrides(Id userId) {
        List<OverrideAccessWrapper> result = new List<OverrideAccessWrapper>();
        
        List<FinancialAccountAccess__c> overrides = [
            SELECT Id, User__c, User__r.Name, FinancialAccount__c, 
                   FinancialAccount__r.Name, CreatedDate
            FROM FinancialAccountAccess__c 
            WHERE User__c = :userId
            AND AccessType__c = 'Override'
            WITH SECURITY_ENFORCED
            ORDER BY CreatedDate DESC
        ];
        
        for (FinancialAccountAccess__c override : overrides) {
            result.add(new OverrideAccessWrapper(override));
        }
        
        return result;
    }
    
    /**
     * @description Get all users that could be granted override access to a financial account
     * @param accountId The ID of the financial account
     * @return List of users who could be granted access
     */
    @AuraEnabled(cacheable=true)
    public static List<UserWrapper> getEligibleUsersForOverride(Id accountId) {
        // Check if user has permission to grant overrides
        String permissionLevel = PermissionUtility.getCurrentUserPermissionLevel();
        if (permissionLevel != 'Admin_Level' && permissionLevel != 'Mid_Level') {
            throw new AuraHandledException('You do not have permission to view eligible users');
        }
        
        // Get the financial account to check if it's an employee account
        FinServ__FinancialAccount__c account = [
            SELECT Id, FinServ__PrimaryOwner__c, FinServ__PrimaryOwner__r.Is_Employee_Account__c
            FROM FinServ__FinancialAccount__c
            WHERE Id = :accountId
            WITH SECURITY_ENFORCED
            LIMIT 1
        ];
        
        // Only employee accounts need overrides
        if (!account.FinServ__PrimaryOwner__r.Is_Employee_Account__c) {
            return new List<UserWrapper>();
        }
        
        // Get users who already have override access
        Set<Id> usersWithOverride = new Set<Id>();
        for (FinancialAccountAccess__c override : [
            SELECT User__c 
            FROM FinancialAccountAccess__c 
            WHERE FinancialAccount__c = :accountId
            AND AccessType__c = 'Override'
            WITH SECURITY_ENFORCED
        ]) {
            usersWithOverride.add(override.User__c);
        }
        
        // Get users with Mid-Level or Admin-Level permission sets who don't already have overrides
        // and who aren't the owner
        List<UserWrapper> result = new List<UserWrapper>();
        
        // Get Mid-Level permission set ID
        PermissionSet midPS = [
            SELECT Id FROM PermissionSet 
            WHERE Name = 'FinancialAccount_Mid_Access'
            WITH SECURITY_ENFORCED
            LIMIT 1
        ];
        
        // Get Admin permission set ID
        PermissionSet adminPS = [
            SELECT Id FROM PermissionSet 
            WHERE Name = 'FinancialAccount_Admin_Access'
            WITH SECURITY_ENFORCED
            LIMIT 1
        ];
        
        // Get users with mid or admin permission sets
        for (User u : [
            SELECT Id, Name, Username, Profile.Name
            FROM User
            WHERE Id IN (
                SELECT AssigneeId 
                FROM PermissionSetAssignment 
                WHERE PermissionSetId = :midPS.Id OR PermissionSetId = :adminPS.Id
            )
            AND Id != :account.FinServ__PrimaryOwner__c
            AND Id NOT IN :usersWithOverride
            AND IsActive = true
            WITH SECURITY_ENFORCED
            ORDER BY Name
        ]) {
            result.add(new UserWrapper(u));
        }
        
        return result;
    }
    
    /**
     * @description Wrapper class for Override Access records
     */
    public class OverrideAccessWrapper {
        @AuraEnabled public Id id;
        @AuraEnabled public Id userId;
        @AuraEnabled public String userName;
        @AuraEnabled public Id accountId;
        @AuraEnabled public String accountName;
        @AuraEnabled public Datetime createdDate;
        
        public OverrideAccessWrapper(FinancialAccountAccess__c access) {
            this.id = access.Id;
            this.userId = access.User__c;
            this.userName = access.User__r.Name;
            this.accountId = access.FinancialAccount__c;
            this.accountName = access.FinancialAccount__r.Name;
            this.createdDate = access.CreatedDate;
        }
    }
    
    /**
     * @description Wrapper class for User records
     */
    public class UserWrapper {
        @AuraEnabled public Id id;
        @AuraEnabled public String name;
        @AuraEnabled public String username;
        @AuraEnabled public String profileName;
        
        public UserWrapper(User u) {
            this.id = u.Id;
            this.name = u.Name;
            this.username = u.Username;
            this.profileName = u.Profile?.Name;
        }
    }
}
