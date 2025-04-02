/**
 * @description Main dashboard component for managing financial account access
 * @author Your Name
 * @date Current Date
 */
import { LightningElement, track, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';

// Import Apex methods
import getUsersWithEmployeeFlag from '@salesforce/apex/EmployeeAccountFlagService.getUsersWithEmployeeFlag';
import getAccessibleFinancialAccounts from '@salesforce/apex/FinancialAccountAccessController.getAccessibleFinancialAccounts';
import getCurrentUserPermissionLevel from '@salesforce/apex/PermissionUtility.getCurrentUserPermissionLevel';

export default class AccessManagementDashboard extends NavigationMixin(LightningElement) {
    @track users = [];
    @track accounts = [];
    @track currentPermissionLevel;
    @track error;
    @track isLoading = true;
    @track activeTab = 'users';
    @track showPermissionManager = false;
    @track showAccessOverrideModal = false;
    @track selectedAccount;
    
    // Wired results for refreshing
    wiredUsersResult;
    wiredAccountsResult;
    
    // Get the current user's permission level
    @wire(getCurrentUserPermissionLevel)
    wiredPermissionLevel({ error, data }) {
        if (data) {
            this.currentPermissionLevel = data;
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.currentPermissionLevel = undefined;
            this.showToast('Error', 'Error loading permission level: ' + this.reduceErrors(error), 'error');
        }
    }
    
    // Get users with employee flag information
    @wire(getUsersWithEmployeeFlag)
    wiredUsers(result) {
        this.wiredUsersResult = result;
        const { data, error } = result;
        this.isLoading = false;
        
        if (data) {
            this.users = data;
            this.error = undefined;
        } else if (error) {
            this.users = [];
            this.error = error;
            this.showToast('Error', 'Error loading users: ' + this.reduceErrors(error), 'error');
        }
    }
    
    // Get financial accounts accessible to the current user
    @wire(getAccessibleFinancialAccounts)
    wiredAccounts(result) {
        this.wiredAccountsResult = result;
        const { data, error } = result;
        this.isLoading = false;
        
        if (data) {
            this.accounts = data;
            this.error = undefined;
        } else if (error) {
            this.accounts = [];
            this.error = error;
            this.showToast('Error', 'Error loading accounts: ' + this.reduceErrors(error), 'error');
        }
    }
    
    // Event handlers
    handleTabChange(event) {
        this.activeTab = event.target.value;
    }
    
    handleRefresh() {
        this.isLoading = true;
        
        Promise.all([
            refreshApex(this.wiredUsersResult),
            refreshApex(this.wiredAccountsResult)
        ]).then(() => {
            this.isLoading = false;
            this.showToast('Success', 'Dashboard refreshed', 'success');
        }).catch(error => {
            this.isLoading = false;
            this.showToast('Error', 'Error refreshing data: ' + this.reduceErrors(error), 'error');
        });
    }
    
    handleOpenPermissionManager() {
        this.showPermissionManager = true;
    }
    
    handleClosePermissionManager() {
        this.showPermissionManager = false;
        this.handleRefresh();
    }
    
    handleManageAccessOverrides(event) {
        this.selectedAccount = event.detail;
        this.showAccessOverrideModal = true;
    }
    
    handleCloseAccessOverrideModal() {
        this.showAccessOverrideModal = false;
        this.selectedAccount = null;
        this.handleRefresh();
    }
    
    handleViewUser(event) {
        const userId = event.detail;
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: userId,
                objectApiName: 'User',
                actionName: 'view'
            }
        });
    }
    
    handleViewAccount(event) {
        const accountId = event.detail;
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: accountId,
                objectApiName: 'FinServ__FinancialAccount__c',
                actionName: 'view'
            }
        });
    }
    
    // Helper methods
    get isAdmin() {
        return this.currentPermissionLevel === 'Admin_Level';
    }
    
    get isMidLevelOrHigher() {
        return this.currentPermissionLevel === 'Admin_Level' || this.currentPermissionLevel === 'Mid_Level';
    }
    
    get noUsers() {
        return this.users.length === 0;
    }
    
    get noAccounts() {
        return this.accounts.length === 0;
    }
    
    get employeeUsers() {
        return this.users.filter(user => user.isEmployee);
    }
    
    get nonEmployeeUsers() {
        return this.users.filter(user => !user.isEmployee);
    }
    
    get employeeAccounts() {
        return this.accounts.filter(account => 
            account.FinServ__PrimaryOwner__r && account.FinServ__PrimaryOwner__r.Is_Employee_Account__c);
    }
    
    get nonEmployeeAccounts() {
        return this.accounts.filter(account => 
            !account.FinServ__PrimaryOwner__r || !account.FinServ__PrimaryOwner__r.Is_Employee_Account__c);
    }
    
    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(event);
    }
    
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
