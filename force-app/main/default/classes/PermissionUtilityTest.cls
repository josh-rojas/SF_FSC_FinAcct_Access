/**
 * @description Test class for PermissionUtility
 * @author Your Name
 * @date Current Date
 */
@isTest
private class PermissionUtilityTest {
    
    @TestSetup
    static void setupTestData() {
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
            ProfileId = p.Id
        );
        testUsers.add(adminUser);
        
        // Mid-level user
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
            ProfileId = p.Id
        );
        testUsers.add(midLevelUser);
        
        // Base level user
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
            ProfileId = p.Id
        );
        testUsers.add(baseLevelUser);
        
        // User with no permission sets
        User noPermissionUser = new User(
            FirstName = 'No',
            LastName = 'Permission',
            Email = 'noperm@example.com',
            Username = 'no_permission@example.com' + System.currentTimeMillis(),
            EmailEncodingKey = 'UTF-8',
            Alias = 'noperm',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            LanguageLocaleKey = 'en_US',
            ProfileId = p.Id
        );
        testUsers.add(noPermissionUser);
        
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
        
        insert psAssignments;
    }
    
    @isTest
    static void testGetUserPermissionLevel() {
        User adminUser = [SELECT Id FROM User WHERE FirstName = 'Admin' AND LastName = 'User' LIMIT 1];
        User midLevelUser = [SELECT Id FROM User WHERE FirstName = 'Mid' AND LastName = 'User' LIMIT 1];
        User baseLevelUser = [SELECT Id FROM User WHERE FirstName = 'Base' AND LastName = 'User' LIMIT 1];
        User noPermissionUser = [SELECT Id FROM User WHERE FirstName = 'No' AND LastName = 'Permission' LIMIT 1];
        
        Test.startTest();
        
        // Test admin user permission level
        String adminPermission = PermissionUtility.getUserPermissionLevel(adminUser.Id);
        System.assertEquals('Admin_Level', adminPermission, 'Admin user should have Admin_Level permission');
        
        // Test mid-level user permission level
        String midPermission = PermissionUtility.getUserPermissionLevel(midLevelUser.Id);
        System.assertEquals('Mid_Level', midPermission, 'Mid-level user should have Mid_Level permission');
        
        // Test base level user permission level
        String basePermission = PermissionUtility.getUserPermissionLevel(baseLevelUser.Id);
        System.assertEquals('Base_Level', basePermission, 'Base level user should have Base_Level permission');
        
        // Test user with no permission sets
        String noPermission = PermissionUtility.getUserPermissionLevel(noPermissionUser.Id);
        System.assertEquals('Base_Level', noPermission, 'User with no permission sets should default to Base_Level');
        
        Test.stopTest();
    }
    
    @isTest
    static void testGetCurrentUserPermissionLevel() {
        User adminUser = [SELECT Id FROM User WHERE FirstName = 'Admin' AND LastName = 'User' LIMIT 1];
        
        System.runAs(adminUser) {
            Test.startTest();
            
            String permissionLevel = PermissionUtility.getCurrentUserPermissionLevel();
            System.assertEquals('Admin_Level', permissionLevel, 'Current user should have Admin_Level permission');
            
            Test.stopTest();
        }
    }
    
    @isTest
    static void testHasAdminAccess() {
        User adminUser = [SELECT Id FROM User WHERE FirstName = 'Admin' AND LastName = 'User' LIMIT 1];
        User midLevelUser = [SELECT Id FROM User WHERE FirstName = 'Mid' AND LastName = 'User' LIMIT 1];
        
        System.runAs(adminUser) {
            Test.startTest();
            
            Boolean hasAdmin = PermissionUtility.hasAdminAccess();
            System.assert(hasAdmin, 'Admin user should have admin access');
            
            Test.stopTest();
        }
        
        System.runAs(midLevelUser) {
            Test.startTest();
            
            Boolean hasAdmin = PermissionUtility.hasAdminAccess();
            System.assert(!hasAdmin, 'Mid-level user should not have admin access');
            
            Test.stopTest();
        }
    }
    
    @isTest
    static void testHasMidLevelAccessOrHigher() {
        User adminUser = [SELECT Id FROM User WHERE FirstName = 'Admin' AND LastName = 'User' LIMIT 1];
        User midLevelUser = [SELECT Id FROM User WHERE FirstName = 'Mid' AND LastName = 'User' LIMIT 1];
        User baseLevelUser = [SELECT Id FROM User WHERE FirstName = 'Base' AND LastName = 'User' LIMIT 1];
        
        System.runAs(adminUser) {
            Test.startTest();
            
            Boolean hasMidOrHigher = PermissionUtility.hasMidLevelAccessOrHigher();
            System.assert(hasMidOrHigher, 'Admin user should have mid level access or higher');
            
            Test.stopTest();
        }
        
        System.runAs(midLevelUser) {
            Test.startTest();
            
            Boolean hasMidOrHigher = PermissionUtility.hasMidLevelAccessOrHigher();
            System.assert(hasMidOrHigher, 'Mid-level user should have mid level access or higher');
            
            Test.stopTest();
        }
        
        System.runAs(baseLevelUser) {
            Test.startTest();
            
            Boolean hasMidOrHigher = PermissionUtility.hasMidLevelAccessOrHigher();
            System.assert(!hasMidOrHigher, 'Base level user should not have mid level access or higher');
            
            Test.stopTest();
        }
    }
    
    @isTest
    static void testClearPermissionCache() {
        User adminUser = [SELECT Id FROM User WHERE FirstName = 'Admin' AND LastName = 'User' LIMIT 1];
        
        System.runAs(adminUser) {
            Test.startTest();
            
            // This will cache the permission level
            String permissionLevel = PermissionUtility.getCurrentUserPermissionLevel();
            
            // Clear the cache for this user
            PermissionUtility.clearPermissionCache(adminUser.Id);
            
            // This should query again since the cache was cleared
            permissionLevel = PermissionUtility.getCurrentUserPermissionLevel();
            System.assertEquals('Admin_Level', permissionLevel, 'Permission level should be correctly retrieved after cache clear');
            
            // Clear all cache
            PermissionUtility.clearAllPermissionCache();
            
            // This should query again since all cache was cleared
            permissionLevel = PermissionUtility.getCurrentUserPermissionLevel();
            System.assertEquals('Admin_Level', permissionLevel, 'Permission level should be correctly retrieved after all cache clear');
            
            Test.stopTest();
        }
    }
    
    @isTest
    static void testGetUsersWithPermissionLevel() {
        Test.startTest();
        
        // Get admin users
        List<User> adminUsers = PermissionUtility.getUsersWithPermissionLevel('Admin_Level');
        System.assertEquals(1, adminUsers.size(), 'Should have 1 admin user');
        
        // Get mid-level users
        List<User> midUsers = PermissionUtility.getUsersWithPermissionLevel('Mid_Level');
        System.assertEquals(1, midUsers.size(), 'Should have 1 mid-level user');
        
        // Get base level users
        List<User> baseUsers = PermissionUtility.getUsersWithPermissionLevel('Base_Level');
        System.assertEquals(1, baseUsers.size(), 'Should have 1 base level user');
        
        Test.stopTest();
    }
}
