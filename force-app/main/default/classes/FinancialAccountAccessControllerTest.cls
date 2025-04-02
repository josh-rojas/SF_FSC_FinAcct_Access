/**
 * @description Test class for FinancialAccountAccessController
 * @author Your Name
 * @date Current Date
 */
@isTest
private class FinancialAccountAccessControllerTest {
    
    private static final String ADMIN_PERMISSION = 'FinancialAccount_Admin_Access';
    private static final String MID_PERMISSION = 'FinancialAccount_Mid_Access';
    private static final String BASE_PERMISSION = 'FinancialAccount_Base_Access';
    
    @TestSetup
    static void setupTestData() {
        // Create test roles for hierarchy testing
        List<UserRole> roles = new List<UserRole>();
        UserRole ceoRole = new UserRole(Name = 'CEO', DeveloperName = 'CEO');
        roles.add(ceoRole);
        insert roles;
        
        // Get the CEO role ID
        ceoRole = [SELECT Id FROM UserRole WHERE DeveloperName = 'CEO' LIMIT 1];
        
        // Create manager role
        UserRole managerRole = new UserRole(
            Name = 'Manager', 
            DeveloperName = 'Manager',
            ParentRoleId = ceoRole.Id
        );
        insert managerRole;
        
        // Create employee role
        UserRole employeeRole = new UserRole(
            Name = 'Employee', 
            DeveloperName = 'Employee',
            ParentRoleId = managerRole.Id
        );
        insert employeeRole;
        
        // Create test users
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        
        List<User> testUsers = new List<User>();
        
        // Admin user
        User adminUser = new User(
            FirstName = 'Admin',
            LastName = 'User',
            Email = 'admin@example.com',
            Username = 'admin_user@example.com' + System.currentTimeMillis(),
            EmailEncodingKey = 'UTF-8',
            Alias = 'admin',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            LanguageLocaleKey = 'en_US',
            ProfileId = p.Id,
            UserRoleId = ceoRole.Id
        );
        testUsers.add(adminUser);
        
        // Mid-level user (manager)
        User midLevelUser = new User(
            FirstName = 'Mid',
            LastName = 'User',
            Email = 'mid@example.com',
            Username = 'mid_user@example.com' + System.currentTimeMillis(),
            EmailEncodingKey = 'UTF-8',
            Alias = 'mid',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            LanguageLocaleKey = 'en_US',
            ProfileId = p.Id,
            UserRoleId = managerRole.Id
        );
        testUsers.add(midLevelUser);
        
        // Base level user (employee)
        User baseLevelUser = new User(
            FirstName = 'Base',
            LastName = 'User',
            Email = 'base@example.com',
            Username = 'base_user@example.com' + System.currentTimeMillis(),
            EmailEncodingKey = 'UTF-8',
            Alias = 'base',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            LanguageLocaleKey = 'en_US',
            ProfileId = p.Id,
            UserRoleId = employeeRole.Id,
            ManagerId = midLevelUser.Id,
            Is_Employee_Account__c = true
        );
        testUsers.add(baseLevelUser);
        
        // Another employee (not managed by midLevelUser)
        User otherEmployee = new User(
            FirstName = 'Other',
            LastName = 'Employee',
            Email = 'other@example.com',
            Username = 'other_employee@example.com' + System.currentTimeMillis(),
            EmailEncodingKey = 'UTF-8',
            Alias = 'other',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            LanguageLocaleKey = 'en_US',
            ProfileId = p.Id,
            UserRoleId = employeeRole.Id,
            Is_Employee_Account__c = true
        );
        testUsers.add(otherEmployee);
        
        // Regular customer (not an employee)
        User regularCustomer = new User(
            FirstName = 'Regular',
            LastName = 'Customer',
            Email = 'customer@example.com',
            Username = 'regular_customer@example.com' + System.currentTimeMillis(),
            EmailEncodingKey = 'UTF-8',
            Alias = 'cust',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            LanguageLocaleKey = 'en_US',
            ProfileId = p.Id,
            Is_Employee_Account__c = false
        );
        testUsers.add(regularCustomer);
        
        insert testUsers;
        
        // Create permission set assignments
        PermissionSet adminPS = [SELECT Id FROM PermissionSet WHERE Name = :ADMIN_PERMISSION LIMIT 1];
        PermissionSet midPS = [SELECT Id FROM PermissionSet WHERE Name = :MID_PERMISSION LIMIT 1];
        PermissionSet basePS = [SELECT Id FROM PermissionSet WHERE Name = :BASE_PERMISSION LIMIT 1];
        
        List<PermissionSetAssignment> psAssignments = new List<PermissionSetAssignment>();
        psAssignments.add(new PermissionSetAssignment(
            AssigneeId = adminUser.Id,
            PermissionSetId = adminPS.Id
        ));
        psAssignments.add(new PermissionSetAssignment(
            AssigneeId = midLevelUser.Id,
            PermissionSetId = midPS.Id
        ));
        psAssignments.add(new PermissionSetAssignment(
            AssigneeId = baseLevelUser.Id,
            PermissionSetId = basePS.Id
        ));
        psAssignments.add(new PermissionSetAssignment(
            AssigneeId = otherEmployee.Id,
            PermissionSetId = basePS.Id
        ));
        psAssignments.add(new PermissionSetAssignment(
            AssigneeId = regularCustomer.Id,
            PermissionSetId = basePS.Id
        ));
        
        insert psAssignments;
        
        // Create Financial Accounts
        System.runAs(adminUser) {
            // Create account records for each user
            List<Account> accounts = new List<Account>();
            
            Account baseAccount = new Account(
                Name = 'Base User Account',
                RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId()
            );
            accounts.add(baseAccount);
            
            Account otherAccount = new Account(
                Name = 'Other Employee Account',
                RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId()
            );
            accounts.add(otherAccount);
            
            Account customerAccount = new Account(
                Name = 'Customer Account',
                RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId()
            );
            accounts.add(customerAccount);
            
            insert accounts;
            
            // Create financial accounts
            List<FinServ__FinancialAccount__c> financialAccounts = new List<FinServ__FinancialAccount__c>();
            
            // Employee financial account
            FinServ__FinancialAccount__c baseUserFinancialAccount = new FinServ__FinancialAccount__c(
                Name = 'Base User Checking',
                FinServ__PrimaryOwner__c = baseLevelUser.Id,
                FinServ__FinancialAccountType__c = 'Checking',
                FinServ__Balance__c = 5000,
                FinServ__Status__c = 'Open'
            );
            financialAccounts.add(baseUserFinancialAccount);
            
            // Another employee financial account
            FinServ__FinancialAccount__c otherEmployeeFinancialAccount = new FinServ__FinancialAccount__c(
                Name = 'Other Employee Checking',
                FinServ__PrimaryOwner__c = otherEmployee.Id,
                FinServ__FinancialAccountType__c = 'Checking',
                FinServ__Balance__c = 7500,
                FinServ__Status__c = 'Open'
            );
            financialAccounts.add(otherEmployeeFinancialAccount);
            
            // Regular customer financial account
            FinServ__FinancialAccount__c customerFinancialAccount = new FinServ__FinancialAccount__c(
                Name = 'Customer Checking',
                FinServ__PrimaryOwner__c = regularCustomer.Id,
                FinServ__FinancialAccountType__c = 'Checking',
                FinServ__Balance__c = 10000,
                FinServ__Status__c = 'Open'
            );
            financialAccounts.add(customerFinancialAccount);
            
            insert financialAccounts;
            
            // Create access override for mid-level user to other employee account
            FinancialAccountAccess__c accessOverride = new FinancialAccountAccess__c(
                User__c = midLevelUser.Id,
                FinancialAccount__c = otherEmployeeFinancialAccount.Id,
                AccessType__c = 'Override'
            );
            
            insert accessOverride;
        }
    }
    
    @isTest
    static void testAdminAccess() {
        User adminUser = [SELECT Id FROM User WHERE FirstName = 'Admin' AND LastName = 'User' LIMIT 1];
        List<FinServ__FinancialAccount__c> allAccounts = [SELECT Id FROM FinServ__FinancialAccount__c];
        
        System.runAs(adminUser) {
            Test.startTest();
            
            // Admin should have access to all accounts
            for (FinServ__FinancialAccount__c account : allAccounts) {
                Boolean hasAccess = FinancialAccountAccessController.hasAccessToFinancialAccount(account.Id);
                System.assert(hasAccess, 'Admin should have access to all financial accounts');
            }
            
            // Get all accessible accounts
            List<FinServ__FinancialAccount__c> accessibleAccounts = FinancialAccountAccessController.getAccessibleFinancialAccounts();
            System.assertEquals(allAccounts.size(), accessibleAccounts.size(), 'Admin should see all financial accounts');
            
            Test.stopTest();
        }
    }
    
    @isTest
    static void testMidLevelAccess() {
        User midUser = [SELECT Id FROM User WHERE FirstName = 'Mid' AND LastName = 'User' LIMIT 1];
        User baseUser = [SELECT Id FROM User WHERE FirstName = 'Base' AND LastName = 'User' LIMIT 1];
        User otherEmployee = [SELECT Id FROM User WHERE FirstName = 'Other' AND LastName = 'Employee' LIMIT 1];
        User customer = [SELECT Id FROM User WHERE FirstName = 'Regular' AND LastName = 'Customer' LIMIT 1];
        
        FinServ__FinancialAccount__c baseUserAccount = [SELECT Id FROM FinServ__FinancialAccount__c WHERE FinServ__PrimaryOwner__c = :baseUser.Id LIMIT 1];
        FinServ__FinancialAccount__c otherEmployeeAccount = [SELECT Id FROM FinServ__FinancialAccount__c WHERE FinServ__PrimaryOwner__c = :otherEmployee.Id LIMIT 1];
        FinServ__FinancialAccount__c customerAccount = [SELECT Id FROM FinServ__FinancialAccount__c WHERE FinServ__PrimaryOwner__c = :customer.Id LIMIT 1];
        
        System.runAs(midUser) {
            Test.startTest();
            
            // Mid-level user should have access to:
            // 1. Customer account (non-employee)
            Boolean hasCustomerAccess = FinancialAccountAccessController.hasAccessToFinancialAccount(customerAccount.Id);
            System.assert(hasCustomerAccess, 'Mid-level user should have access to customer accounts');
            
            // 2. Managed employee accounts
            Boolean hasBaseUserAccess = FinancialAccountAccessController.hasAccessToFinancialAccount(baseUserAccount.Id);
            System.assert(hasBaseUserAccess, 'Mid-level user should have access to accounts of employees they manage');
            
            // 3. Accounts with override access
            Boolean hasOtherEmployeeAccess = FinancialAccountAccessController.hasAccessToFinancialAccount(otherEmployeeAccount.Id);
            System.assert(hasOtherEmployeeAccess, 'Mid-level user should have access to accounts with override access');
            
            // Get all accessible accounts
            List<FinServ__FinancialAccount__c> accessibleAccounts = FinancialAccountAccessController.getAccessibleFinancialAccounts();
            System.assertEquals(3, accessibleAccounts.size(), 'Mid-level user should see customer, managed employee, and override access accounts');
            
            Test.stopTest();
        }
    }
    
    @isTest
    static void testBaseLevelAccess() {
        User baseUser = [SELECT Id FROM User WHERE FirstName = 'Base' AND LastName = 'User' LIMIT 1];
        User otherEmployee = [SELECT Id FROM User WHERE FirstName = 'Other' AND LastName = 'Employee' LIMIT 1];
        User customer = [SELECT Id FROM User WHERE FirstName = 'Regular' AND LastName = 'Customer' LIMIT 1];
        
        FinServ__FinancialAccount__c baseUserAccount = [SELECT Id FROM FinServ__FinancialAccount__c WHERE FinServ__PrimaryOwner__c = :baseUser.Id LIMIT 1];
        FinServ__FinancialAccount__c otherEmployeeAccount = [SELECT Id FROM FinServ__FinancialAccount__c WHERE FinServ__PrimaryOwner__c = :otherEmployee.Id LIMIT 1];
        FinServ__FinancialAccount__c customerAccount = [SELECT Id FROM FinServ__FinancialAccount__c WHERE FinServ__PrimaryOwner__c = :customer.Id LIMIT 1];
        
        System.runAs(baseUser) {
            Test.startTest();
            
            // Base level user should have access only to non-employee accounts
            Boolean hasCustomerAccess = FinancialAccountAccessController.hasAccessToFinancialAccount(customerAccount.Id);
            System.assert(hasCustomerAccess, 'Base level user should have access to customer accounts');
            
            // Should not have access to employee accounts (even their own)
            Boolean hasBaseUserAccess = FinancialAccountAccessController.hasAccessToFinancialAccount(baseUserAccount.Id);
            System.assert(!hasBaseUserAccess, 'Base level user should not have access to employee accounts');
            
            // Should not have access to other employee accounts
            Boolean hasOtherEmployeeAccess = FinancialAccountAccessController.hasAccessToFinancialAccount(otherEmployeeAccount.Id);
            System.assert(!hasOtherEmployeeAccess, 'Base level user should not have access to other employee accounts');
            
            // Get all accessible accounts
            List<FinServ__FinancialAccount__c> accessibleAccounts = FinancialAccountAccessController.getAccessibleFinancialAccounts();
            System.assertEquals(1, accessibleAccounts.size(), 'Base level user should only see customer accounts');
            
            Test.stopTest();
        }
    }
    
    @isTest
    static void testRoleHierarchyAccess() {
        User adminUser = [SELECT Id FROM User WHERE FirstName = 'Admin' AND LastName = 'User' LIMIT 1];
        User midUser = [SELECT Id FROM User WHERE FirstName = 'Mid' AND LastName = 'User' LIMIT 1];
        User baseUser = [SELECT Id FROM User WHERE FirstName = 'Base' AND LastName = 'User' LIMIT 1];
        
        FinServ__FinancialAccount__c baseUserAccount = [SELECT Id FROM FinServ__FinancialAccount__c WHERE FinServ__PrimaryOwner__c = :baseUser.Id LIMIT 1];
        
        System.runAs(adminUser) {
            Test.startTest();
            
            // Admin should have access through role hierarchy
            Boolean hasAccessThroughRole = FinancialAccountAccessController.hasAccessToFinancialAccount(baseUserAccount.Id);
            System.assert(hasAccessThroughRole, 'User with higher role should have access through role hierarchy');
            
            Test.stopTest();
        }
    }
    
    @isTest
    static void testAccessOverride() {
        User midUser = [SELECT Id FROM User WHERE FirstName = 'Mid' AND LastName = 'User' LIMIT 1];
        User otherEmployee = [SELECT Id FROM User WHERE FirstName = 'Other' AND LastName = 'Employee' LIMIT 1];
        
        FinServ__FinancialAccount__c otherEmployeeAccount = [SELECT Id FROM FinServ__FinancialAccount__c WHERE FinServ__PrimaryOwner__c = :otherEmployee.Id LIMIT 1];
        
        System.runAs(midUser) {
            Test.startTest();
            
            // Mid-level user should have access through override
            Boolean hasAccessThroughOverride = FinancialAccountAccessController.hasAccessToFinancialAccount(otherEmployeeAccount.Id);
            System.assert(hasAccessThroughOverride, 'Mid-level user should have access through override');
            
            // Delete the override
            FinancialAccountAccess__c override = [
                SELECT Id FROM FinancialAccountAccess__c 
                WHERE User__c = :midUser.Id 
                AND FinancialAccount__c = :otherEmployeeAccount.Id
                LIMIT 1
            ];
            delete override;
            
            // Now should not have access
            Boolean hasAccessAfterOverrideRemoval = FinancialAccountAccessController.hasAccessToFinancialAccount(otherEmployeeAccount.Id);
            System.assert(!hasAccessAfterOverrideRemoval, 'Mid-level user should not have access after override removal');
            
            Test.stopTest();
        }
    }
}
