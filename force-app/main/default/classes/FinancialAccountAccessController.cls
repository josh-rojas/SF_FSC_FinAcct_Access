/**
 * @description Controller class for managing Financial Account access permissions
 * This class enforces the three-tiered permission structure for Financial Service Cloud
 * @author Your Name
 * @date Current Date
 */
public with sharing class FinancialAccountAccessController {
    
    /**
     * @description Check if the current user has access to the specified financial account
     * @param accountId The ID of the financial account to check access for
     * @return Boolean indicating whether the user has access
     */
    @AuraEnabled(cacheable=true)
    public static Boolean hasAccessToFinancialAccount(Id accountId) {
        try {
            // Get the current user's permission level
            String permissionLevel = PermissionUtility.getCurrentUserPermissionLevel();
            
            // Admin level has complete access to all accounts
            if (permissionLevel == 'Admin_Level') {
                return true;
            }
            
            // Base level has no access to employee financial accounts
            if (permissionLevel == 'Base_Level') {
                // Check if account is flagged as employee account
                Boolean isEmployeeAccount = EmployeeAccountFlagService.isEmployeeAccount(accountId);
                return !isEmployeeAccount;
            }
            
            // Mid level has selective access based on relationships
            if (permissionLevel == 'Mid_Level') {
                // Check for employee account
                Boolean isEmployeeAccount = EmployeeAccountFlagService.isEmployeeAccount(accountId);
                
                // If not an employee account, they have access
                if (!isEmployeeAccount) {
                    return true;
                }
                
                // Check for management relationship or role hierarchy
                Boolean hasManagementAccess = checkManagementAccess(accountId);
                
                // Check for explicit override access
                Boolean hasOverrideAccess = AccessOverrideService.hasOverrideAccess(UserInfo.getUserId(), accountId);
                
                return hasManagementAccess || hasOverrideAccess;
            }
            
            return false;
        } catch (Exception e) {
            System.debug('Error checking financial account access: ' + e.getMessage());
            LoggingService.logError('FinancialAccountAccessController.hasAccessToFinancialAccount', e.getMessage(), e.getStackTraceString());
            return false;
        }
    }
    
    /**
     * @description Get all financial accounts that the current user has access to
     * @return List of financial accounts the user can access
     */
    @AuraEnabled(cacheable=true)
    public static List<FinServ__FinancialAccount__c> getAccessibleFinancialAccounts() {
        try {
            String permissionLevel = PermissionUtility.getCurrentUserPermissionLevel();
            
            // Admin level users get all accounts
            if (permissionLevel == 'Admin_Level') {
                return [SELECT Id, Name, FinServ__PrimaryOwner__c, FinServ__Balance__c, 
                        FinServ__FinancialAccountType__c, FinServ__Status__c
                        FROM FinServ__FinancialAccount__c 
                        WITH SECURITY_ENFORCED
                        ORDER BY Name];
            }
            
            // Base level users get non-employee accounts
            if (permissionLevel == 'Base_Level') {
                return [SELECT Id, Name, FinServ__PrimaryOwner__c, FinServ__Balance__c, 
                        FinServ__FinancialAccountType__c, FinServ__Status__c
                        FROM FinServ__FinancialAccount__c 
                        WHERE FinServ__PrimaryOwner__r.Is_Employee_Account__c = false
                        WITH SECURITY_ENFORCED
                        ORDER BY Name];
            }
            
            // Mid level users get non-employee accounts plus ones they have access to
            if (permissionLevel == 'Mid_Level') {
                Set<Id> accessibleIds = new Set<Id>();
                
                // Get all accounts user has override access to
                List<FinancialAccountAccess__c> overrides = [
                    SELECT FinancialAccount__c 
                    FROM FinancialAccountAccess__c 
                    WHERE User__c = :UserInfo.getUserId()
                    WITH SECURITY_ENFORCED
                ];
                
                for (FinancialAccountAccess__c access : overrides) {
                    accessibleIds.add(access.FinancialAccount__c);
                }
                
                // Get management hierarchy accounts
                accessibleIds.addAll(getManagedEmployeeAccountIds());
                
                return [SELECT Id, Name, FinServ__PrimaryOwner__c, FinServ__Balance__c, 
                        FinServ__FinancialAccountType__c, FinServ__Status__c
                        FROM FinServ__FinancialAccount__c 
                        WHERE FinServ__PrimaryOwner__r.Is_Employee_Account__c = false
                        OR Id IN :accessibleIds
                        WITH SECURITY_ENFORCED
                        ORDER BY Name];
            }
            
            return new List<FinServ__FinancialAccount__c>();
        } catch (Exception e) {
            System.debug('Error retrieving accessible financial accounts: ' + e.getMessage());
            LoggingService.logError('FinancialAccountAccessController.getAccessibleFinancialAccounts', e.getMessage(), e.getStackTraceString());
            throw new AuraHandledException('Error retrieving accessible financial accounts: ' + e.getMessage());
        }
    }
    
    /**
     * @description Check if a user has management access to a financial account
     * based on management relationship or role hierarchy
     * @param accountId The ID of the financial account to check access for
     * @return Boolean indicating whether the user has management access
     */
    private static Boolean checkManagementAccess(Id accountId) {
        try {
            // Get the account owner from the financial account
            FinServ__FinancialAccount__c account = [
                SELECT FinServ__PrimaryOwner__c 
                FROM FinServ__FinancialAccount__c 
                WHERE Id = :accountId
                WITH SECURITY_ENFORCED
                LIMIT 1
            ];
            
            // Get the owner's user ID
            User owner = [
                SELECT Id, ManagerId 
                FROM User 
                WHERE Id = :account.FinServ__PrimaryOwner__c
                WITH SECURITY_ENFORCED
                LIMIT 1
            ];
            
            // Check if current user is the manager of the owner
            if (owner.ManagerId == UserInfo.getUserId()) {
                return true;
            }
            
            // Check role hierarchy
            Id currentUserRoleId = UserInfo.getUserRoleId();
            if (currentUserRoleId != null) {
                // Get user role of owner
                User ownerWithRole = [
                    SELECT UserRoleId 
                    FROM User 
                    WHERE Id = :owner.Id
                    WITH SECURITY_ENFORCED
                    LIMIT 1
                ];
                
                if (ownerWithRole.UserRoleId != null) {
                    // Check if current user's role is above owner's role in hierarchy
                    return isRoleAbove(currentUserRoleId, ownerWithRole.UserRoleId);
                }
            }
            
            return false;
        } catch (Exception e) {
            System.debug('Error checking management access: ' + e.getMessage());
            LoggingService.logError('FinancialAccountAccessController.checkManagementAccess', e.getMessage(), e.getStackTraceString());
            return false;
        }
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
     * @description Get all financial account IDs for employee accounts that the current user manages
     * @return Set of financial account IDs that the user has management access to
     */
    private static Set<Id> getManagedEmployeeAccountIds() {
        Set<Id> managedAccountIds = new Set<Id>();
        
        // Get all users that the current user manages
        List<Id> managedUserIds = new List<Id>();
        Id currentUserId = UserInfo.getUserId();
        
        // Direct reports
        for(User u : [SELECT Id FROM User WHERE ManagerId = :currentUserId WITH SECURITY_ENFORCED]) {
            managedUserIds.add(u.Id);
        }
        
        // Users in subordinate roles
        Id currentUserRoleId = UserInfo.getUserRoleId();
        if (currentUserRoleId != null) {
            List<Id> subordinateRoleIds = getSubordinateRoleIds(currentUserRoleId);
            
            for(User u : [SELECT Id FROM User WHERE UserRoleId IN :subordinateRoleIds WITH SECURITY_ENFORCED]) {
                managedUserIds.add(u.Id);
            }
        }
        
        // Get financial accounts owned by these managed users
        if (!managedUserIds.isEmpty()) {
            for(FinServ__FinancialAccount__c account : [
                SELECT Id 
                FROM FinServ__FinancialAccount__c 
                WHERE FinServ__PrimaryOwner__c IN :managedUserIds
                AND FinServ__PrimaryOwner__r.Is_Employee_Account__c = true
                WITH SECURITY_ENFORCED
            ]) {
                managedAccountIds.add(account.Id);
            }
        }
        
        return managedAccountIds;
    }
    
    /**
     * @description Get all role IDs that are subordinate to the specified role
     * @param roleId The ID of the role to find subordinates for
     * @return List of role IDs that are below the specified role in the hierarchy
     */
    private static List<Id> getSubordinateRoleIds(Id roleId) {
        List<Id> subordinateRoleIds = new List<Id>();
        
        // Build role hierarchy
        Map<Id, List<Id>> roleHierarchy = new Map<Id, List<Id>>();
        for (UserRole role : [SELECT Id, ParentRoleId FROM UserRole WITH SECURITY_ENFORCED]) {
            if (!roleHierarchy.containsKey(role.ParentRoleId)) {
                roleHierarchy.put(role.ParentRoleId, new List<Id>());
            }
            roleHierarchy.get(role.ParentRoleId).add(role.Id);
        }
        
        // Traverse down the hierarchy
        addSubordinateRoles(roleId, roleHierarchy, subordinateRoleIds);
        
        return subordinateRoleIds;
    }
    
    /**
     * @description Recursively add all subordinate roles to the list
     * @param roleId The current role ID to find subordinates for
     * @param roleHierarchy Map of parent role ID to list of child role IDs
     * @param subordinateRoleIds List to accumulate subordinate role IDs
     */
    private static void addSubordinateRoles(Id roleId, Map<Id, List<Id>> roleHierarchy, List<Id> subordinateRoleIds) {
        if (roleHierarchy.containsKey(roleId)) {
            for (Id childRoleId : roleHierarchy.get(roleId)) {
                subordinateRoleIds.add(childRoleId);
                addSubordinateRoles(childRoleId, roleHierarchy, subordinateRoleIds);
            }
        }
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
