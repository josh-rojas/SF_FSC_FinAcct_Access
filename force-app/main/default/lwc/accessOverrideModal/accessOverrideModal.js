/**
 * @description Component to manage access overrides for a financial account
 * @author Your Name
 * @date Current Date
 */
import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';

// Import Apex methods
import getAccountOverrides from '@salesforce/apex/AccessOverrideService.getAccountOverrides';
import getEligibleUsersForOverride from '@salesforce/apex/AccessOverrideService.getEligibleUsersForOverride';
import grantOverrideAccess from '@salesforce/apex/AccessOverrideService.grantOverrideAccess';
import revokeOverrideAccess from '@salesforce/apex/AccessOverrideService.revokeOverrideAccess';

export default class AccessOverrideModal extends LightningElement {
    @api account;
    @track overrides = [];
    @track eligibleUsers = [];
    @track selectedUserId;
    @track isLoading = true;
    @track error;
    
    // Wired results for refreshing
    wiredOverridesResult;
    wiredEligibleUsersResult;
    
    // Get account overrides
    @wire(getAccountOverrides, { accountId: '$account.Id' })
    wiredOverrides(result) {
        this.wiredOverridesResult = result;
        const { data, error } = result;
        this.isLoading = false;
        
        if (data) {
            this.overrides = data;
            this.error = undefined;
        } else if (error) {
            this.overrides = [];
            this.error = error;
            this.showToast('Error', 'Error loading overrides: ' + this.reduceErrors(error), 'error');
        }
    }
    
    // Get eligible users for override
    @wire(getEligibleUsersForOverride, { accountId: '$account.Id' })
    wiredEligibleUsers(result) {
        this.wiredEligibleUsersResult = result;
        const { data, error } = result;
        this.isLoading = false;
        
        if (data) {
            this.eligibleUsers = data;
            this.error = undefined;
        } else if (error) {
            this.eligibleUsers = [];
            this.error = error;
            this.showToast('Error', 'Error loading eligible users: ' + this.reduceErrors(error), 'error');
        }
    }
    
    // Close modal
    handleClose() {
        this.dispatchEvent(new CustomEvent('close'));
    }
    
    // Refresh data
    handleRefresh() {
        this.isLoading = true;
        
        Promise.all([
            refreshApex(this.wiredOverridesResult),
            refreshApex(this.wiredEligibleUsersResult)
        ]).then(() => {
            this.isLoading = false;
            this.showToast('Success', 'Override data refreshed', 'success');
        }).catch(error => {
            this.isLoading = false;
            this.showToast('Error', 'Error refreshing data: ' + this.reduceErrors(error), 'error');
        });
    }
    
    // Handle user selection
    handleUserSelection(event) {
        this.selectedUserId = event.target.value;
    }
    
    // Grant override access
    handleGrantAccess() {
        if (!this.selectedUserId) {
            this.showToast('Error', 'Please select a user', 'error');
            return;
        }
        
        this.isLoading = true;
        
        grantOverrideAccess({ userId: this.selectedUserId, accountId: this.account.Id })
            .then(() => {
                this.showToast('Success', 'Override access granted', 'success');
                this.selectedUserId = null;
                this.handleRefresh();
            })
            .catch(error => {
                this.showToast('Error', 'Error granting access: ' + this.reduceErrors(error), 'error');
                this.isLoading = false;
            });
    }
    
    // Revoke override access
    handleRevokeAccess(event) {
        const userId = event.target.dataset.userid;
        
        this.isLoading = true;
        
        revokeOverrideAccess({ userId: userId, accountId: this.account.Id })
            .then(() => {
                this.showToast('Success', 'Override access revoked', 'success');
                this.handleRefresh();
            })
            .catch(error => {
                this.showToast('Error', 'Error revoking access: ' + this.reduceErrors(error), 'error');
                this.isLoading = false;
            });
    }
    
    // Helper methods
    get accountName() {
        return this.account ? this.account.Name : '';
    }
    
    get noOverrides() {
        return this.overrides.length === 0;
    }
    
    get noEligibleUsers() {
        return this.eligibleUsers.length === 0;
    }
    
    get userOptions() {
        return this.eligibleUsers.map(user => {
            return {
                label: user.name,
                value: user.id
            };
        });
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
