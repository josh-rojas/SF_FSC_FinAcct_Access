/**
 * @description Service class to handle employee account flagging
 * This class provides methods to check and manage employee account flags
 * @author Your Name
 * @date Current Date
 */
public with sharing class EmployeeAccountFlagService {
    
    /**
     * @description Checks if a financial account is flagged as an employee account
     * @param accountId The ID of the financial account to check
     * @return Boolean indicating whether the account is an employee account
     */
    public static Boolean isEmployeeAccount(Id accountId) {
        try {
            FinServ__FinancialAccount__c account = [
                SELECT Id, FinServ__PrimaryOwner__c, FinServ__PrimaryOwner__r.Is_Employee_Account__c
                FROM FinServ__FinancialAccount__c
                WHERE Id = :accountId
                WITH SECURITY_ENFORCED
                LIMIT 1
            ];
            
            return account.FinServ__PrimaryOwner__r.Is_Employee_Account__c;
        } catch (Exception e) {
            System.debug('Error checking employee account flag: ' + e.getMessage());
            return false;
        }
    }
    
    /**
     * @description Gets all financial accounts that are flagged as employee accounts
     * @return List of financial accounts that are employee accounts
     */
    public static List<FinServ__FinancialAccount__c> getEmployeeAccounts() {
        return [
            SELECT Id, Name, FinServ__PrimaryOwner__c, FinServ__PrimaryOwner__r.Name,
                   FinServ__Balance__c, FinServ__FinancialAccountType__c, FinServ__Status__c
            FROM FinServ__FinancialAccount__c
            WHERE FinServ__PrimaryOwner__r.Is_Employee_Account__c = true
            WITH SECURITY_ENFORCED
            ORDER BY Name
        ];
    }
    
    /**
     * @description Gets all financial accounts that are NOT flagged as employee accounts
     * @return List of financial accounts that are not employee accounts
     */
    public static List<FinServ__FinancialAccount__c> getNonEmployeeAccounts() {
        return [
            SELECT Id, Name, FinServ__PrimaryOwner__c, FinServ__PrimaryOwner__r.Name,
                   FinServ__Balance__c, FinServ__FinancialAccountType__c, FinServ__Status__c
            FROM FinServ__FinancialAccount__c
            WHERE FinServ__PrimaryOwner__r.Is_Employee_Account__c = false
            WITH SECURITY_ENFORCED
            ORDER BY Name
        ];
    }
    
    /**
     * @description Set the employee account flag for a list of user IDs
     * @param userIds List of user IDs to update
     * @param isEmployee Boolean value to set for the employee flag
     * @return List of users that were updated
     */
    @AuraEnabled(cacheable=false)
    public static List<User> setEmployeeFlag(List<Id> userIds, Boolean isEmployee) {
        if (userIds == null || userIds.isEmpty()) {
            return new List<User>();
        }
        
        // Check if current user has permission to modify user records
        if (!Schema.sObjectType.User.isUpdateable()) {
            throw new SecurityException('Insufficient permissions to update User records');
        }
        
        List<User> usersToUpdate = [
            SELECT Id, Is_Employee_Account__c
            FROM User
            WHERE Id IN :userIds
            WITH SECURITY_ENFORCED
        ];
        
        for (User u : usersToUpdate) {
            u.Is_Employee_Account__c = isEmployee;
        }
        
        try {
            update usersToUpdate;
            return usersToUpdate;
        } catch (Exception e) {
            System.debug('Error updating employee flags: ' + e.getMessage());
            throw new AuraHandledException('Failed to update employee flags: ' + e.getMessage());
        }
    }
    
    /**
     * @description Get a list of all users with their employee account flag status
     * @return List of users with their employee flag status
     */
    @AuraEnabled(cacheable=true)
    public static List<UserWrapper> getUsersWithEmployeeFlag() {
        List<UserWrapper> result = new List<UserWrapper>();
        
        for (User u : [
            SELECT Id, Name, Username, Is_Employee_Account__c, Profile.Name, UserRole.Name
            FROM User
            WHERE IsActive = true
            AND Profile.UserLicense.LicenseDefinitionKey != 'GUEST'
            WITH SECURITY_ENFORCED
            ORDER BY Name
        ]) {
            result.add(new UserWrapper(u));
        }
        
        return result;
    }
    
    /**
     * @description Wrapper class for User records with additional information
     */
    public class UserWrapper {
        @AuraEnabled public Id id;
        @AuraEnabled public String name;
        @AuraEnabled public String username;
        @AuraEnabled public Boolean isEmployee;
        @AuraEnabled public String profileName;
        @AuraEnabled public String roleName;
        
        public UserWrapper(User u) {
            this.id = u.Id;
            this.name = u.Name;
            this.username = u.Username;
            this.isEmployee = u.Is_Employee_Account__c;
            this.profileName = u.Profile?.Name;
            this.roleName = u.UserRole?.Name;
        }
    }
}
