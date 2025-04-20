/**
 * @description Utility class for managing and checking user permissions
 * This class provides methods to determine a user's permission level based on assigned permission sets
 * @author Your Name
 * @date Current Date
 */
public with sharing class PermissionUtility {
    
    // Permission set names for different access levels
    private static final String ADMIN_PERMISSION = 'FinancialAccount_Admin_Access';
    private static final String MID_PERMISSION = 'FinancialAccount_Mid_Access';
    private static final String BASE_PERMISSION = 'FinancialAccount_Base_Access';
    
    // Cache for permission level by user ID to reduce query load
    private static Map<Id, String> userPermissionLevelCache = new Map<Id, String>();
    
    /**
     * @description Get the current user's permission level for financial account access
     * @return String representing the permission level: Admin_Level, Mid_Level, or Base_Level
     */
    public static String getCurrentUserPermissionLevel() {
        return getUserPermissionLevel(UserInfo.getUserId());
    }
    
    /**
     * @description Get a specific user's permission level for financial account access
     * @param userId The ID of the user to check permissions for
     * @return String representing the permission level: Admin_Level, Mid_Level, or Base_Level
     */
    public static String getUserPermissionLevel(Id userId) {
        // Check cache first to reduce database queries
        if (userPermissionLevelCache.containsKey(userId)) {
            return userPermissionLevelCache.get(userId);
        }
        
        String permissionLevel = 'Base_Level'; // Default to base level
        
        try {
            // Query for permission set assignments
            List<PermissionSetAssignment> assignments = [
                SELECT PermissionSet.Name 
                FROM PermissionSetAssignment 
                WHERE AssigneeId = :userId
                AND PermissionSet.Name IN (:ADMIN_PERMISSION, :MID_PERMISSION, :BASE_PERMISSION)
                WITH SECURITY_ENFORCED
            ];
            
            // Check for the highest level permission set assigned
            for (PermissionSetAssignment psa : assignments) {
                if (psa.PermissionSet.Name == ADMIN_PERMISSION) {
                    permissionLevel = 'Admin_Level';
                    break; // Admin is highest, so we can stop checking
                } else if (psa.PermissionSet.Name == MID_PERMISSION) {
                    permissionLevel = 'Mid_Level';
                    // Don't break as we still need to check for Admin
                }
            }
            
            // Cache the result
            userPermissionLevelCache.put(userId, permissionLevel);
            
            return permissionLevel;
        } catch (Exception e) {
            System.debug('Error determining user permission level: ' + e.getMessage());
            new LoggingService().logError('PermissionUtility.getUserPermissionLevel', e.getMessage(), e.getStackTraceString());
            return permissionLevel; // Return default level if there's an error
        }
    }
    
    /**
     * @description Check if the current user has admin level access
     * @return Boolean indicating whether the user has admin access
     */
    public static Boolean hasAdminAccess() {
        return getCurrentUserPermissionLevel() == 'Admin_Level';
    }
    
    /**
     * @description Check if the current user has mid level access or higher
     * @return Boolean indicating whether the user has mid level access or higher
     */
    public static Boolean hasMidLevelAccessOrHigher() {
        String level = getCurrentUserPermissionLevel();
        return level == 'Mid_Level' || level == 'Admin_Level';
    }
    
    /**
     * @description Clear the permission level cache for a specific user
     * Call this when a user's permission sets change
     * @param userId The ID of the user to clear from cache
     */
    public static void clearPermissionCache(Id userId) {
        if (userPermissionLevelCache.containsKey(userId)) {
            userPermissionLevelCache.remove(userId);
        }
    }
    
    /**
     * @description Clear the entire permission level cache
     * Call this when doing mass permission set changes
     */
    public static void clearAllPermissionCache() {
        userPermissionLevelCache.clear();
    }
    
    /**
     * @description Get all users with a specific permission level
     * @param permissionLevel The permission level to find users for (Admin_Level, Mid_Level, Base_Level)
     * @return List of users who have the specified permission level
     */
    public static List<User> getUsersWithPermissionLevel(String permissionLevel) {
        // Map permission level to permission set name
        String permissionSetName;
        
        if (permissionLevel == 'Admin_Level') {
            permissionSetName = ADMIN_PERMISSION;
        } else if (permissionLevel == 'Mid_Level') {
            permissionSetName = MID_PERMISSION;
        } else {
            permissionSetName = BASE_PERMISSION;
        }
        
        // Get permission set ID
        PermissionSet ps = [
            SELECT Id FROM PermissionSet 
            WHERE Name = :permissionSetName
            WITH SECURITY_ENFORCED
            LIMIT 1
        ];
        
        // Query for users with this permission set
        List<User> users = new List<User>();
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
     * @description Logging service to record errors
     * This is a placeholder for a more complete logging service implementation
     */
    private class LoggingService {
        public void logError(String className, String message, String stackTrace) {
            System.debug('Error in ' + className + ': ' + message + '\n' + stackTrace);
            // In a full implementation, this would write to a custom object or external system
        }
    }
}
