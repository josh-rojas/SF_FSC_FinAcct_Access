/**
 * @description Component to manage permission set assignments
 * @author Your Name
 * @date Current Date
 */
import { LightningElement, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';

// Import custom Apex methods for this component
import getUsersWithPermissionLevel from '@salesforce/apex/PermissionUtility.getUsersWithPermissionLevel';
import getUsersWithEmployeeFlag from '@salesforce/apex/EmployeeAccountFlagService.getUsersWithEmployeeFlag';

// Import assignPermissionSet and removePermissionSet methods from a PermissionSetAssignmentService
// These would need to be implemented in a separate Apex class
import assignPermissionSet from '@salesforce/apex/PermissionSetManager.assignPermissionSet';
import removePermissionSet from '@salesforce/apex/PermissionSetManager.removePermissionSet';

export default class PermissionSetManager extends LightningElement {
    @track isLoading = true;
    @track adminUsers = [];
    @track midLevelUsers = [];
    @track baseLevelUsers = [];
    @track allUsers = [];
    @track error;
    @track selectedUserId;
    @track selectedLevel;
    @track showAssignModal = false;
    
    // Wired results for refreshing
    wiredAdminUsersResult;
    wiredMidLevelUsersResult;
    wiredBaseLevelUsersResult;
    wiredAllUsersResult;
    
    // Wire admin users
    @wire(getUsersWithPermissionLevel, { permissionLevel: 'Admin_Level' })
    wiredAdminUsers(result) {
        this.wiredAdminUsersResult = result;
        const { data, error } = result;
        this.isLoading = false;
        
        if (data) {
            this.adminUsers = data;
            this.error = undefined;
        } else if (error) {
            this.adminUsers = [];
            this.error = error;
            this.showToast('Error', 'Error loading admin users: ' + this.reduceErrors(error), 'error');
        }
    }
    
    // Wire mid-level users
    @wire(getUsersWithPermissionLevel, { permissionLevel: 'Mid_Level' })
    wiredMidLevelUsers(result) {
        this.wiredMidLevelUsersResult = result;
        const { data, error } = result;
        this.isLoading = false;
        
        if (data) {
            this.midLevelUsers = data;
            this.error = undefined;
        } else if (error) {
            this.midLevelUsers = [];
            this.error = error;
            this.showToast('Error', 'Error loading mid-level users: ' + this.reduceErrors(error), 'error');
        }
    }
    
    // Wire base level users
    @wire(getUsersWithPermissionLevel, { permissionLevel: 'Base_Level' })
    wiredBaseLevelUsers(result) {
        this.wiredBaseLevelUsersResult = result;
        const { data, error } = result;
        this.isLoading = false;
        
        if (data) {
            this.baseLevelUsers = data;
            this.error = undefined;
        } else if (error) {
            this.baseLevelUsers = [];
            this.error = error;
            this.showToast('Error', 'Error loading base level users: ' + this.reduceErrors(error), 'error');
        }
    }
    
    // Wire all users
    @wire(getUsersWithEmployeeFlag)
    wiredAllUsers(result) {
        this.wiredAllUsersResult = result;
        const { data, error } = result;
        this.isLoading = false;
        
        if (data) {
            this.allUsers = data;
            this.error = undefined;
        } else if (error) {
            this.allUsers = [];
            this.error = error;
            this.showToast('Error', 'Error loading all users: ' + this.reduceErrors(error), 'error');
        }
    }
    
    // Handle close modal
    handleClose() {
        this.dispatchEvent(new CustomEvent('close'));
    }
    
    // Handle refresh data
    handleRefresh() {
        this.isLoading = true;
        
        Promise.all([
            refreshApex(this.wiredAdminUsersResult),
            refreshApex(this.wiredMidLevelUsersResult),
            refreshApex(this.wiredBaseLevelUsersResult),
            refreshApex(this.wiredAllUsersResult)
        ]).then(() => {
            this.isLoading = false;
            this.showToast('Success', 'Permission data refreshed', 'success');
        }).catch(error => {
            this.isLoading = false;
            this.showToast('Error', 'Error refreshing data: ' + this.reduceErrors(error), 'error');
        });
    }
    
    // Handle open assign modal
    handleOpenAssignModal() {
        this.showAssignModal = true;
    }
    
    // Handle close assign modal
    handleCloseAssignModal() {
        this.showAssignModal = false;
        this.selectedUserId = null;
        this.selectedLevel = null;
    }
    
    // Handle user selection
    handleUserSelection(event) {
        this.selectedUserId = event.target.value;
    }
    
    // Handle level selection
    handleLevelSelection(event) {
        this.selectedLevel = event.target.value;
    }
    
    // Handle assign permission
    handleAssignPermission() {
        if (!this.selectedUserId || !this.selectedLevel) {
            this.showToast('Error', 'Please select a user and permission level', 'error');
            return;
        }
        
        this.isLoading = true;
        
        assignPermissionSet({ userId: this.selectedUserId, permissionLevel: this.selectedLevel })
            .then(() => {
                this.showToast('Success', 'Permission level assigned', 'success');
                this.handleCloseAssignModal();
                this.handleRefresh();
            })
            .catch(error => {
                this.showToast('Error', 'Error assigning permission: ' + this.reduceErrors(error), 'error');
                this.isLoading = false;
            });
    }
    
    // Handle remove permission
    handleRemovePermission(event) {
        const userId = event.target.dataset.userid;
        const permissionLevel = event.target.dataset.level;
        
        this.isLoading = true;
        
        removePermissionSet({ userId: userId, permissionLevel: permissionLevel })
            .then(() => {
                this.showToast('Success', 'Permission level removed', 'success');
                this.handleRefresh();
            })
            .catch(error => {
                this.showToast('Error', 'Error removing permission: ' + this.reduceErrors(error), 'error');
                this.isLoading = false;
            });
    }
    
    // Helper methods
    get usersForSelection() {
        return this.allUsers.map(user => {
            return {
                label: user.name,
                value: user.id
            };
        });
    }
    
    get levelOptions() {
        return [
            { label: 'Admin Level', value: 'Admin_Level' },
            { label: 'Mid Level', value: 'Mid_Level' },
            { label: 'Base Level', value: 'Base_Level' }
        ];
    }
    
    // Show toast message
    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(event);
    }
    
    // Reduce errors to readable format
    reduceErrors(errors) {
        if (!Array.isArray(errors)) {
            errors = [errors];
        }
        
        return errors
            .filter(error => !!error)
            .map(error => {
                if (typeof error === 'string') {
                    return error;
                } else if (error.message) {
                    return error.message;
                } else if (error.body && error.body.message) {
                    return error.body.message;
                } else {
                    return JSON.stringify(error);
                }
            })
            .join(', ');
    }
}
