# Salesforce Financial Services Cloud - Financial Account Access

This Salesforce DX project implements a solution for managing financial account access in Financial Services Cloud (FSC).

## Project Overview

This project provides functionality for managing and controlling access to financial accounts within Salesforce Financial Services Cloud. It includes Lightning Web Components (LWC), Apex classes, and custom objects to handle account access permissions and overrides.

## Project Structure

```
force-app/
├── main/
│   └── default/
│       ├── classes/           # Apex classes
│       ├── lwc/              # Lightning Web Components
│       ├── objects/          # Custom objects
│       ├── permissions/      # Permission sets
│       ├── staticresources/  # Static resources (images, etc.)
│       └── triggers/         # Apex triggers
```

## Key Components

- **Lightning Web Components**
  - `financialAccountAccess` - Main component for managing account access
  - `accessOverrideModal` - Modal for overriding access permissions

- **Apex Classes**
  - `FinancialAccountAccessController` - Main controller for account access logic
  - `AccessOverrideService` - Service for handling access override operations
  - `EmployeeAccountFlagService` - Service for managing employee account flags

- **Custom Objects**
  - `Financial_Account_Access__c` - Stores access permissions
  - `Access_Override__c` - Records access override requests

## Setup Instructions

1. Clone this repository
2. Install Salesforce CLI
3. Authenticate with your org:
   ```bash
   sfdx auth:web:login
   ```
4. Deploy to your org:
   ```bash
   sfdx force:source:deploy -p force-app/main/default
   ```

## Development

- Use `sfdx force:org:create` to create a scratch org
- Use `sfdx force:source:push` to push changes
- Use `sfdx force:source:pull` to pull changes

## Testing

Run tests using:
```bash
sfdx force:apex:test:run
```

## Contributing

1. Create a feature branch
2. Make your changes
3. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details. 