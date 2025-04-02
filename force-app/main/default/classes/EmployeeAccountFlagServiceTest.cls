/**
 * @description Test class for EmployeeAccountFlagService
 * @author Your Name
 * @date Current Date
 */
@isTest
private class EmployeeAccountFlagServiceTest {
    
    @TestSetup
    static void setupTestData() {
        // Create test users
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        
        List<User> testUsers = new List<User>();
        
        // Employee user
        User employeeUser = new User(
            FirstName = 'Test',
            LastName = 'Employee',
            Email = 'employee@example.com',
            Username = 'test_employee@example.com' + System.currentTimeMillis(),
            EmailEncodingKey = 'UTF-8',
            Alias = 'empl',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            LanguageLocaleKey = 'en_US',
            ProfileId = p.Id,
            Is_Employee_Account__c = true
        );
        testUsers.add(employeeUser);
        
        // Customer user
        User customerUser = new User(
            FirstName = 'Test',
            LastName = 'Customer',
            Email = 'customer@example.com',
            Username = 'test_customer@example.com' + System.currentTimeMillis(),
            EmailEncodingKey = 'UTF-8',
            Alias = 'cust',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            LanguageLocaleKey = 'en_US',
            ProfileId = p.Id,
            Is_Employee_Account__c = false
        );
        testUsers.add(customerUser);
        
        insert testUsers;
        
        // Create admin user to create financial accounts
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
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1].Id
        );
        insert adminUser;
        
        System.runAs(adminUser) {
            // Create financial accounts
            List<FinServ__FinancialAccount__c> financialAccounts = new List<FinServ__FinancialAccount__c>();
            
            // Employee financial account
            FinServ__FinancialAccount__c employeeAccount = new FinServ__FinancialAccount__c(
                Name = 'Employee Checking',
                FinServ__PrimaryOwner__c = employeeUser.Id,
                FinServ__FinancialAccountType__c = 'Checking',
                FinServ__Balance__c = 5000,
                FinServ__Status__c = 'Open'
            );
            financialAccounts.add(employeeAccount);
            
            // Customer financial account
            FinServ__FinancialAccount__c customerAccount = new FinServ__FinancialAccount__c(
                Name = 'Customer Checking',
                FinServ__PrimaryOwner__c = customerUser.Id,
                FinServ__FinancialAccountType__c = 'Checking',
                FinServ__Balance__c = 10000,
                FinServ__Status__c = 'Open'
            );
            financialAccounts.add(customerAccount);
            
            insert financialAccounts;
        }
    }
    
    @isTest
    static void testIsEmployeeAccount() {
        User employeeUser = [SELECT Id FROM User WHERE FirstName = 'Test' AND LastName = 'Employee' LIMIT 1];
        User customerUser = [SELECT Id FROM User WHERE FirstName = 'Test' AND LastName = 'Customer' LIMIT 1];
        
        FinServ__FinancialAccount__c employeeAccount = [
            SELECT Id FROM FinServ__FinancialAccount__c 
            WHERE FinServ__PrimaryOwner__c = :employeeUser.Id LIMIT 1
        ];
        
        FinServ__FinancialAccount__c customerAccount = [
            SELECT Id FROM FinServ__FinancialAccount__c 
            WHERE FinServ__PrimaryOwner__c = :customerUser.Id LIMIT 1
        ];
        
        Test.startTest();
        
        // Employee account should be flagged as employee account
        Boolean isEmployeeAccountFlagged = EmployeeAccountFlagService.isEmployeeAccount(employeeAccount.Id);
        System.assert(isEmployeeAccountFlagged, 'Employee account should be flagged as employee account');
        
        // Customer account should not be flagged as employee account
        Boolean isCustomerAccountFlagged = EmployeeAccountFlagService.isEmployeeAccount(customerAccount.Id);
        System.assert(!isCustomerAccountFlagged, 'Customer account should not be flagged as employee account');
        
        Test.stopTest();
    }
    
    @isTest
    static void testGetEmployeeAccounts() {
        Test.startTest();
        
        List<FinServ__FinancialAccount__c> employeeAccounts = EmployeeAccountFlagService.getEmployeeAccounts();
        
        Test.stopTest();
        
        System.assertEquals(1, employeeAccounts.size(), 'There should be 1 employee account');
        System.assertEquals('Employee Checking', employeeAccounts[0].Name, 'The account should be the employee checking account');
    }
    
    @isTest
    static void testGetNonEmployeeAccounts() {
        Test.startTest();
        
        List<FinServ__FinancialAccount__c> nonEmployeeAccounts = EmployeeAccountFlagService.getNonEmployeeAccounts();
        
        Test.stopTest();
        
        System.assertEquals(1, nonEmployeeAccounts.size(), 'There should be 1 non-employee account');
        System.assertEquals('Customer Checking', nonEmployeeAccounts[0].Name, 'The account should be the customer checking account');
    }
    
    @isTest
    static void testSetEmployeeFlag() {
        User customerUser = [SELECT Id, Is_Employee_Account__c FROM User WHERE FirstName = 'Test' AND LastName = 'Customer' LIMIT 1];
        User employeeUser = [SELECT Id, Is_Employee_Account__c FROM User WHERE FirstName = 'Test' AND LastName = 'Employee' LIMIT 1];
        
        System.assertEquals(false, customerUser.Is_Employee_Account__c, 'Customer user should not be flagged as employee initially');
        System.assertEquals(true, employeeUser.Is_Employee_Account__c, 'Employee user should be flagged as employee initially');
        
        Test.startTest();
        
        // Set customer as employee
        List<Id> userIds = new List<Id>{ customerUser.Id };
        List<User> updatedUsers = EmployeeAccountFlagService.setEmployeeFlag(userIds, true);
        
        // Set employee as non-employee
        List<Id> employeeIds = new List<Id>{ employeeUser.Id };
        List<User> updatedEmployees = EmployeeAccountFlagService.setEmployeeFlag(employeeIds, false);
        
        Test.stopTest();
        
        // Verify updates
        User updatedCustomer = [SELECT Is_Employee_Account__c FROM User WHERE Id = :customerUser.Id LIMIT 1];
        User updatedEmployee = [SELECT Is_Employee_Account__c FROM User WHERE Id = :employeeUser.Id LIMIT 1];
        
        System.assertEquals(true, updatedCustomer.Is_Employee_Account__c, 'Customer user should now be flagged as employee');
        System.assertEquals(false, updatedEmployee.Is_Employee_Account__c, 'Employee user should now be flagged as non-employee');
    }
    
    @isTest
    static void testGetUsersWithEmployeeFlag() {
        Test.startTest();
        
        List<EmployeeAccountFlagService.UserWrapper> users = EmployeeAccountFlagService.getUsersWithEmployeeFlag();
        
        Test.stopTest();
        
        System.assert(users.size() >= 2, 'Should return at least the 2 test users');
        
        Boolean foundEmployee = false;
        Boolean foundCustomer = false;
        
        for (EmployeeAccountFlagService.UserWrapper user : users) {
            if (user.name == 'Test Employee') {
                foundEmployee = true;
                System.assertEquals(true, user.isEmployee, 'Employee user should be flagged as employee');
            }
            if (user.name == 'Test Customer') {
                foundCustomer = true;
                System.assertEquals(false, user.isEmployee, 'Customer user should not be flagged as employee');
            }
        }
        
        System.assert(foundEmployee, 'Should find the employee user');
        System.assert(foundCustomer, 'Should find the customer user');
    }
    
    @isTest
    static void testEmptyUserIdList() {
        Test.startTest();
        
        List<User> result1 = EmployeeAccountFlagService.setEmployeeFlag(null, true);
        List<User> result2 = EmployeeAccountFlagService.setEmployeeFlag(new List<Id>(), true);
        
        Test.stopTest();
        
        System.assertEquals(0, result1.size(), 'Null user ID list should return empty list');
        System.assertEquals(0, result2.size(), 'Empty user ID list should return empty list');
    }
}
