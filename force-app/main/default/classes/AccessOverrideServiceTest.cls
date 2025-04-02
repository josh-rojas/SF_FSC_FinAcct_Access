/**
 * @description Test class for AccessOverrideService
 * @author Your Name
 * @date Current Date
 */
@isTest
private class AccessOverrideServiceTest {
    
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
        
        // Another mid-level user (for override testing)
        User anotherMidLevelUser = new User(
            FirstName = 'Another',
            LastName = 'Mid',
            Email = 'another@example.com',
            Username = 'another_mid@example.com' + System.currentTimeMillis(),
            EmailEncodingKey = 'UTF-8',
            Alias = 'anoth',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            LanguageLocaleKey = 'en_US',
            ProfileId = p.Id,
            UserRoleId = managerRole.Id
        );
        testUsers.add(anotherMidLevelUser);
        
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
        PermissionSet adminPS = [SELECT Id FROM PermissionSet WHERE Name = 'FinancialAccount_Admin_Access' LIMIT 1];
        PermissionSet midPS = [SELECT Id FROM PermissionSet WHERE Name = 'FinancialAccount_Mid_Access' LIMIT 1];
        PermissionSet basePS = [SELECT Id FROM PermissionSet WHERE Name = 'FinancialAccount_Base_Access' LIMIT 1];
        
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
            AssigneeId = anotherMidLevelUser.Id,
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
    static void testHasOverrideAccess() {
        User midLevelUser = [SELECT Id FROM User WHERE FirstName = 'Mid' AND LastName = 'User' LIMIT 1];
        User otherEmployee = [SELECT Id FROM User WHERE FirstName = 'Other' AND LastName = 'Employee' LIMIT 1];
        
        FinServ__FinancialAccount__c otherEmployeeAccount = [
            SELECT Id FROM FinServ__FinancialAccount__c 
            WHERE FinServ__PrimaryOwner__c = :otherEmployee.Id LIMIT 1
        ];
        
        Test.startTest();
        
        // Mid-level user should have override access
        Boolean hasAccess = AccessOverrideService.hasOverrideAccess(midLevelUser.Id, otherEmployeeAccount.Id);
        System.assert(hasAccess, 'Mid-level user should have override access');
        
        // Employee should not have override access to their own account
        Boolean selfAccess = AccessOverrideService.hasOverrideAccess(otherEmployee.Id, otherEmployeeAccount.Id);
        System.assert(!selfAccess, 'Employee should not have override access to their own account');
        
        Test.stopTest();
    }
    
    @isTest
    static void testGrantOverrideAccess() {
        User adminUser = [SELECT Id FROM User WHERE FirstName = 'Admin' AND LastName = 'User' LIMIT 1];
        User anotherMidLevelUser = [SELECT Id FROM User WHERE FirstName = 'Another' AND LastName = 'Mid' LIMIT 1];
        User otherEmployee = [SELECT Id FROM User WHERE FirstName = 'Other' AND LastName = 'Employee' LIMIT 1];
        
        FinServ__FinancialAccount__c otherEmployeeAccount = [
            SELECT Id FROM FinServ__FinancialAccount__c 
            WHERE FinServ__PrimaryOwner__c = :otherEmployee.Id LIMIT 1
        ];
        
        System.runAs(adminUser) {
            Test.startTest();
            
            // Grant override access to another mid-level user
            FinancialAccountAccess__c override = AccessOverrideService.grantOverrideAccess(
                anotherMidLevelUser.Id, otherEmployeeAccount.Id);
            
            System.assertNotEquals(null, override.Id, 'Override should have been created');
            
            // Verify the override was created
            Boolean hasAccess = AccessOverrideService.hasOverrideAccess(
                anotherMidLevelUser.Id, otherEmployeeAccount.Id);
            System.assert(hasAccess, 'Another mid-level user should now have override access');
            
            // Try to grant access again (should return existing override)
            FinancialAccountAccess__c duplicateOverride = AccessOverrideService.grantOverrideAccess(
                anotherMidLevelUser.Id, otherEmployeeAccount.Id);
            
            System.assertEquals(override.Id, duplicateOverride.Id, 'Should return existing override');
            
            Test.stopTest();
        }
    }
    
    @isTest
    static void testRevokeOverrideAccess() {
        User adminUser = [SELECT Id FROM User WHERE FirstName = 'Admin' AND LastName = 'User' LIMIT 1];
        User midLevelUser = [SELECT Id FROM User WHERE FirstName = 'Mid' AND LastName = 'User' LIMIT 1];
        User otherEmployee = [SELECT Id FROM User WHERE FirstName = 'Other' AND LastName = 'Employee' LIMIT 1];
        
        FinServ__FinancialAccount__c otherEmployeeAccount = [
            SELECT Id FROM FinServ__FinancialAccount__c 
            WHERE FinServ__PrimaryOwner__c = :otherEmployee.Id LIMIT 1
        ];
        
        System.runAs(adminUser) {
            Test.startTest();
            
            // Verify override exists
            Boolean hasAccessBefore = AccessOverrideService.hasOverrideAccess(
                midLevelUser.Id, otherEmployeeAccount.Id);
            System.assert(hasAccessBefore, 'Mid-level user should have override access initially');
            
            // Revoke override access
            Boolean result = AccessOverrideService.revokeOverrideAccess(
                midLevelUser.Id, otherEmployeeAccount.Id);
            
            System.assert(result, 'Revoke should return true for success');
            
            // Verify override was removed
            Boolean hasAccessAfter = AccessOverrideService.hasOverrideAccess(
                midLevelUser.Id, otherEmployeeAccount.Id);
            System.assert(!hasAccessAfter, 'Mid-level user should no longer have override access');
            
            // Try to revoke again (should return false)
            Boolean secondResult = AccessOverrideService.revokeOverrideAccess(
                midLevelUser.Id, otherEmployeeAccount.Id);
            
            System.assert(!secondResult, 'Revoke should return false when no override exists');
            
            Test.stopTest();
        }
    }
    
    @isTest
    static void testGetAccountOverrides() {
        User adminUser = [SELECT Id FROM User WHERE FirstName = 'Admin' AND LastName = 'User' LIMIT 1];
        User midLevelUser = [SELECT Id FROM User WHERE FirstName = 'Mid' AND LastName = 'User' LIMIT 1];
        User anotherMidLevelUser = [SELECT Id FROM User WHERE FirstName = 'Another' AND LastName = 'Mid' LIMIT 1];
        User otherEmployee = [SELECT Id FROM User WHERE FirstName = 'Other' AND LastName = 'Employee' LIMIT 1];
        
        FinServ__FinancialAccount__c otherEmployeeAccount = [
            SELECT Id FROM FinServ__FinancialAccount__c 
            WHERE FinServ__PrimaryOwner__c = :otherEmployee.Id LIMIT 1
        ];
        
        System.runAs(adminUser) {
            // Add another override
            AccessOverrideService.grantOverrideAccess(anotherMidLevelUser.Id, otherEmployeeAccount.Id);
            
            Test.startTest();
            
            // Get account overrides
            List<AccessOverrideService.OverrideAccessWrapper> overrides = 
                AccessOverrideService.getAccountOverrides(otherEmployeeAccount.Id);
            
            System.assertEquals(2, overrides.size(), 'Should have 2 overrides for the account');
            
            // Verify content
            Boolean foundMidUserOverride = false;
            Boolean foundAnotherMidUserOverride = false;
            
            for (AccessOverrideService.OverrideAccessWrapper override : overrides) {
                if (override.userId == midLevelUser.Id) {
                    foundMidUserOverride = true;
                }
                if (override.userId == anotherMidLevelUser.Id) {
                    foundAnotherMidUserOverride = true;
                }
            }
            
            System.assert(foundMidUserOverride, 'Should find override for mid-level user');
            System.assert(foundAnotherMidUserOverride, 'Should find override for another mid-level user');
            
            Test.stopTest();
        }
    }
    
    @isTest
    static void testGetUserOverrides() {
        User adminUser = [SELECT Id FROM User WHERE FirstName = 'Admin' AND LastName = 'User' LIMIT 1];
        User midLevelUser = [SELECT Id FROM User WHERE FirstName = 'Mid' AND LastName = 'User' LIMIT 1];
        User baseLevelUser = [SELECT Id FROM User WHERE FirstName = 'Base' AND LastName = 'User' LIMIT 1];
        User otherEmployee = [SELECT Id FROM User WHERE FirstName = 'Other' AND LastName = 'Employee' LIMIT 1];
        
        FinServ__FinancialAccount__c baseUserAccount = [
            SELECT Id FROM FinServ__FinancialAccount__c 
            WHERE FinServ__PrimaryOwner__c = :baseLevelUser.Id LIMIT 1
        ];
        
        FinServ__FinancialAccount__c otherEmployeeAccount = [
            SELECT Id FROM FinServ__FinancialAccount__c 
            WHERE FinServ__PrimaryOwner__c = :otherEmployee.Id LIMIT 1
        ];
        
        System.runAs(adminUser) {
            // Add another override for the mid-level user
            AccessOverrideService.grantOverrideAccess(midLevelUser.Id, baseUserAccount.Id);
            
            Test.startTest();
            
            // Get user overrides
            List<AccessOverrideService.OverrideAccessWrapper> overrides = 
                AccessOverrideService.getUserOverrides(midLevelUser.Id);
            
            System.assertEquals(2, overrides.size(), 'Mid-level user should have 2 overrides');
            
            // Verify content
            Boolean foundBaseUserAccountOverride = false;
            Boolean foundOtherEmployeeAccountOverride = false;
            
            for (AccessOverrideService.OverrideAccessWrapper override : overrides) {
                if (override.accountId == baseUserAccount.Id) {
                    foundBaseUserAccountOverride = true;
                }
                if (override.accountId == otherEmployeeAccount.Id) {
                    foundOtherEmployeeAccountOverride = true;
                }
            }
            
            System.assert(foundBaseUserAccountOverride, 'Should find override for base user account');
            System.assert(foundOtherEmployeeAccountOverride, 'Should find override for other employee account');
            
            Test.stopTest();
        }
    }
    
    @isTest
    static void testGetEligibleUsersForOverride() {
        User adminUser = [SELECT Id FROM User WHERE FirstName = 'Admin' AND LastName = 'User' LIMIT 1];
        User otherEmployee = [SELECT Id FROM User WHERE FirstName = 'Other' AND LastName = 'Employee' LIMIT 1];
        User regularCustomer = [SELECT Id FROM User WHERE FirstName = 'Regular' AND LastName = 'Customer' LIMIT 1];
        
        FinServ__FinancialAccount__c otherEmployeeAccount = [
            SELECT Id FROM FinServ__FinancialAccount__c 
            WHERE FinServ__PrimaryOwner__c = :otherEmployee.Id LIMIT 1
        ];
        
        FinServ__FinancialAccount__c customerAccount = [
            SELECT Id FROM FinServ__FinancialAccount__c 
            WHERE FinServ__PrimaryOwner__c = :regularCustomer.Id LIMIT 1
        ];
        
        System.runAs(adminUser) {
            Test.startTest();
            
            // Get eligible users for employee account
            List<AccessOverrideService.UserWrapper> eligibleUsers = 
                AccessOverrideService.getEligibleUsersForOverride(otherEmployeeAccount.Id);
            
            // Should include admin and one mid-level user (Another Mid)
            // The other mid-level user already has an override
            System.assert(eligibleUsers.size() >= 2, 'Should have at least 2 eligible users');
            
            // Get eligible users for customer account
            List<AccessOverrideService.UserWrapper> customerEligibleUsers = 
                AccessOverrideService.getEligibleUsersForOverride(customerAccount.Id);
            
            // Non-employee accounts don't need overrides
            System.assertEquals(0, customerEligibleUsers.size(), 'Customer account should have no eligible users');
            
            Test.stopTest();
        }
    }
    
    @isTest
    static void testGrantAccessToNonEmployeeAccount() {
        User adminUser = [SELECT Id FROM User WHERE FirstName = 'Admin' AND LastName = 'User' LIMIT 1];
        User midLevelUser = [SELECT Id FROM User WHERE FirstName = 'Mid' AND LastName = 'User' LIMIT 1];
        User regularCustomer = [SELECT Id FROM User WHERE FirstName = 'Regular' AND LastName = 'Customer' LIMIT 1];
        
        FinServ__FinancialAccount__c customerAccount = [
            SELECT Id FROM FinServ__FinancialAccount__c 
            WHERE FinServ__PrimaryOwner__c = :regularCustomer.Id LIMIT 1
        ];
        
        System.runAs(adminUser) {
            Test.startTest();
            
            try {
                // Try to grant override for a non-employee account
                AccessOverrideService.grantOverrideAccess(midLevelUser.Id, customerAccount.Id);
                System.assert(false, 'Should have thrown an exception');
            } catch (AuraHandledException e) {
                System.assert(e.getMessage().contains('can only be granted for employee accounts'), 
                           'Should get error message about employee accounts');
            }
            
            Test.stopTest();
        }
    }
    
    @isTest
    static void testPermissionCheckForGrantRevoke() {
        User baseLevelUser = [SELECT Id FROM User WHERE FirstName = 'Base' AND LastName = 'User' LIMIT 1];
        User otherEmployee = [SELECT Id FROM User WHERE FirstName = 'Other' AND LastName = 'Employee' LIMIT 1];
        
        FinServ__FinancialAccount__c otherEmployeeAccount = [
            SELECT Id FROM FinServ__FinancialAccount__c 
            WHERE FinServ__PrimaryOwner__c = :otherEmployee.Id LIMIT 1
        ];
        
        System.runAs(baseLevelUser) {
            Test.startTest();
            
            try {
                // Base level user shouldn't be able to grant override
                AccessOverrideService.grantOverrideAccess(baseLevelUser.Id, otherEmployeeAccount.Id);
                System.assert(false, 'Should have thrown an exception');
            } catch (AuraHandledException e) {
                System.assert(e.getMessage().contains('do not have permission'), 
                           'Should get error message about permissions');
            }
            
            try {
                // Base level user shouldn't be able to revoke override
                AccessOverrideService.revokeOverrideAccess(baseLevelUser.Id, otherEmployeeAccount.Id);
                System.assert(false, 'Should have thrown an exception');
            } catch (AuraHandledException e) {
                System.assert(e.getMessage().contains('do not have permission'), 
                           'Should get error message about permissions');
            }
            
            Test.stopTest();
        }
    }
}
