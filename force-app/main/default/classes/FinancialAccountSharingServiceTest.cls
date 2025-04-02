/**
 * @description Test class for FinancialAccountSharingService
 * @author Your Name
 * @date Current Date
 */
@isTest
private class FinancialAccountSharingServiceTest {
    
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
    static void testCreateSharing() {
        User adminUser = [SELECT Id FROM User WHERE FirstName = 'Admin' AND LastName = 'User' LIMIT 1];
        User baseLevelUser = [SELECT Id FROM User WHERE FirstName = 'Base' AND LastName = 'User' LIMIT 1];
        
        FinServ__FinancialAccount__c baseUserAccount = [
            SELECT Id FROM FinServ__FinancialAccount__c 
            WHERE FinServ__PrimaryOwner__c = :baseLevelUser.Id LIMIT 1
        ];
        
        System.runAs(adminUser) {
            Test.startTest();
            
            // Delete any existing sharing
            FinancialAccountSharingService.deleteSharing(baseUserAccount.Id);
            
            // Create sharing
            FinancialAccountSharingService.createSharing(baseUserAccount.Id);
            
            // Verify sharing was created
            List<FinServ__FinancialAccountShare> shares = [
                SELECT Id, UserOrGroupId, AccessLevel 
                FROM FinServ__FinancialAccountShare 
                WHERE ParentId = :baseUserAccount.Id
                AND RowCause = 'Manual'
            ];
            
            // Should have at least 2 shares: admin user and manager (mid-level user)
            System.assert(shares.size() >= 2, 'Should have at least 2 shares');
            
            // Verify admin has edit access
            Boolean foundAdminShare = false;
            for (FinServ__FinancialAccountShare share : shares) {
                if (share.UserOrGroupId == adminUser.Id) {
                    foundAdminShare = true;
                    System.assertEquals('Edit', share.AccessLevel, 'Admin should have Edit access');
                }
            }
            
            System.assert(foundAdminShare, 'Should have a share for admin user');
            
            Test.stopTest();
        }
    }
    
    @isTest
    static void testUpdateSharing() {
        User adminUser = [SELECT Id FROM User WHERE FirstName = 'Admin' AND LastName = 'User' LIMIT 1];
        User baseLevelUser = [SELECT Id FROM User WHERE FirstName = 'Base' AND LastName = 'User' LIMIT 1];
        
        FinServ__FinancialAccount__c baseUserAccount = [
            SELECT Id FROM FinServ__FinancialAccount__c 
            WHERE FinServ__PrimaryOwner__c = :baseLevelUser.Id LIMIT 1
        ];
        
        System.runAs(adminUser) {
            Test.startTest();
            
            // Initial sharing count
            Integer initialShareCount = [
                SELECT COUNT() FROM FinServ__FinancialAccountShare 
                WHERE ParentId = :baseUserAccount.Id
                AND RowCause = 'Manual'
            ];
            
            // Update sharing
            FinancialAccountSharingService.updateSharing(baseUserAccount.Id);
            
            // Verify sharing was updated
            Integer finalShareCount = [
                SELECT COUNT() FROM FinServ__FinancialAccountShare 
                WHERE ParentId = :baseUserAccount.Id
                AND RowCause = 'Manual'
            ];
            
            // Counts should be the same since we're just re-creating the same sharing
            System.assertEquals(initialShareCount, finalShareCount, 'Share count should remain consistent after update');
            
            Test.stopTest();
        }
    }
    
    @isTest
    static void testDeleteSharing() {
        User adminUser = [SELECT Id FROM User WHERE FirstName = 'Admin' AND LastName = 'User' LIMIT 1];
        User baseLevelUser = [SELECT Id FROM User WHERE FirstName = 'Base' AND LastName = 'User' LIMIT 1];
        
        FinServ__FinancialAccount__c baseUserAccount = [
            SELECT Id FROM FinServ__FinancialAccount__c 
            WHERE FinServ__PrimaryOwner__c = :baseLevelUser.Id LIMIT 1
        ];
        
        System.runAs(adminUser) {
            Test.startTest();
            
            // Create sharing first
            FinancialAccountSharingService.createSharing(baseUserAccount.Id);
            
            // Verify shares exist
            Integer shareCount = [
                SELECT COUNT() FROM FinServ__FinancialAccountShare 
                WHERE ParentId = :baseUserAccount.Id
                AND RowCause = 'Manual'
            ];
            
            System.assert(shareCount > 0, 'Shares should be created before deleting');
            
            // Delete sharing
            FinancialAccountSharingService.deleteSharing(baseUserAccount.Id);
            
            // Verify shares were deleted
            Integer finalShareCount = [
                SELECT COUNT() FROM FinServ__FinancialAccountShare 
                WHERE ParentId = :baseUserAccount.Id
                AND RowCause = 'Manual'
            ];
            
            System.assertEquals(0, finalShareCount, 'All manual shares should be deleted');
            
            Test.stopTest();
        }
    }
    
    @isTest
    static void testProcessSharingUpdates() {
        User adminUser = [SELECT Id FROM User WHERE FirstName = 'Admin' AND LastName = 'User' LIMIT 1];
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
            Test.startTest();
            
            // Delete any existing sharing
            FinancialAccountSharingService.deleteSharing(baseUserAccount.Id);
            FinancialAccountSharingService.deleteSharing(otherEmployeeAccount.Id);
            
            // Process updates for multiple accounts
            List<Id> accountIds = new List<Id>{ baseUserAccount.Id, otherEmployeeAccount.Id };
            FinancialAccountSharingService.processSharingUpdates(accountIds);
            
            // Verify sharing was created for both accounts
            Integer baseUserShareCount = [
                SELECT COUNT() FROM FinServ__FinancialAccountShare 
                WHERE ParentId = :baseUserAccount.Id
                AND RowCause = 'Manual'
            ];
            
            Integer otherEmployeeShareCount = [
                SELECT COUNT() FROM FinServ__FinancialAccountShare 
                WHERE ParentId = :otherEmployeeAccount.Id
                AND RowCause = 'Manual'
            ];
            
            System.assert(baseUserShareCount > 0, 'Shares should be created for base user account');
            System.assert(otherEmployeeShareCount > 0, 'Shares should be created for other employee account');
            
            // Test with null and empty lists
            FinancialAccountSharingService.processSharingUpdates(null);
            FinancialAccountSharingService.processSharingUpdates(new List<Id>());
            
            Test.stopTest();
        }
    }
    
    @isTest
    static void testSharingWithRoleHierarchy() {
        User adminUser = [SELECT Id FROM User WHERE FirstName = 'Admin' AND LastName = 'User' LIMIT 1];
        User midLevelUser = [SELECT Id FROM User WHERE FirstName = 'Mid' AND LastName = 'User' LIMIT 1];
        User baseLevelUser = [SELECT Id FROM User WHERE FirstName = 'Base' AND LastName = 'User' LIMIT 1];
        
        FinServ__FinancialAccount__c baseUserAccount = [
            SELECT Id FROM FinServ__FinancialAccount__c 
            WHERE FinServ__PrimaryOwner__c = :baseLevelUser.Id LIMIT 1
        ];
        
        System.runAs(adminUser) {
            Test.startTest();
            
            // Delete any existing sharing
            FinancialAccountSharingService.deleteSharing(baseUserAccount.Id);
            
            // Create sharing
            FinancialAccountSharingService.createSharing(baseUserAccount.Id);
            
            // Verify mid-level user has access through role hierarchy
            List<FinServ__FinancialAccountShare> midUserShares = [
                SELECT Id, AccessLevel 
                FROM FinServ__FinancialAccountShare 
                WHERE ParentId = :baseUserAccount.Id
                AND UserOrGroupId = :midLevelUser.Id
                AND RowCause = 'Manual'
            ];
            
            System.assertEquals(1, midUserShares.size(), 'Mid-level user should have share through role hierarchy');
            System.assertEquals('Read', midUserShares[0].AccessLevel, 'Mid-level user should have Read access');
            
            Test.stopTest();
        }
    }
    
    @isTest
    static void testSharingWithOverrideAccess() {
        User adminUser = [SELECT Id FROM User WHERE FirstName = 'Admin' AND LastName = 'User' LIMIT 1];
        User midLevelUser = [SELECT Id FROM User WHERE FirstName = 'Mid' AND LastName = 'User' LIMIT 1];
        User otherEmployee = [SELECT Id FROM User WHERE FirstName = 'Other' AND LastName = 'Employee' LIMIT 1];
        
        FinServ__FinancialAccount__c otherEmployeeAccount = [
            SELECT Id FROM FinServ__FinancialAccount__c 
            WHERE FinServ__PrimaryOwner__c = :otherEmployee.Id LIMIT 1
        ];
        
        System.runAs(adminUser) {
            Test.startTest();
            
            // Delete any existing sharing
            FinancialAccountSharingService.deleteSharing(otherEmployeeAccount.Id);
            
            // Create sharing
            FinancialAccountSharingService.createSharing(otherEmployeeAccount.Id);
            
            // Verify mid-level user has access through override
            List<FinServ__FinancialAccountShare> midUserShares = [
                SELECT Id, AccessLevel 
                FROM FinServ__FinancialAccountShare 
                WHERE ParentId = :otherEmployeeAccount.Id
                AND UserOrGroupId = :midLevelUser.Id
                AND RowCause = 'Manual'
            ];
            
            System.assertEquals(1, midUserShares.size(), 'Mid-level user should have share through override');
            
            // Remove the override access
            FinancialAccountAccess__c override = [
                SELECT Id FROM FinancialAccountAccess__c 
                WHERE User__c = :midLevelUser.Id 
                AND FinancialAccount__c = :otherEmployeeAccount.Id
                LIMIT 1
            ];
            delete override;
            
            // Update sharing
            FinancialAccountSharingService.updateSharing(otherEmployeeAccount.Id);
            
            // Verify mid-level user no longer has access
            List<FinServ__FinancialAccountShare> updatedMidUserShares = [
                SELECT Id 
                FROM FinServ__FinancialAccountShare 
                WHERE ParentId = :otherEmployeeAccount.Id
                AND UserOrGroupId = :midLevelUser.Id
                AND RowCause = 'Manual'
            ];
            
            System.assertEquals(0, updatedMidUserShares.size(), 'Mid-level user should not have access after override removal');
            
            Test.stopTest();
        }
    }
}
