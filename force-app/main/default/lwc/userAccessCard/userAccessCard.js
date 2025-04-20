/**
 * @description Component to display user access details and actions
 * @author Your Name
 * @date Current Date
 */
import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import setEmployeeFlag from '@salesforce/apex/EmployeeAccountFlagService.setEmployeeFlag';

export default class UserAccessCard extends LightningElement {
    @api user;
    @api permissionLevel;
    @track isUpdating = false;
    
    get userName() {
        return this.user ? this.user.name : '';
    }
    
    get userProfile() {
        return this.user ? this.user.profileName : '';
    }
    
    get userRole() {
        return this.user ? (this.user.roleName || 'No Role') : '';
    }
    
    get isEmployee() {
        return this.user ? this.user.isEmployee : false;
    }
    
    get employeeBadgeClass() {
        return this.isEmployee ? 
            'slds-badge slds-badge_success slds-m-right_xx-small' : 
            'slds-badge slds-badge_light slds-m-right_xx-small';
    }
    
    get employeeBadgeLabel() {
        return this.isEmployee ? 'Employee' : 'Not Employee';
    }
    
    get canEditEmployeeFlag() {
        return this.permissionLevel === 'Admin_Level' || this.permissionLevel === 'Mid_Level';
    }
    
    get canTogglePermission() {
        return this.permissionLevel === 'Admin_Level';
    }
    
    get toggleEmployeeLabel() {
        return this.isEmployee ? 'Remove Employee Flag' : 'Set as Employee';
    }
    
    handleViewUser() {
        this.dispatchEvent(new CustomEvent('view', {
            detail: this.user.id
        }));
    }
    
    handleToggleEmployeeFlag() {
        if (!this.canEditEmployeeFlag) {
            this.showToast('Error', 'You do not have permission to edit employee flags', 'error');
            return;
        }
        
        this.isUpdating = true;
        const newValue = !this.isEmployee;
        
        setEmployeeFlag([this.user.id], newValue)
            .then(() => {
                this.user.isEmployee = newValue;
                this.showToast(
                    'Success', 
                    `User ${this.userName} ${newValue ? 'marked' : 'unmarked'} as employee`, 
                    'success'
                );
                this.isUpdating = false;
            })
            .catch(error => {
                this.showToast('Error', 'Failed to update employee flag: ' + this.reduceErrors(error), 'error');
                this.isUpdating = false;
            });
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
