# Financial Account Access Manager

This Salesforce DX project implements a solution for managing and controlling financial account access permissions and overrides. The application provides a comprehensive interface for administrators to manage user access to financial accounts, including permission sets, access overrides, and access management dashboards.

## Project Structure

```
force-app/
├── main/
│   └── default/
│       ├── applications/     # Custom app configuration
│       ├── classes/         # Apex classes
│       ├── lwc/            # Lightning Web Components
│       ├── objects/        # Custom objects
│       ├── permissionsets/ # Permission sets
│       └── triggers/       # Apex triggers
```

## Key Components

- **Lightning Web Components**
  - `accessManagementDashboard`: Main dashboard for managing account access
  - `accessOverrideModal`: Modal for managing access overrides
  - `permissionSetManager`: Component for managing permission sets
  - `userAccessCard`: Component for displaying user access information

- **Apex Classes**
  - `FinancialAccountAccessController`: Main controller for account access operations
  - `FinancialAccountAccessTriggerHandler`: Handles trigger logic for account access

- **Custom Objects**
  - `Financial_Account_Access__c`: Stores account access records
  - `Access_Override__c`: Stores access override records

- **Permission Sets**
  - `Financial_Account_Access_Admin`: Administrative access
  - `Financial_Account_Access_User`: Standard user access

## Setup Instructions

1. Clone the repository
2. Install Salesforce CLI
3. Authenticate with your org
4. Deploy the components:
   ```bash
   sfdx force:source:deploy -p force-app/main/default
   ```

## Development Guidelines

1. Follow Salesforce Lightning Design System (SLDS) guidelines
2. Use Apex best practices for triggers and controllers
3. Implement proper error handling and logging
4. Write unit tests for all Apex classes

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