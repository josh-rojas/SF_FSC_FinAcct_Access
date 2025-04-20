public with sharing class PermissionSetManager {

    private static final String ADMIN_PERMISSION_SET = 'FinancialAccount_Admin_Access';
    private static final String MID_PERMISSION_SET = 'FinancialAccount_Mid_Access';
    private static final String BASE_PERMISSION_SET = 'FinancialAccount_Base_Access';

    @AuraEnabled(cacheable=false) // Use cacheable=false for methods performing DML
    public static void assignPermissionSet(Id userId, String permissionLevel) {
        System.debug('Attempting to assign permission level: ' + permissionLevel + ' to user: ' + userId);

        String permissionSetName = getPermissionSetNameFromLevel(permissionLevel);

        if (String.isBlank(permissionSetName)) {
            throw new AuraHandledException('Invalid permission level provided: ' + permissionLevel);
        }

        try {
            // Basic example: Create a new assignment (doesn't handle existing ones or conflicts)
            PermissionSetAssignment psa = new PermissionSetAssignment(
                AssigneeId = userId,
                PermissionSetId = [SELECT Id FROM PermissionSet WHERE Name = :permissionSetName LIMIT 1].Id
            );
            insert psa;
            System.debug('Successfully assigned ' + permissionSetName + ' to user ' + userId);
        } catch (Exception e) {
            System.debug('Error assigning permission set ' + permissionSetName + ' to user ' + userId + ': ' + e.getMessage());
            // Consider more specific error handling/logging
            throw new AuraHandledException('Failed to assign permission: ' + e.getMessage());
        }
    }

    @AuraEnabled(cacheable=false) // Use cacheable=false for methods performing DML
    public static void removePermissionSet(Id userId, String permissionLevel) {
        System.debug('Attempting to remove permission level: ' + permissionLevel + ' from user: ' + userId);

        String permissionSetName = getPermissionSetNameFromLevel(permissionLevel);

        if (String.isBlank(permissionSetName)) {
            throw new AuraHandledException('Invalid permission level provided: ' + permissionLevel);
        }

        try {
            PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = :permissionSetName LIMIT 1];
            List<PermissionSetAssignment> assignments = [
                SELECT Id
                FROM PermissionSetAssignment
                WHERE AssigneeId = :userId AND PermissionSetId = :ps.Id
                LIMIT 1
            ];

            if (!assignments.isEmpty()) {
                delete assignments;
                System.debug('Successfully removed ' + permissionSetName + ' from user ' + userId);
            } else {
                 System.debug('No assignment found for ' + permissionSetName + ' for user ' + userId + '. Nothing to remove.');
                 // Optionally throw an error or just log depending on desired behavior
            }
        } catch (Exception e) {
            System.debug('Error removing permission set ' + permissionSetName + ' from user ' + userId + ': ' + e.getMessage());
            // Consider more specific error handling/logging
            throw new AuraHandledException('Failed to remove permission: ' + e.getMessage());
        }
    }

    // Helper method to map level string to actual Permission Set Name
    private static String getPermissionSetNameFromLevel(String permissionLevel) {
        if (permissionLevel == 'Admin_Level') {
            return ADMIN_PERMISSION_SET;
        } else if (permissionLevel == 'Mid_Level') {
            return MID_PERMISSION_SET;
        } else if (permissionLevel == 'Base_Level') {
            return BASE_PERMISSION_SET;
        }
        System.debug('Unknown permission level requested: ' + permissionLevel);
        return null; // Return null for unknown levels
    }
}
